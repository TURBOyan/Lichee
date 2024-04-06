注意点：
    1、所有操作均在root权限下执行！！！！解压rootfs.tar时，需要在root用户下，否则会报EXT4-fs (mmcblk0p2): couldn‘t mount RDWR because of unsupported optional features (400)
    2、用户名：root，密码licheepi
    3、编译linux需要使用gcc9低版本
    4、编译linux，报错bc命令找不到，需要sudo apt install bc
    5、TF卡分区：
        （1）boot分区：32M，FAT16格式
        （2）rootfs分区：EXT4格式


参考教程：https://blog.csdn.net/Code_MoMo/article/details/104623584