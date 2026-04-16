#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

TMP_DIR=$SCRIPT_DIR/tmp
UBOOT_DIR=$SCRIPT_DIR/src/uboot
KERNEL_DIR=$SCRIPT_DIR/src/kernel
ROOTFS_DIR=$SCRIPT_DIR/src/rootfs
PUBLISH_DIR=$REPO_ROOT/publish
OUTPUT_DIR=$SCRIPT_DIR

UBOOT_IMG=u-boot-sunxi-with-spl.bin
DTB_IMG=sun8i-v3s-licheepi-zero.dtb
KERNEL_IMG=zImage
JFFS2_IMG=jffs2.img

OUTPUT_IMG=digicap.dav
ROOTFS_ARCHIVE=$ROOTFS_DIR/rootfs.tar.gz
ROOTFS_CONTENT_DIR=$ROOTFS_DIR/rootfs
PUSH_DIR=/mnt/nastftp/

## flag
GET_PUBLISH=0
PUSH_OUTPUT=0
WRITE_UBOOT=0
WRITE_DTB=0
WRITE_KERNEL=0
WRITE_ROOTFS=0
WRITE_DIGICAP=0

function print_usage
{
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -h, --help              显示帮助信息"
    echo "  -g, --get               从仓库 publish 目录同步最新产物"
    echo "  -p, --push              打包完成后复制到 $PUSH_DIR"
    echo "  -w, --write <target>    烧写目标: uboot|dtb|kernel|rootfs|digicap|all"
    echo "  -c, --clean             清理临时产物"
}

function _verify_allow_
{
    read -p "输入y继续, 输入其他则退出:" input
    case $input in
        [yY] ) return 1;;
        * ) echo -e "$KBOLD$KRED==操作无法继续，终止脚本==$KRST"; exit 1;;
    esac
}

function _require_file_
{
    if [ ! -f "$1" ]; then
        echo "Required file not found: $1"
        exit 1
    fi
}

function _prepare_rootfs_
{
    rm -rf "$TMP_DIR/rootfs"
    mkdir -p "$TMP_DIR/rootfs"

    if [ -f "$ROOTFS_ARCHIVE" ]; then
        tar zxf "$ROOTFS_ARCHIVE" -C "$TMP_DIR/rootfs"
        return 0
    fi

    if [ -d "$ROOTFS_CONTENT_DIR" ]; then
        cp -a "$ROOTFS_CONTENT_DIR/." "$TMP_DIR/rootfs/"
        return 0
    fi

    echo "Rootfs source not found: $ROOTFS_ARCHIVE or $ROOTFS_CONTENT_DIR"
    exit 1
}

function __get_publish__
{
    if [ $GET_PUBLISH -ne 1 ]; then
        return 0
    fi

    mkdir -p "$UBOOT_DIR" "$KERNEL_DIR" "$ROOTFS_DIR"

    if [ -d "$PUBLISH_DIR/uboot" ]; then
        cp "$PUBLISH_DIR/uboot/"* "$UBOOT_DIR/" 2>/dev/null
    fi

    if [ -d "$PUBLISH_DIR/kernel" ]; then
        cp "$PUBLISH_DIR/kernel/"* "$KERNEL_DIR/" 2>/dev/null
    fi

    if [ -f "$PUBLISH_DIR/rootfs/rootfs.tar.gz" ]; then
        cp "$PUBLISH_DIR/rootfs/rootfs.tar.gz" "$ROOTFS_ARCHIVE"
    elif [ -f "$PUBLISH_DIR/rootfs.tar.gz" ]; then
        cp "$PUBLISH_DIR/rootfs.tar.gz" "$ROOTFS_ARCHIVE"
    fi
}

