#!/bin/bash

## DIR
ROOT_DIR=$(pwd)
SCRIPT_DIR=$ROOT_DIR/script
PREFIX_DIR=$ROOT_DIR/publish

UBOOT_DIR=$ROOT_DIR/Lichee-Pi_u-boot
LINUX_DIR=$ROOT_DIR/linux
ROOTFS_DIR=$ROOT_DIR/buildroot-2017.08.1
LIBS_DIR=$ROOT_DIR/libs_src

TOOLCHAIN_DIR=$ROOT_DIR/toolchain
TOOLCHAIN=$TOOLCHAIN_DIR/gcc-linaro-6.5.0-2018.12-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-
CC="${TOOLCHAIN}gcc"
CPP="${TOOLCHAIN}g++"

## FLAG
MK_UBOOT=0
MK_LINUX=0
MK_ROOTFS=0

MK_LIRC=0
MK_EVTEST=0

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
    export ARCH=arm
    export CROSS_COMPILE=$TOOLCHAIN
    cd $LINUX_DIR
    # make ARCH=arm licheepi_zero_defconfig
    # make -j16 ARCH=arm CROSS_COMPILE=$TOOLCHAIN
}

function _mk_lirc_
{
    if [ $MK_LIRC -ne 1 ]; then
        return 0
    fi
    echo -e "$KBLUE start make lirc $KRST"

    git submodule update --init --progress libs_src/lirc
    cd $LIBS_DIR/lirc

    export CC=${TOOLCHAIN}gcc
    export CXX=${TOOLCHAIN}g++
    export LD=${TOOLCHAIN}ld
    export AR=${TOOLCHAIN}ar
    export AS=${TOOLCHAIN}as
    export RANLIB=${TOOLCHAIN}ranlib
    export STRIP=${TOOLCHAIN}strip

    ./autogen.sh
    autoreconf -i
    ./configure --host=arm-linux-gnueabihf
    make -j8
    make install DESTDIR=$PREFIX_DIR/lirc
    make clean
    cd -
}

function _mk_evtest_
{
    if [ $MK_EVTEST -ne 1 ]; then
        return 0
    fi
    echo -e "$KBLUE start make evtest $KRST"

    git submodule update --init --progress libs_src/evtest
    cd $LIBS_DIR/evtest
    export CC=${TOOLCHAIN}gcc
    export CXX=${TOOLCHAIN}g++
    export LD=${TOOLCHAIN}ld
    export AR=${TOOLCHAIN}ar
    export AS=${TOOLCHAIN}as
    export RANLIB=${TOOLCHAIN}ranlib
    export STRIP=${TOOLCHAIN}strip

    ./autogen.sh
    ./configure --host=arm-linux-gnueabihf
    make -j8
    make install DESTDIR=$PREFIX_DIR/evtest
    make clean
    cd -
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

    _mk_lirc_
    _mk_evtest_
}

__main__
