import configparser
import json
import os
import subprocess
import sys
import time
import shutil
import signal
import libcomps

from omniimager import lorax
from omniimager import rootfs_worker, utils
from omniimager import installer_maker
from omniimager import iso_worker
from omniimager import pkg_fetcher
from omniimager.log_utils import LogUtils
from omniimager.utils import binary_exists
from omniimager.ks_util import get_ksparser, get_packages

ROOTFS_DIR = 'rootfs'
DNF_COMMAND = 'dnf'

TYPE_VHD = 'vhd'
TYPE_CALAMARES_INSTALLER = 'calamares-iso'
TYPE_ANACONDA_INSTALLER = 'anaconda-iso'
TYPE_LIVECD = 'livecd-iso'
SUPPORTED_BUILDTYPE = [TYPE_LIVECD, TYPE_CALAMARES_INSTALLER, TYPE_ANACONDA_INSTALLER, TYPE_VHD]

INITRD_PKG_LIST = [
    "filesystem", "audit", "bash", "ncurses", "ncurses-libs",
    "cronie", "coreutils", "basesystem", "file", "bc", "bash",
    "bzip2", "sed", "procps-ng", "findutils", "gzip", "grep",
    "libtool", "openssl", "pkgconf", "readline", "sed", "sudo",
    "systemd", "util-linux", "bridge-utils", "e2fsprogs",
    "elfutils-libelf", "expat", "setup", "gdbm", "tar",
    "xz", "zlib", "iproute", "dbus", "cpio", "file",
    "procps-ng", "net-tools", "nspr", "lvm2", "firewalld",
    "glibc", "grubby", "hostname", "initscripts", "iprutils",
    "irqbalance", "kbd", "kexec-tools", "less", "openssh",
    "openssh-server", "openssh-clients", "parted", "passwd",
    "policycoreutils", "rng-tools", "rootfiles",
    "selinux-policy-targeted", "sssd", "tuned", "vim-minimal",
    "xfsprogs", "NetworkManager", "NetworkManager-config-server",
    "authselect", "dracut-config-rescue", "kernel-tools", "sysfsutils",
    "linux-firmware", "lshw", "lsscsi", "rsyslog", "security-tool",
    "sg3_utils", "dracut-config-generic", "dracut-network", "rdma-core",
    "selinux-policy-mls", "kernel"
]

REQUIRED_BINARIES = ["createrepo", "dnf", "mkisofs", "lorax"]


def parse_repo_files(save_path, repo_files_str):
    print('Parsing and making a new repo file, please wait...')
    repo_file_list = repo_files_str.split(',')
    key_list = []
    config_write = configparser.ConfigParser()
    write_dict = {}
    for repo_file in repo_file_list:
        if not os.path.exists(repo_file):
            print(f'{repo_file} does not exist, exit')
            sys.exit(1)
        filename = os.path.splitext(repo_file)[0].split('/')[-1]
        config_read = configparser.ConfigParser()
        config_read.read(repo_file, encoding='utf-8')
        section_list = config_read.sections()
        for section in section_list:
            new_section = ''
            item_list = config_read.items(section)
            if section in key_list:
                while True:
                    num = 0
                    suffix = '-' + filename + '-' + str(num) if num else '-' + filename
                    new_section = section + suffix
                    if new_section not in key_list:
                        break
                    num += 1
            for item in item_list:
                if item[0] == 'name' and new_section:
                    write_dict[item[0]] = new_section
                else:
                    write_dict[item[0]] = item[1]
                if new_section:
                    section = new_section
            config_write[section] = write_dict
            key_list.append(section)
    filepath = os.path.join(save_path, 'omni-build.repo')
    with open(filepath, 'w') as f:
        config_write.write(f)
    print('Make repo file successfully！')
    return filepath


def parse_comps_packages(ks_file, comps_file):
    ksparser = get_ksparser(ks_file)
    comps = libcomps.Comps()
    comps.fromxml_f(comps_file)

    pkglist = []
    for grp in ksparser.handler.packages.groupList:
        pkglist += get_packages(comps, grp.name)
 
    c_pkglist = list(set(pkglist))
    return c_pkglist


def parse_package_list(list_file):
    if not list_file:
        raise Exception

    with open(list_file, 'r') as inputs:
        input_dict = json.load(inputs)

    package_list = input_dict["packages"]
    return package_list


def clean_up_dir(target_dir):
    if os.path.exists(target_dir):
        shutil.rmtree(target_dir)


