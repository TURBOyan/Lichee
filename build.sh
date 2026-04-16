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
PACK_DIR=$ROOT_DIR/Pack

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
MK_PACK=0
INTERACTIVE_CONFIG=0

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
    if [ $INTERACTIVE_CONFIG -ne 1 ]; then
        echo -e "$KYELLOW 非交互模式，自动继续执行$KRST"
        return 0
    fi

    read -p "输入y继续, 输入其他则退出脚本:" input
    case $input in
        [yY] ) return 1;;
        * ) echo -e "$KBOLD$KRED==操作无法继续，终止脚本==$KRST"; exit 1;;
    esac
}

function _run_config_command_
{
    if [ $INTERACTIVE_CONFIG -eq 1 ]; then
        "$@"
        return $?
    fi

    echo -e "$KYELLOW 非交互模式，跳过配置命令: $*$KRST"
}

function print_usage
{
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -h, --help              显示帮助信息"
    echo "      --pull              先执行 repo sync"
    echo "  -p, --push              编译完成后推送产物"
    echo "  -c, --clean             清理构建产物"
    echo "  -m, --make <target>     构建目标: app|uboot|kernel|rootfs|lirc|evtest|pack"
    echo "  -i, --interactive       启用交互式配置(默认)"
    echo "  -n, --non-interactive   禁用交互式配置，沿用已有配置参数"
}

function _sync_repo_sources_
{
    if [ $PULL_CODE -ne 1 ]; then
        return 0
    fi

    if [ ! -d "$ROOT_DIR/.repo/" ]; then
        echo -e "$KBOLD$KRED==当前目录不是repo工作区，无法执行repo sync==$KRST"
        exit 1
    fi

    if ! command -v repo >/dev/null 2>&1; then
        echo -e "$KBOLD$KRED==未找到repo命令，请先安装repo工具==$KRST"
        exit 1
    fi

    echo -e "$KBLUE start repo sync source tree $KRST"
    repo sync
}

