<div align="center">

<img src="https://umsousercontent.com/lib_lnlnuhLgkYnZdkSC/hj0vk05j0kemus1i.png" alt="ChipFoundry Logo" height="140" />

# Caravel Runtime-Reconfigurable FPGA Project

### FABulous FPGA Fabric · RISC-V Configuration · SPI Demonstration · SKY130

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Process](https://img.shields.io/badge/Process-SKY130-6E40C9.svg)](https://github.com/google/skywater-pdk)
[![Verification](https://img.shields.io/badge/Verification-cocotb-2EA44F.svg)](#functional-verification)

</div>

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [System Architecture](#system-architecture)
- [How It Works](#how-it-works)
- [Repository Structure](#repository-structure)
- [Getting Started](#getting-started)
- [Functional Verification](#functional-verification)
- [OpenLane Hardening](#openlane-hardening)
- [Changing the FPGA Function](#changing-the-fpga-function)
- [License](#license)

## Overview

This repository integrates a **5x5 FABulous FPGA fabric** into the ChipFoundry
Caravel user area using the **SkyWater SKY130** process.

Caravel's management RISC-V processor configures the FPGA at runtime by loading
a generated bitstream through the user Wishbone interface. The demonstrated
bitstream configures the FPGA as an SPI controller and communicates with an
external SPI memory model during cocotb verification.

The FPGA fabric is reusable. A different function can be implemented by
generating and loading another compatible bitstream without changing the
Caravel wrapper or the physical FPGA macro.

## Key Features

- 5x5 runtime-reconfigurable FABulous FPGA fabric.
- Integration with the Caravel user-project wrapper.
- RISC-V-controlled FPGA bitstream loading through Wishbone.
- SPI controller implemented inside the configured FPGA fabric.
- Register-controlled SPI transmit, receive and status interface.
- Cocotb verification with an external SPI memory model.
- SKY130-compatible FPGA macro views for physical integration.
- OpenLane configuration for hardening `user_project_wrapper`.
- Support for replacing the SPI function with another FPGA design.

## System Architecture

```text
Caravel Management SoC
        |
        | Wishbone
        v
FPGA Configuration and Control Interface
        |
        | Bitstream configuration
        v
5x5 FABulous FPGA Fabric
        |
        | SPI signals
        v
External SPI Device or Memory
```

The management processor is responsible for loading the bitstream and accessing
the FPGA control registers. The SPI state machine, serial clock generation and
data shifting are implemented by logic configured inside the FPGA fabric.

## How It Works

The demonstration follows this sequence:

1. The Caravel management processor enables the user Wishbone interface.
2. The FPGA user logic is held in reset.
3. The firmware streams the SPI configuration bitstream into the FPGA.
4. The configuration controller reports that the FPGA is ready.
5. The processor releases the FPGA user reset.
6. Firmware starts an SPI memory-write transaction.
7. Firmware starts an SPI memory-read transaction.
8. The returned data is checked by the firmware and cocotb testbench.

The cocotb test models the external SPI device. It does not replace the SPI
controller or directly configure the FPGA during the full Caravel test.

## Repository Structure

```text
caravel_user_project_FPGA/
|-- gds/
|   `-- tiny_fabric_5x5.gds
|-- lef/
|   |-- tiny_fabric_5x5.lef
|   `-- user_project_wrapper.lef
|-- openlane/
|   `-- user_project_wrapper/
|       `-- config.json
|-- verilog/
|   |-- rtl/
|   |   |-- fabric_config.v
|   |   |-- fabulous_control.v
|   |   |-- fabulous_fabric_adapter.v
|   |   |-- fabulous_sim.v
|   |   `-- user_project_wrapper.v
|   |-- gl/
|   |   |-- tiny_fabric_5x5.v
|   |   `-- user_project_wrapper.v
|   |-- includes/
|   |   `-- includes.rtl.caravel_user_project
|   `-- dv/cocotb/
|       |-- cocotb_tests.py
|       `-- fabulous_spi/
|           |-- fabulous_spi.c
|           |-- fabulous_spi.py
|           |-- fabulous_spi.yaml
|           `-- runtime_spi_bitstream.h
|-- Makefile
`-- README.md
```

### Main Components

| Component | Description |
|---|---|
| `fabric_config.v` | Converts processor configuration writes into FPGA frame data and strobes. |
| `fabulous_control.v` | Provides the Wishbone configuration and control registers. |
| `fabulous_fabric_adapter.v` | Connects the generated FPGA fabric to the fixed Caravel interface. |
| `fabulous_sim.v` | Generated FPGA model used during RTL simulation. |
| `user_project_wrapper.v` | Integrates the control interface and FPGA into Caravel. |
| `fabulous_spi.c` | Management RISC-V firmware for configuration and SPI testing. |
| `fabulous_spi.py` | Cocotb test and external SPI memory model. |
| `runtime_spi_bitstream.h` | Generated FPGA configuration data used by firmware. |

## Getting Started

### Prerequisites

- Linux
- Git
- Docker
- Python 3.8 or newer
- ChipFoundry CLI

Install the required command-line tools:

```bash
sudo apt-get update
sudo apt-get install -y git python3 python3-pip docker.io
python3 -m pip install --user chipfoundry-cli
```

### Clone the Repository

```bash
git clone https://github.com/Baavanes/caravel_user_project_FPGA.git
cd caravel_user_project_FPGA
```

### Initialize the Caravel Environment

```bash
cf login
cf init
cf setup
cf gpio-config
```

`cf setup` installs the Caravel simulation environment, management-core model,
PDK and hardening tools required by the project.

## Functional Verification

Run the SPI cocotb test with the ChipFoundry CLI:

```bash
cf verify fabulous_spi
```

The test performs the following checks:

- Caravel management-processor startup.
- Wishbone access to the FPGA configuration interface.
- FPGA bitstream loading.
- FPGA configuration completion.
- SPI write transaction.
- SPI read transaction.
- Firmware and cocotb result checking.

A successful run reports:

```text
TESTS=1 PASS=1 FAIL=0
```

The cocotb source and RISC-V firmware are located under:

```text
verilog/dv/cocotb/fabulous_spi/
```

## OpenLane Hardening

The FPGA macro physical views used by the wrapper flow are located at:

```text
gds/tiny_fabric_5x5.gds
lef/tiny_fabric_5x5.lef
```

Run the Caravel wrapper hardening flow with:

```bash
cf harden user_project_wrapper
```

The OpenLane wrapper configuration is located at:

```text
openlane/user_project_wrapper/config.json
```

After hardening, use the ChipFoundry verification and precheck commands that
are appropriate for the target shuttle or development environment.

## Changing the FPGA Function

The FPGA function is selected by its bitstream. To implement a different
function:

1. Create RTL using the supported FPGA interface.
2. Synthesize and place-and-route the design for the 5x5 FABulous fabric.
3. Generate the new FPGA bitstream.
4. Convert the bitstream into a firmware-compatible data array.
5. Update the RISC-V firmware to load and exercise the new design.
6. Add cocotb checks for the new functionality.
7. Run the FPGA-level and full Caravel verification flows.

The same physical FPGA macro and Caravel wrapper can be reused when the new
design fits in the available fabric and uses the existing interface.

## License

This project retains the Apache 2.0 license and notices of the ChipFoundry
Caravel user-project template. Third-party components remain under their
respective licenses. See [LICENSE](LICENSE) for details.
