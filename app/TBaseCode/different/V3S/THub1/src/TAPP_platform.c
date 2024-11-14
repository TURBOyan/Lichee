#include "TAPP_platform.h"

#include <stdio.h>
#include <stdlib.h>
#include <error.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>

#include "common.h"

#include "TAPP_RF433.h"
#include "TAPP_lirc.h"
#include "TAPP_lradc.h"

#define MAX_NUM_THREADS (20)
pthread_t threads[MAX_NUM_THREADS];

int32_t TAPP_Platform_Init(void)
{
    int32_t ret = 0;
    int32_t threads_cnt = 0;

    ret = TAPP_RF433_Init();
    if (ret != 0)
    {
        printf("ERROR; return code from TAPP_RF433_Init is %d\n", ret);
        return -1;
    }

    printf("start pthread\n");
    ret = pthread_create(&threads[threads_cnt++], NULL, (void*)TAPP_lradc_Process, NULL);
    if (ret)
    {
        printf("ERROR; return code from pthread_create() is %d\n", ret);
        return -1;
    }

    ret = pthread_create(&threads[threads_cnt++], NULL, (void*)TAPP_lirc_Process, NULL);
    if (ret)
    {
        printf("ERROR; return code from pthread_create() is %d\n", ret);
        return -1;
    }
    return 0;
}