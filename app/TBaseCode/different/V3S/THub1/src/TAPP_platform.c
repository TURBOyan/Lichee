#include "TAPP_platform.h"
#include "common.h"

#include "gpiod.h"


#define msleep(t) usleep((t)*1000)

struct gpiod_chip *gpiochip0;
struct gpiod_line *led;
struct gpiod_line_request_config config;

#include <time.h>

void high_precision_delay(long us) {
    struct timespec req, rem;
    req.tv_sec = us / 1000000000000; // 秒
    req.tv_nsec = us % 1000000000000; // 纳秒
    while (nanosleep(&req, &rem) == -1) {
        req = rem; // 如果被信号打断，继续睡眠
    }
}

void T433_BitStatus(int status)
{
    if(status)
    {
        gpiod_line_set_value(led, 1);
        high_precision_delay(481000);
        gpiod_line_set_value(led, 0);
        high_precision_delay(1280000);
    }
    else
    {
        gpiod_line_set_value(led, 1);
        high_precision_delay(1280000);
        gpiod_line_set_value(led, 0);
        high_precision_delay(481000);
    }
}


int32_t TAPP_Platform_Init(void)
{

    int req;
    /* PH0=(H-1)*32+0=(7-1)*32+0=192 */
    int PB8=32;

    /* 打开 GPIO 控制器 */
    gpiochip0 = gpiod_chip_open("/dev/gpiochip0");
    if (!gpiochip0)
        return -1;

    /* 获取PH5引脚 */
    led = gpiod_chip_get_line(gpiochip0, PB8);

    if (!led)
    {
        gpiod_chip_close(gpiochip0);
        return -1;
    }

    /* 配置引脚  输出模式 name为“bilik” 初始电平为low*/
    req = gpiod_line_request_output(led, "blink", 0);
    if (req)
    {
        fprintf(stderr, "led request error.\n");
        return -1;
    }

    high_precision_delay(400);

    while (1)
    {
        /* 设置引脚电平 */
        gpiod_line_set_value(led, 1);
        high_precision_delay(400);
        gpiod_line_set_value(led, 0);
        high_precision_delay(400);
    }

    return 0;
}