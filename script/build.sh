#!/bin/bash

## DIR
ROOT_DIR=../
SCRIPT_DIR=$ROOT_DIR/script
PREFIX_DIR=$ROOT_DIR/output

UBOOT_DIR=$ROOT_DIR/Lichee-Pi_u-boot
LINUX_DIR=$ROOT_DIR/linux
ROOTFS_DIR=$ROOT_DIR/buildroot-2017.08.1

TOOLCHAIN_DIR=$ROOT_DIR/toolchain
TOOLCHAIN=$TOOLCHAIN_DIR/gcc-linaro-6.5.0-2018.12-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-
CC="${TOOLCHAIN}gcc"
CPP="${TOOLCHAIN}g++"

## FLAG
MK_UBOOT=0
MK_LINUX=0
MK_ROOTFS=1

## VARIABLE


## COLOR
KBLACK="\e[30m"
KRED="\e[31m"
KGREEN="\e[32m"
KYELLOW="\e[33m"
KBLUE="\e[34m"
KPURPLE="\e[35m"
KCYAN="\e[36m"  #青色
KWHITE="\e[37m"
KRST="\e[0m"    #重置默认
KBOLD="\e[1m"   #加粗
KUNDERLINE="\e[4m"  #下划线

function _verify_allow_
{
    read -p "输入y继续, 输入其他则退出脚本:" input
    case $input in
        [yY] ) return 1;;
        * ) echo -e "$KBOLD$KRED==操作无法继续，终止脚本==$KRST"; exit 1;;
    esac
}

function _mk_uboot_
{
    if [ $MK_UBOOT -ne 1 ]; then
        return 0
    fi
    echo -e "$KBLUE start make uboot $KRST"
    _verify_allow_
    cd $UBOOT_DIR
}

function _mk_linux_
{
    if [ $MK_LINUX -ne 1 ]; then
        return 0
    fi
    echo -e "$KBLUE start make linux kernel $KRST"

    # echo -e "$KBLUE 开始安装依赖 $KRST"
    # _verify_allow_
    # sudo apt install make gcc flex bison libssl-dev bc kmod

    export PREFIX=$PREFIX_DIR/linux
    cd $LINUX_DIR
    make ARCH=arm licheepi_zero_defconfig
    make -j16 ARCH=arm CROSS_COMPILE=$TOOLCHAIN
}

function _mk_rootfs_
{
    if [ $MK_ROOTFS -ne 1 ]; then
        return 0
    fi
    echo -e "$KBLUE start make rootfs $KRST"
    _verify_allow_
}

function __main__
{
    # 编译工具链管理
    if [ ! -d "$ROOT_DIR/toolchain/gcc-linaro-6.5.0-2018.12-x86_64_arm-linux-gnueabihf/" ];then
        echo -e "$KYELLOW 编译工具链未解压,是否解压?$KRST"
        _verify_allow_
        cd $TOOLCHAIN_DIR
        tar -xvf gcc-linaro-6.5.0-2018.12-x86_64_arm-linux-gnueabihf.tar.xz
    else
        echo -e "$KBLUE Tool chain exist!$KRST"
    fi

    _mk_uboot_
    _mk_linux_
    _mk_rootfs_
}

__main__