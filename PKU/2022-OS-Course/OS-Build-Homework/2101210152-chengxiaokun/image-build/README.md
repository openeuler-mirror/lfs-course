# Omni-Imager:

The imager worker of the Omni-Build Platform, **Omni-Imager** is in charge of manipulating bootable openEuler images,
available actions now includes build bootable images(ISO, RAW, VHD, etc.). Omni-Imager is currently written in Python.

## Quick Start

For more detailed information about design and implementation of Omni-Imager, please refer
to [Develop Documentation](./docs/develop.md).

### Dependencies:

- openEuler distro
- General: `cpio` `gzip` `tar` `cifs-utils` `syslinux`
- Python runtime: `Python 3.8+`
- rpm packages: `dnf` `dnf-plugins-core` `genisoimage` `coreutils` `libcomps`
- pypi packages: check `requirements.txt`

### Install：

There are two ways to install omni-imager:

1. From source:

```shell
git clone https://github.com/omnibuildplatform/omni-imager.git
cd omni-imager && pip install -r requirements.txt
python3 setup.py install
```

2. Using pip(currently you should download the release manually):

```shell
curl -s  https://api.github.com/repos/omnibuildplatform/omni-imager/releases/latest \
| grep omniimager | grep download | cut -d '"' -f 4 | wget -qi -

# ${version} is you download version, such as ./omniimager-0.3.1.tar.gz
pip3 install --prefix / ./omniimager-${version}.tar.gz
```

### Before Running:

The omni-imager currently has there different functions decided by the positional argument. They are as follows:
build, edit, load.

Before using the script, you should know how to config files to run the script. One is an ini format file that config
some necessary information, you can use --config-file argument to specify its path. The other is a json format file that
config packages that you will install into your image, its path can be specified by --package-list argument.

In short, you should config an ini format file when using all functions(build, edit, load), and a json format file when
using build function.

For example:

conf.ini

```shell
[common]
# debug mode, that debug is True will print more information on the console.
debug=false

# path of saving output file, make sure you don't have something important in the path before running scripts because scripts
# will clean up it.
working_dir=/opt/omni-workspace

# set log level.
log_level=DEBUG

# path of saving logs.
log_dir=/var/log/omni-imager

# when build or edit a image successfully. the script will generate a image checksum file. The option will decide which 
# algorithm to be used,now we support sha256, sha1, md5, sha224, sha384, sha512 if you don't config it, default: sha256.   
checksum_algorithm=sha256

[calamares]
# customized username and password for generated image.
user_name=root
user_passwd=openEuler

# path of init.sh that is needed to build calamares install iso, we don't suggest you modify it.
init_script=/etc/omni-imager/init

# path of runinstaller.sh that is needed to build calamares install iso, we don't suggest you modify it.
installer_script=/etc/omni-imager/runinstaller

# path of calamares configurations, we don't suggest you modify it.
installer_configs=/etc/omni-imager/installer_assets/calamares-configs

# path of important configuration, we don't suggest you modify it.
systemd_configs=/etc/omni-imager/installer_assets/systemd-configs

# whether or not to use cached rootfs, if you don't have it, set to false.
use_cached_rootfs=true

# path of cached rootfs.
cached_rootfs_gz=/opt/rootfs_cache/rootfs.tar.gz
```

package-file.json:

```shell
{
  "packages": [
    "filesystem",
    "kernel",
    other packages you need to download...
  ]
}
```

If you don't know which packages are necessary for building minimal ISO, we suggest you use
/etc/omni-imager/openEuler-minimal.json.

### Running:

1. To build an ISO with Anaconda Installer (Lorax backend):

```shell
omni-imager build anaconda-iso --config-file /opt/omni-imager/etc/conf.ini \
--repo-files /etc/omni-imager/repos/openEuler-22.03-LTS.repo --product ${product_name} \
--version ${version} --release ${release_name} --variant ${variant} --output-file ${output_name} \
--package-list ${package_list} 
```

Positional Arguments:

- omni-imager build ${image-type} ...: The type of ISO you want to build, currently supported ISO with anaconda
  installer and calamares installer

Keyword Arguments:

- --package-list: The list of packages that you want to put into your image.
- --config-file: Configuration file for the software.
- --repo-files: The list of repo files that you want to use, the program will consolidate them to a new repo file.
- --product: The product name of you OS.
- --version: The version of this build.
- --release: The release name of this build (e.g. LTS, dev)
- --variant: If a variant is passed to lorax it will select a system-release package that ends with the variant name.
eg. Passing `--variant server` will select the `openEuler-release-server` package if it exists, the default value of
this parameter is `server`.
- --output-file: The output image file name. If it's not specified, use default name: 'openEuler-image.iso'


2. To build an ISO with Calamares Installer:

```shell
omni-imager build calamares-iso --package-list /etc/omni-imager/openEuler-minimal.json --config-file /etc/omni-imager/conf.ini \
--repo-files /etc/omni-imager/local.repo,/etc/omni-imager/openEuler-21.03.repo  --output-file openEuler-image.iso
```

Positional Arguments:

- omni-imager build ${image-type} ...: The type of ISO you want to build, currently supported ISO with anaconda
  installer and calamares installer

Keyword Arguments:

- --package-list: The list of packages that you want to put into your image.
- --config-file: Configuration file for the software.
- --repo-files: The list of repo files that you want to use, the program will consolidate them to a new repo file
in '[working_dir]/etc' and use it when building image. Separate by ',' when there are several repo files.
- --output-file: The output image file name. If it's not specified, use default name: 'openEuler-image.iso'


3. To load a kickstart config file from an existing ISO file:

```shell
omni-imager load ks --config-file /etc/omni-imager/conf.ini
--iso ${iso file path} --output-file ks.cfg --loop-device ${loop device path}
```

Positional Arguments:

- omni-imager load ${file-type}: The file type that you want to get, currently only supported ks(kickstart config file)

This will extract the kickstart config file from the given ISO and put it under the workspace with your specified name.

Keyword Arguments:

- --config-file: Configuration file for the software.
- --iso: ISO path that you want to extract
- --output-file: The output file name. If it's not specified, use default name: ks.cfg
- --loop-device: Device path to mount the image, when it set to 'auto', program will choose loop device automatically.
  If it's not specified, default: 'auto'

4. To edit the kickstart config file of an existing ISO file:

```shell
omni-imager edit ks --ks ${ks.cfg file path}  --config-file /etc/omni-imager/conf.ini
--iso /opt/openEuler-22.03-LTS-netinst-x86_64-dvd.iso --output-file testnew.iso --loop-device ${loop device path}
```

This will overwrite the kickstart config file of an existing ISO file and generate a new ISO file in the workspace with
your specified name.

Positional Arguments:

- omni-imager edit ${file-type}: The file type that you want to use, currently only supported ks(kickstart config file)

Keyword Arguments:

- --config-file: Configuration file for the software.
- --ks: Kickstart config file path that you want to put it into image.
- --iso: ISO path that you want to edit.
- --output-file: The output new image name, default: new.iso
- --loop-device: Device path to mount the image, when it set to 'auto', program will choose loop device automatically.
  If it's not specified, default: 'auto'

## TODO list

- Full support for Lorax backend

## Contribute

Welcome to file issues or bugs at:
https://github.com/omnibuildplatform/omni-imager/issues