def prepare_workspace(config_options, repo_files, logger):
    working_dir = config_options['working_dir']
    clean_up_dir(working_dir)
    os.makedirs(working_dir)
    generated_repo_path = os.path.join(working_dir, 'etc')
    os.makedirs(generated_repo_path)

    verbose = True
    if config_options.get('debug'):
        verbose = False

    # prepare an empty rootfs folder with repo file in place
    rootfs_dir = os.path.join(working_dir, ROOTFS_DIR)
    rootfs_repo_dir = os.path.join(rootfs_dir, 'etc/yum.repos.d')

    repo_file = parse_repo_files(generated_repo_path, repo_files)

    clean_up_dir(rootfs_dir)
    os.makedirs(rootfs_dir)
    os.makedirs(rootfs_repo_dir)
    shutil.copy(repo_file, rootfs_repo_dir)

    logger.debug('Create a clean dir to hold all files required to make iso ...')

    iso_base_dir = os.path.join(working_dir, 'iso')
    os.makedirs(iso_base_dir)

    return rootfs_dir, working_dir, iso_base_dir, repo_file, rootfs_repo_dir, verbose


def omni_interrupt_handler(signum, frame):
    print('\nKeyboard Interrupted! Cleaning Up and Exit!')
    sys.exit(1)


def build(build_type, config_file, package_list, repo_files, product, version, release, variant, output_file):
    signal.signal(signal.SIGINT, omni_interrupt_handler)
    start_time = time.time()
    config_options = utils.parse_config_file(config_file)
    isolabel = "%s-%s%s-%s"%(product, version, release, os.uname().machine)
    logger = LogUtils('logger', config_options)
    if build_type not in SUPPORTED_BUILDTYPE:
        logger.debug('Unsupported build-type, Stopped ...')
        sys.exit(1)
    else:
        logger.debug(f'Building:{build_type}')

    for command in REQUIRED_BINARIES:
        if not binary_exists(command):
            logger.debug(f'Binary not found: {command}')
            sys.exit(1)
    packages = parse_package_list(package_list)
    user_specified_packages = []
    config_options['auto_login'] = False
    # Installer ISO have different rootfs with other image type
    if build_type == TYPE_CALAMARES_INSTALLER:
        user_specified_packages = packages
        packages = INITRD_PKG_LIST
        config_options['auto_login'] = True

    rootfs_dir, work_dir, iso_base, repo_file, rootfs_repo_dir, verbose = prepare_workspace(
        config_options, repo_files, logger)

    if build_type == TYPE_ANACONDA_INSTALLER:
        ks_file = config_options['ks_file']
        comps_file = config_options['comps_file']
        comps_packages_list = parse_comps_packages(ks_file, comps_file)

        if not variant:
            variant = 'Server'

        lorax_iso_dir = lorax.build_install_img(
            work_dir, product, version, release, repo_file, config_options, logger, variant)
        package_dir = os.path.join(lorax_iso_dir, 'Packages')
        os.makedirs(package_dir)
        pkg_fetcher.fetch_pkgs(package_dir, comps_packages_list, rootfs_dir, verbose=True)
        subprocess.run('createrepo -d -g %s -o %s %s'%(comps_file, lorax_iso_dir, lorax_iso_dir), shell=True)
        iso_worker.make_iso(lorax_iso_dir, rootfs_dir, output_file, isolabel, skip_isolinux=True)
    else:
        use_cached = config_options.get('use_cached_rootfs')
        if not use_cached:
            rootfs_worker.make_rootfs(
                rootfs_dir, packages, config_options, repo_file, rootfs_repo_dir, build_type, logger, verbose)

            if build_type == TYPE_CALAMARES_INSTALLER:
                installer_maker.install_and_configure_installer(
                    config_options, rootfs_dir, repo_file, rootfs_repo_dir, user_specified_packages, logger)
        else:
            rootfs_worker.unzip_rootfs(
                work_dir, config_options, repo_file, rootfs_repo_dir, build_type, logger, verbose)
        logger.debug('Compressing rootfs ...')
        rootfs_worker.compress_to_gz(rootfs_dir, work_dir, logger)

        if build_type == TYPE_CALAMARES_INSTALLER:
            logger.debug('Downloading RPMs for installer ISO ...')
            rpms_dir = os.path.join(iso_base, 'RPMS')
            os.makedirs(rpms_dir)
            pkg_fetcher.fetch_pkgs(rpms_dir, user_specified_packages, rootfs_dir, verbose=True)
            subprocess.run('createrepo ' + rpms_dir, shell=True)

        iso_worker.make_iso(iso_base, rootfs_dir, output_file, isolabel)
    logger.debug(f'ISO: openEuler-test.iso generated in: {work_dir}')
    utils.create_checksum_file(config_options, work_dir, output_file)
    end_time = time.time()
    elapsed_time = end_time - start_time
    logger.debug(f'Elapsed time: {elapsed_time} s')
