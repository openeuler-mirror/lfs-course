主要阅读和参考了https://github.com/WilliamWongQAQ/my-imager   的代码

实在是时间有限（目前在实习）+能力有限（主要技术栈是java和go）

### Imager

The imager is the coordinator and the main entrance for the image building workflow. It will call functions in other python files, such as `installer_maker.py`, `iso_worker`, `pkg_fether` etc.

The imager worker will support multiple backends, such as `raw`, `calamares-installer` and `anaconda-installer(WIP)`, in order to support different types of images.

The overall workflow to build ISO is like this:

1. Generate installer image:
   1. For Calamares Installer:
      1. Prepare rootfs according to rootfs package list(`rootfs_worker.py`)
      2. Build, install and config Calamares installer(`installer_maker.py`)
      3. Can use pre-built rootfs with Calamares installer inside by specify `use_cached_rootfs: True` and `cached_rootfs_gz: /opt/rootfs_cache/rootfs.tar.gz` in the configuration file
   2. For Anaconda Installer:
      1. Calling `lorax` to build installer image with pre-configured templates
2. Download software package(`dnf` commands) according to user's specification(`pkg_fetcher.py`)
3. Prepare `isolinux` related binaries
4. Generate ISO file with `mkisofs`(`iso_worker.py`)
5. Add `kickstart` config file if needed



主要参考资料：

https://blog.csdn.net/mydsyc/article/details/44062401

https://blog.csdn.net/geekard/article/details/6455502

# Linux安装流程

## 流程

1. BIOS加电自检

2. 运行isolinux目录下面的isolinux.bin文件，这个isolinux.bin文件根据isolinux.cfg文件的选项来加载内核vmlinuz和initrd.img文件，initrd.img文件会在内存中生成一个虚拟的linux操作系统，为安装过程提供一个安装环境。

3. initrd.img文件中的/sbin/loader文件会探测安装介质,如果探测到是cd安装,就会运行images目录中的stage2.img(安装过程需要的所有镜像)镜像文件,这个文件中最重要的就是anaconda程序,我们看到的安装过程中的向导图就是这个anaconda程序的作用。

4. 安装完成，重启系统。

文件的调用顺序为isolinux/vmlinuz--->isolinux/initrd.img--->/init--->/sbin/loader--->imagaes/install.img---

\>/usr/bin/anaconda 

## 重要组件

1. kernel

   ​      系统启动后,Kernel会常驻内存,负责系统的基础功能,如进程调度,硬件管理.普通程序就是用户态程序,在Kernel中的程序叫做内核态程序.普通程序如果想申请内存,需要进行系统调用来申请,系统调用这个动作就是kernel来做的.

   ​      如果用户程序想申请相机资源,需要调用Kernel提供的系统接口.

   ​      如果一个普通用户进程死掉了,系统不会崩,但是如果Kernel死掉了,系统也就死掉了.Kernel是系统启动的第一个程序

   ​      kernel运行在受保护的内存中间中,普通程序不能访问.

   

2. initrd

   ​      initrd是进入系统所需预告加载的硬件驱动module的一个最小集。当GRUB加载kernel时，kernel会在内存中将initrd文件mount到rootfs上激活，然后kernel照着initrd中的init一步一步地加载驱动。在initrd文件中所放入的模块，必须是与操作系统同一版本kernel所编译。

   ​      initrd的最初的目的是为了把kernel的启动分成两个阶段：在kernel中保留最少最基本的启动代码，然后把对各种各样硬件设备的支持以模块的方式放在initrd中，这样就在启动过程中可以从initrd中mount根文件系统中需要装载的模块。这样的一个好处就是在保持kernel不变的情况下，通过修改initrd中的内容就可以灵活的支持不同的硬件。在启动完成的最后阶段，根文件系统可以重新mount到其他设备上。我们常在编译核心的使用，使用make menuconfig，其中对某些而外的驱动，是可以选择以模块编译，还是<*>直接编译到核心里面。例如ext3文件系统驱动，如果核心需要放在该文件系统上，可以有两个方法： 
   引用 
   1、把其全都编译到内核中，则只需要一个内核文件系统即可启动； 
   2、把其编译为模块，然后通过initrd虚拟的内存系统加载； 
     也就是说由于initrd会在内存虚拟一个文件系统，然后可以根据不同的硬件加载不同的驱动，而不需要重新编译整个核心。所以，大部分的发行版都会通过这种方式对驱动进行加载。 

   使用mkinitrd命令，生成initrd文件

   

