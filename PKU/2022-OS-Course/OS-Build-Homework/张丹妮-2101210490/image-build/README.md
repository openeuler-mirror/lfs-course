# omni-imager

omni-imager 可用于构建可启动的 openEuler  ISO 镜像，目前采用 Python 语言编写。

有关 omni-imager 的设计和实现的更多详细信息，可以参阅[development.md](./docs/development.md)

### **依赖：**

- openEuler distro
- General: `cpio` `gzip` `tar` `cifs-utils` `syslinux`
- Python runtime: `Python 3.8+`
- rpm packages: `dnf` `dnf-plugins-core` `genisoimage` `coreutils` `libcomps`
- pypi packages: check `requirements.txt`

### **安装：**

```bash
cd omni-imager && pip install -r requirements.txt
python3 setup.py install
```

### **在运行前：**

在使用脚本之前，需要一些配置文件来运行脚本。 一个是 ini 格式文件，用于配制一些必要信息，您可以使用 `--config-file` 参数指定其路径。 另一个是 json 格式文件，用于配置需要安装到镜像中的包，您可以使用`--package-list`参数指定其路径。 

例如：

conf.ini

```bash
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

```bash
{
  "packages": [
    "filesystem",
    "kernel",
    other packages you need to download...
  ]
}
```

如果您不清楚构建最小 ISO 需要哪些软件包，我们建议您使用 /etc/omni-imager/openEuler-minimal.json。

### **运行：**

使用 Anaconda 安装程序（Lorax 后端）构建 ISO：

```bash
omni-imager build anaconda-iso --config-file /opt/omni-imager/etc/conf.ini \
--repo-files /etc/omni-imager/repos/openEuler-22.03-LTS.repo --product ${product_name} \
--version ${version} --release ${release_name} --variant ${variant} --output-file ${output_name} \
--package-list ${package_list}
```

关键参数：

- --package-list: 要安装到镜像中的软件包列表。
- --config-file: 配置文件。
- --repo-files: 要使用的 repo 文件列表，程序会将它们合并到一个新的 repo 文件中。
- --product: 您的操作系统产品名称。
- --version: 此构建的版本。
- --release: 此构建的发布名称（例如 LTS、dev）。
- --variant: 如果一个变量被传递给 lorax，它将选择一个以此变量名称结尾的系统发布包。
    
    例如：传递 `--variant server` 变量会选择 `openEuler-release-server` 包，如果该包存在的话，该参数默认值为 `server`。
    
- --output-file: 输出的镜像文件名。如果未指定，则使用默认名称：'openEuler-image.iso'。