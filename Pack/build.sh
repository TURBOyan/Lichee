#!/bin/bash

PWD=$(pwd)

TMP_DIR=$PWD/tmp
UBOOT_DIR=$PWD/src/uboot
KERNEL_DIR=$PWD/src/kernel
ROOTFS_DIR=$PWD/src/rootfs

UBOOT_IMG=u-boot-sunxi-with-spl.bin
DTB_IMG=sun8i-v3s-licheepi-zero.dtb
KERNEL_IMG=zImage
JFFS2_IMG=jffs2.img

OUTPUT_IMG=digicap.dav

## flag
GET_PUBLISH=0
WRITE_UBOOT=0
WRITE_DTB=0
WRITE_KERNEL=0
WRITE_ROOTFS=0
WRITE_DIGICAP=0

function print_usage
{
    echo print_usage
}

function _verify_allow_
{
    read -p "输入y继续, 输入其他则退出:" input
    case $input in
        [yY] ) return 1;;
        * ) echo -e "$KBOLD$KRED==操作无法继续，终止脚本==$KRST"; exit 1;;
    esac
}

function __get_publish__
{
    if [ $GET_PUBLISH -ne 1 ]; then
        return 0
    fi

    cd $PWD
    cp ../publish/uboot/* $UBOOT_DIR
    cp ../publish/kernel/* $KERNEL_DIR
    cp ../publish/rootfs/rootfs.tar.gz $ROOTFS_DIR
}

function __mk_image__
{
    mkdir -p $TMP_DIR/rootfs
    tar zxvf $ROOTFS_DIR/rootfs.tar.gz -C $TMP_DIR/rootfs
    fakeroot mkfs.jffs2 -s 0x100 -e 0x10000 -p 0x9F0000 -d $TMP_DIR/rootfs -o $TMP_DIR/$JFFS2_IMG

    dd if=/dev/zero of=$TMP_DIR/$OUTPUT_IMG bs=1M count=16
    dd if=$UBOOT_DIR/$UBOOT_IMG of=$TMP_DIR/$OUTPUT_IMG bs=1K conv=notrunc
    dd if=$KERNEL_DIR/$DTB_IMG of=$TMP_DIR/$OUTPUT_IMG bs=1K seek=1024  conv=notrunc
    dd if=$KERNEL_DIR/$KERNEL_IMG of=$TMP_DIR/$OUTPUT_IMG bs=1K seek=1088  conv=notrunc
    dd if=$TMP_DIR/$JFFS2_IMG of=$TMP_DIR/$OUTPUT_IMG  bs=1K seek=6208  conv=notrunc

    cp $TMP_DIR/$OUTPUT_IMG /mnt/nastftp/
    mv $TMP_DIR/$OUTPUT_IMG $PWD
}

function __flashwrite__
{
    
    if [ $WRITE_UBOOT -eq 1 ]; then
        echo "start write uboot to spi flash"
        _verify_allow_

        # uboot分区固定1M
        dd if=/dev/zero of=tmp.bin bs=1M count=1
        dd if=$UBOOT_DIR/$UBOOT_IMG of=tmp.bin bs=1k conv=notrunc
        sunxi-fel.exe -p spiflash-write 0 tmp.bin
        rm tmp.bin
    fi

    if [ $WRITE_DTB -eq 1 ]; then
        echo "start write dtb to spi flash"
        _verify_allow_

        # dtb分区固定64K
        dd if=/dev/zero of=tmp.bin bs=1K count=64
        dd if=$KERNEL_DIR/$DTB_IMG of=tmp.bin bs=1k conv=notrunc
        sunxi-fel.exe -p spiflash-write 0x100000 tmp.bin
        rm tmp.bin
    fi

    if [ $WRITE_KERNEL -eq 1 ]; then
        echo "start write zImage to spi flash"
        _verify_allow_

        # zImage分区固定5M
        dd if=/dev/zero of=tmp.bin bs=1M count=5
        dd if=$KERNEL_DIR/$KERNEL_IMG of=tmp.bin bs=1k conv=notrunc
        sunxi-fel.exe -p spiflash-write 0x110000 tmp.bin
        rm tmp.bin
    fi

    if [ $WRITE_ROOTFS -eq 1 ]; then
        echo "start write rootfs to spi flash"
        _verify_allow_

        #剩下全部给rootfs
        sunxi-fel.exe -p spiflash-write 0x610000 $TMP_DIR/$JFFS2_IMG
    fi

    if [ $WRITE_DIGICAP -eq 1 ]; then
        echo "start write digicap.dav to spi flash"
        _verify_allow_
        sunxi-fel.exe -p spiflash-write 0 $TMP_DIR/$OUTPUT_IMG
    fi
    
}

function __main__
{
    __get_publish__
    __mk_image__

    __flashwrite__
}

#至少输入一个参数
if [ $# -lt 1 ]; then
        echo -e "${KYELLOW}Please input the correct parameters, at least 1 parameters!${KRST}"
        print_usage
        exit 1
fi

ARGS=`getopt --options h,g,w: --long help,get,write: -n "${PROG}" -- "$@"`
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
        -g|--get)
            GET_PUBLISH=1;
            shift
            ;;
        -w|--write)
            case "$2" in
                uboot)
                    WRITE_UBOOT=1
                    shift
                    break
                    ;;
                dtb)
                    WRITE_DTB=1
                    shift
                    break
                    ;;
                kernel)
                    WRITE_KERNEL=1
                    shift
                    break
                    ;;
                rootfs)
                    WRITE_ROOTFS=1
                    shift
                    break
                    ;;
                all)
                    WRITE_UBOOT=1
                    WRITE_DTB=1
                    WRITE_KERNEL=1
                    WRITE_ROOTFS=1
                    shift
                    break
                    ;;
                digicap)
                    WRITE_DIGICAP=1
                    shift
                    break
                    ;;
                *)
                    shift
                    break
                    ;;
            esac
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