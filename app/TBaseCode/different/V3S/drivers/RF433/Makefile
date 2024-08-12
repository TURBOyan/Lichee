# 模块目标
obj-m := rf433.o

# 交叉编译工具链前缀，使用你的交叉编译工具链前缀替换下面的内容
CROSS_COMPILE:=

# 内核源码路径，指向目标设备的内核源码目录
KERNELDIR:=

# 驱动的输出目录
PREFIX=


# 默认目标：编译模块
all:
	$(MAKE) -C $(KERNELDIR) M=$(CURDIR) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) modules
	mv rf433.ko $(PREFIX)

# 清理构建生成的文件
clean:
	$(MAKE) -C $(KERNELDIR) M=$(CURDIR) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) clean

.PHONY: all clean
