#include <linux/printk.h>
#include <linux/gpio.h>
#include <linux/delay.h>
#include <linux/fs.h>
#include <linux/module.h>
#include <linux/uaccess.h>

#define GPIO_PIN 32  // 假设我们使用 GPIO17

// 用于定义 433MHz 协议的脉冲长度
#define RFCMD_LEN (16)
#define PULSE_SHORT (320)  // 短脉冲脉冲长度为320微秒
#define PULSE_LONG  (PULSE_SHORT*2)  // 长脉冲脉冲长度为320微秒

typedef struct _RFCTRL_S_
{
    __u8  header;    //帧头 0xFD 固定值
    __u8  freq;      //发射频率 F3==315M  F4==433M
    __u8  time;      //发射时间 0x01--0xFF
    __u16 addr;      //地址16位 每个字节0x01--0xFF 
    __u8  value;     //键值8位  0x01--0xFF
    __u8  osc;       //震荡参数，和脉冲长度有关，此处为等于250us的倍数没，0x01--0xFF
    __u8  endframe;  //帧尾 0xDF 固定值
} __attribute__((packed)) RFCTRL_S; //不要字节对齐


void inline send_sync(__u8 width)
{
    gpio_set_value(GPIO_PIN, 1);
    usleep_range(PULSE_SHORT*width, PULSE_SHORT*width + 10);  // 保持高电平
    gpio_set_value(GPIO_PIN, 0);
    usleep_range((PULSE_SHORT*width+PULSE_LONG*width)*8, (PULSE_SHORT*width+PULSE_LONG*width)*8 + 10);  // 保持低电平
}

// 发送 "1" 的信号 (高电平, 低电平)
void inline send_high(__u8 width) {
    gpio_set_value(GPIO_PIN, 1);
    usleep_range(PULSE_LONG*width, PULSE_LONG*width + 10);  // 保持高电平
    gpio_set_value(GPIO_PIN, 0);
    usleep_range(PULSE_SHORT*width, PULSE_SHORT*width + 10);  // 保持低电平
}

// 发送 "0" 的信号 (低电平, 高电平)
void inline send_low(__u8 width) {
    gpio_set_value(GPIO_PIN, 1);
    usleep_range(PULSE_SHORT*width, PULSE_SHORT*width + 10);  // 保持低电平
    gpio_set_value(GPIO_PIN, 0);
    usleep_range(PULSE_LONG*width, PULSE_LONG*width + 10);  // 保持高电平
}

void send_RF433Data(RFCTRL_S* pRFData)
{
    __s32 i=0;
    __u32 width=1;

    //发送同步字
    send_sync(width);

    //发送地址位
    for(i=15;i>=0;i--)
    {
        if(pRFData->addr & (1<<i))
        {
            send_high(width);
        }
        else
        {
            send_low(width);
        }
    }

    //发送数据位
    for(i=7;i>=0;i--)
    {
        if(pRFData->value & (1<<i))
        {
            send_high(width);
        }
        else
        {
            send_low(width);
        }
    }
}

__s32 parseString(char* hexStr, RFCTRL_S* pRFCtrl)
{
    __u8 len = strlen(hexStr);
    __u64 DataIn={0};

    if (len != RFCMD_LEN)
    {
        printk(KERN_ERR "str:%s len error, strlen:%d\n",hexStr,len);
        return -1;
    }

    if((NULL == pRFCtrl) || (sizeof(RFCTRL_S) != sizeof(DataIn)))
    {
        printk(KERN_ERR "pRFCtrl is NULL, or size:%d error, need:%d\n", sizeof(RFCTRL_S), sizeof(DataIn));
        return -2; 
    }

    DataIn = simple_strtoull(hexStr, NULL, 16);
    pRFCtrl->header     = DataIn>>56 & 0xFF;
    pRFCtrl->freq       = DataIn>>48 & 0xFF;
    pRFCtrl->time       = DataIn>>40 & 0xFF;
    pRFCtrl->addr       = DataIn>>24 & 0xFFFF;
    pRFCtrl->value      = DataIn>>16 & 0xFF;
    pRFCtrl->osc        = DataIn>>8 & 0xFF;
    pRFCtrl->endframe   = DataIn & 0xFF;
    return 0;
}

// 发送信号
__s32 send_code(RFCTRL_S* pRFCtrl)
{
    int i=0;

    if(NULL == pRFCtrl || pRFCtrl->header != 0xFD || pRFCtrl->endframe != 0xDF)
    {
        printk(KERN_ERR "pRFCtrl is NULL, or header:0x%X or endframe:0x%X error\n", pRFCtrl->header, pRFCtrl->endframe);
        return -1;
    }

    if(pRFCtrl->freq == 0xF4)
    {
        for(i=0;i<pRFCtrl->time;i++)
        {
            send_RF433Data(pRFCtrl);
        }
    }

    return 0;
}

static ssize_t rf433_write(struct file *file, const char __user *buf, size_t len, loff_t *offset) {
    char kbuf[32] = {0};
    RFCTRL_S RFCtrl = {0};
    if (len > sizeof(kbuf))
        return -EINVAL;

    if (copy_from_user(kbuf, buf, len))
        return -EFAULT;

    // 根据从用户空间传递的 code 发送 RF433 信号
    kbuf[RFCMD_LEN] = '\0';
    parseString(kbuf, &RFCtrl);

    send_code(&RFCtrl);

    return len;
}

static const struct file_operations rf433_fops = {
    .write = rf433_write,
};

static int __init rf433_init(void) {
    int ret;

    ret = gpio_request(GPIO_PIN, "RF433");
    if (ret) {
        printk(KERN_ERR "Unable to request GPIO pin\n");
        return ret;
    }

    gpio_direction_output(GPIO_PIN, 0);

    // 注册字符设备，允许用户空间写入来控制发送
    ret = register_chrdev(240, "rf433", &rf433_fops);
    if (ret < 0) {
        printk(KERN_ERR "Failed to register device\n");
        gpio_free(GPIO_PIN);
        return ret;
    }

    printk(KERN_INFO "RF433 driver initialized\n");
    return 0;
}

static void __exit rf433_exit(void) {
    unregister_chrdev(240, "rf433");
    gpio_free(GPIO_PIN);
    printk(KERN_INFO "RF433 driver exited\n");
}

module_init(rf433_init);
module_exit(rf433_exit);

MODULE_LICENSE("GPL");
