/**
    {RF_UP,   "FDF40337326857DF"},
    {RF_DOWN, "FDF40337326257DF"},
    {RF_STOP, "FDF40337326457DF"},
    {RF_LOCK, "FDF40337326157DF"},
 */

#include "TAPP_RF433.h"

#include "cJSON.h"

#define RFTX_DEV "/dev/rftx"
#define RFTX_JSON_FILE "/dav/conf/rftx.json"

typedef struct
{
    RF_CMD_E cmd;
    char cmdStr[128];
} RF433_CMD2CHAR;
RF433_CMD2CHAR stCMD2CHAR[RF_MAX] = {0};

int32_t rf_fd = -1;
pthread_mutex_t rftx_mutex = PTHREAD_MUTEX_INITIALIZER;

#define RF433_INFO printf
#define RF433_WARN printf
#define RF433_ERROR printf
#define RF433_FATAL printf

static int32_t Parse_RFTX_Param(void)
{
    FILE *file = NULL;
    file = fopen(RFTX_JSON_FILE, "r");
    if (file == NULL)
    {
        printf("Open file fail! \n");
        return -1;
    }

    // 获得文件大小
    struct stat statbuf;
    stat(RFTX_JSON_FILE, &statbuf);
    int fileSize = statbuf.st_size;
    printf("file:%s size: %d\n", RFTX_JSON_FILE, fileSize);

    // 分配符合文件大小的内存
    char *jsonStr = (char *)malloc(sizeof(char) * fileSize + 1);
    memset(jsonStr, 0, fileSize + 1);

    // 读取文件中的json字符串
    int size = fread(jsonStr, sizeof(char), fileSize, file);
    if (size == 0)
    {
        printf("fread:%s failed!\n", RFTX_JSON_FILE);
        fclose(file);
        return -2;
    }
    fclose(file);

    /* 解析整段JSO数据 */
    cJSON *root = cJSON_Parse(jsonStr);
    if (root == NULL)
    {
        RF433_ERROR("parse fail. %s\n", cJSON_GetErrorPtr());
        return -1;
    }

    cJSON *item = cJSON_GetObjectItem(root, "rftx_cmd");
    if (item != NULL)
    {
        cJSON *obj = item->child;
        while (obj)
        {
            if (obj->type == cJSON_String)
            {
                printf("%s = %s\n", obj->string, obj->valuestring);

                if (strcmp(obj->string, "RF_UP") == 0)
                {
                    stCMD2CHAR[RF_UP].cmd = RF_UP;
                    strcpy(stCMD2CHAR[RF_UP].cmdStr, (const char *)obj->valuestring);
                }
                else if (strcmp(obj->string, "RF_DOWN") == 0)
                {
                    stCMD2CHAR[RF_DOWN].cmd = RF_DOWN;
                    strcpy(stCMD2CHAR[RF_DOWN].cmdStr, (const char *)obj->valuestring);
                }
                else if (strcmp(obj->string, "RF_STOP") == 0)
                {
                    stCMD2CHAR[RF_STOP].cmd = RF_STOP;
                    strcpy(stCMD2CHAR[RF_STOP].cmdStr, (const char *)obj->valuestring);
                }
                else if (strcmp(obj->string, "RF_LOCK") == 0)
                {
                    stCMD2CHAR[RF_LOCK].cmd = RF_LOCK;
                    strcpy(stCMD2CHAR[RF_LOCK].cmdStr, (const char *)obj->valuestring);
                }
            }
            // 获取下一个元素
            obj = obj->next;
        }
    }

    free(jsonStr);
    return 0;
}

#define RLED_DEV_PATH "/sys/class/leds/licheepi:red:usr/brightness"
#define GLED_DEV_PATH "/sys/class/leds/licheepi:green:usr/brightness"
#define BLED_DEV_PATH "/sys/class/leds/licheepi:blue:usr/brightness"
FILE *r_fd, *g_fd, *b_fd;
int32_t LEDS_Init(void)
{
    printf("start init the leds\n");
    // 获取红灯的设备文件描述符
    r_fd = fopen(RLED_DEV_PATH, "w");
    if (r_fd < 0)
    {
        printf("Fail to Open %s device\n", RLED_DEV_PATH);
        return -1;
    }
    fwrite("0",1,1,r_fd);
    fflush(r_fd);

    // 获取绿灯的设备文件描述符
    g_fd = fopen(GLED_DEV_PATH, "w");
    if (g_fd < 0)
    {
        printf("Fail to Open %s device\n", GLED_DEV_PATH);
        return -2;
    }
    fwrite("0",1,1,g_fd);
    fflush(g_fd);

    // 获取蓝灯的设备文件描述符
    b_fd = fopen(BLED_DEV_PATH, "w");
    if (b_fd < 0)
    {
        printf("Fail to Open %s device\n", BLED_DEV_PATH);
        return -3;
    }
    fwrite("0",1,1,b_fd);
    fflush(b_fd);

    //红灯亮1秒，指示系统正常
    fwrite("255",3,1,r_fd);
    fflush(r_fd);
    sleep(1);
    //红灯灭
    fwrite("0",1,1,r_fd);
    fflush(r_fd);

    return 0;
}

int32_t TAPP_RF433_Init(void)
{
    LEDS_Init();
    Parse_RFTX_Param();
    rf_fd = open(RFTX_DEV, O_WRONLY);
    if (rf_fd < 0)
    {
        RF433_ERROR("Failed to open device:%s\n", RFTX_DEV);
        return -1;
    }
    return 0;
}

int32_t TAPP_RF433_SendCMD(RF_CMD_E cmd)
{
    int ret = 0;
    if (cmd >= RF_MAX)
    {
        printf("TAPP_RF433_SendCMD cmd:%d out of range\n", cmd);
        return -1;
    }

    if (rf_fd < 0)
    {
        printf("TAPP_RF433_Init didn't init, rf_fd:%d\n", rf_fd);
        return -2;
    }

    pthread_mutex_lock(&rftx_mutex);
    //蓝灯亮
    fwrite("255",3,1,b_fd);
    fflush(b_fd);
    if (cmd == stCMD2CHAR[cmd].cmd)
    {
        ret = write(rf_fd, stCMD2CHAR[cmd].cmdStr, strlen((const char *)stCMD2CHAR[cmd].cmdStr));
        if (ret != strlen(stCMD2CHAR[cmd].cmdStr))
        {
            RF433_ERROR("TAPP_RF433_SendCMD write to rf_fd failed, ret:%d\n", ret);
            pthread_mutex_unlock(&rftx_mutex);
            return -3;
        }
    }
    //蓝灯灭
    fwrite("0",1,1,b_fd);
    fflush(b_fd);
    pthread_mutex_unlock(&rftx_mutex);
    return 0;
}

int32_t TAPP_RF433_Exit(void)
{
    if (rf_fd >= 0)
    {
        close(rf_fd);
        rf_fd = -1;
    }
    return -1;
}
