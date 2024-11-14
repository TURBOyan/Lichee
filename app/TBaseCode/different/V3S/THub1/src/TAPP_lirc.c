#include "TAPP_lirc.h"

#include "TAPP_RF433.h"

#define LIRC_SOCKET "/var/run/lirc/lircd"
#define BUFFER_SIZE 128

#define LIRC_INFO printf
#define LIRC_WARN printf
#define LIRC_ERROR printf
#define LIRC_FATAL printf

void *TAPP_lirc_Process(void)
{
    int sockfd;
    struct sockaddr_un serv_addr;
    char buffer[BUFFER_SIZE];

    printf("start TAPP_lirc_Process\n");

    // 创建 Socket
    if ((sockfd = socket(AF_UNIX, SOCK_STREAM, 0)) == -1)
    {
        perror("Socket create fail");
        exit(EXIT_FAILURE);
    }

    // 设置 Socket 地址
    memset(&serv_addr, 0, sizeof(serv_addr));
    serv_addr.sun_family = AF_UNIX;
    strncpy(serv_addr.sun_path, LIRC_SOCKET, sizeof(serv_addr.sun_path) - 1);

    // 连接到 lircd 的 Unix Socket
    if (connect(sockfd, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) == -1)
    {
        perror("connect to lircd fail\n");
        close(sockfd);
        exit(EXIT_FAILURE);
    }

    printf("lircd connected...\n");

    // 循环读取按键事件
    while (1)
    {
        usleep(100 * 1000);
        memset(buffer, 0, BUFFER_SIZE);
        // 从 lircd 读取按键数据
        if (read(sockfd, buffer, BUFFER_SIZE) > 0)
        {
            // 解析并显示按键事件
            printf("receive IR: %s\n", buffer);

            // 检查特定按键
            if (strstr(buffer, "KEY_UP"))
            {
                printf("KEY_UP\n");
                if (TAPP_RF433_SendCMD(RF_UP) < 0)
                {
                    perror("Failed to send command");
                }
            }
            else if (strstr(buffer, "KEY_DOWN"))
            {
                printf("KEY_DOWN\n");
                if (TAPP_RF433_SendCMD(RF_DOWN) < 0)
                {
                    perror("Failed to send command");
                }
            }
            else if (strstr(buffer, "KEY_LEFT"))
            {
                printf("KEY_LEFT\n");
                if (TAPP_RF433_SendCMD(RF_LOCK) < 0)
                {
                    perror("Failed to send command");
                }
            }
            else if (strstr(buffer, "KEY_RIGHT"))
            {
                printf("KEY_RIGHT\n");
                if (TAPP_RF433_SendCMD(RF_STOP) < 0)
                {
                    perror("Failed to send command");
                }
            }
        }
    }
    // 关闭 Socket
    close(sockfd);
    return NULL;
}
