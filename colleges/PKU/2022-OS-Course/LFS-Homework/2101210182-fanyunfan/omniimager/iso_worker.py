import os
from shutil import copy
import subprocess


def prepare_iso_linux(iso_base_dir, rootfs_dir):
    # copy isolinux files to the corresponding folder
    isolinux_files = ['isolinux.bin', 'isolinux.cfg', 'ldlinux.c32']
    for file in isolinux_files:
        full_file = os.path.join('/etc/omni-imager/isolinux/', file)
        copy(full_file, iso_base_dir)

    # copy linux kernel to the corresponding folder
    kernel_dir = os.path.join(rootfs_dir, 'boot/vmlinuz-*')
    cmd = ['cp', kernel_dir, iso_base_dir + '/vmlinuz']
    subprocess.run(' '.join(cmd), shell=True)


def make_iso(iso_base, rootfs_dir, image_name, image_label, skip_isolinux=False):
    if not skip_isolinux:
        prepare_iso_linux(iso_base, rootfs_dir)
        cmd = "mkisofs -R -l -D -o ../%s -b isolinux.bin -c boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table ./" % image_name
    else:
        cmd = "mkisofs -R -J -T -r -l -d -joliet-long -V %s -allow-multidot -allow-leading-dots \
        -no-bak -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 \
        -boot-info-table  -eltorito-alt-boot \
        -e images/efiboot.img -no-emul-boot -o ../%s ./" % (image_label ,image_name)
    orig_dir = os.getcwd()
    os.chdir(iso_base)
    subprocess.run(cmd, shell=True)
    os.chdir(orig_dir)
