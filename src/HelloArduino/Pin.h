#pragma once

#include <HelloArduino/util.h>

extern "C"
{
#include <hal/nrf_gpio.h>
}

class Pin
{
    uint32_t const pin;
public:
    enum class Mode
    {
        Input = NRF_GPIO_PIN_DIR_INPUT,
        Output = NRF_GPIO_PIN_DIR_OUTPUT,
    };

    Pin(uint32_t const port, uint32_t const pin, Mode mode): pin(NRF_GPIO_PIN_MAP(port, pin))
    {
        nrf_gpio_cfg(
            this->pin,
            static_cast<nrf_gpio_pin_dir_t>(mode),
            NRF_GPIO_PIN_INPUT_DISCONNECT,
            NRF_GPIO_PIN_NOPULL,
            NRF_GPIO_PIN_S0S1,
            NRF_GPIO_PIN_NOSENSE
        );
    }
    void set(bool const v) const
    {
        nrf_gpio_pin_write(pin, v ? 1 : 0);
    }
    void blink(std::chrono::milliseconds const d) const
    {
        set(1);
        delay(d);
        set(0);
    }
};