3. rootfs

   ​    根文件系统首先是内核启动时所mount的第一个文件系统，内核代码映像文件保存在根文件系统中，而系统引导启动程序会在根文件系统挂载之后从中把一些基本的初始化脚本和服务等加载到内存中去运行。

   ​    展开来细说就是，根文件系统首先是一种文件系统，该文件系统不仅具有普通文件系统的存储数据文件的功能，但是相对于普通的文件系统，它的特殊之处在于，它是内核启动时所挂载（mount）的第一个文件系统，内核代码的映像文件保存在根文件系统中，系统引导启动程序会在根文件系统挂载之后从中把一些初始化脚本（如rcS,inittab）和服务加载到内存中去运行。我们要明白文件系统和内核是完全独立的两个部分。在嵌入式中移植的内核下载到开发板上，是没有办法真正的启动Linux操作系统的，会出现无法加载文件系统的错误。

      根文件系统之所以在前面加一个”根“，说明它是加载其它文件系统的”根“，那么如果没有这个根，其它的文件系统也就没有办法进行加载的。

      根文件系统包含系统启动时所必须的目录和关键性的文件，以及使其他文件系统得以挂载（mount）所必要的文件。例如：

   init进程的应用程序必须运行在根文件系统上；
   根文件系统提供了根目录“/”；
   linux挂载分区时所依赖的信息存放于根文件系统/etc/fstab这个文件中；
   shell命令程序必须运行在根文件系统上，譬如ls、cd等命令；
   总之：一套linux体系，只有内核本身是不能工作的，必须要rootfs（上的etc目录下的配置文件、/bin /sbin等目录下的shell命令，还有/lib目录下的库文件等···）相配合才能工作。

   Linux启动时，第一个必须挂载的是根文件系统；若系统不能从指定设备上挂载根文件系统，则系统会出错而退出启动。成功之后可以自动或手动挂载其他的文件系统。因此，一个系统中可以同时存在不同的文件系统。在 Linux 中将一个文件系统与一个存储设备关联起来的过程称为挂载（mount）。使用 mount 命令将一个文件系统附着到当前文件系统层次结构中（根）。在执行挂装时，要提供文件系统类型、文件系统和一个挂装点。根文件系统被挂载到根目录下“/”上后，在根目录下就有根文件系统的各个目录，文件：/bin /sbin /mnt等，再将其他分区挂接到/mnt目录上，/mnt目录下就有这个分区的各个目录和文件。

# Linux启动流程

## BIOS

当你打开计算机电源，计算机会首先加载BIOS(Basic Input Output System)。系统加电后会读取其中各项数据， BIOS信息是如此的重要，以至于计算机必须在最开始就找到它。这是因为BIOS中包含了CPU的相关信息、设备启动顺序信息、硬盘信息、内存信息、时钟信息、PnP特性等等。在 PC 中，引导 Linux 是从 BIOS 中的地址 0xFFFF0 处开始的。 在此之后，PC获得了第一启动设备代号。

## BootLoader

### stage1

第一启动设备上面的第0磁道第一个扇区被称为MBR，也就是Master Boot Record，即主引导记录，它的大小是512字节，里面存放了预启动信息、分区表信息。当启动设备找到之后，加载MBR到RAM中执行。在linux系统中，这个阶段读取的文件是/boot/grub/stage1。一旦这个boot loader加载到RAM，BIOS就把计算机控制权交给它。

```bash
MBR组成：
1.主引导程序(bootloader)（占446个字节）
    可在FDISK程序中找到，它用于硬盘启动时将系统控制转给用户指定的并在分区表中登记了的某个操作系统。

2.磁盘分区表项（DPT，Disk Partition Table)
    由四个分区表项构成（每个16个字节）。
负责说明磁盘上的分区情况，其内容由磁盘介质及用户在使用FDISK定义分区时决定。（具体内容略）

3.有效硬盘标书（占2个字节）
    其值为AA55，存储时低位在前，高位在后，即看上去是55AA（十六进制）。如果这个标志为0XAA55就认为这个是MBR。
```

### stage1.5

1.stage1.5是MBR后面的分区
2.stage1.5能识别区分文件系统
3.stage1.5是stage1和stage2的桥梁
4.GRUB访问/boot分区grub目录下得stage2文件，将stage2载入内存并执行

### stage2

大体过程如下：

1.解析grub的配置文件/boot分区下/grub/grub.conf
2.显示操作系统启动菜单
3.加载内核镜像到内存
4.通过/boot/initrd开头文件建立虚拟DAM DISK虚拟文件系统
5.转交给内核

Stage2 Boot Loader 就是在操作系统内核运行之前运行的一段小程序。通过这段小程序，我们可以初始化硬件设备、建立内存空间的映射图，从而将系统的软硬件环境带到一个合适的状态，以便为最终调用操作系统内核做好一切准备，并且加载内核。 

  我们常常把first-stage（stage1）和second-stage(stage2)的boot loaders合称为Linux Loader(LILO)或是x86 PC环境下的GRand Unified Bootloader (GRUB)。 在GRUB中，通过文件/boot/grub/grub.conf来显示一个菜单或是输入命令。GRUB相对于LILO的最大的好处是它能够读懂各种linux的文件系统。实际上，GRUB是把前面说的两个stage的boot loader扩展到三个阶段，也就是在stage1之后，加入了stage1.5 boot loader，来完成对文件系统的认知的。比如reiserfs_stage1_5 (从一个 Reiser文件系统)或者e2fs_stage1_5 (从ext2或者ext3文件系统)加载。当这个stage 1.5 boot loader加载运行之后，stage 2 boot loader才加载。 

  grub是在grub.conf的支配下运行的 ，一旦grub从它的命令行或者配置文件中，接到开始操作系统的正确指令，它就寻找必要的引导文件，然后把机器的控制权移交给操作系统。

  grub的功能： 
  1.能够实现启动哪个操作系统 
  2.grub的编辑模式可以直接向内核传递参数。 
  3.加密保护功能 

