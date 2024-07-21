# 一、操作系统启动流程简介
**操作系统启动大致流程：**
  POST --> BootSequence (BIOS) -->Bootloader(MBR) --> kernel(ramdisk) --> rootfs(只读) --> init（systemd）

#### 1、第一阶段：BIOS启动引导阶段
在该过程中实现硬件的初始化以及查找启动介质；
从MBR中装载启动引导管理器（GRUB）并运行该启动引导管理
```
BIOS(Basic Input / Output System)，又称基本输入输出系统，可以视为是一个永久地记录在ROM中的一个软件，
是操作系统输入输出管理系统的一部分。早期的BIOS芯片确实是”只读”的，里面的内容是用一种烧录器写入的，一旦写入
就不能更改，除非更换芯片。现在的主机板都使用一种叫Flash EPROM的芯片来存储系统BIOS，里面的内容可通过使用主板
厂商提供的擦写程序擦除后重新写入，这样就给用户升级BIOS提供了极大的方便。
```
  BIOS的功能由两部分组成，分别是POST码和Runtime服务。POST阶段完成后它将从存储器中被清除，而Runtime服务会被一直保留，用于目标操作系统的启动。BIOS两个阶段所做的详细工作如下:
* 步骤1：上电自检POST(Power-on self test)，主要负责检测系统外围关键设备（如：CPU、内存、显卡、I/O、键盘鼠标等）是否正常。例如，最常见的是内存松动的情况，BIOS自检阶段会报错，系统就无法启动起来；
* 步骤2：步骤1成功后，便会执行一段小程序用来枚举本地设备并对其初始化。这一步主要是根据我们在BIOS中设置的系统启动顺序来搜索用于启动系统的驱动器，如硬盘、光盘、U盘、软盘和网络等。以硬盘启动为例，BIOS此时去读取硬盘驱动器的第一个扇区(MBR，512字节)，然后执行里面的代码。实际上这里BIOS并不关心启动设备第一个扇区中是什么内容，它只是负责读取该扇区内容、并执行。

  至此，BIOS的任务就完成了，此后将系统启动的控制权移交到MBR部分的代码。

#### 2、第二阶段：GRUB启动引导阶段
  系统引导 >MBR，它是Master Boot Record的缩写。硬盘的0柱面、0磁头、1扇区称为主引导扇区。它由三个部分组成，主引导程序(Bootloader)、 硬盘分区表DPT（Disk Partition table）和硬盘有效标志（55AA）
```
MBR(Master Boot Record)，主引导记录，MBR存储于磁盘的头部，大小为512bytes，其中，446bytes用于存储
BootLoader程序，64bytes用于存储分区表信息，最后2bytes用于MBR的有效性检查。
```
  GRUB(Grand Unified Bootloader)，多系统启动程序，其执行过程可分为三个步骤：
* 第一步：这个其实就是MBR，它的主要工作就是查找并加载第二段Bootloader程序(stage2)，但系统在没启动时，MBR根本找不到文件系统，也就找不到stage2所存放的位置，因此，就有了stage2
* 第二步：识别文件系统
* 第三步：GRUB程序会根据/boot/grub/grub.conf文件查找Kernel的信息，然后开始加载Kernel程序，当Kernel程序被检测并在加载到内存中，GRUB就将控制权交接给了Kernel程序。

实际上这个步骤/boot还没被挂载，GRUB直接识别grub所在磁盘的文件系统，所以实际上应该是/grub/grub.conf文件，该配置文件的信息如下：
```
default=0 #设定默认启动的title的编号，从0开始
timeout=5 #等待用户选择的超时时间
splashimage=(hd0,0)/boot/grub/splash.xpm.gz #GRUB的背景图片
hiddenmenu #隐藏菜单
title CentOS (2.6.18-194.el5PAE) #内核标题
root (hd0,0) #内核文件所在的设备
kernel /vmlinuz-2.6.18-194.el5PAE ro root=LABEL=/ #内核文件路径以及传递给内核的参数　　　
initrd /initrd-2.6.18-194.el5PAE.img #ramdisk文件路径
```
#### 第三阶段：内核阶段
运行内核启动参数；
解压initrd文件并挂载initd文件系统，装载必须的驱动；
```
Kernel，内核，Kernel是Linux系统最主要的程序，实际上，Kernel的文件很小，只保留了最基本的模块，并以压缩
的文件形式存储在硬盘中，当GRUB将Kernel读进内存，内存开始解压缩内核文件。
```
initrd(Initial RAM Disk)，它在stage2这个步骤就被拷贝到了内存中，这个文件是在安装系统时产生的，是一个临时的根文件系统(rootfs)。因为Kernel为了精简，只保留了最基本的模块，因此，Kernel上并没有各种硬件的驱动程序，也就无法识rootfs所在的设备，故产生了initrd这个文件，该文件装载了必要的驱动模块，当Kernel启动时，可以从initrd文件中装载驱动模块，直到挂载真正的rootfs，然后将initrd从内存中移除。

