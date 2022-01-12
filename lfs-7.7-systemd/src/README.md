## Scripts of building LFS

| No. | File Name | Application                                     | User                   | How to do it               |
|-----|-----------|-------------------------------------------------|------------------------|----------------------------|
|  1  |part-0.sh  |Create VM,<br/> install OS,<br/> setup sdb       |root of host            |Step by Step                |
|  2  |part-1.sh  |Install apps,<br/> setup $LFS,<br/> get material |root of host            |Step by Step                |
|  3  |part-2.sh  |Build toolchain and temporary tools              |lfs  of host            |Step by Step,<br/>sh this.sh|
|  4  |part-3.0.sh|Preparing for installing basic system software   |root of host            |Step by Step                |
|  5  |part-3.1.sh|Installing basic system software                 |chrooted    root of host|Step by Step,<br/>sh this.sh|
|  6  |part-3.2.sh|System Configuration and Bootscripts             |chrooted(2) root of host|Step by Step                |
|  7  |part-3.3.sh|Building kernel                                  |chrooted(2) root of host|Step by Step                |
|  8  |part-3.4.sh|Setup GRUB of LFS_TGT_SYS                        |chrooted(2) root of host|Step by Step                |
|  9  |part-3.5.sh|Update GRUB config of host and reboot the system |root of host            |Step by Step                |
|  10 |part-3.6.sh|Entering LFS_TGT_SYS                             |root of LFS_TGT_SYS     |Step by Step                |
|  11 |part-4.sh  |Pull Request (PR)                                |root of host            |Step by Step                |

## Users and passwords

| No. | User Name                     | Instance of Password | When was it created           |
|-----|-------------------------------|----------------------|-------------------------------|
|  1  |root of host                   |Euler@123             |Installing openEuler           |
|  2  |lfs of host                    |Lfs@123               |Creating lfs user              |
|  3  |root of target <br/>LFS system |Lfs@12#$              |Installing shadow in chapter 6 |

Note: LFS here means LFS target system.
