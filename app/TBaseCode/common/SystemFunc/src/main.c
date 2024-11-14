#include <stdio.h>
#include "common.h"
#include "TAPP_platform.h"

int main(int argc, char** argv)
{
    TAPP_Platform_Init();

    while(1)
    {
        usleep(5*1000*1000);
    }
    return 0;
}