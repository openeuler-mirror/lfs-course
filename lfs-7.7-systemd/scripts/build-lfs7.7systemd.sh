#Revision history
#V1.1 zhaoxiaohu 2021.07.04
#V1.2 libaolin 2021.07.08

#
#       Linux From Scratch
#      Version 7.7-systemd
#
#    Created by Gerard Beekmans
# Edited by Matthew Burgess and Armin K.
#
# Implementer: Andrew Zhao
# Create Date: 4-14-2021
# Update Date: 7-01-2021
#       Locus: Hangzhou, China
#

#
# Preface
#

# VM Architecture:
# x86_64

# VM OS
# Other Linux 4.x 64-bit

# Disk sda size
# 30 GB

#
# Part I. Introduction
#

#
# Chapter 1. Introduction
#


#
# Part II. Preparing for the Build
#


# openEuler 20.09 Minimal Installation.

# Terminal
ssh root@192.168.11.130 # instead of your own IP address

yum group install -y "Development Tools"
yum install -y bc
yum install -y openssl-devel

yum install -y texinfo # for makeinfo

yum install -y vim
yum install -y nano

#
# Get "实验指导手册" and "脚本" from gitee
#

# You need to set your git account when you first run it
git config --global user.name "your-user-name"
git config --global user.email "your-email-address-on-gitee"

mkdir ~/openEuler
cd ~/openEuler
git clone https://gitee.com/openeuler-practice-courses/lfs-course
cd lfs-course/
ls
#LICENSE  README.en.md  README.md  lfs-7.7-systemd/

# Check the file cfns-4.9.2.patch
ls ~/openEuler/lfs-course/lfs-7.7-systemd/scripts/sample/patch/cfns-4.9.2.patch


cat > ./version-check.sh << "EOF"
#!/bin/bash
# Simple script to list version numbers of critical development tools
export LC_ALL=C
bash --version | head -n1 | cut -d" " -f2-4
MYSH=$(readlink -f /bin/sh)
echo "/bin/sh -> $MYSH"
echo $MYSH | grep -q bash || echo "ERROR: /bin/sh does not point to bash"
unset MYSH
echo -n "Binutils: "; ld --version | head -n1 | cut -d" " -f3-
bison --version | head -n1
if [ -h /usr/bin/yacc ]; then
echo "/usr/bin/yacc -> `readlink -f /usr/bin/yacc`";
elif [ -x /usr/bin/yacc ]; then
echo yacc is `/usr/bin/yacc -V | head -n1`
else
echo "yacc not found"
fi
bzip2 --version 2>&1 < /dev/null | head -n1 | cut -d" " -f1,6-
echo -n "Coreutils: "; chown --version | head -n1 | cut -d")" -f2
diff --version | head -n1
find --version | head -n1
gawk --version | head -n1
if [ -h /usr/bin/awk ]; then
echo "/usr/bin/awk -> `readlink -f /usr/bin/awk`";
elif [ -x /usr/bin/awk ]; then
echo awk is `/usr/bin/awk --version | head -n1`
else
echo "awk not found"
fi
gcc --version | head -n1
g++ --version | head -n1
ldd --version | head -n1 | cut -d" " -f2- # glibc version
grep --version | head -n1
gzip --version | head -n1
cat /proc/version
m4 --version | head -n1
make --version | head -n1
patch --version | head -n1
echo Perl `perl -V:version`
sed --version | head -n1
tar --version | head -n1
makeinfo --version | head -n1 # texinfo version
xz --version | head -n1
echo 'int main(){}' > dummy.c && g++ -o dummy dummy.c
if [ -x dummy ]
then echo "g++ compilation OK";
else echo "g++ compilation failed"; fi
rm -f dummy.c dummy
EOF

bash version-check.sh

# More determination
cat > ./library-check.sh << "EOF"
#!/bin/bash
for lib in lib{gmp,mpfr,mpc}.la; do
echo $lib: $(if find /usr/lib* -name $lib|
grep -q $lib;then :;else echo not;fi) found
done
unset lib
EOF

bash library-check.sh
#如果出现以下保存则忽略
#libgmp.la: not found
#libmpfr.la: not found
#libmpc.la: not found

#
# Chapter 2. Preparing a New Partition
#

# 2.1. Introduction

# 2.2. Host System Requirements

# 2.3. Building LFS in Stages

# 2.3.1. Chapters 1–4
# These chapters are accomplished on the host system.

# 2.3.2. Chapter 5–6
# The /mnt/lfs partition must be mounted.
# These two chapters must be done as user lfs.

# 2.3.3. Chapter 7–10
# The /mnt/lfs partition must be mounted.
# A few operations, from “Changing Ownership” to “Entering the Chroot Environment” must be done.
# The virtual file systems must be mounted.

# 2.4. Creating a New Partition

# Adding a Disk for LFS in VM
# Size: 30GB


#关机，参考实验手册添加另外一块硬盘
shutdown -h now

# Start the machine
# Terminal
ssh root@192.168.11.130 # instead of your own IP address

# Start a disk partitioning program such as fdisk to create a Linux native partition.

# Check
lsblk
fdisk -l /dev/sdb

#开始给第二块磁盘分配
# Just create a primary partition: sdb1
fdisk /dev/sdb

#依次输入 n  p 回车 回车 回车 w
# Welcome to fdisk (util-linux 2.35.2).
# Changes will remain in memory only, until you decide to write them.
# Be careful before using the write command.

# Device does not contain a recognized partition table.
# Created a new DOS disklabel with disk identifier 0x9d1c2177.

# Command (m for help): n
# Partition type
#    p   primary (0 primary, 0 extended, 4 free)
#    e   extended (container for logical partitions)
# Select (default p):

# Using default response p.
# Partition number (1-4, default 1):
# First sector (2048-62914559, default 2048):
# Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-62914559, default 62914559):

# Created a new partition 1 of type 'Linux' and of size 30 GiB.

# Command (m for help): w
# The partition table has been altered.
# Calling ioctl() to re-read partition table.
# Syncing disks.

# Determine
lsblk
blkid

# 2.5. Creating a File System on the Partition

# LFS assumes that the root file system (/) is of type ext4.
# mkfs -v -t ext4 /dev/<xxx>
# Replace <xxx> with the name of the LFS partition.
#格式化刚刚分区的磁盘
mkfs -v -t ext4 /dev/sdb1

# Determine
lsblk
blkid

# 2.6. Setting The $LFS Variable

# export LFS=/mnt/lfs
cp /root/.bash_profile{,.origin}
echo "export LFS=/mnt/lfs" >> /root/.bash_profile
source /root/.bash_profile

# Determine
echo $LFS # /mnt/lfs


# 2.7. Mounting the New Partition

mkdir -pv $LFS

# Determine
ls $LFS
#  


# Do "mount -v -t ext4 /dev/sdb1 $LFS" in fstab
cp /etc/fstab{,.origin}
echo "/dev/sdb1 /mnt/lfs ext4 defaults 1 1" >> /etc/fstab

# mount -a
# or reboot to determine
reboot

# Terminal
ssh root@192.168.11.130 # instead of your own IP address

# Determine
ls $LFS
#  lost+found


#
# Chapter 3. Packages and Patches
#

# 3.1. Introduction

mkdir -v $LFS/sources

# Make this directory writable and sticky
chmod -v a+wt $LFS/sources
#  mode of '/mnt/lfs/sources' changed from 0755 (rwxr-xr-x) to 1777 (rwxrwxrwt)

  

# 3.2. All Packages
# 3.3. Needed Patches

# Get the packages for LFS
# http://www.linuxfromscratch.org/lfs/packages.html#packages
# http://ftp.osuosl.org/pub/lfs/lfs-packages/
# Execuate in terminal, and replace the IP address of yours
#scp lfs-packages-7.7-systemd.tar root@192.168.11.130:/mnt/lfs/
#下载lfs-packages-7.7-systemd.tar
cd $LFS
wget https://zhuanyejianshe.obs.cn-north-4.myhuaweicloud.com/chuangxinshijianke/lfs-packages-7.7-systemd.tar

#或者用下面链接，速度可能会慢些
#wget http://ftp.osuosl.org/pub/lfs/lfs-packages/lfs-packages-7.7-systemd.tar


#
# The bug is on the GCC 4.9 side, so either you need to patch it, 
# or build with -std=gnu++98 - then __GNUC_STDC_INLINE__ 
# will not be defined and it ought to compile fine.
#
# Now I modified this file in my own way. And maybe you'd better  
# fix it by a 'political correctness' way. 
#
# ps.: set a check-point

scp ~/openEuler/lfs-course/lfs-7.7-systemd/scripts/sample/patch/cfns-4.9.2.patch $LFS/


#
# Chapter 4. Final Preparations
#

# 4.1. Introduction

# 4.2. Creating a limited directory layout in LFS filesystem

# Creating the $LFS/tools Directory to separate the cross-compiler in 
# the chapter 6 from the other programs
mkdir -pv $LFS/tools

ln -sv $LFS/tools /

# 4.3. Adding the LFS User

groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs

passwd lfs # Input password by handwork
#  lfs@123

# Grant lfs full access to all directories under $LFS 
# by making lfs the directory owner

chown -v lfs $LFS/tools
#  changed ownership of '/mnt/lfs/tools' from root to lfs
chown -v lfs $LFS/sources
#  changed ownership of '/mnt/lfs/sources' from root to lfs

# Check
whoami # root

# Adding sudo for lfs, by Andrew

cp /etc/sudoers{,.origin}
nano +100 /etc/sudoers

#复制root这一行，将root替换为lfs，替换后结果如下：
#  root    ALL=(ALL)       ALL
#  lfs     ALL=(ALL)       ALL
#按Ctrl+o回车保存，Ctrl+x退出

#
# Login as user lfs!!!
#
su - lfs

