// SPDX-License-Identifier: Apache-2.0

`default_nettype none

// Fixed Caravel shell around the reconfigurable FABulous macro.
// The management RISC-V reaches these registers over the user Wishbone bus.
module fabulous_control (
    input  wire        wb_clk_i,
    input  wire        wb_rst_i,
    input  wire        wbs_stb_i,
    input  wire        wbs_cyc_i,
    input  wire        wbs_we_i,
    input  wire [3:0]  wbs_sel_i,
    input  wire [31:0] wbs_dat_i,
    input  wire [31:0] wbs_adr_i,
    output reg         wbs_ack_o,
    output reg  [31:0] wbs_dat_o,

    input  wire        spi_miso_i,
    output wire        spi_sclk_o,
    output wire        spi_mosi_o,
    output wire        spi_cs_n_o,

    output wire [159:0] frame_data_o,
    output wire [99:0]  frame_strobe_o,
    output wire [25:0]  fabric_pad_in_o,
    input  wire [25:0]  fabric_pad_out_i,
    output wire         configured_o,
    output wire         config_busy_o,
    output wire         spi_busy_o,
    output wire         spi_done_o,
    output wire [1:0]   test_status_o
);
    localparam [7:0] REG_ID            = 8'h00;
    localparam [7:0] REG_CONFIG_DATA   = 8'h04;
    localparam [7:0] REG_CONFIG_STATUS = 8'h08;
    localparam [7:0] REG_CONTROL       = 8'h0c;
    localparam [7:0] REG_TX_DATA       = 8'h10;
    localparam [7:0] REG_RX_DATA       = 8'h14;
    localparam [7:0] REG_SPI_STATUS    = 8'h18;
    localparam [7:0] REG_FABRIC_INPUT  = 8'h1c;
    localparam [7:0] REG_FABRIC_OUTPUT = 8'h20;
    localparam [7:0] REG_TEST_STATUS   = 8'h24;

    wire wb_valid = wbs_cyc_i && wbs_stb_i;
    wire [7:0] reg_addr = wbs_adr_i[7:0];

    reg [31:0] config_data;
    reg        config_valid;
    reg [7:0]  tx_data;
    reg        start_pulse;
    reg        hold_cs;
    reg        fabric_reset;
    reg [25:0] generic_input;
    reg [1:0]  test_status;
    assign test_status_o = test_status;

    wire [7:0] rx_data = fabric_pad_out_i[17:10];
    assign spi_sclk_o = fabric_pad_out_i[21];
    assign spi_mosi_o = fabric_pad_out_i[22];
    assign spi_cs_n_o = fabric_pad_out_i[23];
    assign spi_busy_o = fabric_pad_out_i[24];
    wire fabric_spi_done = fabric_pad_out_i[25];
    reg spi_done_sticky;
    assign spi_done_o = spi_done_sticky;

    // The fixed pin ABI is shared by every runtime bitstream.
    reg [25:0] fabric_pad_in;
    always @* begin
        fabric_pad_in = generic_input;
        fabric_pad_in[0] = wb_clk_i;
        fabric_pad_in[1] = fabric_reset;
        fabric_pad_in[9:2] = tx_data;
        fabric_pad_in[18] = start_pulse;
        fabric_pad_in[19] = spi_miso_i;
        fabric_pad_in[20] = hold_cs;
    end
    assign fabric_pad_in_o = fabric_pad_in;

    fabric_config #(
        .FABRIC_NUM_COLUMNS(5),
        .FABRIC_NUM_ROWS(5)
    ) config_loader (
        .clk_i(wb_clk_i),
        .rst_ni(~wb_rst_i),
        .bitstream_data_i(config_data),
        .bitstream_valid_i(config_valid),
        .busy_o(config_busy_o),
        .configured_o(configured_o),
        .frame_data_o(frame_data_o),
        .frame_strobe_o(frame_strobe_o)
    );

    always @* begin
        case (reg_addr)
            REG_ID:            wbs_dat_o = 32'hFAB5_0001;
            REG_CONFIG_STATUS: wbs_dat_o = {30'd0, config_busy_o, configured_o};
            REG_CONTROL:       wbs_dat_o = {29'd0, fabric_reset, hold_cs, 1'b0};
            REG_TX_DATA:       wbs_dat_o = {24'd0, tx_data};
            REG_RX_DATA:       wbs_dat_o = {24'd0, rx_data};
            REG_SPI_STATUS:    wbs_dat_o = {30'd0, spi_done_o, spi_busy_o};
            REG_FABRIC_INPUT:  wbs_dat_o = {6'd0, generic_input};
            REG_FABRIC_OUTPUT: wbs_dat_o = {6'd0, fabric_pad_out_i};
            REG_TEST_STATUS:   wbs_dat_o = {30'd0, test_status};
            default:           wbs_dat_o = 32'd0;
        endcase
    end

    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            wbs_ack_o <= 1'b0;
            config_data <= 32'd0;
            config_valid <= 1'b0;
            tx_data <= 8'd0;
            start_pulse <= 1'b0;
            hold_cs <= 1'b0;
            fabric_reset <= 1'b1;
            generic_input <= 26'd0;
            test_status <= 2'd0;
            spi_done_sticky <= 1'b0;
        end else begin
            wbs_ack_o <= 1'b0;
            config_valid <= 1'b0;
            start_pulse <= 1'b0;
            if (fabric_spi_done) spi_done_sticky <= 1'b1;

            if (wb_valid && !wbs_ack_o) begin
                wbs_ack_o <= 1'b1;
                if (wbs_we_i) begin
                    case (reg_addr)
                        REG_CONFIG_DATA: if (&wbs_sel_i) begin
                            config_data <= wbs_dat_i;
                            config_valid <= 1'b1;
                        end
                        REG_CONTROL: if (wbs_sel_i[0]) begin
                            start_pulse <= wbs_dat_i[0];
                            hold_cs <= wbs_dat_i[1];
                            fabric_reset <= wbs_dat_i[2];
                            if (wbs_dat_i[0]) spi_done_sticky <= 1'b0;
                        end
                        REG_TX_DATA: if (wbs_sel_i[0]) tx_data <= wbs_dat_i[7:0];
                        REG_FABRIC_INPUT: begin
                            if (wbs_sel_i[0]) generic_input[7:0] <= wbs_dat_i[7:0];
                            if (wbs_sel_i[1]) generic_input[15:8] <= wbs_dat_i[15:8];
                            if (wbs_sel_i[2]) generic_input[23:16] <= wbs_dat_i[23:16];
                            if (wbs_sel_i[3]) generic_input[25:24] <= wbs_dat_i[25:24];
                        end
                        REG_TEST_STATUS: if (wbs_sel_i[0]) test_status <= wbs_dat_i[1:0];
                    endcase
                end
            end
        end
    end
endmodule

`default_nettype wire