Kernel会以只读方式挂载根文件系统，当根文件系统被挂载后，开始装载第一个进程(用户空间的进程)，执行/sbin/init，之后就将控制权交接给了init程序。
#### 4、第四阶段: init初始化阶段
```
init程序就是进行OS初始化操作，实际上是根据/etc/inittab(定义了系统默认运行级别)设定的动作进行脚本的执行，
第一个被执行的脚本为/etc/rc.d/rc.sysinit，这个是真正的OS初始化脚本，这个脚本的任务主要有：

激活udev和selinux；
根据/etc/sysctl.conf文件，来设定内核参数；
设定系统时钟；
装载硬盘映射；
启用交换分区；
设置主机名；
根文件系统检测，并以读写方式重新挂载根文件系统；
激活RAID和LVM设备；
启用磁盘配额；
根据/etc/fstab，检查并挂载其他文件系统；
清理过期的锁和PID文件
```

执行完后，根据配置的启动级别，执行对应目录底下的脚本，最后执行/etc/rc.d/rc.local这个脚本，至此，系统启动完成。

# 二、操作系统关键组成部分
Linux系统的组成部分组成：内核+根文件系统（kernel+rootfs）

#### Kernel
根据grub设定的内核映像所在路径，系统读取内存映像，并进行解压缩操作。此时，屏幕一般会输出“Uncompressing Linux”的提示。当解压缩内核完成后，屏幕输出“OK, booting the kernel”。
  系统将解压后的内核放置在内存之中，并调用start_kernel()函数来启动一系列的初始化函数并初始化各种设备，完成Linux核心环境的建立。至此，Linux内核已经建立起来了，基于Linux的程序应该可以正常运行了。


#### Initrd
进入系统所需预告加载的硬件驱动module的一个最小集。当GRUB加载kernel时，kernel会在内存中将initrd文件mount到rootfs上激活，然后kernel照着initrd中的init一步一步地加载驱动。在initrd文件中所放入的模块，必须是与操作系统同一版本kernel所编译的模块。

rootfs_initcall(populate_rootfs) --> populate_rootfs函数加载：initrd。

initrd文件系统提供了init程序，在linux初始化阶段的后期会跳转到init程序，由该程序负责加载驱动程序和挂载磁盘文件系统以及其他的初始化工作。
#### Rootfs
Rootfs源码调用过程：
```
init/main.c->

　　start_kernel()->vfs_caches_init(totalram_pages)-->

　　　　mnt_init()-->

　　　　　 /**

　　　　　　*sysfs用来记录和展示linux驱动模型，sysfs先于rootfs挂载是为全面展示linux驱动模型做好准备。

   　　　　   *mnt_init()调用sysfs_init()注册并挂载sysfs文件系统，然后调用kobject_create_and_add()创建"fs"目录。

　　　　　　**/

　　　　　　sysfs_init();      

　　　　　　/**init_rootfs()注册rootfs，然后调用init_mount_tree()挂载rootfs。**/
　　　　　　init_rootfs();

　　　　　　init_mount_tree();
```
* 1、sysfs文件系统目前还没有挂载到rootfs的某个挂载点上，后续init程序会把sysfs挂载到rootfs的sys挂载点上；
* 2、rootfs是基于内存的文件系统，所有操作都在内存中完成；也没有实际的存储设备，所以不需要设备驱动程序的参与。基于以上原因，linux在启动阶段使用rootfs文件系统，当磁盘驱动程序和磁盘文件系统成功加载后，linux系统会将系统根目录从rootfs切换到磁盘文件系统。


```
init/main.c-> 　　

　　start_kernel()->

　　　　rest_init()-->

　　　　　　kernel_init->

　　　　　　　　do_basic_setup()->

　　　　　　　　　　 do_initcalls()        //这里会根据优先级，加载initcall
```
# 三、Omni-Imager
Omni-Imager使用python开发，可以实现自动化从指定openEuler官方Repo 中的RPM软件包列表选定必要的软件包，调用 Lorax、mkisofs、isolinux 等工具，制作可启动的ISO镜像(Anaconda Installer)
## 1、组成部分
包含以下组成部分：
#### CLI
CLI使用Click库，可以提供一种简单而优雅的方式来提供嵌套命令。

Omni-Imager目前支持3个CLI：
* 1、构建可启动镜像，目前我们支持构建两种类型的ISO镜像：
    * 用户提供的软件包列表中的 Live-CD 映像，这种类型的 ISO 映像是可启动的，可以加载到内存中，映像启动后的修改将在映像重新启动后恢复，可用于测试和演示目的。
    * 带有 Calamares GUI 安装程序的 ISO 映像，该类型的 ISO 映像将提供 GUI 安装程序并指导用户将提供的 openEuler 系统安装到新磁盘，可用的软件包列表由用户提供。