# To test for getting password
sudo ls

# [lfs@localhost ~]$
# Determine
whoami # lfs

# 4.4. Setting Up the Environment

# While logged in as user lfs, issue the following command 
# to create a new .bash_profile
cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

# The new instance of the shell reads, and executes, the .bashrc file instead
cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/tools/bin:/bin:/usr/bin
export LFS LC_ALL LFS_TGT PATH
EOF

# To have the environment fully prepared for building the temporary tools, 
# source the just-created user profile.
source ~/.bash_profile

# lfs:~$ 
whoami # lfs

# To make sure that ...
# LFS=/mnt/lfs
# bash is the shell in use.
# sh is a symbolic link to bash.
# /usr/bin/awk is a symbolic link to gawk.
# /usr/bin/yacc is a symbolic link to bison or a small script that executes bison.

echo $LFS

# More determination

cat /etc/shells
#  /bin/sh
#  /bin/bash
#  /usr/bin/sh
#  /usr/bin/bash

ls -l /bin/sh
#  lrwxrwxrwx. 1 root root 4 Sep 27  2020 /bin/sh -> bash

echo $SHELL
#  /bin/bash

ls -l /usr/bin/awk
#  lrwxrwxrwx. 1 root root 4 Sep 27  2020 /usr/bin/awk -> gawk

ls -l /usr/bin/yacc
# -rwxr-xr-x. 1 root root 109128 Sep 27  2020 /usr/bin/yacc

whereis bison
#  bison: /usr/bin/bison /usr/share/bison

exit

reboot


# Chapter 5. Constructing a Temporary System

# 5.1. Introduction

# 5.2. Toolchain Technical Notes

# 5.3. General Compilation Instructions

# For each package:
# a. Using the tar program, extract the package to be built. In Chapter 5 and Chapter 6, ensure you are
#    the lfs user when extracting the package.
# b. Change to the directory created when the package was extracted.
# c. Follow the book's instructions for building the package.
# d. Change back to the sources directory.
# e. Delete the extracted source directory unless instructed otherwise.


# 此处开始第一遍编译，以lfs用户登录
ssh lfs@192.168.11.130 # instead of your own IP address

cd $LFS
tar xf ./lfs-packages-7.7-systemd.tar -C ./sources

#
# 5.4. Binutils-2.25 - Pass 1
#

cd $LFS/sources/
tar xjf binutils-2.25.tar.bz2
cd binutils-2.25
mkdir build && cd build

../configure --prefix=/tools --with-sysroot=$LFS --with-lib-path=/tools/lib --target=$LFS_TGT --disable-nls --disable-werror
make

# Architecture determination
uname -m # x86_64

# For x86_64 platform
mkdir -v /tools/lib && ln -sv lib /tools/lib64

make install

# Clean
cd $LFS/sources/
rm -rf binutils-2.25


#
# 5.5. GCC-4.9.2 - Pass 1
#

cd $LFS/sources/
tar xjf gcc-4.9.2.tar.bz2
cd gcc-4.9.2

# GCC now requires the GMP, MPFR and MPC packages.
tar -xf ../mpfr-3.1.2.tar.xz
mv -v mpfr-3.1.2 mpfr
tar -xf ../gmp-6.0.0a.tar.xz
mv -v gmp-6.0.0 gmp
tar -xf ../mpc-1.0.2.tar.gz
mv -v mpc-1.0.2 mpc

# The following command will change the location of GCC's default dynamic linker to use the one installed in /tools.
# It also removes /usr/include from GCC's include search path. Issue:
cat > ./gcc-lambda.sh << "EOF"
#!/bin/sh

for file in \
    $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h)
do
    cp -uv $file{,.orig}
    sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
        -e 's@/usr@/tools@g' $file.orig > $file
    echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
    touch $file.orig
done
EOF

# Just for character set issue if any.
##vim lambda.sh # :set ff=unix
sh gcc-lambda.sh

sed -i '/k prot/agcc_cv_libc_provides_ssp=yes' gcc/configure

cd $LFS/sources/gcc-4.9.2

cp $LFS/cfns-4.9.2.patch ./
patch -p1 < cfns-4.9.2.patch

mkdir -v build
cd build/
../configure --target=$LFS_TGT --prefix=/tools --with-sysroot=$LFS --with-newlib --without-headers --with-local-prefix=/tools --with-native-system-header-dir=/tools/include --disable-nls --disable-shared --disable-multilib --disable-decimal-float --disable-threads --disable-libatomic --disable-libgomp --disable-libitm --disable-libquadmath --disable-libsanitizer --disable-libssp --disable-libvtv --disable-libcilkrts --disable-libstdc++-v3 --enable-languages=c,c++

make
make install

# Clean
cd $LFS/sources/
rm -rf gcc-4.9.2


#
# 5.6. Linux-3.19 API Headers
#

cd $LFS/sources/
tar xJf linux-3.19.tar.xz
cd linux-3.19