当stage 2加载完毕，GRUB可以列出可用的kernel（在/boot/grub/grub.conf中定义）。你可以选择其中的一个，并且设置你选中的kernel的启动参数。 

当stage 2 boot loader加载到内存后，默认的kernel映像和initrd映像会加载到内存中。这些映像加载完毕之后，stage 2 boot loader就会激活kernel映像。

## kernel

Stage 2 bootloader之后，内核已经加载到了内存中，控制权转移到了kernerl。这个kernel一般还不是一个可执行的kernel，而是压缩过的kernel映像。通常这个映像使用zlib压缩为zImage (compressed image，小于512KB) 或者是bzImage (big compressed image，大于512KB)。在这个映像的初始部分是一个小模块，进行一些基本的硬件初始化工作，然后把可执行的kernel部分解压出来，放到内存高位。接下来，这个模块就调用kernel，开始kernel引导工作。当解压缩内核完成后，屏幕输出“OK, booting the kernel”。系统将解压后的内核放置在内存之中，kernel会立即初始化系统中各设备并做相关配置工作，其中包括CPU、I/O、存储设备等。在2.6内核中，支持两种格式的initrd，一种是2.4内核的文件系统镜像image-initrd，一种是cpio格式。以 cpio 格式为例，内核判断initrd为cpio的文件格式后，会将initrd中的内容释放到rootfs中。initrd一种基于内存的文件系统，启动过程中，系统在访问真正的根文件系统/时，会先访问initrd 文件系统。将initrd中的内容打开来看，会发现有bin、devetc、lib、procsys、sysroot、 init等文件（包含目录）。其中包含了一些设备的驱模拟块，比如scsi ata等设备驱动模块，同时还有几个基本的可执行程序 insmod, modprobe, lvm，nash。主要目的是加载一些存储介质的驱动模块，如上面所说的scsi ideusb等设备驱动模块，初始化LVM，把/根文件系统以只读方式挂载 
  initrd中的内容释放到rootfs中后，Kernel会执行其中的init文件，这里的init是一个nash脚本，由nash解释器执行。这个时候内核的控制权移交给init文件处理，我们查看init文件的内容，主要也是加载各种存储介质相关的设备驱动。 
  驱动加载后，会创建一个根设备，然后将根文件系统/以只读的方式挂载。这步结束后，执行switchroot，转换到真正的根/上面去，同时运行/sbin/init程序，这就是我们系统的1号进程，此后，系统启动的控制权移交给 init 进程。关于switchroot，这是在nash中定义的程序。 

总结：在整个kernel的启动中，在stage 2的boot loader载入到内存中的initial-RAM disk (initrd) 会被拷贝到RAM中，并挂载起来。它以一个临时的文件系统的身份在RAM中工作，使得kernel在没有任何物理设备挂载的情况下也可以完整的启动起来。正是由于所有与外围设备相关的交互都可以放到initrd中，kernel本身虽然很小，但却支持范围极其广的硬件设备。在kernel的启动完成之后，root文件系统就会回滚(通过pivot_root)，initrd的root文件系统被卸载，实际的root文件系统被挂载起来。 

  Initrd存在是因为Linux Kernel需要适应多种不同的硬件架构，但是将所有的硬件驱动编入Kernel又是不实际的，而且Kernel也不可能每新出一种硬件结构，就将该硬件的设备驱动写入内核。实际上LinuxKernel仅是包含了基本的硬件驱动，在系统安装过程中会检测系统硬件信息，根据安装信息和系统硬件信息将一部分设备驱动写入 initrd 。这样在以后启动系统时，一部分设备驱动就放在 initrd 中来加载。 

综上，kernel的主要操作包括: 
  1.Device探测 
  2.驱动程序初始化 
  3.以只读方式加载根文件系统 
  4.启动init进程 

  initrd是inital ram disk的宿写. 
  当存在initrd的时候,机器启动的过程大概是以下几个步骤(当initrd这一行用noinitrd 命令代替后,就不存在initrd了) 
  1)boot loader(grub)加载内核和initrd.img 
  2)内核将压缩的initrd.img解压成正常的ram disk并且释放initrd所占的内存空间3)initrd作为根目录以读写方式被挂载 
  4)initrd里面的文件linuxrc被执行  5)linuxrc挂载新的文件系统 
  6)linuxrc使用pivot_root系统调用指定新的根目录并将现有的根目录place到指定位置. 
  7)在新的文件系统下正式init 
  8)initrd被卸载

## init进程

1.读取inittable

2.在单用户模式下引导 

 
