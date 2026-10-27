# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.triggers import Edge, FallingEdge, Timer
from caravel_cocotb.caravel_interfaces import report_test, test_configure


async def spi_memory(dut, caravel_env, memory):
    """External 256-byte SPI memory connected to Caravel GPIO 8..11."""
    gpio_bus = caravel_env.dut.mprj_io_tb

    def gpio(pin):
        value = caravel_env.monitor_gpio(pin)
        return int(value) if value.is_resolvable else None

    caravel_env.drive_gpio_in(10, 0)
    previous_cs = gpio(11)
    while True:
        # Use Caravel's GPIO monitor bus.  The gpioN top-level pad aliases can
        # remain high-impedance in RTL mode even while the user output is valid.
        # monitor_gpio() returns a snapshot, so wait on the complete bus handle
        # and select the required pin after each bus transition.
        while True:
            await Edge(gpio_bus)
            current_cs = gpio(11)
            if previous_cs == 1 and current_cs == 0:
                break
            if current_cs is not None:
                previous_cs = current_cs

        opcode = None
        address = None
        byte_index = 0
        bit_index = 7
        incoming = 0
        outgoing = 0
        previous_sclk = gpio(8)

        while gpio(11) == 0:
            await Edge(gpio_bus)
            await Timer(1, units="ns")
            if gpio(11) != 0:
                previous_cs = gpio(11)
                break

            current_sclk = gpio(8)
            if current_sclk is None or current_sclk == previous_sclk:
                continue
            previous_sclk = current_sclk

            if current_sclk:
                incoming |= gpio(9) << bit_index
                if bit_index == 0:
                    if byte_index == 0:
                        opcode = incoming
                    elif byte_index == 1:
                        address = incoming
                    elif byte_index == 2 and opcode == 0x02:
                        memory[address] = incoming

                    byte_index += 1
                    bit_index = 7
                    incoming = 0
                    outgoing = memory[address] if (opcode == 0x03 and byte_index == 2) else 0
                else:
                    bit_index -= 1
            else:
                caravel_env.drive_gpio_in(10, (outgoing >> bit_index) & 1)


@cocotb.test()
@report_test
async def fabulous_spi(dut):
    env = await test_configure(dut, timeout_cycles=5_000_000)
    memory = bytearray(256)
    cocotb.start_soon(spi_memory(dut, env, memory))

    await env.release_csb()
    await env.wait_mgmt_gpio(1)

    assert memory[0x3C] == 0xA5, "RISC-V firmware did not write SPI memory"
    assert int(env.monitor_gpio(12).value) == 1, "FABulous configured flag is low"
    assert int(env.monitor_gpio(14, 13).value) == 1, "firmware readback status is not PASS"
