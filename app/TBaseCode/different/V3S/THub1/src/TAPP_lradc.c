#include "TAPP_lradc.h"

#include <string.h>
#include <fcntl.h>
#include <linux/input.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "TAPP_RF433.h"

void *TAPP_lradc_Process(void)
{
    printf("start TAPP_lradc_Process\n");
    int fd = open("/dev/input/event0", O_RDONLY);

    printf("fd = %d\n", fd);
    struct input_event t;
    printf("size of t = %d\n", sizeof(t));
    while (1)
    {
        usleep(100 * 1000);
        int len = read(fd, &t, sizeof(t));
        if (len == sizeof(t))
        {
            if (t.type == EV_KEY && t.value == 1)
            {
                switch (t.code)
                {
                case KEY_VOLUMEUP:
                    if (TAPP_RF433_SendCMD(RF_UP) < 0)
                    {
                        perror("Failed to send command");
                    }
                    break;
                case KEY_SELECT:
                    if (TAPP_RF433_SendCMD(RF_DOWN) < 0)
                    {
                        perror("Failed to send command");
                    }
                    break;
                case KEY_OK:
                    if (TAPP_RF433_SendCMD(RF_STOP) < 0)
                    {
                        perror("Failed to send command");
                    }
                    break;
                case KEY_VOLUMEDOWN:
                    if (TAPP_RF433_SendCMD(RF_STOP) < 0)
                    {
                        perror("Failed to send command");
                    }
                    break;
                default:
                    break;
                }
                printf("key %d %s\n", t.code, (t.value) ? "Pressed" : "Released");
                if (t.code == KEY_ESC)
                    break;
            }
        }
    }
    return NULL;
}
