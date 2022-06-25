from shutil import copy
import subprocess

RPM_INSTALLER = 'dnf'


def fetch_and_install_pkg(dest_dir, pkg, verbose=True):
    cmd = [RPM_INSTALLER, 'install', pkg, '--installroot',
           dest_dir, '-y']
    if not verbose:
        cmd.append('-q')
    subprocess.run(' '.join(cmd), shell=True)


def fetch_and_install_pkgs(dest_dir, pkg_list, repo_file, rootfs_repo_dir, logger, verbose=True):
    logger.debug('Fetching and Installing Packages ...')
    # copy repo files again to avoid override by filesystem
    copy(repo_file, rootfs_repo_dir)
    for pkg in pkg_list:
        fetch_and_install_pkg(dest_dir, pkg, verbose)
    logger.debug("Done.")
    logger.debug("Fetched and Installed %s Packages" % len(pkg_list))


def fetch_pkgs(dest_dir, pkg_list, installroot=None, verbose=True):
    for pkg in pkg_list:
        cmd = [RPM_INSTALLER,
               'download', '--resolv --alldeps',
               '--destdir', dest_dir, pkg]
        if installroot:
            cmd.append('--installroot ' + installroot)
        if not verbose:
            cmd.append('-q')
        subprocess.run(' '.join(cmd), shell=True)
