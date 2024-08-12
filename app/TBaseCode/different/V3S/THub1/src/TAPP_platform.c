#include "TAPP_platform.h"
#include "common.h"
#include <stdio.h>
#include <stdlib.h>
#include <error.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>
static char buf[256] = {1};
int32_t TAPP_Platform_Init(void)
{
    int fd = open("/dev/rf433_tx",O_RDWR);
    if(fd < 0)
    {
        perror("Open file failed!!!\r\n");
        return -1;
    }
    while(1){
        printf("Please input <on> or <off>:\n");
        scanf("%s",buf);
        if(strlen(buf) > 3){
            printf("Ivalid input!\n");
        }
        else
        {
            int ret = write(fd,buf,strlen(buf));
            if(ret < 0){
                perror("Failed to write!!");
        }
    }
    }
    close(fd);
    return 0;
}