function _mk_uboot_
{
    if [ $MK_UBOOT -ne 1 ]; then
        return 0
    fi
    echo -e "$KBLUE start make uboot $KRST"

    export PREFIX=$PREFIX_DIR/uboot
    export ARCH=arm
    export CROSS_COMPILE=$TOOLCHAIN
    cd $UBOOT_DIR

    make LicheePi_Zero_defconfig
    _run_config_command_ make menuconfig
    make -j16 ARCH=arm CROSS_COMPILE=$TOOLCHAIN

    mkdir -p $PREFIX_DIR/uboot/
    cp $UBOOT_DIR/u-boot-sunxi-with-spl.bin $PREFIX_DIR/uboot/

    if [ $PUSH_BIN -eq 1 ]; then
        for file in $PREFIX_DIR/uboot/*; do
            exchange -p $file
        done
    fi
}

function _mk_kernel_
{
    if [ $MK_KERNEL -ne 1 ]; then
        return 0
    fi
    echo -e "$KBLUE start make linux kernel $KRST"

    # echo -e "$KBLUE 开始安装依赖 $KRST"
    # _verify_allow_
    # sudo apt install make gcc flex bison libssl-dev bc kmod

    export PREFIX=$PREFIX_DIR/kernel
    export ARCH=arm
    export CROSS_COMPILE=$TOOLCHAIN
    cd $LINUX_DIR
    # make ARCH=arm licheepi_zero_turbo_defconfig
    make ARCH=arm licheepi_zero_turbo_spiflash_defconfig
    _run_config_command_ make menuconfig
    _run_config_command_ make savedefconfig
    make -j16 ARCH=arm CROSS_COMPILE=$TOOLCHAIN
    make modules ARCH=arm CROSS_COMPILE=$TOOLCHAIN
    make dtbs ARCH=arm CROSS_COMPILE=$TOOLCHAIN


    mkdir -p $PREFIX_DIR/kernel/
    cp $LINUX_DIR/arch/arm/boot/zImage $PREFIX_DIR/kernel/
    cp $LINUX_DIR/arch/arm/boot/dts/sun8i-v3s-licheepi-zero.dtb $PREFIX_DIR/kernel/
    cp $LINUX_DIR/arch/arm/boot/dts/sun8i-v3s-licheepi-zero-dock.dtb $PREFIX_DIR/kernel/

    if [ $PUSH_BIN -eq 1 ]; then
        for file in $PREFIX_DIR/kernel/*; do
            exchange -p $file
        done
    fi
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
    _run_config_command_ make menuconfig
    _run_config_command_ make savedefconfig
    _run_config_command_ make busybox-menuconfig
    _run_config_command_ make busybox-update-config
    make -j

    mkdir -p $PREFIX_DIR/rootfs/
    cp $ROOTFS_DIR/output/images/rootfs.tar.gz $PREFIX_DIR/rootfs/
    
    if [ $PUSH_BIN -eq 1 ]; then
        for file in $PREFIX_DIR/rootfs/*; do
            exchange -p $file
        done
    fi
}

function _mk_lirc_
{
    if [ $MK_LIRC -ne 1 ]; then
        return 0
    fi
    echo -e "$KBLUE start make lirc $KRST"
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
    ac_cv_file__dev_input=no HAVE_WORKING_POLL=yes ./configure \
        --host=arm-linux-gnueabihf \
        --prefix=$PREFIX_DIR/lirc \
        --enable-devinput=no
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
    if [ $PUSH_BIN -eq 1 ]; then
        ./build.sh --name THub1 --push
    else
        ./build.sh --name THub1
    fi
}

function _mk_pack_
{
    if [ $MK_PACK -ne 1 ]; then
        return 0
    fi

    echo -e "$KBLUE start pack image $KRST"
    cd "$PACK_DIR"

    if [ $PUSH_BIN -eq 1 ]; then
        ./build.sh --get --push
    else
        ./build.sh --get
    fi
}

function _need_toolchain_
{
    if [ $MK_APP -eq 1 ] || [ $MK_UBOOT -eq 1 ] || [ $MK_KERNEL -eq 1 ] || [ $MK_ROOTFS -eq 1 ] || [ $MK_LIRC -eq 1 ] || [ $MK_EVTEST -eq 1 ]; then
        return 0
    fi

    return 1
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

    if [ -d "$LIBS_DIR/lirc" ]; then
        cd "$LIBS_DIR/lirc"
        make clean >/dev/null 2>&1 || true
    fi
    rm -rf $PREFIX_DIR/lirc/

    if [ -d "$LIBS_DIR/evtest" ]; then
        cd "$LIBS_DIR/evtest"
        make clean >/dev/null 2>&1 || true
    fi
    rm -rf $PREFIX_DIR/evtest/

    if [ -f "$APP_DIR/build.sh" ]; then
        cd "$APP_DIR"
        ./build.sh --clean
    fi

    if [ -f "$PACK_DIR/build.sh" ]; then
        cd "$PACK_DIR"
        ./build.sh --clean
    fi
}

function __main__
{
    _sync_repo_sources_

    if _need_toolchain_; then
        # 编译工具链管理
        if [ ! -d "$ROOT_DIR/toolchain/gcc-linaro-6.5.0-2018.12-x86_64_arm-linux-gnueabihf/" ];then
            echo -e "$KYELLOW 编译工具链未解压,是否解压?$KRST"
            _verify_allow_
            cd $TOOLCHAIN_DIR
            tar -xvf gcc-linaro-6.5.0-2018.12-x86_64_arm-linux-gnueabihf.tar.xz
        else
            echo -e "$KBLUE Tool chain exist!$KRST"
        fi
    fi

    _mk_app_
    _mk_uboot_
    _mk_kernel_
    _mk_rootfs_

    _mk_lirc_
    _mk_evtest_
    _mk_pack_
}

#至少输入一个参数
if [ $# -lt 1 ]; then
        echo -e "${KYELLOW}Please input the correct parameters, at least 1 parameters!${KRST}"
        print_usage
        exit 1
fi

ARGS=`getopt --options h,p,c,m:in --long help,pull,make:,name:,clean,push,interactive,non-interactive -n "${PROG}" -- "$@"`
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
                    shift 2
                ;;
                uboot)
                    MK_UBOOT=1
                    shift 2
                ;;
                kernel)
                    MK_KERNEL=1
                    shift 2
                ;;
                rootfs)
                    MK_ROOTFS=1
                    shift 2
                ;;
                lirc)
                    MK_LIRC=1
                    shift 2
                ;;
                evtest)
                    MK_EVTEST=1
                    shift 2
                ;;
                pack)
                    MK_PACK=1
                    shift 2
                ;;
            esac
        ;;
        --pull)
            PULL_CODE=1;
            shift
            ;;
        -p|--push)
            PUSH_BIN=1;
            shift
            ;;
        -i|--interactive)
            INTERACTIVE_CONFIG=1
            shift
            ;;
        -c|--clean)
            __clean__
            exit
            ;;
		--)
            break
            ;;
        *)
            echo "Internal error!"
            exit 1
            ;;
    esac
done

__main__
