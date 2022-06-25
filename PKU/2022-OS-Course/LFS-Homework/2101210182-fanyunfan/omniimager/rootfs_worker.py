import os
from shutil import copy
import subprocess

from pychroot import Chroot

from omniimager import imager, utils
from omniimager import pkg_fetcher

RPM_INSTALLER = 'dnf'


def prepare_init_script(config_options, dest_dir):
    init_file = utils.format_path(config_options['init_script'])
    copy(init_file, dest_dir)


def config_rootfs(dest_dir, logger):
    with Chroot(dest_dir):
        # TODO: make this configurable
        subprocess.run('echo "root:openEuler" | chpasswd', shell=True)
        # walk-around to avoid systemd failure
        subprocess.run("sed -i '/SELINUX/{s/enforcing/disabled/}' /etc/selinux/config", shell=True)

    logger.debug('Users and Selinux configuration finished in rootfs.')


def compress_to_gz(dest_dir, work_dir, logger):
    orig_dir = os.getcwd()
    os.chdir(dest_dir)
    # run cpio command to generate rootfs.gz
    subprocess.run('find . | cpio -R root:root -H newc -o | gzip > ../iso/rootfs.gz', shell=True)
    os.chdir(orig_dir)
    logger.debug(f'Done! rootfs.gz generated at {work_dir} /iso')


def unzip_rootfs(dest_dir, config_options, repo_file, rootfs_repo_dir, build_type, logger, verbose=True):
    logger.debug('Unzip Rootfs ...')
    subprocess.run('tar -xzf ' + config_options['cached_rootfs_gz'] + ' -C ' + dest_dir, shell=True)
    copy(repo_file, rootfs_repo_dir)

    dest_dir = dest_dir + '/rootfs'

    if build_type == imager.TYPE_CALAMARES_INSTALLER:
        # If the build type is iso-installer, we have to prepare a base folder to extract to
        # target disk, currently we name it 'basefs' and put it under 'opt' folder of
        # rootfs
        basefs = dest_dir + '/opt/basefs/'
        subprocess.run('mkdir -p ' + basefs, shell=True)

        # We need to add a repo file to install 'dnf' in this folder
        # TODO: Refactor Calamares package plugin to install packages using '--installroot' so that
        # we do not need to install it again in basefs.
        basefs_repo_dir = basefs + 'etc/yum.repos.d/'
        subprocess.run('mkdir -p ' + basefs_repo_dir, shell=True)
        pkg_fetcher.fetch_and_install_pkgs(basefs, ['dnf'], repo_file, basefs_repo_dir, logger, verbose)

        # Replace openEuler.repo with local.repo, because it was override by filesystem
        # this will be used in the installation phase
        subprocess.run('rm -f ' + basefs_repo_dir + 'openEuler.repo', shell=True)
        local_repo = '/etc/omni-imager/repos/local.repo'
        copy(local_repo, basefs_repo_dir)

        # If the build type is iso-installer, we should mount cd-rom(/dev/sr0) automatically,
        # add the corresponding line to /etc/fstab
        subprocess.run("""echo '/dev/sr0  /mnt/cdrom  auto  defaults  0  0' > """ + dest_dir + '/etc/fstab',
                       shell=True)
        # If the build type is iso-installer, we should also do auto login, override the default
        # systemd configuration files
        dest_systemd_dir = dest_dir + '/lib/systemd/system/'
        config_source_dir = config_options['systemd_configs']
        subprocess.run('rm -f ' + dest_systemd_dir + 'getty@.service', shell=True)
        subprocess.run('rm -f ' + dest_systemd_dir + 'serial-getty@.service', shell=True)
        copy(config_source_dir + '/getty@.service', dest_systemd_dir)
        copy(config_source_dir + '/serial-getty@.service', dest_systemd_dir)


def make_rootfs(dest_dir, pkg_list, config_options,
                repo_file, rootfs_repo_dir, build_type, logger, verbose=True):
    logger.debug('Making rootfs ...')
    # Install filesystem first
    if 'filesystem' in pkg_list:
        pkg_fetcher.fetch_and_install_pkgs(dest_dir, ['filesystem'], repo_file, rootfs_repo_dir, logger, verbose)
        pkg_list.remove('filesystem')
        # Replace openEuler.repo because filesystem override it
        subprocess.run('rm -f ' + rootfs_repo_dir + '/openEuler.repo', shell=True)

    pkg_fetcher.fetch_and_install_pkgs(dest_dir, pkg_list, repo_file, rootfs_repo_dir, logger, verbose)
    prepare_init_script(config_options, dest_dir)

    if build_type == imager.TYPE_CALAMARES_INSTALLER:
        # If the build type is iso-installer, we have to prepare a base folder to extract to
        # target disk, currently we name it 'basefs' and put it under 'opt' folder of
        # rootfs
        basefs = dest_dir + '/opt/basefs/'
        subprocess.run('mkdir -p ' + basefs, shell=True)

        # We need to add a repo file to install 'dnf' in this folder
        # TODO: Refactor Calamares package plugin to install packages using '--installroot' so that
        # we do not need to install it again in basefs.
        basefs_repo_dir = basefs + 'etc/yum.repos.d/'
        subprocess.run('mkdir -p ' + basefs_repo_dir, shell=True)
        pkg_fetcher.fetch_and_install_pkgs(basefs, ['dnf'], repo_file, basefs_repo_dir, logger, verbose)

        # Replace openEuler.repo with local.repo, because it was override by filesystem
        # this will be used in the installation phase
        subprocess.run('rm -f ' + basefs_repo_dir + 'openEuler.repo', shell=True)
        local_repo = '/etc/omni-imager/repos/local.repo'
        copy(local_repo, basefs_repo_dir)

        # If the build type is iso-installer, we should mount cd-rom(/dev/sr0) automatically,
        # add the corresponding line to /etc/fstab
        subprocess.run("""echo '/dev/sr0  /mnt/cdrom  auto  defaults  0  0' > """ + dest_dir + '/etc/fstab',
                       shell=True)
        # If the build type is iso-installer, we should also do auto login, override the default
        # systemd configuration files
        dest_systemd_dir = dest_dir + '/lib/systemd/system/'
        config_source_dir = config_options['systemd_configs']
        subprocess.run('rm -f ' + dest_systemd_dir + 'getty@.service', shell=True)
        subprocess.run('rm -f ' + dest_systemd_dir + 'serial-getty@.service', shell=True)
        copy(config_source_dir + '/getty@.service', dest_systemd_dir)
        copy(config_source_dir + '/serial-getty@.service', dest_systemd_dir)

    config_rootfs(dest_dir, logger)
