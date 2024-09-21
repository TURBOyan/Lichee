#include "TAPP_platform.h"
#include "common.h"
#include <stdio.h>
#include <stdlib.h>
#include <error.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#include "TAPP_lirc.h"

int32_t TAPP_Platform_Init(void)
{
    lirc_test();
    return 0;
}