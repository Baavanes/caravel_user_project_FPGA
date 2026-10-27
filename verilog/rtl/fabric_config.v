// SPDX-License-Identifier: Apache-2.0

`default_nettype none

// Converts the 32-bit FABulous bitstream stream written by the management
// RISC-V into the 5x5 fabric's FrameData and FrameStrobe configuration ports.
module fabric_config #(
    parameter FRAME_BITS_PER_ROW = 32,
    parameter MAX_FRAMES_PER_COL = 20,
    parameter FRAME_SELECT_WIDTH = 5,
    parameter FABRIC_NUM_COLUMNS = 5,
    parameter FABRIC_NUM_ROWS = 5
) (
    input  wire clk_i,
    input  wire rst_ni,
    input  wire [31:0] bitstream_data_i,
    input  wire bitstream_valid_i,
    output wire busy_o,
    output reg  configured_o,
    output wire [(FRAME_BITS_PER_ROW*FABRIC_NUM_ROWS)-1:0] frame_data_o,
    output wire [(MAX_FRAMES_PER_COL*FABRIC_NUM_COLUMNS)-1:0] frame_strobe_o
);
    localparam [31:0] BITSTREAM_START = 32'hFAB0FAB1;
    localparam integer DESYNC_FLAG = 20;
    localparam [1:0] S_IDLE = 2'd0;
    localparam [1:0] S_HEADER = 2'd1;
    localparam [1:0] S_DATA = 2'd2;

    reg [1:0] state;
    reg [1:0] next_state;
    reg [$clog2(FABRIC_NUM_COLUMNS)-1:0] column_select;
    reg [MAX_FRAMES_PER_COL-1:0] frame_select;
    reg frame_strobe;
    reg [$clog2(FABRIC_NUM_ROWS+1)-1:0] row_select;
    reg [(FRAME_BITS_PER_ROW*FABRIC_NUM_ROWS)-1:0] frame_data_reg;

    wire row_strobe = (state == S_DATA) && bitstream_valid_i;
    assign busy_o = state != S_IDLE;
    assign frame_data_o = frame_data_reg;

    always @* begin
        next_state = state;
        case (state)
            S_IDLE:   if (bitstream_valid_i && bitstream_data_i == BITSTREAM_START) next_state = S_HEADER;
            S_HEADER: if (bitstream_valid_i && bitstream_data_i[DESYNC_FLAG]) next_state = S_IDLE;
                      else if (bitstream_valid_i) next_state = S_DATA;
            S_DATA:   if (bitstream_valid_i && row_select == 0) next_state = S_HEADER;
            default:  next_state = S_IDLE;
        endcase
    end

    always @(posedge clk_i) begin
        if (!rst_ni) begin
            state <= S_IDLE;
            configured_o <= 1'b0;
        end else begin
            state <= next_state;
            if (state == S_IDLE && bitstream_valid_i && bitstream_data_i == BITSTREAM_START)
                configured_o <= 1'b0;
            if (state == S_HEADER && bitstream_valid_i && bitstream_data_i[DESYNC_FLAG])
                configured_o <= 1'b1;
        end
    end

    always @(posedge clk_i) begin
        if (!rst_ni) begin
            column_select <= 0;
            frame_select <= 0;
            frame_strobe <= 1'b0;
            row_select <= 0;
        end else begin
            frame_strobe <= 1'b0;
            case (state)
                S_IDLE: begin
                    column_select <= 0;
                    frame_select <= 0;
                    row_select <= 0;
                end
                S_HEADER: if (bitstream_valid_i && !bitstream_data_i[DESYNC_FLAG]) begin
                    frame_select <= bitstream_data_i[MAX_FRAMES_PER_COL-1:0];
                    column_select <= bitstream_data_i[FRAME_BITS_PER_ROW-1 -: FRAME_SELECT_WIDTH];
                    row_select <= FABRIC_NUM_ROWS-1;
                end
                S_DATA: if (bitstream_valid_i) begin
                    row_select <= row_select - 1'b1;
                    if (row_select == 0) frame_strobe <= 1'b1;
                end
            endcase
        end
    end

    genvar row;
    generate for (row = 0; row < FABRIC_NUM_ROWS; row = row + 1) begin : gen_framedata
        always @(posedge clk_i) begin
            if (row_strobe && row_select == row)
                frame_data_reg[FRAME_BITS_PER_ROW*row +: FRAME_BITS_PER_ROW] <= bitstream_data_i;
        end
    end endgenerate

    genvar col;
    generate for (col = 0; col < FABRIC_NUM_COLUMNS; col = col + 1) begin : gen_framestrobe
        assign frame_strobe_o[MAX_FRAMES_PER_COL*col +: MAX_FRAMES_PER_COL] =
            (column_select == col && frame_strobe) ? frame_select : {MAX_FRAMES_PER_COL{1'b0}};
    end endgenerate
endmodule

`default_nettype wire