make mrproper
make INSTALL_HDR_PATH=dest headers_install
cp -rv dest/include/* /tools/include

# Clean
cd $LFS/sources/
rm -rf linux-3.19


#
# 5.7. Glibc-2.21
#

cd $LFS/sources/
tar xJf glibc-2.21.tar.xz
cd glibc-2.21

##patch -p1 < ../glibc-2.21-fhs-1.patch

cat > ./glibc-lambda.sh << "EOF"
#!/bin/sh

if [ ! -r /usr/include/rpc/types.h ]; then
echo "ture"
fi
EOF
sh glibc-lambda.sh

# sudo: need lfs password
sudo ls /usr/include/rpc/ # To input the lfs password
sudo mv /usr/include/rpc/netdb.h{,.origin}
sudo cp -v $LFS/sources/glibc-2.21/sunrpc/rpc/*.h /usr/include/rpc/

cp sysdeps/i386/i686/multiarch/mempcpy_chk.S{,.origin}
sed -e '/ia32/s/^/1:/' -e '/SSE2/s/^1://' -i sysdeps/i386/i686/multiarch/mempcpy_chk.S

# Do these by lfs user
mkdir build && cd build

../configure --prefix=/tools --host=$LFS_TGT --build=$(../glibc-2.21/scripts/config.guess) --disable-profile --enable-kernel=2.6.32 --with-headers=/tools/include libc_cv_forced_unwind=yes libc_cv_ctors_header=yes libc_cv_c_cleanup=yes

make
make install

echo 'int main(){}' > dummy.c
$LFS_TGT-gcc dummy.c
readelf -l a.out | grep ': /tools'
#      [Requesting program interpreter: /tools/lib64/ld-linux-x86-64.so.2]
rm -v dummy.c a.out

# Clean
cd $LFS/sources/
rm -rf glibc-2.21


#
# 5.8. Libstdc++-4.9.2
#

cd $LFS/sources/
tar xjf gcc-4.9.2.tar.bz2
cd gcc-4.9.2

mkdir build && cd build

../libstdc++-v3/configure --host=$LFS_TGT --prefix=/tools --disable-multilib --disable-shared --disable-nls --disable-libstdcxx-threads --disable-libstdcxx-pch --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/4.9.2
make
make install

# Clean
cd $LFS/sources/
rm -rf gcc-4.9.2

#
# 5.9. Binutils-2.25 - Pass 2
#

cd $LFS/sources/
tar xjf binutils-2.25.tar.bz2
cd binutils-2.25
mkdir build && cd build

CC=$LFS_TGT-gcc AR=$LFS_TGT-ar RANLIB=$LFS_TGT-ranlib ../configure --prefix=/tools --disable-nls --disable-werror --with-lib-path=/tools/lib --with-sysroot

make
make install

make -C ld clean
make -C ld LIB_PATH=/usr/lib:/lib
cp -v ld/ld-new /tools/bin

# Clean
cd $LFS/sources/
rm -rf binutils-2.25


#
# 5.10. GCC-4.9.2 - Pass 2
#

cd $LFS/sources/
tar xjf gcc-4.9.2.tar.bz2
cd gcc-4.9.2

# This build of GCC now requires the full internal header.
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include-fixed/limits.h

# Once again, change the location of GCC's default dynamic linker to use the one installed in /tools.
cat > ./gcc-lambda.sh << "EOF"
#!/bin/sh

for file in \
    $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h)
do
    cp -uv $file{,.orig}
    sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
        -e 's@/usr@/tools@g' $file.orig > $file
    echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
    touch $file.orig
done
EOF

sh gcc-lambda.sh

# As in the first build of GCC it requires the GMP, MPFR and MPC packages. 
# Unpack the tarballs and move them into the required directory names:
tar -xf ../mpfr-3.1.2.tar.xz
mv -v mpfr-3.1.2 mpfr
tar -xf ../gmp-6.0.0a.tar.xz
mv -v gmp-6.0.0 gmp
tar -xf ../mpc-1.0.2.tar.gz
mv -v mpc-1.0.2 mpc

cd $LFS/sources/gcc-4.9.2

cp $LFS/cfns-4.9.2.patch ./
patch -p1 < cfns-4.9.2.patch

# Create a separate build directory again:
mkdir -v build
cd build/

CC=$LFS_TGT-gcc CXX=$LFS_TGT-g++ AR=$LFS_TGT-ar RANLIB=$LFS_TGT-ranlib ../configure --prefix=/tools --with-local-prefix=/tools --with-native-system-header-dir=/tools/include --enable-languages=c,c++ --disable-libstdcxx-pch --disable-multilib --disable-bootstrap --disable-libgomp

make
make install

ln -sv gcc /tools/bin/cc

# Check
echo 'int main(){}' > dummy.c
cc dummy.c 
readelf -l a.out | grep ': /tools'
#      [Requesting program interpreter: /tools/lib64/ld-linux-x86-64.so.2]
rm -v dummy.c a.out

# Clean
cd $LFS/sources/
rm -rf gcc-4.9.2


#
# 5.11. Tcl-8.6.3
#

cd $LFS/sources/
tar xzf tcl8.6.3-src.tar.gz 
cd tcl8.6.3/unix

./configure --prefix=/tools

make

##TZ=UTC make test # no necessary

make install

chmod -v u+w /tools/lib/libtcl8.6.so

make install-private-headers

ln -sv tclsh8.6 /tools/bin/tclsh

which tclsh # for check

# Clean
cd $LFS/sources/
rm -rf tcl8.6.3


#
# 5.12. Expect-5.45
#

cd $LFS/sources/
tar xzf expect5.45.tar.gz
cd expect5.45

cp -v configure{,.orig}
sed 's:/usr/local/bin:/bin:' configure.orig > configure

./configure --prefix=/tools --with-tcl=/tools/lib --with-tclinclude=/tools/include

make
##make test # no necessary
make SCRIPTS="" install

which expect # for check

# Clean
cd $LFS/sources/
rm -rf expect5.45


#
# 5.13. DejaGNU-1.5.2
#

cd $LFS/sources/
tar xzf dejagnu-1.5.2.tar.gz
cd dejagnu-1.5.2

./configure --prefix=/tools

make install
##make check # no necessary

which runtest # check

# Clean
cd $LFS/sources/
rm -rf dejagnu-1.5.2


#
# 5.14. Check-0.9.14
#

cd $LFS/sources/
tar xzf check-0.9.14.tar.gz
cd check-0.9.14

PKG_CONFIG= ./configure --prefix=/tools

make
##make check # no necessary
make install

which checkmk # check

# Clean
cd $LFS/sources/
rm -rf check-0.9.14


#
# 5.15. Ncurses-5.9
#

cd $LFS/sources/
tar xzf ncurses-5.9.tar.gz
cd ncurses-5.9

./configure --prefix=/tools --with-shared --without-debug --without-ada --enable-widec --enable-overwrite

make
make install

# Clean
cd $LFS/sources/
rm -rf ncurses-5.9


#
# 5.16. Bash-4.3.30
#

cd $LFS/sources/
tar xzf bash-4.3.30.tar.gz
cd bash-4.3.30

##patch -p1 < ../bash-4.3.30-upstream_fixes-1.patch 

./configure --prefix=/tools --without-bash-malloc

make
##make tests # no necessary
make install

ln -sv bash /tools/bin/sh

# Clean
cd $LFS/sources/
rm -rf bash-4.3.30


#
# 5.17. Bzip2-1.0.6
#

cd $LFS/sources/
tar xzf bzip2-1.0.6.tar.gz
cd bzip2-1.0.6

##patch -p1 < ../bzip2-1.0.6-install_docs-1.patch

make
make PREFIX=/tools install

which bzip2 # check

# Clean
cd $LFS/sources/
rm -rf bzip2-1.0.6


#
# 5.18. Coreutils-8.23
#

cd $LFS/sources/
tar xJf coreutils-8.23.tar.xz
cd coreutils-8.23

# Donot do this patch
##patch -p1 < ../coreutils-8.23-i18n-1.patch

./configure --prefix=/tools --enable-install-program=hostname

make
##make RUN_EXPENSIVE_TESTS=yes check
make install

# Clean
cd $LFS/sources/
rm -rf coreutils-8.23


#
# 5.19. Diffutils-3.3
#

cd $LFS/sources/
tar xJf diffutils-3.3.tar.xz
cd diffutils-3.3

./configure --prefix=/tools

make
##make check # no necessary
make install

which diff

# Clean
cd $LFS/sources/
rm -rf diffutils-3.3


#
# 5.20. File-5.22
#

cd $LFS/sources/
tar xzf file-5.22.tar.gz 
cd file-5.22

./configure --prefix=/tools

make
##make check
make install

which file

# Clean
cd $LFS/sources/
rm -rf file-5.22


#
# 5.21. Findutils-4.4.2
#

cd $LFS/sources/
tar xzf findutils-4.4.2.tar.gz 
cd findutils-4.4.2

./configure --prefix=/tools

make
##make check
make install

which find

# Clean
cd $LFS/sources/
rm -rf findutils-4.4.2


#
# 5.22. Gawk-4.1.1
#

cd $LFS/sources/
tar xJf gawk-4.1.1.tar.xz 
cd gawk-4.1.1

./configure --prefix=/tools

make
##make check
make install

which gawk

# Clean
cd $LFS/sources/
rm -rf gawk-4.1.1


#
# 5.23. Gettext-0.19.4
#

cd $LFS/sources/
tar xJf gettext-0.19.4.tar.xz 
cd gettext-0.19.4

cd gettext-tools/

EMACS="no" ./configure --prefix=/tools --disable-shared

make -C gnulib-lib
make -C intl pluralx.c
make -C src msgfmt
make -C src msgmerge
make -C src xgettext

cp -v src/{msgfmt,msgmerge,xgettext} /tools/bin

# Clean
cd $LFS/sources/
rm -rf gettext-0.19.4


#
# 5.24. Grep-2.21
#

cd $LFS/sources/
tar xJf grep-2.21.tar.xz 
cd grep-2.21

./configure --prefix=/tools

make
##make check
make install

which grep

# Clean
cd $LFS/sources/
rm -rf grep-2.21


#
# 5.25. Gzip
#

cd $LFS/sources/
tar xJf gzip-1.6.tar.xz 
cd gzip-1.6

./configure --prefix=/tools

make
##make check
make install

which gzip

# Clean
cd $LFS/sources/
rm -rf gzip-1.6


#
# 5.26. M4-1.4.17
#

cd $LFS/sources/
tar xJf m4-1.4.17.tar.xz 
cd m4-1.4.17

./configure --prefix=/tools

make
##make check
make install

which m4

# Clean
cd $LFS/sources/
rm -rf m4-1.4.17


#
# 5.27. Make-4.1
#

cd $LFS/sources/
tar xjf make-4.1.tar.bz2 
cd make-4.1

./configure --prefix=/tools --without-guile

make
##make check
make install

which make

# Clean
cd $LFS/sources/
rm -rf make-4.1


#
# 5.28. Patch-2.7.4
#

cd $LFS/sources/
tar xJf patch-2.7.4.tar.xz 
cd patch-2.7.4

./configure --prefix=/tools

make
##make check
make install

which patch

# Clean
cd $LFS/sources/
rm -rf patch-2.7.4


#
# 5.29. Perl-5.20.2
#

cd $LFS/sources/
tar xjf perl-5.20.2.tar.bz2 
cd perl-5.20.2

sh Configure -des -Dprefix=/tools -Dlibs=-lm

make

cp -v perl cpan/podlators/pod2man /tools/bin
mkdir -pv /tools/lib/perl5/5.20.2
cp -Rv lib/* /tools/lib/perl5/5.20.2

which perl

# Clean
cd $LFS/sources/
rm -rf perl-5.20.2


#
# 5.30. Sed-4.2.2
#

cd $LFS/sources/
tar xjf sed-4.2.2.tar.bz2 
cd sed-4.2.2

./configure --prefix=/tools

make
##make check
make install

which sed

# Clean
cd $LFS/sources/
rm -rf sed-4.2.2


#
# 5.31. Tar-1.28
#

cd $LFS/sources/
tar xJf tar-1.28.tar.xz 
cd tar-1.28

./configure --prefix=/tools

make
##make check
make install

which tar

# Clean
cd $LFS/sources/
rm -rf tar-1.28


#
# 5.32. Texinfo
#

cd $LFS/sources/
tar xJf texinfo-5.2.tar.xz 
cd texinfo-5.2

./configure --prefix=/tools

make
##make check
make install

which makeinfo

# Clean
cd $LFS/sources/
rm -rf texinfo-5.2


#
# 5.33. Util-linux-2.26
#

cd $LFS/sources/
tar xJf util-linux-2.26.tar.xz 
cd util-linux-2.26

./configure --prefix=/tools --without-python --disable-makeinstall-chown --without-systemdsystemunitdir PKG_CONFIG=""
make
make install

# Clean
cd $LFS/sources/
rm -rf util-linux-2.26


#
# 5.34. Xz-5.2.0
#

cd $LFS/sources/
tar xJf xz-5.2.0.tar.xz 
cd xz-5.2.0

./configure --prefix=/tools

make
##make check
make install

# Clean
cd $LFS/sources/
rm -rf xz-5.2.0


#
# 5.35. Stripping
#

# Not necessary, skip it.


#
# 5.36. Changing Ownership
#

# sudo it
sudo chown -Rv root:root $LFS/tools
exit


# Part III. Building the LFS System

# Chapter 6. Installing Basic System Software

# 6.1. Introduction

# 6.2. Preparing Virtual Kernel File Systems and etc.

ssh root@192.168.11.130 # instead of your own IP address

# Do it by root user
mkdir -pv $LFS/{dev,proc,sys,run}

# 6.2.1. Creating Initial Device Nodes

mknod -m 600 $LFS/dev/console c 5 1
mknod -m 666 $LFS/dev/null c 1 3

# 6.2.2. Mounting and Populating /dev

mount -v --bind /dev $LFS/dev

# 6.2.3. Mounting Virtual Kernel File Systems 

# Make a check-point: it doesn't work
##mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620

mount -v --bind /dev/pts $LFS/dev/pts -o gid=5,mode=620
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run

# For mount-and-populate later - step 1/2
cat > ~/mount-and-populate.sh << "EOF"
#!/bin/bash

# 6.2.2. Mounting and Populating /dev
mount -v --bind /dev $LFS/dev
# 6.2.3. Mounting Virtual Kernel File Systems 
mount -v --bind /dev/pts $LFS/dev/pts -o gid=5,mode=620
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run
EOF

##sh ~/mount-and-populate.sh


cat > dev-shm.sh << "EOF"
#!/bin/bash

if [ -h $LFS/dev/shm ]; then
        mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi
EOF

sh dev-shm.sh

# 6.3. Package Management

# 6.4. Entering the Chroot Environment

cat > ~/chroot-lfs.sh << "EOF"
#!/bin/bash

# 6.4. Entering the Chroot Environment
chroot "$LFS" /tools/bin/env -i \
    HOME=/root \
    TERM="$TERM" \
    PS1='\u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    /tools/bin/bash --login +h
EOF

# chroot - step 2/2
sh ~/chroot-lfs.sh

# 6.5. Creating Directories

cat > lambda-of-creating-directories.sh << "EOF"
#!/bin/bash

mkdir -pv /{bin,boot,etc/{opt,sysconfig},home,lib/firmware,mnt,opt}
mkdir -pv /{media/{floppy,cdrom},sbin,srv,var}
install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp
mkdir -pv /usr/{,local/}{bin,include,lib,sbin,src}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -v /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -v /usr/libexec
mkdir -pv /usr/{,local/}share/man/man{1..8}
case $(uname -m) in
x86_64) ln -sv lib /lib64
ln -sv lib /usr/lib64
ln -sv lib /usr/local/lib64 ;;
esac
mkdir -v /var/{log,mail,spool}
ln -sv /run /var/run
ln -sv /run/lock /var/lock
mkdir -pv /var/{opt,cache,lib/{color,misc,locate},local}
EOF

sh lambda-of-creating-directories.sh

# 6.6. Creating Essential Files and Symlinks

ln -sv /tools/bin/{bash,cat,echo,pwd,stty} /bin
ln -sv /tools/bin/perl /usr/bin
ln -sv /tools/lib/libgcc_s.so{,.1} /usr/lib
ln -sv /tools/lib/libstdc++.so{,.6} /usr/lib
sed 's/tools/usr/' /tools/lib/libstdc++.la > /usr/lib/libstdc++.la
ln -sv bash /bin/sh

# For historical reason
ln -sv /proc/self/mounts /etc/mtab

# Create the /etc/passwd file
cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:Daemon User:/dev/null:/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/var/run/dbus:/bin/false
systemd-bus-proxy:x:72:72:systemd Bus Proxy:/:/bin/false
systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/bin/false
systemd-journal-remote:x:74:74:systemd Journal Remote:/:/bin/false
systemd-journal-upload:x:75:75:systemd Journal Upload:/:/bin/false
systemd-network:x:76:76:systemd Network Management:/:/bin/false
systemd-resolve:x:77:77:systemd Resolver:/:/bin/false
systemd-timesync:x:78:78:systemd Time Synchronization:/:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
EOF

# Create the /etc/group file
cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
systemd-bus-proxy:x:72:
systemd-journal-gateway:x:73:
systemd-journal-remote:x:74:
systemd-journal-upload:x:75:
systemd-network:x:76:
systemd-resolve:x:77:
systemd-timesync:x:78:
nogroup:x:99:
users:x:999:
EOF

# To remove the “I have no name!” prompt
exec /tools/bin/bash --login +h

# Initialize the log files and give them proper permissions
touch /var/log/{btmp,lastlog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664 /var/log/lastlog
chmod -v 600 /var/log/btmp


### Do it as chrooted!

#
# 6.7. Linux-3.19 API Headers
#

cd /sources
tar xJf linux-3.19.tar.xz
cd linux-3.19

make mrproper # check-point for make error: Segmentation fault (core dumped)
make INSTALL_HDR_PATH=dest headers_install
find dest/include \( -name .install -o -name ..install.cmd \) -delete
cp -rv dest/include/* /usr/include

# Clean
cd /sources/
rm -rf linux-3.19


# 6.8. Man-pages-3.79

cd /sources
tar xJf man-pages-3.79.tar.xz
cd man-pages-3.79

make install

# Clean
cd /sources/
rm -rf man-pages-3.79


# 6.9. Glibc-2.21

cd /sources
tar xJf glibc-2.21.tar.xz
cd glibc-2.21

# 6.9.1. Installation of Glibc

patch -Np1 -i ../glibc-2.21-fhs-1.patch

sed -e '/ia32/s/^/1:/' -e '/SSE2/s/^1://' -i sysdeps/i386/i686/multiarch/mempcpy_chk.S

mkdir build
cd build/

../configure --prefix=/usr --disable-profile --enable-kernel=2.6.32 --enable-obsolete-rpc

make
##make check # Do it!

touch /etc/ld.so.conf
make install

cp -v /sources/glibc-2.21/nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd

install -v -Dm644 ../nscd/nscd.tmpfiles /usr/lib/tmpfiles.d/nscd.conf
install -v -Dm644 ../nscd/nscd.service /lib/systemd/system/nscd.service

make localedata/install-locales


# 6.9.2. Configuring Glibc

cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf
passwd: files
group: files
shadow: files
hosts: files dns myhostname
networks: files
protocols: files
services: files
ethers: files
rpc: files
# End /etc/nsswitch.conf
EOF

cd ..
tar -xf ../tzdata2015a.tar.gz

cat > install-timezone-data.sh << "EOF"
#!/bin/bash

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}
for tz in etcetera southamerica northamerica europe africa antarctica asia australasia backward pacificnew systemv; do
zic -L /dev/null -d $ZONEINFO -y "sh yearistype.sh" ${tz}
zic -L /dev/null -d $ZONEINFO/posix -y "sh yearistype.sh" ${tz}
zic -L leapseconds -d $ZONEINFO/right -y "sh yearistype.sh" ${tz}
done
cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO
EOF

sh install-timezone-data.sh

##tzselect
#  Need to answer a few questions about the location

# And the result is:
ln -sfv /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 6.9.3. Configuring the Dynamic Loader
cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib
EOF

cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf
EOF

mkdir -pv /etc/ld.so.conf.d

# Clean
cd /sources/
rm -rf glibc-2.21


#
# 6.10. Adjusting the Toolchain
#

mv -v /tools/bin/{ld,ld-old}
mv -v /tools/$(gcc -dumpmachine)/bin/{ld,ld-old}
mv -v /tools/bin/{ld-new,ld}
ln -sv /tools/bin/ld /tools/$(gcc -dumpmachine)/bin/ld

gcc -dumpspecs | sed -e 's@/tools@@g' -e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' -e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' > `dirname $(gcc --print-libgcc-file-name)`/specs

echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'

grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log
grep -B1 '^ /usr/include' dummy.log
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
grep "/lib.*/libc.so.6 " dummy.log
grep found dummy.log