* 2、加载 Ananconda 安装程序 ISO 的 kickstart 配置脚本，Ananconda 安装程序支持使用脚本（kickstart 配置脚本）来自动运行安装程序作业，Omni-Imager 提供了一个 CLI 来从用户提供的 ISO 文件加载 kickstart 脚本以供进一步使用。

* 3、编辑Ananconda 安装程序ISO 的 kickstart 配置脚本，用户可以使用此 CLI 使用用户提供的 kickstart 文件覆盖给定 ISO 的现有 kickstart 脚本，这可以是使用先前 CLI 加载的现有 kickstart 脚本的修改版本。

#### Editor
编辑器是负责从给定 ISO 加载和编辑 kickstart脚本的工作人员，它的工作方式如下：
```
1、将给定的 ISO 挂载到临时目录
2、将ISO的内容解压到工作目录
3、卸载 ISO
4、加载或修改 ISO 的 kickstart 脚本
5、使用用户提供的输出名称将内容重新打包到 ISO
6、清理
```
如果您想向具有不同配置要求的不同用户提供相同的 ISO，该编辑器可能非常有用，例如，部门 A 想要使用软件列表 A 和用户名 DeptA 安装 100 个 ISO，部门 B 想要使用软件列表 B 安装 200 个 ISO 和使用用户名 DeptB，这可以通过调用editCLI 来修改ksISO 文件来轻松完成。
#### Imager
成像器是图像构建工作流程的协调者和主要入口。它将调用其他 python 文件中的函数，例如`installer_maker.py`,`iso_worker`等`pkg_fether`。

imager worker 将支持多个后端，例如`raw`、`calamares-installer`和`anaconda-installer(WIP)`，以支持不同类型的图像。

构建 ISO 的整体工作流程是这样的：

* 1、生成安装程序映像：
    * 对于 Calamares 安装程序：
        a. 根据rootfs包列表准备rootfs( `rootfs_worker.py`)
        b. 构建、安装和配置 Calamares 安装程序（`installer_maker.py`）
        c. 可以通过在配置文件中指定`use_cached_rootfs: True`和 在内部使用预构建的 rootfs 和 Calamares 安装程序`cached_rootfs_gz: /opt/rootfs_cache/rootfs.tar.gz`
    * 对于 Anaconda 安装程序：
        a. 调用`lorax`以使用预配置模板构建安装程序映像
* 2、dnf根据用户要求下载软件包（命令）( `pkg_fetcher.py`)
* 3、准备`isolinux`相关的二进制文件
* 4、`mkisofs`使用( `iso_worker.py`)生成 ISO 文件
* 5、如果需要，添加`kickstart`配置文件

## 2、代码解释
在omniimager文件夹中，通过cli.py程序进行build，例如，调lorax，则进入lorax.py生产出一个路径，再把该路径用iso_worker.py中的命令装一下。
命令行可以用click，也可以用ArgumentParse,本项目用的click。

* cli.py中build代码：
```
@click.command()
@click.argument('build-type')
@click.option('--config-file', help='Configuration file for the software.')
@click.option('--package-list', help='The list of packages that you want to put into your image.')
@click.option('--repo-files', help='The list of repo files that you want to use, the program will consolidate them.')
@click.option('--product', help='Product Name.')
@click.option('--version', help='Version Identifier.')
@click.option('--release', help='Release.')
@click.option('--variant', help='Variant.')
@click.option('--output-file', default='openEuler-image.iso', help='The output image file name.')
def build(build_type, config_file, package_list, repo_files, product, version, release, variant, output_file):
    imager.build(build_type, config_file, package_list, repo_files, product, version, release, variant, output_file)
```
* lorax.py程序生产出一个路径:
```
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
```
* iso_worker.py程序生成iso：
```
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
```

## 3、程序执行
所需依赖：
* openEuler distro
* General: cpio gzip tar cifs-utils syslinux
* Python runtime: Python 3.8+
* rpm packages: dnf dnf-plugins-core genisoimage coreutils libcomps
* pypi packages: check requirements.txt

执行：通过Anaconda Installer创建ISO
```
omni-imager build anaconda-iso --config-file /opt/omni-imager/etc/conf.ini \
--repo-files /etc/omni-imager/repos/openEuler-22.03-LTS.repo --product ${product_name} \
--version ${version} --release ${release_name} --variant ${variant} --output-file ${output_name} \
--package-list ${package_list} 
```
执行上面命令，设置对应参数即可生成对应的ISO镜像。

注：具体详见README.md文档。














