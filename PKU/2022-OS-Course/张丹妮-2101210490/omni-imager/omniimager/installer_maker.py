import os
import wget
from shutil import copy
from shutil import copytree
import subprocess

from pychroot import Chroot

from omniimager import pkg_fetcher

CALAMARES_DEPENDENCIES = [
    'boost-python3', 'rsync', 'make', 'qt5',
    'polkit-qt5-1-devel', 'extra-cmake-modules',
    'qt5-qtsvg-devel', 'qt5-qtquickcontrols2-devel',
    'kf5-kcoreaddons-devel', 'xorg-x11-drv-fbdev',
    'xorg-x11-server', 'xorg-x11-drivers', 'kf5-kservice-devel',
    'openssl-devel', 'libgcrypt-devel', 'yaml-cpp-devel',
    'libatasmart-devel', 'kf5-kwidgetsaddons-devel'
]

# Please do not change the order of this list
CALAMARES_PACKAGE_URLS = [
    'https://github.com/omnibuildplatform/oEFS-rpms/releases/download/v0.1/qca.tar.gz',
    'https://github.com/omnibuildplatform/oEFS-rpms/releases/download/v0.1/kpmcore.tar.gz',
    'https://github.com/omnibuildplatform/oEFS-rpms/releases/download/v0.1/calamares.tar.gz',
]


def get_decompress_and_install(source_file, dest_root_dir):
    dest_dir = dest_root_dir + '/opt/'
    orig_dir = os.getcwd()
    os.chdir(dest_dir)
    wget.download(source_file)
    pkg_name = source_file.split('/')[-1]

    # Decompress file
    cmd = ['tar', '-xzf', pkg_name]
    subprocess.run(' '.join(cmd), shell=True)

    # Chroot and install
    with Chroot(dest_root_dir):
        full_name = '/opt/' + pkg_name.split('.')[0] + '-*/build'
        cmd = ['cd', full_name, '&&', 'make', 'install/fast']
        subprocess.run(' '.join(cmd), shell=True)

    os.chdir(orig_dir)


def install_and_configure_installer(
        config_options, dest_dir, repo_file, rootfs_repo_dir, pkgs, logger, verbose=True):
    """
    Install and configure installer to rootfs, current supported installers:
    calamares
    """

    logger.debug('Installing dependencies for Calamares ...')
    # Install dependencies for calamares
    pkg_fetcher.fetch_and_install_pkgs(dest_dir, CALAMARES_DEPENDENCIES,
                                       repo_file, rootfs_repo_dir, logger, verbose)

    # openEuler currently does not have calamares package and two of the
    # dependency, so we have to manually install pre-built one together
    # with its' dependencies kpmcore and qca
    for url in CALAMARES_PACKAGE_URLS:
        get_decompress_and_install(url, dest_dir)

    # Copy installer script file and make it executable, configure it start
    # when root user login
    installer_file = config_options['installer_script']
    copy(installer_file, dest_dir)
    find_pattern = '^\(root.*\):[^:]*$'
    replacePattern = '\1:/runinstaller'
    with Chroot(dest_dir):
        subprocess.run('chmod +x /runinstaller', shell=True)
        subprocess.run("sed -i 's|^\(root.*\):[^:]*$|\\1:/runinstaller|' etc/passwd", shell=True)

    with Chroot(dest_dir):
        subprocess.run('mkdir -p /run/user/0', shell=True)
        subprocess.run('chmod 700 /run/user/0', shell=True)

    calamares_config_dir = dest_dir + '/etc/calamares/'

    # TODO: make installer config configurable
    copytree(config_options['installer_configs'], calamares_config_dir)

    # Configure calamares packages plugin to install user specified packages
    pkg_config_file = calamares_config_dir + 'modules/packages.conf'
    with open(pkg_config_file, 'a') as output:
        for line in pkgs:
            output.write('    - ' + line)
            output.write('\n')
