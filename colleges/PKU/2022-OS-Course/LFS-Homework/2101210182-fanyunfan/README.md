# Omni-Imager:

Omni-Build Platform 的镜像 worker，**Omni-Imager** 负责操作可启动的 openEuler 镜像，现在可用的操作包括构建可启动镜像（ISO、RAW、VHD 等）。 Omni-Imager 目前是用 Python 编写的。

## 快速启动

有关 Omni-Imager 的设计和实现的更多详细信息，请参阅[开发文档 report.md](./docs/report.md)。

### 依赖:

- openEuler distro
- General: `cpio` `gzip` `tar` `cifs-utils` `syslinux`
- Python runtime: `Python 3.8+`
- rpm packages: `dnf` `dnf-plugins-core` `genisoimage` `coreutils` `libcomps`
- pypi packages: check `requirements.txt`

### 安装：

有两种安装 omni-imager 的方法:

1. 从源安装:

```shell
git clone https://github.com/omnibuildplatform/omni-imager.git
cd omni-imager && pip install -r requirements.txt
python3 setup.py install
```

2. 使用 pip（目前你应该手动下载发行版本）:

```shell
curl -s  https://api.github.com/repos/omnibuildplatform/omni-imager/releases/latest \
| grep omniimager | grep download | cut -d '"' -f 4 | wget -qi -

# ${version} is you download version, such as ./omniimager-0.3.1.tar.gz
pip3 install --prefix / ./omniimager-${version}.tar.gz
```

### 在运行之前:

Omni-imager 目前具有由位置参数决定的不同功能。 它们如下：构建、编辑、加载。

在使用脚本之前，您应该知道如何配置文件来运行脚本。 一种是配置一些必要信息的 ini 格式文件，您可以使用 `--config-file` 参数指定其路径。 另一个是一个 json 格式的文件，用于配置你将安装到镜像中的包，它的路径可以由 `--package-list` 参数指定。

简而言之，使用所有功能（构建、编辑、加载）时应配置 ini 格式文件，使用构建功能时应配置 json 格式文件。

例如：

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

如果您不知道构建最小 ISO 需要哪些软件包，我们建议您使用 /etc/omni-imager/openEuler-minimal.json。

### 运行:

1. 使用 Anaconda 安装程序（Lorax 后端）构建 ISO：

```shell
omni-imager build anaconda-iso --config-file /opt/omni-imager/etc/conf.ini \
--repo-files /etc/omni-imager/repos/openEuler-22.03-LTS.repo --product ${product_name} \
--version ${version} --release ${release_name} --variant ${variant} --output-file ${output_name} \
--package-list ${package_list} 
```

位置参数：

- omni-imager build ${image-type} ...：您要构建的 ISO 类型，目前支持使用 anaconda 安装程序和 calamares 安装程序的 ISO。

关键参数：

- --package-list: 要放入镜像的软件包列表。

- --config-file: 软件的配置文件。

- --repo-files: 您要使用的 repo 文件列表，程序会将它们合并到一个新的 repo 文件中。

- --product: 您的操作系统的产品名称。

- --version: 此构建的版本。

- --release: 此版本的发布名称（例如 LTS、dev）。

- --variant: 如果一个变量被传递给 lorax，它将选择一个以变量名称结尾的系统发布包。

  例如：传递 `--variant server` 会选择 `openEuler-release-server` 包如果存在，该参数默认值为 `server`。

- --output-file: 输出图像文件名。如果未指定，请使用默认名称：'openEuler-image.iso'。


2. 使用 Calamares 安装程序构建 ISO：

```shell
omni-imager build calamares-iso --package-list /etc/omni-imager/openEuler-minimal.json --config-file /etc/omni-imager/conf.ini \
--repo-files /etc/omni-imager/local.repo,/etc/omni-imager/openEuler-21.03.repo  --output-file openEuler-image.iso
```

位置参数：

- omni-imager build ${image-type} ...：您要构建的 ISO 类型，目前支持使用 anaconda 安装程序和 calamares 安装程序的 ISO。

关键参数:

- --package-list: 要放入镜像的软件包列表。
- --config-file: 软件的配置文件。
- --repo-files: 您要使用的 repo 文件列表，程序会将它们合并到 '[working_dir]/etc' 中的新 repo 文件并在构建映像时使用它。 当有多个 repo 文件时，用 ',' 分隔。
- --output-file: 输出图像文件名。 如果未指定，请使用默认名称：'openEuler-image.iso'。


3. 要从现有 ISO 文件加载 kickstart 配置文件：

```shell
omni-imager load ks --config-file /etc/omni-imager/conf.ini
--iso ${iso file path} --output-file ks.cfg --loop-device ${loop device path}
```

位置参数:

- omni-imager load ${file-type}：你要获取的文件类型，目前只支持 ks ( kickstart config file )。

这将从给定的 ISO 中提取 kickstart 配置文件，并将其放在具有您指定名称的工作区下。

关键参数：

- --config-file: 软件的配置文件。
- --iso: 要提取的 ISO 路径。
- --output-file: 输出文件名。 如果未指定，请使用默认名称：ks.cfg。
- --loop-device: 挂载镜像的设备路径，设置为"自动"时，程序会自动选择循环设备。 如果未指定，默认值：'auto'。

4. 编辑现有 ISO 文件的 kickstart 配置文件：

```shell
omni-imager edit ks --ks ${ks.cfg file path}  --config-file /etc/omni-imager/conf.ini
--iso /opt/openEuler-22.03-LTS-netinst-x86_64-dvd.iso --output-file testnew.iso --loop-device ${loop device path}
```

这将覆盖现有 ISO 文件的 kickstart 配置文件，并在工作区中使用您指定的名称生成一个新的 ISO 文件。

位置参数:

- omni-imager load ${file-type}：你要获取的文件类型，目前只支持 ks ( kickstart config file )。

关键参数:

- --config-file: 软件的配置文件。
- --ks: 您想放入镜像中的 Kickstart 配置文件路径。
- --iso: 要编辑的 ISO 路径。
- --output-file: 输出的新镜像名称，默认：new.iso。
- --loop-device: 挂载镜像的设备路径，设置为"自动"时，程序会自动选择循环设备。 如果未指定，默认值：'auto'。
