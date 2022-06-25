import os
import subprocess
import shutil


def build_install_img(workdir, product, version, release, repo_files, config_options, logger, variant):
    logger.debug('Create Anaconda installer image with Lorax ...')
    buildarch = '--buildarch=' + os.uname().machine
    iso_dir = workdir + '/iso'
    if os.path.exists(iso_dir):
        shutil.rmtree(iso_dir)
    cmd = ['lorax', '--isfinal', '-p', product, '-v', version + release,
           '-r', release, '-t', variant, '--sharedir', '/etc/omni-imager/80-openeuler',
           '--rootfs-size=4', buildarch, '--repo', repo_files, '--nomacboot',
           '--noupgrade', iso_dir, '> /var/log/omni-image/lorax.logfile 2>&1']
    subprocess.run(' '.join(cmd), shell=True)
    return iso_dir
