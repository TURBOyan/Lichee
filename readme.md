# 注意点：
    1、所有操作均在root权限下执行！！！！解压rootfs.tar时，需要在root用户下，否则会报EXT4-fs (mmcblk0p2): couldn‘t mount RDWR because of unsupported optional features (400)
    2、用户名：root，密码licheepi
    3、编译linux需要使用gcc9低版本
    4、编译linux，报错bc命令找不到，需要sudo apt install bc
    5、TF卡分区：
        （1）boot分区：32M，FAT16格式
        （2）rootfs分区：EXT4格式


# linux驱动:
## 1、USB转网口,使用licheepi_zero_defconfig后menuconfig内打勾即可：
```yaml
Device Drivers --->
    Network device support --->
        USB Network Adapters --->
            <*>   Multi-purpose USB Networking Framework
```
## 2、LIRC：
### （1）menuconfig配置
```yaml
Device Drivers --->
    <*> Remote Controller support  --->
        [*]   LIRC user interface
        [*]   Remote controller decoders  --->
            <*>   Enable IR raw decoder for the NEC protocol
            <*>   Enable IR raw decoder for the RC-5 protocol 
            <*>   Enable IR raw decoder for the RC6 protocol
            <*>   Enable IR raw decoder for the JVC protocol
            <*>   Enable IR raw decoder for the Sony protocol
            <*>   Enable IR raw decoder for the Sanyo protocol
            <*>   Enable IR raw decoder for the Sharp protocol
            <*>   Enable IR raw decoder for the MCE keyboard/mouse protocol
            <*>   Enable IR raw decoder for the XMP protocol
            <*>   Enable IR raw decoder for the iMON protocol
            <*>   Enable IR raw decoder for the RC-MM protocol
        [*]   Remote Controller devices  --->
            <*>   GPIO IR remote control
            <*>   GPIO IR Bit Banging Transmitter
```
### （2）DTS文件配置：
```dts
ir_gpio_rx {
    compatible  = "gpio-ir-receiver";
    gpios = <&pio 1 5 GPIO_ACTIVE_LOW>; /* PB5 */
    /*active_low = <1>;*/
    linux,rc-map-name = "rc-tevii-nec";
    status = "okay";
};

ir_gpio_tx {
    compatible  = "gpio-ir-tx";
    gpios = <&pio 1 4 GPIO_ACTIVE_LOW>; /* PB4 */
    /*active_low = <1>;*/
    status = "okay";
};
```

# 参考教程
荔枝派Zero 制作TF启动卡详细过程（绝对能用） https://blog.csdn.net/Code_MoMo/article/details/104623584

荔枝派zero linux5.2，spi flash启动识别不到分区 https://whycan.com/t_4119.html

尝试使用Ubuntu20.04从零构建Licheepi V3s Zero的SPI Flash系统镜像（linux zero-5.2.y）https://whycan.com/t_4193.html

荔枝派Zero 全志V3s，NORFlash xt25f128b的移植 https://blog.csdn.net/u013850566/article/details/123368703

荔枝派Zero（V3s）SPI Flash 启动 https://blog.csdn.net/qq_40860568/article/details/100517132