rm -v dummy.c a.out dummy.log


#
# 6.11. Zlib-1.2.8
#

cd /sources
tar xJf zlib-1.2.8.tar.xz
cd zlib-1.2.8

./configure --prefix=/usr
make
##make check # Do it!
make install

mv -v /usr/lib/libz.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so

# Clean
cd /sources/
rm -rf zlib-1.2.8

#
# 6.12. File-5.22
#

cd /sources
tar xzf file-5.22.tar.gz
cd file-5.22

./configure --prefix=/usr
make
##make check # Do it!
make install

# Clean
cd /sources/
rm -rf file-5.22

#
# 6.13. Binutils-2.25
#

cd /sources
tar xjf binutils-2.25.tar.bz2
cd binutils-2.25
expect -c "spawn ls"
  
mkdir build
cd build

../configure --prefix=/usr --enable-shared --disable-werror
make tooldir=/usr
##make -k check # Do it!
make tooldir=/usr install

# Clean
cd /sources/
rm -rf binutils-2.25

#
# 6.14. GMP-6.0.0a
#

cd /sources
tar xJf gmp-6.0.0a.tar.xz
cd gmp-6.0.0

./configure --prefix=/usr --enable-cxx --docdir=/usr/share/doc/gmp-6.0.0a
make
make html

# Do it begin
##make check 2>&1 | tee gmp-check-log
##awk '/tests passed/{total+=$2} ; END{print total}' gmp-check-log
# Do it end.

make install
make install-html

# Clean
cd /sources/
rm -rf gmp-6.0.0


#
# 6.15. MPFR-3.1.2
#

cd /sources
tar xJf mpfr-3.1.2.tar.xz
cd mpfr-3.1.2

patch -Np1 -i ../mpfr-3.1.2-upstream_fixes-3.patch
./configure --prefix=/usr --enable-thread-safe --docdir=/usr/share/doc/mpfr-3.1.2
make
make html
##make check # Do it!
make install
make install-html

# Clean
cd /sources/
rm -rf mpfr-3.1.2


#
# 6.16. MPC-1.0.2
#

cd /sources
tar xzf mpc-1.0.2.tar.gz
cd mpc-1.0.2

./configure --prefix=/usr --docdir=/usr/share/doc/mpc-1.0.2
make
make html
##make check # Do it!
make install
make install-html

# Clean
cd /sources/
rm -rf mpc-1.0.2


#
# 6.17. GCC-4.9.2
#

cd /sources
tar xjf gcc-4.9.2.tar.bz2
cd gcc-4.9.2

cp /cfns-4.9.2.patch ./
patch -p1 < cfns-4.9.2.patch

mkdir build
cd build

SED=sed ../configure --prefix=/usr --enable-languages=c,c++ --disable-multilib --disable-bootstrap --with-system-zlib

make

# Do it begin
##ulimit -s 32768
##make -k check
##../contrib/test_summary
##../contrib/test_summary | grep -A7 Summ
# Do it end.

make install

ln -sv /usr/bin/cpp /lib
ln -sv gcc /usr/bin/cc

install -v -dm755 /usr/lib/bfd-plugins
ln -sfv /usr/libexec/gcc/$(gcc -dumpmachine)/4.9.2/liblto_plugin.so /usr/lib/bfd-plugins/

echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'
#      [Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]

grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log
grep -B4 '^ /usr/include' dummy.log
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
grep "/lib.*/libc.so.6 " dummy.log
grep found dummy.log
#  found ld-linux-x86-64.so.2 at /lib64/ld-linux-x86-64.so.2

rm -v dummy.c a.out dummy.log # no necessary

mkdir -pv /usr/share/gdb/auto-load/usr/lib
##ls /usr/lib/*gdb.py
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

# Clean
cd /sources/
rm -rf gcc-4.9.2


#
# 6.18. Bzip2-1.0.6
#

cd /sources
tar xzf bzip2-1.0.6.tar.gz
cd bzip2-1.0.6

patch -Np1 -i ../bzip2-1.0.6-install_docs-1.patch

sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile

make -f Makefile-libbz2_so
make clean
make
make PREFIX=/usr install

cp -v bzip2-shared /bin/bzip2
cp -av libbz2.so* /lib
ln -sv ../../lib/libbz2.so.1.0 /usr/lib/libbz2.so
rm -v /usr/bin/{bunzip2,bzcat,bzip2}
ln -sv bzip2 /bin/bunzip2
ln -sv bzip2 /bin/bzcat

# Clean
cd /sources/
rm -rf bzip2-1.0.6


#
# 6.19. Pkg-config-0.28
#

cd /sources
tar xzf pkg-config-0.28.tar.gz
cd pkg-config-0.28

./configure --prefix=/usr --with-internal-glib --disable-host-tool --docdir=/usr/share/doc/pkg-config-0.28

make
##make check # Do it!
make install

# Clean
cd /sources/
rm -rf pkg-config-0.28


#
# 6.20. Ncurses-5.9
#

cd /sources
tar xzf ncurses-5.9.tar.gz
cd ncurses-5.9

./configure --prefix=/usr --mandir=/usr/share/man --with-shared --without-debug --enable-pc-files --enable-widec

make
make install

mv -v /usr/lib/libncursesw.so.5* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libncursesw.so) /usr/lib/libncursesw.so

cat > ncurses4app.sh << "EOF"
#!/bin/bash

for lib in ncurses form panel menu ; do
rm -vf /usr/lib/lib${lib}.so
echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
ln -sfv lib${lib}w.a /usr/lib/lib${lib}.a
ln -sfv ${lib}w.pc /usr/lib/pkgconfig/${lib}.pc
done
ln -sfv libncurses++w.a /usr/lib/libncurses++.a
EOF

sh ncurses4app.sh

rm -vf /usr/lib/libcursesw.so
echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
ln -sfv libncurses.so /usr/lib/libcurses.so
ln -sfv libncursesw.a /usr/lib/libcursesw.a
ln -sfv libncurses.a /usr/lib/libcurses.a

