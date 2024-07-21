# omni-imager development

omni-imager 采用 Python 编写，它包括以下几个组成部分：

### Imager：

imager 模块是镜像构建工作流的主要入口，它将调用其他 python 文件中的函数，例如 `iso_worker`、`pkg_fether` 等。

构建 Ananconda Installer ISO 的主要工作流程为：

1. 生成安装程序映像（installer image）：对于Ananconda Installer，会调用 lorax 使用预配置的模板构建安装程序映像

```python
lorax_iso_dir = lorax.build_install_img(work_dir, product, version, release, repo_file, config_options, logger, variant)
```

2. 根据用户要求下载软件包 ( `dnf` 命令) (`pkg_fetcher.py`)

```python
package_dir = os.path.join(lorax_iso_dir, 'Packages')
os.makedirs(package_dir)
pkg_fetcher.fetch_pkgs(package_dir, comps_packages_list, rootfs_dir, verbose=True)
```

3. 准备 `isolinux` 相关的二进制文件

```python
subprocess.run('createrepo -d -g %s -o %s %s'%(comps_file, lorax_iso_dir, lorax_iso_dir), shell=True)
```

4. 使用 `mkisofs` 生成 ISO 文件(`iso_worker.py`) 

```python
iso_worker.make_iso(lorax_iso_dir, rootfs_dir, output_file, isolabel, skip_isolinux=False)
```

5. 如果需要，添加 `kickstart` 配置文件