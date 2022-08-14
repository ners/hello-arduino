#pragma once

extern "C"
{
#include <drivers/nrfx_systick.h>
}

#include <chrono>

void delay(std::chrono::milliseconds const ms)
{
    nrfx_systick_delay_ms(ms.count());
}