mkdir -v /usr/share/doc/ncurses-5.9
cp -v -R doc/* /usr/share/doc/ncurses-5.9

# Clean
cd /sources/
rm -rf ncurses-5.9


#
# 6.21. Attr-2.4.47
#

cd /sources
tar xzf attr-2.4.47.src.tar.gz
cd attr-2.4.47

sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in
sed -i -e "/SUBDIRS/s|man2||" man/Makefile

./configure --prefix=/usr

make
##make -j1 tests root-tests # 29 commands (14 passed, 15 failed)

make install install-dev install-lib
chmod -v 755 /usr/lib/libattr.so

mv -v /usr/lib/libattr.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libattr.so) /usr/lib/libattr.so

# Clean
cd /sources/
rm -rf attr-2.4.47


#
# 6.22. Acl-2.2.52
#

cd /sources
tar xzf acl-2.2.52.src.tar.gz
cd acl-2.2.52

sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in
sed -i "s:| sed.*::g" test/{sbits-restore,cp,misc}.test
sed -i -e "/TABS-1;/a if (x > (TABS-1)) x = (TABS-1);" libacl/__acl_to_any_text.c

./configure --prefix=/usr --libexecdir=/usr/lib

make

##make -j1 tests # Note: When coreutils have built # Do it!

make install install-dev install-lib
chmod -v 755 /usr/lib/libacl.so

mv -v /usr/lib/libacl.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libacl.so) /usr/lib/libacl.so

# Clean
cd /sources/
rm -rf acl-2.2.52


#
# 6.23. Libcap-2.24
#

cd /sources
tar xJf libcap-2.24.tar.xz
cd libcap-2.24

make

make RAISE_SETFCAP=no prefix=/usr install
chmod -v 755 /usr/lib/libcap.so

mv -v /usr/lib/libcap.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libcap.so) /usr/lib/libcap.so

# Clean
cd /sources/
rm -rf libcap-2.24


#
# 6.24. Sed-4.2.2
#

cd /sources
tar xjf sed-4.2.2.tar.bz2
cd sed-4.2.2

./configure --prefix=/usr --bindir=/bin --htmldir=/usr/share/doc/sed-4.2.2

make
make html
##make check # Do it!
make install
make -C doc install-html

# Clean
cd /sources/
rm -rf sed-4.2.2


#
# 6.25. Shadow-4.2.1
#

# 6.25.1. Installation of Shadow

cd /sources
tar xJf shadow-4.2.1.tar.xz
cd shadow-4.2.1

sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /' {} \;

sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' -e 's@/var/spool/mail@/var/mail@' etc/login.defs

sed -i 's/1000/999/' etc/useradd

./configure --sysconfdir=/etc --with-group-name-max-length=32

make
make install
mv -v /usr/bin/passwd /bin

# 6.25.2. Configuring Shadow

# To enable shadowed passwords and group passwords:
pwconv
grpconv

# If you would prefer that the mailbox files are not created by useradd:
sed -i 's/yes/no/' /etc/default/useradd

# 6.25.3. Setting the root password
passwd root # by inputing handy, but no necessary.
#  Changing password for root
#  Enter the new password (minimum of 5 characters)
#  Please use a combination of upper and lower case letters and numbers.
#  New password:
#  Re-enter new password:
#  passwd: password changed.

# Clean
cd /sources/
rm -rf shadow-4.2.1


#
# 6.26. Psmisc-22.21
#

cd /sources
tar xzf psmisc-22.21.tar.gz
cd psmisc-22.21

./configure --prefix=/usr

make
make install
mv -v /usr/bin/fuser /bin
mv -v /usr/bin/killall /bin

# Clean
cd /sources/
rm -rf psmisc-22.21


#
# 6.27. Procps-ng-3.3.10
#

cd /sources
tar xJf procps-ng-3.3.10.tar.xz
cd procps-ng-3.3.10

./configure --prefix=/usr --exec-prefix= --libdir=/usr/lib --docdir=/usr/share/doc/procps-ng-3.3.10 --disable-static --disable-kill

make

# The test suite needs some custom modifications:
##sed -i -r 's|(pmap_initname)\\\$|\1|' testsuite/pmap.test/pmap.exp
##make check

make install
mv -v /usr/bin/pidof /bin
mv -v /usr/lib/libprocps.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so

# Clean
cd /sources/
rm -rf procps-ng-3.3.10


#
# 6.28. E2fsprogs-1.42.12
#

cd /sources
tar xzf e2fsprogs-1.42.12.tar.gz
cd e2fsprogs-1.42.12

sed -e '/int.*old_desc_blocks/s/int/blk64_t/' -e '/if (old_desc_blocks/s/super->s_first_meta_bg/desc_blocks/' -i lib/ext2fs/closefs.c
mkdir build
cd build

LIBS=-L/tools/lib CFLAGS=-I/tools/include PKG_CONFIG_PATH=/tools/lib/pkgconfig ../configure --prefix=/usr --bindir=/bin --with-root-prefix="" --enable-elf-shlibs --disable-libblkid --disable-libuuid --disable-uuidd --disable-fsck

make

# To set up and run the test suite we need to first link some libraries 
# from /tools/lib to a location where the test programs look:
##ln -sfv /tools/lib/lib{blk,uu}id.so.1 lib
##make LD_LIBRARY_PATH=/tools/lib check # Do it!

make install
make install-libs

chmod -v u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a

gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info

makeinfo -o doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info

# Clean
cd /sources/
rm -rf e2fsprogs-1.42.12


#
# 6.29. Coreutils-8.23
#

cd /sources
tar xJf coreutils-8.23.tar.xz
cd coreutils-8.23

patch -Np1 -i ../coreutils-8.23-i18n-1.patch
touch Makefile.in

FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr --enable-no-install-program=kill,uptime
make

# Do it begin
##make NON_ROOT_USERNAME=nobody check-root
##echo "dummy:x:1000:nobody" >> /etc/group
##chown -Rv nobody .
##su nobody -s /bin/bash -c "PATH=$PATH make RUN_EXPENSIVE_TESTS=yes check"
##sed -i '/dummy/d' /etc/group
# Do it end.

make install

mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin
mv -v /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin
mv -v /usr/bin/{rmdir,stty,sync,true,uname} /bin
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i s/\"1\"/\"8\"/1 /usr/share/man/man8/chroot.8

mv -v /usr/bin/{head,sleep,nice,test,[} /bin

# Clean
cd /sources/
rm -rf coreutils-8.23


#
# 6.30. Iana-Etc-2.30
#

cd /sources
tar xjf iana-etc-2.30.tar.bz2
cd iana-etc-2.30

make
make install

# Clean
cd /sources/
rm -rf iana-etc-2.30


#
# 6.31. M4-1.4.17
#

cd /sources
tar xJf m4-1.4.17.tar.xz
cd m4-1.4.17

./configure --prefix=/usr

make
##make check # Do it!
make install

# Clean
cd /sources/
rm -rf m4-1.4.17


#
# 6.32. Flex-2.5.39
#

cd /sources
tar xjf flex-2.5.39.tar.bz2
cd flex-2.5.39

sed -i -e '/test-bison/d' tests/Makefile.in
./configure --prefix=/usr --docdir=/usr/share/doc/flex-2.5.39

make
##make check # Do it!
make install

ln -sv flex /usr/bin/lex

# Clean
cd /sources/
rm -rf flex-2.5.39


#
# 6.33. Bison-3.0.4
#

cd /sources
tar xJf bison-3.0.4.tar.xz
cd bison-3.0.4

./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.0.4

make
##make check # Do it!
make install

# Clean
cd /sources/
rm -rf bison-3.0.4


#
# 6.34. Grep-2.21
#

cd /sources
tar xJf grep-2.21.tar.xz
cd grep-2.21

sed -i -e '/tp++/a if (ep <= tp) break;' src/kwset.c

./configure --prefix=/usr --bindir=/bin

make
##make check # Do it!
make install

# Clean
cd /sources/
rm -rf grep-2.21


#
# 6.35. Readline-6.3
#

cd /sources
tar xzf readline-6.3.tar.gz
cd readline-6.3

patch -Np1 -i ../readline-6.3-upstream_fixes-3.patch

sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
./configure --prefix=/usr --docdir=/usr/share/doc/readline-6.3

make SHLIB_LIBS=-lncurses
make SHLIB_LIBS=-lncurses install

mv -v /usr/lib/lib{readline,history}.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so
ln -sfv ../../lib/$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so

install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-6.3

# Clean
cd /sources/
rm -rf readline-6.3


# 6.36. Bash-4.3.30

cd /sources
tar xzf bash-4.3.30.tar.gz
cd bash-4.3.30

patch -Np1 -i ../bash-4.3.30-upstream_fixes-1.patch

./configure --prefix=/usr --bindir=/bin --docdir=/usr/share/doc/bash-4.3.30 --without-bash-malloc --with-installed-readline

make

# Do it begin
# To prepare the tests, ensure that the nobody user can write to the sources tree:
##chown -Rv nobody .
##su nobody -s /bin/bash -c "PATH=$PATH make tests"
# Do it end.

make install

# Run the newly compiled bash program (replacing the one that is currently being executed):
exec /bin/bash --login +h

# Clean
cd /sources/
rm -rf bash-4.3.30


# 6.37. Bc-1.06.95

cd /sources
tar xjf bc-1.06.95.tar.bz2
cd bc-1.06.95

patch -Np1 -i ../bc-1.06.95-memory_leak-1.patch

./configure --prefix=/usr --with-readline --mandir=/usr/share/man --infodir=/usr/share/info

make

# To test bc, run the commands below:
##echo "quit" | ./bc/bc -l Test/checklib.b

make install

# Clean
cd /sources/
rm -rf bc-1.06.95


# 6.38. Libtool-2.4.6

cd /sources
tar xJf libtool-2.4.6.tar.xz
cd libtool-2.4.6

./configure --prefix=/usr

make
##make check # 5 failures before installing automake # Do it!
make install

# Clean
cd /sources/
rm -rf libtool-2.4.6


# 6.39. GDBM-1.11

cd /sources
tar xzf gdbm-1.11.tar.gz
cd gdbm-1.11

./configure --prefix=/usr --enable-libgdbm-compat

make
##make check # Do it!
make install

# Clean
cd /sources/
rm -rf gdbm-1.11


# 6.40. Expat-2.1.0

cd /sources
tar xzf expat-2.1.0.tar.gz
cd expat-2.1.0

./configure --prefix=/usr

make
##make check # Do it!
make install
  
install -v -dm755 /usr/share/doc/expat-2.1.0
install -v -m644 doc/*.{html,png,css} /usr/share/doc/expat-2.1.0

# Clean
cd /sources/
rm -rf expat-2.1.0


# 6.41. Inetutils-1.9.2

cd /sources
tar xzf inetutils-1.9.2.tar.gz
cd inetutils-1.9.2

echo '#define PATH_PROCNET_DEV "/proc/net/dev"' >> ifconfig/system/linux.h

./configure --prefix=/usr --localstatedir=/var --disable-logger --disable-whois --disable-servers

make
##make check # Do it!
make install

mv -v /usr/bin/{hostname,ping,ping6,traceroute} /bin
mv -v /usr/bin/ifconfig /sbin

# Clean
cd /sources/
rm -rf inetutils-1.9.2


# 6.42. Perl-5.20.2

cd /sources
tar xjf perl-5.20.2.tar.bz2
cd perl-5.20.2

echo "127.0.0.1 localhost $(hostname)" > /etc/hosts

export BUILD_ZLIB=False
export BUILD_BZIP2=0

sh Configure -des -Dprefix=/usr -Dvendorprefix=/usr -Dman1dir=/usr/share/man/man1 -Dman3dir=/usr/share/man/man3 -Dpager="/usr/bin/less -isR" -Duseshrplib

make

##make -k test # Do it!

make install
unset BUILD_ZLIB BUILD_BZIP2

# Clean
cd /sources/
rm -rf perl-5.20.2


# 6.43. XML::Parser-2.44

cd /sources
tar xzf XML-Parser-2.44.tar.gz
cd XML-Parser-2.44

perl Makefile.PL

make
##make test # Do it!
make install

# Clean
cd /sources/
rm -rf XML-Parser-2.44


# 6.44. Autoconf-2.69

cd /sources
tar xJf autoconf-2.69.tar.xz
cd autoconf-2.69

./configure --prefix=/usr

make
##make check # One test fails due to changes in libtool-2.4.3 and later.
make install

# Clean
cd /sources/
rm -rf autoconf-2.69


# 6.45. Automake-1.15

cd /sources
tar xJf automake-1.15.tar.xz
cd automake-1.15

./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.15

make

sed -i "s:./configure:LEXLIB=/usr/lib/libfl.a &:" t/lex-{clean,depend}-cxx.sh
##make -j4 check

make install

# Clean
cd /sources/
rm -rf automake-1.15


# 6.46. Diffutils-3.3

cd /sources
tar xJf diffutils-3.3.tar.xz
cd diffutils-3.3

sed -i 's:= @mkdir_p@:= /bin/mkdir -p:' po/Makefile.in.in
./configure --prefix=/usr

make
##make check
make install

# Clean
cd /sources/
rm -rf diffutils-3.3


# 6.47. Gawk-4.1.1

cd /sources
tar xJf gawk-4.1.1.tar.xz
cd gawk-4.1.1

./configure --prefix=/usr

make
##make check
make install

# If desired, install the documentation:
mkdir -v /usr/share/doc/gawk-4.1.1
cp -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-4.1.1

# Clean
cd /sources/
rm -rf gawk-4.1.1


# 6.48. Findutils-4.4.2

cd /sources
tar xzf findutils-4.4.2.tar.gz
cd findutils-4.4.2

./configure --prefix=/usr --localstatedir=/var/lib/locate

make
##make check # optimize the source code to dispaly green "PASS"
make install

# Clean
cd /sources/
rm -rf findutils-4.4.2


# 6.49. Gettext-0.19.4

cd /sources
tar xJf gettext-0.19.4.tar.xz
cd gettext-0.19.4

./configure --prefix=/usr --docdir=/usr/share/doc/gettext-0.19.4

make
##make check
make install

# Clean
cd /sources/
rm -rf gettext-0.19.4


# 6.50. Intltool-0.50.2

cd /sources
tar xzf intltool-0.50.2.tar.gz
cd intltool-0.50.2

./configure --prefix=/usr

make
##make check
make install
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.50.2/I18NHOWTO

# Clean
cd /sources/
rm -rf intltool-0.50.2


# 6.51. Gperf-3.0.4

cd /sources
tar xzf gperf-3.0.4.tar.gz
cd gperf-3.0.4

./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.0.4

make
##make check
make install

# Clean
cd /sources/
rm -rf gperf-3.0.4


# 6.52. Groff-1.22.3

cd /sources
tar xzf groff-1.22.3.tar.gz
cd groff-1.22.3

PAGE=letter ./configure --prefix=/usr

make
make install

# Clean
cd /sources/
rm -rf groff-1.22.3


# 6.53. Xz-5.2.0

cd /sources
tar xJf xz-5.2.0.tar.xz
cd xz-5.2.0

./configure --prefix=/usr --docdir=/usr/share/doc/xz-5.2.0

make

##make check

# Install the package and make sure that all essential files are in the correct directory:

make install
mv -v /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin
mv -v /usr/lib/liblzma.so.* /lib
# Warning: Do not copy Chinese edition LFS-BOOK for this command due to full-width brackets
ln -svf ../../lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so

# Clean
cd /sources/
rm -rf xz-5.2.0


# 6.54. GRUB-2.02~beta2

cd /sources
tar xJf grub-2.02~beta2.tar.xz
cd grub-2.02~beta2

./configure --prefix=/usr --sbindir=/sbin --sysconfdir=/etc --disable-grub-emu-usb --disable-efiemu --disable-werror

make
make install

# Clean
cd /sources/
rm -rf grub-2.02~beta2


# 6.55. Less-458

cd /sources
tar xzf less-458.tar.gz
cd less-458

./configure --prefix=/usr --sysconfdir=/etc

make
make install

# Clean
cd /sources/
rm -rf less-458


# 6.56. Gzip-1.6

cd /sources
tar xJf gzip-1.6.tar.xz
cd gzip-1.6

./configure --prefix=/usr --bindir=/bin

make
##make check
make install

mv -v /bin/{gzexe,uncompress,zcmp,zdiff,zegrep} /usr/bin
mv -v /bin/{zfgrep,zforce,zgrep,zless,zmore,znew} /usr/bin

# Clean
cd /sources/
rm -rf gzip-1.6


# 6.57. IPRoute2-3.19.0

cd /sources
tar xJf iproute2-3.19.0.tar.xz
cd iproute2-3.19.0

sed -i '/^TARGETS/s@arpd@@g' misc/Makefile
sed -i /ARPD/d Makefile
sed -i 's/arpd.8//' man/man8/Makefile

make
make DOCDIR=/usr/share/doc/iproute2-3.19.0 install

# Clean
cd /sources/
rm -rf iproute2-3.19.0


# 6.58. Kbd-2.0.2

cd /sources
tar xzf kbd-2.0.2.tar.gz
cd kbd-2.0.2

patch -Np1 -i ../kbd-2.0.2-backspace-1.patch

# Warning: Do not copy Chinese edition LFS-BOOK for this command due to full-width brackets
sed -i 's/\(RESIZECONS_PROGS=\)yes/\1no/g' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in

PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr --disable-vlock

make
##make check
make install

mkdir -v /usr/share/doc/kbd-2.0.2
cp -R -v docs/doc/* /usr/share/doc/kbd-2.0.2

# Clean
cd /sources/
rm -rf kbd-2.0.2


# 6.59. Kmod-19

cd /sources
tar xJf kmod-19.tar.xz
cd kmod-19

./configure --prefix=/usr --bindir=/bin --sysconfdir=/etc --with-rootlibdir=/lib --with-xz --with-zlib

make
##make check
make install

cat > module-init-tools.sh << "EOF"
#!/bin/bash

for target in depmod insmod lsmod modinfo modprobe rmmod; do
ln -sv ../bin/kmod /sbin/$target
done
ln -sv kmod /bin/lsmod
EOF

sh module-init-tools.sh

# Clean
cd /sources/
rm -rf kmod-19


# 6.60. Libpipeline-1.4.0

cd /sources
tar xzf libpipeline-1.4.0.tar.gz
cd libpipeline-1.4.0

PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr

make
##make check
make install

# Clean
cd /sources/
rm -rf libpipeline-1.4.0


# 6.61. Make-4.1

cd /sources
tar xjf make-4.1.tar.bz2
cd make-4.1

./configure --prefix=/usr

make
##make check
make install

# Clean
cd /sources/
rm -rf make-4.1


# 6.62. Patch-2.7.4

cd /sources
tar xJf patch-2.7.4.tar.xz
cd patch-2.7.4

./configure --prefix=/usr

make
##make check
make install

# Clean
cd /sources/
rm -rf patch-2.7.4


# 6.63. Systemd-219

cd /sources
tar xJf systemd-219.tar.xz
cd systemd-219

# First, create a file to allow systemd to build when using Util-Linux built 
# in Chapter 5 and disable LTO by default:
cat > config.cache << "EOF"
KILL=/bin/kill
HAVE_BLKID=1
BLKID_LIBS="-lblkid"
BLKID_CFLAGS="-I/tools/include/blkid"
HAVE_LIBMOUNT=1
MOUNT_LIBS="-lmount"
MOUNT_CFLAGS="-I/tools/include/libmount"
cc_cv_CFLAGS__flto=no
EOF

# Additionally, fix a build error when using Util-Linux built in Chapter 5:
# Warning: Do not copy Chinese edition LFS-BOOK for this command due to full-width brackets
sed -i "s:blkid/::" $(grep -rl "blkid/blkid.h")

# Apply the following patch so that compat pkg-config files get installed 
# without installing compat libs which are useless on LFS:
patch -Np1 -i ../systemd-219-compat-1.patch

# Disable a test case that always fails:
sed -i "s:test/udev-test.pl ::g" Makefile.in

# Prepare systemd for compilation:
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --config-cache --with-rootprefix= --with-rootlibdir=/lib --enable-split-usr --disable-gudev --disable-firstboot --disable-ldconfig --disable-sysusers --without-python --docdir=/usr/share/doc/systemd-219 --with-dbuspolicydir=/etc/dbus-1/system.d --with-dbussessionservicedir=/usr/share/dbus-1/services --with-dbussystemservicedir=/usr/share/dbus-1/system-services

# Compile the package:
make LIBRARY_PATH=/tools/lib

# Install the package:
make LD_LIBRARY_PATH=/tools/lib install

# Move NSS libraries to /lib:
mv -v /usr/lib/libnss_{myhostname,mymachines,resolve}.so.2 /lib

# Remove an unnecessary directory:
rm -rfv /usr/lib/rpm

# Create the Sysvinit compatibility symlinks, so systemd is used as the default init system:
cat > sysvinit-compatibility.sh << "EOF"
#!/bin/bash

for tool in runlevel reboot shutdown poweroff halt telinit; do
ln -sfv ../bin/systemctl /sbin/${tool}
done
ln -sfv ../lib/systemd/systemd /sbin/init
EOF

sh sysvinit-compatibility.sh

# Remove a reference to a non-existent group and fix a configuration file 
# so it doesn't cause systemd-tmpfiles to fail at boot:
sed -i "s:0775 root lock:0755 root root:g" /usr/lib/tmpfiles.d/legacy.conf
sed -i "/pam.d/d" /usr/lib/tmpfiles.d/etc.conf

# Create the /etc/machine-id file needed by systemd-journald:
systemd-machine-id-setup
#  Initializing machine ID from KVM UUID.

# To test the results, issue:
##sed -i "s:minix:ext4:g" src/test/test-path-util.c
##make LD_LIBRARY_PATH=/tools/lib -k check

# Clean
cd /sources/
rm -rf systemd-219


# 6.64. D-Bus-1.8.16

cd /sources
tar xzf dbus-1.8.16.tar.gz
cd dbus-1.8.16

./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --docdir=/usr/share/doc/dbus-1.8.16 --with-console-auth-dir=/run/console

make
make install

# The shared library:
mv -v /usr/lib/libdbus-1.so.* /lib
# Warning: Do not copy Chinese edition LFS-BOOK for this command due to full-width brackets
ln -sfv ../../lib/$(readlink /usr/lib/libdbus-1.so) /usr/lib/libdbus-1.so

# Create a symlink, so that D-Bus and systemd can use the same machine-id file:
ln -sfv /etc/machine-id /var/lib/dbus

# Clean
cd /sources/
rm -rf dbus-1.8.16


# 6.65. Util-linux-2.26

cd /sources
tar -xJf util-linux-2.26.tar.xz
cd util-linux-2.26

mkdir -pv /var/lib/hwclock

./configure ADJTIME_PATH=/var/lib/hwclock/adjtime --docdir=/usr/share/doc/util-linux-2.26 --disable-chfn-chsh --disable-login --disable-nologin --disable-su --disable-setpriv --disable-runuser --disable-pylibmount --without-python

make
make install

# Clean
cd /sources/
rm -rf util-linux-2.26


# 6.66. Man-DB-2.7.1

cd /sources
tar xJf man-db-2.7.1.tar.xz
cd man-db-2.7.1

./configure --prefix=/usr --docdir=/usr/share/doc/man-db-2.7.1 --sysconfdir=/etc --disable-setuid --with-browser=/usr/bin/lynx --with-vgrind=/usr/bin/vgrind --with-grap=/usr/bin/grap

make
##make check
make install

sed -i "s:man root:root root:g" /usr/lib/tmpfiles.d/man-db.conf

# Clean
cd /sources/
rm -rf man-db-2.7.1


# 6.67. Tar-1.28

cd /sources
tar xJf tar-1.28.tar.xz
cd tar-1.28

FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr --bindir=/bin

make
##make check

# Install the package:
make install
make -C doc install-html docdir=/usr/share/doc/tar-1.28

# Clean
cd /sources/
rm -rf tar-1.28


# 6.68. Texinfo-5.2

cd /sources
tar xJf texinfo-5.2.tar.xz
cd texinfo-5.2

./configure --prefix=/usr

##make check
make install

make TEXMF=/usr/share/texmf install-tex

# Clean
cd /sources/
rm -rf texinfo-5.2


# 6.69. Vim-7.4

# 6.69.1. Installation of Vim

cd /sources
tar xjf vim-7.4.tar.bz2
cd vim74/

echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h

./configure --prefix=/usr
make
##make -j1 test
make install

# Ignoring begin 
##cat > vim4vi.sh << "EOF"
##ln -sv vim /usr/bin/vi
##for L in /usr/share/man/{,*/}man1/vim.1; do
##ln -sv vim.1 $(dirname $L)/vi.1
##done
##EOF
##sh vim4vi.sh
# Ignoring end

