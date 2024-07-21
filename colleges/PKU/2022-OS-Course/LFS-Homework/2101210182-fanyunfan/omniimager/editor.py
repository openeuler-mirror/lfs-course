import os
import random
import subprocess
import traceback
import shutil
import glob
import re

from omniimager import utils
from omniimager.log_utils import LogUtils

EFI_GRUB_FILE="/EFI/BOOT/grub.cfg"
LEGACY_GRUB_FILE="/isolinux/isolinux.cfg"


def _add_ks(grub_file, kword):
    with open(grub_file, "r") as f:
        file_read = f.read()
    re_search = re.search(kword+'.*', file_read)
    if re_search:
        re_sub = re.sub(re_search.group(), re_search.group()+" ks=cdrom:/ks/ks.cfg", file_read)
        with open(grub_file, "w") as f1:
            f1.write(re_sub)


def add_ks_para(work_dir):
    efi_grub = glob.glob(work_dir + EFI_GRUB_FILE)
    efi_grub = efi_grub[0] if efi_grub else ""
    isolinux_file = glob.glob(work_dir + LEGACY_GRUB_FILE)
    isolinux_file = isolinux_file[0] if isolinux_file else ""
    
    if efi_grub:
        _add_ks(efi_grub, "linuxefi")

    if isolinux_file:
        _add_ks(isolinux_file, "append")


def mount_by_loop_device(logger, imager, dest_dir, loop_device='auto'):
    is_auto = False
    if loop_device == 'auto':
        while True:
            loop_device_prefix = '/dev/loop'
            device_num = str(random.randint(0, 2 ** 20 - 1))
            loop_device = loop_device_prefix + device_num
            if os.path.exists(loop_device):
                continue
            subprocess.run(f'mknod {loop_device} b 7 {device_num}', shell=True)
            subprocess.run(f'chown --reference=/dev/loop0 {loop_device}', shell=True)
            subprocess.run(f'chmod --reference=/dev/loop0 {loop_device}', shell=True)
            subprocess.run(f'mount -o loop={loop_device} {imager} {dest_dir}', shell=True)
            is_auto = True
            break
    else:
        logger.debug(f'Using customized loop device:  {loop_device}...')
        if not os.path.exists(loop_device):
            logger.debug(f'loop device {loop_device} does not exist...')
            raise BaseException
        subprocess.run(f'mount -o loop={loop_device} {imager} {dest_dir}', shell=True)
    return loop_device, is_auto


def umount_loop_device(loop_device, dest_dir, is_auto=False):
    subprocess.run('umount ' + dest_dir, shell=True)
    subprocess.run(f'rm -rf {dest_dir}', shell=True)
    if is_auto:
        subprocess.run(f'rm -rf {loop_device}', shell=True)


def read_iso_label(iso, logger):
    label = "CD-ROM"
    result = subprocess.run('isoinfo -d -i' + iso,stdout=subprocess.PIPE,encoding="utf-8",shell=True)
    if result.returncode == 0:
        isoinfo = result.stdout
        pattern = re.compile('Volume id: +\S*')
        volume_id = pattern.search(isoinfo).group()
        label = re.split(' +', volume_id)[2]
    else:
        logger.debug(f'The iso Volume id is invalid')
    return label