function __mk_image__
{
    mkdir -p "$TMP_DIR"
    _require_file_ "$UBOOT_DIR/$UBOOT_IMG"
    _require_file_ "$KERNEL_DIR/$DTB_IMG"
    _require_file_ "$KERNEL_DIR/$KERNEL_IMG"

    _prepare_rootfs_
    fakeroot mkfs.jffs2 -s 0x100 -e 0x10000 -p 0x9F0000 -d "$TMP_DIR/rootfs" -o "$TMP_DIR/$JFFS2_IMG"

    dd if=/dev/zero of="$TMP_DIR/$OUTPUT_IMG" bs=1M count=16
    dd if="$UBOOT_DIR/$UBOOT_IMG" of="$TMP_DIR/$OUTPUT_IMG" bs=1K conv=notrunc
    dd if="$KERNEL_DIR/$DTB_IMG" of="$TMP_DIR/$OUTPUT_IMG" bs=1K seek=1024 conv=notrunc
    dd if="$KERNEL_DIR/$KERNEL_IMG" of="$TMP_DIR/$OUTPUT_IMG" bs=1K seek=1088 conv=notrunc
    dd if="$TMP_DIR/$JFFS2_IMG" of="$TMP_DIR/$OUTPUT_IMG" bs=1K seek=6208 conv=notrunc

    cp "$TMP_DIR/$OUTPUT_IMG" "$OUTPUT_DIR/$OUTPUT_IMG"

    if [ $PUSH_OUTPUT -eq 1 ]; then
        if [ ! -d "$PUSH_DIR" ]; then
            echo "Push directory not found: $PUSH_DIR"
            exit 1
        fi
        cp "$TMP_DIR/$OUTPUT_IMG" "$PUSH_DIR"
    fi
}

function __flashwrite__
{
    
    if [ $WRITE_UBOOT -eq 1 ]; then
        echo "start write uboot to spi flash"
        _verify_allow_

        # uboot分区固定1M
        dd if=/dev/zero of=tmp.bin bs=1M count=1
        dd if="$UBOOT_DIR/$UBOOT_IMG" of=tmp.bin bs=1k conv=notrunc
        sunxi-fel.exe -p spiflash-write 0 tmp.bin
        rm tmp.bin
    fi

    if [ $WRITE_DTB -eq 1 ]; then
        echo "start write dtb to spi flash"
        _verify_allow_

        # dtb分区固定64K
        dd if=/dev/zero of=tmp.bin bs=1K count=64
        dd if="$KERNEL_DIR/$DTB_IMG" of=tmp.bin bs=1k conv=notrunc
        sunxi-fel.exe -p spiflash-write 0x100000 tmp.bin
        rm tmp.bin
    fi

    if [ $WRITE_KERNEL -eq 1 ]; then
        echo "start write zImage to spi flash"
        _verify_allow_

        # zImage分区固定5M
        dd if=/dev/zero of=tmp.bin bs=1M count=5
        dd if="$KERNEL_DIR/$KERNEL_IMG" of=tmp.bin bs=1k conv=notrunc
        sunxi-fel.exe -p spiflash-write 0x110000 tmp.bin
        rm tmp.bin
    fi

    if [ $WRITE_ROOTFS -eq 1 ]; then
        echo "start write rootfs to spi flash"
        _verify_allow_

        #剩下全部给rootfs
        sunxi-fel.exe -p spiflash-write 0x610000 "$TMP_DIR/$JFFS2_IMG"
    fi

    if [ $WRITE_DIGICAP -eq 1 ]; then
        echo "start write digicap.dav to spi flash"
        _verify_allow_
        sunxi-fel.exe -p spiflash-write 0 "$OUTPUT_DIR/$OUTPUT_IMG"
    fi
    
}

function __clean__
{
    rm -rf "$TMP_DIR"
    rm -f "$OUTPUT_DIR/$OUTPUT_IMG"
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

ARGS=`getopt --options h,g,w:,c,p --long help,get,write:,clean,push -n "${PROG}" -- "$@"`
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
        -p|--push)
            PUSH_OUTPUT=1
            shift
            ;;
        -w|--write)
            case "$2" in
                uboot)
                    WRITE_UBOOT=1
                    shift 2
                    ;;
                dtb)
                    WRITE_DTB=1
                    shift 2
                    ;;
                kernel)
                    WRITE_KERNEL=1
                    shift 2
                    ;;
                rootfs)
                    WRITE_ROOTFS=1
                    shift 2
                    ;;
                all)
                    WRITE_UBOOT=1
                    WRITE_DTB=1
                    WRITE_KERNEL=1
                    WRITE_ROOTFS=1
                    shift 2
                    ;;
                digicap)
                    WRITE_DIGICAP=1
                    shift 2
                    ;;
                *)
                    echo "Unsupported write target: $2"
                    print_usage
                    exit 1
                    ;;
            esac
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
    esac
done

__main__