# By default, Vim's documentation is installed in /usr/share/vim. The following symlink allows the documentation
# to be accessed via /usr/share/doc/vim-7.4, making it consistent with the location of documentation for other
# packages:
ln -sv ../vim/vim74/doc /usr/share/doc/vim-7.4

# 6.69.2. Configuring Vim

# Configuring Vim
cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

set nocompatible
set backspace=2
syntax on
if (&term == "iterm") || (&term == "putty")
    set background=dark
endif

" End /etc/vimrc
EOF

# Documentation for other available options can be obtained 
# by running the following command:
##vim -c ':options'


# 6.70. About Debugging Symbols and Stripping

# 6.71. Stripping Again
# Ignore this stripping.

# 6.72. Cleaning Up

exit
reboot # and login by root user

ssh root@192.168.11.130 # instead of your own IP address

# mount-and-populate - step 1/2
sh ~/mount-and-populate.sh

cat > ~/chroot-lfs2.sh << "EOF"
#!/bin/bash

# 6.72. Cleaning Up
chroot "$LFS" /usr/bin/env -i \
    HOME=/root \
    TERM="$TERM" \
    PS1='\u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin \
    /bin/bash --login

EOF

# chroot2 - step 2/2
sh ~/chroot-lfs2.sh

# Ignore this cleaning up
##rm -rf /tmp/*
##rm -rf /tools

# Chapter 7. System Configuration and Bootscripts