def edit_ks(config_options, iso, ks, output_file, loop_device):
    logger = LogUtils('logger', config_options)
    mount_temp_dir = '/mnt/omni-temp'
    is_auto_device = False
    try:
        subprocess.run('rm -rf ' + mount_temp_dir, shell=True)
        subprocess.run('mkdir -p ' + mount_temp_dir, shell=True)
        working_dir = config_options['working_dir']
        temp_dir = os.path.join(working_dir, 'omni-temp')
        loop_device, is_auto_device = mount_by_loop_device(logger, iso, mount_temp_dir, loop_device)
        subprocess.run('rm -rf ' + temp_dir, shell=True)
        shutil.copytree(mount_temp_dir, temp_dir)
        umount_loop_device(loop_device, mount_temp_dir, is_auto_device)
        ks_dir = os.path.join(temp_dir, 'ks')
        if not os.path.exists(ks_dir):
            logger.debug(f"{ks_dir} dose not exist in original ISO. Try to make it...")
            subprocess.run('mkdir -p ' + ks_dir, shell=True)
            add_ks_para(temp_dir)
        subprocess.run('rm -rf ' + ks_dir + '/ks.cfg', shell=True)
        shutil.copy(ks, ks_dir)

        curr_dir = os.getcwd()
        os.chdir(temp_dir)
        logger.debug('Initializing environment, please wait for a while... ')
        output_file_path = os.path.join(working_dir, output_file)
        label = read_iso_label(iso, logger)
        iso_cmd_prefix = f'mkisofs -R -J -T -r -l -d -V {label} -joliet-long -allow-multidot -allow-leading-dots -no-bak -o {output_file_path} -e images/efiboot.img -no-emul-boot '
        if os.uname().machine == 'x86_64':
            iso_cmd = iso_cmd_prefix + '-b isolinux/isolinux.bin -c isolinux/boot.cat -boot-load-size 4 ' \
                                       '-boot-info-table -eltorito-alt-boot ' + temp_dir
            subprocess.run(iso_cmd, shell=True)
            os.chdir(working_dir)
            subprocess.run('isohybrid -u ' + output_file, shell=True)
        elif os.uname().machine == 'aarch64':
            iso_cmd = iso_cmd_prefix + temp_dir
            subprocess.run(iso_cmd, shell=True)
        os.chdir(curr_dir)
        subprocess.run('rm -rf ' + temp_dir, shell=True)
        utils.create_checksum_file(config_options, working_dir, output_file)
        logger.debug('Done!')
    except BaseException as e:
        if isinstance(e, KeyboardInterrupt):
            logger.debug('\nKeyboard Interrupted! Cleaning Up Caches...')
        else:
            logger.debug(traceback.format_exc())
            logger.debug('Exception Encountered! Cleaning up and Caches...')
        umount_loop_device(loop_device, mount_temp_dir, is_auto_device)
        logger.debug('Exit!')


def load_ks(config_options, iso, output_file, loop_device):
    logger = LogUtils('logger', config_options)
    mount_temp_dir = '/mnt/omni-temp'
    is_auto_device = False
    working_dir = config_options['working_dir']

    try:
        subprocess.run('rm -rf ' + mount_temp_dir, shell=True)
        subprocess.run('mkdir -p ' + mount_temp_dir, shell=True)
        loop_device, is_auto_device = mount_by_loop_device(logger, iso, mount_temp_dir, loop_device)

        ks_dir = os.path.join(mount_temp_dir, 'ks')
        if not os.path.exists(ks_dir):
            logger.debug(f'{ks_dir} does not exist! Stop running...')
            raise BaseException
        shutil.copy(ks_dir + '/ks.cfg', working_dir + '/' + output_file)
        logger.debug(f'Get ks.cfg successfully! Cleaning up caches......')

        umount_loop_device(loop_device, mount_temp_dir, is_auto_device)

        logger.debug('Done!')
    except BaseException as e:
        if isinstance(e, KeyboardInterrupt):
            logger.debug('\nKeyboard Interrupted! Cleaning Up Caches!')
        else:
            logger.debug(traceback.format_exc())
            logger.debug('Exception Encountered! Cleaning up Caches!')
        umount_loop_device(loop_device, mount_temp_dir, is_auto_device)
        logger.debug('Exit!')


def edit(resource_type, config_file, iso, ks, output_file, loop_device):
    # Format parameters
    config_options = utils.parse_config_file(config_file)
    output_file = utils.format_filename(output_file)
    ks = utils.format_path(ks)
    iso = utils.format_path(iso)
    loop_device = utils.format_path(loop_device)
    if resource_type == 'ks':
        edit_ks(config_options, iso, ks, output_file, loop_device)


def load(resource_type, config_file, iso, output_file, loop_device):
    # Format parameters
    config_options = utils.parse_config_file(config_file)
    output_file = utils.format_filename(output_file)
    iso = utils.format_path(iso)
    loop_device = utils.format_path(loop_device)
    if resource_type == 'ks':
        load_ks(config_options, iso, output_file, loop_device)
