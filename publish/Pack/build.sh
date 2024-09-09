#!/bin/bash

PWD=$(pwd)

TMP_DIR=tmp
UBOOT_DIR=src/uboot
KERNEL_DIR=src/kernel
ROOTFS_DIR=src/rootfs

UBOOT_IMG=u-boot-sunxi-with-spl.bin
KERNEL_DTS_IMG=sun8i-v3s-licheepi-zero.dtb
JFFS2_IMG=jffs2.img

OUTPUT_IMG=digicap.dav


function _verify_allow_
{
    read -p "输入y继续, 输入其他则退出脚本:" input
    case $input in
        [yY] ) return 1;;
        * ) echo -e "$KBOLD$KRED==操作无法继续，终止脚本==$KRST"; exit 1;;
    esac
}

function __main__
{
    mkdir -p $TMP_DIR/rootfs
    tar zxvf $ROOTFS_DIR/rootfs.tar.gz -C $TMP_DIR/rootfs
    fakeroot mkfs.jffs2 -s 0x100 -e 0x10000 -p 0x9F0000 -d $TMP_DIR/rootfs -o $TMP_DIR/$JFFS2_IMG

    dd if=/dev/zero of=$TMP_DIR/$OUTPUT_IMG bs=1M count=16
    dd if=$UBOOT_DIR/$UBOOT_IMG of=$TMP_DIR/$OUTPUT_IMG bs=1K conv=notrunc
    dd if=$KERNEL_DIR/$KERNEL_DTS_IMG of=$TMP_DIR/$OUTPUT_IMG bs=1K seek=1024  conv=notrunc
    dd if=$KERNEL_DIR/zImage of=$TMP_DIR/$OUTPUT_IMG bs=1K seek=1088  conv=notrunc
    dd if=$TMP_DIR/$JFFS2_IMG of=$TMP_DIR/$OUTPUT_IMG  bs=1K seek=6208  conv=notrunc

    cp $TMP_DIR/$OUTPUT_IMG /mnt/nastftp/
    mv $TMP_DIR/$OUTPUT_IMG $PWD
    rm -rf $TMP_DIR

    _verify_allow_
    sunxi-fel.exe -p spiflash-write 0 digicap.dav
}

__main__