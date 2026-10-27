// SPDX-License-Identifier: Apache-2.0

`default_nettype none

// Gives the generated FABulous macro a stable 26-bit pad-vector interface.
module fabulous_fabric_adapter (
    input  wire [25:0]  pad_in,
    output wire [25:0]  pad_out,
    output wire [25:0]  pad_oeb,
    input  wire [159:0] frame_data,
    input  wire [99:0]  frame_strobe
);
    tiny_fabric_5x5 fabric (
        .Tile_X0Y2_A_OUT_top(pad_in[0]),  .Tile_X0Y2_A_IN_top(pad_out[0]),  .Tile_X0Y2_A_EN_top(pad_oeb[0]),
        .Tile_X0Y2_B_OUT_top(pad_in[1]),  .Tile_X0Y2_B_IN_top(pad_out[1]),  .Tile_X0Y2_B_EN_top(pad_oeb[1]),
        .Tile_X0Y3_A_OUT_top(pad_in[2]),  .Tile_X0Y3_A_IN_top(pad_out[2]),  .Tile_X0Y3_A_EN_top(pad_oeb[2]),
        .Tile_X0Y3_B_OUT_top(pad_in[3]),  .Tile_X0Y3_B_IN_top(pad_out[3]),  .Tile_X0Y3_B_EN_top(pad_oeb[3]),
        .Tile_X0Y3_C_OUT_top(pad_in[4]),  .Tile_X0Y3_C_IN_top(pad_out[4]),  .Tile_X0Y3_C_EN_top(pad_oeb[4]),
        .Tile_X0Y3_D_OUT_top(pad_in[5]),  .Tile_X0Y3_D_IN_top(pad_out[5]),  .Tile_X0Y3_D_EN_top(pad_oeb[5]),
        .Tile_X0Y1_A_OUT_top(pad_in[6]),  .Tile_X0Y1_A_IN_top(pad_out[6]),  .Tile_X0Y1_A_EN_top(pad_oeb[6]),
        .Tile_X0Y1_B_OUT_top(pad_in[7]),  .Tile_X0Y1_B_IN_top(pad_out[7]),  .Tile_X0Y1_B_EN_top(pad_oeb[7]),
        .Tile_X0Y1_C_OUT_top(pad_in[8]),  .Tile_X0Y1_C_IN_top(pad_out[8]),  .Tile_X0Y1_C_EN_top(pad_oeb[8]),
        .Tile_X0Y1_D_OUT_top(pad_in[9]),  .Tile_X0Y1_D_IN_top(pad_out[9]),  .Tile_X0Y1_D_EN_top(pad_oeb[9]),
        .Tile_X4Y3_A_OUT_top(pad_in[10]), .Tile_X4Y3_A_IN_top(pad_out[10]), .Tile_X4Y3_A_EN_top(pad_oeb[10]),
        .Tile_X4Y3_B_OUT_top(pad_in[11]), .Tile_X4Y3_B_IN_top(pad_out[11]), .Tile_X4Y3_B_EN_top(pad_oeb[11]),
        .Tile_X4Y3_C_OUT_top(pad_in[12]), .Tile_X4Y3_C_IN_top(pad_out[12]), .Tile_X4Y3_C_EN_top(pad_oeb[12]),
        .Tile_X4Y3_D_OUT_top(pad_in[13]), .Tile_X4Y3_D_IN_top(pad_out[13]), .Tile_X4Y3_D_EN_top(pad_oeb[13]),
        .Tile_X4Y1_A_OUT_top(pad_in[14]), .Tile_X4Y1_A_IN_top(pad_out[14]), .Tile_X4Y1_A_EN_top(pad_oeb[14]),
        .Tile_X4Y1_B_OUT_top(pad_in[15]), .Tile_X4Y1_B_IN_top(pad_out[15]), .Tile_X4Y1_B_EN_top(pad_oeb[15]),
        .Tile_X4Y1_C_OUT_top(pad_in[16]), .Tile_X4Y1_C_IN_top(pad_out[16]), .Tile_X4Y1_C_EN_top(pad_oeb[16]),
        .Tile_X4Y1_D_OUT_top(pad_in[17]), .Tile_X4Y1_D_IN_top(pad_out[17]), .Tile_X4Y1_D_EN_top(pad_oeb[17]),
        .Tile_X1Y4_A_OUT_top(pad_in[18]), .Tile_X1Y4_A_IN_top(pad_out[18]), .Tile_X1Y4_A_EN_top(pad_oeb[18]),
        .Tile_X1Y4_B_OUT_top(pad_in[19]), .Tile_X1Y4_B_IN_top(pad_out[19]), .Tile_X1Y4_B_EN_top(pad_oeb[19]),
        .Tile_X1Y4_C_OUT_top(pad_in[20]), .Tile_X1Y4_C_IN_top(pad_out[20]), .Tile_X1Y4_C_EN_top(pad_oeb[20]),
        .Tile_X1Y4_D_OUT_top(pad_in[21]), .Tile_X1Y4_D_IN_top(pad_out[21]), .Tile_X1Y4_D_EN_top(pad_oeb[21]),
        .Tile_X3Y4_A_OUT_top(pad_in[22]), .Tile_X3Y4_A_IN_top(pad_out[22]), .Tile_X3Y4_A_EN_top(pad_oeb[22]),
        .Tile_X3Y4_B_OUT_top(pad_in[23]), .Tile_X3Y4_B_IN_top(pad_out[23]), .Tile_X3Y4_B_EN_top(pad_oeb[23]),
        .Tile_X3Y4_C_OUT_top(pad_in[24]), .Tile_X3Y4_C_IN_top(pad_out[24]), .Tile_X3Y4_C_EN_top(pad_oeb[24]),
        .Tile_X3Y4_D_OUT_top(pad_in[25]), .Tile_X3Y4_D_IN_top(pad_out[25]), .Tile_X3Y4_D_EN_top(pad_oeb[25]),
        .Tile_X0Y4_SYS_RESET_RESET_top(1'b0),
        .FrameData(frame_data),
        .FrameStrobe(frame_strobe)
    );
endmodule

`default_nettype wire
