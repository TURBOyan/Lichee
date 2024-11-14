#ifndef __TAPP_RF433_H__
#define __TAPP_RF433_H__

#ifdef __cplusplus
extern "C" {
#endif

#include "common.h"

typedef enum
{
    RF_UP = 0,
    RF_DOWN,
    RF_STOP,
    RF_LOCK,

    RF_MAX
}RF_CMD_E;

int32_t TAPP_RF433_Init(void);
int32_t TAPP_RF433_SendCMD(RF_CMD_E cmd);
int32_t TAPP_RF433_Exit(void);

#ifdef __cplusplus
}
#endif

#endif //__TAPP_RF433_H__
