PROJECT_DIR=$(pwd)
PRODUCT_NAME=
BUILD_DIR=
DIFFERENT_DIR=
SHARE_DIR=$PROJECT_DIR/share

CROSS_COMPILE=
PREFIX=


# FLAG
MK_LIBGPIOD=0
PUSH_BIN=0

function print_usage
{
    echo "app print_usage"
}

function _check_list_
{
    CROSS_COMPILE=/home/turboyan/work/Lichee/toolchain/gcc-linaro-6.5.0-2018.12-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-
    BUILD_DIR=$PROJECT_DIR/build/THub1
    PREFIX=$PROJECT_DIR/bin/THub1
    MK_LIBGPIOD=0
}

function __mk_bin__
{
    cd $BUILD_DIR
    mkdir -p $PREFIX
    make -j16 CROSS_COMPILE=$CROSS_COMPILE PREFIX=$PREFIX
    make clean
}

function __push_bin__
{
    cd $PREFIX
    cp tuapp /mnt/nastftp/
}

function __mk_lib__
{
    if [ $MK_LIBGPIOD -eq 1 ]
    then
        export CC=${CROSS_COMPILE}gcc
        export CXX=${CROSS_COMPILE}g++
        export LD=${CROSS_COMPILE}ld
        export AR=${CROSS_COMPILE}ar
        export AS=${CROSS_COMPILE}as
        export RANLIB=${CROSS_COMPILE}ranlib
        export STRIP=${CROSS_COMPILE}strip
        cd $SHARE_DIR/libgpiod-1.6.3
        ./autogen.sh
        ./configure --enable-tools=no --host=arm-linux-gnueabihf --prefix=$PREFIX/libgpiod/
        make
        make install
    fi
}

function __main__
{
    _check_list_
    __mk_lib__
    __mk_bin__

    if [ $PUSH_BIN -eq 1 ]
    then
        __push_bin__
    fi
}

#至少输入一个参数
if [ $# -lt 1 ]; then
        echo -e "${KYELLOW}Please input the correct parameters, at least 1 parameters!${KRST}"
        print_usage
        exit 1
fi

ARGS=`getopt --options n:,s,c,h,p,o:,r: --long help,risky:,name:,clean,svn_ignore,push -n "${PROG}" -- "$@"`
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
        -n|--name)
            PRODUCT_NAME=$2
            shift 2
            ;;
        -p|--push)
            PUSH_BIN=1
            shift
            ;;
        --)
            case "$2" in
                *)
                    shift
                    break
                    ;;
            esac
            ;;
        *)
            echo "Internal error!"
            exit 1
    esac
done

__main__