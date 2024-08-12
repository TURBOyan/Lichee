#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/platform_device.h>
#include <linux/gpio/consumer.h>
#include <linux/of.h>

// 模块信息
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Your Name");
MODULE_DESCRIPTION("A simple platform driver example");
MODULE_VERSION("0.1");

static struct gpio_desc *gpiod;

// probe函数 - 在设备匹配成功后调用
static int my_device_probe(struct platform_device *pdev)
{
    struct device *dev = &pdev->dev;

    printk(KERN_INFO "my_device_probe: Device probed successfully\n");

    // 获取 GPIO 描述符
    gpiod = gpiod_get(dev, "my-gpio", GPIOD_OUT_LOW);
    if (IS_ERR(gpiod)) {
        printk(KERN_ERR "my_device_probe: Failed to get GPIO\n");
        return PTR_ERR(gpiod);
    }

    // 设置 GPIO 初始值
    gpiod_set_value(gpiod, 1);
    printk(KERN_INFO "my_device_probe: GPIO set to high\n");

    return 0;
}

// remove函数 - 在设备卸载时调用
static int my_device_remove(struct platform_device *pdev)
{
    // 释放 GPIO 资源
    if (gpiod) {
        gpiod_set_value(gpiod, 0);  // 设置GPIO为低电平
        gpiod_put(gpiod);            // 释放GPIO描述符
        printk(KERN_INFO "my_device_remove: GPIO set to low and released\n");
    }

    return 0;
}

// 匹配设备树中的设备
static const struct of_device_id my_device_of_match[] = {
    { .compatible = "my-company,my-device", },
    { /* Sentinel */ }
};
MODULE_DEVICE_TABLE(of, my_device_of_match);

// 定义平台驱动
static struct platform_driver my_device_driver = {
    .probe = my_device_probe,
    .remove = my_device_remove,
    .driver = {
        .name = "my_device_driver",
        .of_match_table = my_device_of_match,
    },
};

// 驱动注册
module_platform_driver(my_device_driver);
