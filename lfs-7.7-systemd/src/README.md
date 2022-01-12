## Scripts of building LFS

| No. | Script File | Task                                            | User                   | How to do it                   |
|-----|-------------|-------------------------------------------------|------------------------|--------------------------------|
|  1  |part-0.sh    |Prepare the host system                          |root of host            |Step by Step                    |
|  2  |part-1.sh    |Prepare the development environment for lfs user |root of host            |Step by Step                    |
|  3  |part-2.sh    |Build toolchain and temporary tools as lfs user  |lfs  of host            |Step by Step, or<br/>sh thisfile|
|  4  |part-3.0.sh  |Prepare for installing basic system software     |root of host            |Step by Step                    |
|  5  |part-3.1.sh  |Install basic system software as chrooted root   |chrooted    root of host|Step by Step, or<br/>sh thisfile|
|  6  |part-3.2.sh  |System configuration and bootscripts             |chrooted(2) root of host|Step by Step                    |
|  7  |part-3.3.sh  |Build kernel                                     |chrooted(2) root of host|Step by Step                    |
|  8  |part-3.4.sh  |Setup GRUB of LFS_TGT_SYS                        |chrooted(2) root of host|Step by Step                    |
|  9  |part-3.5.sh  |Update GRUB config of host                       |root of host            |Step by Step                    |
|  10 |part-3.6.sh  |Enter the target LFS system                      |root of LFS_TGT_SYS     |Step by Step                    |
|  11 |part-4.sh    |Pull Request (PR)                                |root of host            |Step by Step                    |

## Users and passwords

| No. | Who the user is          | What password (for instance) | When was it created           |
|-----|--------------------------|------------------------------|-------------------------------|
|  1  |root of host              |Euler@123                     |Installing openEuler           |
|  2  |lfs of host               |Lfs@123                       |Creating lfs user              |
|  3  |root of target LFS system |Lfs@12#$                      |Installing shadow in chapter 6 |
