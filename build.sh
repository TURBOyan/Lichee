#!/bin/bash

## DIR
ROOT_DIR=$(pwd)
SCRIPT_DIR=$ROOT_DIR/script
PREFIX_DIR=$ROOT_DIR/publish

UBOOT_DIR=$ROOT_DIR/Lichee-Pi_u-boot
LINUX_DIR=$ROOT_DIR/linux
ROOTFS_DIR=$ROOT_DIR/buildroot-2024.02.5
APP_DIR=$ROOT_DIR/app/TBaseCode
LIBS_DIR=$ROOT_DIR/libs_src

TOOLCHAIN_DIR=$ROOT_DIR/toolchain
TOOLCHAIN=$TOOLCHAIN_DIR/gcc-linaro-6.5.0-2018.12-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-
CC="${TOOLCHAIN}gcc"
CPP="${TOOLCHAIN}g++"


## FLAG
PULL_CODE=0
PUSH_BIN=0
MK_UBOOT=0
MK_KERNEL=0
MK_ROOTFS=0
MK_APP=0

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

    if [ $PULL_CODE -eq 1 ]; then
        git submodule update --init --progress --depth 1 Lichee-Pi_u-boot/
    fi

    export PREFIX=$PREFIX_DIR/uboot
    export ARCH=arm
    export CROSS_COMPILE=$TOOLCHAIN
    cd $UBOOT_DIR

    make LicheePi_Zero_defconfig
    make menuconfig
    make -j16 ARCH=arm CROSS_COMPILE=$TOOLCHAIN

    mkdir -p $PREFIX_DIR/uboot/
    cp $UBOOT_DIR/u-boot-sunxi-with-spl.bin $PREFIX_DIR/uboot/

    if [ $PUSH_BIN -eq 1 ]; then
        cp $PREFIX_DIR/uboot/* /mnt/nastftp/
    fi
}

function _mk_kernel_
{
    if [ $MK_KERNEL -ne 1 ]; then
        return 0
    fi
    echo -e "$KBLUE start make linux kernel $KRST"

    if [ $PULL_CODE -eq 1 ]; then
        git submodule update --init --progress --depth 1 linux/
    fi

    # echo -e "$KBLUE 开始安装依赖 $KRST"
    # _verify_allow_
    # sudo apt install make gcc flex bison libssl-dev bc kmod

    export PREFIX=$PREFIX_DIR/kernel
    export ARCH=arm
    export CROSS_COMPILE=$TOOLCHAIN
    cd $LINUX_DIR
    # make ARCH=arm licheepi_zero_turbo_defconfig
    make ARCH=arm licheepi_zero_turbo_spiflash_defconfig
    make menuconfig
    make savedefconfig
    make -j16 ARCH=arm CROSS_COMPILE=$TOOLCHAIN
    make modules ARCH=arm CROSS_COMPILE=$TOOLCHAIN
    make dtbs ARCH=arm CROSS_COMPILE=$TOOLCHAIN


    mkdir -p $PREFIX_DIR/kernel/
    cp $LINUX_DIR/arch/arm/boot/zImage $PREFIX_DIR/kernel/
    cp $LINUX_DIR/arch/arm/boot/dts/sun8i-v3s-licheepi-zero.dtb $PREFIX_DIR/kernel/
    cp $LINUX_DIR/arch/arm/boot/dts/sun8i-v3s-licheepi-zero-dock.dtb $PREFIX_DIR/kernel/
    cp $PREFIX_DIR/kernel/* /mnt/nastftp/
}

function _mk_rootfs_
{
    if [ $MK_ROOTFS -ne 1 ]; then
        return 0
    fi
    echo -e "$KBLUE start make rootfs $KRST"

    export PREFIX=$PREFIX_DIR/linux
    export ARCH=arm
    export CROSS_COMPILE=$TOOLCHAIN
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    cd $ROOTFS_DIR
    make ARCH=arm licheepi_zero_turboyan_defconfig
    make menuconfig
    make savedefconfig
    make busybox-menuconfig
    make busybox-update-config
    make -j

    mkdir -p $PREFIX_DIR/rootfs/
    cp $ROOTFS_DIR/output/images/rootfs.tar.gz $PREFIX_DIR/rootfs/
    cp $PREFIX_DIR/rootfs/* /mnt/nastftp/
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
    ./configure --host=arm-linux-gnueabihf --prefix=$PREFIX_DIR/lirc --with-driver=userspace
    make -j8
    make install
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

function _mk_app_
{
    if [ $MK_APP -ne 1 ]; then
        return 0
    fi
    echo -e "$KBLUE start make app $KRST"
    cd $APP_DIR
    ./build.sh -n THub1 -p
}

function __clean__
{
    cd $UBOOT_DIR
    make clean
    rm -rf $PREFIX_DIR/uboot/

    cd $LINUX_DIR
    make clean
    rm -rf $PREFIX_DIR/kernel/

    cd $ROOTFS_DIR
    make clean
    rm -rf $PREFIX_DIR/rootfs/
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

    _mk_app_
    _mk_uboot_
    _mk_kernel_
    _mk_rootfs_

    _mk_lirc_
    _mk_evtest_
}

#至少输入一个参数
if [ $# -lt 1 ]; then
        echo -e "${KYELLOW}Please input the correct parameters, at least 1 parameters!${KRST}"
        print_usage
        exit 1
fi

ARGS=`getopt --options h,p,c,m: --long help,pull,make:,name:,clean,push -n "${PROG}" -- "$@"`
if [ $? != 0 ]; then
    echo
    print_usage
    exit 1
fi

for v in ${ARGS}; do
    if [[ ${v} == -* ]] ; then
        continue
    fi
#    echo "@@@@@@@ $v"
    # 非 "-" 或者 "--" 开头的参数
    case "$v" in
    esac
done


#将规范化后的命令行参数分配至位置参数（$1,$2,...)
eval set -- "${ARGS}"

while true
do
    case "$1" in
        -h|--help)
            print_usage
            exit
            ;;
        -m|--make)
            case "$2" in
                app)
                    MK_APP=1
                    shift
                    break
                ;;
                uboot)
                    MK_UBOOT=1
                    shift
                    break
                ;;
                kernel)
                    MK_KERNEL=1
                    shift
                    break
                ;;
                rootfs)
                    MK_ROOTFS=1
                    shift
                    break
                ;;
                lirc)
                    MK_LIRC=1
                    shift
                    break
                ;;
                evtest)
                    MK_EVTEST=1
                    shift
                    break
                ;;
            esac
        ;;
        --pull)
            PULL_CODE=1;
            break;
            ;;
        -p|--push)
            PUSH_BIN=1;
            break;
            ;;
        -c|--clean)
            __clean__
            exit
            ;;
        *)
            echo "Internal error!"
            exit 1
            ;;
    esac
done

__main__
