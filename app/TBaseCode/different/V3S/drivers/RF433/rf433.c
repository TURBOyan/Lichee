#include <linux/init.h>  
#include <linux/module.h>
#include <linux/device.h>  
#include <linux/kernel.h>  
#include <linux/fs.h>
#include <linux/uaccess.h>
#include <linux/gpio.h>
#include <linux/interrupt.h>
#include <linux/string.h>
#include <linux/delay.h>


MODULE_AUTHOR("turboyan");
MODULE_LICENSE("GPL");

static int majorNumber = 0;
/*Class 名称，对应/sys/class/下的目录名称*/
static const char *CLASS_NAME = "rf433_tx_class";
/*Device 名称，对应/dev下的目录名称*/
static const char *DEVICE_NAME = "rf433_tx";

static int rf433_tx_open(struct inode *node, struct file *file);
static ssize_t rf433_tx_read(struct file *file,char *buf, size_t len,loff_t *offset);
static ssize_t rf433_tx_write(struct file *file,const char *buf,size_t len,loff_t* offset);
static int rf433_tx_release(struct inode *node,struct file *file);

#define RF433_TX_PIN   32 
static int gpio_status;


static char recv_msg[20];

static struct class *rf433_tx_class = NULL;
static struct device *rf433_tx_device = NULL;

/*File opertion 结构体，我们通过这个结构体建立应用程序到内核之间操作的映射*/
static struct file_operations file_oprts = 
{
    .open = rf433_tx_open,
    .read = rf433_tx_read,
    .write = rf433_tx_write,
    .release = rf433_tx_release,
};

static void gpio_config(void)
{
    if(!gpio_is_valid(RF433_TX_PIN)){
        printk(KERN_ALERT "Error wrong gpio number\n");
        return ;
    }
    gpio_request(RF433_TX_PIN,"led_ctr");
    gpio_direction_output(RF433_TX_PIN,1);
    gpio_set_value(RF433_TX_PIN,1);
    gpio_status = 1;
}


static void gpio_deconfig(void)
{
    gpio_free(RF433_TX_PIN);
}

static int __init rf433_tx_init(void)
{
    printk(KERN_ALERT "Driver init\r\n");
    /*注册一个新的字符设备，返回主设备号*/
    majorNumber = register_chrdev(0,DEVICE_NAME,&file_oprts);
    if(majorNumber < 0 ){
        printk(KERN_ALERT "Register failed!!\r\n");
        return majorNumber;
    }
    printk(KERN_ALERT "Registe success,major number is %d\r\n",majorNumber);

    /*以CLASS_NAME创建一个class结构，这个动作将会在/sys/class目录创建一个名为CLASS_NAME的目录*/
    rf433_tx_class = class_create(THIS_MODULE,CLASS_NAME);
    if(IS_ERR(rf433_tx_class))
    {
        unregister_chrdev(majorNumber,DEVICE_NAME);
        return PTR_ERR(rf433_tx_class);
    }

    /*以DEVICE_NAME为名，参考/sys/class/CLASS_NAME在/dev目录下创建一个设备：/dev/DEVICE_NAME*/
    rf433_tx_device = device_create(rf433_tx_class,NULL,MKDEV(majorNumber,0),NULL,DEVICE_NAME);
    if(IS_ERR(rf433_tx_device))
    {
        class_destroy(rf433_tx_class);
        unregister_chrdev(majorNumber,DEVICE_NAME);
        return PTR_ERR(rf433_tx_device);
    }
    printk(KERN_ALERT "rf433_tx device init success!!\r\n");

    return 0;
}

/*当用户打开这个设备文件时，调用这个函数*/
static int rf433_tx_open(struct inode *node, struct file *file)
{
    printk(KERN_ALERT "GPIO init \n");
    gpio_config();
    return 0;
}

/*当用户试图从设备空间读取数据时，调用这个函数*/
static ssize_t rf433_tx_read(struct file *file,char *buf, size_t len,loff_t *offset)
{
    int cnt = 0;
    /*将内核空间的数据copy到用户空间*/
    cnt = copy_to_user(buf,&gpio_status,1);
    if(0 == cnt){
        return 0;
    }
    else{
        printk(KERN_ALERT "ERROR occur when reading!!\n");
        return -EFAULT;
    }
    return 1;
}

/*当用户往设备文件写数据时，调用这个函数*/
static ssize_t rf433_tx_write(struct file *file,const char *buf,size_t len,loff_t *offset)
{
    /*将用户空间的数据copy到内核空间*/
    int cnt = copy_from_user(recv_msg,buf,len);
    int loop=0;
    if(0 == cnt){
        if(0 == memcmp(recv_msg,"on",2))
        {
            printk(KERN_INFO "LED ON32!\n");

            for(loop=0;loop<20;loop++)
            {
                gpio_set_value(RF433_TX_PIN,1);
                gpio_set_value(RF433_TX_PIN,0);
            }
            gpio_status = 1;
        }
        else
        {
            printk(KERN_INFO "LED OFF!\n");
            for(loop=0;loop<20;loop++)
            {
                gpio_set_value(RF433_TX_PIN,1);
                udelay(1280);
                gpio_set_value(RF433_TX_PIN,0);
                udelay(1280);
            }
            gpio_status = 0;
        }
    }
    else{
        printk(KERN_ALERT "ERROR occur when writing!!\n");
        return -EFAULT;
    }
    return len;
}

/*当用户打开设备文件时，调用这个函数*/
static int rf433_tx_release(struct inode *node,struct file *file)
{
    printk(KERN_INFO "Release!!\n");
    gpio_deconfig();
    return 0;
}

/*销毁注册的所有资源，卸载模块，这是保持linux内核稳定的重要一步*/
static void __exit rf433_tx_exit(void)
{
    device_destroy(rf433_tx_class,MKDEV(majorNumber,0));
    class_unregister(rf433_tx_class);
    class_destroy(rf433_tx_class);
    unregister_chrdev(majorNumber,DEVICE_NAME);
}

module_init(rf433_tx_init);
module_exit(rf433_tx_exit);