# 7.1. Introduction

# 7.2. General Network Configuration

# 7.2.1. Network Interface Configuration Files

ip link
ifconfig
#  enp0s3    Link encap:Ethernet  HWaddr 08:00:27:35:4E:16
#            inet addr:10.0.2.15  Bcast:10.0.2.255  Mask:255.255.255.0
#            ......
# 
#  enp0s8    Link encap:Ethernet  HWaddr 08:00:27:31:6C:0A
#            inet addr:192.168.56.102  Bcast:192.168.56.255  Mask:255.255.255.0
#            ......
#
#  lo        Link encap:Local Loopback
#            inet addr:127.0.0.1  Mask:255.0.0.0
#            ......

# To creates a basic configuration file for Static IP setup:
cat > /etc/systemd/network/10-static-enp0s8.network << "EOF"
[Match]
Name=enp0s8
[Network]
Address=192.168.56.122/24
Gateway=192.168.56.1
DNS=192.168.56.1
EOF

# To creates a basic configuration file for DHCP setup:
##cat > /etc/systemd/network/10-dhcp-enp0s8.network << "EOF"
##[Match]
##Name=enp0s8
##[Network]
##DHCP=yes
##EOF

# 7.2.2. Creating the /etc/resolv.conf File

cat > /etc/resolv.conf << "EOF"
# Begin /etc/resolv.conf
nameserver 114.114.114.114

# End /etc/resolv.conf
EOF

##ln -sfv /run/systemd/resolve/resolv.conf /etc/resolv.conf # ???

# 7.2.3. Configuring the system hostname

echo "andrew" > /etc/hostname

# 7.2.4. Customizing the /etc/hosts File

cat > /etc/hosts << "EOF"
# Begin /etc/hosts (network card version)
127.0.0.1 localhost
::1 localhost
192.168.56.122 andrew@manjucc.com
# End /etc/hosts (network card version)
EOF


# 7.3. Overview of Device and Module Handling

# 7.4. Creating Custom Symlinks to Devices

# 7.5. System Time Configuration

# 7.6. Console Configuration

# 7.7. Configuring the System Locale

# 7.8. Creating the /etc/inputrc File

# 7.9. Creating the /etc/shells File

# 7.10 Configuration of systemd


#
# Chapter 8. Making the LFS System Bootable
#

# 8.1. Introduction

# 8.2. Creating the /etc/fstab File

cat > /etc/fstab << "EOF"
# Begin /etc/fstab
# file system    mount-point    type        options                dump    fsck
#                                                                          order
/dev/sdb1        /              ext4        defaults               1       1

# End /etc/fstab
EOF

# 8.3. Linux-3.19

# 8.3.1. Installation of the kernel

cd /sources
tar xJf linux-3.19.tar.xz
cd linux-3.19

make mrproper

# You can check the device on PCI bus to install driver
#lspci

# For SCSI Disk
#Linux Kernel Configuration
#    -> Device Drivers
#        -> SCSI device support
#            -> SCSI disk support

# For BusLogic
#Linux Kernel Configuration
#    -> Device Drivers
#        -> SCSI device support
#            -> SCSI low-level drivers
#                -> BusLogic SCSI support

# For LSI Logic
#Linux Kernel Configuration
#    -> Device Drivers 
#        -> Fusion MPT device support
#            -> Fusion MPT (base + ScsiHost) drivers 


# Refer to LFS-BOOK

# General setup --->
#   [*] open by fhandle syscalls [CONFIG_FHANDLE]
#   [ ] Auditing support [CONFIG_AUDIT]
#   [*] Control Group support [CONFIG_CGROUPS]
# Processor type and features --->
#   [*] Enable seccomp to safely compute untrusted bytecode [CONFIG_SECCOMP]
# Networking support --->
#   Networking options --->
#     <*> The IPv6 protocol [CONFIG_IPV6]
# Device Drivers --->
#   Generic Driver Options --->
#     [ ] Support for uevent helper [CONFIG_UEVENT_HELPER]
#     [*] Maintain a devtmpfs filesystem to mount at /dev [CONFIG_DEVTMPFS]
#     [ ] Fallback user-helper invocation for firmware loading [CONFIG_FW_LOADER_USER_HELPER]
# Firmware Drivers --->
#   [*] Export DMI identification via sysfs to userspace [CONFIG_DMIID]
# File systems --->
#   [*] Inotify support for userspace [CONFIG_INOTIFY_USER]
#   <*> Kernel automounter version 4 support (also supports v3) [CONFIG_AUTOFS4_FS]
#   Pseudo filesystems --->
#     [*] Tmpfs POSIX Access Control Lists [CONFIG_TMPFS_POSIX_ACL]
#     [*] Tmpfs extended attributes [CONFIG_TMPFS_XATTR]


##ls /sources/linux-3.19/arch/x86/configs/x86_64_defconfig

make menuconfig
#  saved to /sources/linux-3.19/.config

##make defconfig # the config file was saved to .config

make

make modules_install
#  ......
#  DEPMOD  3.19.0

# Some files need to be copied to the /boot directory
cp -v arch/x86/boot/bzImage /boot/vmlinuz-3.19-lfs-7.7-systemd
cp -v System.map /boot/System.map-3.19
cp -v .config /boot/config-3.19

# Install the documentation for the Linux kernel:
install -d /usr/share/doc/linux-3.19
cp -r Documentation/* /usr/share/doc/linux-3.19

# If the kernel source tree is going to be retained, 
# run chown -R 0:0 on the linux-3.19 directory 
# to ensure all files are owned by user root
cd /sources
chown -R 0:0 linux-3.19


# 8.3.2. Configuring Linux Module Load Order
## Ignore it.

# 8.4. Using GRUB to Set Up the Boot Process

# 8.4.1. Introduction
# Warning: Make a snapshot of system before implement any instructions in this section.

# 8.4.2. GRUB Naming Conventions

# For example, partition sda1 is (hd0,1) to GRUB and sdb3 is (hd1,3).
#                                   | |
#                   hard drive number |
#                                     partition number
#
# The hard drive number starts from zero, but the partition number starts from one for
# normal partitions and five for extended partitions.
# 
# And GRUB does not consider CD-ROM drives to be hard drives.

# 8.4.3. Setting Up the Configuration

grub-install /dev/sdb
#  Installing for i386-pc platform.
#  Installation finished. No error reported.


# 8.4.4. Creating the GRUB Configuration File

grub-mkconfig -o /boot/grub/grub.cfg
#  Generating grub configuration file ...
#  Found linux image: /boot/vmlinuz-3.19-lfs-7.7-systemd
#  done


# Chapter 9. The End

# 9.1. The End

# Create an /etc/os-release file required by systemd
cat > /etc/os-release << "EOF"
NAME="Linux From Scratch"
VERSION="7.7-systemd"
ID=lfs
PRETTY_NAME="Linux From Scratch 7.7-systemd"
EOF

# For compatibility with non systemd branch
echo 7.7-systemd > /etc/lfs-release

# Show the status of your new system with respect to the Linux Standards Base(LSB)
cat > /etc/lsb-release << "EOF"
DISTRIB_ID="Linux From Scratch"
DISTRIB_RELEASE="7.7-systemd"
DISTRIB_CODENAME="Andrew"
DISTRIB_DESCRIPTION="Linux From Scratch"
EOF


# 9.2. Get Counted

# 9.3. Rebooting the System

# First exit from the chroot environment
logout

# Then unmount the virtual file systems and LFS file system itself
umount -v $LFS/dev/pts
umount -v $LFS/dev
umount -v $LFS/run
umount -v $LFS/proc
umount -v $LFS/sys
umount -v $LFS


echo "Now please refer to 实验指导手册 to update the content of file /boot/grub2/grub.cfg" # Part 4.6.2

reboot # and log in by root user

# Update /boot/grub2/grub.cfg

ssh root@192.168.11.130 # instead of your own IP address

cd /mnt/lfs/boot/grub
cp -v grub.cfg{,.origin}
cat grub.cfg
# or
# vi grub.cfg


# Copy part begin
# ### BEGIN /etc/grub.d/10_linux ###
# menuentry 'GNU/Linux' --class gnu-linux --class gnu --class os $menuentry_id_option 'gnulinux-simple-cc2f6dd5-caf9-4e91-9eac-edbfa484a4bc' {
# 	load_video
# 	insmod gzio
# 	insmod part_msdos 
# 	insmod ext2
# 	set root='hd1,msdos1'
# 	if [ x$feature_platform_search_hint = xy ]; then
# 	  search --no-floppy --fs-uuid --set=root --hint-bios=hd1,msdos1 --hint-efi=hd1,msdos1 --hint-baremetal=ahci1,msdos1  cc2f6dd5-caf9-4e91-9eac-edbfa484a4bc
# 	else
# 	  search --no-floppy --fs-uuid --set=root cc2f6dd5-caf9-4e91-9eac-edbfa484a4bc
# 	fi
# 	echo	'Loading Linux 3.19-lfs-7.7-systemd ...'
# 	linux	/boot/vmlinuz-3.19-lfs-7.7-systemd root=/dev/sdb1 ro  
# }
# Copy part end

cd /boot/grub2/
cp -v grub.cfg{,.origin}
vi grub.cfg

# Paste after
# ### BEGIN /etc/grub.d/10_linux ###

# !!! ATTENTION !!!
# Modify 'GNU/Linux' -> 'GNU/Linux {your-number}-{your-name}'



# Now, reboot the system
reboot

# Chose 'GNU/Linux, with Linux 3.19-lfs-7.7-systemd'
# Username: root
# Password: Lfs@123 # The password of lfs user which set in Chapter 4
#           or `passwd root` in "6.25.3. Setting the root password"

uname -m 
uname -r
cat /etc/os-release 
hostname

# 9.4. What Now?

