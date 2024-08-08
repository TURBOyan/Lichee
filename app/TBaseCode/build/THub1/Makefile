# 项目目录
PROJECT_DIR = ../../

# 公共目录和差异目录
COMMON_DIR = $(PROJECT_DIR)/common
DIFFERENT_DIR = $(PROJECT_DIR)/different/V3S/THub1/

# 编译器
CC = $(CROSS_COMPILE)gcc

# 可执行文件名称
TARGET = tuapp

# 头文件目录
INC_DIR += -I$(COMMON_DIR)/SystemFunc/inc/
INC_DIR += -I$(DIFFERENT_DIR)/inc/
INC_DIR += -I$(DIFFERENT_DIR)/libs/libgpiod/include/

# 源文件列表
SRCS += $(wildcard $(COMMON_DIR)/SystemFunc/src/*.c)
SRCS += $(wildcard $(DIFFERENT_DIR)/src/*.c)

# 编译选项
CFLAGS = -Wall $(INC_DIR)

# 目标文件列表
OBJS = $(SRCS:.c=.o)

# 链接动态库
SO_LIBS += -L$(DIFFERENT_DIR)/libs/libgpiod/lib -static -lgpiod

# 链接静态库
A_LIBS +=

# 默认目标
all: $(TARGET)

# 生成可执行文件
$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(SO_LIBS) $(A_LIBS)
	cp $(TARGET) $(PREFIX)/$(TARGET)

# 编译每个源文件
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# 清理
clean:
	rm -f $(OBJS) $(TARGET)

# 伪目标
.PHONY: all clean
