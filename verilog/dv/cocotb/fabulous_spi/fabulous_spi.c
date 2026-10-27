// SPDX-License-Identifier: Apache-2.0

#include <firmware_apis.h>
#include <stdint.h>
#include "runtime_spi_bitstream.h"

#define USER_BASE          0x30000000u
#define REG_ID             0x00u
#define REG_CONFIG_DATA    0x04u
#define REG_CONFIG_STATUS  0x08u
#define REG_CONTROL        0x0cu
#define REG_TX_DATA        0x10u
#define REG_RX_DATA        0x14u
#define REG_SPI_STATUS     0x18u
#define REG_TEST_STATUS    0x24u

#define CONTROL_START      0x1u
#define CONTROL_HOLD_CS    0x2u
#define CONTROL_RESET      0x4u

static inline void user_write(uint32_t offset, uint32_t value) {
    (*(volatile uint32_t *)(USER_BASE + offset)) = value;
}

static inline uint32_t user_read(uint32_t offset) {
    return (*(volatile uint32_t *)(USER_BASE + offset));
}

static uint8_t spi_byte(uint8_t value, uint32_t hold_cs) {
    user_write(REG_TX_DATA, value);
    user_write(REG_CONTROL, CONTROL_START | (hold_cs ? CONTROL_HOLD_CS : 0u));
    while ((user_read(REG_SPI_STATUS) & 0x2u) == 0u) { }
    return (uint8_t)user_read(REG_RX_DATA);
}

void main(void) {
    uint32_t i;
    uint8_t readback;

    ManagmentGpio_outputEnable();
    ManagmentGpio_write(0);
    enableHkSpi(0);

    GPIOs_configureAll(GPIO_MODE_USER_STD_OUT_MONITORED);
    GPIOs_configure(10, GPIO_MODE_USER_STD_INPUT_NOPULL); // FPGA SPI MISO
    GPIOs_loadConfigs();
    User_enableIF();

    if (user_read(REG_ID) != 0xFAB50001u) {
        user_write(REG_TEST_STATUS, 2u);
        ManagmentGpio_write(1);
        return;
    }

    // Hold the reconfigurable circuit in reset while loading the bitstream.
    user_write(REG_CONTROL, CONTROL_RESET);
    for (i = 0; i < runtime_spi_bitstream_words; ++i)
        user_write(REG_CONFIG_DATA, runtime_spi_bitstream[i]);

    if ((user_read(REG_CONFIG_STATUS) & 1u) == 0u) {
        user_write(REG_TEST_STATUS, 2u);
        ManagmentGpio_write(1);
        return;
    }
    user_write(REG_CONTROL, 0u);

    // SPI memory write: command 0x02, address 0x3c, data 0xa5.
    (void)spi_byte(0x02u, 1u);
    (void)spi_byte(0x3cu, 1u);
    (void)spi_byte(0xa5u, 0u);

    // SPI memory read: command 0x03, address 0x3c, dummy/read byte.
    (void)spi_byte(0x03u, 1u);
    (void)spi_byte(0x3cu, 1u);
    readback = spi_byte(0x00u, 0u);

    user_write(REG_TEST_STATUS, readback == 0xa5u ? 1u : 2u);
    ManagmentGpio_write(1);
}
