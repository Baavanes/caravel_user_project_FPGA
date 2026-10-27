// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_project_wrapper
 *
 * This wrapper enumerates all of the pins available to the
 * user for the user project.
 *
 * An example user project is provided in this wrapper.  The
 * example should be removed and replaced with the actual
 * user project.
 *
 *-------------------------------------------------------------
 */

module user_project_wrapper #(
    parameter BITS = 32
) (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // Analog (direct connection to GPIO pad---use with caution)
    // Note that analog I/O is not available on the 7 lowest-numbered
    // GPIO pads, and so the analog_io indexing is offset from the
    // GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
    inout [`MPRJ_IO_PADS-10:0] analog_io,

    // Independent clock (on independent integer divider)
    input   user_clock2,

    // User maskable interrupt signals
    output [2:0] user_irq
);

    wire [159:0] frame_data;
    wire [99:0] frame_strobe;
    wire [25:0] fabric_pad_in;
    wire [25:0] fabric_pad_out;
    wire [25:0] fabric_pad_oeb;
    wire configured;
    wire config_busy;
    wire spi_busy;
    wire spi_done;
    wire spi_sclk;
    wire spi_mosi;
    wire spi_cs_n;
    wire [1:0] test_status;

    fabulous_control control (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stb_i),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ack_o),
        .wbs_dat_o(wbs_dat_o),
        .spi_miso_i(io_in[10]),
        .spi_sclk_o(spi_sclk),
        .spi_mosi_o(spi_mosi),
        .spi_cs_n_o(spi_cs_n),
        .frame_data_o(frame_data),
        .frame_strobe_o(frame_strobe),
        .fabric_pad_in_o(fabric_pad_in),
        .fabric_pad_out_i(fabric_pad_out),
        .configured_o(configured),
        .config_busy_o(config_busy),
        .spi_busy_o(spi_busy),
        .spi_done_o(spi_done),
        .test_status_o(test_status)
    );

    fabulous_fabric_adapter fabric_adapter (
        .pad_in(fabric_pad_in),
        .pad_out(fabric_pad_out),
        .pad_oeb(fabric_pad_oeb),
        .frame_data(frame_data),
        .frame_strobe(frame_strobe)
    );

    // GPIO 8..11 form the external SPI bus.  GPIO 12 reports configuration.
    reg [`MPRJ_IO_PADS-1:0] io_out_reg;
    reg [`MPRJ_IO_PADS-1:0] io_oeb_reg;
    always @* begin
        io_out_reg = {`MPRJ_IO_PADS{1'b0}};
        io_oeb_reg = {`MPRJ_IO_PADS{1'b1}};
        io_out_reg[8] = spi_sclk;
        io_oeb_reg[8] = 1'b0;
        io_out_reg[9] = spi_mosi;
        io_oeb_reg[9] = 1'b0;
        io_oeb_reg[10] = 1'b1;
        io_out_reg[11] = spi_cs_n;
        io_oeb_reg[11] = 1'b0;
        io_out_reg[12] = configured;
        io_oeb_reg[12] = 1'b0;
        io_out_reg[14:13] = test_status;
        io_oeb_reg[14:13] = 2'b00;
    end
    assign io_out = io_out_reg;
    assign io_oeb = io_oeb_reg;

    // Debug visibility without affecting normal operation.
    assign la_data_out = {64'd0, fabric_pad_out, 34'd0,
                          spi_done, spi_busy, config_busy, configured};
    assign user_irq = {2'b00, spi_done};

    wire unused = &{1'b0, la_data_in, la_oenb, user_clock2,
                    fabric_pad_oeb};

endmodule	// user_project_wrapper

`default_nettype wire
