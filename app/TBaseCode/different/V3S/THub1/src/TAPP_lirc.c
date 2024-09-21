#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <fcntl.h>

#define LIRC_SOCKET "/var/run/lirc/lircd"
#define BUFFER_SIZE 128

char command1[] = "FDF408C38DA14CDF";
char command2[] = "FDF408C38DA24CDF";
char command3[] = "FDF408C38DA44CDF";
char command4[] = "FDF408C38DA84CDF";

int lirc_test()
{
    int sockfd;
    struct sockaddr_un serv_addr;
    char buffer[BUFFER_SIZE];

    int fd = open("/dev/rftx", O_WRONLY);
    if (fd < 0) {
        perror("Failed to open device");
        return 1;
    }

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
            if (strstr(buffer, "KEY_UP"))
            {
                printf("KEY_UP\n");
                if (write(fd, command1, strlen(command1)) < 0) {
                    perror("Failed to send command");
                }
            }
            else if (strstr(buffer, "KEY_DOWN"))
            {
                printf("KEY_DOWN\n");
                if (write(fd, command2, strlen(command2)) < 0) {
                    perror("Failed to send command");
                }
            }
            else if (strstr(buffer, "KEY_LEFT"))
            {
                printf("KEY_LEFT\n");
                if (write(fd, command3, strlen(command3)) < 0) {
                    perror("Failed to send command");
                }
            }
            else if (strstr(buffer, "KEY_RIGHT"))
            {
                printf("KEY_RIGHT\n");
                if (write(fd, command4, strlen(command4)) < 0) {
                    perror("Failed to send command");
                }
            }
        }
    }

    // 关闭 Socket
    close(sockfd);
    close(fd);
    return 0;
}
