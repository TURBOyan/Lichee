#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

#define LIRC_SOCKET "/var/run/lirc/lircd"
#define BUFFER_SIZE 128

int lirc_test()
{
    int sockfd;
    struct sockaddr_un serv_addr;
    char buffer[BUFFER_SIZE];

    // 创建 Socket
    if ((sockfd = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
        perror("Socket 创建失败");
        exit(EXIT_FAILURE);
    }

    // 设置 Socket 地址
    memset(&serv_addr, 0, sizeof(serv_addr));
    serv_addr.sun_family = AF_UNIX;
    strncpy(serv_addr.sun_path, LIRC_SOCKET, sizeof(serv_addr.sun_path) - 1);

    // 连接到 lircd 的 Unix Socket
    if (connect(sockfd, (struct sockaddr*)&serv_addr, sizeof(serv_addr)) == -1) {
        perror("连接 lircd 失败");
        close(sockfd);
        exit(EXIT_FAILURE);
    }

    printf("已连接到 lircd, 等待按键事件...\n");

    // 循环读取按键事件
    while (1) {
        memset(buffer, 0, BUFFER_SIZE);

        // 从 lircd 读取按键数据
        if (read(sockfd, buffer, BUFFER_SIZE) > 0) {
            // 解析并显示按键事件
            printf("接收到的按键事件: %s\n", buffer);

            // 检查特定按键
            if (strstr(buffer, "KEY_1")) {
                printf("按键事件1被按下\n");
            } else if (strstr(buffer, "KEY_2")) {
                printf("按键事件2被按下\n");
            } else if (strstr(buffer, "KEY_3")) {
                printf("按键事件3被按下\n");
            } else if (strstr(buffer, "KEY_4")) {
                printf("按键事件4被按下\n");
            }
        }
    }

    // 关闭 Socket
    close(sockfd);
    return 0;
}
