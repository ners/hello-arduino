#include <HelloArduino/Pin.h>
#include <HelloArduino/util.h>

#include <drivers/nrfx_uart.h>

void uart_handler(nrfx_uart_event_t const* p_event, void* p_context)
{

}

int main()
{
    nrfx_systick_init();

    Pin const led(0, 13, Pin::Mode::Output);

    nrfx_uart_t uart;
    nrfx_uart_config_t uart_config;
    nrfx_uart_init(&uart, &uart_config, &uart_handler);

    while (true)
    {
        using ms = std::chrono::milliseconds;
        led.blink(ms(100));
        delay(ms(100));
        led.blink(ms(100));
        delay(ms(100));
        led.blink(ms(100));
        delay(ms(300));
        led.blink(ms(300));
        delay(ms(300));
        led.blink(ms(300));
        delay(ms(300));
        led.blink(ms(300));
        delay(ms(300));
        led.blink(ms(100));
        delay(ms(100));
        led.blink(ms(100));
        delay(ms(100));
        led.blink(ms(100));
        delay(ms(500));
    }
}