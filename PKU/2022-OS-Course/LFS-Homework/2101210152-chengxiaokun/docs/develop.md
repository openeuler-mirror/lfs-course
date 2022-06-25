# Omni-Imager Development

The Omni-Imager worker is written in Python, it includes the following parts:

### CLI

The CLI of Omni-Imager is uses `Click` library, it can provide an easy and elegant way to
provide nested commands. For implementation details, please check [CLI Codes](../omniimager/cli.py). 

Omni-Imager currently supports 3 CLIs:

1. Build bootable images, currently we support to build two types of ISO images:
   1. A Live-CD image from user provided software package list, this type of ISO image is bootable and can be
   loaded to the memory, modifications after the image is booted will be restored after reboot of the image,
   it could be useful for test and demonstration purpose.
   2. An ISO image with Calamares GUI installer, this type of ISO image will provide an GUI installer and guide
   users to install the provided openEuler system to a new disk, the available software package list is provided
   by the users.

2. Load kickstart configuration script of an **Ananconda Installer** ISO, the **Ananconda Installer** supports
using a script(the kickstart config script) to automatically run installer jobs, Omni-Imager provided a CLI
to load the kickstart script from a user provided ISO file for further use.

3. Edit kickstart configuration script of an **Ananconda Installer** ISO, users can use this CLI to override the
existing kickstart script of the given ISO with a user provided kickstart file, this could be a modified version
of the existing kickstart script loaded using the previous CLI.

### Editor

The editor is the worker in charge of load and editing kickstart scripts from given ISO, it works as the following
way:

1. Mount the given ISO to the temp directory
2. Extract the content of the ISO to the working directory
3. Unmount the ISO
4. Load or modify the kickstart script of the ISO
5. Repack the contents to ISO with the user provided output name
6. Cleanup

The editor could be very useful if you want to deliver the same ISO to different users with different configuration
requirements, for example department A want 100 ISO installed with software list A and with username DeptA,
department B want 200 ISO installed with software list B and with username DeptB, this could be easily done by
calling the `edit` CLI to modify the `ks` file of the ISO.

### Imager

The imager is the coordinator and the main entrance for the image building workflow. It will call functions in other
python files, such as `installer_maker.py`, `iso_worker`, `pkg_fether` etc.

The imager worker will support multiple backends, such as `raw`, `calamares-installer` and `anaconda-installer(WIP)`,
in order to support different types of images.

The overall workflow to build ISO is like this:

1. Generate installer image:
   1. For Calamares Installer:
      1. Prepare rootfs according to rootfs package list(`rootfs_worker.py`)
      2. Build, install and config Calamares installer(`installer_maker.py`)
      3. Can use pre-built rootfs with Calamares installer inside by specify `use_cached_rootfs: True` and 
`cached_rootfs_gz: /opt/rootfs_cache/rootfs.tar.gz` in the configuration file
   2. For Anaconda Installer:
      1. Calling `lorax` to build installer image with pre-configured templates
2. Download software package(`dnf` commands) according to user's specification(`pkg_fetcher.py`)
3. Prepare `isolinux` related binaries
4. Generate ISO file with `mkisofs`(`iso_worker.py`)
5. Add `kickstart` config file if needed
