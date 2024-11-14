#include "TAPP_RF433.h"

#define RFTX_DEV "/dev/rftx"

typedef struct
{
    RF_CMD_E cmd;
    const char* cmdStr;
}RF433_CMD2CHAR;
RF433_CMD2CHAR stCMD2CHAR[]= 
{
    {RF_UP,     "FDF40337326857DF"},
    {RF_DOWN,   "FDF40337326257DF"},
    {RF_STOP,   "FDF40337326457DF"},
    {RF_LOCK,   "FDF40337326157DF"},
};

int32_t rf_fd = -1;
pthread_mutex_t rftx_mutex = PTHREAD_MUTEX_INITIALIZER;

#define RF433_INFO printf
#define RF433_WARN printf
#define RF433_ERROR printf
#define RF433_FATAL printf

int32_t TAPP_RF433_Init(void)
{
    rf_fd = open(RFTX_DEV, O_WRONLY);
    if (rf_fd < 0)
    {
        RF433_ERROR("Failed to open device:%s\n",RFTX_DEV);
        return -1;
    }
    return 0;
}

int32_t TAPP_RF433_SendCMD(RF_CMD_E cmd)
{
    int ret = 0;
    if(cmd >= RF_MAX)
    {
        printf("TAPP_RF433_SendCMD cmd:%d out of range\n",cmd);
        return -1;
    }

    if(rf_fd < 0)
    {
        printf("TAPP_RF433_Init didn't init, rf_fd:%d\n",rf_fd);
        return -2;
    }

    pthread_mutex_lock(&rftx_mutex);
    for(int32_t i=0;i<sizeof(stCMD2CHAR)/sizeof(RF433_CMD2CHAR);i++)
    {
        if(cmd == stCMD2CHAR[i].cmd)
        {
            ret = write(rf_fd, stCMD2CHAR[i].cmdStr, strlen(stCMD2CHAR[i].cmdStr));
            if(ret != strlen(stCMD2CHAR[i].cmdStr))
            {
                RF433_ERROR("TAPP_RF433_SendCMD write to rf_fd failed, ret:%d\n",ret);
                pthread_mutex_unlock(&rftx_mutex);
                return -3;
            }
        }
    }
    pthread_mutex_unlock(&rftx_mutex);
    return 0;
}

int32_t TAPP_RF433_Exit(void)
{
    if(rf_fd>=0)
    {
        close(rf_fd);
        rf_fd=-1;
    }
    return -1;
}


