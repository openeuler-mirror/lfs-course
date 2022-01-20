#
# Part IV. Pull Request (PR)
#

#
# 在这一部分，我们提交 PR。
#
# 1. 您可以以 root 用户登录宿主系统，如：
#    ssh root@192.168.56.102 # instead of your own IP address
#    然后将作业以 PR 的形式提交。
# 2. 您也可以利用其他 git 工具将作业以 PR 的形式提交。
# 3. 本实验以第一种情况为例进行讲解。
#

whoami # root

cd # /root

cat > ~/tf/part-4.txt << "EOF"
        __        __   _
        \ \      / /__| | ___ ___  _ __ ___   ___
         \ \ /\ / / _ \ |/ __/ _ \| '_ ` _ \ / _ \
          \ V  V /  __/ | (_| (_) | | | | | |  __/
           \_/\_/ \___|_|\___\___/|_| |_| |_|\___|

                           _
                          | |_ ___
                          | __/ _ \
                          | || (_) |
                           \__\___/

             ____            _       ___ __     __
            |  _ \ __ _ _ __| |_    |_ _|\ \   / /
            | |_) / _` | '__| __|    | |  \ \ / /
            |  __/ (_| | |  | |_     | |   \ V /
            |_|   \__,_|_|   \__|   |___|   \_/

EOF

cat ~/tf/part-4.txt 1>&2

#
# 请按照视频的指导提交 PR，此处仅列出一些关键步骤以供参考。
#

# 假设您的 git 账号已经正确配置：
##git config --global user.name "your-user-name"
##git config --global user.email "your-email-address-on-gitee"
# 注意要配置成签署 CLA 的用户名和邮箱。

# 我们以 https://gitee.com/glibc/lanzhou_university_2021 仓库为例，
# 假设 https://gitee.com/openeuler-practice-courses/lfs-course
# 已经被 fork 到一个名为 glibc 的账号下。
git clone https://gitee.com/glibc/lanzhou_university_2021.git
cd lanzhou_university_2021/

git status
#On branch master
#Your branch is up to date with 'origin/master'.

git checkout -b 101010-zhaoxiaohu
#Switched to a new branch '101010-zhaoxiaohu'

git status
#On branch 101010-zhaoxiaohu
#nothing to commit, working tree clean

mkdir 101010-zhaoxiaohu
cd 101010-zhaoxiaohu

#
# 在这里用 scp 命令将实验截图从本地 PC 上传至此目录，
# 比方说是 1.jpg。
#
# 然后可以用以下命令增加此图片：
# git add ../101010-zhaoxiaohu/1.jpg
# 或者（其中 -s 选项是添加 signed-off-by 信息，-a 是提交本次所有修改）：
git commit -s -a
git push --set-upstream origin 101010-zhaoxiaohu # The first push

#
# 比如在这里继续上传截图，然后继续提交 commit 和 push。
# 最好是一次性提交相关联的更新，这样使 commit 不至重复和分不清主题，
# 这里只是举例。
#

# 然后继续提交
git commit -s -a
git push origin 101010-zhaoxiaohu

git log # Review if anything

# 然后在您自己的 gitee 页面提交 PR。
# 在本例中，注意需提交新建的 101010-zhaoxiaohu 分支。



