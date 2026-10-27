// Generated from the SKY130 FABulous build; do not edit by hand.
// Copyright 2021 University of Manchester
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//	  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CoNDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

module LUTK #(
    parameter K=4,
    parameter LUT_ENTRIES = 2**K
)(
    input [K-1:0] I,
    input [LUT_ENTRIES-1:0] INIT,
    output O
);

    generate
    
    if (K == 1) begin : LUT1
        assign O = I ? INIT[1] : INIT[0];
    end else begin : split_LUT
        wire lower_O, upper_O;
    
        parameter LUT_ENTRIES_HALF = 2**(K-1);
    
        LUTK #(
          .K (K-1)
        ) LUTK_lower (
          .I    (I[K-2:0]),
          .INIT (INIT[LUT_ENTRIES_HALF-1:0]),
          .O    (lower_O)
        );
        
        LUTK #(
          .K (K-1)
        ) LUTK_upper (
          .I    (I[K-2:0]),
          .INIT (INIT[LUT_ENTRIES-1:LUT_ENTRIES_HALF]),
          .O    (upper_O)
        );
        
        assign O = I[K-1] ? upper_O : lower_O;
    end
    
    endgenerate

endmodule

// Note: nextpnr also has support for ASYNC_SR and NEG_CLK
(*FABulous, BelMap,
    INIT=0,
    INIT_1=1,
    INIT_2=2,
    INIT_3=3,
    INIT_4=4,
    INIT_5=5,
    INIT_6=6,
    INIT_7=7,
    INIT_8=8,
    INIT_9=9,
    INIT_10=10,
    INIT_11=11,
    INIT_12=12,
    INIT_13=13,
    INIT_14=14,
    INIT_15=15,
    FF=16,
    I0mux=17,
    SET_NORESET=18
*)
module FABULOUS_LC #(
    // #LUT inputs
    parameter K=4,
  	  parameter LUT_ENTRIES = 2**K,
    
    // ConfigBits has to be adjusted manually (we don't use an arithmetic parser for the value)
    parameter N_CONFIG_BITS = LUT_ENTRIES + 3
)(
    input [K-1:0] I,   // Vector for I0, I1, I2, I3 ...
    output        O,   // Single output for LUT result
    input         Ci,  // Carry chain input
    output        Co,  // Carry chain output
    input         SR,  // Shared reset
    input         EN,  // Shared enable
    input         CLK, // Sahred clock
    
    (* FABulous, GLOBAL *) input [N_CONFIG_BITS-1:0] ConfigBits // Config bits as vector
);

    // Configuration bits
	  wire [LUT_ENTRIES-1 : 0] INIT;
	  wire FF, I0mux, SET_NORESET;

	  assign INIT   = ConfigBits[LUT_ENTRIES-1:0];
	  assign FF           = ConfigBits[LUT_ENTRIES+0];
	  assign I0mux        = ConfigBits[LUT_ENTRIES+1];
	  assign SET_NORESET  = ConfigBits[LUT_ENTRIES+2];

    // Signals
	  wire [K-1 : 0] LUT_index;
	  wire LUT_out;
	  reg  LUT_flop;
	  wire I0mux_wire; // normal input '0', or carry input '1'

	  assign I0mux_wire = I0mux ? Ci : I[0];

	  assign LUT_index = {I[K-1:1], I0mux_wire};

    // The look-up table
    LUTK #(
        .K (4)
    ) LUT4 (
        .I    (LUT_index),
        .INIT (INIT),
        .O    (LUT_out)
    );

	  assign O = FF ? LUT_flop : LUT_out;
	  
	  // iCE40 like carry chain (as this is supported in Yosys; would normally go for fractured LUT)
	  assign Co = (Ci & I[1]) | (Ci & I[2]) | (I[1] & I[2]);

	  always @ (posedge CLK) begin
        if (SR) begin
            LUT_flop <= SET_NORESET;
        end else begin
            if (EN) begin
                LUT_flop <= LUT_out;
            end
        end
	  end

endmodule

// Copyright 2026 FABulous Contributors
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

(*FABulous, BelMap,
    INVERT=0
*)
module GBUF #(
    // ConfigBits has to be adjusted manually (we don't use an arithmetic parser for the value)
    parameter N_CONFIG_BITS = 1
)(
    // Fabric side
    input  IN,
    output OUT,
    
    (* FABulous, GLOBAL *) input [N_CONFIG_BITS-1:0] ConfigBits // Config bits as vector
);

    wire INVERT;
  	  assign INVERT = ConfigBits[0];

    assign OUT = INVERT ? ~IN : IN;

endmodule

// Copyright 2026 FABulous Contributors
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

(* FABulous, BelMap,
OUT_REG=0
*)
module IBUF #(
    parameter NoConfigBits = 1
)(
    // Fabric side
    input  CLK,
    output OUT,

    // External side
    (* FABulous, EXTERNAL *) input  OUT_top,

    // Static configuration bits
    (* FABulous, GLOBAL *) input [NoConfigBits-1:0] ConfigBits
);
    logic OUT_top_q;

    always_ff @(posedge CLK) begin
        OUT_top_q <= OUT_top;
    end

    // External -> Fabric
    assign OUT = ConfigBits[2] ? OUT_top_q : OUT_top;

endmodule

// Copyright 2026 FABulous Contributors
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

(* FABulous, BelMap,
INIT_Q0=0,
INIT_Q1=1
*)
module IDDR #(
    parameter NoConfigBits = 2
)(
    // Fabric side
    input  CLK,
    input  EN,
    input  SR,
    input  D,
    output Q0,
    output Q1,

    // Static configuration bits
    (* FABulous, GLOBAL *) input [NoConfigBits-1:0] ConfigBits
);
    // Static configuration
    wire INIT_Q0, INIT_Q1;
    
    assign INIT_Q0 = ConfigBits[0];
    assign INIT_Q1 = ConfigBits[1];

    // Functionality
    logic D0_q, D1_q;

    always_ff @(posedge CLK) begin
        if (SR) begin
            D0_q <= INIT_Q0;
        end else begin
            if (EN) begin
                D0_q  <= D;
            end
        end
    end
    
    always_ff @(negedge CLK) begin
        if (SR) begin
            D1_q <= INIT_Q1;
        end else begin
            if (EN) begin
                D1_q  <= D;
            end
        end
    end
    
    assign Q0 = D0_q;
    assign Q1 = D1_q;

endmodule

// Copyright 2026 FABulous Contributors
// Copyright 2025 Leo Moser
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

(* FABulous, BelMap,
A_CLK_INV=0,
B_CLK_INV=1
*)
module IHP_SRAM_1024x16_2RW #(
    parameter NoConfigBits = 2
)(
    // Fabric side
    input                 A_CLK,
    input  [(10 - 1) : 0] A_ADDR,
    input  [(16 - 1) : 0] A_DIN,
    input  [(16 - 1) : 0] A_BM,
    input                 A_WEN,
    input                 A_MEN,
    input                 A_REN,
    	output [(16 - 1) : 0] A_DOUT,

    // Fabric side
    input                 B_CLK,
    input  [(10 - 1) : 0] B_ADDR,
    input  [(16 - 1) : 0] B_DIN,
    input  [(16 - 1) : 0] B_BM,
    input                 B_WEN,
    input                 B_MEN,
    input                 B_REN,
    	output [(16 - 1) : 0] B_DOUT,

    // External side
    (* FABulous, EXTERNAL *) output                A_CLK_SRAM,
    (* FABulous, EXTERNAL *) output [(10 - 1) : 0] A_ADDR_SRAM,
    (* FABulous, EXTERNAL *) output [(16 - 1) : 0] A_DIN_SRAM,
    (* FABulous, EXTERNAL *) output [(16 - 1) : 0] A_BM_SRAM,
    (* FABulous, EXTERNAL *) output                A_WEN_SRAM,
    (* FABulous, EXTERNAL *) output                A_MEN_SRAM,
    (* FABulous, EXTERNAL *) output                A_REN_SRAM,
    (* FABulous, EXTERNAL *) input  [(16 - 1) : 0] A_DOUT_SRAM,

    (* FABulous, EXTERNAL *) output                B_CLK_SRAM,
    (* FABulous, EXTERNAL *) output [(10 - 1) : 0] B_ADDR_SRAM,
    (* FABulous, EXTERNAL *) output [(16 - 1) : 0] B_DIN_SRAM,
    (* FABulous, EXTERNAL *) output [(16 - 1) : 0] B_BM_SRAM,
    (* FABulous, EXTERNAL *) output                B_WEN_SRAM,
    (* FABulous, EXTERNAL *) output                B_MEN_SRAM,
    (* FABulous, EXTERNAL *) output                B_REN_SRAM,
    (* FABulous, EXTERNAL *) input  [(16 - 1) : 0] B_DOUT_SRAM,

    (* FABulous, EXTERNAL *) output                TIE_HIGH_SRAM,
    (* FABulous, EXTERNAL *) output                TIE_LOW_SRAM,
    
    (* FABulous, EXTERNAL *) input                 CONFIGURED_top,

    // Static configuration bits
    (* FABulous, GLOBAL *) input [NoConfigBits-1:0] ConfigBits
);
    // Configuration bits
    wire A_CLK_INV, B_CLK_INV;
    assign A_CLK_INV = ConfigBits[0];
    assign B_CLK_INV = ConfigBits[1];

    // Fabric -> External
    assign A_CLK_SRAM     = A_CLK_INV ? !A_CLK : A_CLK;
    assign A_ADDR_SRAM    = A_ADDR;
    assign A_DIN_SRAM     = A_DIN;
    assign A_BM_SRAM      = A_BM;
    assign A_WEN_SRAM     = A_WEN;
    // Only enable the SRAM if the fabric is configured
    assign A_MEN_SRAM     = A_MEN && CONFIGURED_top;
    assign A_REN_SRAM     = A_REN;
    
    assign B_CLK_SRAM     = B_CLK_INV ? !B_CLK : B_CLK;
    assign B_ADDR_SRAM    = B_ADDR;
    assign B_DIN_SRAM     = B_DIN;
    assign B_BM_SRAM      = B_BM;
    assign B_WEN_SRAM     = B_WEN;
    // Only enable the SRAM if the fabric is configured
    assign B_MEN_SRAM     = B_MEN && CONFIGURED_top;
    assign B_REN_SRAM     = B_REN;
    
    // External -> Fabric
    assign A_DOUT         = A_DOUT_SRAM;

    assign B_DOUT         = B_DOUT_SRAM;

    // Constants
    assign TIE_HIGH_SRAM = 1'b1;
    assign TIE_LOW_SRAM  = 1'b0;

endmodule

// Copyright 2026 FABulous Contributors
// Copyright 2025 Leo Moser
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

(* FABulous, BelMap,
CLK_INV=0
*)
module IHP_SRAM_1024x32_1RW #(
    parameter NoConfigBits = 1
)(
    // Fabric side
    input                 CLK,
    input  [(10 - 1) : 0] ADDR,
    input  [(32 - 1) : 0] DIN,
    input  [(32 - 1) : 0] BM,
    input                 WEN,
    input                 MEN,
    input                 REN,
    	output [(32 - 1) : 0] DOUT,

    // External side
    (* FABulous, EXTERNAL *) output                CLK_SRAM,
    (* FABulous, EXTERNAL *) output [(10 - 1) : 0] ADDR_SRAM,
    (* FABulous, EXTERNAL *) output [(32 - 1) : 0] DIN_SRAM,
    (* FABulous, EXTERNAL *) output [(32 - 1) : 0] BM_SRAM,
    (* FABulous, EXTERNAL *) output                WEN_SRAM,
    (* FABulous, EXTERNAL *) output                MEN_SRAM,
    (* FABulous, EXTERNAL *) output                REN_SRAM,
    (* FABulous, EXTERNAL *) input  [(32 - 1) : 0] DOUT_SRAM,
    
    (* FABulous, EXTERNAL *) output                TIE_HIGH_SRAM,
    (* FABulous, EXTERNAL *) output                TIE_LOW_SRAM,
    
    (* FABulous, EXTERNAL *) input                 CONFIGURED_top,

    // Static configuration bits
    (* FABulous, GLOBAL *) input [NoConfigBits-1:0] ConfigBits
);
    // Configuration bits
    wire CLK_INV;
    assign CLK_INV = ConfigBits[0];

    // Fabric -> External
    assign CLK_SRAM     = CLK_INV ? !CLK : CLK;
    assign ADDR_SRAM    = ADDR;
    assign DIN_SRAM     = DIN;
    assign BM_SRAM      = BM;
    assign WEN_SRAM     = WEN;
    // Only enable the SRAM if the fabric is configured
    assign MEN_SRAM     = MEN && CONFIGURED_top;
    assign REN_SRAM     = REN;
    
    // External -> Fabric
    assign DOUT         = DOUT_SRAM;

    // Constants
    assign TIE_HIGH_SRAM = 1'b1;
    assign TIE_LOW_SRAM  = 1'b0;

endmodule

// Copyright 2026 FABulous Contributors
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

(* FABulous, BelMap,
EN_REG=0,
IN_REG=1,
OUT_REG=2
*)
module IOBUF #(
    parameter NoConfigBits = 3
)(
    // Fabric side
    input  CLK,
    input  IN,
    input  EN,
    output OUT,

    // External side
    (* FABulous, EXTERNAL *) output IN_top,
    (* FABulous, EXTERNAL *) output EN_top,
    (* FABulous, EXTERNAL *) input  OUT_top,

    // Static configuration bits
    (* FABulous, GLOBAL *) input [NoConfigBits-1:0] ConfigBits
);
    // Static configuration
    wire EN_REG, IN_REG, OUT_REG;
    
    assign EN_REG = ConfigBits[0];
    assign IN_REG = ConfigBits[1];
    assign OUT_REG = ConfigBits[2];

    // Functionality
    logic EN_q, IN_q, OUT_top_q;

    always_ff @(posedge CLK) begin
        EN_q  <= EN;
        IN_q  <= IN;
        OUT_top_q <= OUT_top;
    end

    // Fabric -> External
    assign IN_top = IN_REG ? IN_q : IN;
    assign EN_top = EN_REG ? EN_q : EN;

    // External -> Fabric
    assign OUT = OUT_REG ? OUT_top_q : OUT_top;

endmodule

// Copyright 2026 FABulous Contributors
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

(* FABulous, BelMap,
A_REG=0,
B_REG=1,
C_REG=2,
SIGN_EXT=3,
ACC_SEL=4,
ACC_OUT=5,
CLK_INV=6
*)
module MACC_8x8_20 #(
    parameter NoConfigBits = 7
)(
    // Fabric side
    input  CLK,
    input  EN,

    input  ACC_RST,
    input  ACC_CI,
    output ACC_CO,
    
    input  [ 7:0] A,
    input  [ 7:0] B,
    input  [19:0] C,
    
    output [19:0] Q,

    // Static configuration bits
    (* FABulous, GLOBAL *) input [NoConfigBits-1:0] ConfigBits
);
    // Configuration bits
    wire A_REG, B_REG, C_REG, MULTIPLY, SIGN_EXT, ACC_SEL, ACC_OUT, CLK_INV;

    assign A_REG = ConfigBits[0];
    assign B_REG = ConfigBits[1];
    assign C_REG = ConfigBits[2];
    assign SIGN_EXT = ConfigBits[3];
    assign ACC_SEL = ConfigBits[4];
    assign ACC_OUT = ConfigBits[5];
    assign CLK_INV = ConfigBits[6];

    // Clock inversion
    wire clk;
    assign clk = CLK_INV ? !CLK : CLK;

    // Registers the inputs
    logic [7:0] A_q, B_q;
    logic [19:0] C_q;

    always_ff @(posedge clk) begin
        if (EN) begin
            A_q <= A;
            B_q <= B;
            C_q <= C;
        end
    end
    
    // Select the operands
    logic [7:0] OPA, OPB;
    logic [19:0] OPC;
    
    assign OPA = A_REG ? A_q : A;
    assign OPB = B_REG ? B_q : B;
    assign OPC = C_REG ? C_q : C;
    
    // Multiplication
    wire [15:0] product;
    assign product = OPA * OPB;
    
    // Sign extension
    wire [19:0] extended;
    assign extended = SIGN_EXT ? {{4{product[15]}}, product} : {4'd0, product};

    // Addition
    wire [19:0] sum;

    // Accumulator
    logic [19:0] ACC;
    always_ff @(posedge clk) begin
        if (ACC_RST) begin
            ACC <= '0;
        end else begin
            if (EN) begin
                ACC <= sum;
            end
        end
    end

    assign {ACC_CO, sum} = extended + (ACC_SEL ? ACC : OPC) + ACC_CI;

    // Output
    assign Q = ACC_OUT ? ACC : sum;

endmodule

// Copyright 2026 FABulous Contributors
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

(* FABulous, BelMap,
EN_REG=0,
IN_REG=1
*)
module OBUF #(
    parameter NoConfigBits = 2
)(
    // Fabric side
    input  CLK,
    input  IN,
    input  EN,

    // External side
    (* FABulous, EXTERNAL *) output IN_top,
    (* FABulous, EXTERNAL *) output EN_top,

    // Static configuration bits
    (* FABulous, GLOBAL *) input [NoConfigBits-1:0] ConfigBits
);
    logic EN_q, IN_q;

    always_ff @(posedge CLK) begin
        EN_q  <= EN;
        IN_q  <= IN;
    end

    // Fabric -> External
    assign IN_top = ConfigBits[1] ? IN_q : IN;
    assign EN_top = ConfigBits[0] ? EN_q : EN;

endmodule

// Copyright 2026 FABulous Contributors
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

(* FABulous, BelMap,
INIT_Q0=0,
INIT_Q1=1
*)
module ODDR #(
    parameter NoConfigBits = 2
)(
    // Fabric side
    input  CLK,
    input  D0,
    input  D1,
    input  EN,
    input  SR,
    output Q,

    // Static configuration bits
    (* FABulous, GLOBAL *) input [NoConfigBits-1:0] ConfigBits
);
    // Static configuration
    wire INIT_Q0, INIT_Q1;
    
    assign INIT_Q0 = ConfigBits[0];
    assign INIT_Q1 = ConfigBits[1];

    // Functionality
    logic D0_q, D1_q;

    always_ff @(posedge CLK) begin
        if (SR) begin
            D0_q <= INIT_Q0;
        end else begin
            if (EN) begin
                D0_q  <= D0;
            end
        end
    end
    
    always_ff @(negedge CLK) begin
        if (SR) begin
            D1_q <= INIT_Q1;
        end else begin
            if (EN) begin
                D1_q  <= D1;
            end
        end
    end
    
    assign Q = CLK ? D0_q : D1_q;

endmodule

// Copyright 2026 FABulous Contributors
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

(* FABulous, BelMap,
B_REG=0,
C_REG=1,
A_CLK_INV=2,
B_CLK_INV=3,
C_CLK_INV=4
*)
module RAM_32x4_2R_1W #(
    parameter NoConfigBits = 5,
    parameter WIDTH=4,
    parameter DEPTH=5
)(
    // Fabric side
    
    // Port A - Write
    input              A_CLK,
    input  [DEPTH-1:0] A_ADDR,
    input              A_WEN,
    input  [WIDTH-1:0] A_DIN,

    // Port B - Read
    input              B_CLK,
    input  [DEPTH-1:0] B_ADDR,
    input              B_REN,
    output [WIDTH-1:0] B_DOUT,

    // Port C - Read
    input              C_CLK,
    input  [DEPTH-1:0] C_ADDR,
    input              C_REN,
    output [WIDTH-1:0] C_DOUT,

    // Static configuration bits
    (* FABulous, GLOBAL *) input [NoConfigBits-1:0] ConfigBits
);
    // Configuration bits
    wire B_REG, C_REG, A_CLK_INV, B_CLK_INV, C_CLK_INV;

    assign B_REG = ConfigBits[0];
    assign C_REG = ConfigBits[1];
    assign A_CLK_INV = ConfigBits[2];
    assign B_CLK_INV = ConfigBits[3];
    assign C_CLK_INV = ConfigBits[4];

    // Clock inversion
    wire a_clk, b_clk, c_clk;
    assign a_clk = A_CLK_INV ? !A_CLK : A_CLK;
    assign b_clk = B_CLK_INV ? !B_CLK : B_CLK;
    assign c_clk = C_CLK_INV ? !C_CLK : C_CLK;

    reg [WIDTH-1:0] mem [2**DEPTH];
    
    // Port A - Write
    always @(posedge a_clk) begin
        if (A_WEN) begin
            mem[A_ADDR] <= A_DIN;
        end
    end
    
    // Port B - Read
    wire [WIDTH-1:0] B_DOUT_comb;
    reg  [WIDTH-1:0] B_DOUT_reg;
    
    assign B_DOUT_comb = mem[B_ADDR];
    
    always @(posedge b_clk) begin
        if (B_REN) begin
            B_DOUT_reg <= B_DOUT_comb;
        end
    end
    
    assign B_DOUT = B_REG ? B_DOUT_reg : B_DOUT_comb;
    
    // Port C - Read
    wire [WIDTH-1:0] C_DOUT_comb;
    reg  [WIDTH-1:0] C_DOUT_reg;
    
    assign C_DOUT_comb = mem[C_ADDR];
    
    always @(posedge c_clk) begin
        if (C_REN) begin
            C_DOUT_reg <= C_DOUT_comb;
        end
    end
    
    assign C_DOUT = C_REG ? C_DOUT_reg : C_DOUT_comb;

endmodule

// Copyright 2026 FABulous Contributors
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

module SYS_RESET (
    // Fabric side
    output RESET,

    // External side
    (* FABulous, EXTERNAL *) input  RESET_top
);

    // Fabric -> External
    assign RESET = RESET_top;

endmodule

// Copyright 2026 FABulous Contributors
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

(* FABulous, BelMap,
EN_REG=0,
IN_REG=1
*)
module TBUF #(
    parameter NoConfigBits = 2
)(
    // Fabric side
    input  CLK,
    input  IN,
    input  EN,

    // External side
    (* FABulous, EXTERNAL *) output IN_top,
    (* FABulous, EXTERNAL *) output EN_top,

    // Static configuration bits
    (* FABulous, GLOBAL *) input [NoConfigBits-1:0] ConfigBits
);
    logic EN_q, IN_q;

    always_ff @(posedge CLK) begin
        EN_q  <= EN;
        IN_q  <= IN;
    end

    // Fabric -> External
    assign IN_top = ConfigBits[1] ? IN_q : IN;
    assign EN_top = ConfigBits[0] ? EN_q : EN;

endmodule

// Copyright 2026 FABulous Contributors
// Copyright 2025 Leo Moser
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

(*FABulous, BelMap,
    ENABLE_POWER=0
*)
module TT_PROJECT #(
    parameter N_CONFIG_BITS = 1
)(	
    // Fabric side
    input  wire [7:0] UI_IN,
    output wire [7:0] UO_OUT,
    input  wire [7:0] UIO_IN,
    output wire [7:0] UIO_OUT,
    output wire [7:0] UIO_OE,
    input  wire       ENA,
    input  wire       CLK,
    input  wire       RST_N,

    // External side
    (* FABulous, EXTERNAL *) output wire       ENABLE_POWER_TT_PROJECT,
    (* FABulous, EXTERNAL *) output wire [7:0] UI_IN_TT_PROJECT,
    (* FABulous, EXTERNAL *) input  wire [7:0] UO_OUT_TT_PROJECT,
    (* FABulous, EXTERNAL *) output wire [7:0] UIO_IN_TT_PROJECT,
    (* FABulous, EXTERNAL *) input  wire [7:0] UIO_OUT_TT_PROJECT,
    (* FABulous, EXTERNAL *) input  wire [7:0] UIO_OE_TT_PROJECT,
    (* FABulous, EXTERNAL *) output wire       ENA_TT_PROJECT,
    (* FABulous, EXTERNAL *) output wire       CLK_TT_PROJECT,
    (* FABulous, EXTERNAL *) output wire       RST_N_TT_PROJECT,
    
    (* FABulous, GLOBAL *) input [N_CONFIG_BITS-1:0] ConfigBits // Config bits as vector
);
    // Configuration bits
    wire ENABLE_POWER;
	  assign ENABLE_POWER = ConfigBits[0];

    // Fabric -> External
    assign ENABLE_POWER_TT_PROJECT = ENABLE_POWER;
    assign CLK_TT_PROJECT       = CLK;
    assign UI_IN_TT_PROJECT     = UI_IN;
    assign UIO_IN_TT_PROJECT    = UIO_IN;
    assign ENA_TT_PROJECT       = ENA;
    assign RST_N_TT_PROJECT     = RST_N;
    
    // External -> Fabric
    assign UO_OUT   = UO_OUT_TT_PROJECT;
    assign UIO_OUT  = UIO_OUT_TT_PROJECT;
    assign UIO_OE   = UIO_OE_TT_PROJECT;
    
    // User projects are power-gated
    // keep the outputs from floating
    
    generate
    // verilator lint_off ASSIGNIN
    for (genvar i=0; i<8; i++) begin : UO_OUT_TT_PROJECT_sighold
        bus_keeper sighold (
            .X (UO_OUT_TT_PROJECT[i])
        );
    end
    for (genvar i=0; i<8; i++) begin : UIO_OUT_TT_PROJECT_sighold
        bus_keeper sighold (
            .X (UIO_OUT_TT_PROJECT[i])
        );
    end
    for (genvar i=0; i<8; i++) begin : UIO_OE_TT_PROJECT_sighold
        bus_keeper sighold (
            .X (UIO_OE_TT_PROJECT[i])
        );
    end
    // verilator lint_on ASSIGNIN
    endgenerate

endmodule

// Copyright 2026 FABulous Contributors
// Copyright 2025 Leo Moser
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

(*FABulous, BelMap,
    ENABLE_POWER=0
*)
module TT_PROJECT_LARGE #(
    parameter N_CONFIG_BITS = 1
)(	
    // Fabric side
    input  wire [15:0] UI_IN,
    output wire [15:0] UO_OUT,
    input  wire [15:0] UIO_IN,
    output wire [15:0] UIO_OUT,
    output wire [15:0] UIO_OE,
    input  wire       ENA,
    input  wire       CLK,
    input  wire       RST_N,

    // External side
    (* FABulous, EXTERNAL *) output wire        ENABLE_POWER_TT_PROJECT,
    (* FABulous, EXTERNAL *) output wire [15:0] UI_IN_TT_PROJECT,
    (* FABulous, EXTERNAL *) input  wire [15:0] UO_OUT_TT_PROJECT,
    (* FABulous, EXTERNAL *) output wire [15:0] UIO_IN_TT_PROJECT,
    (* FABulous, EXTERNAL *) input  wire [15:0] UIO_OUT_TT_PROJECT,
    (* FABulous, EXTERNAL *) input  wire [15:0] UIO_OE_TT_PROJECT,
    (* FABulous, EXTERNAL *) output wire        ENA_TT_PROJECT,
    (* FABulous, EXTERNAL *) output wire        CLK_TT_PROJECT,
    (* FABulous, EXTERNAL *) output wire        RST_N_TT_PROJECT,
    
    (* FABulous, GLOBAL *) input [N_CONFIG_BITS-1:0] ConfigBits // Config bits as vector
);
    // Configuration bits
    wire ENABLE_POWER;
	  assign ENABLE_POWER = ConfigBits[0];

    // Fabric -> External
    assign ENABLE_POWER_TT_PROJECT = ENABLE_POWER;
    assign CLK_TT_PROJECT       = CLK;
    assign UI_IN_TT_PROJECT     = UI_IN;
    assign UIO_IN_TT_PROJECT    = UIO_IN;
    assign ENA_TT_PROJECT       = ENA;
    assign RST_N_TT_PROJECT     = RST_N;
    
    // External -> Fabric
    assign UO_OUT   = UO_OUT_TT_PROJECT;
    assign UIO_OUT  = UIO_OUT_TT_PROJECT;
    assign UIO_OE   = UIO_OE_TT_PROJECT;

    // User projects are power-gated
    // keep the outputs from floating
    
    generate
    // verilator lint_off ASSIGNIN
    for (genvar i=0; i<16; i++) begin : UO_OUT_TT_PROJECT_sighold
        bus_keeper sighold (
            .X (UO_OUT_TT_PROJECT[i])
        );
    end
    for (genvar i=0; i<16; i++) begin : UIO_OUT_TT_PROJECT_sighold
        bus_keeper sighold (
            .X (UIO_OUT_TT_PROJECT[i])
        );
    end
    for (genvar i=0; i<16; i++) begin : UIO_OE_TT_PROJECT_sighold
        bus_keeper sighold (
            .X (UIO_OE_TT_PROJECT[i])
        );
    end
    // verilator lint_on ASSIGNIN
    endgenerate

endmodule

// Copyright 2026 FABulous Contributors
// Copyright 2025 Leo Moser
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

(*FABulous, BelMap,
    ENABLE_POWER=0,
    SELECT_SLOT=1
*)
module TT_PROJECT_MUX #(
    parameter N_CONFIG_BITS = 2
)(	
    // Fabric side
    input  wire [7:0] UI_IN,
    output wire [7:0] UO_OUT,
    input  wire [7:0] UIO_IN,
    output wire [7:0] UIO_OUT,
    output wire [7:0] UIO_OE,
    input  wire       ENA,
    input  wire       CLK,
    input  wire       RST_N,

    // External side
    (* FABulous, EXTERNAL *) output wire       ENABLE_POWER_TT_PROJECT,
    (* FABulous, EXTERNAL *) output wire       SELECT_SLOT_TT_PROJECT,
    (* FABulous, EXTERNAL *) output wire [7:0] UI_IN_TT_PROJECT,
    (* FABulous, EXTERNAL *) input  wire [7:0] UO_OUT_TT_PROJECT,
    (* FABulous, EXTERNAL *) output wire [7:0] UIO_IN_TT_PROJECT,
    (* FABulous, EXTERNAL *) input  wire [7:0] UIO_OUT_TT_PROJECT,
    (* FABulous, EXTERNAL *) input  wire [7:0] UIO_OE_TT_PROJECT,
    (* FABulous, EXTERNAL *) output wire       ENA_TT_PROJECT,
    (* FABulous, EXTERNAL *) output wire       CLK_TT_PROJECT,
    (* FABulous, EXTERNAL *) output wire       RST_N_TT_PROJECT,
    
    (* FABulous, GLOBAL *) input [N_CONFIG_BITS-1:0] ConfigBits // Config bits as vector
);
    // Configuration bits
    wire ENABLE_POWER, SELECT_SLOT;
	  assign ENABLE_POWER = ConfigBits[0];
  	  assign SELECT_SLOT = ConfigBits[1];

    // Fabric -> External
    assign ENABLE_POWER_TT_PROJECT = ENABLE_POWER;
    assign SELECT_SLOT_TT_PROJECT  = SELECT_SLOT;
    assign CLK_TT_PROJECT       = CLK;
    assign UI_IN_TT_PROJECT     = UI_IN;
    assign UIO_IN_TT_PROJECT    = UIO_IN;
    assign ENA_TT_PROJECT       = ENA;
    assign RST_N_TT_PROJECT     = RST_N;
    
    // External -> Fabric
    assign UO_OUT   = UO_OUT_TT_PROJECT;
    assign UIO_OUT  = UIO_OUT_TT_PROJECT;
    assign UIO_OE   = UIO_OE_TT_PROJECT;

    // User projects are power-gated
    // keep the outputs from floating
    
    generate
    // verilator lint_off ASSIGNIN
    for (genvar i=0; i<8; i++) begin : UO_OUT_TT_PROJECT_sighold
        bus_keeper sighold (
            .X (UO_OUT_TT_PROJECT[i])
        );
    end
    for (genvar i=0; i<8; i++) begin : UIO_OUT_TT_PROJECT_sighold
        bus_keeper sighold (
            .X (UIO_OUT_TT_PROJECT[i])
        );
    end
    for (genvar i=0; i<8; i++) begin : UIO_OE_TT_PROJECT_sighold
        bus_keeper sighold (
            .X (UIO_OE_TT_PROJECT[i])
        );
    end
    // verilator lint_on ASSIGNIN
    endgenerate

endmodule

// Copyright 2026 FABulous Contributors
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

module WARMBOOT #(
    parameter NUM_SLOTS = 16
)(
    // Fabric side
    input  [$clog2(NUM_SLOTS)-1:0] SLOT,
    input                          TRIGGER,

    // External side
    (* FABulous, EXTERNAL *) output [$clog2(NUM_SLOTS)-1:0] SLOT_top,
    (* FABulous, EXTERNAL *) output TRIGGER_top
);

    // Fabric -> External
    assign SLOT_top = SLOT;
    assign TRIGGER_top = TRIGGER;

endmodule

module E_IO4_ConfigMem
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=96
    )
    (
        input  [FrameBitsPerRow - 1:0] FrameData,
        input  [MaxFramesPerCol - 1:0] FrameStrobe,
        output  [NoConfigBits - 1:0] ConfigBits,
        output  [NoConfigBits - 1:0] ConfigBits_N
    );

`ifdef EMULATION
assign ConfigBits[95] = Emulate_Bitstream[31];
assign ConfigBits[94] = Emulate_Bitstream[30];
assign ConfigBits[93] = Emulate_Bitstream[29];
assign ConfigBits[92] = Emulate_Bitstream[28];
assign ConfigBits[91] = Emulate_Bitstream[27];
assign ConfigBits[90] = Emulate_Bitstream[26];
assign ConfigBits[89] = Emulate_Bitstream[25];
assign ConfigBits[88] = Emulate_Bitstream[24];
assign ConfigBits[87] = Emulate_Bitstream[23];
assign ConfigBits[86] = Emulate_Bitstream[22];
assign ConfigBits[85] = Emulate_Bitstream[21];
assign ConfigBits[84] = Emulate_Bitstream[20];
assign ConfigBits[83] = Emulate_Bitstream[19];
assign ConfigBits[82] = Emulate_Bitstream[18];
assign ConfigBits[81] = Emulate_Bitstream[17];
assign ConfigBits[80] = Emulate_Bitstream[16];
assign ConfigBits[79] = Emulate_Bitstream[15];
assign ConfigBits[78] = Emulate_Bitstream[14];
assign ConfigBits[77] = Emulate_Bitstream[13];
assign ConfigBits[76] = Emulate_Bitstream[12];
assign ConfigBits[75] = Emulate_Bitstream[11];
assign ConfigBits[74] = Emulate_Bitstream[10];
assign ConfigBits[73] = Emulate_Bitstream[9];
assign ConfigBits[72] = Emulate_Bitstream[8];
assign ConfigBits[71] = Emulate_Bitstream[7];
assign ConfigBits[70] = Emulate_Bitstream[6];
assign ConfigBits[69] = Emulate_Bitstream[5];
assign ConfigBits[68] = Emulate_Bitstream[4];
assign ConfigBits[67] = Emulate_Bitstream[3];
assign ConfigBits[66] = Emulate_Bitstream[2];
assign ConfigBits[65] = Emulate_Bitstream[1];
assign ConfigBits[64] = Emulate_Bitstream[0];
assign ConfigBits[63] = Emulate_Bitstream[63];
assign ConfigBits[62] = Emulate_Bitstream[62];
assign ConfigBits[61] = Emulate_Bitstream[61];
assign ConfigBits[60] = Emulate_Bitstream[60];
assign ConfigBits[59] = Emulate_Bitstream[59];
assign ConfigBits[58] = Emulate_Bitstream[58];
assign ConfigBits[57] = Emulate_Bitstream[57];
assign ConfigBits[56] = Emulate_Bitstream[56];
assign ConfigBits[55] = Emulate_Bitstream[55];
assign ConfigBits[54] = Emulate_Bitstream[54];
assign ConfigBits[53] = Emulate_Bitstream[53];
assign ConfigBits[52] = Emulate_Bitstream[52];
assign ConfigBits[51] = Emulate_Bitstream[51];
assign ConfigBits[50] = Emulate_Bitstream[50];
assign ConfigBits[49] = Emulate_Bitstream[49];
assign ConfigBits[48] = Emulate_Bitstream[48];
assign ConfigBits[47] = Emulate_Bitstream[47];
assign ConfigBits[46] = Emulate_Bitstream[46];
assign ConfigBits[45] = Emulate_Bitstream[45];
assign ConfigBits[44] = Emulate_Bitstream[44];
assign ConfigBits[43] = Emulate_Bitstream[43];
assign ConfigBits[42] = Emulate_Bitstream[42];
assign ConfigBits[41] = Emulate_Bitstream[41];
assign ConfigBits[40] = Emulate_Bitstream[40];
assign ConfigBits[39] = Emulate_Bitstream[39];
assign ConfigBits[38] = Emulate_Bitstream[38];
assign ConfigBits[37] = Emulate_Bitstream[37];
assign ConfigBits[36] = Emulate_Bitstream[36];
assign ConfigBits[35] = Emulate_Bitstream[35];
assign ConfigBits[34] = Emulate_Bitstream[34];
assign ConfigBits[33] = Emulate_Bitstream[33];
assign ConfigBits[32] = Emulate_Bitstream[32];
assign ConfigBits[31] = Emulate_Bitstream[95];
assign ConfigBits[30] = Emulate_Bitstream[94];
assign ConfigBits[29] = Emulate_Bitstream[93];
assign ConfigBits[28] = Emulate_Bitstream[92];
assign ConfigBits[27] = Emulate_Bitstream[91];
assign ConfigBits[26] = Emulate_Bitstream[90];
assign ConfigBits[25] = Emulate_Bitstream[89];
assign ConfigBits[24] = Emulate_Bitstream[88];
assign ConfigBits[23] = Emulate_Bitstream[87];
assign ConfigBits[22] = Emulate_Bitstream[86];
assign ConfigBits[21] = Emulate_Bitstream[85];
assign ConfigBits[20] = Emulate_Bitstream[84];
assign ConfigBits[19] = Emulate_Bitstream[83];
assign ConfigBits[18] = Emulate_Bitstream[82];
assign ConfigBits[17] = Emulate_Bitstream[81];
assign ConfigBits[16] = Emulate_Bitstream[80];
assign ConfigBits[15] = Emulate_Bitstream[79];
assign ConfigBits[14] = Emulate_Bitstream[78];
assign ConfigBits[13] = Emulate_Bitstream[77];
assign ConfigBits[12] = Emulate_Bitstream[76];
assign ConfigBits[11] = Emulate_Bitstream[75];
assign ConfigBits[10] = Emulate_Bitstream[74];
assign ConfigBits[9] = Emulate_Bitstream[73];
assign ConfigBits[8] = Emulate_Bitstream[72];
assign ConfigBits[7] = Emulate_Bitstream[71];
assign ConfigBits[6] = Emulate_Bitstream[70];
assign ConfigBits[5] = Emulate_Bitstream[69];
assign ConfigBits[4] = Emulate_Bitstream[68];
assign ConfigBits[3] = Emulate_Bitstream[67];
assign ConfigBits[2] = Emulate_Bitstream[66];
assign ConfigBits[1] = Emulate_Bitstream[65];
assign ConfigBits[0] = Emulate_Bitstream[64];
`else

 //instantiate frame latches
config_latch Inst_frame0_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[95]),
    .QN(ConfigBits_N[95])
);

config_latch Inst_frame0_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[94]),
    .QN(ConfigBits_N[94])
);

config_latch Inst_frame0_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[93]),
    .QN(ConfigBits_N[93])
);

config_latch Inst_frame0_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[92]),
    .QN(ConfigBits_N[92])
);

config_latch Inst_frame0_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[91]),
    .QN(ConfigBits_N[91])
);

config_latch Inst_frame0_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[90]),
    .QN(ConfigBits_N[90])
);

config_latch Inst_frame0_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[89]),
    .QN(ConfigBits_N[89])
);

config_latch Inst_frame0_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[88]),
    .QN(ConfigBits_N[88])
);

config_latch Inst_frame0_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[87]),
    .QN(ConfigBits_N[87])
);

config_latch Inst_frame0_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[86]),
    .QN(ConfigBits_N[86])
);

config_latch Inst_frame0_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[85]),
    .QN(ConfigBits_N[85])
);

config_latch Inst_frame0_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[84]),
    .QN(ConfigBits_N[84])
);

config_latch Inst_frame0_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[83]),
    .QN(ConfigBits_N[83])
);

config_latch Inst_frame0_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[82]),
    .QN(ConfigBits_N[82])
);

config_latch Inst_frame0_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[81]),
    .QN(ConfigBits_N[81])
);

config_latch Inst_frame0_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[80]),
    .QN(ConfigBits_N[80])
);

config_latch Inst_frame0_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[79]),
    .QN(ConfigBits_N[79])
);

config_latch Inst_frame0_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[78]),
    .QN(ConfigBits_N[78])
);

config_latch Inst_frame0_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[77]),
    .QN(ConfigBits_N[77])
);

config_latch Inst_frame0_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[76]),
    .QN(ConfigBits_N[76])
);

config_latch Inst_frame0_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[75]),
    .QN(ConfigBits_N[75])
);

config_latch Inst_frame0_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[74]),
    .QN(ConfigBits_N[74])
);

config_latch Inst_frame0_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[73]),
    .QN(ConfigBits_N[73])
);

config_latch Inst_frame0_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[72]),
    .QN(ConfigBits_N[72])
);

config_latch Inst_frame0_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[71]),
    .QN(ConfigBits_N[71])
);

config_latch Inst_frame0_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[70]),
    .QN(ConfigBits_N[70])
);

config_latch Inst_frame0_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[69]),
    .QN(ConfigBits_N[69])
);

config_latch Inst_frame0_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[68]),
    .QN(ConfigBits_N[68])
);

config_latch Inst_frame0_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[67]),
    .QN(ConfigBits_N[67])
);

config_latch Inst_frame0_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[66]),
    .QN(ConfigBits_N[66])
);

config_latch Inst_frame0_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[65]),
    .QN(ConfigBits_N[65])
);

config_latch Inst_frame0_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[64]),
    .QN(ConfigBits_N[64])
);

config_latch Inst_frame1_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[63]),
    .QN(ConfigBits_N[63])
);

config_latch Inst_frame1_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[62]),
    .QN(ConfigBits_N[62])
);

config_latch Inst_frame1_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[61]),
    .QN(ConfigBits_N[61])
);

config_latch Inst_frame1_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[60]),
    .QN(ConfigBits_N[60])
);

config_latch Inst_frame1_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[59]),
    .QN(ConfigBits_N[59])
);

config_latch Inst_frame1_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[58]),
    .QN(ConfigBits_N[58])
);

config_latch Inst_frame1_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[57]),
    .QN(ConfigBits_N[57])
);

config_latch Inst_frame1_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[56]),
    .QN(ConfigBits_N[56])
);

config_latch Inst_frame1_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[55]),
    .QN(ConfigBits_N[55])
);

config_latch Inst_frame1_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[54]),
    .QN(ConfigBits_N[54])
);

config_latch Inst_frame1_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[53]),
    .QN(ConfigBits_N[53])
);

config_latch Inst_frame1_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[52]),
    .QN(ConfigBits_N[52])
);

config_latch Inst_frame1_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[51]),
    .QN(ConfigBits_N[51])
);

config_latch Inst_frame1_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[50]),
    .QN(ConfigBits_N[50])
);

config_latch Inst_frame1_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[49]),
    .QN(ConfigBits_N[49])
);

config_latch Inst_frame1_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[48]),
    .QN(ConfigBits_N[48])
);

config_latch Inst_frame1_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[47]),
    .QN(ConfigBits_N[47])
);

config_latch Inst_frame1_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[46]),
    .QN(ConfigBits_N[46])
);

config_latch Inst_frame1_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[45]),
    .QN(ConfigBits_N[45])
);

config_latch Inst_frame1_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[44]),
    .QN(ConfigBits_N[44])
);

config_latch Inst_frame1_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[43]),
    .QN(ConfigBits_N[43])
);

config_latch Inst_frame1_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[42]),
    .QN(ConfigBits_N[42])
);

config_latch Inst_frame1_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[41]),
    .QN(ConfigBits_N[41])
);

config_latch Inst_frame1_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[40]),
    .QN(ConfigBits_N[40])
);

config_latch Inst_frame1_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[39]),
    .QN(ConfigBits_N[39])
);

config_latch Inst_frame1_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[38]),
    .QN(ConfigBits_N[38])
);

config_latch Inst_frame1_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[37]),
    .QN(ConfigBits_N[37])
);

config_latch Inst_frame1_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[36]),
    .QN(ConfigBits_N[36])
);

config_latch Inst_frame1_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[35]),
    .QN(ConfigBits_N[35])
);

config_latch Inst_frame1_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[34]),
    .QN(ConfigBits_N[34])
);

config_latch Inst_frame1_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[33]),
    .QN(ConfigBits_N[33])
);

config_latch Inst_frame1_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[32]),
    .QN(ConfigBits_N[32])
);

config_latch Inst_frame2_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[31]),
    .QN(ConfigBits_N[31])
);

config_latch Inst_frame2_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[30]),
    .QN(ConfigBits_N[30])
);

config_latch Inst_frame2_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[29]),
    .QN(ConfigBits_N[29])
);

config_latch Inst_frame2_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[28]),
    .QN(ConfigBits_N[28])
);

config_latch Inst_frame2_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[27]),
    .QN(ConfigBits_N[27])
);

config_latch Inst_frame2_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[26]),
    .QN(ConfigBits_N[26])
);

config_latch Inst_frame2_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[25]),
    .QN(ConfigBits_N[25])
);

config_latch Inst_frame2_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[24]),
    .QN(ConfigBits_N[24])
);

config_latch Inst_frame2_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[23]),
    .QN(ConfigBits_N[23])
);

config_latch Inst_frame2_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[22]),
    .QN(ConfigBits_N[22])
);

config_latch Inst_frame2_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[21]),
    .QN(ConfigBits_N[21])
);

config_latch Inst_frame2_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[20]),
    .QN(ConfigBits_N[20])
);

config_latch Inst_frame2_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[19]),
    .QN(ConfigBits_N[19])
);

config_latch Inst_frame2_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[18]),
    .QN(ConfigBits_N[18])
);

config_latch Inst_frame2_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[17]),
    .QN(ConfigBits_N[17])
);

config_latch Inst_frame2_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[16]),
    .QN(ConfigBits_N[16])
);

config_latch Inst_frame2_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[15]),
    .QN(ConfigBits_N[15])
);

config_latch Inst_frame2_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[14]),
    .QN(ConfigBits_N[14])
);

config_latch Inst_frame2_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[13]),
    .QN(ConfigBits_N[13])
);

config_latch Inst_frame2_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[12]),
    .QN(ConfigBits_N[12])
);

config_latch Inst_frame2_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[11]),
    .QN(ConfigBits_N[11])
);

config_latch Inst_frame2_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[10]),
    .QN(ConfigBits_N[10])
);

config_latch Inst_frame2_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[9]),
    .QN(ConfigBits_N[9])
);

config_latch Inst_frame2_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[8]),
    .QN(ConfigBits_N[8])
);

config_latch Inst_frame2_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[7]),
    .QN(ConfigBits_N[7])
);

config_latch Inst_frame2_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[6]),
    .QN(ConfigBits_N[6])
);

config_latch Inst_frame2_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[5]),
    .QN(ConfigBits_N[5])
);

config_latch Inst_frame2_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[4]),
    .QN(ConfigBits_N[4])
);

config_latch Inst_frame2_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[3]),
    .QN(ConfigBits_N[3])
);

config_latch Inst_frame2_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[2]),
    .QN(ConfigBits_N[2])
);

config_latch Inst_frame2_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[1]),
    .QN(ConfigBits_N[1])
);

config_latch Inst_frame2_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[0]),
    .QN(ConfigBits_N[0])
);

`endif
endmodule
 // NumberOfConfigBits: 84
module E_IO4_switch_matrix
    #(
        parameter NoConfigBits=84
    )
    (
        input  N_GBUF_END0,
        input  N_GBUF_END1,
        input  N_GBUF_END2,
        input  N_GBUF_END3,
        input  E1END0,
        input  E1END1,
        input  E1END2,
        input  E1END3,
        input  E1END4,
        input  E1END5,
        input  E1END6,
        input  E1END7,
        input  E2MID0,
        input  E2MID1,
        input  E2MID2,
        input  E2MID3,
        input  E2MID4,
        input  E2MID5,
        input  E2MID6,
        input  E2MID7,
        input  E2END0,
        input  E2END1,
        input  E2END2,
        input  E2END3,
        input  E2END4,
        input  E2END5,
        input  E2END6,
        input  E2END7,
        input  A_OUT,
        input  B_OUT,
        input  C_OUT,
        input  D_OUT,
        output  N_GBUF_BEG0,
        output  N_GBUF_BEG1,
        output  N_GBUF_BEG2,
        output  N_GBUF_BEG3,
        output  W1BEG0,
        output  W1BEG1,
        output  W1BEG2,
        output  W1BEG3,
        output  W1BEG4,
        output  W1BEG5,
        output  W1BEG6,
        output  W1BEG7,
        output  W2BEG0,
        output  W2BEG1,
        output  W2BEG2,
        output  W2BEG3,
        output  W2BEG4,
        output  W2BEG5,
        output  W2BEG6,
        output  W2BEG7,
        output  W2BEGb0,
        output  W2BEGb1,
        output  W2BEGb2,
        output  W2BEGb3,
        output  W2BEGb4,
        output  W2BEGb5,
        output  W2BEGb6,
        output  W2BEGb7,
        output  A_CLK,
        output  A_IN,
        output  A_EN,
        output  B_CLK,
        output  B_IN,
        output  B_EN,
        output  C_CLK,
        output  C_IN,
        output  C_EN,
        output  D_CLK,
        output  D_IN,
        output  D_EN,
 //global
        input  [NoConfigBits-1:0] ConfigBits,
        input  [NoConfigBits-1:0] ConfigBits_N
);
parameter GND0 = 1'b0;
parameter GND = 1'b0;
parameter VCC0 = 1'b1;
parameter VCC = 1'b1;
parameter VDD0 = 1'b1;
parameter VDD = 1'b1;

wire[4-1:0] W1BEG0_input;
wire[4-1:0] W1BEG1_input;
wire[4-1:0] W1BEG2_input;
wire[4-1:0] W1BEG3_input;
wire[4-1:0] W1BEG4_input;
wire[4-1:0] W1BEG5_input;
wire[4-1:0] W1BEG6_input;
wire[4-1:0] W1BEG7_input;
wire[4-1:0] W2BEG0_input;
wire[4-1:0] W2BEG1_input;
wire[4-1:0] W2BEG2_input;
wire[4-1:0] W2BEG3_input;
wire[4-1:0] W2BEG4_input;
wire[4-1:0] W2BEG5_input;
wire[4-1:0] W2BEG6_input;
wire[4-1:0] W2BEG7_input;
wire[4-1:0] W2BEGb0_input;
wire[4-1:0] W2BEGb1_input;
wire[4-1:0] W2BEGb2_input;
wire[4-1:0] W2BEGb3_input;
wire[4-1:0] W2BEGb4_input;
wire[4-1:0] W2BEGb5_input;
wire[4-1:0] W2BEGb6_input;
wire[4-1:0] W2BEGb7_input;
wire[4-1:0] A_CLK_input;
wire[16-1:0] A_IN_input;
wire[8-1:0] A_EN_input;
wire[4-1:0] B_CLK_input;
wire[16-1:0] B_IN_input;
wire[8-1:0] B_EN_input;
wire[4-1:0] C_CLK_input;
wire[16-1:0] C_IN_input;
wire[8-1:0] C_EN_input;
wire[4-1:0] D_CLK_input;
wire[16-1:0] D_IN_input;
wire[8-1:0] D_EN_input;
 //The configuration bits (if any) are just a long shift register
 //This shift register is padded to an even number of flops/latches
 //switch matrix multiplexer N_GBUF_BEG0 MUX-1
assign N_GBUF_BEG0 = N_GBUF_END0;

 //switch matrix multiplexer N_GBUF_BEG1 MUX-1
assign N_GBUF_BEG1 = N_GBUF_END1;

 //switch matrix multiplexer N_GBUF_BEG2 MUX-1
assign N_GBUF_BEG2 = N_GBUF_END2;

 //switch matrix multiplexer N_GBUF_BEG3 MUX-1
assign N_GBUF_BEG3 = N_GBUF_END3;

 //switch matrix multiplexer W1BEG0 MUX-4
assign W1BEG0_input = {A_OUT,E2END7,E2MID7,E1END7};
cus_mux41 inst_cus_mux41_W1BEG0 (
    .A0(W1BEG0_input[0]),
    .A1(W1BEG0_input[1]),
    .A2(W1BEG0_input[2]),
    .A3(W1BEG0_input[3]),
    .S0(ConfigBits[0+0]),
    .S0N(ConfigBits_N[0+0]),
    .S1(ConfigBits[0+1]),
    .S1N(ConfigBits_N[0+1]),
    .X(W1BEG0)
);

 //switch matrix multiplexer W1BEG1 MUX-4
assign W1BEG1_input = {B_OUT,E2END6,E2MID6,E1END6};
cus_mux41 inst_cus_mux41_W1BEG1 (
    .A0(W1BEG1_input[0]),
    .A1(W1BEG1_input[1]),
    .A2(W1BEG1_input[2]),
    .A3(W1BEG1_input[3]),
    .S0(ConfigBits[2+0]),
    .S0N(ConfigBits_N[2+0]),
    .S1(ConfigBits[2+1]),
    .S1N(ConfigBits_N[2+1]),
    .X(W1BEG1)
);

 //switch matrix multiplexer W1BEG2 MUX-4
assign W1BEG2_input = {C_OUT,E2END5,E2MID5,E1END5};
cus_mux41 inst_cus_mux41_W1BEG2 (
    .A0(W1BEG2_input[0]),
    .A1(W1BEG2_input[1]),
    .A2(W1BEG2_input[2]),
    .A3(W1BEG2_input[3]),
    .S0(ConfigBits[4+0]),
    .S0N(ConfigBits_N[4+0]),
    .S1(ConfigBits[4+1]),
    .S1N(ConfigBits_N[4+1]),
    .X(W1BEG2)
);

 //switch matrix multiplexer W1BEG3 MUX-4
assign W1BEG3_input = {D_OUT,E2END4,E2MID4,E1END4};
cus_mux41 inst_cus_mux41_W1BEG3 (
    .A0(W1BEG3_input[0]),
    .A1(W1BEG3_input[1]),
    .A2(W1BEG3_input[2]),
    .A3(W1BEG3_input[3]),
    .S0(ConfigBits[6+0]),
    .S0N(ConfigBits_N[6+0]),
    .S1(ConfigBits[6+1]),
    .S1N(ConfigBits_N[6+1]),
    .X(W1BEG3)
);

 //switch matrix multiplexer W1BEG4 MUX-4
assign W1BEG4_input = {A_OUT,E2END3,E2MID3,E1END3};
cus_mux41 inst_cus_mux41_W1BEG4 (
    .A0(W1BEG4_input[0]),
    .A1(W1BEG4_input[1]),
    .A2(W1BEG4_input[2]),
    .A3(W1BEG4_input[3]),
    .S0(ConfigBits[8+0]),
    .S0N(ConfigBits_N[8+0]),
    .S1(ConfigBits[8+1]),
    .S1N(ConfigBits_N[8+1]),
    .X(W1BEG4)
);

 //switch matrix multiplexer W1BEG5 MUX-4
assign W1BEG5_input = {B_OUT,E2END2,E2MID2,E1END2};
cus_mux41 inst_cus_mux41_W1BEG5 (
    .A0(W1BEG5_input[0]),
    .A1(W1BEG5_input[1]),
    .A2(W1BEG5_input[2]),
    .A3(W1BEG5_input[3]),
    .S0(ConfigBits[10+0]),
    .S0N(ConfigBits_N[10+0]),
    .S1(ConfigBits[10+1]),
    .S1N(ConfigBits_N[10+1]),
    .X(W1BEG5)
);

 //switch matrix multiplexer W1BEG6 MUX-4
assign W1BEG6_input = {C_OUT,E2END1,E2MID1,E1END1};
cus_mux41 inst_cus_mux41_W1BEG6 (
    .A0(W1BEG6_input[0]),
    .A1(W1BEG6_input[1]),
    .A2(W1BEG6_input[2]),
    .A3(W1BEG6_input[3]),
    .S0(ConfigBits[12+0]),
    .S0N(ConfigBits_N[12+0]),
    .S1(ConfigBits[12+1]),
    .S1N(ConfigBits_N[12+1]),
    .X(W1BEG6)
);

 //switch matrix multiplexer W1BEG7 MUX-4
assign W1BEG7_input = {D_OUT,E2END0,E2MID0,E1END0};
cus_mux41 inst_cus_mux41_W1BEG7 (
    .A0(W1BEG7_input[0]),
    .A1(W1BEG7_input[1]),
    .A2(W1BEG7_input[2]),
    .A3(W1BEG7_input[3]),
    .S0(ConfigBits[14+0]),
    .S0N(ConfigBits_N[14+0]),
    .S1(ConfigBits[14+1]),
    .S1N(ConfigBits_N[14+1]),
    .X(W1BEG7)
);

 //switch matrix multiplexer W2BEG0 MUX-4
assign W2BEG0_input = {A_OUT,E2END7,E2MID7,E1END7};
cus_mux41 inst_cus_mux41_W2BEG0 (
    .A0(W2BEG0_input[0]),
    .A1(W2BEG0_input[1]),
    .A2(W2BEG0_input[2]),
    .A3(W2BEG0_input[3]),
    .S0(ConfigBits[16+0]),
    .S0N(ConfigBits_N[16+0]),
    .S1(ConfigBits[16+1]),
    .S1N(ConfigBits_N[16+1]),
    .X(W2BEG0)
);

 //switch matrix multiplexer W2BEG1 MUX-4
assign W2BEG1_input = {B_OUT,E2END6,E2MID6,E1END6};
cus_mux41 inst_cus_mux41_W2BEG1 (
    .A0(W2BEG1_input[0]),
    .A1(W2BEG1_input[1]),
    .A2(W2BEG1_input[2]),
    .A3(W2BEG1_input[3]),
    .S0(ConfigBits[18+0]),
    .S0N(ConfigBits_N[18+0]),
    .S1(ConfigBits[18+1]),
    .S1N(ConfigBits_N[18+1]),
    .X(W2BEG1)
);

 //switch matrix multiplexer W2BEG2 MUX-4
assign W2BEG2_input = {C_OUT,E2END5,E2MID5,E1END5};
cus_mux41 inst_cus_mux41_W2BEG2 (
    .A0(W2BEG2_input[0]),
    .A1(W2BEG2_input[1]),
    .A2(W2BEG2_input[2]),
    .A3(W2BEG2_input[3]),
    .S0(ConfigBits[20+0]),
    .S0N(ConfigBits_N[20+0]),
    .S1(ConfigBits[20+1]),
    .S1N(ConfigBits_N[20+1]),
    .X(W2BEG2)
);

 //switch matrix multiplexer W2BEG3 MUX-4
assign W2BEG3_input = {D_OUT,E2END4,E2MID4,E1END4};
cus_mux41 inst_cus_mux41_W2BEG3 (
    .A0(W2BEG3_input[0]),
    .A1(W2BEG3_input[1]),
    .A2(W2BEG3_input[2]),
    .A3(W2BEG3_input[3]),
    .S0(ConfigBits[22+0]),
    .S0N(ConfigBits_N[22+0]),
    .S1(ConfigBits[22+1]),
    .S1N(ConfigBits_N[22+1]),
    .X(W2BEG3)
);

 //switch matrix multiplexer W2BEG4 MUX-4
assign W2BEG4_input = {A_OUT,E2END3,E2MID3,E1END3};
cus_mux41 inst_cus_mux41_W2BEG4 (
    .A0(W2BEG4_input[0]),
    .A1(W2BEG4_input[1]),
    .A2(W2BEG4_input[2]),
    .A3(W2BEG4_input[3]),
    .S0(ConfigBits[24+0]),
    .S0N(ConfigBits_N[24+0]),
    .S1(ConfigBits[24+1]),
    .S1N(ConfigBits_N[24+1]),
    .X(W2BEG4)
);

 //switch matrix multiplexer W2BEG5 MUX-4
assign W2BEG5_input = {B_OUT,E2END2,E2MID2,E1END2};
cus_mux41 inst_cus_mux41_W2BEG5 (
    .A0(W2BEG5_input[0]),
    .A1(W2BEG5_input[1]),
    .A2(W2BEG5_input[2]),
    .A3(W2BEG5_input[3]),
    .S0(ConfigBits[26+0]),
    .S0N(ConfigBits_N[26+0]),
    .S1(ConfigBits[26+1]),
    .S1N(ConfigBits_N[26+1]),
    .X(W2BEG5)
);

 //switch matrix multiplexer W2BEG6 MUX-4
assign W2BEG6_input = {C_OUT,E2END1,E2MID1,E1END1};
cus_mux41 inst_cus_mux41_W2BEG6 (
    .A0(W2BEG6_input[0]),
    .A1(W2BEG6_input[1]),
    .A2(W2BEG6_input[2]),
    .A3(W2BEG6_input[3]),
    .S0(ConfigBits[28+0]),
    .S0N(ConfigBits_N[28+0]),
    .S1(ConfigBits[28+1]),
    .S1N(ConfigBits_N[28+1]),
    .X(W2BEG6)
);

 //switch matrix multiplexer W2BEG7 MUX-4
assign W2BEG7_input = {D_OUT,E2END0,E2MID0,E1END0};
cus_mux41 inst_cus_mux41_W2BEG7 (
    .A0(W2BEG7_input[0]),
    .A1(W2BEG7_input[1]),
    .A2(W2BEG7_input[2]),
    .A3(W2BEG7_input[3]),
    .S0(ConfigBits[30+0]),
    .S0N(ConfigBits_N[30+0]),
    .S1(ConfigBits[30+1]),
    .S1N(ConfigBits_N[30+1]),
    .X(W2BEG7)
);

 //switch matrix multiplexer W2BEGb0 MUX-4
assign W2BEGb0_input = {D_OUT,E2END7,E2MID7,E1END7};
cus_mux41 inst_cus_mux41_W2BEGb0 (
    .A0(W2BEGb0_input[0]),
    .A1(W2BEGb0_input[1]),
    .A2(W2BEGb0_input[2]),
    .A3(W2BEGb0_input[3]),
    .S0(ConfigBits[32+0]),
    .S0N(ConfigBits_N[32+0]),
    .S1(ConfigBits[32+1]),
    .S1N(ConfigBits_N[32+1]),
    .X(W2BEGb0)
);

 //switch matrix multiplexer W2BEGb1 MUX-4
assign W2BEGb1_input = {C_OUT,E2END6,E2MID6,E1END6};
cus_mux41 inst_cus_mux41_W2BEGb1 (
    .A0(W2BEGb1_input[0]),
    .A1(W2BEGb1_input[1]),
    .A2(W2BEGb1_input[2]),
    .A3(W2BEGb1_input[3]),
    .S0(ConfigBits[34+0]),
    .S0N(ConfigBits_N[34+0]),
    .S1(ConfigBits[34+1]),
    .S1N(ConfigBits_N[34+1]),
    .X(W2BEGb1)
);

 //switch matrix multiplexer W2BEGb2 MUX-4
assign W2BEGb2_input = {C_OUT,E2END5,E2MID5,E1END5};
cus_mux41 inst_cus_mux41_W2BEGb2 (
    .A0(W2BEGb2_input[0]),
    .A1(W2BEGb2_input[1]),
    .A2(W2BEGb2_input[2]),
    .A3(W2BEGb2_input[3]),
    .S0(ConfigBits[36+0]),
    .S0N(ConfigBits_N[36+0]),
    .S1(ConfigBits[36+1]),
    .S1N(ConfigBits_N[36+1]),
    .X(W2BEGb2)
);

 //switch matrix multiplexer W2BEGb3 MUX-4
assign W2BEGb3_input = {A_OUT,E2END4,E2MID4,E1END4};
cus_mux41 inst_cus_mux41_W2BEGb3 (
    .A0(W2BEGb3_input[0]),
    .A1(W2BEGb3_input[1]),
    .A2(W2BEGb3_input[2]),
    .A3(W2BEGb3_input[3]),
    .S0(ConfigBits[38+0]),
    .S0N(ConfigBits_N[38+0]),
    .S1(ConfigBits[38+1]),
    .S1N(ConfigBits_N[38+1]),
    .X(W2BEGb3)
);

 //switch matrix multiplexer W2BEGb4 MUX-4
assign W2BEGb4_input = {D_OUT,E2END3,E2MID3,E1END3};
cus_mux41 inst_cus_mux41_W2BEGb4 (
    .A0(W2BEGb4_input[0]),
    .A1(W2BEGb4_input[1]),
    .A2(W2BEGb4_input[2]),
    .A3(W2BEGb4_input[3]),
    .S0(ConfigBits[40+0]),
    .S0N(ConfigBits_N[40+0]),
    .S1(ConfigBits[40+1]),
    .S1N(ConfigBits_N[40+1]),
    .X(W2BEGb4)
);

 //switch matrix multiplexer W2BEGb5 MUX-4
assign W2BEGb5_input = {C_OUT,E2END2,E2MID2,E1END2};
cus_mux41 inst_cus_mux41_W2BEGb5 (
    .A0(W2BEGb5_input[0]),
    .A1(W2BEGb5_input[1]),
    .A2(W2BEGb5_input[2]),
    .A3(W2BEGb5_input[3]),
    .S0(ConfigBits[42+0]),
    .S0N(ConfigBits_N[42+0]),
    .S1(ConfigBits[42+1]),
    .S1N(ConfigBits_N[42+1]),
    .X(W2BEGb5)
);

 //switch matrix multiplexer W2BEGb6 MUX-4
assign W2BEGb6_input = {B_OUT,E2END1,E2MID1,E1END1};
cus_mux41 inst_cus_mux41_W2BEGb6 (
    .A0(W2BEGb6_input[0]),
    .A1(W2BEGb6_input[1]),
    .A2(W2BEGb6_input[2]),
    .A3(W2BEGb6_input[3]),
    .S0(ConfigBits[44+0]),
    .S0N(ConfigBits_N[44+0]),
    .S1(ConfigBits[44+1]),
    .S1N(ConfigBits_N[44+1]),
    .X(W2BEGb6)
);

 //switch matrix multiplexer W2BEGb7 MUX-4
assign W2BEGb7_input = {A_OUT,E2END0,E2MID0,E1END0};
cus_mux41 inst_cus_mux41_W2BEGb7 (
    .A0(W2BEGb7_input[0]),
    .A1(W2BEGb7_input[1]),
    .A2(W2BEGb7_input[2]),
    .A3(W2BEGb7_input[3]),
    .S0(ConfigBits[46+0]),
    .S0N(ConfigBits_N[46+0]),
    .S1(ConfigBits[46+1]),
    .S1N(ConfigBits_N[46+1]),
    .X(W2BEGb7)
);

 //switch matrix multiplexer A_CLK MUX-4
assign A_CLK_input = {N_GBUF_END3,N_GBUF_END2,N_GBUF_END1,N_GBUF_END0};
cus_mux41 inst_cus_mux41_A_CLK (
    .A0(A_CLK_input[0]),
    .A1(A_CLK_input[1]),
    .A2(A_CLK_input[2]),
    .A3(A_CLK_input[3]),
    .S0(ConfigBits[48+0]),
    .S0N(ConfigBits_N[48+0]),
    .S1(ConfigBits[48+1]),
    .S1N(ConfigBits_N[48+1]),
    .X(A_CLK)
);

 //switch matrix multiplexer A_IN MUX-16
assign A_IN_input = {VCC0,GND0,E2END7,E2END6,E2END5,E2MID2,E2MID1,E2MID0,E1END7,E1END6,E1END5,E1END4,E1END3,E1END2,E1END1,E1END0};
cus_mux161 inst_cus_mux161_A_IN (
    .A0(A_IN_input[0]),
    .A1(A_IN_input[1]),
    .A2(A_IN_input[2]),
    .A3(A_IN_input[3]),
    .A4(A_IN_input[4]),
    .A5(A_IN_input[5]),
    .A6(A_IN_input[6]),
    .A7(A_IN_input[7]),
    .A8(A_IN_input[8]),
    .A9(A_IN_input[9]),
    .A10(A_IN_input[10]),
    .A11(A_IN_input[11]),
    .A12(A_IN_input[12]),
    .A13(A_IN_input[13]),
    .A14(A_IN_input[14]),
    .A15(A_IN_input[15]),
    .S0(ConfigBits[50+0]),
    .S0N(ConfigBits_N[50+0]),
    .S1(ConfigBits[50+1]),
    .S1N(ConfigBits_N[50+1]),
    .S2(ConfigBits[50+2]),
    .S2N(ConfigBits_N[50+2]),
    .S3(ConfigBits[50+3]),
    .S3N(ConfigBits_N[50+3]),
    .X(A_IN)
);

 //switch matrix multiplexer A_EN MUX-8
assign A_EN_input = {VCC0,GND0,E2END2,E2END0,E2MID7,E2MID4,E1END7,E1END3};
cus_mux81 inst_cus_mux81_A_EN (
    .A0(A_EN_input[0]),
    .A1(A_EN_input[1]),
    .A2(A_EN_input[2]),
    .A3(A_EN_input[3]),
    .A4(A_EN_input[4]),
    .A5(A_EN_input[5]),
    .A6(A_EN_input[6]),
    .A7(A_EN_input[7]),
    .S0(ConfigBits[54+0]),
    .S0N(ConfigBits_N[54+0]),
    .S1(ConfigBits[54+1]),
    .S1N(ConfigBits_N[54+1]),
    .S2(ConfigBits[54+2]),
    .S2N(ConfigBits_N[54+2]),
    .X(A_EN)
);

 //switch matrix multiplexer B_CLK MUX-4
assign B_CLK_input = {N_GBUF_END3,N_GBUF_END2,N_GBUF_END1,N_GBUF_END0};
cus_mux41 inst_cus_mux41_B_CLK (
    .A0(B_CLK_input[0]),
    .A1(B_CLK_input[1]),
    .A2(B_CLK_input[2]),
    .A3(B_CLK_input[3]),
    .S0(ConfigBits[57+0]),
    .S0N(ConfigBits_N[57+0]),
    .S1(ConfigBits[57+1]),
    .S1N(ConfigBits_N[57+1]),
    .X(B_CLK)
);

 //switch matrix multiplexer B_IN MUX-16
assign B_IN_input = {VCC0,GND0,E2END7,E2END6,E2END5,E2MID2,E2MID1,E2MID0,E1END7,E1END6,E1END5,E1END4,E1END3,E1END2,E1END1,E1END0};
cus_mux161 inst_cus_mux161_B_IN (
    .A0(B_IN_input[0]),
    .A1(B_IN_input[1]),
    .A2(B_IN_input[2]),
    .A3(B_IN_input[3]),
    .A4(B_IN_input[4]),
    .A5(B_IN_input[5]),
    .A6(B_IN_input[6]),
    .A7(B_IN_input[7]),
    .A8(B_IN_input[8]),
    .A9(B_IN_input[9]),
    .A10(B_IN_input[10]),
    .A11(B_IN_input[11]),
    .A12(B_IN_input[12]),
    .A13(B_IN_input[13]),
    .A14(B_IN_input[14]),
    .A15(B_IN_input[15]),
    .S0(ConfigBits[59+0]),
    .S0N(ConfigBits_N[59+0]),
    .S1(ConfigBits[59+1]),
    .S1N(ConfigBits_N[59+1]),
    .S2(ConfigBits[59+2]),
    .S2N(ConfigBits_N[59+2]),
    .S3(ConfigBits[59+3]),
    .S3N(ConfigBits_N[59+3]),
    .X(B_IN)
);

 //switch matrix multiplexer B_EN MUX-8
assign B_EN_input = {VCC0,GND0,E2END2,E2END0,E2MID7,E2MID4,E1END7,E1END3};
cus_mux81 inst_cus_mux81_B_EN (
    .A0(B_EN_input[0]),
    .A1(B_EN_input[1]),
    .A2(B_EN_input[2]),
    .A3(B_EN_input[3]),
    .A4(B_EN_input[4]),
    .A5(B_EN_input[5]),
    .A6(B_EN_input[6]),
    .A7(B_EN_input[7]),
    .S0(ConfigBits[63+0]),
    .S0N(ConfigBits_N[63+0]),
    .S1(ConfigBits[63+1]),
    .S1N(ConfigBits_N[63+1]),
    .S2(ConfigBits[63+2]),
    .S2N(ConfigBits_N[63+2]),
    .X(B_EN)
);

 //switch matrix multiplexer C_CLK MUX-4
assign C_CLK_input = {N_GBUF_END3,N_GBUF_END2,N_GBUF_END1,N_GBUF_END0};
cus_mux41 inst_cus_mux41_C_CLK (
    .A0(C_CLK_input[0]),
    .A1(C_CLK_input[1]),
    .A2(C_CLK_input[2]),
    .A3(C_CLK_input[3]),
    .S0(ConfigBits[66+0]),
    .S0N(ConfigBits_N[66+0]),
    .S1(ConfigBits[66+1]),
    .S1N(ConfigBits_N[66+1]),
    .X(C_CLK)
);

 //switch matrix multiplexer C_IN MUX-16
assign C_IN_input = {VCC0,GND0,E2END7,E2END6,E2END5,E2MID2,E2MID1,E2MID0,E1END7,E1END6,E1END5,E1END4,E1END3,E1END2,E1END1,E1END0};
cus_mux161 inst_cus_mux161_C_IN (
    .A0(C_IN_input[0]),
    .A1(C_IN_input[1]),
    .A2(C_IN_input[2]),
    .A3(C_IN_input[3]),
    .A4(C_IN_input[4]),
    .A5(C_IN_input[5]),
    .A6(C_IN_input[6]),
    .A7(C_IN_input[7]),
    .A8(C_IN_input[8]),
    .A9(C_IN_input[9]),
    .A10(C_IN_input[10]),
    .A11(C_IN_input[11]),
    .A12(C_IN_input[12]),
    .A13(C_IN_input[13]),
    .A14(C_IN_input[14]),
    .A15(C_IN_input[15]),
    .S0(ConfigBits[68+0]),
    .S0N(ConfigBits_N[68+0]),
    .S1(ConfigBits[68+1]),
    .S1N(ConfigBits_N[68+1]),
    .S2(ConfigBits[68+2]),
    .S2N(ConfigBits_N[68+2]),
    .S3(ConfigBits[68+3]),
    .S3N(ConfigBits_N[68+3]),
    .X(C_IN)
);

 //switch matrix multiplexer C_EN MUX-8
assign C_EN_input = {VCC0,GND0,E2END2,E2END0,E2MID7,E2MID4,E1END7,E1END3};
cus_mux81 inst_cus_mux81_C_EN (
    .A0(C_EN_input[0]),
    .A1(C_EN_input[1]),
    .A2(C_EN_input[2]),
    .A3(C_EN_input[3]),
    .A4(C_EN_input[4]),
    .A5(C_EN_input[5]),
    .A6(C_EN_input[6]),
    .A7(C_EN_input[7]),
    .S0(ConfigBits[72+0]),
    .S0N(ConfigBits_N[72+0]),
    .S1(ConfigBits[72+1]),
    .S1N(ConfigBits_N[72+1]),
    .S2(ConfigBits[72+2]),
    .S2N(ConfigBits_N[72+2]),
    .X(C_EN)
);

 //switch matrix multiplexer D_CLK MUX-4
assign D_CLK_input = {N_GBUF_END3,N_GBUF_END2,N_GBUF_END1,N_GBUF_END0};
cus_mux41 inst_cus_mux41_D_CLK (
    .A0(D_CLK_input[0]),
    .A1(D_CLK_input[1]),
    .A2(D_CLK_input[2]),
    .A3(D_CLK_input[3]),
    .S0(ConfigBits[75+0]),
    .S0N(ConfigBits_N[75+0]),
    .S1(ConfigBits[75+1]),
    .S1N(ConfigBits_N[75+1]),
    .X(D_CLK)
);

 //switch matrix multiplexer D_IN MUX-16
assign D_IN_input = {VCC0,GND0,E2END7,E2END6,E2END5,E2MID2,E2MID1,E2MID0,E1END7,E1END6,E1END5,E1END4,E1END3,E1END2,E1END1,E1END0};
cus_mux161 inst_cus_mux161_D_IN (
    .A0(D_IN_input[0]),
    .A1(D_IN_input[1]),
    .A2(D_IN_input[2]),
    .A3(D_IN_input[3]),
    .A4(D_IN_input[4]),
    .A5(D_IN_input[5]),
    .A6(D_IN_input[6]),
    .A7(D_IN_input[7]),
    .A8(D_IN_input[8]),
    .A9(D_IN_input[9]),
    .A10(D_IN_input[10]),
    .A11(D_IN_input[11]),
    .A12(D_IN_input[12]),
    .A13(D_IN_input[13]),
    .A14(D_IN_input[14]),
    .A15(D_IN_input[15]),
    .S0(ConfigBits[77+0]),
    .S0N(ConfigBits_N[77+0]),
    .S1(ConfigBits[77+1]),
    .S1N(ConfigBits_N[77+1]),
    .S2(ConfigBits[77+2]),
    .S2N(ConfigBits_N[77+2]),
    .S3(ConfigBits[77+3]),
    .S3N(ConfigBits_N[77+3]),
    .X(D_IN)
);

 //switch matrix multiplexer D_EN MUX-8
assign D_EN_input = {VCC0,GND0,E2END2,E2END0,E2MID7,E2MID4,E1END7,E1END3};
cus_mux81 inst_cus_mux81_D_EN (
    .A0(D_EN_input[0]),
    .A1(D_EN_input[1]),
    .A2(D_EN_input[2]),
    .A3(D_EN_input[3]),
    .A4(D_EN_input[4]),
    .A5(D_EN_input[5]),
    .A6(D_EN_input[6]),
    .A7(D_EN_input[7]),
    .S0(ConfigBits[81+0]),
    .S0N(ConfigBits_N[81+0]),
    .S1(ConfigBits[81+1]),
    .S1N(ConfigBits_N[81+1]),
    .S2(ConfigBits[81+2]),
    .S2N(ConfigBits_N[81+2]),
    .X(D_EN)
);

endmodule
module E_IO4
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=96
    )
    (
 //N
        output  [3:0] N_GBUF_BEG,        //Port(Name=N_GBUF_BEG,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=4,Side=N)
 //W
        input  [7:0] E1END,        //Port(Name=E1END,IO=INPUT,XOffset=1,YOffset=0,WireCount=8,Side=W)
        input  [7:0] E2MID,        //Port(Name=E2MID,IO=INPUT,XOffset=1,YOffset=0,WireCount=8,Side=W)
        input  [7:0] E2END,        //Port(Name=E2END,IO=INPUT,XOffset=1,YOffset=0,WireCount=8,Side=W)
        output  [7:0] W1BEG,        //Port(Name=W1BEG,IO=OUTPUT,XOffset=-1,YOffset=0,WireCount=8,Side=W)
        output  [7:0] W2BEG,        //Port(Name=W2BEG,IO=OUTPUT,XOffset=-1,YOffset=0,WireCount=8,Side=W)
        output  [7:0] W2BEGb,        //Port(Name=W2BEGb,IO=OUTPUT,XOffset=-1,YOffset=0,WireCount=8,Side=W)
 //S
        input  [3:0] N_GBUF_END,        //Port(Name=N_GBUF_END,IO=INPUT,XOffset=0,YOffset=-1,WireCount=4,Side=S)
        input  A_OUT_top,
        output  A_IN_top,
        output  A_EN_top,
        input  B_OUT_top,
        output  B_IN_top,
        output  B_EN_top,
        input  C_OUT_top,
        output  C_IN_top,
        output  C_EN_top,
        input  D_OUT_top,
        output  D_IN_top,
        output  D_EN_top,
    //Tile IO ports from BELs
        input  [FrameBitsPerRow-1:0] FrameData, //CONFIG_PORT
        output  [FrameBitsPerRow-1:0] FrameData_O,
        input  [MaxFramesPerCol-1:0] FrameStrobe, //CONFIG_PORT
        output  [MaxFramesPerCol-1:0] FrameStrobe_O
    //global
);
 //signal declarations
 //BEL ports (e.g., slices)
wire A_CLK;
wire A_IN;
wire A_EN;
wire A_OUT;
wire B_CLK;
wire B_IN;
wire B_EN;
wire B_OUT;
wire C_CLK;
wire C_IN;
wire C_EN;
wire C_OUT;
wire D_CLK;
wire D_IN;
wire D_EN;
wire D_OUT;
 //Jump wires
 //internal configuration data signal to daisy-chain all BELs (if any and in the order they are listed in the fabric.csv)
wire[NoConfigBits-1:0] ConfigBits;
wire[NoConfigBits-1:0] ConfigBits_N;

 //Connection for outgoing wires
wire[FrameBitsPerRow-1:0] FrameData_i;
wire[FrameBitsPerRow-1:0] FrameData_O_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_O_i;

assign FrameData_O_i = FrameData_i;

my_buf data_inbuf_0 (
    .A(FrameData[0]),
    .X(FrameData_i[0])
);

my_buf data_inbuf_1 (
    .A(FrameData[1]),
    .X(FrameData_i[1])
);

my_buf data_inbuf_2 (
    .A(FrameData[2]),
    .X(FrameData_i[2])
);

my_buf data_inbuf_3 (
    .A(FrameData[3]),
    .X(FrameData_i[3])
);

my_buf data_inbuf_4 (
    .A(FrameData[4]),
    .X(FrameData_i[4])
);

my_buf data_inbuf_5 (
    .A(FrameData[5]),
    .X(FrameData_i[5])
);

my_buf data_inbuf_6 (
    .A(FrameData[6]),
    .X(FrameData_i[6])
);

my_buf data_inbuf_7 (
    .A(FrameData[7]),
    .X(FrameData_i[7])
);

my_buf data_inbuf_8 (
    .A(FrameData[8]),
    .X(FrameData_i[8])
);

my_buf data_inbuf_9 (
    .A(FrameData[9]),
    .X(FrameData_i[9])
);

my_buf data_inbuf_10 (
    .A(FrameData[10]),
    .X(FrameData_i[10])
);

my_buf data_inbuf_11 (
    .A(FrameData[11]),
    .X(FrameData_i[11])
);

my_buf data_inbuf_12 (
    .A(FrameData[12]),
    .X(FrameData_i[12])
);

my_buf data_inbuf_13 (
    .A(FrameData[13]),
    .X(FrameData_i[13])
);

my_buf data_inbuf_14 (
    .A(FrameData[14]),
    .X(FrameData_i[14])
);

my_buf data_inbuf_15 (
    .A(FrameData[15]),
    .X(FrameData_i[15])
);

my_buf data_inbuf_16 (
    .A(FrameData[16]),
    .X(FrameData_i[16])
);

my_buf data_inbuf_17 (
    .A(FrameData[17]),
    .X(FrameData_i[17])
);

my_buf data_inbuf_18 (
    .A(FrameData[18]),
    .X(FrameData_i[18])
);

my_buf data_inbuf_19 (
    .A(FrameData[19]),
    .X(FrameData_i[19])
);

my_buf data_inbuf_20 (
    .A(FrameData[20]),
    .X(FrameData_i[20])
);

my_buf data_inbuf_21 (
    .A(FrameData[21]),
    .X(FrameData_i[21])
);

my_buf data_inbuf_22 (
    .A(FrameData[22]),
    .X(FrameData_i[22])
);

my_buf data_inbuf_23 (
    .A(FrameData[23]),
    .X(FrameData_i[23])
);

my_buf data_inbuf_24 (
    .A(FrameData[24]),
    .X(FrameData_i[24])
);

my_buf data_inbuf_25 (
    .A(FrameData[25]),
    .X(FrameData_i[25])
);

my_buf data_inbuf_26 (
    .A(FrameData[26]),
    .X(FrameData_i[26])
);

my_buf data_inbuf_27 (
    .A(FrameData[27]),
    .X(FrameData_i[27])
);

my_buf data_inbuf_28 (
    .A(FrameData[28]),
    .X(FrameData_i[28])
);

my_buf data_inbuf_29 (
    .A(FrameData[29]),
    .X(FrameData_i[29])
);

my_buf data_inbuf_30 (
    .A(FrameData[30]),
    .X(FrameData_i[30])
);

my_buf data_inbuf_31 (
    .A(FrameData[31]),
    .X(FrameData_i[31])
);

my_buf data_outbuf_0 (
    .A(FrameData_O_i[0]),
    .X(FrameData_O[0])
);

my_buf data_outbuf_1 (
    .A(FrameData_O_i[1]),
    .X(FrameData_O[1])
);

my_buf data_outbuf_2 (
    .A(FrameData_O_i[2]),
    .X(FrameData_O[2])
);

my_buf data_outbuf_3 (
    .A(FrameData_O_i[3]),
    .X(FrameData_O[3])
);

my_buf data_outbuf_4 (
    .A(FrameData_O_i[4]),
    .X(FrameData_O[4])
);

my_buf data_outbuf_5 (
    .A(FrameData_O_i[5]),
    .X(FrameData_O[5])
);

my_buf data_outbuf_6 (
    .A(FrameData_O_i[6]),
    .X(FrameData_O[6])
);

my_buf data_outbuf_7 (
    .A(FrameData_O_i[7]),
    .X(FrameData_O[7])
);

my_buf data_outbuf_8 (
    .A(FrameData_O_i[8]),
    .X(FrameData_O[8])
);

my_buf data_outbuf_9 (
    .A(FrameData_O_i[9]),
    .X(FrameData_O[9])
);

my_buf data_outbuf_10 (
    .A(FrameData_O_i[10]),
    .X(FrameData_O[10])
);

my_buf data_outbuf_11 (
    .A(FrameData_O_i[11]),
    .X(FrameData_O[11])
);

my_buf data_outbuf_12 (
    .A(FrameData_O_i[12]),
    .X(FrameData_O[12])
);

my_buf data_outbuf_13 (
    .A(FrameData_O_i[13]),
    .X(FrameData_O[13])
);

my_buf data_outbuf_14 (
    .A(FrameData_O_i[14]),
    .X(FrameData_O[14])
);

my_buf data_outbuf_15 (
    .A(FrameData_O_i[15]),
    .X(FrameData_O[15])
);

my_buf data_outbuf_16 (
    .A(FrameData_O_i[16]),
    .X(FrameData_O[16])
);

my_buf data_outbuf_17 (
    .A(FrameData_O_i[17]),
    .X(FrameData_O[17])
);

my_buf data_outbuf_18 (
    .A(FrameData_O_i[18]),
    .X(FrameData_O[18])
);

my_buf data_outbuf_19 (
    .A(FrameData_O_i[19]),
    .X(FrameData_O[19])
);

my_buf data_outbuf_20 (
    .A(FrameData_O_i[20]),
    .X(FrameData_O[20])
);

my_buf data_outbuf_21 (
    .A(FrameData_O_i[21]),
    .X(FrameData_O[21])
);

my_buf data_outbuf_22 (
    .A(FrameData_O_i[22]),
    .X(FrameData_O[22])
);

my_buf data_outbuf_23 (
    .A(FrameData_O_i[23]),
    .X(FrameData_O[23])
);

my_buf data_outbuf_24 (
    .A(FrameData_O_i[24]),
    .X(FrameData_O[24])
);

my_buf data_outbuf_25 (
    .A(FrameData_O_i[25]),
    .X(FrameData_O[25])
);

my_buf data_outbuf_26 (
    .A(FrameData_O_i[26]),
    .X(FrameData_O[26])
);

my_buf data_outbuf_27 (
    .A(FrameData_O_i[27]),
    .X(FrameData_O[27])
);

my_buf data_outbuf_28 (
    .A(FrameData_O_i[28]),
    .X(FrameData_O[28])
);

my_buf data_outbuf_29 (
    .A(FrameData_O_i[29]),
    .X(FrameData_O[29])
);

my_buf data_outbuf_30 (
    .A(FrameData_O_i[30]),
    .X(FrameData_O[30])
);

my_buf data_outbuf_31 (
    .A(FrameData_O_i[31]),
    .X(FrameData_O[31])
);

assign FrameStrobe_O_i = FrameStrobe_i;

my_buf strobe_inbuf_0 (
    .A(FrameStrobe[0]),
    .X(FrameStrobe_i[0])
);

my_buf strobe_inbuf_1 (
    .A(FrameStrobe[1]),
    .X(FrameStrobe_i[1])
);

my_buf strobe_inbuf_2 (
    .A(FrameStrobe[2]),
    .X(FrameStrobe_i[2])
);

my_buf strobe_inbuf_3 (
    .A(FrameStrobe[3]),
    .X(FrameStrobe_i[3])
);

my_buf strobe_inbuf_4 (
    .A(FrameStrobe[4]),
    .X(FrameStrobe_i[4])
);

my_buf strobe_inbuf_5 (
    .A(FrameStrobe[5]),
    .X(FrameStrobe_i[5])
);

my_buf strobe_inbuf_6 (
    .A(FrameStrobe[6]),
    .X(FrameStrobe_i[6])
);

my_buf strobe_inbuf_7 (
    .A(FrameStrobe[7]),
    .X(FrameStrobe_i[7])
);

my_buf strobe_inbuf_8 (
    .A(FrameStrobe[8]),
    .X(FrameStrobe_i[8])
);

my_buf strobe_inbuf_9 (
    .A(FrameStrobe[9]),
    .X(FrameStrobe_i[9])
);

my_buf strobe_inbuf_10 (
    .A(FrameStrobe[10]),
    .X(FrameStrobe_i[10])
);

my_buf strobe_inbuf_11 (
    .A(FrameStrobe[11]),
    .X(FrameStrobe_i[11])
);

my_buf strobe_inbuf_12 (
    .A(FrameStrobe[12]),
    .X(FrameStrobe_i[12])
);

my_buf strobe_inbuf_13 (
    .A(FrameStrobe[13]),
    .X(FrameStrobe_i[13])
);

my_buf strobe_inbuf_14 (
    .A(FrameStrobe[14]),
    .X(FrameStrobe_i[14])
);

my_buf strobe_inbuf_15 (
    .A(FrameStrobe[15]),
    .X(FrameStrobe_i[15])
);

my_buf strobe_inbuf_16 (
    .A(FrameStrobe[16]),
    .X(FrameStrobe_i[16])
);

my_buf strobe_inbuf_17 (
    .A(FrameStrobe[17]),
    .X(FrameStrobe_i[17])
);

my_buf strobe_inbuf_18 (
    .A(FrameStrobe[18]),
    .X(FrameStrobe_i[18])
);

my_buf strobe_inbuf_19 (
    .A(FrameStrobe[19]),
    .X(FrameStrobe_i[19])
);

my_buf strobe_outbuf_0 (
    .A(FrameStrobe_O_i[0]),
    .X(FrameStrobe_O[0])
);

my_buf strobe_outbuf_1 (
    .A(FrameStrobe_O_i[1]),
    .X(FrameStrobe_O[1])
);

my_buf strobe_outbuf_2 (
    .A(FrameStrobe_O_i[2]),
    .X(FrameStrobe_O[2])
);

my_buf strobe_outbuf_3 (
    .A(FrameStrobe_O_i[3]),
    .X(FrameStrobe_O[3])
);

my_buf strobe_outbuf_4 (
    .A(FrameStrobe_O_i[4]),
    .X(FrameStrobe_O[4])
);

my_buf strobe_outbuf_5 (
    .A(FrameStrobe_O_i[5]),
    .X(FrameStrobe_O[5])
);

my_buf strobe_outbuf_6 (
    .A(FrameStrobe_O_i[6]),
    .X(FrameStrobe_O[6])
);

my_buf strobe_outbuf_7 (
    .A(FrameStrobe_O_i[7]),
    .X(FrameStrobe_O[7])
);

my_buf strobe_outbuf_8 (
    .A(FrameStrobe_O_i[8]),
    .X(FrameStrobe_O[8])
);

my_buf strobe_outbuf_9 (
    .A(FrameStrobe_O_i[9]),
    .X(FrameStrobe_O[9])
);

my_buf strobe_outbuf_10 (
    .A(FrameStrobe_O_i[10]),
    .X(FrameStrobe_O[10])
);

my_buf strobe_outbuf_11 (
    .A(FrameStrobe_O_i[11]),
    .X(FrameStrobe_O[11])
);

my_buf strobe_outbuf_12 (
    .A(FrameStrobe_O_i[12]),
    .X(FrameStrobe_O[12])
);

my_buf strobe_outbuf_13 (
    .A(FrameStrobe_O_i[13]),
    .X(FrameStrobe_O[13])
);

my_buf strobe_outbuf_14 (
    .A(FrameStrobe_O_i[14]),
    .X(FrameStrobe_O[14])
);

my_buf strobe_outbuf_15 (
    .A(FrameStrobe_O_i[15]),
    .X(FrameStrobe_O[15])
);

my_buf strobe_outbuf_16 (
    .A(FrameStrobe_O_i[16]),
    .X(FrameStrobe_O[16])
);

my_buf strobe_outbuf_17 (
    .A(FrameStrobe_O_i[17]),
    .X(FrameStrobe_O[17])
);

my_buf strobe_outbuf_18 (
    .A(FrameStrobe_O_i[18]),
    .X(FrameStrobe_O[18])
);

my_buf strobe_outbuf_19 (
    .A(FrameStrobe_O_i[19]),
    .X(FrameStrobe_O[19])
);


 //configuration storage latches
E_IO4_ConfigMem
`ifdef EMULATION
    #(
    .Emulate_Bitstream(Emulate_Bitstream)
    )
`endif
    Inst_E_IO4_ConfigMem
    (
    .FrameData(FrameData),
    .FrameStrobe(FrameStrobe),
    .ConfigBits(ConfigBits),
    .ConfigBits_N(ConfigBits_N)
);


 //BEL component instantiations
IOBUF Inst_A_IOBUF (
    .CLK(A_CLK),
    .IN(A_IN),
    .EN(A_EN),
    .OUT(A_OUT),
    .IN_top(A_IN_top),
    .EN_top(A_EN_top),
    .OUT_top(A_OUT_top),
    .ConfigBits(ConfigBits[3-1:0])
);

IOBUF Inst_B_IOBUF (
    .CLK(B_CLK),
    .IN(B_IN),
    .EN(B_EN),
    .OUT(B_OUT),
    .IN_top(B_IN_top),
    .EN_top(B_EN_top),
    .OUT_top(B_OUT_top),
    .ConfigBits(ConfigBits[6-1:3])
);

IOBUF Inst_C_IOBUF (
    .CLK(C_CLK),
    .IN(C_IN),
    .EN(C_EN),
    .OUT(C_OUT),
    .IN_top(C_IN_top),
    .EN_top(C_EN_top),
    .OUT_top(C_OUT_top),
    .ConfigBits(ConfigBits[9-1:6])
);

IOBUF Inst_D_IOBUF (
    .CLK(D_CLK),
    .IN(D_IN),
    .EN(D_EN),
    .OUT(D_OUT),
    .IN_top(D_IN_top),
    .EN_top(D_EN_top),
    .OUT_top(D_OUT_top),
    .ConfigBits(ConfigBits[12-1:9])
);

E_IO4_switch_matrix Inst_E_IO4_switch_matrix (
    .N_GBUF_END0(N_GBUF_END[0]),
    .N_GBUF_END1(N_GBUF_END[1]),
    .N_GBUF_END2(N_GBUF_END[2]),
    .N_GBUF_END3(N_GBUF_END[3]),
    .E1END0(E1END[0]),
    .E1END1(E1END[1]),
    .E1END2(E1END[2]),
    .E1END3(E1END[3]),
    .E1END4(E1END[4]),
    .E1END5(E1END[5]),
    .E1END6(E1END[6]),
    .E1END7(E1END[7]),
    .E2MID0(E2MID[0]),
    .E2MID1(E2MID[1]),
    .E2MID2(E2MID[2]),
    .E2MID3(E2MID[3]),
    .E2MID4(E2MID[4]),
    .E2MID5(E2MID[5]),
    .E2MID6(E2MID[6]),
    .E2MID7(E2MID[7]),
    .E2END0(E2END[0]),
    .E2END1(E2END[1]),
    .E2END2(E2END[2]),
    .E2END3(E2END[3]),
    .E2END4(E2END[4]),
    .E2END5(E2END[5]),
    .E2END6(E2END[6]),
    .E2END7(E2END[7]),
    .A_OUT(A_OUT),
    .B_OUT(B_OUT),
    .C_OUT(C_OUT),
    .D_OUT(D_OUT),
    .N_GBUF_BEG0(N_GBUF_BEG[0]),
    .N_GBUF_BEG1(N_GBUF_BEG[1]),
    .N_GBUF_BEG2(N_GBUF_BEG[2]),
    .N_GBUF_BEG3(N_GBUF_BEG[3]),
    .W1BEG0(W1BEG[0]),
    .W1BEG1(W1BEG[1]),
    .W1BEG2(W1BEG[2]),
    .W1BEG3(W1BEG[3]),
    .W1BEG4(W1BEG[4]),
    .W1BEG5(W1BEG[5]),
    .W1BEG6(W1BEG[6]),
    .W1BEG7(W1BEG[7]),
    .W2BEG0(W2BEG[0]),
    .W2BEG1(W2BEG[1]),
    .W2BEG2(W2BEG[2]),
    .W2BEG3(W2BEG[3]),
    .W2BEG4(W2BEG[4]),
    .W2BEG5(W2BEG[5]),
    .W2BEG6(W2BEG[6]),
    .W2BEG7(W2BEG[7]),
    .W2BEGb0(W2BEGb[0]),
    .W2BEGb1(W2BEGb[1]),
    .W2BEGb2(W2BEGb[2]),
    .W2BEGb3(W2BEGb[3]),
    .W2BEGb4(W2BEGb[4]),
    .W2BEGb5(W2BEGb[5]),
    .W2BEGb6(W2BEGb[6]),
    .W2BEGb7(W2BEGb[7]),
    .A_CLK(A_CLK),
    .A_IN(A_IN),
    .A_EN(A_EN),
    .B_CLK(B_CLK),
    .B_IN(B_IN),
    .B_EN(B_EN),
    .C_CLK(C_CLK),
    .C_IN(C_IN),
    .C_EN(C_EN),
    .D_CLK(D_CLK),
    .D_IN(D_IN),
    .D_EN(D_EN),
    .ConfigBits(ConfigBits[96-1:12]),
    .ConfigBits_N(ConfigBits_N[96-1:12])
);

endmodule
module E_IO_ConfigMem
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=60
    )
    (
        input  [FrameBitsPerRow - 1:0] FrameData,
        input  [MaxFramesPerCol - 1:0] FrameStrobe,
        output  [NoConfigBits - 1:0] ConfigBits,
        output  [NoConfigBits - 1:0] ConfigBits_N
    );

`ifdef EMULATION
assign ConfigBits[59] = Emulate_Bitstream[31];
assign ConfigBits[58] = Emulate_Bitstream[30];
assign ConfigBits[57] = Emulate_Bitstream[29];
assign ConfigBits[56] = Emulate_Bitstream[28];
assign ConfigBits[55] = Emulate_Bitstream[27];
assign ConfigBits[54] = Emulate_Bitstream[26];
assign ConfigBits[53] = Emulate_Bitstream[25];
assign ConfigBits[52] = Emulate_Bitstream[24];
assign ConfigBits[51] = Emulate_Bitstream[23];
assign ConfigBits[50] = Emulate_Bitstream[22];
assign ConfigBits[49] = Emulate_Bitstream[21];
assign ConfigBits[48] = Emulate_Bitstream[20];
assign ConfigBits[47] = Emulate_Bitstream[19];
assign ConfigBits[46] = Emulate_Bitstream[18];
assign ConfigBits[45] = Emulate_Bitstream[17];
assign ConfigBits[44] = Emulate_Bitstream[16];
assign ConfigBits[43] = Emulate_Bitstream[15];
assign ConfigBits[42] = Emulate_Bitstream[14];
assign ConfigBits[41] = Emulate_Bitstream[13];
assign ConfigBits[40] = Emulate_Bitstream[12];
assign ConfigBits[39] = Emulate_Bitstream[11];
assign ConfigBits[38] = Emulate_Bitstream[10];
assign ConfigBits[37] = Emulate_Bitstream[9];
assign ConfigBits[36] = Emulate_Bitstream[8];
assign ConfigBits[35] = Emulate_Bitstream[7];
assign ConfigBits[34] = Emulate_Bitstream[6];
assign ConfigBits[33] = Emulate_Bitstream[5];
assign ConfigBits[32] = Emulate_Bitstream[4];
assign ConfigBits[31] = Emulate_Bitstream[3];
assign ConfigBits[30] = Emulate_Bitstream[2];
assign ConfigBits[29] = Emulate_Bitstream[1];
assign ConfigBits[28] = Emulate_Bitstream[0];
assign ConfigBits[27] = Emulate_Bitstream[63];
assign ConfigBits[26] = Emulate_Bitstream[62];
assign ConfigBits[25] = Emulate_Bitstream[61];
assign ConfigBits[24] = Emulate_Bitstream[60];
assign ConfigBits[23] = Emulate_Bitstream[59];
assign ConfigBits[22] = Emulate_Bitstream[58];
assign ConfigBits[21] = Emulate_Bitstream[57];
assign ConfigBits[20] = Emulate_Bitstream[56];
assign ConfigBits[19] = Emulate_Bitstream[55];
assign ConfigBits[18] = Emulate_Bitstream[54];
assign ConfigBits[17] = Emulate_Bitstream[53];
assign ConfigBits[16] = Emulate_Bitstream[52];
assign ConfigBits[15] = Emulate_Bitstream[51];
assign ConfigBits[14] = Emulate_Bitstream[50];
assign ConfigBits[13] = Emulate_Bitstream[49];
assign ConfigBits[12] = Emulate_Bitstream[48];
assign ConfigBits[11] = Emulate_Bitstream[47];
assign ConfigBits[10] = Emulate_Bitstream[46];
assign ConfigBits[9] = Emulate_Bitstream[45];
assign ConfigBits[8] = Emulate_Bitstream[44];
assign ConfigBits[7] = Emulate_Bitstream[43];
assign ConfigBits[6] = Emulate_Bitstream[42];
assign ConfigBits[5] = Emulate_Bitstream[41];
assign ConfigBits[4] = Emulate_Bitstream[40];
assign ConfigBits[3] = Emulate_Bitstream[39];
assign ConfigBits[2] = Emulate_Bitstream[38];
assign ConfigBits[1] = Emulate_Bitstream[37];
assign ConfigBits[0] = Emulate_Bitstream[36];
`else

 //instantiate frame latches
config_latch Inst_frame0_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[59]),
    .QN(ConfigBits_N[59])
);

config_latch Inst_frame0_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[58]),
    .QN(ConfigBits_N[58])
);

config_latch Inst_frame0_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[57]),
    .QN(ConfigBits_N[57])
);

config_latch Inst_frame0_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[56]),
    .QN(ConfigBits_N[56])
);

config_latch Inst_frame0_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[55]),
    .QN(ConfigBits_N[55])
);

config_latch Inst_frame0_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[54]),
    .QN(ConfigBits_N[54])
);

config_latch Inst_frame0_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[53]),
    .QN(ConfigBits_N[53])
);

config_latch Inst_frame0_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[52]),
    .QN(ConfigBits_N[52])
);

config_latch Inst_frame0_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[51]),
    .QN(ConfigBits_N[51])
);

config_latch Inst_frame0_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[50]),
    .QN(ConfigBits_N[50])
);

config_latch Inst_frame0_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[49]),
    .QN(ConfigBits_N[49])
);

config_latch Inst_frame0_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[48]),
    .QN(ConfigBits_N[48])
);

config_latch Inst_frame0_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[47]),
    .QN(ConfigBits_N[47])
);

config_latch Inst_frame0_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[46]),
    .QN(ConfigBits_N[46])
);

config_latch Inst_frame0_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[45]),
    .QN(ConfigBits_N[45])
);

config_latch Inst_frame0_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[44]),
    .QN(ConfigBits_N[44])
);

config_latch Inst_frame0_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[43]),
    .QN(ConfigBits_N[43])
);

config_latch Inst_frame0_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[42]),
    .QN(ConfigBits_N[42])
);

config_latch Inst_frame0_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[41]),
    .QN(ConfigBits_N[41])
);

config_latch Inst_frame0_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[40]),
    .QN(ConfigBits_N[40])
);

config_latch Inst_frame0_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[39]),
    .QN(ConfigBits_N[39])
);

config_latch Inst_frame0_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[38]),
    .QN(ConfigBits_N[38])
);

config_latch Inst_frame0_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[37]),
    .QN(ConfigBits_N[37])
);

config_latch Inst_frame0_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[36]),
    .QN(ConfigBits_N[36])
);

config_latch Inst_frame0_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[35]),
    .QN(ConfigBits_N[35])
);

config_latch Inst_frame0_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[34]),
    .QN(ConfigBits_N[34])
);

config_latch Inst_frame0_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[33]),
    .QN(ConfigBits_N[33])
);

config_latch Inst_frame0_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[32]),
    .QN(ConfigBits_N[32])
);

config_latch Inst_frame0_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[31]),
    .QN(ConfigBits_N[31])
);

config_latch Inst_frame0_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[30]),
    .QN(ConfigBits_N[30])
);

config_latch Inst_frame0_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[29]),
    .QN(ConfigBits_N[29])
);

config_latch Inst_frame0_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[28]),
    .QN(ConfigBits_N[28])
);

config_latch Inst_frame1_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[27]),
    .QN(ConfigBits_N[27])
);

config_latch Inst_frame1_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[26]),
    .QN(ConfigBits_N[26])
);

config_latch Inst_frame1_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[25]),
    .QN(ConfigBits_N[25])
);

config_latch Inst_frame1_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[24]),
    .QN(ConfigBits_N[24])
);

config_latch Inst_frame1_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[23]),
    .QN(ConfigBits_N[23])
);

config_latch Inst_frame1_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[22]),
    .QN(ConfigBits_N[22])
);

config_latch Inst_frame1_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[21]),
    .QN(ConfigBits_N[21])
);

config_latch Inst_frame1_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[20]),
    .QN(ConfigBits_N[20])
);

config_latch Inst_frame1_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[19]),
    .QN(ConfigBits_N[19])
);

config_latch Inst_frame1_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[18]),
    .QN(ConfigBits_N[18])
);

config_latch Inst_frame1_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[17]),
    .QN(ConfigBits_N[17])
);

config_latch Inst_frame1_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[16]),
    .QN(ConfigBits_N[16])
);

config_latch Inst_frame1_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[15]),
    .QN(ConfigBits_N[15])
);

config_latch Inst_frame1_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[14]),
    .QN(ConfigBits_N[14])
);

config_latch Inst_frame1_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[13]),
    .QN(ConfigBits_N[13])
);

config_latch Inst_frame1_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[12]),
    .QN(ConfigBits_N[12])
);

config_latch Inst_frame1_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[11]),
    .QN(ConfigBits_N[11])
);

config_latch Inst_frame1_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[10]),
    .QN(ConfigBits_N[10])
);

config_latch Inst_frame1_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[9]),
    .QN(ConfigBits_N[9])
);

config_latch Inst_frame1_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[8]),
    .QN(ConfigBits_N[8])
);

config_latch Inst_frame1_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[7]),
    .QN(ConfigBits_N[7])
);

config_latch Inst_frame1_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[6]),
    .QN(ConfigBits_N[6])
);

config_latch Inst_frame1_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[5]),
    .QN(ConfigBits_N[5])
);

config_latch Inst_frame1_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[4]),
    .QN(ConfigBits_N[4])
);

config_latch Inst_frame1_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[3]),
    .QN(ConfigBits_N[3])
);

config_latch Inst_frame1_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[2]),
    .QN(ConfigBits_N[2])
);

config_latch Inst_frame1_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[1]),
    .QN(ConfigBits_N[1])
);

config_latch Inst_frame1_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[0]),
    .QN(ConfigBits_N[0])
);

`endif
endmodule
 // NumberOfConfigBits: 57
module E_IO_switch_matrix
    #(
        parameter NoConfigBits=57
    )
    (
        input  N_GBUF_END0,
        input  N_GBUF_END1,
        input  N_GBUF_END2,
        input  N_GBUF_END3,
        input  E1END0,
        input  E1END1,
        input  E1END2,
        input  E1END3,
        input  E1END4,
        input  E1END5,
        input  E1END6,
        input  E1END7,
        input  E2MID0,
        input  E2MID1,
        input  E2MID2,
        input  E2MID3,
        input  E2MID4,
        input  E2MID5,
        input  E2MID6,
        input  E2MID7,
        input  E2END0,
        input  E2END1,
        input  E2END2,
        input  E2END3,
        input  E2END4,
        input  E2END5,
        input  E2END6,
        input  E2END7,
        input  A_OUT,
        output  N_GBUF_BEG0,
        output  N_GBUF_BEG1,
        output  N_GBUF_BEG2,
        output  N_GBUF_BEG3,
        output  W1BEG0,
        output  W1BEG1,
        output  W1BEG2,
        output  W1BEG3,
        output  W1BEG4,
        output  W1BEG5,
        output  W1BEG6,
        output  W1BEG7,
        output  W2BEG0,
        output  W2BEG1,
        output  W2BEG2,
        output  W2BEG3,
        output  W2BEG4,
        output  W2BEG5,
        output  W2BEG6,
        output  W2BEG7,
        output  W2BEGb0,
        output  W2BEGb1,
        output  W2BEGb2,
        output  W2BEGb3,
        output  W2BEGb4,
        output  W2BEGb5,
        output  W2BEGb6,
        output  W2BEGb7,
        output  A_CLK,
        output  A_IN,
        output  A_EN,
 //global
        input  [NoConfigBits-1:0] ConfigBits,
        input  [NoConfigBits-1:0] ConfigBits_N
);
parameter GND0 = 1'b0;
parameter GND = 1'b0;
parameter VCC0 = 1'b1;
parameter VCC = 1'b1;
parameter VDD0 = 1'b1;
parameter VDD = 1'b1;

wire[4-1:0] W1BEG0_input;
wire[4-1:0] W1BEG1_input;
wire[4-1:0] W1BEG2_input;
wire[4-1:0] W1BEG3_input;
wire[4-1:0] W1BEG4_input;
wire[4-1:0] W1BEG5_input;
wire[4-1:0] W1BEG6_input;
wire[4-1:0] W1BEG7_input;
wire[4-1:0] W2BEG0_input;
wire[4-1:0] W2BEG1_input;
wire[4-1:0] W2BEG2_input;
wire[4-1:0] W2BEG3_input;
wire[4-1:0] W2BEG4_input;
wire[4-1:0] W2BEG5_input;
wire[4-1:0] W2BEG6_input;
wire[4-1:0] W2BEG7_input;
wire[4-1:0] W2BEGb0_input;
wire[4-1:0] W2BEGb1_input;
wire[4-1:0] W2BEGb2_input;
wire[4-1:0] W2BEGb3_input;
wire[4-1:0] W2BEGb4_input;
wire[4-1:0] W2BEGb5_input;
wire[4-1:0] W2BEGb6_input;
wire[4-1:0] W2BEGb7_input;
wire[4-1:0] A_CLK_input;
wire[16-1:0] A_IN_input;
wire[8-1:0] A_EN_input;
 //The configuration bits (if any) are just a long shift register
 //This shift register is padded to an even number of flops/latches
 //switch matrix multiplexer N_GBUF_BEG0 MUX-1
assign N_GBUF_BEG0 = N_GBUF_END0;

 //switch matrix multiplexer N_GBUF_BEG1 MUX-1
assign N_GBUF_BEG1 = N_GBUF_END1;

 //switch matrix multiplexer N_GBUF_BEG2 MUX-1
assign N_GBUF_BEG2 = N_GBUF_END2;

 //switch matrix multiplexer N_GBUF_BEG3 MUX-1
assign N_GBUF_BEG3 = N_GBUF_END3;

 //switch matrix multiplexer W1BEG0 MUX-4
assign W1BEG0_input = {A_OUT,E2END7,E2MID7,E1END7};
cus_mux41 inst_cus_mux41_W1BEG0 (
    .A0(W1BEG0_input[0]),
    .A1(W1BEG0_input[1]),
    .A2(W1BEG0_input[2]),
    .A3(W1BEG0_input[3]),
    .S0(ConfigBits[0+0]),
    .S0N(ConfigBits_N[0+0]),
    .S1(ConfigBits[0+1]),
    .S1N(ConfigBits_N[0+1]),
    .X(W1BEG0)
);

 //switch matrix multiplexer W1BEG1 MUX-4
assign W1BEG1_input = {A_OUT,E2END6,E2MID6,E1END6};
cus_mux41 inst_cus_mux41_W1BEG1 (
    .A0(W1BEG1_input[0]),
    .A1(W1BEG1_input[1]),
    .A2(W1BEG1_input[2]),
    .A3(W1BEG1_input[3]),
    .S0(ConfigBits[2+0]),
    .S0N(ConfigBits_N[2+0]),
    .S1(ConfigBits[2+1]),
    .S1N(ConfigBits_N[2+1]),
    .X(W1BEG1)
);

 //switch matrix multiplexer W1BEG2 MUX-4
assign W1BEG2_input = {A_OUT,E2END5,E2MID5,E1END5};
cus_mux41 inst_cus_mux41_W1BEG2 (
    .A0(W1BEG2_input[0]),
    .A1(W1BEG2_input[1]),
    .A2(W1BEG2_input[2]),
    .A3(W1BEG2_input[3]),
    .S0(ConfigBits[4+0]),
    .S0N(ConfigBits_N[4+0]),
    .S1(ConfigBits[4+1]),
    .S1N(ConfigBits_N[4+1]),
    .X(W1BEG2)
);

 //switch matrix multiplexer W1BEG3 MUX-4
assign W1BEG3_input = {A_OUT,E2END4,E2MID4,E1END4};
cus_mux41 inst_cus_mux41_W1BEG3 (
    .A0(W1BEG3_input[0]),
    .A1(W1BEG3_input[1]),
    .A2(W1BEG3_input[2]),
    .A3(W1BEG3_input[3]),
    .S0(ConfigBits[6+0]),
    .S0N(ConfigBits_N[6+0]),
    .S1(ConfigBits[6+1]),
    .S1N(ConfigBits_N[6+1]),
    .X(W1BEG3)
);

 //switch matrix multiplexer W1BEG4 MUX-4
assign W1BEG4_input = {A_OUT,E2END3,E2MID3,E1END3};
cus_mux41 inst_cus_mux41_W1BEG4 (
    .A0(W1BEG4_input[0]),
    .A1(W1BEG4_input[1]),
    .A2(W1BEG4_input[2]),
    .A3(W1BEG4_input[3]),
    .S0(ConfigBits[8+0]),
    .S0N(ConfigBits_N[8+0]),
    .S1(ConfigBits[8+1]),
    .S1N(ConfigBits_N[8+1]),
    .X(W1BEG4)
);

 //switch matrix multiplexer W1BEG5 MUX-4
assign W1BEG5_input = {A_OUT,E2END2,E2MID2,E1END2};
cus_mux41 inst_cus_mux41_W1BEG5 (
    .A0(W1BEG5_input[0]),
    .A1(W1BEG5_input[1]),
    .A2(W1BEG5_input[2]),
    .A3(W1BEG5_input[3]),
    .S0(ConfigBits[10+0]),
    .S0N(ConfigBits_N[10+0]),
    .S1(ConfigBits[10+1]),
    .S1N(ConfigBits_N[10+1]),
    .X(W1BEG5)
);

 //switch matrix multiplexer W1BEG6 MUX-4
assign W1BEG6_input = {A_OUT,E2END1,E2MID1,E1END1};
cus_mux41 inst_cus_mux41_W1BEG6 (
    .A0(W1BEG6_input[0]),
    .A1(W1BEG6_input[1]),
    .A2(W1BEG6_input[2]),
    .A3(W1BEG6_input[3]),
    .S0(ConfigBits[12+0]),
    .S0N(ConfigBits_N[12+0]),
    .S1(ConfigBits[12+1]),
    .S1N(ConfigBits_N[12+1]),
    .X(W1BEG6)
);

 //switch matrix multiplexer W1BEG7 MUX-4
assign W1BEG7_input = {A_OUT,E2END0,E2MID0,E1END0};
cus_mux41 inst_cus_mux41_W1BEG7 (
    .A0(W1BEG7_input[0]),
    .A1(W1BEG7_input[1]),
    .A2(W1BEG7_input[2]),
    .A3(W1BEG7_input[3]),
    .S0(ConfigBits[14+0]),
    .S0N(ConfigBits_N[14+0]),
    .S1(ConfigBits[14+1]),
    .S1N(ConfigBits_N[14+1]),
    .X(W1BEG7)
);

 //switch matrix multiplexer W2BEG0 MUX-4
assign W2BEG0_input = {A_OUT,E2END7,E2MID7,E1END7};
cus_mux41 inst_cus_mux41_W2BEG0 (
    .A0(W2BEG0_input[0]),
    .A1(W2BEG0_input[1]),
    .A2(W2BEG0_input[2]),
    .A3(W2BEG0_input[3]),
    .S0(ConfigBits[16+0]),
    .S0N(ConfigBits_N[16+0]),
    .S1(ConfigBits[16+1]),
    .S1N(ConfigBits_N[16+1]),
    .X(W2BEG0)
);

 //switch matrix multiplexer W2BEG1 MUX-4
assign W2BEG1_input = {A_OUT,E2END6,E2MID6,E1END6};
cus_mux41 inst_cus_mux41_W2BEG1 (
    .A0(W2BEG1_input[0]),
    .A1(W2BEG1_input[1]),
    .A2(W2BEG1_input[2]),
    .A3(W2BEG1_input[3]),
    .S0(ConfigBits[18+0]),
    .S0N(ConfigBits_N[18+0]),
    .S1(ConfigBits[18+1]),
    .S1N(ConfigBits_N[18+1]),
    .X(W2BEG1)
);

 //switch matrix multiplexer W2BEG2 MUX-4
assign W2BEG2_input = {A_OUT,E2END5,E2MID5,E1END5};
cus_mux41 inst_cus_mux41_W2BEG2 (
    .A0(W2BEG2_input[0]),
    .A1(W2BEG2_input[1]),
    .A2(W2BEG2_input[2]),
    .A3(W2BEG2_input[3]),
    .S0(ConfigBits[20+0]),
    .S0N(ConfigBits_N[20+0]),
    .S1(ConfigBits[20+1]),
    .S1N(ConfigBits_N[20+1]),
    .X(W2BEG2)
);

 //switch matrix multiplexer W2BEG3 MUX-4
assign W2BEG3_input = {A_OUT,E2END4,E2MID4,E1END4};
cus_mux41 inst_cus_mux41_W2BEG3 (
    .A0(W2BEG3_input[0]),
    .A1(W2BEG3_input[1]),
    .A2(W2BEG3_input[2]),
    .A3(W2BEG3_input[3]),
    .S0(ConfigBits[22+0]),
    .S0N(ConfigBits_N[22+0]),
    .S1(ConfigBits[22+1]),
    .S1N(ConfigBits_N[22+1]),
    .X(W2BEG3)
);

 //switch matrix multiplexer W2BEG4 MUX-4
assign W2BEG4_input = {A_OUT,E2END3,E2MID3,E1END3};
cus_mux41 inst_cus_mux41_W2BEG4 (
    .A0(W2BEG4_input[0]),
    .A1(W2BEG4_input[1]),
    .A2(W2BEG4_input[2]),
    .A3(W2BEG4_input[3]),
    .S0(ConfigBits[24+0]),
    .S0N(ConfigBits_N[24+0]),
    .S1(ConfigBits[24+1]),
    .S1N(ConfigBits_N[24+1]),
    .X(W2BEG4)
);

 //switch matrix multiplexer W2BEG5 MUX-4
assign W2BEG5_input = {A_OUT,E2END2,E2MID2,E1END2};
cus_mux41 inst_cus_mux41_W2BEG5 (
    .A0(W2BEG5_input[0]),
    .A1(W2BEG5_input[1]),
    .A2(W2BEG5_input[2]),
    .A3(W2BEG5_input[3]),
    .S0(ConfigBits[26+0]),
    .S0N(ConfigBits_N[26+0]),
    .S1(ConfigBits[26+1]),
    .S1N(ConfigBits_N[26+1]),
    .X(W2BEG5)
);

 //switch matrix multiplexer W2BEG6 MUX-4
assign W2BEG6_input = {A_OUT,E2END1,E2MID1,E1END1};
cus_mux41 inst_cus_mux41_W2BEG6 (
    .A0(W2BEG6_input[0]),
    .A1(W2BEG6_input[1]),
    .A2(W2BEG6_input[2]),
    .A3(W2BEG6_input[3]),
    .S0(ConfigBits[28+0]),
    .S0N(ConfigBits_N[28+0]),
    .S1(ConfigBits[28+1]),
    .S1N(ConfigBits_N[28+1]),
    .X(W2BEG6)
);

 //switch matrix multiplexer W2BEG7 MUX-4
assign W2BEG7_input = {A_OUT,E2END0,E2MID0,E1END0};
cus_mux41 inst_cus_mux41_W2BEG7 (
    .A0(W2BEG7_input[0]),
    .A1(W2BEG7_input[1]),
    .A2(W2BEG7_input[2]),
    .A3(W2BEG7_input[3]),
    .S0(ConfigBits[30+0]),
    .S0N(ConfigBits_N[30+0]),
    .S1(ConfigBits[30+1]),
    .S1N(ConfigBits_N[30+1]),
    .X(W2BEG7)
);

 //switch matrix multiplexer W2BEGb0 MUX-4
assign W2BEGb0_input = {A_OUT,E2END7,E2MID7,E1END7};
cus_mux41 inst_cus_mux41_W2BEGb0 (
    .A0(W2BEGb0_input[0]),
    .A1(W2BEGb0_input[1]),
    .A2(W2BEGb0_input[2]),
    .A3(W2BEGb0_input[3]),
    .S0(ConfigBits[32+0]),
    .S0N(ConfigBits_N[32+0]),
    .S1(ConfigBits[32+1]),
    .S1N(ConfigBits_N[32+1]),
    .X(W2BEGb0)
);

 //switch matrix multiplexer W2BEGb1 MUX-4
assign W2BEGb1_input = {A_OUT,E2END6,E2MID6,E1END6};
cus_mux41 inst_cus_mux41_W2BEGb1 (
    .A0(W2BEGb1_input[0]),
    .A1(W2BEGb1_input[1]),
    .A2(W2BEGb1_input[2]),
    .A3(W2BEGb1_input[3]),
    .S0(ConfigBits[34+0]),
    .S0N(ConfigBits_N[34+0]),
    .S1(ConfigBits[34+1]),
    .S1N(ConfigBits_N[34+1]),
    .X(W2BEGb1)
);

 //switch matrix multiplexer W2BEGb2 MUX-4
assign W2BEGb2_input = {A_OUT,E2END5,E2MID5,E1END5};
cus_mux41 inst_cus_mux41_W2BEGb2 (
    .A0(W2BEGb2_input[0]),
    .A1(W2BEGb2_input[1]),
    .A2(W2BEGb2_input[2]),
    .A3(W2BEGb2_input[3]),
    .S0(ConfigBits[36+0]),
    .S0N(ConfigBits_N[36+0]),
    .S1(ConfigBits[36+1]),
    .S1N(ConfigBits_N[36+1]),
    .X(W2BEGb2)
);

 //switch matrix multiplexer W2BEGb3 MUX-4
assign W2BEGb3_input = {A_OUT,E2END4,E2MID4,E1END4};
cus_mux41 inst_cus_mux41_W2BEGb3 (
    .A0(W2BEGb3_input[0]),
    .A1(W2BEGb3_input[1]),
    .A2(W2BEGb3_input[2]),
    .A3(W2BEGb3_input[3]),
    .S0(ConfigBits[38+0]),
    .S0N(ConfigBits_N[38+0]),
    .S1(ConfigBits[38+1]),
    .S1N(ConfigBits_N[38+1]),
    .X(W2BEGb3)
);

 //switch matrix multiplexer W2BEGb4 MUX-4
assign W2BEGb4_input = {A_OUT,E2END3,E2MID3,E1END3};
cus_mux41 inst_cus_mux41_W2BEGb4 (
    .A0(W2BEGb4_input[0]),
    .A1(W2BEGb4_input[1]),
    .A2(W2BEGb4_input[2]),
    .A3(W2BEGb4_input[3]),
    .S0(ConfigBits[40+0]),
    .S0N(ConfigBits_N[40+0]),
    .S1(ConfigBits[40+1]),
    .S1N(ConfigBits_N[40+1]),
    .X(W2BEGb4)
);

 //switch matrix multiplexer W2BEGb5 MUX-4
assign W2BEGb5_input = {A_OUT,E2END2,E2MID2,E1END2};
cus_mux41 inst_cus_mux41_W2BEGb5 (
    .A0(W2BEGb5_input[0]),
    .A1(W2BEGb5_input[1]),
    .A2(W2BEGb5_input[2]),
    .A3(W2BEGb5_input[3]),
    .S0(ConfigBits[42+0]),
    .S0N(ConfigBits_N[42+0]),
    .S1(ConfigBits[42+1]),
    .S1N(ConfigBits_N[42+1]),
    .X(W2BEGb5)
);

 //switch matrix multiplexer W2BEGb6 MUX-4
assign W2BEGb6_input = {A_OUT,E2END1,E2MID1,E1END1};
cus_mux41 inst_cus_mux41_W2BEGb6 (
    .A0(W2BEGb6_input[0]),
    .A1(W2BEGb6_input[1]),
    .A2(W2BEGb6_input[2]),
    .A3(W2BEGb6_input[3]),
    .S0(ConfigBits[44+0]),
    .S0N(ConfigBits_N[44+0]),
    .S1(ConfigBits[44+1]),
    .S1N(ConfigBits_N[44+1]),
    .X(W2BEGb6)
);

 //switch matrix multiplexer W2BEGb7 MUX-4
assign W2BEGb7_input = {A_OUT,E2END0,E2MID0,E1END0};
cus_mux41 inst_cus_mux41_W2BEGb7 (
    .A0(W2BEGb7_input[0]),
    .A1(W2BEGb7_input[1]),
    .A2(W2BEGb7_input[2]),
    .A3(W2BEGb7_input[3]),
    .S0(ConfigBits[46+0]),
    .S0N(ConfigBits_N[46+0]),
    .S1(ConfigBits[46+1]),
    .S1N(ConfigBits_N[46+1]),
    .X(W2BEGb7)
);

 //switch matrix multiplexer A_CLK MUX-4
assign A_CLK_input = {N_GBUF_END3,N_GBUF_END2,N_GBUF_END1,N_GBUF_END0};
cus_mux41 inst_cus_mux41_A_CLK (
    .A0(A_CLK_input[0]),
    .A1(A_CLK_input[1]),
    .A2(A_CLK_input[2]),
    .A3(A_CLK_input[3]),
    .S0(ConfigBits[48+0]),
    .S0N(ConfigBits_N[48+0]),
    .S1(ConfigBits[48+1]),
    .S1N(ConfigBits_N[48+1]),
    .X(A_CLK)
);

 //switch matrix multiplexer A_IN MUX-16
assign A_IN_input = {VCC0,GND0,E2END7,E2END6,E2END5,E2MID2,E2MID1,E2MID0,E1END7,E1END6,E1END5,E1END4,E1END3,E1END2,E1END1,E1END0};
cus_mux161 inst_cus_mux161_A_IN (
    .A0(A_IN_input[0]),
    .A1(A_IN_input[1]),
    .A2(A_IN_input[2]),
    .A3(A_IN_input[3]),
    .A4(A_IN_input[4]),
    .A5(A_IN_input[5]),
    .A6(A_IN_input[6]),
    .A7(A_IN_input[7]),
    .A8(A_IN_input[8]),
    .A9(A_IN_input[9]),
    .A10(A_IN_input[10]),
    .A11(A_IN_input[11]),
    .A12(A_IN_input[12]),
    .A13(A_IN_input[13]),
    .A14(A_IN_input[14]),
    .A15(A_IN_input[15]),
    .S0(ConfigBits[50+0]),
    .S0N(ConfigBits_N[50+0]),
    .S1(ConfigBits[50+1]),
    .S1N(ConfigBits_N[50+1]),
    .S2(ConfigBits[50+2]),
    .S2N(ConfigBits_N[50+2]),
    .S3(ConfigBits[50+3]),
    .S3N(ConfigBits_N[50+3]),
    .X(A_IN)
);

 //switch matrix multiplexer A_EN MUX-8
assign A_EN_input = {VCC0,GND0,E2END2,E2END0,E2MID7,E2MID4,E1END7,E1END3};
cus_mux81 inst_cus_mux81_A_EN (
    .A0(A_EN_input[0]),
    .A1(A_EN_input[1]),
    .A2(A_EN_input[2]),
    .A3(A_EN_input[3]),
    .A4(A_EN_input[4]),
    .A5(A_EN_input[5]),
    .A6(A_EN_input[6]),
    .A7(A_EN_input[7]),
    .S0(ConfigBits[54+0]),
    .S0N(ConfigBits_N[54+0]),
    .S1(ConfigBits[54+1]),
    .S1N(ConfigBits_N[54+1]),
    .S2(ConfigBits[54+2]),
    .S2N(ConfigBits_N[54+2]),
    .X(A_EN)
);

endmodule
module E_IO
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=60
    )
    (
 //N
        output  [3:0] N_GBUF_BEG,        //Port(Name=N_GBUF_BEG,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=4,Side=N)
 //W
        input  [7:0] E1END,        //Port(Name=E1END,IO=INPUT,XOffset=1,YOffset=0,WireCount=8,Side=W)
        input  [7:0] E2MID,        //Port(Name=E2MID,IO=INPUT,XOffset=1,YOffset=0,WireCount=8,Side=W)
        input  [7:0] E2END,        //Port(Name=E2END,IO=INPUT,XOffset=1,YOffset=0,WireCount=8,Side=W)
        output  [7:0] W1BEG,        //Port(Name=W1BEG,IO=OUTPUT,XOffset=-1,YOffset=0,WireCount=8,Side=W)
        output  [7:0] W2BEG,        //Port(Name=W2BEG,IO=OUTPUT,XOffset=-1,YOffset=0,WireCount=8,Side=W)
        output  [7:0] W2BEGb,        //Port(Name=W2BEGb,IO=OUTPUT,XOffset=-1,YOffset=0,WireCount=8,Side=W)
 //S
        input  [3:0] N_GBUF_END,        //Port(Name=N_GBUF_END,IO=INPUT,XOffset=0,YOffset=-1,WireCount=4,Side=S)
        input  A_OUT_top,
        output  A_IN_top,
        output  A_EN_top,
    //Tile IO ports from BELs
        input  [FrameBitsPerRow-1:0] FrameData, //CONFIG_PORT
        output  [FrameBitsPerRow-1:0] FrameData_O,
        input  [MaxFramesPerCol-1:0] FrameStrobe, //CONFIG_PORT
        output  [MaxFramesPerCol-1:0] FrameStrobe_O
    //global
);
 //signal declarations
 //BEL ports (e.g., slices)
wire A_CLK;
wire A_IN;
wire A_EN;
wire A_OUT;
 //Jump wires
 //internal configuration data signal to daisy-chain all BELs (if any and in the order they are listed in the fabric.csv)
wire[NoConfigBits-1:0] ConfigBits;
wire[NoConfigBits-1:0] ConfigBits_N;

 //Connection for outgoing wires
wire[FrameBitsPerRow-1:0] FrameData_i;
wire[FrameBitsPerRow-1:0] FrameData_O_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_O_i;

assign FrameData_O_i = FrameData_i;

my_buf data_inbuf_0 (
    .A(FrameData[0]),
    .X(FrameData_i[0])
);

my_buf data_inbuf_1 (
    .A(FrameData[1]),
    .X(FrameData_i[1])
);

my_buf data_inbuf_2 (
    .A(FrameData[2]),
    .X(FrameData_i[2])
);

my_buf data_inbuf_3 (
    .A(FrameData[3]),
    .X(FrameData_i[3])
);

my_buf data_inbuf_4 (
    .A(FrameData[4]),
    .X(FrameData_i[4])
);

my_buf data_inbuf_5 (
    .A(FrameData[5]),
    .X(FrameData_i[5])
);

my_buf data_inbuf_6 (
    .A(FrameData[6]),
    .X(FrameData_i[6])
);

my_buf data_inbuf_7 (
    .A(FrameData[7]),
    .X(FrameData_i[7])
);

my_buf data_inbuf_8 (
    .A(FrameData[8]),
    .X(FrameData_i[8])
);

my_buf data_inbuf_9 (
    .A(FrameData[9]),
    .X(FrameData_i[9])
);

my_buf data_inbuf_10 (
    .A(FrameData[10]),
    .X(FrameData_i[10])
);

my_buf data_inbuf_11 (
    .A(FrameData[11]),
    .X(FrameData_i[11])
);

my_buf data_inbuf_12 (
    .A(FrameData[12]),
    .X(FrameData_i[12])
);

my_buf data_inbuf_13 (
    .A(FrameData[13]),
    .X(FrameData_i[13])
);

my_buf data_inbuf_14 (
    .A(FrameData[14]),
    .X(FrameData_i[14])
);

my_buf data_inbuf_15 (
    .A(FrameData[15]),
    .X(FrameData_i[15])
);

my_buf data_inbuf_16 (
    .A(FrameData[16]),
    .X(FrameData_i[16])
);

my_buf data_inbuf_17 (
    .A(FrameData[17]),
    .X(FrameData_i[17])
);

my_buf data_inbuf_18 (
    .A(FrameData[18]),
    .X(FrameData_i[18])
);

my_buf data_inbuf_19 (
    .A(FrameData[19]),
    .X(FrameData_i[19])
);

my_buf data_inbuf_20 (
    .A(FrameData[20]),
    .X(FrameData_i[20])
);

my_buf data_inbuf_21 (
    .A(FrameData[21]),
    .X(FrameData_i[21])
);

my_buf data_inbuf_22 (
    .A(FrameData[22]),
    .X(FrameData_i[22])
);

my_buf data_inbuf_23 (
    .A(FrameData[23]),
    .X(FrameData_i[23])
);

my_buf data_inbuf_24 (
    .A(FrameData[24]),
    .X(FrameData_i[24])
);

my_buf data_inbuf_25 (
    .A(FrameData[25]),
    .X(FrameData_i[25])
);

my_buf data_inbuf_26 (
    .A(FrameData[26]),
    .X(FrameData_i[26])
);

my_buf data_inbuf_27 (
    .A(FrameData[27]),
    .X(FrameData_i[27])
);

my_buf data_inbuf_28 (
    .A(FrameData[28]),
    .X(FrameData_i[28])
);

my_buf data_inbuf_29 (
    .A(FrameData[29]),
    .X(FrameData_i[29])
);

my_buf data_inbuf_30 (
    .A(FrameData[30]),
    .X(FrameData_i[30])
);

my_buf data_inbuf_31 (
    .A(FrameData[31]),
    .X(FrameData_i[31])
);

my_buf data_outbuf_0 (
    .A(FrameData_O_i[0]),
    .X(FrameData_O[0])
);

my_buf data_outbuf_1 (
    .A(FrameData_O_i[1]),
    .X(FrameData_O[1])
);

my_buf data_outbuf_2 (
    .A(FrameData_O_i[2]),
    .X(FrameData_O[2])
);

my_buf data_outbuf_3 (
    .A(FrameData_O_i[3]),
    .X(FrameData_O[3])
);

my_buf data_outbuf_4 (
    .A(FrameData_O_i[4]),
    .X(FrameData_O[4])
);

my_buf data_outbuf_5 (
    .A(FrameData_O_i[5]),
    .X(FrameData_O[5])
);

my_buf data_outbuf_6 (
    .A(FrameData_O_i[6]),
    .X(FrameData_O[6])
);

my_buf data_outbuf_7 (
    .A(FrameData_O_i[7]),
    .X(FrameData_O[7])
);

my_buf data_outbuf_8 (
    .A(FrameData_O_i[8]),
    .X(FrameData_O[8])
);

my_buf data_outbuf_9 (
    .A(FrameData_O_i[9]),
    .X(FrameData_O[9])
);

my_buf data_outbuf_10 (
    .A(FrameData_O_i[10]),
    .X(FrameData_O[10])
);

my_buf data_outbuf_11 (
    .A(FrameData_O_i[11]),
    .X(FrameData_O[11])
);

my_buf data_outbuf_12 (
    .A(FrameData_O_i[12]),
    .X(FrameData_O[12])
);

my_buf data_outbuf_13 (
    .A(FrameData_O_i[13]),
    .X(FrameData_O[13])
);

my_buf data_outbuf_14 (
    .A(FrameData_O_i[14]),
    .X(FrameData_O[14])
);

my_buf data_outbuf_15 (
    .A(FrameData_O_i[15]),
    .X(FrameData_O[15])
);

my_buf data_outbuf_16 (
    .A(FrameData_O_i[16]),
    .X(FrameData_O[16])
);

my_buf data_outbuf_17 (
    .A(FrameData_O_i[17]),
    .X(FrameData_O[17])
);

my_buf data_outbuf_18 (
    .A(FrameData_O_i[18]),
    .X(FrameData_O[18])
);

my_buf data_outbuf_19 (
    .A(FrameData_O_i[19]),
    .X(FrameData_O[19])
);

my_buf data_outbuf_20 (
    .A(FrameData_O_i[20]),
    .X(FrameData_O[20])
);

my_buf data_outbuf_21 (
    .A(FrameData_O_i[21]),
    .X(FrameData_O[21])
);

my_buf data_outbuf_22 (
    .A(FrameData_O_i[22]),
    .X(FrameData_O[22])
);

my_buf data_outbuf_23 (
    .A(FrameData_O_i[23]),
    .X(FrameData_O[23])
);

my_buf data_outbuf_24 (
    .A(FrameData_O_i[24]),
    .X(FrameData_O[24])
);

my_buf data_outbuf_25 (
    .A(FrameData_O_i[25]),
    .X(FrameData_O[25])
);

my_buf data_outbuf_26 (
    .A(FrameData_O_i[26]),
    .X(FrameData_O[26])
);

my_buf data_outbuf_27 (
    .A(FrameData_O_i[27]),
    .X(FrameData_O[27])
);

my_buf data_outbuf_28 (
    .A(FrameData_O_i[28]),
    .X(FrameData_O[28])
);

my_buf data_outbuf_29 (
    .A(FrameData_O_i[29]),
    .X(FrameData_O[29])
);

my_buf data_outbuf_30 (
    .A(FrameData_O_i[30]),
    .X(FrameData_O[30])
);

my_buf data_outbuf_31 (
    .A(FrameData_O_i[31]),
    .X(FrameData_O[31])
);

assign FrameStrobe_O_i = FrameStrobe_i;

my_buf strobe_inbuf_0 (
    .A(FrameStrobe[0]),
    .X(FrameStrobe_i[0])
);

my_buf strobe_inbuf_1 (
    .A(FrameStrobe[1]),
    .X(FrameStrobe_i[1])
);

my_buf strobe_inbuf_2 (
    .A(FrameStrobe[2]),
    .X(FrameStrobe_i[2])
);

my_buf strobe_inbuf_3 (
    .A(FrameStrobe[3]),
    .X(FrameStrobe_i[3])
);

my_buf strobe_inbuf_4 (
    .A(FrameStrobe[4]),
    .X(FrameStrobe_i[4])
);

my_buf strobe_inbuf_5 (
    .A(FrameStrobe[5]),
    .X(FrameStrobe_i[5])
);

my_buf strobe_inbuf_6 (
    .A(FrameStrobe[6]),
    .X(FrameStrobe_i[6])
);

my_buf strobe_inbuf_7 (
    .A(FrameStrobe[7]),
    .X(FrameStrobe_i[7])
);

my_buf strobe_inbuf_8 (
    .A(FrameStrobe[8]),
    .X(FrameStrobe_i[8])
);

my_buf strobe_inbuf_9 (
    .A(FrameStrobe[9]),
    .X(FrameStrobe_i[9])
);

my_buf strobe_inbuf_10 (
    .A(FrameStrobe[10]),
    .X(FrameStrobe_i[10])
);

my_buf strobe_inbuf_11 (
    .A(FrameStrobe[11]),
    .X(FrameStrobe_i[11])
);

my_buf strobe_inbuf_12 (
    .A(FrameStrobe[12]),
    .X(FrameStrobe_i[12])
);

my_buf strobe_inbuf_13 (
    .A(FrameStrobe[13]),
    .X(FrameStrobe_i[13])
);

my_buf strobe_inbuf_14 (
    .A(FrameStrobe[14]),
    .X(FrameStrobe_i[14])
);

my_buf strobe_inbuf_15 (
    .A(FrameStrobe[15]),
    .X(FrameStrobe_i[15])
);

my_buf strobe_inbuf_16 (
    .A(FrameStrobe[16]),
    .X(FrameStrobe_i[16])
);

my_buf strobe_inbuf_17 (
    .A(FrameStrobe[17]),
    .X(FrameStrobe_i[17])
);

my_buf strobe_inbuf_18 (
    .A(FrameStrobe[18]),
    .X(FrameStrobe_i[18])
);

my_buf strobe_inbuf_19 (
    .A(FrameStrobe[19]),
    .X(FrameStrobe_i[19])
);

my_buf strobe_outbuf_0 (
    .A(FrameStrobe_O_i[0]),
    .X(FrameStrobe_O[0])
);

my_buf strobe_outbuf_1 (
    .A(FrameStrobe_O_i[1]),
    .X(FrameStrobe_O[1])
);

my_buf strobe_outbuf_2 (
    .A(FrameStrobe_O_i[2]),
    .X(FrameStrobe_O[2])
);

my_buf strobe_outbuf_3 (
    .A(FrameStrobe_O_i[3]),
    .X(FrameStrobe_O[3])
);

my_buf strobe_outbuf_4 (
    .A(FrameStrobe_O_i[4]),
    .X(FrameStrobe_O[4])
);

my_buf strobe_outbuf_5 (
    .A(FrameStrobe_O_i[5]),
    .X(FrameStrobe_O[5])
);

my_buf strobe_outbuf_6 (
    .A(FrameStrobe_O_i[6]),
    .X(FrameStrobe_O[6])
);

my_buf strobe_outbuf_7 (
    .A(FrameStrobe_O_i[7]),
    .X(FrameStrobe_O[7])
);

my_buf strobe_outbuf_8 (
    .A(FrameStrobe_O_i[8]),
    .X(FrameStrobe_O[8])
);

my_buf strobe_outbuf_9 (
    .A(FrameStrobe_O_i[9]),
    .X(FrameStrobe_O[9])
);

my_buf strobe_outbuf_10 (
    .A(FrameStrobe_O_i[10]),
    .X(FrameStrobe_O[10])
);

my_buf strobe_outbuf_11 (
    .A(FrameStrobe_O_i[11]),
    .X(FrameStrobe_O[11])
);

my_buf strobe_outbuf_12 (
    .A(FrameStrobe_O_i[12]),
    .X(FrameStrobe_O[12])
);

my_buf strobe_outbuf_13 (
    .A(FrameStrobe_O_i[13]),
    .X(FrameStrobe_O[13])
);

my_buf strobe_outbuf_14 (
    .A(FrameStrobe_O_i[14]),
    .X(FrameStrobe_O[14])
);

my_buf strobe_outbuf_15 (
    .A(FrameStrobe_O_i[15]),
    .X(FrameStrobe_O[15])
);

my_buf strobe_outbuf_16 (
    .A(FrameStrobe_O_i[16]),
    .X(FrameStrobe_O[16])
);

my_buf strobe_outbuf_17 (
    .A(FrameStrobe_O_i[17]),
    .X(FrameStrobe_O[17])
);

my_buf strobe_outbuf_18 (
    .A(FrameStrobe_O_i[18]),
    .X(FrameStrobe_O[18])
);

my_buf strobe_outbuf_19 (
    .A(FrameStrobe_O_i[19]),
    .X(FrameStrobe_O[19])
);


 //configuration storage latches
E_IO_ConfigMem
`ifdef EMULATION
    #(
    .Emulate_Bitstream(Emulate_Bitstream)
    )
`endif
    Inst_E_IO_ConfigMem
    (
    .FrameData(FrameData),
    .FrameStrobe(FrameStrobe),
    .ConfigBits(ConfigBits),
    .ConfigBits_N(ConfigBits_N)
);


 //BEL component instantiations
IOBUF Inst_A_IOBUF (
    .CLK(A_CLK),
    .IN(A_IN),
    .EN(A_EN),
    .OUT(A_OUT),
    .IN_top(A_IN_top),
    .EN_top(A_EN_top),
    .OUT_top(A_OUT_top),
    .ConfigBits(ConfigBits[3-1:0])
);

E_IO_switch_matrix Inst_E_IO_switch_matrix (
    .N_GBUF_END0(N_GBUF_END[0]),
    .N_GBUF_END1(N_GBUF_END[1]),
    .N_GBUF_END2(N_GBUF_END[2]),
    .N_GBUF_END3(N_GBUF_END[3]),
    .E1END0(E1END[0]),
    .E1END1(E1END[1]),
    .E1END2(E1END[2]),
    .E1END3(E1END[3]),
    .E1END4(E1END[4]),
    .E1END5(E1END[5]),
    .E1END6(E1END[6]),
    .E1END7(E1END[7]),
    .E2MID0(E2MID[0]),
    .E2MID1(E2MID[1]),
    .E2MID2(E2MID[2]),
    .E2MID3(E2MID[3]),
    .E2MID4(E2MID[4]),
    .E2MID5(E2MID[5]),
    .E2MID6(E2MID[6]),
    .E2MID7(E2MID[7]),
    .E2END0(E2END[0]),
    .E2END1(E2END[1]),
    .E2END2(E2END[2]),
    .E2END3(E2END[3]),
    .E2END4(E2END[4]),
    .E2END5(E2END[5]),
    .E2END6(E2END[6]),
    .E2END7(E2END[7]),
    .A_OUT(A_OUT),
    .N_GBUF_BEG0(N_GBUF_BEG[0]),
    .N_GBUF_BEG1(N_GBUF_BEG[1]),
    .N_GBUF_BEG2(N_GBUF_BEG[2]),
    .N_GBUF_BEG3(N_GBUF_BEG[3]),
    .W1BEG0(W1BEG[0]),
    .W1BEG1(W1BEG[1]),
    .W1BEG2(W1BEG[2]),
    .W1BEG3(W1BEG[3]),
    .W1BEG4(W1BEG[4]),
    .W1BEG5(W1BEG[5]),
    .W1BEG6(W1BEG[6]),
    .W1BEG7(W1BEG[7]),
    .W2BEG0(W2BEG[0]),
    .W2BEG1(W2BEG[1]),
    .W2BEG2(W2BEG[2]),
    .W2BEG3(W2BEG[3]),
    .W2BEG4(W2BEG[4]),
    .W2BEG5(W2BEG[5]),
    .W2BEG6(W2BEG[6]),
    .W2BEG7(W2BEG[7]),
    .W2BEGb0(W2BEGb[0]),
    .W2BEGb1(W2BEGb[1]),
    .W2BEGb2(W2BEGb[2]),
    .W2BEGb3(W2BEGb[3]),
    .W2BEGb4(W2BEGb[4]),
    .W2BEGb5(W2BEGb[5]),
    .W2BEGb6(W2BEGb[6]),
    .W2BEGb7(W2BEGb[7]),
    .A_CLK(A_CLK),
    .A_IN(A_IN),
    .A_EN(A_EN),
    .ConfigBits(ConfigBits[60-1:3]),
    .ConfigBits_N(ConfigBits_N[60-1:3])
);

endmodule
module E_term_ConfigMem
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=48
    )
    (
        input  [FrameBitsPerRow - 1:0] FrameData,
        input  [MaxFramesPerCol - 1:0] FrameStrobe,
        output  [NoConfigBits - 1:0] ConfigBits,
        output  [NoConfigBits - 1:0] ConfigBits_N
    );

`ifdef EMULATION
assign ConfigBits[47] = Emulate_Bitstream[31];
assign ConfigBits[46] = Emulate_Bitstream[30];
assign ConfigBits[45] = Emulate_Bitstream[29];
assign ConfigBits[44] = Emulate_Bitstream[28];
assign ConfigBits[43] = Emulate_Bitstream[27];
assign ConfigBits[42] = Emulate_Bitstream[26];
assign ConfigBits[41] = Emulate_Bitstream[25];
assign ConfigBits[40] = Emulate_Bitstream[24];
assign ConfigBits[39] = Emulate_Bitstream[23];
assign ConfigBits[38] = Emulate_Bitstream[22];
assign ConfigBits[37] = Emulate_Bitstream[21];
assign ConfigBits[36] = Emulate_Bitstream[20];
assign ConfigBits[35] = Emulate_Bitstream[19];
assign ConfigBits[34] = Emulate_Bitstream[18];
assign ConfigBits[33] = Emulate_Bitstream[17];
assign ConfigBits[32] = Emulate_Bitstream[16];
assign ConfigBits[31] = Emulate_Bitstream[15];
assign ConfigBits[30] = Emulate_Bitstream[14];
assign ConfigBits[29] = Emulate_Bitstream[13];
assign ConfigBits[28] = Emulate_Bitstream[12];
assign ConfigBits[27] = Emulate_Bitstream[11];
assign ConfigBits[26] = Emulate_Bitstream[10];
assign ConfigBits[25] = Emulate_Bitstream[9];
assign ConfigBits[24] = Emulate_Bitstream[8];
assign ConfigBits[23] = Emulate_Bitstream[7];
assign ConfigBits[22] = Emulate_Bitstream[6];
assign ConfigBits[21] = Emulate_Bitstream[5];
assign ConfigBits[20] = Emulate_Bitstream[4];
assign ConfigBits[19] = Emulate_Bitstream[3];
assign ConfigBits[18] = Emulate_Bitstream[2];
assign ConfigBits[17] = Emulate_Bitstream[1];
assign ConfigBits[16] = Emulate_Bitstream[0];
assign ConfigBits[15] = Emulate_Bitstream[63];
assign ConfigBits[14] = Emulate_Bitstream[62];
assign ConfigBits[13] = Emulate_Bitstream[61];
assign ConfigBits[12] = Emulate_Bitstream[60];
assign ConfigBits[11] = Emulate_Bitstream[59];
assign ConfigBits[10] = Emulate_Bitstream[58];
assign ConfigBits[9] = Emulate_Bitstream[57];
assign ConfigBits[8] = Emulate_Bitstream[56];
assign ConfigBits[7] = Emulate_Bitstream[55];
assign ConfigBits[6] = Emulate_Bitstream[54];
assign ConfigBits[5] = Emulate_Bitstream[53];
assign ConfigBits[4] = Emulate_Bitstream[52];
assign ConfigBits[3] = Emulate_Bitstream[51];
assign ConfigBits[2] = Emulate_Bitstream[50];
assign ConfigBits[1] = Emulate_Bitstream[49];
assign ConfigBits[0] = Emulate_Bitstream[48];
`else

 //instantiate frame latches
config_latch Inst_frame0_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[47]),
    .QN(ConfigBits_N[47])
);

config_latch Inst_frame0_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[46]),
    .QN(ConfigBits_N[46])
);

config_latch Inst_frame0_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[45]),
    .QN(ConfigBits_N[45])
);

config_latch Inst_frame0_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[44]),
    .QN(ConfigBits_N[44])
);

config_latch Inst_frame0_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[43]),
    .QN(ConfigBits_N[43])
);

config_latch Inst_frame0_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[42]),
    .QN(ConfigBits_N[42])
);

config_latch Inst_frame0_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[41]),
    .QN(ConfigBits_N[41])
);

config_latch Inst_frame0_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[40]),
    .QN(ConfigBits_N[40])
);

config_latch Inst_frame0_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[39]),
    .QN(ConfigBits_N[39])
);

config_latch Inst_frame0_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[38]),
    .QN(ConfigBits_N[38])
);

config_latch Inst_frame0_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[37]),
    .QN(ConfigBits_N[37])
);

config_latch Inst_frame0_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[36]),
    .QN(ConfigBits_N[36])
);

config_latch Inst_frame0_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[35]),
    .QN(ConfigBits_N[35])
);

config_latch Inst_frame0_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[34]),
    .QN(ConfigBits_N[34])
);

config_latch Inst_frame0_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[33]),
    .QN(ConfigBits_N[33])
);

config_latch Inst_frame0_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[32]),
    .QN(ConfigBits_N[32])
);

config_latch Inst_frame0_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[31]),
    .QN(ConfigBits_N[31])
);

config_latch Inst_frame0_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[30]),
    .QN(ConfigBits_N[30])
);

config_latch Inst_frame0_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[29]),
    .QN(ConfigBits_N[29])
);

config_latch Inst_frame0_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[28]),
    .QN(ConfigBits_N[28])
);

config_latch Inst_frame0_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[27]),
    .QN(ConfigBits_N[27])
);

config_latch Inst_frame0_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[26]),
    .QN(ConfigBits_N[26])
);

config_latch Inst_frame0_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[25]),
    .QN(ConfigBits_N[25])
);

config_latch Inst_frame0_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[24]),
    .QN(ConfigBits_N[24])
);

config_latch Inst_frame0_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[23]),
    .QN(ConfigBits_N[23])
);

config_latch Inst_frame0_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[22]),
    .QN(ConfigBits_N[22])
);

config_latch Inst_frame0_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[21]),
    .QN(ConfigBits_N[21])
);

config_latch Inst_frame0_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[20]),
    .QN(ConfigBits_N[20])
);

config_latch Inst_frame0_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[19]),
    .QN(ConfigBits_N[19])
);

config_latch Inst_frame0_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[18]),
    .QN(ConfigBits_N[18])
);

config_latch Inst_frame0_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[17]),
    .QN(ConfigBits_N[17])
);

config_latch Inst_frame0_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[16]),
    .QN(ConfigBits_N[16])
);

config_latch Inst_frame1_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[15]),
    .QN(ConfigBits_N[15])
);

config_latch Inst_frame1_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[14]),
    .QN(ConfigBits_N[14])
);

config_latch Inst_frame1_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[13]),
    .QN(ConfigBits_N[13])
);

config_latch Inst_frame1_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[12]),
    .QN(ConfigBits_N[12])
);

config_latch Inst_frame1_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[11]),
    .QN(ConfigBits_N[11])
);

config_latch Inst_frame1_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[10]),
    .QN(ConfigBits_N[10])
);

config_latch Inst_frame1_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[9]),
    .QN(ConfigBits_N[9])
);

config_latch Inst_frame1_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[8]),
    .QN(ConfigBits_N[8])
);

config_latch Inst_frame1_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[7]),
    .QN(ConfigBits_N[7])
);

config_latch Inst_frame1_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[6]),
    .QN(ConfigBits_N[6])
);

config_latch Inst_frame1_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[5]),
    .QN(ConfigBits_N[5])
);

config_latch Inst_frame1_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[4]),
    .QN(ConfigBits_N[4])
);

config_latch Inst_frame1_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[3]),
    .QN(ConfigBits_N[3])
);

config_latch Inst_frame1_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[2]),
    .QN(ConfigBits_N[2])
);

config_latch Inst_frame1_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[1]),
    .QN(ConfigBits_N[1])
);

config_latch Inst_frame1_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[0]),
    .QN(ConfigBits_N[0])
);

`endif
endmodule
 // NumberOfConfigBits: 48
module E_term_switch_matrix
    #(
        parameter NoConfigBits=48
    )
    (
        input  N_GBUF_END0,
        input  N_GBUF_END1,
        input  N_GBUF_END2,
        input  N_GBUF_END3,
        input  E1END0,
        input  E1END1,
        input  E1END2,
        input  E1END3,
        input  E1END4,
        input  E1END5,
        input  E1END6,
        input  E1END7,
        input  E2MID0,
        input  E2MID1,
        input  E2MID2,
        input  E2MID3,
        input  E2MID4,
        input  E2MID5,
        input  E2MID6,
        input  E2MID7,
        input  E2END0,
        input  E2END1,
        input  E2END2,
        input  E2END3,
        input  E2END4,
        input  E2END5,
        input  E2END6,
        input  E2END7,
        output  N_GBUF_BEG0,
        output  N_GBUF_BEG1,
        output  N_GBUF_BEG2,
        output  N_GBUF_BEG3,
        output  W1BEG0,
        output  W1BEG1,
        output  W1BEG2,
        output  W1BEG3,
        output  W1BEG4,
        output  W1BEG5,
        output  W1BEG6,
        output  W1BEG7,
        output  W2BEG0,
        output  W2BEG1,
        output  W2BEG2,
        output  W2BEG3,
        output  W2BEG4,
        output  W2BEG5,
        output  W2BEG6,
        output  W2BEG7,
        output  W2BEGb0,
        output  W2BEGb1,
        output  W2BEGb2,
        output  W2BEGb3,
        output  W2BEGb4,
        output  W2BEGb5,
        output  W2BEGb6,
        output  W2BEGb7,
 //global
        input  [NoConfigBits-1:0] ConfigBits,
        input  [NoConfigBits-1:0] ConfigBits_N
);
parameter GND0 = 1'b0;
parameter GND = 1'b0;
parameter VCC0 = 1'b1;
parameter VCC = 1'b1;
parameter VDD0 = 1'b1;
parameter VDD = 1'b1;

wire[4-1:0] W1BEG0_input;
wire[4-1:0] W1BEG1_input;
wire[4-1:0] W1BEG2_input;
wire[4-1:0] W1BEG3_input;
wire[4-1:0] W1BEG4_input;
wire[4-1:0] W1BEG5_input;
wire[4-1:0] W1BEG6_input;
wire[4-1:0] W1BEG7_input;
wire[4-1:0] W2BEG0_input;
wire[4-1:0] W2BEG1_input;
wire[4-1:0] W2BEG2_input;
wire[4-1:0] W2BEG3_input;
wire[4-1:0] W2BEG4_input;
wire[4-1:0] W2BEG5_input;
wire[4-1:0] W2BEG6_input;
wire[4-1:0] W2BEG7_input;
wire[4-1:0] W2BEGb0_input;
wire[4-1:0] W2BEGb1_input;
wire[4-1:0] W2BEGb2_input;
wire[4-1:0] W2BEGb3_input;
wire[4-1:0] W2BEGb4_input;
wire[4-1:0] W2BEGb5_input;
wire[4-1:0] W2BEGb6_input;
wire[4-1:0] W2BEGb7_input;
 //The configuration bits (if any) are just a long shift register
 //This shift register is padded to an even number of flops/latches
 //switch matrix multiplexer N_GBUF_BEG0 MUX-1
assign N_GBUF_BEG0 = N_GBUF_END0;

 //switch matrix multiplexer N_GBUF_BEG1 MUX-1
assign N_GBUF_BEG1 = N_GBUF_END1;

 //switch matrix multiplexer N_GBUF_BEG2 MUX-1
assign N_GBUF_BEG2 = N_GBUF_END2;

 //switch matrix multiplexer N_GBUF_BEG3 MUX-1
assign N_GBUF_BEG3 = N_GBUF_END3;

 //switch matrix multiplexer W1BEG0 MUX-4
assign W1BEG0_input = {E2END7,E2MID7,E1END7,E1END5};
cus_mux41 inst_cus_mux41_W1BEG0 (
    .A0(W1BEG0_input[0]),
    .A1(W1BEG0_input[1]),
    .A2(W1BEG0_input[2]),
    .A3(W1BEG0_input[3]),
    .S0(ConfigBits[0+0]),
    .S0N(ConfigBits_N[0+0]),
    .S1(ConfigBits[0+1]),
    .S1N(ConfigBits_N[0+1]),
    .X(W1BEG0)
);

 //switch matrix multiplexer W1BEG1 MUX-4
assign W1BEG1_input = {E2END6,E2MID6,E1END6,E1END3};
cus_mux41 inst_cus_mux41_W1BEG1 (
    .A0(W1BEG1_input[0]),
    .A1(W1BEG1_input[1]),
    .A2(W1BEG1_input[2]),
    .A3(W1BEG1_input[3]),
    .S0(ConfigBits[2+0]),
    .S0N(ConfigBits_N[2+0]),
    .S1(ConfigBits[2+1]),
    .S1N(ConfigBits_N[2+1]),
    .X(W1BEG1)
);

 //switch matrix multiplexer W1BEG2 MUX-4
assign W1BEG2_input = {E2END5,E2END1,E2MID5,E1END5};
cus_mux41 inst_cus_mux41_W1BEG2 (
    .A0(W1BEG2_input[0]),
    .A1(W1BEG2_input[1]),
    .A2(W1BEG2_input[2]),
    .A3(W1BEG2_input[3]),
    .S0(ConfigBits[4+0]),
    .S0N(ConfigBits_N[4+0]),
    .S1(ConfigBits[4+1]),
    .S1N(ConfigBits_N[4+1]),
    .X(W1BEG2)
);

 //switch matrix multiplexer W1BEG3 MUX-4
assign W1BEG3_input = {E2END6,E2END4,E2MID4,E1END4};
cus_mux41 inst_cus_mux41_W1BEG3 (
    .A0(W1BEG3_input[0]),
    .A1(W1BEG3_input[1]),
    .A2(W1BEG3_input[2]),
    .A3(W1BEG3_input[3]),
    .S0(ConfigBits[6+0]),
    .S0N(ConfigBits_N[6+0]),
    .S1(ConfigBits[6+1]),
    .S1N(ConfigBits_N[6+1]),
    .X(W1BEG3)
);

 //switch matrix multiplexer W1BEG4 MUX-4
assign W1BEG4_input = {E2END3,E2MID3,E2MID0,E1END3};
cus_mux41 inst_cus_mux41_W1BEG4 (
    .A0(W1BEG4_input[0]),
    .A1(W1BEG4_input[1]),
    .A2(W1BEG4_input[2]),
    .A3(W1BEG4_input[3]),
    .S0(ConfigBits[8+0]),
    .S0N(ConfigBits_N[8+0]),
    .S1(ConfigBits[8+1]),
    .S1N(ConfigBits_N[8+1]),
    .X(W1BEG4)
);

 //switch matrix multiplexer W1BEG5 MUX-4
assign W1BEG5_input = {E2END2,E2MID7,E2MID2,E1END2};
cus_mux41 inst_cus_mux41_W1BEG5 (
    .A0(W1BEG5_input[0]),
    .A1(W1BEG5_input[1]),
    .A2(W1BEG5_input[2]),
    .A3(W1BEG5_input[3]),
    .S0(ConfigBits[10+0]),
    .S0N(ConfigBits_N[10+0]),
    .S1(ConfigBits[10+1]),
    .S1N(ConfigBits_N[10+1]),
    .X(W1BEG5)
);

 //switch matrix multiplexer W1BEG6 MUX-4
assign W1BEG6_input = {VCC0,E2END1,E2MID1,E1END1};
cus_mux41 inst_cus_mux41_W1BEG6 (
    .A0(W1BEG6_input[0]),
    .A1(W1BEG6_input[1]),
    .A2(W1BEG6_input[2]),
    .A3(W1BEG6_input[3]),
    .S0(ConfigBits[12+0]),
    .S0N(ConfigBits_N[12+0]),
    .S1(ConfigBits[12+1]),
    .S1N(ConfigBits_N[12+1]),
    .X(W1BEG6)
);

 //switch matrix multiplexer W1BEG7 MUX-4
assign W1BEG7_input = {GND0,E2END0,E2MID0,E1END0};
cus_mux41 inst_cus_mux41_W1BEG7 (
    .A0(W1BEG7_input[0]),
    .A1(W1BEG7_input[1]),
    .A2(W1BEG7_input[2]),
    .A3(W1BEG7_input[3]),
    .S0(ConfigBits[14+0]),
    .S0N(ConfigBits_N[14+0]),
    .S1(ConfigBits[14+1]),
    .S1N(ConfigBits_N[14+1]),
    .X(W1BEG7)
);

 //switch matrix multiplexer W2BEG0 MUX-4
assign W2BEG0_input = {E2END7,E2MID7,E1END7,E1END5};
cus_mux41 inst_cus_mux41_W2BEG0 (
    .A0(W2BEG0_input[0]),
    .A1(W2BEG0_input[1]),
    .A2(W2BEG0_input[2]),
    .A3(W2BEG0_input[3]),
    .S0(ConfigBits[16+0]),
    .S0N(ConfigBits_N[16+0]),
    .S1(ConfigBits[16+1]),
    .S1N(ConfigBits_N[16+1]),
    .X(W2BEG0)
);

 //switch matrix multiplexer W2BEG1 MUX-4
assign W2BEG1_input = {E2END6,E2MID6,E1END6,E1END3};
cus_mux41 inst_cus_mux41_W2BEG1 (
    .A0(W2BEG1_input[0]),
    .A1(W2BEG1_input[1]),
    .A2(W2BEG1_input[2]),
    .A3(W2BEG1_input[3]),
    .S0(ConfigBits[18+0]),
    .S0N(ConfigBits_N[18+0]),
    .S1(ConfigBits[18+1]),
    .S1N(ConfigBits_N[18+1]),
    .X(W2BEG1)
);

 //switch matrix multiplexer W2BEG2 MUX-4
assign W2BEG2_input = {E2END5,E2END1,E2MID5,E1END5};
cus_mux41 inst_cus_mux41_W2BEG2 (
    .A0(W2BEG2_input[0]),
    .A1(W2BEG2_input[1]),
    .A2(W2BEG2_input[2]),
    .A3(W2BEG2_input[3]),
    .S0(ConfigBits[20+0]),
    .S0N(ConfigBits_N[20+0]),
    .S1(ConfigBits[20+1]),
    .S1N(ConfigBits_N[20+1]),
    .X(W2BEG2)
);

 //switch matrix multiplexer W2BEG3 MUX-4
assign W2BEG3_input = {E2END6,E2END4,E2MID4,E1END4};
cus_mux41 inst_cus_mux41_W2BEG3 (
    .A0(W2BEG3_input[0]),
    .A1(W2BEG3_input[1]),
    .A2(W2BEG3_input[2]),
    .A3(W2BEG3_input[3]),
    .S0(ConfigBits[22+0]),
    .S0N(ConfigBits_N[22+0]),
    .S1(ConfigBits[22+1]),
    .S1N(ConfigBits_N[22+1]),
    .X(W2BEG3)
);

 //switch matrix multiplexer W2BEG4 MUX-4
assign W2BEG4_input = {E2END3,E2MID3,E2MID0,E1END3};
cus_mux41 inst_cus_mux41_W2BEG4 (
    .A0(W2BEG4_input[0]),
    .A1(W2BEG4_input[1]),
    .A2(W2BEG4_input[2]),
    .A3(W2BEG4_input[3]),
    .S0(ConfigBits[24+0]),
    .S0N(ConfigBits_N[24+0]),
    .S1(ConfigBits[24+1]),
    .S1N(ConfigBits_N[24+1]),
    .X(W2BEG4)
);

 //switch matrix multiplexer W2BEG5 MUX-4
assign W2BEG5_input = {E2END2,E2MID7,E2MID2,E1END2};
cus_mux41 inst_cus_mux41_W2BEG5 (
    .A0(W2BEG5_input[0]),
    .A1(W2BEG5_input[1]),
    .A2(W2BEG5_input[2]),
    .A3(W2BEG5_input[3]),
    .S0(ConfigBits[26+0]),
    .S0N(ConfigBits_N[26+0]),
    .S1(ConfigBits[26+1]),
    .S1N(ConfigBits_N[26+1]),
    .X(W2BEG5)
);

 //switch matrix multiplexer W2BEG6 MUX-4
assign W2BEG6_input = {VCC0,E2END1,E2MID1,E1END1};
cus_mux41 inst_cus_mux41_W2BEG6 (
    .A0(W2BEG6_input[0]),
    .A1(W2BEG6_input[1]),
    .A2(W2BEG6_input[2]),
    .A3(W2BEG6_input[3]),
    .S0(ConfigBits[28+0]),
    .S0N(ConfigBits_N[28+0]),
    .S1(ConfigBits[28+1]),
    .S1N(ConfigBits_N[28+1]),
    .X(W2BEG6)
);

 //switch matrix multiplexer W2BEG7 MUX-4
assign W2BEG7_input = {GND0,E2END0,E2MID0,E1END0};
cus_mux41 inst_cus_mux41_W2BEG7 (
    .A0(W2BEG7_input[0]),
    .A1(W2BEG7_input[1]),
    .A2(W2BEG7_input[2]),
    .A3(W2BEG7_input[3]),
    .S0(ConfigBits[30+0]),
    .S0N(ConfigBits_N[30+0]),
    .S1(ConfigBits[30+1]),
    .S1N(ConfigBits_N[30+1]),
    .X(W2BEG7)
);

 //switch matrix multiplexer W2BEGb0 MUX-4
assign W2BEGb0_input = {E2END7,E2MID7,E1END7,E1END5};
cus_mux41 inst_cus_mux41_W2BEGb0 (
    .A0(W2BEGb0_input[0]),
    .A1(W2BEGb0_input[1]),
    .A2(W2BEGb0_input[2]),
    .A3(W2BEGb0_input[3]),
    .S0(ConfigBits[32+0]),
    .S0N(ConfigBits_N[32+0]),
    .S1(ConfigBits[32+1]),
    .S1N(ConfigBits_N[32+1]),
    .X(W2BEGb0)
);

 //switch matrix multiplexer W2BEGb1 MUX-4
assign W2BEGb1_input = {E2END6,E2MID6,E1END6,E1END3};
cus_mux41 inst_cus_mux41_W2BEGb1 (
    .A0(W2BEGb1_input[0]),
    .A1(W2BEGb1_input[1]),
    .A2(W2BEGb1_input[2]),
    .A3(W2BEGb1_input[3]),
    .S0(ConfigBits[34+0]),
    .S0N(ConfigBits_N[34+0]),
    .S1(ConfigBits[34+1]),
    .S1N(ConfigBits_N[34+1]),
    .X(W2BEGb1)
);

 //switch matrix multiplexer W2BEGb2 MUX-4
assign W2BEGb2_input = {E2END5,E2END1,E2MID5,E1END5};
cus_mux41 inst_cus_mux41_W2BEGb2 (
    .A0(W2BEGb2_input[0]),
    .A1(W2BEGb2_input[1]),
    .A2(W2BEGb2_input[2]),
    .A3(W2BEGb2_input[3]),
    .S0(ConfigBits[36+0]),
    .S0N(ConfigBits_N[36+0]),
    .S1(ConfigBits[36+1]),
    .S1N(ConfigBits_N[36+1]),
    .X(W2BEGb2)
);

 //switch matrix multiplexer W2BEGb3 MUX-4
assign W2BEGb3_input = {E2END6,E2END4,E2MID4,E1END4};
cus_mux41 inst_cus_mux41_W2BEGb3 (
    .A0(W2BEGb3_input[0]),
    .A1(W2BEGb3_input[1]),
    .A2(W2BEGb3_input[2]),
    .A3(W2BEGb3_input[3]),
    .S0(ConfigBits[38+0]),
    .S0N(ConfigBits_N[38+0]),
    .S1(ConfigBits[38+1]),
    .S1N(ConfigBits_N[38+1]),
    .X(W2BEGb3)
);

 //switch matrix multiplexer W2BEGb4 MUX-4
assign W2BEGb4_input = {E2END3,E2MID3,E2MID0,E1END3};
cus_mux41 inst_cus_mux41_W2BEGb4 (
    .A0(W2BEGb4_input[0]),
    .A1(W2BEGb4_input[1]),
    .A2(W2BEGb4_input[2]),
    .A3(W2BEGb4_input[3]),
    .S0(ConfigBits[40+0]),
    .S0N(ConfigBits_N[40+0]),
    .S1(ConfigBits[40+1]),
    .S1N(ConfigBits_N[40+1]),
    .X(W2BEGb4)
);

 //switch matrix multiplexer W2BEGb5 MUX-4
assign W2BEGb5_input = {E2END2,E2MID7,E2MID2,E1END2};
cus_mux41 inst_cus_mux41_W2BEGb5 (
    .A0(W2BEGb5_input[0]),
    .A1(W2BEGb5_input[1]),
    .A2(W2BEGb5_input[2]),
    .A3(W2BEGb5_input[3]),
    .S0(ConfigBits[42+0]),
    .S0N(ConfigBits_N[42+0]),
    .S1(ConfigBits[42+1]),
    .S1N(ConfigBits_N[42+1]),
    .X(W2BEGb5)
);

 //switch matrix multiplexer W2BEGb6 MUX-4
assign W2BEGb6_input = {VCC0,E2END1,E2MID1,E1END1};
cus_mux41 inst_cus_mux41_W2BEGb6 (
    .A0(W2BEGb6_input[0]),
    .A1(W2BEGb6_input[1]),
    .A2(W2BEGb6_input[2]),
    .A3(W2BEGb6_input[3]),
    .S0(ConfigBits[44+0]),
    .S0N(ConfigBits_N[44+0]),
    .S1(ConfigBits[44+1]),
    .S1N(ConfigBits_N[44+1]),
    .X(W2BEGb6)
);

 //switch matrix multiplexer W2BEGb7 MUX-4
assign W2BEGb7_input = {GND0,E2END0,E2MID0,E1END0};
cus_mux41 inst_cus_mux41_W2BEGb7 (
    .A0(W2BEGb7_input[0]),
    .A1(W2BEGb7_input[1]),
    .A2(W2BEGb7_input[2]),
    .A3(W2BEGb7_input[3]),
    .S0(ConfigBits[46+0]),
    .S0N(ConfigBits_N[46+0]),
    .S1(ConfigBits[46+1]),
    .S1N(ConfigBits_N[46+1]),
    .X(W2BEGb7)
);

endmodule
module E_term
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=48
    )
    (
 //N
        output  [3:0] N_GBUF_BEG,        //Port(Name=N_GBUF_BEG,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=4,Side=N)
 //W
        input  [7:0] E1END,        //Port(Name=E1END,IO=INPUT,XOffset=1,YOffset=0,WireCount=8,Side=W)
        input  [7:0] E2MID,        //Port(Name=E2MID,IO=INPUT,XOffset=1,YOffset=0,WireCount=8,Side=W)
        input  [7:0] E2END,        //Port(Name=E2END,IO=INPUT,XOffset=1,YOffset=0,WireCount=8,Side=W)
        output  [7:0] W1BEG,        //Port(Name=W1BEG,IO=OUTPUT,XOffset=-1,YOffset=0,WireCount=8,Side=W)
        output  [7:0] W2BEG,        //Port(Name=W2BEG,IO=OUTPUT,XOffset=-1,YOffset=0,WireCount=8,Side=W)
        output  [7:0] W2BEGb,        //Port(Name=W2BEGb,IO=OUTPUT,XOffset=-1,YOffset=0,WireCount=8,Side=W)
 //S
        input  [3:0] N_GBUF_END,        //Port(Name=N_GBUF_END,IO=INPUT,XOffset=0,YOffset=-1,WireCount=4,Side=S)
    //Tile IO ports from BELs
        input  [FrameBitsPerRow-1:0] FrameData, //CONFIG_PORT
        output  [FrameBitsPerRow-1:0] FrameData_O,
        input  [MaxFramesPerCol-1:0] FrameStrobe, //CONFIG_PORT
        output  [MaxFramesPerCol-1:0] FrameStrobe_O
    //global
);
 //signal declarations
 //BEL ports (e.g., slices)
 //Jump wires
 //internal configuration data signal to daisy-chain all BELs (if any and in the order they are listed in the fabric.csv)
wire[NoConfigBits-1:0] ConfigBits;
wire[NoConfigBits-1:0] ConfigBits_N;

 //Connection for outgoing wires
wire[FrameBitsPerRow-1:0] FrameData_i;
wire[FrameBitsPerRow-1:0] FrameData_O_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_O_i;

assign FrameData_O_i = FrameData_i;

my_buf data_inbuf_0 (
    .A(FrameData[0]),
    .X(FrameData_i[0])
);

my_buf data_inbuf_1 (
    .A(FrameData[1]),
    .X(FrameData_i[1])
);

my_buf data_inbuf_2 (
    .A(FrameData[2]),
    .X(FrameData_i[2])
);

my_buf data_inbuf_3 (
    .A(FrameData[3]),
    .X(FrameData_i[3])
);

my_buf data_inbuf_4 (
    .A(FrameData[4]),
    .X(FrameData_i[4])
);

my_buf data_inbuf_5 (
    .A(FrameData[5]),
    .X(FrameData_i[5])
);

my_buf data_inbuf_6 (
    .A(FrameData[6]),
    .X(FrameData_i[6])
);

my_buf data_inbuf_7 (
    .A(FrameData[7]),
    .X(FrameData_i[7])
);

my_buf data_inbuf_8 (
    .A(FrameData[8]),
    .X(FrameData_i[8])
);

my_buf data_inbuf_9 (
    .A(FrameData[9]),
    .X(FrameData_i[9])
);

my_buf data_inbuf_10 (
    .A(FrameData[10]),
    .X(FrameData_i[10])
);

my_buf data_inbuf_11 (
    .A(FrameData[11]),
    .X(FrameData_i[11])
);

my_buf data_inbuf_12 (
    .A(FrameData[12]),
    .X(FrameData_i[12])
);

my_buf data_inbuf_13 (
    .A(FrameData[13]),
    .X(FrameData_i[13])
);

my_buf data_inbuf_14 (
    .A(FrameData[14]),
    .X(FrameData_i[14])
);

my_buf data_inbuf_15 (
    .A(FrameData[15]),
    .X(FrameData_i[15])
);

my_buf data_inbuf_16 (
    .A(FrameData[16]),
    .X(FrameData_i[16])
);

my_buf data_inbuf_17 (
    .A(FrameData[17]),
    .X(FrameData_i[17])
);

my_buf data_inbuf_18 (
    .A(FrameData[18]),
    .X(FrameData_i[18])
);

my_buf data_inbuf_19 (
    .A(FrameData[19]),
    .X(FrameData_i[19])
);

my_buf data_inbuf_20 (
    .A(FrameData[20]),
    .X(FrameData_i[20])
);

my_buf data_inbuf_21 (
    .A(FrameData[21]),
    .X(FrameData_i[21])
);

my_buf data_inbuf_22 (
    .A(FrameData[22]),
    .X(FrameData_i[22])
);

my_buf data_inbuf_23 (
    .A(FrameData[23]),
    .X(FrameData_i[23])
);

my_buf data_inbuf_24 (
    .A(FrameData[24]),
    .X(FrameData_i[24])
);

my_buf data_inbuf_25 (
    .A(FrameData[25]),
    .X(FrameData_i[25])
);

my_buf data_inbuf_26 (
    .A(FrameData[26]),
    .X(FrameData_i[26])
);

my_buf data_inbuf_27 (
    .A(FrameData[27]),
    .X(FrameData_i[27])
);

my_buf data_inbuf_28 (
    .A(FrameData[28]),
    .X(FrameData_i[28])
);

my_buf data_inbuf_29 (
    .A(FrameData[29]),
    .X(FrameData_i[29])
);

my_buf data_inbuf_30 (
    .A(FrameData[30]),
    .X(FrameData_i[30])
);

my_buf data_inbuf_31 (
    .A(FrameData[31]),
    .X(FrameData_i[31])
);

my_buf data_outbuf_0 (
    .A(FrameData_O_i[0]),
    .X(FrameData_O[0])
);

my_buf data_outbuf_1 (
    .A(FrameData_O_i[1]),
    .X(FrameData_O[1])
);

my_buf data_outbuf_2 (
    .A(FrameData_O_i[2]),
    .X(FrameData_O[2])
);

my_buf data_outbuf_3 (
    .A(FrameData_O_i[3]),
    .X(FrameData_O[3])
);

my_buf data_outbuf_4 (
    .A(FrameData_O_i[4]),
    .X(FrameData_O[4])
);

my_buf data_outbuf_5 (
    .A(FrameData_O_i[5]),
    .X(FrameData_O[5])
);

my_buf data_outbuf_6 (
    .A(FrameData_O_i[6]),
    .X(FrameData_O[6])
);

my_buf data_outbuf_7 (
    .A(FrameData_O_i[7]),
    .X(FrameData_O[7])
);

my_buf data_outbuf_8 (
    .A(FrameData_O_i[8]),
    .X(FrameData_O[8])
);

my_buf data_outbuf_9 (
    .A(FrameData_O_i[9]),
    .X(FrameData_O[9])
);

my_buf data_outbuf_10 (
    .A(FrameData_O_i[10]),
    .X(FrameData_O[10])
);

my_buf data_outbuf_11 (
    .A(FrameData_O_i[11]),
    .X(FrameData_O[11])
);

my_buf data_outbuf_12 (
    .A(FrameData_O_i[12]),
    .X(FrameData_O[12])
);

my_buf data_outbuf_13 (
    .A(FrameData_O_i[13]),
    .X(FrameData_O[13])
);

my_buf data_outbuf_14 (
    .A(FrameData_O_i[14]),
    .X(FrameData_O[14])
);

my_buf data_outbuf_15 (
    .A(FrameData_O_i[15]),
    .X(FrameData_O[15])
);

my_buf data_outbuf_16 (
    .A(FrameData_O_i[16]),
    .X(FrameData_O[16])
);

my_buf data_outbuf_17 (
    .A(FrameData_O_i[17]),
    .X(FrameData_O[17])
);

my_buf data_outbuf_18 (
    .A(FrameData_O_i[18]),
    .X(FrameData_O[18])
);

my_buf data_outbuf_19 (
    .A(FrameData_O_i[19]),
    .X(FrameData_O[19])
);

my_buf data_outbuf_20 (
    .A(FrameData_O_i[20]),
    .X(FrameData_O[20])
);

my_buf data_outbuf_21 (
    .A(FrameData_O_i[21]),
    .X(FrameData_O[21])
);

my_buf data_outbuf_22 (
    .A(FrameData_O_i[22]),
    .X(FrameData_O[22])
);

my_buf data_outbuf_23 (
    .A(FrameData_O_i[23]),
    .X(FrameData_O[23])
);

my_buf data_outbuf_24 (
    .A(FrameData_O_i[24]),
    .X(FrameData_O[24])
);

my_buf data_outbuf_25 (
    .A(FrameData_O_i[25]),
    .X(FrameData_O[25])
);

my_buf data_outbuf_26 (
    .A(FrameData_O_i[26]),
    .X(FrameData_O[26])
);

my_buf data_outbuf_27 (
    .A(FrameData_O_i[27]),
    .X(FrameData_O[27])
);

my_buf data_outbuf_28 (
    .A(FrameData_O_i[28]),
    .X(FrameData_O[28])
);

my_buf data_outbuf_29 (
    .A(FrameData_O_i[29]),
    .X(FrameData_O[29])
);

my_buf data_outbuf_30 (
    .A(FrameData_O_i[30]),
    .X(FrameData_O[30])
);

my_buf data_outbuf_31 (
    .A(FrameData_O_i[31]),
    .X(FrameData_O[31])
);

assign FrameStrobe_O_i = FrameStrobe_i;

my_buf strobe_inbuf_0 (
    .A(FrameStrobe[0]),
    .X(FrameStrobe_i[0])
);

my_buf strobe_inbuf_1 (
    .A(FrameStrobe[1]),
    .X(FrameStrobe_i[1])
);

my_buf strobe_inbuf_2 (
    .A(FrameStrobe[2]),
    .X(FrameStrobe_i[2])
);

my_buf strobe_inbuf_3 (
    .A(FrameStrobe[3]),
    .X(FrameStrobe_i[3])
);

my_buf strobe_inbuf_4 (
    .A(FrameStrobe[4]),
    .X(FrameStrobe_i[4])
);

my_buf strobe_inbuf_5 (
    .A(FrameStrobe[5]),
    .X(FrameStrobe_i[5])
);

my_buf strobe_inbuf_6 (
    .A(FrameStrobe[6]),
    .X(FrameStrobe_i[6])
);

my_buf strobe_inbuf_7 (
    .A(FrameStrobe[7]),
    .X(FrameStrobe_i[7])
);

my_buf strobe_inbuf_8 (
    .A(FrameStrobe[8]),
    .X(FrameStrobe_i[8])
);

my_buf strobe_inbuf_9 (
    .A(FrameStrobe[9]),
    .X(FrameStrobe_i[9])
);

my_buf strobe_inbuf_10 (
    .A(FrameStrobe[10]),
    .X(FrameStrobe_i[10])
);

my_buf strobe_inbuf_11 (
    .A(FrameStrobe[11]),
    .X(FrameStrobe_i[11])
);

my_buf strobe_inbuf_12 (
    .A(FrameStrobe[12]),
    .X(FrameStrobe_i[12])
);

my_buf strobe_inbuf_13 (
    .A(FrameStrobe[13]),
    .X(FrameStrobe_i[13])
);

my_buf strobe_inbuf_14 (
    .A(FrameStrobe[14]),
    .X(FrameStrobe_i[14])
);

my_buf strobe_inbuf_15 (
    .A(FrameStrobe[15]),
    .X(FrameStrobe_i[15])
);

my_buf strobe_inbuf_16 (
    .A(FrameStrobe[16]),
    .X(FrameStrobe_i[16])
);

my_buf strobe_inbuf_17 (
    .A(FrameStrobe[17]),
    .X(FrameStrobe_i[17])
);

my_buf strobe_inbuf_18 (
    .A(FrameStrobe[18]),
    .X(FrameStrobe_i[18])
);

my_buf strobe_inbuf_19 (
    .A(FrameStrobe[19]),
    .X(FrameStrobe_i[19])
);

my_buf strobe_outbuf_0 (
    .A(FrameStrobe_O_i[0]),
    .X(FrameStrobe_O[0])
);

my_buf strobe_outbuf_1 (
    .A(FrameStrobe_O_i[1]),
    .X(FrameStrobe_O[1])
);

my_buf strobe_outbuf_2 (
    .A(FrameStrobe_O_i[2]),
    .X(FrameStrobe_O[2])
);

my_buf strobe_outbuf_3 (
    .A(FrameStrobe_O_i[3]),
    .X(FrameStrobe_O[3])
);

my_buf strobe_outbuf_4 (
    .A(FrameStrobe_O_i[4]),
    .X(FrameStrobe_O[4])
);

my_buf strobe_outbuf_5 (
    .A(FrameStrobe_O_i[5]),
    .X(FrameStrobe_O[5])
);

my_buf strobe_outbuf_6 (
    .A(FrameStrobe_O_i[6]),
    .X(FrameStrobe_O[6])
);

my_buf strobe_outbuf_7 (
    .A(FrameStrobe_O_i[7]),
    .X(FrameStrobe_O[7])
);

my_buf strobe_outbuf_8 (
    .A(FrameStrobe_O_i[8]),
    .X(FrameStrobe_O[8])
);

my_buf strobe_outbuf_9 (
    .A(FrameStrobe_O_i[9]),
    .X(FrameStrobe_O[9])
);

my_buf strobe_outbuf_10 (
    .A(FrameStrobe_O_i[10]),
    .X(FrameStrobe_O[10])
);

my_buf strobe_outbuf_11 (
    .A(FrameStrobe_O_i[11]),
    .X(FrameStrobe_O[11])
);

my_buf strobe_outbuf_12 (
    .A(FrameStrobe_O_i[12]),
    .X(FrameStrobe_O[12])
);

my_buf strobe_outbuf_13 (
    .A(FrameStrobe_O_i[13]),
    .X(FrameStrobe_O[13])
);

my_buf strobe_outbuf_14 (
    .A(FrameStrobe_O_i[14]),
    .X(FrameStrobe_O[14])
);

my_buf strobe_outbuf_15 (
    .A(FrameStrobe_O_i[15]),
    .X(FrameStrobe_O[15])
);

my_buf strobe_outbuf_16 (
    .A(FrameStrobe_O_i[16]),
    .X(FrameStrobe_O[16])
);

my_buf strobe_outbuf_17 (
    .A(FrameStrobe_O_i[17]),
    .X(FrameStrobe_O[17])
);

my_buf strobe_outbuf_18 (
    .A(FrameStrobe_O_i[18]),
    .X(FrameStrobe_O[18])
);

my_buf strobe_outbuf_19 (
    .A(FrameStrobe_O_i[19]),
    .X(FrameStrobe_O[19])
);


 //configuration storage latches
E_term_ConfigMem
`ifdef EMULATION
    #(
    .Emulate_Bitstream(Emulate_Bitstream)
    )
`endif
    Inst_E_term_ConfigMem
    (
    .FrameData(FrameData),
    .FrameStrobe(FrameStrobe),
    .ConfigBits(ConfigBits),
    .ConfigBits_N(ConfigBits_N)
);

E_term_switch_matrix Inst_E_term_switch_matrix (
    .N_GBUF_END0(N_GBUF_END[0]),
    .N_GBUF_END1(N_GBUF_END[1]),
    .N_GBUF_END2(N_GBUF_END[2]),
    .N_GBUF_END3(N_GBUF_END[3]),
    .E1END0(E1END[0]),
    .E1END1(E1END[1]),
    .E1END2(E1END[2]),
    .E1END3(E1END[3]),
    .E1END4(E1END[4]),
    .E1END5(E1END[5]),
    .E1END6(E1END[6]),
    .E1END7(E1END[7]),
    .E2MID0(E2MID[0]),
    .E2MID1(E2MID[1]),
    .E2MID2(E2MID[2]),
    .E2MID3(E2MID[3]),
    .E2MID4(E2MID[4]),
    .E2MID5(E2MID[5]),
    .E2MID6(E2MID[6]),
    .E2MID7(E2MID[7]),
    .E2END0(E2END[0]),
    .E2END1(E2END[1]),
    .E2END2(E2END[2]),
    .E2END3(E2END[3]),
    .E2END4(E2END[4]),
    .E2END5(E2END[5]),
    .E2END6(E2END[6]),
    .E2END7(E2END[7]),
    .N_GBUF_BEG0(N_GBUF_BEG[0]),
    .N_GBUF_BEG1(N_GBUF_BEG[1]),
    .N_GBUF_BEG2(N_GBUF_BEG[2]),
    .N_GBUF_BEG3(N_GBUF_BEG[3]),
    .W1BEG0(W1BEG[0]),
    .W1BEG1(W1BEG[1]),
    .W1BEG2(W1BEG[2]),
    .W1BEG3(W1BEG[3]),
    .W1BEG4(W1BEG[4]),
    .W1BEG5(W1BEG[5]),
    .W1BEG6(W1BEG[6]),
    .W1BEG7(W1BEG[7]),
    .W2BEG0(W2BEG[0]),
    .W2BEG1(W2BEG[1]),
    .W2BEG2(W2BEG[2]),
    .W2BEG3(W2BEG[3]),
    .W2BEG4(W2BEG[4]),
    .W2BEG5(W2BEG[5]),
    .W2BEG6(W2BEG[6]),
    .W2BEG7(W2BEG[7]),
    .W2BEGb0(W2BEGb[0]),
    .W2BEGb1(W2BEGb[1]),
    .W2BEGb2(W2BEGb[2]),
    .W2BEGb3(W2BEGb[3]),
    .W2BEGb4(W2BEGb[4]),
    .W2BEGb5(W2BEGb[5]),
    .W2BEGb6(W2BEGb[6]),
    .W2BEGb7(W2BEGb[7]),
    .ConfigBits(ConfigBits[48-1:0]),
    .ConfigBits_N(ConfigBits_N[48-1:0])
);

endmodule
module LUT4x8_ha_ConfigMem
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=566
    )
    (
        input  [FrameBitsPerRow - 1:0] FrameData,
        input  [MaxFramesPerCol - 1:0] FrameStrobe,
        output  [NoConfigBits - 1:0] ConfigBits,
        output  [NoConfigBits - 1:0] ConfigBits_N
    );

`ifdef EMULATION
assign ConfigBits[565] = Emulate_Bitstream[31];
assign ConfigBits[564] = Emulate_Bitstream[30];
assign ConfigBits[563] = Emulate_Bitstream[29];
assign ConfigBits[562] = Emulate_Bitstream[28];
assign ConfigBits[561] = Emulate_Bitstream[27];
assign ConfigBits[560] = Emulate_Bitstream[26];
assign ConfigBits[559] = Emulate_Bitstream[25];
assign ConfigBits[558] = Emulate_Bitstream[24];
assign ConfigBits[557] = Emulate_Bitstream[23];
assign ConfigBits[556] = Emulate_Bitstream[22];
assign ConfigBits[555] = Emulate_Bitstream[21];
assign ConfigBits[554] = Emulate_Bitstream[20];
assign ConfigBits[553] = Emulate_Bitstream[19];
assign ConfigBits[552] = Emulate_Bitstream[18];
assign ConfigBits[551] = Emulate_Bitstream[17];
assign ConfigBits[550] = Emulate_Bitstream[16];
assign ConfigBits[549] = Emulate_Bitstream[15];
assign ConfigBits[548] = Emulate_Bitstream[14];
assign ConfigBits[547] = Emulate_Bitstream[13];
assign ConfigBits[546] = Emulate_Bitstream[12];
assign ConfigBits[545] = Emulate_Bitstream[11];
assign ConfigBits[544] = Emulate_Bitstream[10];
assign ConfigBits[543] = Emulate_Bitstream[9];
assign ConfigBits[542] = Emulate_Bitstream[8];
assign ConfigBits[541] = Emulate_Bitstream[7];
assign ConfigBits[540] = Emulate_Bitstream[6];
assign ConfigBits[539] = Emulate_Bitstream[5];
assign ConfigBits[538] = Emulate_Bitstream[4];
assign ConfigBits[537] = Emulate_Bitstream[3];
assign ConfigBits[536] = Emulate_Bitstream[2];
assign ConfigBits[535] = Emulate_Bitstream[1];
assign ConfigBits[534] = Emulate_Bitstream[0];
assign ConfigBits[533] = Emulate_Bitstream[63];
assign ConfigBits[532] = Emulate_Bitstream[62];
assign ConfigBits[531] = Emulate_Bitstream[61];
assign ConfigBits[530] = Emulate_Bitstream[60];
assign ConfigBits[529] = Emulate_Bitstream[59];
assign ConfigBits[528] = Emulate_Bitstream[58];
assign ConfigBits[527] = Emulate_Bitstream[57];
assign ConfigBits[526] = Emulate_Bitstream[56];
assign ConfigBits[525] = Emulate_Bitstream[55];
assign ConfigBits[524] = Emulate_Bitstream[54];
assign ConfigBits[523] = Emulate_Bitstream[53];
assign ConfigBits[522] = Emulate_Bitstream[52];
assign ConfigBits[521] = Emulate_Bitstream[51];
assign ConfigBits[520] = Emulate_Bitstream[50];
assign ConfigBits[519] = Emulate_Bitstream[49];
assign ConfigBits[518] = Emulate_Bitstream[48];
assign ConfigBits[517] = Emulate_Bitstream[47];
assign ConfigBits[516] = Emulate_Bitstream[46];
assign ConfigBits[515] = Emulate_Bitstream[45];
assign ConfigBits[514] = Emulate_Bitstream[44];
assign ConfigBits[513] = Emulate_Bitstream[43];
assign ConfigBits[512] = Emulate_Bitstream[42];
assign ConfigBits[511] = Emulate_Bitstream[41];
assign ConfigBits[510] = Emulate_Bitstream[40];
assign ConfigBits[509] = Emulate_Bitstream[39];
assign ConfigBits[508] = Emulate_Bitstream[38];
assign ConfigBits[507] = Emulate_Bitstream[37];
assign ConfigBits[506] = Emulate_Bitstream[36];
assign ConfigBits[505] = Emulate_Bitstream[35];
assign ConfigBits[504] = Emulate_Bitstream[34];
assign ConfigBits[503] = Emulate_Bitstream[33];
assign ConfigBits[502] = Emulate_Bitstream[32];
assign ConfigBits[501] = Emulate_Bitstream[95];
assign ConfigBits[500] = Emulate_Bitstream[94];
assign ConfigBits[499] = Emulate_Bitstream[93];
assign ConfigBits[498] = Emulate_Bitstream[92];
assign ConfigBits[497] = Emulate_Bitstream[91];
assign ConfigBits[496] = Emulate_Bitstream[90];
assign ConfigBits[495] = Emulate_Bitstream[89];
assign ConfigBits[494] = Emulate_Bitstream[88];
assign ConfigBits[493] = Emulate_Bitstream[87];
assign ConfigBits[492] = Emulate_Bitstream[86];
assign ConfigBits[491] = Emulate_Bitstream[85];
assign ConfigBits[490] = Emulate_Bitstream[84];
assign ConfigBits[489] = Emulate_Bitstream[83];
assign ConfigBits[488] = Emulate_Bitstream[82];
assign ConfigBits[487] = Emulate_Bitstream[81];
assign ConfigBits[486] = Emulate_Bitstream[80];
assign ConfigBits[485] = Emulate_Bitstream[79];
assign ConfigBits[484] = Emulate_Bitstream[78];
assign ConfigBits[483] = Emulate_Bitstream[77];
assign ConfigBits[482] = Emulate_Bitstream[76];
assign ConfigBits[481] = Emulate_Bitstream[75];
assign ConfigBits[480] = Emulate_Bitstream[74];
assign ConfigBits[479] = Emulate_Bitstream[73];
assign ConfigBits[478] = Emulate_Bitstream[72];
assign ConfigBits[477] = Emulate_Bitstream[71];
assign ConfigBits[476] = Emulate_Bitstream[70];
assign ConfigBits[475] = Emulate_Bitstream[69];
assign ConfigBits[474] = Emulate_Bitstream[68];
assign ConfigBits[473] = Emulate_Bitstream[67];
assign ConfigBits[472] = Emulate_Bitstream[66];
assign ConfigBits[471] = Emulate_Bitstream[65];
assign ConfigBits[470] = Emulate_Bitstream[64];
assign ConfigBits[469] = Emulate_Bitstream[127];
assign ConfigBits[468] = Emulate_Bitstream[126];
assign ConfigBits[467] = Emulate_Bitstream[125];
assign ConfigBits[466] = Emulate_Bitstream[124];
assign ConfigBits[465] = Emulate_Bitstream[123];
assign ConfigBits[464] = Emulate_Bitstream[122];
assign ConfigBits[463] = Emulate_Bitstream[121];
assign ConfigBits[462] = Emulate_Bitstream[120];
assign ConfigBits[461] = Emulate_Bitstream[119];
assign ConfigBits[460] = Emulate_Bitstream[118];
assign ConfigBits[459] = Emulate_Bitstream[117];
assign ConfigBits[458] = Emulate_Bitstream[116];
assign ConfigBits[457] = Emulate_Bitstream[115];
assign ConfigBits[456] = Emulate_Bitstream[114];
assign ConfigBits[455] = Emulate_Bitstream[113];
assign ConfigBits[454] = Emulate_Bitstream[112];
assign ConfigBits[453] = Emulate_Bitstream[111];
assign ConfigBits[452] = Emulate_Bitstream[110];
assign ConfigBits[451] = Emulate_Bitstream[109];
assign ConfigBits[450] = Emulate_Bitstream[108];
assign ConfigBits[449] = Emulate_Bitstream[107];
assign ConfigBits[448] = Emulate_Bitstream[106];
assign ConfigBits[447] = Emulate_Bitstream[105];
assign ConfigBits[446] = Emulate_Bitstream[104];
assign ConfigBits[445] = Emulate_Bitstream[103];
assign ConfigBits[444] = Emulate_Bitstream[102];
assign ConfigBits[443] = Emulate_Bitstream[101];
assign ConfigBits[442] = Emulate_Bitstream[100];
assign ConfigBits[441] = Emulate_Bitstream[99];
assign ConfigBits[440] = Emulate_Bitstream[98];
assign ConfigBits[439] = Emulate_Bitstream[97];
assign ConfigBits[438] = Emulate_Bitstream[96];
assign ConfigBits[437] = Emulate_Bitstream[159];
assign ConfigBits[436] = Emulate_Bitstream[158];
assign ConfigBits[435] = Emulate_Bitstream[157];
assign ConfigBits[434] = Emulate_Bitstream[156];
assign ConfigBits[433] = Emulate_Bitstream[155];
assign ConfigBits[432] = Emulate_Bitstream[154];
assign ConfigBits[431] = Emulate_Bitstream[153];
assign ConfigBits[430] = Emulate_Bitstream[152];
assign ConfigBits[429] = Emulate_Bitstream[151];
assign ConfigBits[428] = Emulate_Bitstream[150];
assign ConfigBits[427] = Emulate_Bitstream[149];
assign ConfigBits[426] = Emulate_Bitstream[148];
assign ConfigBits[425] = Emulate_Bitstream[147];
assign ConfigBits[424] = Emulate_Bitstream[146];
assign ConfigBits[423] = Emulate_Bitstream[145];
assign ConfigBits[422] = Emulate_Bitstream[144];
assign ConfigBits[421] = Emulate_Bitstream[143];
assign ConfigBits[420] = Emulate_Bitstream[142];
assign ConfigBits[419] = Emulate_Bitstream[141];
assign ConfigBits[418] = Emulate_Bitstream[140];
assign ConfigBits[417] = Emulate_Bitstream[139];
assign ConfigBits[416] = Emulate_Bitstream[138];
assign ConfigBits[415] = Emulate_Bitstream[137];
assign ConfigBits[414] = Emulate_Bitstream[136];
assign ConfigBits[413] = Emulate_Bitstream[135];
assign ConfigBits[412] = Emulate_Bitstream[134];
assign ConfigBits[411] = Emulate_Bitstream[133];
assign ConfigBits[410] = Emulate_Bitstream[132];
assign ConfigBits[409] = Emulate_Bitstream[131];
assign ConfigBits[408] = Emulate_Bitstream[130];
assign ConfigBits[407] = Emulate_Bitstream[129];
assign ConfigBits[406] = Emulate_Bitstream[128];
assign ConfigBits[405] = Emulate_Bitstream[191];
assign ConfigBits[404] = Emulate_Bitstream[190];
assign ConfigBits[403] = Emulate_Bitstream[189];
assign ConfigBits[402] = Emulate_Bitstream[188];
assign ConfigBits[401] = Emulate_Bitstream[187];
assign ConfigBits[400] = Emulate_Bitstream[186];
assign ConfigBits[399] = Emulate_Bitstream[185];
assign ConfigBits[398] = Emulate_Bitstream[184];
assign ConfigBits[397] = Emulate_Bitstream[183];
assign ConfigBits[396] = Emulate_Bitstream[182];
assign ConfigBits[395] = Emulate_Bitstream[181];
assign ConfigBits[394] = Emulate_Bitstream[180];
assign ConfigBits[393] = Emulate_Bitstream[179];
assign ConfigBits[392] = Emulate_Bitstream[178];
assign ConfigBits[391] = Emulate_Bitstream[177];
assign ConfigBits[390] = Emulate_Bitstream[176];
assign ConfigBits[389] = Emulate_Bitstream[175];
assign ConfigBits[388] = Emulate_Bitstream[174];
assign ConfigBits[387] = Emulate_Bitstream[173];
assign ConfigBits[386] = Emulate_Bitstream[172];
assign ConfigBits[385] = Emulate_Bitstream[171];
assign ConfigBits[384] = Emulate_Bitstream[170];
assign ConfigBits[383] = Emulate_Bitstream[169];
assign ConfigBits[382] = Emulate_Bitstream[168];
assign ConfigBits[381] = Emulate_Bitstream[167];
assign ConfigBits[380] = Emulate_Bitstream[166];
assign ConfigBits[379] = Emulate_Bitstream[165];
assign ConfigBits[378] = Emulate_Bitstream[164];
assign ConfigBits[377] = Emulate_Bitstream[163];
assign ConfigBits[376] = Emulate_Bitstream[162];
assign ConfigBits[375] = Emulate_Bitstream[161];
assign ConfigBits[374] = Emulate_Bitstream[160];
assign ConfigBits[373] = Emulate_Bitstream[223];
assign ConfigBits[372] = Emulate_Bitstream[222];
assign ConfigBits[371] = Emulate_Bitstream[221];
assign ConfigBits[370] = Emulate_Bitstream[220];
assign ConfigBits[369] = Emulate_Bitstream[219];
assign ConfigBits[368] = Emulate_Bitstream[218];
assign ConfigBits[367] = Emulate_Bitstream[217];
assign ConfigBits[366] = Emulate_Bitstream[216];
assign ConfigBits[365] = Emulate_Bitstream[215];
assign ConfigBits[364] = Emulate_Bitstream[214];
assign ConfigBits[363] = Emulate_Bitstream[213];
assign ConfigBits[362] = Emulate_Bitstream[212];
assign ConfigBits[361] = Emulate_Bitstream[211];
assign ConfigBits[360] = Emulate_Bitstream[210];
assign ConfigBits[359] = Emulate_Bitstream[209];
assign ConfigBits[358] = Emulate_Bitstream[208];
assign ConfigBits[357] = Emulate_Bitstream[207];
assign ConfigBits[356] = Emulate_Bitstream[206];
assign ConfigBits[355] = Emulate_Bitstream[205];
assign ConfigBits[354] = Emulate_Bitstream[204];
assign ConfigBits[353] = Emulate_Bitstream[203];
assign ConfigBits[352] = Emulate_Bitstream[202];
assign ConfigBits[351] = Emulate_Bitstream[201];
assign ConfigBits[350] = Emulate_Bitstream[200];
assign ConfigBits[349] = Emulate_Bitstream[199];
assign ConfigBits[348] = Emulate_Bitstream[198];
assign ConfigBits[347] = Emulate_Bitstream[197];
assign ConfigBits[346] = Emulate_Bitstream[196];
assign ConfigBits[345] = Emulate_Bitstream[195];
assign ConfigBits[344] = Emulate_Bitstream[194];
assign ConfigBits[343] = Emulate_Bitstream[193];
assign ConfigBits[342] = Emulate_Bitstream[192];
assign ConfigBits[341] = Emulate_Bitstream[255];
assign ConfigBits[340] = Emulate_Bitstream[254];
assign ConfigBits[339] = Emulate_Bitstream[253];
assign ConfigBits[338] = Emulate_Bitstream[252];
assign ConfigBits[337] = Emulate_Bitstream[251];
assign ConfigBits[336] = Emulate_Bitstream[250];
assign ConfigBits[335] = Emulate_Bitstream[249];
assign ConfigBits[334] = Emulate_Bitstream[248];
assign ConfigBits[333] = Emulate_Bitstream[247];
assign ConfigBits[332] = Emulate_Bitstream[246];
assign ConfigBits[331] = Emulate_Bitstream[245];
assign ConfigBits[330] = Emulate_Bitstream[244];
assign ConfigBits[329] = Emulate_Bitstream[243];
assign ConfigBits[328] = Emulate_Bitstream[242];
assign ConfigBits[327] = Emulate_Bitstream[241];
assign ConfigBits[326] = Emulate_Bitstream[240];
assign ConfigBits[325] = Emulate_Bitstream[239];
assign ConfigBits[324] = Emulate_Bitstream[238];
assign ConfigBits[323] = Emulate_Bitstream[237];
assign ConfigBits[322] = Emulate_Bitstream[236];
assign ConfigBits[321] = Emulate_Bitstream[235];
assign ConfigBits[320] = Emulate_Bitstream[234];
assign ConfigBits[319] = Emulate_Bitstream[233];
assign ConfigBits[318] = Emulate_Bitstream[232];
assign ConfigBits[317] = Emulate_Bitstream[231];
assign ConfigBits[316] = Emulate_Bitstream[230];
assign ConfigBits[315] = Emulate_Bitstream[229];
assign ConfigBits[314] = Emulate_Bitstream[228];
assign ConfigBits[313] = Emulate_Bitstream[227];
assign ConfigBits[312] = Emulate_Bitstream[226];
assign ConfigBits[311] = Emulate_Bitstream[225];
assign ConfigBits[310] = Emulate_Bitstream[224];
assign ConfigBits[309] = Emulate_Bitstream[287];
assign ConfigBits[308] = Emulate_Bitstream[286];
assign ConfigBits[307] = Emulate_Bitstream[285];
assign ConfigBits[306] = Emulate_Bitstream[284];
assign ConfigBits[305] = Emulate_Bitstream[283];
assign ConfigBits[304] = Emulate_Bitstream[282];
assign ConfigBits[303] = Emulate_Bitstream[281];
assign ConfigBits[302] = Emulate_Bitstream[280];
assign ConfigBits[301] = Emulate_Bitstream[279];
assign ConfigBits[300] = Emulate_Bitstream[278];
assign ConfigBits[299] = Emulate_Bitstream[277];
assign ConfigBits[298] = Emulate_Bitstream[276];
assign ConfigBits[297] = Emulate_Bitstream[275];
assign ConfigBits[296] = Emulate_Bitstream[274];
assign ConfigBits[295] = Emulate_Bitstream[273];
assign ConfigBits[294] = Emulate_Bitstream[272];
assign ConfigBits[293] = Emulate_Bitstream[271];
assign ConfigBits[292] = Emulate_Bitstream[270];
assign ConfigBits[291] = Emulate_Bitstream[269];
assign ConfigBits[290] = Emulate_Bitstream[268];
assign ConfigBits[289] = Emulate_Bitstream[267];
assign ConfigBits[288] = Emulate_Bitstream[266];
assign ConfigBits[287] = Emulate_Bitstream[265];
assign ConfigBits[286] = Emulate_Bitstream[264];
assign ConfigBits[285] = Emulate_Bitstream[263];
assign ConfigBits[284] = Emulate_Bitstream[262];
assign ConfigBits[283] = Emulate_Bitstream[261];
assign ConfigBits[282] = Emulate_Bitstream[260];
assign ConfigBits[281] = Emulate_Bitstream[259];
assign ConfigBits[280] = Emulate_Bitstream[258];
assign ConfigBits[279] = Emulate_Bitstream[257];
assign ConfigBits[278] = Emulate_Bitstream[256];
assign ConfigBits[277] = Emulate_Bitstream[319];
assign ConfigBits[276] = Emulate_Bitstream[318];
assign ConfigBits[275] = Emulate_Bitstream[317];
assign ConfigBits[274] = Emulate_Bitstream[316];
assign ConfigBits[273] = Emulate_Bitstream[315];
assign ConfigBits[272] = Emulate_Bitstream[314];
assign ConfigBits[271] = Emulate_Bitstream[313];
assign ConfigBits[270] = Emulate_Bitstream[312];
assign ConfigBits[269] = Emulate_Bitstream[311];
assign ConfigBits[268] = Emulate_Bitstream[310];
assign ConfigBits[267] = Emulate_Bitstream[309];
assign ConfigBits[266] = Emulate_Bitstream[308];
assign ConfigBits[265] = Emulate_Bitstream[307];
assign ConfigBits[264] = Emulate_Bitstream[306];
assign ConfigBits[263] = Emulate_Bitstream[305];
assign ConfigBits[262] = Emulate_Bitstream[304];
assign ConfigBits[261] = Emulate_Bitstream[303];
assign ConfigBits[260] = Emulate_Bitstream[302];
assign ConfigBits[259] = Emulate_Bitstream[301];
assign ConfigBits[258] = Emulate_Bitstream[300];
assign ConfigBits[257] = Emulate_Bitstream[299];
assign ConfigBits[256] = Emulate_Bitstream[298];
assign ConfigBits[255] = Emulate_Bitstream[297];
assign ConfigBits[254] = Emulate_Bitstream[296];
assign ConfigBits[253] = Emulate_Bitstream[295];
assign ConfigBits[252] = Emulate_Bitstream[294];
assign ConfigBits[251] = Emulate_Bitstream[293];
assign ConfigBits[250] = Emulate_Bitstream[292];
assign ConfigBits[249] = Emulate_Bitstream[291];
assign ConfigBits[248] = Emulate_Bitstream[290];
assign ConfigBits[247] = Emulate_Bitstream[289];
assign ConfigBits[246] = Emulate_Bitstream[288];
assign ConfigBits[245] = Emulate_Bitstream[351];
assign ConfigBits[244] = Emulate_Bitstream[350];
assign ConfigBits[243] = Emulate_Bitstream[349];
assign ConfigBits[242] = Emulate_Bitstream[348];
assign ConfigBits[241] = Emulate_Bitstream[347];
assign ConfigBits[240] = Emulate_Bitstream[346];
assign ConfigBits[239] = Emulate_Bitstream[345];
assign ConfigBits[238] = Emulate_Bitstream[344];
assign ConfigBits[237] = Emulate_Bitstream[343];
assign ConfigBits[236] = Emulate_Bitstream[342];
assign ConfigBits[235] = Emulate_Bitstream[341];
assign ConfigBits[234] = Emulate_Bitstream[340];
assign ConfigBits[233] = Emulate_Bitstream[339];
assign ConfigBits[232] = Emulate_Bitstream[338];
assign ConfigBits[231] = Emulate_Bitstream[337];
assign ConfigBits[230] = Emulate_Bitstream[336];
assign ConfigBits[229] = Emulate_Bitstream[335];
assign ConfigBits[228] = Emulate_Bitstream[334];
assign ConfigBits[227] = Emulate_Bitstream[333];
assign ConfigBits[226] = Emulate_Bitstream[332];
assign ConfigBits[225] = Emulate_Bitstream[331];
assign ConfigBits[224] = Emulate_Bitstream[330];
assign ConfigBits[223] = Emulate_Bitstream[329];
assign ConfigBits[222] = Emulate_Bitstream[328];
assign ConfigBits[221] = Emulate_Bitstream[327];
assign ConfigBits[220] = Emulate_Bitstream[326];
assign ConfigBits[219] = Emulate_Bitstream[325];
assign ConfigBits[218] = Emulate_Bitstream[324];
assign ConfigBits[217] = Emulate_Bitstream[323];
assign ConfigBits[216] = Emulate_Bitstream[322];
assign ConfigBits[215] = Emulate_Bitstream[321];
assign ConfigBits[214] = Emulate_Bitstream[320];
assign ConfigBits[213] = Emulate_Bitstream[383];
assign ConfigBits[212] = Emulate_Bitstream[382];
assign ConfigBits[211] = Emulate_Bitstream[381];
assign ConfigBits[210] = Emulate_Bitstream[380];
assign ConfigBits[209] = Emulate_Bitstream[379];
assign ConfigBits[208] = Emulate_Bitstream[378];
assign ConfigBits[207] = Emulate_Bitstream[377];
assign ConfigBits[206] = Emulate_Bitstream[376];
assign ConfigBits[205] = Emulate_Bitstream[375];
assign ConfigBits[204] = Emulate_Bitstream[374];
assign ConfigBits[203] = Emulate_Bitstream[373];
assign ConfigBits[202] = Emulate_Bitstream[372];
assign ConfigBits[201] = Emulate_Bitstream[371];
assign ConfigBits[200] = Emulate_Bitstream[370];
assign ConfigBits[199] = Emulate_Bitstream[369];
assign ConfigBits[198] = Emulate_Bitstream[368];
assign ConfigBits[197] = Emulate_Bitstream[367];
assign ConfigBits[196] = Emulate_Bitstream[366];
assign ConfigBits[195] = Emulate_Bitstream[365];
assign ConfigBits[194] = Emulate_Bitstream[364];
assign ConfigBits[193] = Emulate_Bitstream[363];
assign ConfigBits[192] = Emulate_Bitstream[362];
assign ConfigBits[191] = Emulate_Bitstream[361];
assign ConfigBits[190] = Emulate_Bitstream[360];
assign ConfigBits[189] = Emulate_Bitstream[359];
assign ConfigBits[188] = Emulate_Bitstream[358];
assign ConfigBits[187] = Emulate_Bitstream[357];
assign ConfigBits[186] = Emulate_Bitstream[356];
assign ConfigBits[185] = Emulate_Bitstream[355];
assign ConfigBits[184] = Emulate_Bitstream[354];
assign ConfigBits[183] = Emulate_Bitstream[353];
assign ConfigBits[182] = Emulate_Bitstream[352];
assign ConfigBits[181] = Emulate_Bitstream[415];
assign ConfigBits[180] = Emulate_Bitstream[414];
assign ConfigBits[179] = Emulate_Bitstream[413];
assign ConfigBits[178] = Emulate_Bitstream[412];
assign ConfigBits[177] = Emulate_Bitstream[411];
assign ConfigBits[176] = Emulate_Bitstream[410];
assign ConfigBits[175] = Emulate_Bitstream[409];
assign ConfigBits[174] = Emulate_Bitstream[408];
assign ConfigBits[173] = Emulate_Bitstream[407];
assign ConfigBits[172] = Emulate_Bitstream[406];
assign ConfigBits[171] = Emulate_Bitstream[405];
assign ConfigBits[170] = Emulate_Bitstream[404];
assign ConfigBits[169] = Emulate_Bitstream[403];
assign ConfigBits[168] = Emulate_Bitstream[402];
assign ConfigBits[167] = Emulate_Bitstream[401];
assign ConfigBits[166] = Emulate_Bitstream[400];
assign ConfigBits[165] = Emulate_Bitstream[399];
assign ConfigBits[164] = Emulate_Bitstream[398];
assign ConfigBits[163] = Emulate_Bitstream[397];
assign ConfigBits[162] = Emulate_Bitstream[396];
assign ConfigBits[161] = Emulate_Bitstream[395];
assign ConfigBits[160] = Emulate_Bitstream[394];
assign ConfigBits[159] = Emulate_Bitstream[393];
assign ConfigBits[158] = Emulate_Bitstream[392];
assign ConfigBits[157] = Emulate_Bitstream[391];
assign ConfigBits[156] = Emulate_Bitstream[390];
assign ConfigBits[155] = Emulate_Bitstream[389];
assign ConfigBits[154] = Emulate_Bitstream[388];
assign ConfigBits[153] = Emulate_Bitstream[387];
assign ConfigBits[152] = Emulate_Bitstream[386];
assign ConfigBits[151] = Emulate_Bitstream[385];
assign ConfigBits[150] = Emulate_Bitstream[384];
assign ConfigBits[149] = Emulate_Bitstream[447];
assign ConfigBits[148] = Emulate_Bitstream[446];
assign ConfigBits[147] = Emulate_Bitstream[445];
assign ConfigBits[146] = Emulate_Bitstream[444];
assign ConfigBits[145] = Emulate_Bitstream[443];
assign ConfigBits[144] = Emulate_Bitstream[442];
assign ConfigBits[143] = Emulate_Bitstream[441];
assign ConfigBits[142] = Emulate_Bitstream[440];
assign ConfigBits[141] = Emulate_Bitstream[439];
assign ConfigBits[140] = Emulate_Bitstream[438];
assign ConfigBits[139] = Emulate_Bitstream[437];
assign ConfigBits[138] = Emulate_Bitstream[436];
assign ConfigBits[137] = Emulate_Bitstream[435];
assign ConfigBits[136] = Emulate_Bitstream[434];
assign ConfigBits[135] = Emulate_Bitstream[433];
assign ConfigBits[134] = Emulate_Bitstream[432];
assign ConfigBits[133] = Emulate_Bitstream[431];
assign ConfigBits[132] = Emulate_Bitstream[430];
assign ConfigBits[131] = Emulate_Bitstream[429];
assign ConfigBits[130] = Emulate_Bitstream[428];
assign ConfigBits[129] = Emulate_Bitstream[427];
assign ConfigBits[128] = Emulate_Bitstream[426];
assign ConfigBits[127] = Emulate_Bitstream[425];
assign ConfigBits[126] = Emulate_Bitstream[424];
assign ConfigBits[125] = Emulate_Bitstream[423];
assign ConfigBits[124] = Emulate_Bitstream[422];
assign ConfigBits[123] = Emulate_Bitstream[421];
assign ConfigBits[122] = Emulate_Bitstream[420];
assign ConfigBits[121] = Emulate_Bitstream[419];
assign ConfigBits[120] = Emulate_Bitstream[418];
assign ConfigBits[119] = Emulate_Bitstream[417];
assign ConfigBits[118] = Emulate_Bitstream[416];
assign ConfigBits[117] = Emulate_Bitstream[479];
assign ConfigBits[116] = Emulate_Bitstream[478];
assign ConfigBits[115] = Emulate_Bitstream[477];
assign ConfigBits[114] = Emulate_Bitstream[476];
assign ConfigBits[113] = Emulate_Bitstream[475];
assign ConfigBits[112] = Emulate_Bitstream[474];
assign ConfigBits[111] = Emulate_Bitstream[473];
assign ConfigBits[110] = Emulate_Bitstream[472];
assign ConfigBits[109] = Emulate_Bitstream[471];
assign ConfigBits[108] = Emulate_Bitstream[470];
assign ConfigBits[107] = Emulate_Bitstream[469];
assign ConfigBits[106] = Emulate_Bitstream[468];
assign ConfigBits[105] = Emulate_Bitstream[467];
assign ConfigBits[104] = Emulate_Bitstream[466];
assign ConfigBits[103] = Emulate_Bitstream[465];
assign ConfigBits[102] = Emulate_Bitstream[464];
assign ConfigBits[101] = Emulate_Bitstream[463];
assign ConfigBits[100] = Emulate_Bitstream[462];
assign ConfigBits[99] = Emulate_Bitstream[461];
assign ConfigBits[98] = Emulate_Bitstream[460];
assign ConfigBits[97] = Emulate_Bitstream[459];
assign ConfigBits[96] = Emulate_Bitstream[458];
assign ConfigBits[95] = Emulate_Bitstream[457];
assign ConfigBits[94] = Emulate_Bitstream[456];
assign ConfigBits[93] = Emulate_Bitstream[455];
assign ConfigBits[92] = Emulate_Bitstream[454];
assign ConfigBits[91] = Emulate_Bitstream[453];
assign ConfigBits[90] = Emulate_Bitstream[452];
assign ConfigBits[89] = Emulate_Bitstream[451];
assign ConfigBits[88] = Emulate_Bitstream[450];
assign ConfigBits[87] = Emulate_Bitstream[449];
assign ConfigBits[86] = Emulate_Bitstream[448];
assign ConfigBits[85] = Emulate_Bitstream[511];
assign ConfigBits[84] = Emulate_Bitstream[510];
assign ConfigBits[83] = Emulate_Bitstream[509];
assign ConfigBits[82] = Emulate_Bitstream[508];
assign ConfigBits[81] = Emulate_Bitstream[507];
assign ConfigBits[80] = Emulate_Bitstream[506];
assign ConfigBits[79] = Emulate_Bitstream[505];
assign ConfigBits[78] = Emulate_Bitstream[504];
assign ConfigBits[77] = Emulate_Bitstream[503];
assign ConfigBits[76] = Emulate_Bitstream[502];
assign ConfigBits[75] = Emulate_Bitstream[501];
assign ConfigBits[74] = Emulate_Bitstream[500];
assign ConfigBits[73] = Emulate_Bitstream[499];
assign ConfigBits[72] = Emulate_Bitstream[498];
assign ConfigBits[71] = Emulate_Bitstream[497];
assign ConfigBits[70] = Emulate_Bitstream[496];
assign ConfigBits[69] = Emulate_Bitstream[495];
assign ConfigBits[68] = Emulate_Bitstream[494];
assign ConfigBits[67] = Emulate_Bitstream[493];
assign ConfigBits[66] = Emulate_Bitstream[492];
assign ConfigBits[65] = Emulate_Bitstream[491];
assign ConfigBits[64] = Emulate_Bitstream[490];
assign ConfigBits[63] = Emulate_Bitstream[489];
assign ConfigBits[62] = Emulate_Bitstream[488];
assign ConfigBits[61] = Emulate_Bitstream[487];
assign ConfigBits[60] = Emulate_Bitstream[486];
assign ConfigBits[59] = Emulate_Bitstream[485];
assign ConfigBits[58] = Emulate_Bitstream[484];
assign ConfigBits[57] = Emulate_Bitstream[483];
assign ConfigBits[56] = Emulate_Bitstream[482];
assign ConfigBits[55] = Emulate_Bitstream[481];
assign ConfigBits[54] = Emulate_Bitstream[480];
assign ConfigBits[53] = Emulate_Bitstream[543];
assign ConfigBits[52] = Emulate_Bitstream[542];
assign ConfigBits[51] = Emulate_Bitstream[541];
assign ConfigBits[50] = Emulate_Bitstream[540];
assign ConfigBits[49] = Emulate_Bitstream[539];
assign ConfigBits[48] = Emulate_Bitstream[538];
assign ConfigBits[47] = Emulate_Bitstream[537];
assign ConfigBits[46] = Emulate_Bitstream[536];
assign ConfigBits[45] = Emulate_Bitstream[535];
assign ConfigBits[44] = Emulate_Bitstream[534];
assign ConfigBits[43] = Emulate_Bitstream[533];
assign ConfigBits[42] = Emulate_Bitstream[532];
assign ConfigBits[41] = Emulate_Bitstream[531];
assign ConfigBits[40] = Emulate_Bitstream[530];
assign ConfigBits[39] = Emulate_Bitstream[529];
assign ConfigBits[38] = Emulate_Bitstream[528];
assign ConfigBits[37] = Emulate_Bitstream[527];
assign ConfigBits[36] = Emulate_Bitstream[526];
assign ConfigBits[35] = Emulate_Bitstream[525];
assign ConfigBits[34] = Emulate_Bitstream[524];
assign ConfigBits[33] = Emulate_Bitstream[523];
assign ConfigBits[32] = Emulate_Bitstream[522];
assign ConfigBits[31] = Emulate_Bitstream[521];
assign ConfigBits[30] = Emulate_Bitstream[520];
assign ConfigBits[29] = Emulate_Bitstream[519];
assign ConfigBits[28] = Emulate_Bitstream[518];
assign ConfigBits[27] = Emulate_Bitstream[517];
assign ConfigBits[26] = Emulate_Bitstream[516];
assign ConfigBits[25] = Emulate_Bitstream[515];
assign ConfigBits[24] = Emulate_Bitstream[514];
assign ConfigBits[23] = Emulate_Bitstream[513];
assign ConfigBits[22] = Emulate_Bitstream[512];
assign ConfigBits[21] = Emulate_Bitstream[575];
assign ConfigBits[20] = Emulate_Bitstream[574];
assign ConfigBits[19] = Emulate_Bitstream[573];
assign ConfigBits[18] = Emulate_Bitstream[572];
assign ConfigBits[17] = Emulate_Bitstream[571];
assign ConfigBits[16] = Emulate_Bitstream[570];
assign ConfigBits[15] = Emulate_Bitstream[569];
assign ConfigBits[14] = Emulate_Bitstream[568];
assign ConfigBits[13] = Emulate_Bitstream[567];
assign ConfigBits[12] = Emulate_Bitstream[566];
assign ConfigBits[11] = Emulate_Bitstream[565];
assign ConfigBits[10] = Emulate_Bitstream[564];
assign ConfigBits[9] = Emulate_Bitstream[563];
assign ConfigBits[8] = Emulate_Bitstream[562];
assign ConfigBits[7] = Emulate_Bitstream[561];
assign ConfigBits[6] = Emulate_Bitstream[560];
assign ConfigBits[5] = Emulate_Bitstream[559];
assign ConfigBits[4] = Emulate_Bitstream[558];
assign ConfigBits[3] = Emulate_Bitstream[557];
assign ConfigBits[2] = Emulate_Bitstream[556];
assign ConfigBits[1] = Emulate_Bitstream[555];
assign ConfigBits[0] = Emulate_Bitstream[554];
`else

 //instantiate frame latches
config_latch Inst_frame0_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[565]),
    .QN(ConfigBits_N[565])
);

config_latch Inst_frame0_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[564]),
    .QN(ConfigBits_N[564])
);

config_latch Inst_frame0_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[563]),
    .QN(ConfigBits_N[563])
);

config_latch Inst_frame0_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[562]),
    .QN(ConfigBits_N[562])
);

config_latch Inst_frame0_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[561]),
    .QN(ConfigBits_N[561])
);

config_latch Inst_frame0_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[560]),
    .QN(ConfigBits_N[560])
);

config_latch Inst_frame0_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[559]),
    .QN(ConfigBits_N[559])
);

config_latch Inst_frame0_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[558]),
    .QN(ConfigBits_N[558])
);

config_latch Inst_frame0_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[557]),
    .QN(ConfigBits_N[557])
);

config_latch Inst_frame0_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[556]),
    .QN(ConfigBits_N[556])
);

config_latch Inst_frame0_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[555]),
    .QN(ConfigBits_N[555])
);

config_latch Inst_frame0_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[554]),
    .QN(ConfigBits_N[554])
);

config_latch Inst_frame0_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[553]),
    .QN(ConfigBits_N[553])
);

config_latch Inst_frame0_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[552]),
    .QN(ConfigBits_N[552])
);

config_latch Inst_frame0_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[551]),
    .QN(ConfigBits_N[551])
);

config_latch Inst_frame0_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[550]),
    .QN(ConfigBits_N[550])
);

config_latch Inst_frame0_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[549]),
    .QN(ConfigBits_N[549])
);

config_latch Inst_frame0_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[548]),
    .QN(ConfigBits_N[548])
);

config_latch Inst_frame0_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[547]),
    .QN(ConfigBits_N[547])
);

config_latch Inst_frame0_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[546]),
    .QN(ConfigBits_N[546])
);

config_latch Inst_frame0_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[545]),
    .QN(ConfigBits_N[545])
);

config_latch Inst_frame0_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[544]),
    .QN(ConfigBits_N[544])
);

config_latch Inst_frame0_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[543]),
    .QN(ConfigBits_N[543])
);

config_latch Inst_frame0_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[542]),
    .QN(ConfigBits_N[542])
);

config_latch Inst_frame0_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[541]),
    .QN(ConfigBits_N[541])
);

config_latch Inst_frame0_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[540]),
    .QN(ConfigBits_N[540])
);

config_latch Inst_frame0_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[539]),
    .QN(ConfigBits_N[539])
);

config_latch Inst_frame0_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[538]),
    .QN(ConfigBits_N[538])
);

config_latch Inst_frame0_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[537]),
    .QN(ConfigBits_N[537])
);

config_latch Inst_frame0_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[536]),
    .QN(ConfigBits_N[536])
);

config_latch Inst_frame0_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[535]),
    .QN(ConfigBits_N[535])
);

config_latch Inst_frame0_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[534]),
    .QN(ConfigBits_N[534])
);

config_latch Inst_frame1_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[533]),
    .QN(ConfigBits_N[533])
);

config_latch Inst_frame1_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[532]),
    .QN(ConfigBits_N[532])
);

config_latch Inst_frame1_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[531]),
    .QN(ConfigBits_N[531])
);

config_latch Inst_frame1_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[530]),
    .QN(ConfigBits_N[530])
);

config_latch Inst_frame1_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[529]),
    .QN(ConfigBits_N[529])
);

config_latch Inst_frame1_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[528]),
    .QN(ConfigBits_N[528])
);

config_latch Inst_frame1_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[527]),
    .QN(ConfigBits_N[527])
);

config_latch Inst_frame1_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[526]),
    .QN(ConfigBits_N[526])
);

config_latch Inst_frame1_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[525]),
    .QN(ConfigBits_N[525])
);

config_latch Inst_frame1_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[524]),
    .QN(ConfigBits_N[524])
);

config_latch Inst_frame1_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[523]),
    .QN(ConfigBits_N[523])
);

config_latch Inst_frame1_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[522]),
    .QN(ConfigBits_N[522])
);

config_latch Inst_frame1_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[521]),
    .QN(ConfigBits_N[521])
);

config_latch Inst_frame1_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[520]),
    .QN(ConfigBits_N[520])
);

config_latch Inst_frame1_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[519]),
    .QN(ConfigBits_N[519])
);

config_latch Inst_frame1_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[518]),
    .QN(ConfigBits_N[518])
);

config_latch Inst_frame1_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[517]),
    .QN(ConfigBits_N[517])
);

config_latch Inst_frame1_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[516]),
    .QN(ConfigBits_N[516])
);

config_latch Inst_frame1_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[515]),
    .QN(ConfigBits_N[515])
);

config_latch Inst_frame1_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[514]),
    .QN(ConfigBits_N[514])
);

config_latch Inst_frame1_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[513]),
    .QN(ConfigBits_N[513])
);

config_latch Inst_frame1_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[512]),
    .QN(ConfigBits_N[512])
);

config_latch Inst_frame1_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[511]),
    .QN(ConfigBits_N[511])
);

config_latch Inst_frame1_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[510]),
    .QN(ConfigBits_N[510])
);

config_latch Inst_frame1_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[509]),
    .QN(ConfigBits_N[509])
);

config_latch Inst_frame1_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[508]),
    .QN(ConfigBits_N[508])
);

config_latch Inst_frame1_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[507]),
    .QN(ConfigBits_N[507])
);

config_latch Inst_frame1_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[506]),
    .QN(ConfigBits_N[506])
);

config_latch Inst_frame1_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[505]),
    .QN(ConfigBits_N[505])
);

config_latch Inst_frame1_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[504]),
    .QN(ConfigBits_N[504])
);

config_latch Inst_frame1_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[503]),
    .QN(ConfigBits_N[503])
);

config_latch Inst_frame1_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[502]),
    .QN(ConfigBits_N[502])
);

config_latch Inst_frame2_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[501]),
    .QN(ConfigBits_N[501])
);

config_latch Inst_frame2_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[500]),
    .QN(ConfigBits_N[500])
);

config_latch Inst_frame2_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[499]),
    .QN(ConfigBits_N[499])
);

config_latch Inst_frame2_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[498]),
    .QN(ConfigBits_N[498])
);

config_latch Inst_frame2_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[497]),
    .QN(ConfigBits_N[497])
);

config_latch Inst_frame2_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[496]),
    .QN(ConfigBits_N[496])
);

config_latch Inst_frame2_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[495]),
    .QN(ConfigBits_N[495])
);

config_latch Inst_frame2_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[494]),
    .QN(ConfigBits_N[494])
);

config_latch Inst_frame2_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[493]),
    .QN(ConfigBits_N[493])
);

config_latch Inst_frame2_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[492]),
    .QN(ConfigBits_N[492])
);

config_latch Inst_frame2_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[491]),
    .QN(ConfigBits_N[491])
);

config_latch Inst_frame2_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[490]),
    .QN(ConfigBits_N[490])
);

config_latch Inst_frame2_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[489]),
    .QN(ConfigBits_N[489])
);

config_latch Inst_frame2_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[488]),
    .QN(ConfigBits_N[488])
);

config_latch Inst_frame2_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[487]),
    .QN(ConfigBits_N[487])
);

config_latch Inst_frame2_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[486]),
    .QN(ConfigBits_N[486])
);

config_latch Inst_frame2_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[485]),
    .QN(ConfigBits_N[485])
);

config_latch Inst_frame2_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[484]),
    .QN(ConfigBits_N[484])
);

config_latch Inst_frame2_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[483]),
    .QN(ConfigBits_N[483])
);

config_latch Inst_frame2_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[482]),
    .QN(ConfigBits_N[482])
);

config_latch Inst_frame2_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[481]),
    .QN(ConfigBits_N[481])
);

config_latch Inst_frame2_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[480]),
    .QN(ConfigBits_N[480])
);

config_latch Inst_frame2_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[479]),
    .QN(ConfigBits_N[479])
);

config_latch Inst_frame2_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[478]),
    .QN(ConfigBits_N[478])
);

config_latch Inst_frame2_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[477]),
    .QN(ConfigBits_N[477])
);

config_latch Inst_frame2_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[476]),
    .QN(ConfigBits_N[476])
);

config_latch Inst_frame2_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[475]),
    .QN(ConfigBits_N[475])
);

config_latch Inst_frame2_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[474]),
    .QN(ConfigBits_N[474])
);

config_latch Inst_frame2_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[473]),
    .QN(ConfigBits_N[473])
);

config_latch Inst_frame2_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[472]),
    .QN(ConfigBits_N[472])
);

config_latch Inst_frame2_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[471]),
    .QN(ConfigBits_N[471])
);

config_latch Inst_frame2_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[470]),
    .QN(ConfigBits_N[470])
);

config_latch Inst_frame3_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[469]),
    .QN(ConfigBits_N[469])
);

config_latch Inst_frame3_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[468]),
    .QN(ConfigBits_N[468])
);

config_latch Inst_frame3_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[467]),
    .QN(ConfigBits_N[467])
);

config_latch Inst_frame3_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[466]),
    .QN(ConfigBits_N[466])
);

config_latch Inst_frame3_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[465]),
    .QN(ConfigBits_N[465])
);

config_latch Inst_frame3_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[464]),
    .QN(ConfigBits_N[464])
);

config_latch Inst_frame3_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[463]),
    .QN(ConfigBits_N[463])
);

config_latch Inst_frame3_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[462]),
    .QN(ConfigBits_N[462])
);

config_latch Inst_frame3_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[461]),
    .QN(ConfigBits_N[461])
);

config_latch Inst_frame3_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[460]),
    .QN(ConfigBits_N[460])
);

config_latch Inst_frame3_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[459]),
    .QN(ConfigBits_N[459])
);

config_latch Inst_frame3_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[458]),
    .QN(ConfigBits_N[458])
);

config_latch Inst_frame3_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[457]),
    .QN(ConfigBits_N[457])
);

config_latch Inst_frame3_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[456]),
    .QN(ConfigBits_N[456])
);

config_latch Inst_frame3_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[455]),
    .QN(ConfigBits_N[455])
);

config_latch Inst_frame3_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[454]),
    .QN(ConfigBits_N[454])
);

config_latch Inst_frame3_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[453]),
    .QN(ConfigBits_N[453])
);

config_latch Inst_frame3_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[452]),
    .QN(ConfigBits_N[452])
);

config_latch Inst_frame3_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[451]),
    .QN(ConfigBits_N[451])
);

config_latch Inst_frame3_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[450]),
    .QN(ConfigBits_N[450])
);

config_latch Inst_frame3_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[449]),
    .QN(ConfigBits_N[449])
);

config_latch Inst_frame3_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[448]),
    .QN(ConfigBits_N[448])
);

config_latch Inst_frame3_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[447]),
    .QN(ConfigBits_N[447])
);

config_latch Inst_frame3_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[446]),
    .QN(ConfigBits_N[446])
);

config_latch Inst_frame3_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[445]),
    .QN(ConfigBits_N[445])
);

config_latch Inst_frame3_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[444]),
    .QN(ConfigBits_N[444])
);

config_latch Inst_frame3_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[443]),
    .QN(ConfigBits_N[443])
);

config_latch Inst_frame3_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[442]),
    .QN(ConfigBits_N[442])
);

config_latch Inst_frame3_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[441]),
    .QN(ConfigBits_N[441])
);

config_latch Inst_frame3_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[440]),
    .QN(ConfigBits_N[440])
);

config_latch Inst_frame3_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[439]),
    .QN(ConfigBits_N[439])
);

config_latch Inst_frame3_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[438]),
    .QN(ConfigBits_N[438])
);

config_latch Inst_frame4_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[437]),
    .QN(ConfigBits_N[437])
);

config_latch Inst_frame4_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[436]),
    .QN(ConfigBits_N[436])
);

config_latch Inst_frame4_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[435]),
    .QN(ConfigBits_N[435])
);

config_latch Inst_frame4_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[434]),
    .QN(ConfigBits_N[434])
);

config_latch Inst_frame4_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[433]),
    .QN(ConfigBits_N[433])
);

config_latch Inst_frame4_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[432]),
    .QN(ConfigBits_N[432])
);

config_latch Inst_frame4_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[431]),
    .QN(ConfigBits_N[431])
);

config_latch Inst_frame4_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[430]),
    .QN(ConfigBits_N[430])
);

config_latch Inst_frame4_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[429]),
    .QN(ConfigBits_N[429])
);

config_latch Inst_frame4_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[428]),
    .QN(ConfigBits_N[428])
);

config_latch Inst_frame4_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[427]),
    .QN(ConfigBits_N[427])
);

config_latch Inst_frame4_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[426]),
    .QN(ConfigBits_N[426])
);

config_latch Inst_frame4_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[425]),
    .QN(ConfigBits_N[425])
);

config_latch Inst_frame4_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[424]),
    .QN(ConfigBits_N[424])
);

config_latch Inst_frame4_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[423]),
    .QN(ConfigBits_N[423])
);

config_latch Inst_frame4_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[422]),
    .QN(ConfigBits_N[422])
);

config_latch Inst_frame4_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[421]),
    .QN(ConfigBits_N[421])
);

config_latch Inst_frame4_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[420]),
    .QN(ConfigBits_N[420])
);

config_latch Inst_frame4_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[419]),
    .QN(ConfigBits_N[419])
);

config_latch Inst_frame4_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[418]),
    .QN(ConfigBits_N[418])
);

config_latch Inst_frame4_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[417]),
    .QN(ConfigBits_N[417])
);

config_latch Inst_frame4_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[416]),
    .QN(ConfigBits_N[416])
);

config_latch Inst_frame4_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[415]),
    .QN(ConfigBits_N[415])
);

config_latch Inst_frame4_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[414]),
    .QN(ConfigBits_N[414])
);

config_latch Inst_frame4_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[413]),
    .QN(ConfigBits_N[413])
);

config_latch Inst_frame4_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[412]),
    .QN(ConfigBits_N[412])
);

config_latch Inst_frame4_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[411]),
    .QN(ConfigBits_N[411])
);

config_latch Inst_frame4_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[410]),
    .QN(ConfigBits_N[410])
);

config_latch Inst_frame4_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[409]),
    .QN(ConfigBits_N[409])
);

config_latch Inst_frame4_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[408]),
    .QN(ConfigBits_N[408])
);

config_latch Inst_frame4_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[407]),
    .QN(ConfigBits_N[407])
);

config_latch Inst_frame4_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[4]),
    .Q(ConfigBits[406]),
    .QN(ConfigBits_N[406])
);

config_latch Inst_frame5_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[405]),
    .QN(ConfigBits_N[405])
);

config_latch Inst_frame5_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[404]),
    .QN(ConfigBits_N[404])
);

config_latch Inst_frame5_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[403]),
    .QN(ConfigBits_N[403])
);

config_latch Inst_frame5_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[402]),
    .QN(ConfigBits_N[402])
);

config_latch Inst_frame5_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[401]),
    .QN(ConfigBits_N[401])
);

config_latch Inst_frame5_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[400]),
    .QN(ConfigBits_N[400])
);

config_latch Inst_frame5_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[399]),
    .QN(ConfigBits_N[399])
);

config_latch Inst_frame5_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[398]),
    .QN(ConfigBits_N[398])
);

config_latch Inst_frame5_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[397]),
    .QN(ConfigBits_N[397])
);

config_latch Inst_frame5_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[396]),
    .QN(ConfigBits_N[396])
);

config_latch Inst_frame5_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[395]),
    .QN(ConfigBits_N[395])
);

config_latch Inst_frame5_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[394]),
    .QN(ConfigBits_N[394])
);

config_latch Inst_frame5_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[393]),
    .QN(ConfigBits_N[393])
);

config_latch Inst_frame5_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[392]),
    .QN(ConfigBits_N[392])
);

config_latch Inst_frame5_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[391]),
    .QN(ConfigBits_N[391])
);

config_latch Inst_frame5_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[390]),
    .QN(ConfigBits_N[390])
);

config_latch Inst_frame5_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[389]),
    .QN(ConfigBits_N[389])
);

config_latch Inst_frame5_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[388]),
    .QN(ConfigBits_N[388])
);

config_latch Inst_frame5_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[387]),
    .QN(ConfigBits_N[387])
);

config_latch Inst_frame5_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[386]),
    .QN(ConfigBits_N[386])
);

config_latch Inst_frame5_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[385]),
    .QN(ConfigBits_N[385])
);

config_latch Inst_frame5_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[384]),
    .QN(ConfigBits_N[384])
);

config_latch Inst_frame5_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[383]),
    .QN(ConfigBits_N[383])
);

config_latch Inst_frame5_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[382]),
    .QN(ConfigBits_N[382])
);

config_latch Inst_frame5_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[381]),
    .QN(ConfigBits_N[381])
);

config_latch Inst_frame5_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[380]),
    .QN(ConfigBits_N[380])
);

config_latch Inst_frame5_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[379]),
    .QN(ConfigBits_N[379])
);

config_latch Inst_frame5_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[378]),
    .QN(ConfigBits_N[378])
);

config_latch Inst_frame5_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[377]),
    .QN(ConfigBits_N[377])
);

config_latch Inst_frame5_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[376]),
    .QN(ConfigBits_N[376])
);

config_latch Inst_frame5_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[375]),
    .QN(ConfigBits_N[375])
);

config_latch Inst_frame5_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[5]),
    .Q(ConfigBits[374]),
    .QN(ConfigBits_N[374])
);

config_latch Inst_frame6_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[373]),
    .QN(ConfigBits_N[373])
);

config_latch Inst_frame6_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[372]),
    .QN(ConfigBits_N[372])
);

config_latch Inst_frame6_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[371]),
    .QN(ConfigBits_N[371])
);

config_latch Inst_frame6_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[370]),
    .QN(ConfigBits_N[370])
);

config_latch Inst_frame6_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[369]),
    .QN(ConfigBits_N[369])
);

config_latch Inst_frame6_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[368]),
    .QN(ConfigBits_N[368])
);

config_latch Inst_frame6_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[367]),
    .QN(ConfigBits_N[367])
);

config_latch Inst_frame6_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[366]),
    .QN(ConfigBits_N[366])
);

config_latch Inst_frame6_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[365]),
    .QN(ConfigBits_N[365])
);

config_latch Inst_frame6_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[364]),
    .QN(ConfigBits_N[364])
);

config_latch Inst_frame6_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[363]),
    .QN(ConfigBits_N[363])
);

config_latch Inst_frame6_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[362]),
    .QN(ConfigBits_N[362])
);

config_latch Inst_frame6_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[361]),
    .QN(ConfigBits_N[361])
);

config_latch Inst_frame6_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[360]),
    .QN(ConfigBits_N[360])
);

config_latch Inst_frame6_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[359]),
    .QN(ConfigBits_N[359])
);

config_latch Inst_frame6_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[358]),
    .QN(ConfigBits_N[358])
);

config_latch Inst_frame6_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[357]),
    .QN(ConfigBits_N[357])
);

config_latch Inst_frame6_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[356]),
    .QN(ConfigBits_N[356])
);

config_latch Inst_frame6_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[355]),
    .QN(ConfigBits_N[355])
);

config_latch Inst_frame6_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[354]),
    .QN(ConfigBits_N[354])
);

config_latch Inst_frame6_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[353]),
    .QN(ConfigBits_N[353])
);

config_latch Inst_frame6_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[352]),
    .QN(ConfigBits_N[352])
);

config_latch Inst_frame6_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[351]),
    .QN(ConfigBits_N[351])
);

config_latch Inst_frame6_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[350]),
    .QN(ConfigBits_N[350])
);

config_latch Inst_frame6_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[349]),
    .QN(ConfigBits_N[349])
);

config_latch Inst_frame6_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[348]),
    .QN(ConfigBits_N[348])
);

config_latch Inst_frame6_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[347]),
    .QN(ConfigBits_N[347])
);

config_latch Inst_frame6_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[346]),
    .QN(ConfigBits_N[346])
);

config_latch Inst_frame6_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[345]),
    .QN(ConfigBits_N[345])
);

config_latch Inst_frame6_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[344]),
    .QN(ConfigBits_N[344])
);

config_latch Inst_frame6_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[343]),
    .QN(ConfigBits_N[343])
);

config_latch Inst_frame6_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[6]),
    .Q(ConfigBits[342]),
    .QN(ConfigBits_N[342])
);

config_latch Inst_frame7_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[341]),
    .QN(ConfigBits_N[341])
);

config_latch Inst_frame7_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[340]),
    .QN(ConfigBits_N[340])
);

config_latch Inst_frame7_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[339]),
    .QN(ConfigBits_N[339])
);

config_latch Inst_frame7_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[338]),
    .QN(ConfigBits_N[338])
);

config_latch Inst_frame7_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[337]),
    .QN(ConfigBits_N[337])
);

config_latch Inst_frame7_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[336]),
    .QN(ConfigBits_N[336])
);

config_latch Inst_frame7_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[335]),
    .QN(ConfigBits_N[335])
);

config_latch Inst_frame7_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[334]),
    .QN(ConfigBits_N[334])
);

config_latch Inst_frame7_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[333]),
    .QN(ConfigBits_N[333])
);

config_latch Inst_frame7_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[332]),
    .QN(ConfigBits_N[332])
);

config_latch Inst_frame7_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[331]),
    .QN(ConfigBits_N[331])
);

config_latch Inst_frame7_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[330]),
    .QN(ConfigBits_N[330])
);

config_latch Inst_frame7_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[329]),
    .QN(ConfigBits_N[329])
);

config_latch Inst_frame7_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[328]),
    .QN(ConfigBits_N[328])
);

config_latch Inst_frame7_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[327]),
    .QN(ConfigBits_N[327])
);

config_latch Inst_frame7_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[326]),
    .QN(ConfigBits_N[326])
);

config_latch Inst_frame7_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[325]),
    .QN(ConfigBits_N[325])
);

config_latch Inst_frame7_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[324]),
    .QN(ConfigBits_N[324])
);

config_latch Inst_frame7_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[323]),
    .QN(ConfigBits_N[323])
);

config_latch Inst_frame7_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[322]),
    .QN(ConfigBits_N[322])
);

config_latch Inst_frame7_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[321]),
    .QN(ConfigBits_N[321])
);

config_latch Inst_frame7_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[320]),
    .QN(ConfigBits_N[320])
);

config_latch Inst_frame7_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[319]),
    .QN(ConfigBits_N[319])
);

config_latch Inst_frame7_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[318]),
    .QN(ConfigBits_N[318])
);

config_latch Inst_frame7_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[317]),
    .QN(ConfigBits_N[317])
);

config_latch Inst_frame7_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[316]),
    .QN(ConfigBits_N[316])
);

config_latch Inst_frame7_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[315]),
    .QN(ConfigBits_N[315])
);

config_latch Inst_frame7_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[314]),
    .QN(ConfigBits_N[314])
);

config_latch Inst_frame7_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[313]),
    .QN(ConfigBits_N[313])
);

config_latch Inst_frame7_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[312]),
    .QN(ConfigBits_N[312])
);

config_latch Inst_frame7_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[311]),
    .QN(ConfigBits_N[311])
);

config_latch Inst_frame7_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[7]),
    .Q(ConfigBits[310]),
    .QN(ConfigBits_N[310])
);

config_latch Inst_frame8_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[309]),
    .QN(ConfigBits_N[309])
);

config_latch Inst_frame8_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[308]),
    .QN(ConfigBits_N[308])
);

config_latch Inst_frame8_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[307]),
    .QN(ConfigBits_N[307])
);

config_latch Inst_frame8_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[306]),
    .QN(ConfigBits_N[306])
);

config_latch Inst_frame8_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[305]),
    .QN(ConfigBits_N[305])
);

config_latch Inst_frame8_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[304]),
    .QN(ConfigBits_N[304])
);

config_latch Inst_frame8_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[303]),
    .QN(ConfigBits_N[303])
);

config_latch Inst_frame8_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[302]),
    .QN(ConfigBits_N[302])
);

config_latch Inst_frame8_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[301]),
    .QN(ConfigBits_N[301])
);

config_latch Inst_frame8_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[300]),
    .QN(ConfigBits_N[300])
);

config_latch Inst_frame8_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[299]),
    .QN(ConfigBits_N[299])
);

config_latch Inst_frame8_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[298]),
    .QN(ConfigBits_N[298])
);

config_latch Inst_frame8_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[297]),
    .QN(ConfigBits_N[297])
);

config_latch Inst_frame8_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[296]),
    .QN(ConfigBits_N[296])
);

config_latch Inst_frame8_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[295]),
    .QN(ConfigBits_N[295])
);

config_latch Inst_frame8_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[294]),
    .QN(ConfigBits_N[294])
);

config_latch Inst_frame8_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[293]),
    .QN(ConfigBits_N[293])
);

config_latch Inst_frame8_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[292]),
    .QN(ConfigBits_N[292])
);

config_latch Inst_frame8_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[291]),
    .QN(ConfigBits_N[291])
);

config_latch Inst_frame8_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[290]),
    .QN(ConfigBits_N[290])
);

config_latch Inst_frame8_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[289]),
    .QN(ConfigBits_N[289])
);

config_latch Inst_frame8_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[288]),
    .QN(ConfigBits_N[288])
);

config_latch Inst_frame8_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[287]),
    .QN(ConfigBits_N[287])
);

config_latch Inst_frame8_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[286]),
    .QN(ConfigBits_N[286])
);

config_latch Inst_frame8_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[285]),
    .QN(ConfigBits_N[285])
);

config_latch Inst_frame8_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[284]),
    .QN(ConfigBits_N[284])
);

config_latch Inst_frame8_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[283]),
    .QN(ConfigBits_N[283])
);

config_latch Inst_frame8_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[282]),
    .QN(ConfigBits_N[282])
);

config_latch Inst_frame8_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[281]),
    .QN(ConfigBits_N[281])
);

config_latch Inst_frame8_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[280]),
    .QN(ConfigBits_N[280])
);

config_latch Inst_frame8_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[279]),
    .QN(ConfigBits_N[279])
);

config_latch Inst_frame8_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[8]),
    .Q(ConfigBits[278]),
    .QN(ConfigBits_N[278])
);

config_latch Inst_frame9_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[277]),
    .QN(ConfigBits_N[277])
);

config_latch Inst_frame9_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[276]),
    .QN(ConfigBits_N[276])
);

config_latch Inst_frame9_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[275]),
    .QN(ConfigBits_N[275])
);

config_latch Inst_frame9_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[274]),
    .QN(ConfigBits_N[274])
);

config_latch Inst_frame9_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[273]),
    .QN(ConfigBits_N[273])
);

config_latch Inst_frame9_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[272]),
    .QN(ConfigBits_N[272])
);

config_latch Inst_frame9_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[271]),
    .QN(ConfigBits_N[271])
);

config_latch Inst_frame9_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[270]),
    .QN(ConfigBits_N[270])
);

config_latch Inst_frame9_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[269]),
    .QN(ConfigBits_N[269])
);

config_latch Inst_frame9_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[268]),
    .QN(ConfigBits_N[268])
);

config_latch Inst_frame9_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[267]),
    .QN(ConfigBits_N[267])
);

config_latch Inst_frame9_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[266]),
    .QN(ConfigBits_N[266])
);

config_latch Inst_frame9_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[265]),
    .QN(ConfigBits_N[265])
);

config_latch Inst_frame9_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[264]),
    .QN(ConfigBits_N[264])
);

config_latch Inst_frame9_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[263]),
    .QN(ConfigBits_N[263])
);

config_latch Inst_frame9_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[262]),
    .QN(ConfigBits_N[262])
);

config_latch Inst_frame9_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[261]),
    .QN(ConfigBits_N[261])
);

config_latch Inst_frame9_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[260]),
    .QN(ConfigBits_N[260])
);

config_latch Inst_frame9_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[259]),
    .QN(ConfigBits_N[259])
);

config_latch Inst_frame9_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[258]),
    .QN(ConfigBits_N[258])
);

config_latch Inst_frame9_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[257]),
    .QN(ConfigBits_N[257])
);

config_latch Inst_frame9_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[256]),
    .QN(ConfigBits_N[256])
);

config_latch Inst_frame9_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[255]),
    .QN(ConfigBits_N[255])
);

config_latch Inst_frame9_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[254]),
    .QN(ConfigBits_N[254])
);

config_latch Inst_frame9_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[253]),
    .QN(ConfigBits_N[253])
);

config_latch Inst_frame9_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[252]),
    .QN(ConfigBits_N[252])
);

config_latch Inst_frame9_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[251]),
    .QN(ConfigBits_N[251])
);

config_latch Inst_frame9_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[250]),
    .QN(ConfigBits_N[250])
);

config_latch Inst_frame9_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[249]),
    .QN(ConfigBits_N[249])
);

config_latch Inst_frame9_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[248]),
    .QN(ConfigBits_N[248])
);

config_latch Inst_frame9_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[247]),
    .QN(ConfigBits_N[247])
);

config_latch Inst_frame9_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[9]),
    .Q(ConfigBits[246]),
    .QN(ConfigBits_N[246])
);

config_latch Inst_frame10_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[245]),
    .QN(ConfigBits_N[245])
);

config_latch Inst_frame10_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[244]),
    .QN(ConfigBits_N[244])
);

config_latch Inst_frame10_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[243]),
    .QN(ConfigBits_N[243])
);

config_latch Inst_frame10_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[242]),
    .QN(ConfigBits_N[242])
);

config_latch Inst_frame10_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[241]),
    .QN(ConfigBits_N[241])
);

config_latch Inst_frame10_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[240]),
    .QN(ConfigBits_N[240])
);

config_latch Inst_frame10_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[239]),
    .QN(ConfigBits_N[239])
);

config_latch Inst_frame10_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[238]),
    .QN(ConfigBits_N[238])
);

config_latch Inst_frame10_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[237]),
    .QN(ConfigBits_N[237])
);

config_latch Inst_frame10_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[236]),
    .QN(ConfigBits_N[236])
);

config_latch Inst_frame10_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[235]),
    .QN(ConfigBits_N[235])
);

config_latch Inst_frame10_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[234]),
    .QN(ConfigBits_N[234])
);

config_latch Inst_frame10_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[233]),
    .QN(ConfigBits_N[233])
);

config_latch Inst_frame10_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[232]),
    .QN(ConfigBits_N[232])
);

config_latch Inst_frame10_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[231]),
    .QN(ConfigBits_N[231])
);

config_latch Inst_frame10_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[230]),
    .QN(ConfigBits_N[230])
);

config_latch Inst_frame10_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[229]),
    .QN(ConfigBits_N[229])
);

config_latch Inst_frame10_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[228]),
    .QN(ConfigBits_N[228])
);

config_latch Inst_frame10_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[227]),
    .QN(ConfigBits_N[227])
);

config_latch Inst_frame10_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[226]),
    .QN(ConfigBits_N[226])
);

config_latch Inst_frame10_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[225]),
    .QN(ConfigBits_N[225])
);

config_latch Inst_frame10_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[224]),
    .QN(ConfigBits_N[224])
);

config_latch Inst_frame10_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[223]),
    .QN(ConfigBits_N[223])
);

config_latch Inst_frame10_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[222]),
    .QN(ConfigBits_N[222])
);

config_latch Inst_frame10_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[221]),
    .QN(ConfigBits_N[221])
);

config_latch Inst_frame10_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[220]),
    .QN(ConfigBits_N[220])
);

config_latch Inst_frame10_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[219]),
    .QN(ConfigBits_N[219])
);

config_latch Inst_frame10_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[218]),
    .QN(ConfigBits_N[218])
);

config_latch Inst_frame10_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[217]),
    .QN(ConfigBits_N[217])
);

config_latch Inst_frame10_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[216]),
    .QN(ConfigBits_N[216])
);

config_latch Inst_frame10_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[215]),
    .QN(ConfigBits_N[215])
);

config_latch Inst_frame10_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[10]),
    .Q(ConfigBits[214]),
    .QN(ConfigBits_N[214])
);

config_latch Inst_frame11_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[213]),
    .QN(ConfigBits_N[213])
);

config_latch Inst_frame11_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[212]),
    .QN(ConfigBits_N[212])
);

config_latch Inst_frame11_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[211]),
    .QN(ConfigBits_N[211])
);

config_latch Inst_frame11_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[210]),
    .QN(ConfigBits_N[210])
);

config_latch Inst_frame11_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[209]),
    .QN(ConfigBits_N[209])
);

config_latch Inst_frame11_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[208]),
    .QN(ConfigBits_N[208])
);

config_latch Inst_frame11_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[207]),
    .QN(ConfigBits_N[207])
);

config_latch Inst_frame11_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[206]),
    .QN(ConfigBits_N[206])
);

config_latch Inst_frame11_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[205]),
    .QN(ConfigBits_N[205])
);

config_latch Inst_frame11_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[204]),
    .QN(ConfigBits_N[204])
);

config_latch Inst_frame11_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[203]),
    .QN(ConfigBits_N[203])
);

config_latch Inst_frame11_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[202]),
    .QN(ConfigBits_N[202])
);

config_latch Inst_frame11_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[201]),
    .QN(ConfigBits_N[201])
);

config_latch Inst_frame11_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[200]),
    .QN(ConfigBits_N[200])
);

config_latch Inst_frame11_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[199]),
    .QN(ConfigBits_N[199])
);

config_latch Inst_frame11_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[198]),
    .QN(ConfigBits_N[198])
);

config_latch Inst_frame11_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[197]),
    .QN(ConfigBits_N[197])
);

config_latch Inst_frame11_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[196]),
    .QN(ConfigBits_N[196])
);

config_latch Inst_frame11_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[195]),
    .QN(ConfigBits_N[195])
);

config_latch Inst_frame11_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[194]),
    .QN(ConfigBits_N[194])
);

config_latch Inst_frame11_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[193]),
    .QN(ConfigBits_N[193])
);

config_latch Inst_frame11_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[192]),
    .QN(ConfigBits_N[192])
);

config_latch Inst_frame11_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[191]),
    .QN(ConfigBits_N[191])
);

config_latch Inst_frame11_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[190]),
    .QN(ConfigBits_N[190])
);

config_latch Inst_frame11_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[189]),
    .QN(ConfigBits_N[189])
);

config_latch Inst_frame11_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[188]),
    .QN(ConfigBits_N[188])
);

config_latch Inst_frame11_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[187]),
    .QN(ConfigBits_N[187])
);

config_latch Inst_frame11_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[186]),
    .QN(ConfigBits_N[186])
);

config_latch Inst_frame11_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[185]),
    .QN(ConfigBits_N[185])
);

config_latch Inst_frame11_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[184]),
    .QN(ConfigBits_N[184])
);

config_latch Inst_frame11_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[183]),
    .QN(ConfigBits_N[183])
);

config_latch Inst_frame11_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[11]),
    .Q(ConfigBits[182]),
    .QN(ConfigBits_N[182])
);

config_latch Inst_frame12_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[181]),
    .QN(ConfigBits_N[181])
);

config_latch Inst_frame12_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[180]),
    .QN(ConfigBits_N[180])
);

config_latch Inst_frame12_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[179]),
    .QN(ConfigBits_N[179])
);

config_latch Inst_frame12_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[178]),
    .QN(ConfigBits_N[178])
);

config_latch Inst_frame12_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[177]),
    .QN(ConfigBits_N[177])
);

config_latch Inst_frame12_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[176]),
    .QN(ConfigBits_N[176])
);

config_latch Inst_frame12_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[175]),
    .QN(ConfigBits_N[175])
);

config_latch Inst_frame12_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[174]),
    .QN(ConfigBits_N[174])
);

config_latch Inst_frame12_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[173]),
    .QN(ConfigBits_N[173])
);

config_latch Inst_frame12_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[172]),
    .QN(ConfigBits_N[172])
);

config_latch Inst_frame12_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[171]),
    .QN(ConfigBits_N[171])
);

config_latch Inst_frame12_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[170]),
    .QN(ConfigBits_N[170])
);

config_latch Inst_frame12_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[169]),
    .QN(ConfigBits_N[169])
);

config_latch Inst_frame12_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[168]),
    .QN(ConfigBits_N[168])
);

config_latch Inst_frame12_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[167]),
    .QN(ConfigBits_N[167])
);

config_latch Inst_frame12_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[166]),
    .QN(ConfigBits_N[166])
);

config_latch Inst_frame12_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[165]),
    .QN(ConfigBits_N[165])
);

config_latch Inst_frame12_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[164]),
    .QN(ConfigBits_N[164])
);

config_latch Inst_frame12_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[163]),
    .QN(ConfigBits_N[163])
);

config_latch Inst_frame12_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[162]),
    .QN(ConfigBits_N[162])
);

config_latch Inst_frame12_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[161]),
    .QN(ConfigBits_N[161])
);

config_latch Inst_frame12_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[160]),
    .QN(ConfigBits_N[160])
);

config_latch Inst_frame12_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[159]),
    .QN(ConfigBits_N[159])
);

config_latch Inst_frame12_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[158]),
    .QN(ConfigBits_N[158])
);

config_latch Inst_frame12_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[157]),
    .QN(ConfigBits_N[157])
);

config_latch Inst_frame12_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[156]),
    .QN(ConfigBits_N[156])
);

config_latch Inst_frame12_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[155]),
    .QN(ConfigBits_N[155])
);

config_latch Inst_frame12_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[154]),
    .QN(ConfigBits_N[154])
);

config_latch Inst_frame12_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[153]),
    .QN(ConfigBits_N[153])
);

config_latch Inst_frame12_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[152]),
    .QN(ConfigBits_N[152])
);

config_latch Inst_frame12_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[151]),
    .QN(ConfigBits_N[151])
);

config_latch Inst_frame12_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[12]),
    .Q(ConfigBits[150]),
    .QN(ConfigBits_N[150])
);

config_latch Inst_frame13_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[149]),
    .QN(ConfigBits_N[149])
);

config_latch Inst_frame13_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[148]),
    .QN(ConfigBits_N[148])
);

config_latch Inst_frame13_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[147]),
    .QN(ConfigBits_N[147])
);

config_latch Inst_frame13_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[146]),
    .QN(ConfigBits_N[146])
);

config_latch Inst_frame13_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[145]),
    .QN(ConfigBits_N[145])
);

config_latch Inst_frame13_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[144]),
    .QN(ConfigBits_N[144])
);

config_latch Inst_frame13_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[143]),
    .QN(ConfigBits_N[143])
);

config_latch Inst_frame13_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[142]),
    .QN(ConfigBits_N[142])
);

config_latch Inst_frame13_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[141]),
    .QN(ConfigBits_N[141])
);

config_latch Inst_frame13_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[140]),
    .QN(ConfigBits_N[140])
);

config_latch Inst_frame13_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[139]),
    .QN(ConfigBits_N[139])
);

config_latch Inst_frame13_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[138]),
    .QN(ConfigBits_N[138])
);

config_latch Inst_frame13_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[137]),
    .QN(ConfigBits_N[137])
);

config_latch Inst_frame13_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[136]),
    .QN(ConfigBits_N[136])
);

config_latch Inst_frame13_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[135]),
    .QN(ConfigBits_N[135])
);

config_latch Inst_frame13_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[134]),
    .QN(ConfigBits_N[134])
);

config_latch Inst_frame13_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[133]),
    .QN(ConfigBits_N[133])
);

config_latch Inst_frame13_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[132]),
    .QN(ConfigBits_N[132])
);

config_latch Inst_frame13_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[131]),
    .QN(ConfigBits_N[131])
);

config_latch Inst_frame13_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[130]),
    .QN(ConfigBits_N[130])
);

config_latch Inst_frame13_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[129]),
    .QN(ConfigBits_N[129])
);

config_latch Inst_frame13_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[128]),
    .QN(ConfigBits_N[128])
);

config_latch Inst_frame13_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[127]),
    .QN(ConfigBits_N[127])
);

config_latch Inst_frame13_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[126]),
    .QN(ConfigBits_N[126])
);

config_latch Inst_frame13_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[125]),
    .QN(ConfigBits_N[125])
);

config_latch Inst_frame13_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[124]),
    .QN(ConfigBits_N[124])
);

config_latch Inst_frame13_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[123]),
    .QN(ConfigBits_N[123])
);

config_latch Inst_frame13_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[122]),
    .QN(ConfigBits_N[122])
);

config_latch Inst_frame13_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[121]),
    .QN(ConfigBits_N[121])
);

config_latch Inst_frame13_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[120]),
    .QN(ConfigBits_N[120])
);

config_latch Inst_frame13_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[119]),
    .QN(ConfigBits_N[119])
);

config_latch Inst_frame13_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[13]),
    .Q(ConfigBits[118]),
    .QN(ConfigBits_N[118])
);

config_latch Inst_frame14_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[117]),
    .QN(ConfigBits_N[117])
);

config_latch Inst_frame14_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[116]),
    .QN(ConfigBits_N[116])
);

config_latch Inst_frame14_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[115]),
    .QN(ConfigBits_N[115])
);

config_latch Inst_frame14_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[114]),
    .QN(ConfigBits_N[114])
);

config_latch Inst_frame14_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[113]),
    .QN(ConfigBits_N[113])
);

config_latch Inst_frame14_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[112]),
    .QN(ConfigBits_N[112])
);

config_latch Inst_frame14_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[111]),
    .QN(ConfigBits_N[111])
);

config_latch Inst_frame14_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[110]),
    .QN(ConfigBits_N[110])
);

config_latch Inst_frame14_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[109]),
    .QN(ConfigBits_N[109])
);

config_latch Inst_frame14_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[108]),
    .QN(ConfigBits_N[108])
);

config_latch Inst_frame14_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[107]),
    .QN(ConfigBits_N[107])
);

config_latch Inst_frame14_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[106]),
    .QN(ConfigBits_N[106])
);

config_latch Inst_frame14_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[105]),
    .QN(ConfigBits_N[105])
);

config_latch Inst_frame14_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[104]),
    .QN(ConfigBits_N[104])
);

config_latch Inst_frame14_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[103]),
    .QN(ConfigBits_N[103])
);

config_latch Inst_frame14_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[102]),
    .QN(ConfigBits_N[102])
);

config_latch Inst_frame14_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[101]),
    .QN(ConfigBits_N[101])
);

config_latch Inst_frame14_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[100]),
    .QN(ConfigBits_N[100])
);

config_latch Inst_frame14_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[99]),
    .QN(ConfigBits_N[99])
);

config_latch Inst_frame14_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[98]),
    .QN(ConfigBits_N[98])
);

config_latch Inst_frame14_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[97]),
    .QN(ConfigBits_N[97])
);

config_latch Inst_frame14_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[96]),
    .QN(ConfigBits_N[96])
);

config_latch Inst_frame14_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[95]),
    .QN(ConfigBits_N[95])
);

config_latch Inst_frame14_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[94]),
    .QN(ConfigBits_N[94])
);

config_latch Inst_frame14_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[93]),
    .QN(ConfigBits_N[93])
);

config_latch Inst_frame14_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[92]),
    .QN(ConfigBits_N[92])
);

config_latch Inst_frame14_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[91]),
    .QN(ConfigBits_N[91])
);

config_latch Inst_frame14_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[90]),
    .QN(ConfigBits_N[90])
);

config_latch Inst_frame14_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[89]),
    .QN(ConfigBits_N[89])
);

config_latch Inst_frame14_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[88]),
    .QN(ConfigBits_N[88])
);

config_latch Inst_frame14_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[87]),
    .QN(ConfigBits_N[87])
);

config_latch Inst_frame14_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[14]),
    .Q(ConfigBits[86]),
    .QN(ConfigBits_N[86])
);

config_latch Inst_frame15_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[85]),
    .QN(ConfigBits_N[85])
);

config_latch Inst_frame15_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[84]),
    .QN(ConfigBits_N[84])
);

config_latch Inst_frame15_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[83]),
    .QN(ConfigBits_N[83])
);

config_latch Inst_frame15_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[82]),
    .QN(ConfigBits_N[82])
);

config_latch Inst_frame15_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[81]),
    .QN(ConfigBits_N[81])
);

config_latch Inst_frame15_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[80]),
    .QN(ConfigBits_N[80])
);

config_latch Inst_frame15_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[79]),
    .QN(ConfigBits_N[79])
);

config_latch Inst_frame15_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[78]),
    .QN(ConfigBits_N[78])
);

config_latch Inst_frame15_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[77]),
    .QN(ConfigBits_N[77])
);

config_latch Inst_frame15_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[76]),
    .QN(ConfigBits_N[76])
);

config_latch Inst_frame15_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[75]),
    .QN(ConfigBits_N[75])
);

config_latch Inst_frame15_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[74]),
    .QN(ConfigBits_N[74])
);

config_latch Inst_frame15_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[73]),
    .QN(ConfigBits_N[73])
);

config_latch Inst_frame15_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[72]),
    .QN(ConfigBits_N[72])
);

config_latch Inst_frame15_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[71]),
    .QN(ConfigBits_N[71])
);

config_latch Inst_frame15_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[70]),
    .QN(ConfigBits_N[70])
);

config_latch Inst_frame15_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[69]),
    .QN(ConfigBits_N[69])
);

config_latch Inst_frame15_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[68]),
    .QN(ConfigBits_N[68])
);

config_latch Inst_frame15_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[67]),
    .QN(ConfigBits_N[67])
);

config_latch Inst_frame15_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[66]),
    .QN(ConfigBits_N[66])
);

config_latch Inst_frame15_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[65]),
    .QN(ConfigBits_N[65])
);

config_latch Inst_frame15_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[64]),
    .QN(ConfigBits_N[64])
);

config_latch Inst_frame15_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[63]),
    .QN(ConfigBits_N[63])
);

config_latch Inst_frame15_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[62]),
    .QN(ConfigBits_N[62])
);

config_latch Inst_frame15_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[61]),
    .QN(ConfigBits_N[61])
);

config_latch Inst_frame15_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[60]),
    .QN(ConfigBits_N[60])
);

config_latch Inst_frame15_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[59]),
    .QN(ConfigBits_N[59])
);

config_latch Inst_frame15_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[58]),
    .QN(ConfigBits_N[58])
);

config_latch Inst_frame15_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[57]),
    .QN(ConfigBits_N[57])
);

config_latch Inst_frame15_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[56]),
    .QN(ConfigBits_N[56])
);

config_latch Inst_frame15_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[55]),
    .QN(ConfigBits_N[55])
);

config_latch Inst_frame15_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[15]),
    .Q(ConfigBits[54]),
    .QN(ConfigBits_N[54])
);

config_latch Inst_frame16_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[53]),
    .QN(ConfigBits_N[53])
);

config_latch Inst_frame16_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[52]),
    .QN(ConfigBits_N[52])
);

config_latch Inst_frame16_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[51]),
    .QN(ConfigBits_N[51])
);

config_latch Inst_frame16_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[50]),
    .QN(ConfigBits_N[50])
);

config_latch Inst_frame16_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[49]),
    .QN(ConfigBits_N[49])
);

config_latch Inst_frame16_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[48]),
    .QN(ConfigBits_N[48])
);

config_latch Inst_frame16_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[47]),
    .QN(ConfigBits_N[47])
);

config_latch Inst_frame16_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[46]),
    .QN(ConfigBits_N[46])
);

config_latch Inst_frame16_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[45]),
    .QN(ConfigBits_N[45])
);

config_latch Inst_frame16_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[44]),
    .QN(ConfigBits_N[44])
);

config_latch Inst_frame16_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[43]),
    .QN(ConfigBits_N[43])
);

config_latch Inst_frame16_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[42]),
    .QN(ConfigBits_N[42])
);

config_latch Inst_frame16_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[41]),
    .QN(ConfigBits_N[41])
);

config_latch Inst_frame16_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[40]),
    .QN(ConfigBits_N[40])
);

config_latch Inst_frame16_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[39]),
    .QN(ConfigBits_N[39])
);

config_latch Inst_frame16_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[38]),
    .QN(ConfigBits_N[38])
);

config_latch Inst_frame16_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[37]),
    .QN(ConfigBits_N[37])
);

config_latch Inst_frame16_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[36]),
    .QN(ConfigBits_N[36])
);

config_latch Inst_frame16_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[35]),
    .QN(ConfigBits_N[35])
);

config_latch Inst_frame16_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[34]),
    .QN(ConfigBits_N[34])
);

config_latch Inst_frame16_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[33]),
    .QN(ConfigBits_N[33])
);

config_latch Inst_frame16_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[32]),
    .QN(ConfigBits_N[32])
);

config_latch Inst_frame16_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[31]),
    .QN(ConfigBits_N[31])
);

config_latch Inst_frame16_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[30]),
    .QN(ConfigBits_N[30])
);

config_latch Inst_frame16_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[29]),
    .QN(ConfigBits_N[29])
);

config_latch Inst_frame16_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[28]),
    .QN(ConfigBits_N[28])
);

config_latch Inst_frame16_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[27]),
    .QN(ConfigBits_N[27])
);

config_latch Inst_frame16_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[26]),
    .QN(ConfigBits_N[26])
);

config_latch Inst_frame16_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[25]),
    .QN(ConfigBits_N[25])
);

config_latch Inst_frame16_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[24]),
    .QN(ConfigBits_N[24])
);

config_latch Inst_frame16_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[23]),
    .QN(ConfigBits_N[23])
);

config_latch Inst_frame16_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[16]),
    .Q(ConfigBits[22]),
    .QN(ConfigBits_N[22])
);

config_latch Inst_frame17_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[17]),
    .Q(ConfigBits[21]),
    .QN(ConfigBits_N[21])
);

config_latch Inst_frame17_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[17]),
    .Q(ConfigBits[20]),
    .QN(ConfigBits_N[20])
);

config_latch Inst_frame17_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[17]),
    .Q(ConfigBits[19]),
    .QN(ConfigBits_N[19])
);

config_latch Inst_frame17_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[17]),
    .Q(ConfigBits[18]),
    .QN(ConfigBits_N[18])
);

config_latch Inst_frame17_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[17]),
    .Q(ConfigBits[17]),
    .QN(ConfigBits_N[17])
);

config_latch Inst_frame17_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[17]),
    .Q(ConfigBits[16]),
    .QN(ConfigBits_N[16])
);

config_latch Inst_frame17_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[17]),
    .Q(ConfigBits[15]),
    .QN(ConfigBits_N[15])
);

config_latch Inst_frame17_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[17]),
    .Q(ConfigBits[14]),
    .QN(ConfigBits_N[14])
);

config_latch Inst_frame17_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[17]),
    .Q(ConfigBits[13]),
    .QN(ConfigBits_N[13])
);

config_latch Inst_frame17_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[17]),
    .Q(ConfigBits[12]),
    .QN(ConfigBits_N[12])
);

config_latch Inst_frame17_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[17]),
    .Q(ConfigBits[11]),
    .QN(ConfigBits_N[11])
);

config_latch Inst_frame17_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[17]),
    .Q(ConfigBits[10]),
    .QN(ConfigBits_N[10])
);

config_latch Inst_frame17_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[17]),
    .Q(ConfigBits[9]),
    .QN(ConfigBits_N[9])
);

config_latch Inst_frame17_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[17]),
    .Q(ConfigBits[8]),
    .QN(ConfigBits_N[8])
);

config_latch Inst_frame17_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[17]),
    .Q(ConfigBits[7]),
    .QN(ConfigBits_N[7])
);

config_latch Inst_frame17_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[17]),
    .Q(ConfigBits[6]),
    .QN(ConfigBits_N[6])
);

config_latch Inst_frame17_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[17]),
    .Q(ConfigBits[5]),
    .QN(ConfigBits_N[5])
);

config_latch Inst_frame17_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[17]),
    .Q(ConfigBits[4]),
    .QN(ConfigBits_N[4])
);

config_latch Inst_frame17_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[17]),
    .Q(ConfigBits[3]),
    .QN(ConfigBits_N[3])
);

config_latch Inst_frame17_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[17]),
    .Q(ConfigBits[2]),
    .QN(ConfigBits_N[2])
);

config_latch Inst_frame17_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[17]),
    .Q(ConfigBits[1]),
    .QN(ConfigBits_N[1])
);

config_latch Inst_frame17_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[17]),
    .Q(ConfigBits[0]),
    .QN(ConfigBits_N[0])
);

`endif
endmodule
 // NumberOfConfigBits: 414
module LUT4x8_ha_switch_matrix
    #(
        parameter NoConfigBits=414
    )
    (
        input  N_GBUF_END0,
        input  N_GBUF_END1,
        input  N_GBUF_END2,
        input  N_GBUF_END3,
        input  N1END0,
        input  N1END1,
        input  N1END2,
        input  N1END3,
        input  N1END4,
        input  N1END5,
        input  N1END6,
        input  N1END7,
        input  N2MID0,
        input  N2MID1,
        input  N2MID2,
        input  N2MID3,
        input  N2MID4,
        input  N2MID5,
        input  N2MID6,
        input  N2MID7,
        input  N2END0,
        input  N2END1,
        input  N2END2,
        input  N2END3,
        input  N2END4,
        input  N2END5,
        input  N2END6,
        input  N2END7,
        input  E1END0,
        input  E1END1,
        input  E1END2,
        input  E1END3,
        input  E1END4,
        input  E1END5,
        input  E1END6,
        input  E1END7,
        input  E2MID0,
        input  E2MID1,
        input  E2MID2,
        input  E2MID3,
        input  E2MID4,
        input  E2MID5,
        input  E2MID6,
        input  E2MID7,
        input  E2END0,
        input  E2END1,
        input  E2END2,
        input  E2END3,
        input  E2END4,
        input  E2END5,
        input  E2END6,
        input  E2END7,
        input  S1END0,
        input  S1END1,
        input  S1END2,
        input  S1END3,
        input  S1END4,
        input  S1END5,
        input  S1END6,
        input  S1END7,
        input  S2MID0,
        input  S2MID1,
        input  S2MID2,
        input  S2MID3,
        input  S2MID4,
        input  S2MID5,
        input  S2MID6,
        input  S2MID7,
        input  S2END0,
        input  S2END1,
        input  S2END2,
        input  S2END3,
        input  S2END4,
        input  S2END5,
        input  S2END6,
        input  S2END7,
        input  W1END0,
        input  W1END1,
        input  W1END2,
        input  W1END3,
        input  W1END4,
        input  W1END5,
        input  W1END6,
        input  W1END7,
        input  W2MID0,
        input  W2MID1,
        input  W2MID2,
        input  W2MID3,
        input  W2MID4,
        input  W2MID5,
        input  W2MID6,
        input  W2MID7,
        input  W2END0,
        input  W2END1,
        input  W2END2,
        input  W2END3,
        input  W2END4,
        input  W2END5,
        input  W2END6,
        input  W2END7,
        input  CI0,
        input  LA_O,
        input  LA_Co,
        input  LB_O,
        input  LB_Co,
        input  LC_O,
        input  LC_Co,
        input  LD_O,
        input  LD_Co,
        input  LE_O,
        input  LE_Co,
        input  LF_O,
        input  LF_Co,
        input  LG_O,
        input  LG_Co,
        input  LH_O,
        input  LH_Co,
        input  J2MID_ABa_END0,
        input  J2MID_ABa_END1,
        input  J2MID_ABa_END2,
        input  J2MID_ABa_END3,
        input  J2MID_CDa_END0,
        input  J2MID_CDa_END1,
        input  J2MID_CDa_END2,
        input  J2MID_CDa_END3,
        input  J2MID_EFa_END0,
        input  J2MID_EFa_END1,
        input  J2MID_EFa_END2,
        input  J2MID_EFa_END3,
        input  J2MID_GHa_END0,
        input  J2MID_GHa_END1,
        input  J2MID_GHa_END2,
        input  J2MID_GHa_END3,
        input  J2MID_ABb_END0,
        input  J2MID_ABb_END1,
        input  J2MID_ABb_END2,
        input  J2MID_ABb_END3,
        input  J2MID_CDb_END0,
        input  J2MID_CDb_END1,
        input  J2MID_CDb_END2,
        input  J2MID_CDb_END3,
        input  J2MID_EFb_END0,
        input  J2MID_EFb_END1,
        input  J2MID_EFb_END2,
        input  J2MID_EFb_END3,
        input  J2MID_GHb_END0,
        input  J2MID_GHb_END1,
        input  J2MID_GHb_END2,
        input  J2MID_GHb_END3,
        input  J2END_AB_END0,
        input  J2END_AB_END1,
        input  J2END_AB_END2,
        input  J2END_AB_END3,
        input  J2END_CD_END0,
        input  J2END_CD_END1,
        input  J2END_CD_END2,
        input  J2END_CD_END3,
        input  J2END_EF_END0,
        input  J2END_EF_END1,
        input  J2END_EF_END2,
        input  J2END_EF_END3,
        input  J2END_GH_END0,
        input  J2END_GH_END1,
        input  J2END_GH_END2,
        input  J2END_GH_END3,
        input  JN2END0,
        input  JN2END1,
        input  JN2END2,
        input  JN2END3,
        input  JN2END4,
        input  JN2END5,
        input  JN2END6,
        input  JN2END7,
        input  JE2END0,
        input  JE2END1,
        input  JE2END2,
        input  JE2END3,
        input  JE2END4,
        input  JE2END5,
        input  JE2END6,
        input  JE2END7,
        input  JS2END0,
        input  JS2END1,
        input  JS2END2,
        input  JS2END3,
        input  JS2END4,
        input  JS2END5,
        input  JS2END6,
        input  JS2END7,
        input  JW2END0,
        input  JW2END1,
        input  JW2END2,
        input  JW2END3,
        input  JW2END4,
        input  JW2END5,
        input  JW2END6,
        input  JW2END7,
        input  J_l_AB_END0,
        input  J_l_AB_END1,
        input  J_l_AB_END2,
        input  J_l_AB_END3,
        input  J_l_CD_END0,
        input  J_l_CD_END1,
        input  J_l_CD_END2,
        input  J_l_CD_END3,
        input  J_l_EF_END0,
        input  J_l_EF_END1,
        input  J_l_EF_END2,
        input  J_l_EF_END3,
        input  J_l_GH_END0,
        input  J_l_GH_END1,
        input  J_l_GH_END2,
        input  J_l_GH_END3,
        input  GCLK_END0,
        input  GSR_END0,
        input  GEN_END0,
        input  J_SR_END0,
        input  J_EN_END0,
        output  N_GBUF_BEG0,
        output  N_GBUF_BEG1,
        output  N_GBUF_BEG2,
        output  N_GBUF_BEG3,
        output  N1BEG0,
        output  N1BEG1,
        output  N1BEG2,
        output  N1BEG3,
        output  N1BEG4,
        output  N1BEG5,
        output  N1BEG6,
        output  N1BEG7,
        output  N2BEG0,
        output  N2BEG1,
        output  N2BEG2,
        output  N2BEG3,
        output  N2BEG4,
        output  N2BEG5,
        output  N2BEG6,
        output  N2BEG7,
        output  N2BEGb0,
        output  N2BEGb1,
        output  N2BEGb2,
        output  N2BEGb3,
        output  N2BEGb4,
        output  N2BEGb5,
        output  N2BEGb6,
        output  N2BEGb7,
        output  E1BEG0,
        output  E1BEG1,
        output  E1BEG2,
        output  E1BEG3,
        output  E1BEG4,
        output  E1BEG5,
        output  E1BEG6,
        output  E1BEG7,
        output  E2BEG0,
        output  E2BEG1,
        output  E2BEG2,
        output  E2BEG3,
        output  E2BEG4,
        output  E2BEG5,
        output  E2BEG6,
        output  E2BEG7,
        output  E2BEGb0,
        output  E2BEGb1,
        output  E2BEGb2,
        output  E2BEGb3,
        output  E2BEGb4,
        output  E2BEGb5,
        output  E2BEGb6,
        output  E2BEGb7,
        output  S1BEG0,
        output  S1BEG1,
        output  S1BEG2,
        output  S1BEG3,
        output  S1BEG4,
        output  S1BEG5,
        output  S1BEG6,
        output  S1BEG7,
        output  S2BEG0,
        output  S2BEG1,
        output  S2BEG2,
        output  S2BEG3,
        output  S2BEG4,
        output  S2BEG5,
        output  S2BEG6,
        output  S2BEG7,
        output  S2BEGb0,
        output  S2BEGb1,
        output  S2BEGb2,
        output  S2BEGb3,
        output  S2BEGb4,
        output  S2BEGb5,
        output  S2BEGb6,
        output  S2BEGb7,
        output  W1BEG0,
        output  W1BEG1,
        output  W1BEG2,
        output  W1BEG3,
        output  W1BEG4,
        output  W1BEG5,
        output  W1BEG6,
        output  W1BEG7,
        output  W2BEG0,
        output  W2BEG1,
        output  W2BEG2,
        output  W2BEG3,
        output  W2BEG4,
        output  W2BEG5,
        output  W2BEG6,
        output  W2BEG7,
        output  W2BEGb0,
        output  W2BEGb1,
        output  W2BEGb2,
        output  W2BEGb3,
        output  W2BEGb4,
        output  W2BEGb5,
        output  W2BEGb6,
        output  W2BEGb7,
        output  CO0,
        output  LA_I0,
        output  LA_I1,
        output  LA_I2,
        output  LA_I3,
        output  LA_Ci,
        output  LA_SR,
        output  LA_EN,
        output  LA_CLK,
        output  LB_I0,
        output  LB_I1,
        output  LB_I2,
        output  LB_I3,
        output  LB_Ci,
        output  LB_SR,
        output  LB_EN,
        output  LB_CLK,
        output  LC_I0,
        output  LC_I1,
        output  LC_I2,
        output  LC_I3,
        output  LC_Ci,
        output  LC_SR,
        output  LC_EN,
        output  LC_CLK,
        output  LD_I0,
        output  LD_I1,
        output  LD_I2,
        output  LD_I3,
        output  LD_Ci,
        output  LD_SR,
        output  LD_EN,
        output  LD_CLK,
        output  LE_I0,
        output  LE_I1,
        output  LE_I2,
        output  LE_I3,
        output  LE_Ci,
        output  LE_SR,
        output  LE_EN,
        output  LE_CLK,
        output  LF_I0,
        output  LF_I1,
        output  LF_I2,
        output  LF_I3,
        output  LF_Ci,
        output  LF_SR,
        output  LF_EN,
        output  LF_CLK,
        output  LG_I0,
        output  LG_I1,
        output  LG_I2,
        output  LG_I3,
        output  LG_Ci,
        output  LG_SR,
        output  LG_EN,
        output  LG_CLK,
        output  LH_I0,
        output  LH_I1,
        output  LH_I2,
        output  LH_I3,
        output  LH_Ci,
        output  LH_SR,
        output  LH_EN,
        output  LH_CLK,
        output  J2MID_ABa_BEG0,
        output  J2MID_ABa_BEG1,
        output  J2MID_ABa_BEG2,
        output  J2MID_ABa_BEG3,
        output  J2MID_CDa_BEG0,
        output  J2MID_CDa_BEG1,
        output  J2MID_CDa_BEG2,
        output  J2MID_CDa_BEG3,
        output  J2MID_EFa_BEG0,
        output  J2MID_EFa_BEG1,
        output  J2MID_EFa_BEG2,
        output  J2MID_EFa_BEG3,
        output  J2MID_GHa_BEG0,
        output  J2MID_GHa_BEG1,
        output  J2MID_GHa_BEG2,
        output  J2MID_GHa_BEG3,
        output  J2MID_ABb_BEG0,
        output  J2MID_ABb_BEG1,
        output  J2MID_ABb_BEG2,
        output  J2MID_ABb_BEG3,
        output  J2MID_CDb_BEG0,
        output  J2MID_CDb_BEG1,
        output  J2MID_CDb_BEG2,
        output  J2MID_CDb_BEG3,
        output  J2MID_EFb_BEG0,
        output  J2MID_EFb_BEG1,
        output  J2MID_EFb_BEG2,
        output  J2MID_EFb_BEG3,
        output  J2MID_GHb_BEG0,
        output  J2MID_GHb_BEG1,
        output  J2MID_GHb_BEG2,
        output  J2MID_GHb_BEG3,
        output  J2END_AB_BEG0,
        output  J2END_AB_BEG1,
        output  J2END_AB_BEG2,
        output  J2END_AB_BEG3,
        output  J2END_CD_BEG0,
        output  J2END_CD_BEG1,
        output  J2END_CD_BEG2,
        output  J2END_CD_BEG3,
        output  J2END_EF_BEG0,
        output  J2END_EF_BEG1,
        output  J2END_EF_BEG2,
        output  J2END_EF_BEG3,
        output  J2END_GH_BEG0,
        output  J2END_GH_BEG1,
        output  J2END_GH_BEG2,
        output  J2END_GH_BEG3,
        output  JN2BEG0,
        output  JN2BEG1,
        output  JN2BEG2,
        output  JN2BEG3,
        output  JN2BEG4,
        output  JN2BEG5,
        output  JN2BEG6,
        output  JN2BEG7,
        output  JE2BEG0,
        output  JE2BEG1,
        output  JE2BEG2,
        output  JE2BEG3,
        output  JE2BEG4,
        output  JE2BEG5,
        output  JE2BEG6,
        output  JE2BEG7,
        output  JS2BEG0,
        output  JS2BEG1,
        output  JS2BEG2,
        output  JS2BEG3,
        output  JS2BEG4,
        output  JS2BEG5,
        output  JS2BEG6,
        output  JS2BEG7,
        output  JW2BEG0,
        output  JW2BEG1,
        output  JW2BEG2,
        output  JW2BEG3,
        output  JW2BEG4,
        output  JW2BEG5,
        output  JW2BEG6,
        output  JW2BEG7,
        output  J_l_AB_BEG0,
        output  J_l_AB_BEG1,
        output  J_l_AB_BEG2,
        output  J_l_AB_BEG3,
        output  J_l_CD_BEG0,
        output  J_l_CD_BEG1,
        output  J_l_CD_BEG2,
        output  J_l_CD_BEG3,
        output  J_l_EF_BEG0,
        output  J_l_EF_BEG1,
        output  J_l_EF_BEG2,
        output  J_l_EF_BEG3,
        output  J_l_GH_BEG0,
        output  J_l_GH_BEG1,
        output  J_l_GH_BEG2,
        output  J_l_GH_BEG3,
        output  GCLK_BEG0,
        output  GSR_BEG0,
        output  GEN_BEG0,
        output  J_SR_BEG0,
        output  J_EN_BEG0,
 //global
        input  [NoConfigBits-1:0] ConfigBits,
        input  [NoConfigBits-1:0] ConfigBits_N
);
parameter GND0 = 1'b0;
parameter GND = 1'b0;
parameter VCC0 = 1'b1;
parameter VCC = 1'b1;
parameter VDD0 = 1'b1;
parameter VDD = 1'b1;

wire[4-1:0] N1BEG0_input;
wire[4-1:0] N1BEG1_input;
wire[4-1:0] N1BEG2_input;
wire[4-1:0] N1BEG3_input;
wire[4-1:0] N1BEG4_input;
wire[4-1:0] N1BEG5_input;
wire[4-1:0] N1BEG6_input;
wire[4-1:0] N1BEG7_input;
wire[4-1:0] E1BEG0_input;
wire[4-1:0] E1BEG1_input;
wire[4-1:0] E1BEG2_input;
wire[4-1:0] E1BEG3_input;
wire[4-1:0] E1BEG4_input;
wire[4-1:0] E1BEG5_input;
wire[4-1:0] E1BEG6_input;
wire[4-1:0] E1BEG7_input;
wire[4-1:0] S1BEG0_input;
wire[4-1:0] S1BEG1_input;
wire[4-1:0] S1BEG2_input;
wire[4-1:0] S1BEG3_input;
wire[4-1:0] S1BEG4_input;
wire[4-1:0] S1BEG5_input;
wire[4-1:0] S1BEG6_input;
wire[4-1:0] S1BEG7_input;
wire[4-1:0] W1BEG0_input;
wire[4-1:0] W1BEG1_input;
wire[4-1:0] W1BEG2_input;
wire[4-1:0] W1BEG3_input;
wire[4-1:0] W1BEG4_input;
wire[4-1:0] W1BEG5_input;
wire[4-1:0] W1BEG6_input;
wire[4-1:0] W1BEG7_input;
wire[4-1:0] LA_I0_input;
wire[4-1:0] LA_I1_input;
wire[4-1:0] LA_I2_input;
wire[4-1:0] LA_I3_input;
wire[2-1:0] LA_SR_input;
wire[2-1:0] LA_EN_input;
wire[4-1:0] LB_I0_input;
wire[4-1:0] LB_I1_input;
wire[4-1:0] LB_I2_input;
wire[4-1:0] LB_I3_input;
wire[2-1:0] LB_SR_input;
wire[2-1:0] LB_EN_input;
wire[4-1:0] LC_I0_input;
wire[4-1:0] LC_I1_input;
wire[4-1:0] LC_I2_input;
wire[4-1:0] LC_I3_input;
wire[2-1:0] LC_SR_input;
wire[2-1:0] LC_EN_input;
wire[4-1:0] LD_I0_input;
wire[4-1:0] LD_I1_input;
wire[4-1:0] LD_I2_input;
wire[4-1:0] LD_I3_input;
wire[2-1:0] LD_SR_input;
wire[2-1:0] LD_EN_input;
wire[4-1:0] LE_I0_input;
wire[4-1:0] LE_I1_input;
wire[4-1:0] LE_I2_input;
wire[4-1:0] LE_I3_input;
wire[2-1:0] LE_SR_input;
wire[2-1:0] LE_EN_input;
wire[4-1:0] LF_I0_input;
wire[4-1:0] LF_I1_input;
wire[4-1:0] LF_I2_input;
wire[4-1:0] LF_I3_input;
wire[2-1:0] LF_SR_input;
wire[2-1:0] LF_EN_input;
wire[4-1:0] LG_I0_input;
wire[4-1:0] LG_I1_input;
wire[4-1:0] LG_I2_input;
wire[4-1:0] LG_I3_input;
wire[2-1:0] LG_SR_input;
wire[2-1:0] LG_EN_input;
wire[4-1:0] LH_I0_input;
wire[4-1:0] LH_I1_input;
wire[4-1:0] LH_I2_input;
wire[4-1:0] LH_I3_input;
wire[2-1:0] LH_SR_input;
wire[2-1:0] LH_EN_input;
wire[4-1:0] J2MID_ABa_BEG0_input;
wire[4-1:0] J2MID_ABa_BEG1_input;
wire[4-1:0] J2MID_ABa_BEG2_input;
wire[4-1:0] J2MID_ABa_BEG3_input;
wire[4-1:0] J2MID_CDa_BEG0_input;
wire[4-1:0] J2MID_CDa_BEG1_input;
wire[4-1:0] J2MID_CDa_BEG2_input;
wire[4-1:0] J2MID_CDa_BEG3_input;
wire[4-1:0] J2MID_EFa_BEG0_input;
wire[4-1:0] J2MID_EFa_BEG1_input;
wire[4-1:0] J2MID_EFa_BEG2_input;
wire[4-1:0] J2MID_EFa_BEG3_input;
wire[4-1:0] J2MID_GHa_BEG0_input;
wire[4-1:0] J2MID_GHa_BEG1_input;
wire[4-1:0] J2MID_GHa_BEG2_input;
wire[4-1:0] J2MID_GHa_BEG3_input;
wire[4-1:0] J2MID_ABb_BEG0_input;
wire[4-1:0] J2MID_ABb_BEG1_input;
wire[4-1:0] J2MID_ABb_BEG2_input;
wire[4-1:0] J2MID_ABb_BEG3_input;
wire[4-1:0] J2MID_CDb_BEG0_input;
wire[4-1:0] J2MID_CDb_BEG1_input;
wire[4-1:0] J2MID_CDb_BEG2_input;
wire[4-1:0] J2MID_CDb_BEG3_input;
wire[4-1:0] J2MID_EFb_BEG0_input;
wire[4-1:0] J2MID_EFb_BEG1_input;
wire[4-1:0] J2MID_EFb_BEG2_input;
wire[4-1:0] J2MID_EFb_BEG3_input;
wire[4-1:0] J2MID_GHb_BEG0_input;
wire[4-1:0] J2MID_GHb_BEG1_input;
wire[4-1:0] J2MID_GHb_BEG2_input;
wire[4-1:0] J2MID_GHb_BEG3_input;
wire[4-1:0] J2END_AB_BEG0_input;
wire[4-1:0] J2END_AB_BEG1_input;
wire[4-1:0] J2END_AB_BEG2_input;
wire[4-1:0] J2END_AB_BEG3_input;
wire[4-1:0] J2END_CD_BEG0_input;
wire[4-1:0] J2END_CD_BEG1_input;
wire[4-1:0] J2END_CD_BEG2_input;
wire[4-1:0] J2END_CD_BEG3_input;
wire[4-1:0] J2END_EF_BEG0_input;
wire[4-1:0] J2END_EF_BEG1_input;
wire[4-1:0] J2END_EF_BEG2_input;
wire[4-1:0] J2END_EF_BEG3_input;
wire[4-1:0] J2END_GH_BEG0_input;
wire[4-1:0] J2END_GH_BEG1_input;
wire[4-1:0] J2END_GH_BEG2_input;
wire[4-1:0] J2END_GH_BEG3_input;
wire[16-1:0] JN2BEG0_input;
wire[16-1:0] JN2BEG1_input;
wire[16-1:0] JN2BEG2_input;
wire[16-1:0] JN2BEG3_input;
wire[16-1:0] JN2BEG4_input;
wire[16-1:0] JN2BEG5_input;
wire[16-1:0] JN2BEG6_input;
wire[16-1:0] JN2BEG7_input;
wire[16-1:0] JE2BEG0_input;
wire[16-1:0] JE2BEG1_input;
wire[16-1:0] JE2BEG2_input;
wire[16-1:0] JE2BEG3_input;
wire[16-1:0] JE2BEG4_input;
wire[16-1:0] JE2BEG5_input;
wire[16-1:0] JE2BEG6_input;
wire[16-1:0] JE2BEG7_input;
wire[16-1:0] JS2BEG0_input;
wire[16-1:0] JS2BEG1_input;
wire[16-1:0] JS2BEG2_input;
wire[16-1:0] JS2BEG3_input;
wire[16-1:0] JS2BEG4_input;
wire[16-1:0] JS2BEG5_input;
wire[16-1:0] JS2BEG6_input;
wire[16-1:0] JS2BEG7_input;
wire[16-1:0] JW2BEG0_input;
wire[16-1:0] JW2BEG1_input;
wire[16-1:0] JW2BEG2_input;
wire[16-1:0] JW2BEG3_input;
wire[16-1:0] JW2BEG4_input;
wire[16-1:0] JW2BEG5_input;
wire[16-1:0] JW2BEG6_input;
wire[16-1:0] JW2BEG7_input;
wire[4-1:0] J_l_AB_BEG0_input;
wire[4-1:0] J_l_AB_BEG1_input;
wire[4-1:0] J_l_AB_BEG2_input;
wire[4-1:0] J_l_AB_BEG3_input;
wire[4-1:0] J_l_CD_BEG0_input;
wire[4-1:0] J_l_CD_BEG1_input;
wire[4-1:0] J_l_CD_BEG2_input;
wire[4-1:0] J_l_CD_BEG3_input;
wire[4-1:0] J_l_EF_BEG0_input;
wire[4-1:0] J_l_EF_BEG1_input;
wire[4-1:0] J_l_EF_BEG2_input;
wire[4-1:0] J_l_EF_BEG3_input;
wire[4-1:0] J_l_GH_BEG0_input;
wire[4-1:0] J_l_GH_BEG1_input;
wire[4-1:0] J_l_GH_BEG2_input;
wire[4-1:0] J_l_GH_BEG3_input;
wire[4-1:0] GCLK_BEG0_input;
wire[4-1:0] GSR_BEG0_input;
wire[4-1:0] GEN_BEG0_input;
wire[9-1:0] J_SR_BEG0_input;
wire[9-1:0] J_EN_BEG0_input;
 //The configuration bits (if any) are just a long shift register
 //This shift register is padded to an even number of flops/latches
 //switch matrix multiplexer N_GBUF_BEG0 MUX-1
assign N_GBUF_BEG0 = N_GBUF_END0;

 //switch matrix multiplexer N_GBUF_BEG1 MUX-1
assign N_GBUF_BEG1 = N_GBUF_END1;

 //switch matrix multiplexer N_GBUF_BEG2 MUX-1
assign N_GBUF_BEG2 = N_GBUF_END2;

 //switch matrix multiplexer N_GBUF_BEG3 MUX-1
assign N_GBUF_BEG3 = N_GBUF_END3;

 //switch matrix multiplexer N1BEG0 MUX-4
assign N1BEG0_input = {J_l_CD_END1,JW2END3,J2MID_CDb_END3,LC_O};
cus_mux41 inst_cus_mux41_N1BEG0 (
    .A0(N1BEG0_input[0]),
    .A1(N1BEG0_input[1]),
    .A2(N1BEG0_input[2]),
    .A3(N1BEG0_input[3]),
    .S0(ConfigBits[0+0]),
    .S0N(ConfigBits_N[0+0]),
    .S1(ConfigBits[0+1]),
    .S1N(ConfigBits_N[0+1]),
    .X(N1BEG0)
);

 //switch matrix multiplexer N1BEG1 MUX-4
assign N1BEG1_input = {J_l_EF_END2,JW2END0,J2MID_EFb_END0,LD_O};
cus_mux41 inst_cus_mux41_N1BEG1 (
    .A0(N1BEG1_input[0]),
    .A1(N1BEG1_input[1]),
    .A2(N1BEG1_input[2]),
    .A3(N1BEG1_input[3]),
    .S0(ConfigBits[2+0]),
    .S0N(ConfigBits_N[2+0]),
    .S1(ConfigBits[2+1]),
    .S1N(ConfigBits_N[2+1]),
    .X(N1BEG1)
);

 //switch matrix multiplexer N1BEG2 MUX-4
assign N1BEG2_input = {J_l_GH_END3,JW2END1,J2MID_GHb_END1,LE_O};
cus_mux41 inst_cus_mux41_N1BEG2 (
    .A0(N1BEG2_input[0]),
    .A1(N1BEG2_input[1]),
    .A2(N1BEG2_input[2]),
    .A3(N1BEG2_input[3]),
    .S0(ConfigBits[4+0]),
    .S0N(ConfigBits_N[4+0]),
    .S1(ConfigBits[4+1]),
    .S1N(ConfigBits_N[4+1]),
    .X(N1BEG2)
);

 //switch matrix multiplexer N1BEG3 MUX-4
assign N1BEG3_input = {J_l_AB_END0,JW2END2,J2MID_ABb_END2,LF_O};
cus_mux41 inst_cus_mux41_N1BEG3 (
    .A0(N1BEG3_input[0]),
    .A1(N1BEG3_input[1]),
    .A2(N1BEG3_input[2]),
    .A3(N1BEG3_input[3]),
    .S0(ConfigBits[6+0]),
    .S0N(ConfigBits_N[6+0]),
    .S1(ConfigBits[6+1]),
    .S1N(ConfigBits_N[6+1]),
    .X(N1BEG3)
);

 //switch matrix multiplexer N1BEG4 MUX-4
assign N1BEG4_input = {J_l_CD_END2,JW2END5,J2MID_CDb_END3,LG_O};
cus_mux41 inst_cus_mux41_N1BEG4 (
    .A0(N1BEG4_input[0]),
    .A1(N1BEG4_input[1]),
    .A2(N1BEG4_input[2]),
    .A3(N1BEG4_input[3]),
    .S0(ConfigBits[8+0]),
    .S0N(ConfigBits_N[8+0]),
    .S1(ConfigBits[8+1]),
    .S1N(ConfigBits_N[8+1]),
    .X(N1BEG4)
);

 //switch matrix multiplexer N1BEG5 MUX-4
assign N1BEG5_input = {J_l_EF_END3,JW2END7,J2MID_EFb_END0,LH_O};
cus_mux41 inst_cus_mux41_N1BEG5 (
    .A0(N1BEG5_input[0]),
    .A1(N1BEG5_input[1]),
    .A2(N1BEG5_input[2]),
    .A3(N1BEG5_input[3]),
    .S0(ConfigBits[10+0]),
    .S0N(ConfigBits_N[10+0]),
    .S1(ConfigBits[10+1]),
    .S1N(ConfigBits_N[10+1]),
    .X(N1BEG5)
);

 //switch matrix multiplexer N1BEG6 MUX-4
assign N1BEG6_input = {J_l_GH_END0,JW2END6,J2MID_GHb_END1,LA_O};
cus_mux41 inst_cus_mux41_N1BEG6 (
    .A0(N1BEG6_input[0]),
    .A1(N1BEG6_input[1]),
    .A2(N1BEG6_input[2]),
    .A3(N1BEG6_input[3]),
    .S0(ConfigBits[12+0]),
    .S0N(ConfigBits_N[12+0]),
    .S1(ConfigBits[12+1]),
    .S1N(ConfigBits_N[12+1]),
    .X(N1BEG6)
);

 //switch matrix multiplexer N1BEG7 MUX-4
assign N1BEG7_input = {J_l_AB_END1,JW2END4,J2MID_ABb_END2,LB_O};
cus_mux41 inst_cus_mux41_N1BEG7 (
    .A0(N1BEG7_input[0]),
    .A1(N1BEG7_input[1]),
    .A2(N1BEG7_input[2]),
    .A3(N1BEG7_input[3]),
    .S0(ConfigBits[14+0]),
    .S0N(ConfigBits_N[14+0]),
    .S1(ConfigBits[14+1]),
    .S1N(ConfigBits_N[14+1]),
    .X(N1BEG7)
);

 //switch matrix multiplexer N2BEG0 MUX-1
assign N2BEG0 = JN2END0;

 //switch matrix multiplexer N2BEG1 MUX-1
assign N2BEG1 = JN2END1;

 //switch matrix multiplexer N2BEG2 MUX-1
assign N2BEG2 = JN2END2;

 //switch matrix multiplexer N2BEG3 MUX-1
assign N2BEG3 = JN2END3;

 //switch matrix multiplexer N2BEG4 MUX-1
assign N2BEG4 = JN2END4;

 //switch matrix multiplexer N2BEG5 MUX-1
assign N2BEG5 = JN2END5;

 //switch matrix multiplexer N2BEG6 MUX-1
assign N2BEG6 = JN2END6;

 //switch matrix multiplexer N2BEG7 MUX-1
assign N2BEG7 = JN2END7;

 //switch matrix multiplexer N2BEGb0 MUX-1
assign N2BEGb0 = N2MID0;

 //switch matrix multiplexer N2BEGb1 MUX-1
assign N2BEGb1 = N2MID1;

 //switch matrix multiplexer N2BEGb2 MUX-1
assign N2BEGb2 = N2MID2;

 //switch matrix multiplexer N2BEGb3 MUX-1
assign N2BEGb3 = N2MID3;

 //switch matrix multiplexer N2BEGb4 MUX-1
assign N2BEGb4 = N2MID4;

 //switch matrix multiplexer N2BEGb5 MUX-1
assign N2BEGb5 = N2MID5;

 //switch matrix multiplexer N2BEGb6 MUX-1
assign N2BEGb6 = N2MID6;

 //switch matrix multiplexer N2BEGb7 MUX-1
assign N2BEGb7 = N2MID7;

 //switch matrix multiplexer E1BEG0 MUX-4
assign E1BEG0_input = {J_l_CD_END1,JN2END3,J2MID_CDb_END3,LD_O};
cus_mux41 inst_cus_mux41_E1BEG0 (
    .A0(E1BEG0_input[0]),
    .A1(E1BEG0_input[1]),
    .A2(E1BEG0_input[2]),
    .A3(E1BEG0_input[3]),
    .S0(ConfigBits[16+0]),
    .S0N(ConfigBits_N[16+0]),
    .S1(ConfigBits[16+1]),
    .S1N(ConfigBits_N[16+1]),
    .X(E1BEG0)
);

 //switch matrix multiplexer E1BEG1 MUX-4
assign E1BEG1_input = {J_l_EF_END2,JN2END0,J2MID_EFb_END0,LE_O};
cus_mux41 inst_cus_mux41_E1BEG1 (
    .A0(E1BEG1_input[0]),
    .A1(E1BEG1_input[1]),
    .A2(E1BEG1_input[2]),
    .A3(E1BEG1_input[3]),
    .S0(ConfigBits[18+0]),
    .S0N(ConfigBits_N[18+0]),
    .S1(ConfigBits[18+1]),
    .S1N(ConfigBits_N[18+1]),
    .X(E1BEG1)
);

 //switch matrix multiplexer E1BEG2 MUX-4
assign E1BEG2_input = {J_l_GH_END3,JN2END1,J2MID_GHb_END1,LF_O};
cus_mux41 inst_cus_mux41_E1BEG2 (
    .A0(E1BEG2_input[0]),
    .A1(E1BEG2_input[1]),
    .A2(E1BEG2_input[2]),
    .A3(E1BEG2_input[3]),
    .S0(ConfigBits[20+0]),
    .S0N(ConfigBits_N[20+0]),
    .S1(ConfigBits[20+1]),
    .S1N(ConfigBits_N[20+1]),
    .X(E1BEG2)
);

 //switch matrix multiplexer E1BEG3 MUX-4
assign E1BEG3_input = {J_l_AB_END0,JN2END2,J2MID_ABb_END2,LG_O};
cus_mux41 inst_cus_mux41_E1BEG3 (
    .A0(E1BEG3_input[0]),
    .A1(E1BEG3_input[1]),
    .A2(E1BEG3_input[2]),
    .A3(E1BEG3_input[3]),
    .S0(ConfigBits[22+0]),
    .S0N(ConfigBits_N[22+0]),
    .S1(ConfigBits[22+1]),
    .S1N(ConfigBits_N[22+1]),
    .X(E1BEG3)
);

 //switch matrix multiplexer E1BEG4 MUX-4
assign E1BEG4_input = {J_l_CD_END2,JN2END5,J2MID_CDb_END3,LG_O};
cus_mux41 inst_cus_mux41_E1BEG4 (
    .A0(E1BEG4_input[0]),
    .A1(E1BEG4_input[1]),
    .A2(E1BEG4_input[2]),
    .A3(E1BEG4_input[3]),
    .S0(ConfigBits[24+0]),
    .S0N(ConfigBits_N[24+0]),
    .S1(ConfigBits[24+1]),
    .S1N(ConfigBits_N[24+1]),
    .X(E1BEG4)
);

 //switch matrix multiplexer E1BEG5 MUX-4
assign E1BEG5_input = {J_l_EF_END3,JN2END7,J2MID_EFb_END0,LH_O};
cus_mux41 inst_cus_mux41_E1BEG5 (
    .A0(E1BEG5_input[0]),
    .A1(E1BEG5_input[1]),
    .A2(E1BEG5_input[2]),
    .A3(E1BEG5_input[3]),
    .S0(ConfigBits[26+0]),
    .S0N(ConfigBits_N[26+0]),
    .S1(ConfigBits[26+1]),
    .S1N(ConfigBits_N[26+1]),
    .X(E1BEG5)
);

 //switch matrix multiplexer E1BEG6 MUX-4
assign E1BEG6_input = {J_l_GH_END0,JN2END6,J2MID_GHb_END1,LA_O};
cus_mux41 inst_cus_mux41_E1BEG6 (
    .A0(E1BEG6_input[0]),
    .A1(E1BEG6_input[1]),
    .A2(E1BEG6_input[2]),
    .A3(E1BEG6_input[3]),
    .S0(ConfigBits[28+0]),
    .S0N(ConfigBits_N[28+0]),
    .S1(ConfigBits[28+1]),
    .S1N(ConfigBits_N[28+1]),
    .X(E1BEG6)
);

 //switch matrix multiplexer E1BEG7 MUX-4
assign E1BEG7_input = {J_l_AB_END1,JN2END4,J2MID_ABb_END2,LB_O};
cus_mux41 inst_cus_mux41_E1BEG7 (
    .A0(E1BEG7_input[0]),
    .A1(E1BEG7_input[1]),
    .A2(E1BEG7_input[2]),
    .A3(E1BEG7_input[3]),
    .S0(ConfigBits[30+0]),
    .S0N(ConfigBits_N[30+0]),
    .S1(ConfigBits[30+1]),
    .S1N(ConfigBits_N[30+1]),
    .X(E1BEG7)
);

 //switch matrix multiplexer E2BEG0 MUX-1
assign E2BEG0 = JE2END0;

 //switch matrix multiplexer E2BEG1 MUX-1
assign E2BEG1 = JE2END1;

 //switch matrix multiplexer E2BEG2 MUX-1
assign E2BEG2 = JE2END2;

 //switch matrix multiplexer E2BEG3 MUX-1
assign E2BEG3 = JE2END3;

 //switch matrix multiplexer E2BEG4 MUX-1
assign E2BEG4 = JE2END4;

 //switch matrix multiplexer E2BEG5 MUX-1
assign E2BEG5 = JE2END5;

 //switch matrix multiplexer E2BEG6 MUX-1
assign E2BEG6 = JE2END6;

 //switch matrix multiplexer E2BEG7 MUX-1
assign E2BEG7 = JE2END7;

 //switch matrix multiplexer E2BEGb0 MUX-1
assign E2BEGb0 = E2MID0;

 //switch matrix multiplexer E2BEGb1 MUX-1
assign E2BEGb1 = E2MID1;

 //switch matrix multiplexer E2BEGb2 MUX-1
assign E2BEGb2 = E2MID2;

 //switch matrix multiplexer E2BEGb3 MUX-1
assign E2BEGb3 = E2MID3;

 //switch matrix multiplexer E2BEGb4 MUX-1
assign E2BEGb4 = E2MID4;

 //switch matrix multiplexer E2BEGb5 MUX-1
assign E2BEGb5 = E2MID5;

 //switch matrix multiplexer E2BEGb6 MUX-1
assign E2BEGb6 = E2MID6;

 //switch matrix multiplexer E2BEGb7 MUX-1
assign E2BEGb7 = E2MID7;

 //switch matrix multiplexer S1BEG0 MUX-4
assign S1BEG0_input = {J_l_CD_END1,JE2END3,J2MID_CDb_END3,LE_O};
cus_mux41 inst_cus_mux41_S1BEG0 (
    .A0(S1BEG0_input[0]),
    .A1(S1BEG0_input[1]),
    .A2(S1BEG0_input[2]),
    .A3(S1BEG0_input[3]),
    .S0(ConfigBits[32+0]),
    .S0N(ConfigBits_N[32+0]),
    .S1(ConfigBits[32+1]),
    .S1N(ConfigBits_N[32+1]),
    .X(S1BEG0)
);

 //switch matrix multiplexer S1BEG1 MUX-4
assign S1BEG1_input = {J_l_EF_END2,JE2END0,J2MID_EFb_END0,LF_O};
cus_mux41 inst_cus_mux41_S1BEG1 (
    .A0(S1BEG1_input[0]),
    .A1(S1BEG1_input[1]),
    .A2(S1BEG1_input[2]),
    .A3(S1BEG1_input[3]),
    .S0(ConfigBits[34+0]),
    .S0N(ConfigBits_N[34+0]),
    .S1(ConfigBits[34+1]),
    .S1N(ConfigBits_N[34+1]),
    .X(S1BEG1)
);

 //switch matrix multiplexer S1BEG2 MUX-4
assign S1BEG2_input = {J_l_GH_END3,JE2END1,J2MID_GHb_END1,LG_O};
cus_mux41 inst_cus_mux41_S1BEG2 (
    .A0(S1BEG2_input[0]),
    .A1(S1BEG2_input[1]),
    .A2(S1BEG2_input[2]),
    .A3(S1BEG2_input[3]),
    .S0(ConfigBits[36+0]),
    .S0N(ConfigBits_N[36+0]),
    .S1(ConfigBits[36+1]),
    .S1N(ConfigBits_N[36+1]),
    .X(S1BEG2)
);

 //switch matrix multiplexer S1BEG3 MUX-4
assign S1BEG3_input = {J_l_AB_END0,JE2END2,J2MID_ABb_END2,LH_O};
cus_mux41 inst_cus_mux41_S1BEG3 (
    .A0(S1BEG3_input[0]),
    .A1(S1BEG3_input[1]),
    .A2(S1BEG3_input[2]),
    .A3(S1BEG3_input[3]),
    .S0(ConfigBits[38+0]),
    .S0N(ConfigBits_N[38+0]),
    .S1(ConfigBits[38+1]),
    .S1N(ConfigBits_N[38+1]),
    .X(S1BEG3)
);

 //switch matrix multiplexer S1BEG4 MUX-4
assign S1BEG4_input = {J_l_CD_END2,JE2END5,J2MID_CDb_END3,LG_O};
cus_mux41 inst_cus_mux41_S1BEG4 (
    .A0(S1BEG4_input[0]),
    .A1(S1BEG4_input[1]),
    .A2(S1BEG4_input[2]),
    .A3(S1BEG4_input[3]),
    .S0(ConfigBits[40+0]),
    .S0N(ConfigBits_N[40+0]),
    .S1(ConfigBits[40+1]),
    .S1N(ConfigBits_N[40+1]),
    .X(S1BEG4)
);

 //switch matrix multiplexer S1BEG5 MUX-4
assign S1BEG5_input = {J_l_EF_END3,JE2END7,J2MID_EFb_END0,LH_O};
cus_mux41 inst_cus_mux41_S1BEG5 (
    .A0(S1BEG5_input[0]),
    .A1(S1BEG5_input[1]),
    .A2(S1BEG5_input[2]),
    .A3(S1BEG5_input[3]),
    .S0(ConfigBits[42+0]),
    .S0N(ConfigBits_N[42+0]),
    .S1(ConfigBits[42+1]),
    .S1N(ConfigBits_N[42+1]),
    .X(S1BEG5)
);

 //switch matrix multiplexer S1BEG6 MUX-4
assign S1BEG6_input = {J_l_GH_END0,JE2END6,J2MID_GHb_END1,LA_O};
cus_mux41 inst_cus_mux41_S1BEG6 (
    .A0(S1BEG6_input[0]),
    .A1(S1BEG6_input[1]),
    .A2(S1BEG6_input[2]),
    .A3(S1BEG6_input[3]),
    .S0(ConfigBits[44+0]),
    .S0N(ConfigBits_N[44+0]),
    .S1(ConfigBits[44+1]),
    .S1N(ConfigBits_N[44+1]),
    .X(S1BEG6)
);

 //switch matrix multiplexer S1BEG7 MUX-4
assign S1BEG7_input = {J_l_AB_END1,JE2END4,J2MID_ABb_END2,LB_O};
cus_mux41 inst_cus_mux41_S1BEG7 (
    .A0(S1BEG7_input[0]),
    .A1(S1BEG7_input[1]),
    .A2(S1BEG7_input[2]),
    .A3(S1BEG7_input[3]),
    .S0(ConfigBits[46+0]),
    .S0N(ConfigBits_N[46+0]),
    .S1(ConfigBits[46+1]),
    .S1N(ConfigBits_N[46+1]),
    .X(S1BEG7)
);

 //switch matrix multiplexer S2BEG0 MUX-1
assign S2BEG0 = JS2END0;

 //switch matrix multiplexer S2BEG1 MUX-1
assign S2BEG1 = JS2END1;

 //switch matrix multiplexer S2BEG2 MUX-1
assign S2BEG2 = JS2END2;

 //switch matrix multiplexer S2BEG3 MUX-1
assign S2BEG3 = JS2END3;

 //switch matrix multiplexer S2BEG4 MUX-1
assign S2BEG4 = JS2END4;

 //switch matrix multiplexer S2BEG5 MUX-1
assign S2BEG5 = JS2END5;

 //switch matrix multiplexer S2BEG6 MUX-1
assign S2BEG6 = JS2END6;

 //switch matrix multiplexer S2BEG7 MUX-1
assign S2BEG7 = JS2END7;

 //switch matrix multiplexer S2BEGb0 MUX-1
assign S2BEGb0 = S2MID0;

 //switch matrix multiplexer S2BEGb1 MUX-1
assign S2BEGb1 = S2MID1;

 //switch matrix multiplexer S2BEGb2 MUX-1
assign S2BEGb2 = S2MID2;

 //switch matrix multiplexer S2BEGb3 MUX-1
assign S2BEGb3 = S2MID3;

 //switch matrix multiplexer S2BEGb4 MUX-1
assign S2BEGb4 = S2MID4;

 //switch matrix multiplexer S2BEGb5 MUX-1
assign S2BEGb5 = S2MID5;

 //switch matrix multiplexer S2BEGb6 MUX-1
assign S2BEGb6 = S2MID6;

 //switch matrix multiplexer S2BEGb7 MUX-1
assign S2BEGb7 = S2MID7;

 //switch matrix multiplexer W1BEG0 MUX-4
assign W1BEG0_input = {J_l_CD_END1,JS2END3,J2MID_CDb_END3,LF_O};
cus_mux41 inst_cus_mux41_W1BEG0 (
    .A0(W1BEG0_input[0]),
    .A1(W1BEG0_input[1]),
    .A2(W1BEG0_input[2]),
    .A3(W1BEG0_input[3]),
    .S0(ConfigBits[48+0]),
    .S0N(ConfigBits_N[48+0]),
    .S1(ConfigBits[48+1]),
    .S1N(ConfigBits_N[48+1]),
    .X(W1BEG0)
);

 //switch matrix multiplexer W1BEG1 MUX-4
assign W1BEG1_input = {J_l_EF_END2,JS2END0,J2MID_EFb_END0,LG_O};
cus_mux41 inst_cus_mux41_W1BEG1 (
    .A0(W1BEG1_input[0]),
    .A1(W1BEG1_input[1]),
    .A2(W1BEG1_input[2]),
    .A3(W1BEG1_input[3]),
    .S0(ConfigBits[50+0]),
    .S0N(ConfigBits_N[50+0]),
    .S1(ConfigBits[50+1]),
    .S1N(ConfigBits_N[50+1]),
    .X(W1BEG1)
);

 //switch matrix multiplexer W1BEG2 MUX-4
assign W1BEG2_input = {J_l_GH_END3,JS2END1,J2MID_GHb_END1,LH_O};
cus_mux41 inst_cus_mux41_W1BEG2 (
    .A0(W1BEG2_input[0]),
    .A1(W1BEG2_input[1]),
    .A2(W1BEG2_input[2]),
    .A3(W1BEG2_input[3]),
    .S0(ConfigBits[52+0]),
    .S0N(ConfigBits_N[52+0]),
    .S1(ConfigBits[52+1]),
    .S1N(ConfigBits_N[52+1]),
    .X(W1BEG2)
);

 //switch matrix multiplexer W1BEG3 MUX-4
assign W1BEG3_input = {J_l_AB_END0,JS2END2,J2MID_ABb_END2,LA_O};
cus_mux41 inst_cus_mux41_W1BEG3 (
    .A0(W1BEG3_input[0]),
    .A1(W1BEG3_input[1]),
    .A2(W1BEG3_input[2]),
    .A3(W1BEG3_input[3]),
    .S0(ConfigBits[54+0]),
    .S0N(ConfigBits_N[54+0]),
    .S1(ConfigBits[54+1]),
    .S1N(ConfigBits_N[54+1]),
    .X(W1BEG3)
);

 //switch matrix multiplexer W1BEG4 MUX-4
assign W1BEG4_input = {J_l_CD_END2,JS2END5,J2MID_CDb_END3,LG_O};
cus_mux41 inst_cus_mux41_W1BEG4 (
    .A0(W1BEG4_input[0]),
    .A1(W1BEG4_input[1]),
    .A2(W1BEG4_input[2]),
    .A3(W1BEG4_input[3]),
    .S0(ConfigBits[56+0]),
    .S0N(ConfigBits_N[56+0]),
    .S1(ConfigBits[56+1]),
    .S1N(ConfigBits_N[56+1]),
    .X(W1BEG4)
);

 //switch matrix multiplexer W1BEG5 MUX-4
assign W1BEG5_input = {J_l_EF_END3,JS2END7,J2MID_EFb_END0,LH_O};
cus_mux41 inst_cus_mux41_W1BEG5 (
    .A0(W1BEG5_input[0]),
    .A1(W1BEG5_input[1]),
    .A2(W1BEG5_input[2]),
    .A3(W1BEG5_input[3]),
    .S0(ConfigBits[58+0]),
    .S0N(ConfigBits_N[58+0]),
    .S1(ConfigBits[58+1]),
    .S1N(ConfigBits_N[58+1]),
    .X(W1BEG5)
);

 //switch matrix multiplexer W1BEG6 MUX-4
assign W1BEG6_input = {J_l_GH_END0,JS2END6,J2MID_GHb_END1,LA_O};
cus_mux41 inst_cus_mux41_W1BEG6 (
    .A0(W1BEG6_input[0]),
    .A1(W1BEG6_input[1]),
    .A2(W1BEG6_input[2]),
    .A3(W1BEG6_input[3]),
    .S0(ConfigBits[60+0]),
    .S0N(ConfigBits_N[60+0]),
    .S1(ConfigBits[60+1]),
    .S1N(ConfigBits_N[60+1]),
    .X(W1BEG6)
);

 //switch matrix multiplexer W1BEG7 MUX-4
assign W1BEG7_input = {J_l_AB_END1,JS2END4,J2MID_ABb_END2,LB_O};
cus_mux41 inst_cus_mux41_W1BEG7 (
    .A0(W1BEG7_input[0]),
    .A1(W1BEG7_input[1]),
    .A2(W1BEG7_input[2]),
    .A3(W1BEG7_input[3]),
    .S0(ConfigBits[62+0]),
    .S0N(ConfigBits_N[62+0]),
    .S1(ConfigBits[62+1]),
    .S1N(ConfigBits_N[62+1]),
    .X(W1BEG7)
);

 //switch matrix multiplexer W2BEG0 MUX-1
assign W2BEG0 = JW2END0;

 //switch matrix multiplexer W2BEG1 MUX-1
assign W2BEG1 = JW2END1;

 //switch matrix multiplexer W2BEG2 MUX-1
assign W2BEG2 = JW2END2;

 //switch matrix multiplexer W2BEG3 MUX-1
assign W2BEG3 = JW2END3;

 //switch matrix multiplexer W2BEG4 MUX-1
assign W2BEG4 = JW2END4;

 //switch matrix multiplexer W2BEG5 MUX-1
assign W2BEG5 = JW2END5;

 //switch matrix multiplexer W2BEG6 MUX-1
assign W2BEG6 = JW2END6;

 //switch matrix multiplexer W2BEG7 MUX-1
assign W2BEG7 = JW2END7;

 //switch matrix multiplexer W2BEGb0 MUX-1
assign W2BEGb0 = W2MID0;

 //switch matrix multiplexer W2BEGb1 MUX-1
assign W2BEGb1 = W2MID1;

 //switch matrix multiplexer W2BEGb2 MUX-1
assign W2BEGb2 = W2MID2;

 //switch matrix multiplexer W2BEGb3 MUX-1
assign W2BEGb3 = W2MID3;

 //switch matrix multiplexer W2BEGb4 MUX-1
assign W2BEGb4 = W2MID4;

 //switch matrix multiplexer W2BEGb5 MUX-1
assign W2BEGb5 = W2MID5;

 //switch matrix multiplexer W2BEGb6 MUX-1
assign W2BEGb6 = W2MID6;

 //switch matrix multiplexer W2BEGb7 MUX-1
assign W2BEGb7 = W2MID7;

 //switch matrix multiplexer CO0 MUX-1
assign CO0 = LH_Co;

 //switch matrix multiplexer LA_I0 MUX-4
assign LA_I0_input = {J_l_AB_END0,J2END_AB_END0,J2MID_ABb_END0,J2MID_ABa_END0};
cus_mux41 inst_cus_mux41_LA_I0 (
    .A0(LA_I0_input[0]),
    .A1(LA_I0_input[1]),
    .A2(LA_I0_input[2]),
    .A3(LA_I0_input[3]),
    .S0(ConfigBits[64+0]),
    .S0N(ConfigBits_N[64+0]),
    .S1(ConfigBits[64+1]),
    .S1N(ConfigBits_N[64+1]),
    .X(LA_I0)
);

 //switch matrix multiplexer LA_I1 MUX-4
assign LA_I1_input = {J_l_AB_END1,J2END_AB_END1,J2MID_ABb_END1,J2MID_ABa_END1};
cus_mux41 inst_cus_mux41_LA_I1 (
    .A0(LA_I1_input[0]),
    .A1(LA_I1_input[1]),
    .A2(LA_I1_input[2]),
    .A3(LA_I1_input[3]),
    .S0(ConfigBits[66+0]),
    .S0N(ConfigBits_N[66+0]),
    .S1(ConfigBits[66+1]),
    .S1N(ConfigBits_N[66+1]),
    .X(LA_I1)
);

 //switch matrix multiplexer LA_I2 MUX-4
assign LA_I2_input = {J_l_AB_END2,J2END_AB_END2,J2MID_ABb_END2,J2MID_ABa_END2};
cus_mux41 inst_cus_mux41_LA_I2 (
    .A0(LA_I2_input[0]),
    .A1(LA_I2_input[1]),
    .A2(LA_I2_input[2]),
    .A3(LA_I2_input[3]),
    .S0(ConfigBits[68+0]),
    .S0N(ConfigBits_N[68+0]),
    .S1(ConfigBits[68+1]),
    .S1N(ConfigBits_N[68+1]),
    .X(LA_I2)
);

 //switch matrix multiplexer LA_I3 MUX-4
assign LA_I3_input = {J_l_AB_END3,J2END_AB_END3,J2MID_ABb_END3,J2MID_ABa_END3};
cus_mux41 inst_cus_mux41_LA_I3 (
    .A0(LA_I3_input[0]),
    .A1(LA_I3_input[1]),
    .A2(LA_I3_input[2]),
    .A3(LA_I3_input[3]),
    .S0(ConfigBits[70+0]),
    .S0N(ConfigBits_N[70+0]),
    .S1(ConfigBits[70+1]),
    .S1N(ConfigBits_N[70+1]),
    .X(LA_I3)
);

 //switch matrix multiplexer LA_Ci MUX-1
assign LA_Ci = CI0;

 //switch matrix multiplexer LA_SR MUX-2
assign LA_SR_input = {J_SR_END0,GND0};
cus_mux21 inst_cus_mux21_LA_SR (
    .A0(LA_SR_input[0]),
    .A1(LA_SR_input[1]),
    .S(ConfigBits[72+0]),
    .X(LA_SR)
);

 //switch matrix multiplexer LA_EN MUX-2
assign LA_EN_input = {J_EN_END0,VCC0};
cus_mux21 inst_cus_mux21_LA_EN (
    .A0(LA_EN_input[0]),
    .A1(LA_EN_input[1]),
    .S(ConfigBits[73+0]),
    .X(LA_EN)
);

 //switch matrix multiplexer LA_CLK MUX-1
assign LA_CLK = GCLK_END0;

 //switch matrix multiplexer LB_I0 MUX-4
assign LB_I0_input = {J_l_AB_END0,J2END_AB_END0,J2MID_ABb_END0,J2MID_ABa_END0};
cus_mux41 inst_cus_mux41_LB_I0 (
    .A0(LB_I0_input[0]),
    .A1(LB_I0_input[1]),
    .A2(LB_I0_input[2]),
    .A3(LB_I0_input[3]),
    .S0(ConfigBits[74+0]),
    .S0N(ConfigBits_N[74+0]),
    .S1(ConfigBits[74+1]),
    .S1N(ConfigBits_N[74+1]),
    .X(LB_I0)
);

 //switch matrix multiplexer LB_I1 MUX-4
assign LB_I1_input = {J_l_AB_END1,J2END_AB_END1,J2MID_ABb_END1,J2MID_ABa_END1};
cus_mux41 inst_cus_mux41_LB_I1 (
    .A0(LB_I1_input[0]),
    .A1(LB_I1_input[1]),
    .A2(LB_I1_input[2]),
    .A3(LB_I1_input[3]),
    .S0(ConfigBits[76+0]),
    .S0N(ConfigBits_N[76+0]),
    .S1(ConfigBits[76+1]),
    .S1N(ConfigBits_N[76+1]),
    .X(LB_I1)
);

 //switch matrix multiplexer LB_I2 MUX-4
assign LB_I2_input = {J_l_AB_END2,J2END_AB_END2,J2MID_ABb_END2,J2MID_ABa_END2};
cus_mux41 inst_cus_mux41_LB_I2 (
    .A0(LB_I2_input[0]),
    .A1(LB_I2_input[1]),
    .A2(LB_I2_input[2]),
    .A3(LB_I2_input[3]),
    .S0(ConfigBits[78+0]),
    .S0N(ConfigBits_N[78+0]),
    .S1(ConfigBits[78+1]),
    .S1N(ConfigBits_N[78+1]),
    .X(LB_I2)
);

 //switch matrix multiplexer LB_I3 MUX-4
assign LB_I3_input = {J_l_AB_END3,J2END_AB_END3,J2MID_ABb_END3,J2MID_ABa_END3};
cus_mux41 inst_cus_mux41_LB_I3 (
    .A0(LB_I3_input[0]),
    .A1(LB_I3_input[1]),
    .A2(LB_I3_input[2]),
    .A3(LB_I3_input[3]),
    .S0(ConfigBits[80+0]),
    .S0N(ConfigBits_N[80+0]),
    .S1(ConfigBits[80+1]),
    .S1N(ConfigBits_N[80+1]),
    .X(LB_I3)
);

 //switch matrix multiplexer LB_Ci MUX-1
assign LB_Ci = LA_Co;

 //switch matrix multiplexer LB_SR MUX-2
assign LB_SR_input = {J_SR_END0,GND0};
cus_mux21 inst_cus_mux21_LB_SR (
    .A0(LB_SR_input[0]),
    .A1(LB_SR_input[1]),
    .S(ConfigBits[82+0]),
    .X(LB_SR)
);

 //switch matrix multiplexer LB_EN MUX-2
assign LB_EN_input = {J_EN_END0,VCC0};
cus_mux21 inst_cus_mux21_LB_EN (
    .A0(LB_EN_input[0]),
    .A1(LB_EN_input[1]),
    .S(ConfigBits[83+0]),
    .X(LB_EN)
);

 //switch matrix multiplexer LB_CLK MUX-1
assign LB_CLK = GCLK_END0;

 //switch matrix multiplexer LC_I0 MUX-4
assign LC_I0_input = {J_l_CD_END0,J2END_CD_END0,J2MID_CDb_END0,J2MID_CDa_END0};
cus_mux41 inst_cus_mux41_LC_I0 (
    .A0(LC_I0_input[0]),
    .A1(LC_I0_input[1]),
    .A2(LC_I0_input[2]),
    .A3(LC_I0_input[3]),
    .S0(ConfigBits[84+0]),
    .S0N(ConfigBits_N[84+0]),
    .S1(ConfigBits[84+1]),
    .S1N(ConfigBits_N[84+1]),
    .X(LC_I0)
);

 //switch matrix multiplexer LC_I1 MUX-4
assign LC_I1_input = {J_l_CD_END1,J2END_CD_END1,J2MID_CDb_END1,J2MID_CDa_END1};
cus_mux41 inst_cus_mux41_LC_I1 (
    .A0(LC_I1_input[0]),
    .A1(LC_I1_input[1]),
    .A2(LC_I1_input[2]),
    .A3(LC_I1_input[3]),
    .S0(ConfigBits[86+0]),
    .S0N(ConfigBits_N[86+0]),
    .S1(ConfigBits[86+1]),
    .S1N(ConfigBits_N[86+1]),
    .X(LC_I1)
);

 //switch matrix multiplexer LC_I2 MUX-4
assign LC_I2_input = {J_l_CD_END2,J2END_CD_END2,J2MID_CDb_END2,J2MID_CDa_END2};
cus_mux41 inst_cus_mux41_LC_I2 (
    .A0(LC_I2_input[0]),
    .A1(LC_I2_input[1]),
    .A2(LC_I2_input[2]),
    .A3(LC_I2_input[3]),
    .S0(ConfigBits[88+0]),
    .S0N(ConfigBits_N[88+0]),
    .S1(ConfigBits[88+1]),
    .S1N(ConfigBits_N[88+1]),
    .X(LC_I2)
);

 //switch matrix multiplexer LC_I3 MUX-4
assign LC_I3_input = {J_l_CD_END3,J2END_CD_END3,J2MID_CDb_END3,J2MID_CDa_END3};
cus_mux41 inst_cus_mux41_LC_I3 (
    .A0(LC_I3_input[0]),
    .A1(LC_I3_input[1]),
    .A2(LC_I3_input[2]),
    .A3(LC_I3_input[3]),
    .S0(ConfigBits[90+0]),
    .S0N(ConfigBits_N[90+0]),
    .S1(ConfigBits[90+1]),
    .S1N(ConfigBits_N[90+1]),
    .X(LC_I3)
);

 //switch matrix multiplexer LC_Ci MUX-1
assign LC_Ci = LB_Co;

 //switch matrix multiplexer LC_SR MUX-2
assign LC_SR_input = {J_SR_END0,GND0};
cus_mux21 inst_cus_mux21_LC_SR (
    .A0(LC_SR_input[0]),
    .A1(LC_SR_input[1]),
    .S(ConfigBits[92+0]),
    .X(LC_SR)
);

 //switch matrix multiplexer LC_EN MUX-2
assign LC_EN_input = {J_EN_END0,VCC0};
cus_mux21 inst_cus_mux21_LC_EN (
    .A0(LC_EN_input[0]),
    .A1(LC_EN_input[1]),
    .S(ConfigBits[93+0]),
    .X(LC_EN)
);

 //switch matrix multiplexer LC_CLK MUX-1
assign LC_CLK = GCLK_END0;

 //switch matrix multiplexer LD_I0 MUX-4
assign LD_I0_input = {J_l_CD_END0,J2END_CD_END0,J2MID_CDb_END0,J2MID_CDa_END0};
cus_mux41 inst_cus_mux41_LD_I0 (
    .A0(LD_I0_input[0]),
    .A1(LD_I0_input[1]),
    .A2(LD_I0_input[2]),
    .A3(LD_I0_input[3]),
    .S0(ConfigBits[94+0]),
    .S0N(ConfigBits_N[94+0]),
    .S1(ConfigBits[94+1]),
    .S1N(ConfigBits_N[94+1]),
    .X(LD_I0)
);

 //switch matrix multiplexer LD_I1 MUX-4
assign LD_I1_input = {J_l_CD_END1,J2END_CD_END1,J2MID_CDb_END1,J2MID_CDa_END1};
cus_mux41 inst_cus_mux41_LD_I1 (
    .A0(LD_I1_input[0]),
    .A1(LD_I1_input[1]),
    .A2(LD_I1_input[2]),
    .A3(LD_I1_input[3]),
    .S0(ConfigBits[96+0]),
    .S0N(ConfigBits_N[96+0]),
    .S1(ConfigBits[96+1]),
    .S1N(ConfigBits_N[96+1]),
    .X(LD_I1)
);

 //switch matrix multiplexer LD_I2 MUX-4
assign LD_I2_input = {J_l_CD_END2,J2END_CD_END2,J2MID_CDb_END2,J2MID_CDa_END2};
cus_mux41 inst_cus_mux41_LD_I2 (
    .A0(LD_I2_input[0]),
    .A1(LD_I2_input[1]),
    .A2(LD_I2_input[2]),
    .A3(LD_I2_input[3]),
    .S0(ConfigBits[98+0]),
    .S0N(ConfigBits_N[98+0]),
    .S1(ConfigBits[98+1]),
    .S1N(ConfigBits_N[98+1]),
    .X(LD_I2)
);

 //switch matrix multiplexer LD_I3 MUX-4
assign LD_I3_input = {J_l_CD_END3,J2END_CD_END3,J2MID_CDb_END3,J2MID_CDa_END3};
cus_mux41 inst_cus_mux41_LD_I3 (
    .A0(LD_I3_input[0]),
    .A1(LD_I3_input[1]),
    .A2(LD_I3_input[2]),
    .A3(LD_I3_input[3]),
    .S0(ConfigBits[100+0]),
    .S0N(ConfigBits_N[100+0]),
    .S1(ConfigBits[100+1]),
    .S1N(ConfigBits_N[100+1]),
    .X(LD_I3)
);

 //switch matrix multiplexer LD_Ci MUX-1
assign LD_Ci = LC_Co;

 //switch matrix multiplexer LD_SR MUX-2
assign LD_SR_input = {J_SR_END0,GND0};
cus_mux21 inst_cus_mux21_LD_SR (
    .A0(LD_SR_input[0]),
    .A1(LD_SR_input[1]),
    .S(ConfigBits[102+0]),
    .X(LD_SR)
);

 //switch matrix multiplexer LD_EN MUX-2
assign LD_EN_input = {J_EN_END0,VCC0};
cus_mux21 inst_cus_mux21_LD_EN (
    .A0(LD_EN_input[0]),
    .A1(LD_EN_input[1]),
    .S(ConfigBits[103+0]),
    .X(LD_EN)
);

 //switch matrix multiplexer LD_CLK MUX-1
assign LD_CLK = GCLK_END0;

 //switch matrix multiplexer LE_I0 MUX-4
assign LE_I0_input = {J_l_EF_END0,J2END_EF_END0,J2MID_EFb_END0,J2MID_EFa_END0};
cus_mux41 inst_cus_mux41_LE_I0 (
    .A0(LE_I0_input[0]),
    .A1(LE_I0_input[1]),
    .A2(LE_I0_input[2]),
    .A3(LE_I0_input[3]),
    .S0(ConfigBits[104+0]),
    .S0N(ConfigBits_N[104+0]),
    .S1(ConfigBits[104+1]),
    .S1N(ConfigBits_N[104+1]),
    .X(LE_I0)
);

 //switch matrix multiplexer LE_I1 MUX-4
assign LE_I1_input = {J_l_EF_END1,J2END_EF_END1,J2MID_EFb_END1,J2MID_EFa_END1};
cus_mux41 inst_cus_mux41_LE_I1 (
    .A0(LE_I1_input[0]),
    .A1(LE_I1_input[1]),
    .A2(LE_I1_input[2]),
    .A3(LE_I1_input[3]),
    .S0(ConfigBits[106+0]),
    .S0N(ConfigBits_N[106+0]),
    .S1(ConfigBits[106+1]),
    .S1N(ConfigBits_N[106+1]),
    .X(LE_I1)
);

 //switch matrix multiplexer LE_I2 MUX-4
assign LE_I2_input = {J_l_EF_END2,J2END_EF_END2,J2MID_EFb_END2,J2MID_EFa_END2};
cus_mux41 inst_cus_mux41_LE_I2 (
    .A0(LE_I2_input[0]),
    .A1(LE_I2_input[1]),
    .A2(LE_I2_input[2]),
    .A3(LE_I2_input[3]),
    .S0(ConfigBits[108+0]),
    .S0N(ConfigBits_N[108+0]),
    .S1(ConfigBits[108+1]),
    .S1N(ConfigBits_N[108+1]),
    .X(LE_I2)
);

 //switch matrix multiplexer LE_I3 MUX-4
assign LE_I3_input = {J_l_EF_END3,J2END_EF_END3,J2MID_EFb_END3,J2MID_EFa_END3};
cus_mux41 inst_cus_mux41_LE_I3 (
    .A0(LE_I3_input[0]),
    .A1(LE_I3_input[1]),
    .A2(LE_I3_input[2]),
    .A3(LE_I3_input[3]),
    .S0(ConfigBits[110+0]),
    .S0N(ConfigBits_N[110+0]),
    .S1(ConfigBits[110+1]),
    .S1N(ConfigBits_N[110+1]),
    .X(LE_I3)
);

 //switch matrix multiplexer LE_Ci MUX-1
assign LE_Ci = LD_Co;

 //switch matrix multiplexer LE_SR MUX-2
assign LE_SR_input = {J_SR_END0,GND0};
cus_mux21 inst_cus_mux21_LE_SR (
    .A0(LE_SR_input[0]),
    .A1(LE_SR_input[1]),
    .S(ConfigBits[112+0]),
    .X(LE_SR)
);

 //switch matrix multiplexer LE_EN MUX-2
assign LE_EN_input = {J_EN_END0,VCC0};
cus_mux21 inst_cus_mux21_LE_EN (
    .A0(LE_EN_input[0]),
    .A1(LE_EN_input[1]),
    .S(ConfigBits[113+0]),
    .X(LE_EN)
);

 //switch matrix multiplexer LE_CLK MUX-1
assign LE_CLK = GCLK_END0;

 //switch matrix multiplexer LF_I0 MUX-4
assign LF_I0_input = {J_l_EF_END0,J2END_EF_END0,J2MID_EFb_END0,J2MID_EFa_END0};
cus_mux41 inst_cus_mux41_LF_I0 (
    .A0(LF_I0_input[0]),
    .A1(LF_I0_input[1]),
    .A2(LF_I0_input[2]),
    .A3(LF_I0_input[3]),
    .S0(ConfigBits[114+0]),
    .S0N(ConfigBits_N[114+0]),
    .S1(ConfigBits[114+1]),
    .S1N(ConfigBits_N[114+1]),
    .X(LF_I0)
);

 //switch matrix multiplexer LF_I1 MUX-4
assign LF_I1_input = {J_l_EF_END1,J2END_EF_END1,J2MID_EFb_END1,J2MID_EFa_END1};
cus_mux41 inst_cus_mux41_LF_I1 (
    .A0(LF_I1_input[0]),
    .A1(LF_I1_input[1]),
    .A2(LF_I1_input[2]),
    .A3(LF_I1_input[3]),
    .S0(ConfigBits[116+0]),
    .S0N(ConfigBits_N[116+0]),
    .S1(ConfigBits[116+1]),
    .S1N(ConfigBits_N[116+1]),
    .X(LF_I1)
);

 //switch matrix multiplexer LF_I2 MUX-4
assign LF_I2_input = {J_l_EF_END2,J2END_EF_END2,J2MID_EFb_END2,J2MID_EFa_END2};
cus_mux41 inst_cus_mux41_LF_I2 (
    .A0(LF_I2_input[0]),
    .A1(LF_I2_input[1]),
    .A2(LF_I2_input[2]),
    .A3(LF_I2_input[3]),
    .S0(ConfigBits[118+0]),
    .S0N(ConfigBits_N[118+0]),
    .S1(ConfigBits[118+1]),
    .S1N(ConfigBits_N[118+1]),
    .X(LF_I2)
);

 //switch matrix multiplexer LF_I3 MUX-4
assign LF_I3_input = {J_l_EF_END3,J2END_EF_END3,J2MID_EFb_END3,J2MID_EFa_END3};
cus_mux41 inst_cus_mux41_LF_I3 (
    .A0(LF_I3_input[0]),
    .A1(LF_I3_input[1]),
    .A2(LF_I3_input[2]),
    .A3(LF_I3_input[3]),
    .S0(ConfigBits[120+0]),
    .S0N(ConfigBits_N[120+0]),
    .S1(ConfigBits[120+1]),
    .S1N(ConfigBits_N[120+1]),
    .X(LF_I3)
);

 //switch matrix multiplexer LF_Ci MUX-1
assign LF_Ci = LE_Co;

 //switch matrix multiplexer LF_SR MUX-2
assign LF_SR_input = {J_SR_END0,GND0};
cus_mux21 inst_cus_mux21_LF_SR (
    .A0(LF_SR_input[0]),
    .A1(LF_SR_input[1]),
    .S(ConfigBits[122+0]),
    .X(LF_SR)
);

 //switch matrix multiplexer LF_EN MUX-2
assign LF_EN_input = {J_EN_END0,VCC0};
cus_mux21 inst_cus_mux21_LF_EN (
    .A0(LF_EN_input[0]),
    .A1(LF_EN_input[1]),
    .S(ConfigBits[123+0]),
    .X(LF_EN)
);

 //switch matrix multiplexer LF_CLK MUX-1
assign LF_CLK = GCLK_END0;

 //switch matrix multiplexer LG_I0 MUX-4
assign LG_I0_input = {J_l_GH_END0,J2END_GH_END0,J2MID_GHb_END0,J2MID_GHa_END0};
cus_mux41 inst_cus_mux41_LG_I0 (
    .A0(LG_I0_input[0]),
    .A1(LG_I0_input[1]),
    .A2(LG_I0_input[2]),
    .A3(LG_I0_input[3]),
    .S0(ConfigBits[124+0]),
    .S0N(ConfigBits_N[124+0]),
    .S1(ConfigBits[124+1]),
    .S1N(ConfigBits_N[124+1]),
    .X(LG_I0)
);

 //switch matrix multiplexer LG_I1 MUX-4
assign LG_I1_input = {J_l_GH_END1,J2END_GH_END1,J2MID_GHb_END1,J2MID_GHa_END1};
cus_mux41 inst_cus_mux41_LG_I1 (
    .A0(LG_I1_input[0]),
    .A1(LG_I1_input[1]),
    .A2(LG_I1_input[2]),
    .A3(LG_I1_input[3]),
    .S0(ConfigBits[126+0]),
    .S0N(ConfigBits_N[126+0]),
    .S1(ConfigBits[126+1]),
    .S1N(ConfigBits_N[126+1]),
    .X(LG_I1)
);

 //switch matrix multiplexer LG_I2 MUX-4
assign LG_I2_input = {J_l_GH_END2,J2END_GH_END2,J2MID_GHb_END2,J2MID_GHa_END2};
cus_mux41 inst_cus_mux41_LG_I2 (
    .A0(LG_I2_input[0]),
    .A1(LG_I2_input[1]),
    .A2(LG_I2_input[2]),
    .A3(LG_I2_input[3]),
    .S0(ConfigBits[128+0]),
    .S0N(ConfigBits_N[128+0]),
    .S1(ConfigBits[128+1]),
    .S1N(ConfigBits_N[128+1]),
    .X(LG_I2)
);

 //switch matrix multiplexer LG_I3 MUX-4
assign LG_I3_input = {J_l_GH_END3,J2END_GH_END3,J2MID_GHb_END3,J2MID_GHa_END3};
cus_mux41 inst_cus_mux41_LG_I3 (
    .A0(LG_I3_input[0]),
    .A1(LG_I3_input[1]),
    .A2(LG_I3_input[2]),
    .A3(LG_I3_input[3]),
    .S0(ConfigBits[130+0]),
    .S0N(ConfigBits_N[130+0]),
    .S1(ConfigBits[130+1]),
    .S1N(ConfigBits_N[130+1]),
    .X(LG_I3)
);

 //switch matrix multiplexer LG_Ci MUX-1
assign LG_Ci = LF_Co;

 //switch matrix multiplexer LG_SR MUX-2
assign LG_SR_input = {J_SR_END0,GND0};
cus_mux21 inst_cus_mux21_LG_SR (
    .A0(LG_SR_input[0]),
    .A1(LG_SR_input[1]),
    .S(ConfigBits[132+0]),
    .X(LG_SR)
);

 //switch matrix multiplexer LG_EN MUX-2
assign LG_EN_input = {J_EN_END0,VCC0};
cus_mux21 inst_cus_mux21_LG_EN (
    .A0(LG_EN_input[0]),
    .A1(LG_EN_input[1]),
    .S(ConfigBits[133+0]),
    .X(LG_EN)
);

 //switch matrix multiplexer LG_CLK MUX-1
assign LG_CLK = GCLK_END0;

 //switch matrix multiplexer LH_I0 MUX-4
assign LH_I0_input = {J_l_GH_END0,J2END_GH_END0,J2MID_GHb_END0,J2MID_GHa_END0};
cus_mux41 inst_cus_mux41_LH_I0 (
    .A0(LH_I0_input[0]),
    .A1(LH_I0_input[1]),
    .A2(LH_I0_input[2]),
    .A3(LH_I0_input[3]),
    .S0(ConfigBits[134+0]),
    .S0N(ConfigBits_N[134+0]),
    .S1(ConfigBits[134+1]),
    .S1N(ConfigBits_N[134+1]),
    .X(LH_I0)
);

 //switch matrix multiplexer LH_I1 MUX-4
assign LH_I1_input = {J_l_GH_END1,J2END_GH_END1,J2MID_GHb_END1,J2MID_GHa_END1};
cus_mux41 inst_cus_mux41_LH_I1 (
    .A0(LH_I1_input[0]),
    .A1(LH_I1_input[1]),
    .A2(LH_I1_input[2]),
    .A3(LH_I1_input[3]),
    .S0(ConfigBits[136+0]),
    .S0N(ConfigBits_N[136+0]),
    .S1(ConfigBits[136+1]),
    .S1N(ConfigBits_N[136+1]),
    .X(LH_I1)
);

 //switch matrix multiplexer LH_I2 MUX-4
assign LH_I2_input = {J_l_GH_END2,J2END_GH_END2,J2MID_GHb_END2,J2MID_GHa_END2};
cus_mux41 inst_cus_mux41_LH_I2 (
    .A0(LH_I2_input[0]),
    .A1(LH_I2_input[1]),
    .A2(LH_I2_input[2]),
    .A3(LH_I2_input[3]),
    .S0(ConfigBits[138+0]),
    .S0N(ConfigBits_N[138+0]),
    .S1(ConfigBits[138+1]),
    .S1N(ConfigBits_N[138+1]),
    .X(LH_I2)
);

 //switch matrix multiplexer LH_I3 MUX-4
assign LH_I3_input = {J_l_GH_END3,J2END_GH_END3,J2MID_GHb_END3,J2MID_GHa_END3};
cus_mux41 inst_cus_mux41_LH_I3 (
    .A0(LH_I3_input[0]),
    .A1(LH_I3_input[1]),
    .A2(LH_I3_input[2]),
    .A3(LH_I3_input[3]),
    .S0(ConfigBits[140+0]),
    .S0N(ConfigBits_N[140+0]),
    .S1(ConfigBits[140+1]),
    .S1N(ConfigBits_N[140+1]),
    .X(LH_I3)
);

 //switch matrix multiplexer LH_Ci MUX-1
assign LH_Ci = LG_Co;

 //switch matrix multiplexer LH_SR MUX-2
assign LH_SR_input = {J_SR_END0,GND0};
cus_mux21 inst_cus_mux21_LH_SR (
    .A0(LH_SR_input[0]),
    .A1(LH_SR_input[1]),
    .S(ConfigBits[142+0]),
    .X(LH_SR)
);

 //switch matrix multiplexer LH_EN MUX-2
assign LH_EN_input = {J_EN_END0,VCC0};
cus_mux21 inst_cus_mux21_LH_EN (
    .A0(LH_EN_input[0]),
    .A1(LH_EN_input[1]),
    .S(ConfigBits[143+0]),
    .X(LH_EN)
);

 //switch matrix multiplexer LH_CLK MUX-1
assign LH_CLK = GCLK_END0;

 //switch matrix multiplexer J2MID_ABa_BEG0 MUX-4
assign J2MID_ABa_BEG0_input = {JN2END3,W2MID6,S2MID6,N2MID6};
cus_mux41 inst_cus_mux41_J2MID_ABa_BEG0 (
    .A0(J2MID_ABa_BEG0_input[0]),
    .A1(J2MID_ABa_BEG0_input[1]),
    .A2(J2MID_ABa_BEG0_input[2]),
    .A3(J2MID_ABa_BEG0_input[3]),
    .S0(ConfigBits[144+0]),
    .S0N(ConfigBits_N[144+0]),
    .S1(ConfigBits[144+1]),
    .S1N(ConfigBits_N[144+1]),
    .X(J2MID_ABa_BEG0)
);

 //switch matrix multiplexer J2MID_ABa_BEG1 MUX-4
assign J2MID_ABa_BEG1_input = {JE2END3,W2MID2,S2MID2,E2MID2};
cus_mux41 inst_cus_mux41_J2MID_ABa_BEG1 (
    .A0(J2MID_ABa_BEG1_input[0]),
    .A1(J2MID_ABa_BEG1_input[1]),
    .A2(J2MID_ABa_BEG1_input[2]),
    .A3(J2MID_ABa_BEG1_input[3]),
    .S0(ConfigBits[146+0]),
    .S0N(ConfigBits_N[146+0]),
    .S1(ConfigBits[146+1]),
    .S1N(ConfigBits_N[146+1]),
    .X(J2MID_ABa_BEG1)
);

 //switch matrix multiplexer J2MID_ABa_BEG2 MUX-4
assign J2MID_ABa_BEG2_input = {JS2END3,W2MID4,E2MID4,N2MID4};
cus_mux41 inst_cus_mux41_J2MID_ABa_BEG2 (
    .A0(J2MID_ABa_BEG2_input[0]),
    .A1(J2MID_ABa_BEG2_input[1]),
    .A2(J2MID_ABa_BEG2_input[2]),
    .A3(J2MID_ABa_BEG2_input[3]),
    .S0(ConfigBits[148+0]),
    .S0N(ConfigBits_N[148+0]),
    .S1(ConfigBits[148+1]),
    .S1N(ConfigBits_N[148+1]),
    .X(J2MID_ABa_BEG2)
);

 //switch matrix multiplexer J2MID_ABa_BEG3 MUX-4
assign J2MID_ABa_BEG3_input = {JW2END3,S2MID0,E2MID0,N2MID0};
cus_mux41 inst_cus_mux41_J2MID_ABa_BEG3 (
    .A0(J2MID_ABa_BEG3_input[0]),
    .A1(J2MID_ABa_BEG3_input[1]),
    .A2(J2MID_ABa_BEG3_input[2]),
    .A3(J2MID_ABa_BEG3_input[3]),
    .S0(ConfigBits[150+0]),
    .S0N(ConfigBits_N[150+0]),
    .S1(ConfigBits[150+1]),
    .S1N(ConfigBits_N[150+1]),
    .X(J2MID_ABa_BEG3)
);

 //switch matrix multiplexer J2MID_CDa_BEG0 MUX-4
assign J2MID_CDa_BEG0_input = {JN2END4,W2MID6,S2MID6,E2MID6};
cus_mux41 inst_cus_mux41_J2MID_CDa_BEG0 (
    .A0(J2MID_CDa_BEG0_input[0]),
    .A1(J2MID_CDa_BEG0_input[1]),
    .A2(J2MID_CDa_BEG0_input[2]),
    .A3(J2MID_CDa_BEG0_input[3]),
    .S0(ConfigBits[152+0]),
    .S0N(ConfigBits_N[152+0]),
    .S1(ConfigBits[152+1]),
    .S1N(ConfigBits_N[152+1]),
    .X(J2MID_CDa_BEG0)
);

 //switch matrix multiplexer J2MID_CDa_BEG1 MUX-4
assign J2MID_CDa_BEG1_input = {JE2END4,W2MID2,E2MID2,N2MID2};
cus_mux41 inst_cus_mux41_J2MID_CDa_BEG1 (
    .A0(J2MID_CDa_BEG1_input[0]),
    .A1(J2MID_CDa_BEG1_input[1]),
    .A2(J2MID_CDa_BEG1_input[2]),
    .A3(J2MID_CDa_BEG1_input[3]),
    .S0(ConfigBits[154+0]),
    .S0N(ConfigBits_N[154+0]),
    .S1(ConfigBits[154+1]),
    .S1N(ConfigBits_N[154+1]),
    .X(J2MID_CDa_BEG1)
);

 //switch matrix multiplexer J2MID_CDa_BEG2 MUX-4
assign J2MID_CDa_BEG2_input = {JS2END4,S2MID4,E2MID4,N2MID4};
cus_mux41 inst_cus_mux41_J2MID_CDa_BEG2 (
    .A0(J2MID_CDa_BEG2_input[0]),
    .A1(J2MID_CDa_BEG2_input[1]),
    .A2(J2MID_CDa_BEG2_input[2]),
    .A3(J2MID_CDa_BEG2_input[3]),
    .S0(ConfigBits[156+0]),
    .S0N(ConfigBits_N[156+0]),
    .S1(ConfigBits[156+1]),
    .S1N(ConfigBits_N[156+1]),
    .X(J2MID_CDa_BEG2)
);

 //switch matrix multiplexer J2MID_CDa_BEG3 MUX-4
assign J2MID_CDa_BEG3_input = {JW2END4,W2MID0,S2MID0,N2MID0};
cus_mux41 inst_cus_mux41_J2MID_CDa_BEG3 (
    .A0(J2MID_CDa_BEG3_input[0]),
    .A1(J2MID_CDa_BEG3_input[1]),
    .A2(J2MID_CDa_BEG3_input[2]),
    .A3(J2MID_CDa_BEG3_input[3]),
    .S0(ConfigBits[158+0]),
    .S0N(ConfigBits_N[158+0]),
    .S1(ConfigBits[158+1]),
    .S1N(ConfigBits_N[158+1]),
    .X(J2MID_CDa_BEG3)
);

 //switch matrix multiplexer J2MID_EFa_BEG0 MUX-4
assign J2MID_EFa_BEG0_input = {JN2END5,W2MID6,E2MID6,N2MID6};
cus_mux41 inst_cus_mux41_J2MID_EFa_BEG0 (
    .A0(J2MID_EFa_BEG0_input[0]),
    .A1(J2MID_EFa_BEG0_input[1]),
    .A2(J2MID_EFa_BEG0_input[2]),
    .A3(J2MID_EFa_BEG0_input[3]),
    .S0(ConfigBits[160+0]),
    .S0N(ConfigBits_N[160+0]),
    .S1(ConfigBits[160+1]),
    .S1N(ConfigBits_N[160+1]),
    .X(J2MID_EFa_BEG0)
);

 //switch matrix multiplexer J2MID_EFa_BEG1 MUX-4
assign J2MID_EFa_BEG1_input = {JE2END5,S2MID2,E2MID2,N2MID2};
cus_mux41 inst_cus_mux41_J2MID_EFa_BEG1 (
    .A0(J2MID_EFa_BEG1_input[0]),
    .A1(J2MID_EFa_BEG1_input[1]),
    .A2(J2MID_EFa_BEG1_input[2]),
    .A3(J2MID_EFa_BEG1_input[3]),
    .S0(ConfigBits[162+0]),
    .S0N(ConfigBits_N[162+0]),
    .S1(ConfigBits[162+1]),
    .S1N(ConfigBits_N[162+1]),
    .X(J2MID_EFa_BEG1)
);

 //switch matrix multiplexer J2MID_EFa_BEG2 MUX-4
assign J2MID_EFa_BEG2_input = {JS2END5,W2MID4,S2MID4,N2MID4};
cus_mux41 inst_cus_mux41_J2MID_EFa_BEG2 (
    .A0(J2MID_EFa_BEG2_input[0]),
    .A1(J2MID_EFa_BEG2_input[1]),
    .A2(J2MID_EFa_BEG2_input[2]),
    .A3(J2MID_EFa_BEG2_input[3]),
    .S0(ConfigBits[164+0]),
    .S0N(ConfigBits_N[164+0]),
    .S1(ConfigBits[164+1]),
    .S1N(ConfigBits_N[164+1]),
    .X(J2MID_EFa_BEG2)
);

 //switch matrix multiplexer J2MID_EFa_BEG3 MUX-4
assign J2MID_EFa_BEG3_input = {JW2END5,W2MID0,S2MID0,E2MID0};
cus_mux41 inst_cus_mux41_J2MID_EFa_BEG3 (
    .A0(J2MID_EFa_BEG3_input[0]),
    .A1(J2MID_EFa_BEG3_input[1]),
    .A2(J2MID_EFa_BEG3_input[2]),
    .A3(J2MID_EFa_BEG3_input[3]),
    .S0(ConfigBits[166+0]),
    .S0N(ConfigBits_N[166+0]),
    .S1(ConfigBits[166+1]),
    .S1N(ConfigBits_N[166+1]),
    .X(J2MID_EFa_BEG3)
);

 //switch matrix multiplexer J2MID_GHa_BEG0 MUX-4
assign J2MID_GHa_BEG0_input = {JN2END6,S2MID6,E2MID6,N2MID6};
cus_mux41 inst_cus_mux41_J2MID_GHa_BEG0 (
    .A0(J2MID_GHa_BEG0_input[0]),
    .A1(J2MID_GHa_BEG0_input[1]),
    .A2(J2MID_GHa_BEG0_input[2]),
    .A3(J2MID_GHa_BEG0_input[3]),
    .S0(ConfigBits[168+0]),
    .S0N(ConfigBits_N[168+0]),
    .S1(ConfigBits[168+1]),
    .S1N(ConfigBits_N[168+1]),
    .X(J2MID_GHa_BEG0)
);

 //switch matrix multiplexer J2MID_GHa_BEG1 MUX-4
assign J2MID_GHa_BEG1_input = {JE2END6,W2MID2,S2MID2,N2MID2};
cus_mux41 inst_cus_mux41_J2MID_GHa_BEG1 (
    .A0(J2MID_GHa_BEG1_input[0]),
    .A1(J2MID_GHa_BEG1_input[1]),
    .A2(J2MID_GHa_BEG1_input[2]),
    .A3(J2MID_GHa_BEG1_input[3]),
    .S0(ConfigBits[170+0]),
    .S0N(ConfigBits_N[170+0]),
    .S1(ConfigBits[170+1]),
    .S1N(ConfigBits_N[170+1]),
    .X(J2MID_GHa_BEG1)
);

 //switch matrix multiplexer J2MID_GHa_BEG2 MUX-4
assign J2MID_GHa_BEG2_input = {JS2END6,W2MID4,S2MID4,E2MID4};
cus_mux41 inst_cus_mux41_J2MID_GHa_BEG2 (
    .A0(J2MID_GHa_BEG2_input[0]),
    .A1(J2MID_GHa_BEG2_input[1]),
    .A2(J2MID_GHa_BEG2_input[2]),
    .A3(J2MID_GHa_BEG2_input[3]),
    .S0(ConfigBits[172+0]),
    .S0N(ConfigBits_N[172+0]),
    .S1(ConfigBits[172+1]),
    .S1N(ConfigBits_N[172+1]),
    .X(J2MID_GHa_BEG2)
);

 //switch matrix multiplexer J2MID_GHa_BEG3 MUX-4
assign J2MID_GHa_BEG3_input = {JW2END6,W2MID0,E2MID0,N2MID0};
cus_mux41 inst_cus_mux41_J2MID_GHa_BEG3 (
    .A0(J2MID_GHa_BEG3_input[0]),
    .A1(J2MID_GHa_BEG3_input[1]),
    .A2(J2MID_GHa_BEG3_input[2]),
    .A3(J2MID_GHa_BEG3_input[3]),
    .S0(ConfigBits[174+0]),
    .S0N(ConfigBits_N[174+0]),
    .S1(ConfigBits[174+1]),
    .S1N(ConfigBits_N[174+1]),
    .X(J2MID_GHa_BEG3)
);

 //switch matrix multiplexer J2MID_ABb_BEG0 MUX-4
assign J2MID_ABb_BEG0_input = {W2MID7,S2MID7,E2MID7,N2MID7};
cus_mux41 inst_cus_mux41_J2MID_ABb_BEG0 (
    .A0(J2MID_ABb_BEG0_input[0]),
    .A1(J2MID_ABb_BEG0_input[1]),
    .A2(J2MID_ABb_BEG0_input[2]),
    .A3(J2MID_ABb_BEG0_input[3]),
    .S0(ConfigBits[176+0]),
    .S0N(ConfigBits_N[176+0]),
    .S1(ConfigBits[176+1]),
    .S1N(ConfigBits_N[176+1]),
    .X(J2MID_ABb_BEG0)
);

 //switch matrix multiplexer J2MID_ABb_BEG1 MUX-4
assign J2MID_ABb_BEG1_input = {W2MID3,S2MID3,E2MID3,N2MID3};
cus_mux41 inst_cus_mux41_J2MID_ABb_BEG1 (
    .A0(J2MID_ABb_BEG1_input[0]),
    .A1(J2MID_ABb_BEG1_input[1]),
    .A2(J2MID_ABb_BEG1_input[2]),
    .A3(J2MID_ABb_BEG1_input[3]),
    .S0(ConfigBits[178+0]),
    .S0N(ConfigBits_N[178+0]),
    .S1(ConfigBits[178+1]),
    .S1N(ConfigBits_N[178+1]),
    .X(J2MID_ABb_BEG1)
);

 //switch matrix multiplexer J2MID_ABb_BEG2 MUX-4
assign J2MID_ABb_BEG2_input = {W2MID5,S2MID5,E2MID5,N2MID5};
cus_mux41 inst_cus_mux41_J2MID_ABb_BEG2 (
    .A0(J2MID_ABb_BEG2_input[0]),
    .A1(J2MID_ABb_BEG2_input[1]),
    .A2(J2MID_ABb_BEG2_input[2]),
    .A3(J2MID_ABb_BEG2_input[3]),
    .S0(ConfigBits[180+0]),
    .S0N(ConfigBits_N[180+0]),
    .S1(ConfigBits[180+1]),
    .S1N(ConfigBits_N[180+1]),
    .X(J2MID_ABb_BEG2)
);

 //switch matrix multiplexer J2MID_ABb_BEG3 MUX-4
assign J2MID_ABb_BEG3_input = {W2MID1,S2MID1,E2MID1,N2MID1};
cus_mux41 inst_cus_mux41_J2MID_ABb_BEG3 (
    .A0(J2MID_ABb_BEG3_input[0]),
    .A1(J2MID_ABb_BEG3_input[1]),
    .A2(J2MID_ABb_BEG3_input[2]),
    .A3(J2MID_ABb_BEG3_input[3]),
    .S0(ConfigBits[182+0]),
    .S0N(ConfigBits_N[182+0]),
    .S1(ConfigBits[182+1]),
    .S1N(ConfigBits_N[182+1]),
    .X(J2MID_ABb_BEG3)
);

 //switch matrix multiplexer J2MID_CDb_BEG0 MUX-4
assign J2MID_CDb_BEG0_input = {W2MID7,S2MID7,E2MID7,N2MID7};
cus_mux41 inst_cus_mux41_J2MID_CDb_BEG0 (
    .A0(J2MID_CDb_BEG0_input[0]),
    .A1(J2MID_CDb_BEG0_input[1]),
    .A2(J2MID_CDb_BEG0_input[2]),
    .A3(J2MID_CDb_BEG0_input[3]),
    .S0(ConfigBits[184+0]),
    .S0N(ConfigBits_N[184+0]),
    .S1(ConfigBits[184+1]),
    .S1N(ConfigBits_N[184+1]),
    .X(J2MID_CDb_BEG0)
);

 //switch matrix multiplexer J2MID_CDb_BEG1 MUX-4
assign J2MID_CDb_BEG1_input = {W2MID3,S2MID3,E2MID3,N2MID3};
cus_mux41 inst_cus_mux41_J2MID_CDb_BEG1 (
    .A0(J2MID_CDb_BEG1_input[0]),
    .A1(J2MID_CDb_BEG1_input[1]),
    .A2(J2MID_CDb_BEG1_input[2]),
    .A3(J2MID_CDb_BEG1_input[3]),
    .S0(ConfigBits[186+0]),
    .S0N(ConfigBits_N[186+0]),
    .S1(ConfigBits[186+1]),
    .S1N(ConfigBits_N[186+1]),
    .X(J2MID_CDb_BEG1)
);

 //switch matrix multiplexer J2MID_CDb_BEG2 MUX-4
assign J2MID_CDb_BEG2_input = {W2MID5,S2MID5,E2MID5,N2MID5};
cus_mux41 inst_cus_mux41_J2MID_CDb_BEG2 (
    .A0(J2MID_CDb_BEG2_input[0]),
    .A1(J2MID_CDb_BEG2_input[1]),
    .A2(J2MID_CDb_BEG2_input[2]),
    .A3(J2MID_CDb_BEG2_input[3]),
    .S0(ConfigBits[188+0]),
    .S0N(ConfigBits_N[188+0]),
    .S1(ConfigBits[188+1]),
    .S1N(ConfigBits_N[188+1]),
    .X(J2MID_CDb_BEG2)
);

 //switch matrix multiplexer J2MID_CDb_BEG3 MUX-4
assign J2MID_CDb_BEG3_input = {W2MID1,S2MID1,E2MID1,N2MID1};
cus_mux41 inst_cus_mux41_J2MID_CDb_BEG3 (
    .A0(J2MID_CDb_BEG3_input[0]),
    .A1(J2MID_CDb_BEG3_input[1]),
    .A2(J2MID_CDb_BEG3_input[2]),
    .A3(J2MID_CDb_BEG3_input[3]),
    .S0(ConfigBits[190+0]),
    .S0N(ConfigBits_N[190+0]),
    .S1(ConfigBits[190+1]),
    .S1N(ConfigBits_N[190+1]),
    .X(J2MID_CDb_BEG3)
);

 //switch matrix multiplexer J2MID_EFb_BEG0 MUX-4
assign J2MID_EFb_BEG0_input = {W2MID7,S2MID7,E2MID7,N2MID7};
cus_mux41 inst_cus_mux41_J2MID_EFb_BEG0 (
    .A0(J2MID_EFb_BEG0_input[0]),
    .A1(J2MID_EFb_BEG0_input[1]),
    .A2(J2MID_EFb_BEG0_input[2]),
    .A3(J2MID_EFb_BEG0_input[3]),
    .S0(ConfigBits[192+0]),
    .S0N(ConfigBits_N[192+0]),
    .S1(ConfigBits[192+1]),
    .S1N(ConfigBits_N[192+1]),
    .X(J2MID_EFb_BEG0)
);

 //switch matrix multiplexer J2MID_EFb_BEG1 MUX-4
assign J2MID_EFb_BEG1_input = {W2MID3,S2MID3,E2MID3,N2MID3};
cus_mux41 inst_cus_mux41_J2MID_EFb_BEG1 (
    .A0(J2MID_EFb_BEG1_input[0]),
    .A1(J2MID_EFb_BEG1_input[1]),
    .A2(J2MID_EFb_BEG1_input[2]),
    .A3(J2MID_EFb_BEG1_input[3]),
    .S0(ConfigBits[194+0]),
    .S0N(ConfigBits_N[194+0]),
    .S1(ConfigBits[194+1]),
    .S1N(ConfigBits_N[194+1]),
    .X(J2MID_EFb_BEG1)
);

 //switch matrix multiplexer J2MID_EFb_BEG2 MUX-4
assign J2MID_EFb_BEG2_input = {W2MID5,S2MID5,E2MID5,N2MID5};
cus_mux41 inst_cus_mux41_J2MID_EFb_BEG2 (
    .A0(J2MID_EFb_BEG2_input[0]),
    .A1(J2MID_EFb_BEG2_input[1]),
    .A2(J2MID_EFb_BEG2_input[2]),
    .A3(J2MID_EFb_BEG2_input[3]),
    .S0(ConfigBits[196+0]),
    .S0N(ConfigBits_N[196+0]),
    .S1(ConfigBits[196+1]),
    .S1N(ConfigBits_N[196+1]),
    .X(J2MID_EFb_BEG2)
);

 //switch matrix multiplexer J2MID_EFb_BEG3 MUX-4
assign J2MID_EFb_BEG3_input = {W2MID1,S2MID1,E2MID1,N2MID1};
cus_mux41 inst_cus_mux41_J2MID_EFb_BEG3 (
    .A0(J2MID_EFb_BEG3_input[0]),
    .A1(J2MID_EFb_BEG3_input[1]),
    .A2(J2MID_EFb_BEG3_input[2]),
    .A3(J2MID_EFb_BEG3_input[3]),
    .S0(ConfigBits[198+0]),
    .S0N(ConfigBits_N[198+0]),
    .S1(ConfigBits[198+1]),
    .S1N(ConfigBits_N[198+1]),
    .X(J2MID_EFb_BEG3)
);

 //switch matrix multiplexer J2MID_GHb_BEG0 MUX-4
assign J2MID_GHb_BEG0_input = {W2MID7,S2MID7,E2MID7,N2MID7};
cus_mux41 inst_cus_mux41_J2MID_GHb_BEG0 (
    .A0(J2MID_GHb_BEG0_input[0]),
    .A1(J2MID_GHb_BEG0_input[1]),
    .A2(J2MID_GHb_BEG0_input[2]),
    .A3(J2MID_GHb_BEG0_input[3]),
    .S0(ConfigBits[200+0]),
    .S0N(ConfigBits_N[200+0]),
    .S1(ConfigBits[200+1]),
    .S1N(ConfigBits_N[200+1]),
    .X(J2MID_GHb_BEG0)
);

 //switch matrix multiplexer J2MID_GHb_BEG1 MUX-4
assign J2MID_GHb_BEG1_input = {W2MID3,S2MID3,E2MID3,N2MID3};
cus_mux41 inst_cus_mux41_J2MID_GHb_BEG1 (
    .A0(J2MID_GHb_BEG1_input[0]),
    .A1(J2MID_GHb_BEG1_input[1]),
    .A2(J2MID_GHb_BEG1_input[2]),
    .A3(J2MID_GHb_BEG1_input[3]),
    .S0(ConfigBits[202+0]),
    .S0N(ConfigBits_N[202+0]),
    .S1(ConfigBits[202+1]),
    .S1N(ConfigBits_N[202+1]),
    .X(J2MID_GHb_BEG1)
);

 //switch matrix multiplexer J2MID_GHb_BEG2 MUX-4
assign J2MID_GHb_BEG2_input = {W2MID5,S2MID5,E2MID5,N2MID5};
cus_mux41 inst_cus_mux41_J2MID_GHb_BEG2 (
    .A0(J2MID_GHb_BEG2_input[0]),
    .A1(J2MID_GHb_BEG2_input[1]),
    .A2(J2MID_GHb_BEG2_input[2]),
    .A3(J2MID_GHb_BEG2_input[3]),
    .S0(ConfigBits[204+0]),
    .S0N(ConfigBits_N[204+0]),
    .S1(ConfigBits[204+1]),
    .S1N(ConfigBits_N[204+1]),
    .X(J2MID_GHb_BEG2)
);

 //switch matrix multiplexer J2MID_GHb_BEG3 MUX-4
assign J2MID_GHb_BEG3_input = {W2MID1,S2MID1,E2MID1,N2MID1};
cus_mux41 inst_cus_mux41_J2MID_GHb_BEG3 (
    .A0(J2MID_GHb_BEG3_input[0]),
    .A1(J2MID_GHb_BEG3_input[1]),
    .A2(J2MID_GHb_BEG3_input[2]),
    .A3(J2MID_GHb_BEG3_input[3]),
    .S0(ConfigBits[206+0]),
    .S0N(ConfigBits_N[206+0]),
    .S1(ConfigBits[206+1]),
    .S1N(ConfigBits_N[206+1]),
    .X(J2MID_GHb_BEG3)
);

 //switch matrix multiplexer J2END_AB_BEG0 MUX-4
assign J2END_AB_BEG0_input = {W2END6,S1END7,E2END6,N2END6};
cus_mux41 inst_cus_mux41_J2END_AB_BEG0 (
    .A0(J2END_AB_BEG0_input[0]),
    .A1(J2END_AB_BEG0_input[1]),
    .A2(J2END_AB_BEG0_input[2]),
    .A3(J2END_AB_BEG0_input[3]),
    .S0(ConfigBits[208+0]),
    .S0N(ConfigBits_N[208+0]),
    .S1(ConfigBits[208+1]),
    .S1N(ConfigBits_N[208+1]),
    .X(J2END_AB_BEG0)
);

 //switch matrix multiplexer J2END_AB_BEG1 MUX-4
assign J2END_AB_BEG1_input = {W2END2,S2END2,E2END2,N1END4};
cus_mux41 inst_cus_mux41_J2END_AB_BEG1 (
    .A0(J2END_AB_BEG1_input[0]),
    .A1(J2END_AB_BEG1_input[1]),
    .A2(J2END_AB_BEG1_input[2]),
    .A3(J2END_AB_BEG1_input[3]),
    .S0(ConfigBits[210+0]),
    .S0N(ConfigBits_N[210+0]),
    .S1(ConfigBits[210+1]),
    .S1N(ConfigBits_N[210+1]),
    .X(J2END_AB_BEG1)
);

 //switch matrix multiplexer J2END_AB_BEG2 MUX-4
assign J2END_AB_BEG2_input = {W2END4,S2END4,E1END0,N2END4};
cus_mux41 inst_cus_mux41_J2END_AB_BEG2 (
    .A0(J2END_AB_BEG2_input[0]),
    .A1(J2END_AB_BEG2_input[1]),
    .A2(J2END_AB_BEG2_input[2]),
    .A3(J2END_AB_BEG2_input[3]),
    .S0(ConfigBits[212+0]),
    .S0N(ConfigBits_N[212+0]),
    .S1(ConfigBits[212+1]),
    .S1N(ConfigBits_N[212+1]),
    .X(J2END_AB_BEG2)
);

 //switch matrix multiplexer J2END_AB_BEG3 MUX-4
assign J2END_AB_BEG3_input = {W1END3,S2END0,E2END0,N2END0};
cus_mux41 inst_cus_mux41_J2END_AB_BEG3 (
    .A0(J2END_AB_BEG3_input[0]),
    .A1(J2END_AB_BEG3_input[1]),
    .A2(J2END_AB_BEG3_input[2]),
    .A3(J2END_AB_BEG3_input[3]),
    .S0(ConfigBits[214+0]),
    .S0N(ConfigBits_N[214+0]),
    .S1(ConfigBits[214+1]),
    .S1N(ConfigBits_N[214+1]),
    .X(J2END_AB_BEG3)
);

 //switch matrix multiplexer J2END_CD_BEG0 MUX-4
assign J2END_CD_BEG0_input = {W2END6,S2END6,E2END6,N1END7};
cus_mux41 inst_cus_mux41_J2END_CD_BEG0 (
    .A0(J2END_CD_BEG0_input[0]),
    .A1(J2END_CD_BEG0_input[1]),
    .A2(J2END_CD_BEG0_input[2]),
    .A3(J2END_CD_BEG0_input[3]),
    .S0(ConfigBits[216+0]),
    .S0N(ConfigBits_N[216+0]),
    .S1(ConfigBits[216+1]),
    .S1N(ConfigBits_N[216+1]),
    .X(J2END_CD_BEG0)
);

 //switch matrix multiplexer J2END_CD_BEG1 MUX-4
assign J2END_CD_BEG1_input = {W1END2,S2END2,E2END2,N2END2};
cus_mux41 inst_cus_mux41_J2END_CD_BEG1 (
    .A0(J2END_CD_BEG1_input[0]),
    .A1(J2END_CD_BEG1_input[1]),
    .A2(J2END_CD_BEG1_input[2]),
    .A3(J2END_CD_BEG1_input[3]),
    .S0(ConfigBits[218+0]),
    .S0N(ConfigBits_N[218+0]),
    .S1(ConfigBits[218+1]),
    .S1N(ConfigBits_N[218+1]),
    .X(J2END_CD_BEG1)
);

 //switch matrix multiplexer J2END_CD_BEG2 MUX-4
assign J2END_CD_BEG2_input = {W2END4,S1END6,E2END4,N2END4};
cus_mux41 inst_cus_mux41_J2END_CD_BEG2 (
    .A0(J2END_CD_BEG2_input[0]),
    .A1(J2END_CD_BEG2_input[1]),
    .A2(J2END_CD_BEG2_input[2]),
    .A3(J2END_CD_BEG2_input[3]),
    .S0(ConfigBits[220+0]),
    .S0N(ConfigBits_N[220+0]),
    .S1(ConfigBits[220+1]),
    .S1N(ConfigBits_N[220+1]),
    .X(J2END_CD_BEG2)
);

 //switch matrix multiplexer J2END_CD_BEG3 MUX-4
assign J2END_CD_BEG3_input = {W2END0,S2END0,E1END1,N2END0};
cus_mux41 inst_cus_mux41_J2END_CD_BEG3 (
    .A0(J2END_CD_BEG3_input[0]),
    .A1(J2END_CD_BEG3_input[1]),
    .A2(J2END_CD_BEG3_input[2]),
    .A3(J2END_CD_BEG3_input[3]),
    .S0(ConfigBits[222+0]),
    .S0N(ConfigBits_N[222+0]),
    .S1(ConfigBits[222+1]),
    .S1N(ConfigBits_N[222+1]),
    .X(J2END_CD_BEG3)
);

 //switch matrix multiplexer J2END_EF_BEG0 MUX-4
assign J2END_EF_BEG0_input = {W2END7,S2END7,E1END2,N2END7};
cus_mux41 inst_cus_mux41_J2END_EF_BEG0 (
    .A0(J2END_EF_BEG0_input[0]),
    .A1(J2END_EF_BEG0_input[1]),
    .A2(J2END_EF_BEG0_input[2]),
    .A3(J2END_EF_BEG0_input[3]),
    .S0(ConfigBits[224+0]),
    .S0N(ConfigBits_N[224+0]),
    .S1(ConfigBits[224+1]),
    .S1N(ConfigBits_N[224+1]),
    .X(J2END_EF_BEG0)
);

 //switch matrix multiplexer J2END_EF_BEG1 MUX-4
assign J2END_EF_BEG1_input = {W1END1,S2END3,E2END3,N2END3};
cus_mux41 inst_cus_mux41_J2END_EF_BEG1 (
    .A0(J2END_EF_BEG1_input[0]),
    .A1(J2END_EF_BEG1_input[1]),
    .A2(J2END_EF_BEG1_input[2]),
    .A3(J2END_EF_BEG1_input[3]),
    .S0(ConfigBits[226+0]),
    .S0N(ConfigBits_N[226+0]),
    .S1(ConfigBits[226+1]),
    .S1N(ConfigBits_N[226+1]),
    .X(J2END_EF_BEG1)
);

 //switch matrix multiplexer J2END_EF_BEG2 MUX-4
assign J2END_EF_BEG2_input = {W2END5,S1END5,E2END5,N2END5};
cus_mux41 inst_cus_mux41_J2END_EF_BEG2 (
    .A0(J2END_EF_BEG2_input[0]),
    .A1(J2END_EF_BEG2_input[1]),
    .A2(J2END_EF_BEG2_input[2]),
    .A3(J2END_EF_BEG2_input[3]),
    .S0(ConfigBits[228+0]),
    .S0N(ConfigBits_N[228+0]),
    .S1(ConfigBits[228+1]),
    .S1N(ConfigBits_N[228+1]),
    .X(J2END_EF_BEG2)
);

 //switch matrix multiplexer J2END_EF_BEG3 MUX-4
assign J2END_EF_BEG3_input = {W2END1,S2END1,E2END1,N1END6};
cus_mux41 inst_cus_mux41_J2END_EF_BEG3 (
    .A0(J2END_EF_BEG3_input[0]),
    .A1(J2END_EF_BEG3_input[1]),
    .A2(J2END_EF_BEG3_input[2]),
    .A3(J2END_EF_BEG3_input[3]),
    .S0(ConfigBits[230+0]),
    .S0N(ConfigBits_N[230+0]),
    .S1(ConfigBits[230+1]),
    .S1N(ConfigBits_N[230+1]),
    .X(J2END_EF_BEG3)
);

 //switch matrix multiplexer J2END_GH_BEG0 MUX-4
assign J2END_GH_BEG0_input = {W1END0,S2END7,E2END7,N2END7};
cus_mux41 inst_cus_mux41_J2END_GH_BEG0 (
    .A0(J2END_GH_BEG0_input[0]),
    .A1(J2END_GH_BEG0_input[1]),
    .A2(J2END_GH_BEG0_input[2]),
    .A3(J2END_GH_BEG0_input[3]),
    .S0(ConfigBits[232+0]),
    .S0N(ConfigBits_N[232+0]),
    .S1(ConfigBits[232+1]),
    .S1N(ConfigBits_N[232+1]),
    .X(J2END_GH_BEG0)
);

 //switch matrix multiplexer J2END_GH_BEG1 MUX-4
assign J2END_GH_BEG1_input = {W2END3,S1END4,E2END3,N2END3};
cus_mux41 inst_cus_mux41_J2END_GH_BEG1 (
    .A0(J2END_GH_BEG1_input[0]),
    .A1(J2END_GH_BEG1_input[1]),
    .A2(J2END_GH_BEG1_input[2]),
    .A3(J2END_GH_BEG1_input[3]),
    .S0(ConfigBits[234+0]),
    .S0N(ConfigBits_N[234+0]),
    .S1(ConfigBits[234+1]),
    .S1N(ConfigBits_N[234+1]),
    .X(J2END_GH_BEG1)
);

 //switch matrix multiplexer J2END_GH_BEG2 MUX-4
assign J2END_GH_BEG2_input = {W2END5,S2END5,E2END5,N1END5};
cus_mux41 inst_cus_mux41_J2END_GH_BEG2 (
    .A0(J2END_GH_BEG2_input[0]),
    .A1(J2END_GH_BEG2_input[1]),
    .A2(J2END_GH_BEG2_input[2]),
    .A3(J2END_GH_BEG2_input[3]),
    .S0(ConfigBits[236+0]),
    .S0N(ConfigBits_N[236+0]),
    .S1(ConfigBits[236+1]),
    .S1N(ConfigBits_N[236+1]),
    .X(J2END_GH_BEG2)
);

 //switch matrix multiplexer J2END_GH_BEG3 MUX-4
assign J2END_GH_BEG3_input = {W2END1,S2END1,E1END3,N2END1};
cus_mux41 inst_cus_mux41_J2END_GH_BEG3 (
    .A0(J2END_GH_BEG3_input[0]),
    .A1(J2END_GH_BEG3_input[1]),
    .A2(J2END_GH_BEG3_input[2]),
    .A3(J2END_GH_BEG3_input[3]),
    .S0(ConfigBits[238+0]),
    .S0N(ConfigBits_N[238+0]),
    .S1(ConfigBits[238+1]),
    .S1N(ConfigBits_N[238+1]),
    .X(J2END_GH_BEG3)
);

 //switch matrix multiplexer JN2BEG0 MUX-16
assign JN2BEG0_input = {LH_O,LG_O,LF_O,LE_O,LD_O,LC_O,LB_O,W2END1,W1END4,S1END5,E2END1,E1END7,E1END3,N2END1,N1END5,N1END1};
cus_mux161 inst_cus_mux161_JN2BEG0 (
    .A0(JN2BEG0_input[0]),
    .A1(JN2BEG0_input[1]),
    .A2(JN2BEG0_input[2]),
    .A3(JN2BEG0_input[3]),
    .A4(JN2BEG0_input[4]),
    .A5(JN2BEG0_input[5]),
    .A6(JN2BEG0_input[6]),
    .A7(JN2BEG0_input[7]),
    .A8(JN2BEG0_input[8]),
    .A9(JN2BEG0_input[9]),
    .A10(JN2BEG0_input[10]),
    .A11(JN2BEG0_input[11]),
    .A12(JN2BEG0_input[12]),
    .A13(JN2BEG0_input[13]),
    .A14(JN2BEG0_input[14]),
    .A15(JN2BEG0_input[15]),
    .S0(ConfigBits[240+0]),
    .S0N(ConfigBits_N[240+0]),
    .S1(ConfigBits[240+1]),
    .S1N(ConfigBits_N[240+1]),
    .S2(ConfigBits[240+2]),
    .S2N(ConfigBits_N[240+2]),
    .S3(ConfigBits[240+3]),
    .S3N(ConfigBits_N[240+3]),
    .X(JN2BEG0)
);

 //switch matrix multiplexer JN2BEG1 MUX-16
assign JN2BEG1_input = {LH_O,LG_O,LF_O,LE_O,LD_O,LC_O,LA_O,W2END2,W1END5,S2END2,E2END2,E1END6,E1END0,N2END2,N1END6,N1END2};
cus_mux161 inst_cus_mux161_JN2BEG1 (
    .A0(JN2BEG1_input[0]),
    .A1(JN2BEG1_input[1]),
    .A2(JN2BEG1_input[2]),
    .A3(JN2BEG1_input[3]),
    .A4(JN2BEG1_input[4]),
    .A5(JN2BEG1_input[5]),
    .A6(JN2BEG1_input[6]),
    .A7(JN2BEG1_input[7]),
    .A8(JN2BEG1_input[8]),
    .A9(JN2BEG1_input[9]),
    .A10(JN2BEG1_input[10]),
    .A11(JN2BEG1_input[11]),
    .A12(JN2BEG1_input[12]),
    .A13(JN2BEG1_input[13]),
    .A14(JN2BEG1_input[14]),
    .A15(JN2BEG1_input[15]),
    .S0(ConfigBits[244+0]),
    .S0N(ConfigBits_N[244+0]),
    .S1(ConfigBits[244+1]),
    .S1N(ConfigBits_N[244+1]),
    .S2(ConfigBits[244+2]),
    .S2N(ConfigBits_N[244+2]),
    .S3(ConfigBits[244+3]),
    .S3N(ConfigBits_N[244+3]),
    .X(JN2BEG1)
);

 //switch matrix multiplexer JN2BEG2 MUX-16
assign JN2BEG2_input = {LH_O,LG_O,LF_O,LE_O,LD_O,LB_O,LA_O,W2END3,W1END7,S2END3,E2END3,E1END5,E1END1,N2END3,N1END7,N1END3};
cus_mux161 inst_cus_mux161_JN2BEG2 (
    .A0(JN2BEG2_input[0]),
    .A1(JN2BEG2_input[1]),
    .A2(JN2BEG2_input[2]),
    .A3(JN2BEG2_input[3]),
    .A4(JN2BEG2_input[4]),
    .A5(JN2BEG2_input[5]),
    .A6(JN2BEG2_input[6]),
    .A7(JN2BEG2_input[7]),
    .A8(JN2BEG2_input[8]),
    .A9(JN2BEG2_input[9]),
    .A10(JN2BEG2_input[10]),
    .A11(JN2BEG2_input[11]),
    .A12(JN2BEG2_input[12]),
    .A13(JN2BEG2_input[13]),
    .A14(JN2BEG2_input[14]),
    .A15(JN2BEG2_input[15]),
    .S0(ConfigBits[248+0]),
    .S0N(ConfigBits_N[248+0]),
    .S1(ConfigBits[248+1]),
    .S1N(ConfigBits_N[248+1]),
    .S2(ConfigBits[248+2]),
    .S2N(ConfigBits_N[248+2]),
    .S3(ConfigBits[248+3]),
    .S3N(ConfigBits_N[248+3]),
    .X(JN2BEG2)
);

 //switch matrix multiplexer JN2BEG3 MUX-16
assign JN2BEG3_input = {LH_O,LG_O,LF_O,LE_O,LC_O,LB_O,LA_O,W2END4,W1END6,S2END4,E2END4,E1END4,E1END2,N2END4,N1END4,N1END0};
cus_mux161 inst_cus_mux161_JN2BEG3 (
    .A0(JN2BEG3_input[0]),
    .A1(JN2BEG3_input[1]),
    .A2(JN2BEG3_input[2]),
    .A3(JN2BEG3_input[3]),
    .A4(JN2BEG3_input[4]),
    .A5(JN2BEG3_input[5]),
    .A6(JN2BEG3_input[6]),
    .A7(JN2BEG3_input[7]),
    .A8(JN2BEG3_input[8]),
    .A9(JN2BEG3_input[9]),
    .A10(JN2BEG3_input[10]),
    .A11(JN2BEG3_input[11]),
    .A12(JN2BEG3_input[12]),
    .A13(JN2BEG3_input[13]),
    .A14(JN2BEG3_input[14]),
    .A15(JN2BEG3_input[15]),
    .S0(ConfigBits[252+0]),
    .S0N(ConfigBits_N[252+0]),
    .S1(ConfigBits[252+1]),
    .S1N(ConfigBits_N[252+1]),
    .S2(ConfigBits[252+2]),
    .S2N(ConfigBits_N[252+2]),
    .S3(ConfigBits[252+3]),
    .S3N(ConfigBits_N[252+3]),
    .X(JN2BEG3)
);

 //switch matrix multiplexer JN2BEG4 MUX-16
assign JN2BEG4_input = {LH_O,LG_O,LF_O,LD_O,LC_O,LB_O,LA_O,W2END5,W1END3,W1END1,S2END5,S1END1,E2END5,E1END1,N2END5,N1END1};
cus_mux161 inst_cus_mux161_JN2BEG4 (
    .A0(JN2BEG4_input[0]),
    .A1(JN2BEG4_input[1]),
    .A2(JN2BEG4_input[2]),
    .A3(JN2BEG4_input[3]),
    .A4(JN2BEG4_input[4]),
    .A5(JN2BEG4_input[5]),
    .A6(JN2BEG4_input[6]),
    .A7(JN2BEG4_input[7]),
    .A8(JN2BEG4_input[8]),
    .A9(JN2BEG4_input[9]),
    .A10(JN2BEG4_input[10]),
    .A11(JN2BEG4_input[11]),
    .A12(JN2BEG4_input[12]),
    .A13(JN2BEG4_input[13]),
    .A14(JN2BEG4_input[14]),
    .A15(JN2BEG4_input[15]),
    .S0(ConfigBits[256+0]),
    .S0N(ConfigBits_N[256+0]),
    .S1(ConfigBits[256+1]),
    .S1N(ConfigBits_N[256+1]),
    .S2(ConfigBits[256+2]),
    .S2N(ConfigBits_N[256+2]),
    .S3(ConfigBits[256+3]),
    .S3N(ConfigBits_N[256+3]),
    .X(JN2BEG4)
);

 //switch matrix multiplexer JN2BEG5 MUX-16
assign JN2BEG5_input = {LH_O,LG_O,LE_O,LD_O,LC_O,LB_O,LA_O,W2END6,W1END2,W1END0,S2END6,S1END2,E2END6,E1END2,N2END6,N1END2};
cus_mux161 inst_cus_mux161_JN2BEG5 (
    .A0(JN2BEG5_input[0]),
    .A1(JN2BEG5_input[1]),
    .A2(JN2BEG5_input[2]),
    .A3(JN2BEG5_input[3]),
    .A4(JN2BEG5_input[4]),
    .A5(JN2BEG5_input[5]),
    .A6(JN2BEG5_input[6]),
    .A7(JN2BEG5_input[7]),
    .A8(JN2BEG5_input[8]),
    .A9(JN2BEG5_input[9]),
    .A10(JN2BEG5_input[10]),
    .A11(JN2BEG5_input[11]),
    .A12(JN2BEG5_input[12]),
    .A13(JN2BEG5_input[13]),
    .A14(JN2BEG5_input[14]),
    .A15(JN2BEG5_input[15]),
    .S0(ConfigBits[260+0]),
    .S0N(ConfigBits_N[260+0]),
    .S1(ConfigBits[260+1]),
    .S1N(ConfigBits_N[260+1]),
    .S2(ConfigBits[260+2]),
    .S2N(ConfigBits_N[260+2]),
    .S3(ConfigBits[260+3]),
    .S3N(ConfigBits_N[260+3]),
    .X(JN2BEG5)
);

 //switch matrix multiplexer JN2BEG6 MUX-16
assign JN2BEG6_input = {LH_O,LF_O,LE_O,LD_O,LC_O,LB_O,LA_O,W2END7,W1END3,W1END1,S2END7,S1END3,E2END7,E1END3,N2END7,N1END3};
cus_mux161 inst_cus_mux161_JN2BEG6 (
    .A0(JN2BEG6_input[0]),
    .A1(JN2BEG6_input[1]),
    .A2(JN2BEG6_input[2]),
    .A3(JN2BEG6_input[3]),
    .A4(JN2BEG6_input[4]),
    .A5(JN2BEG6_input[5]),
    .A6(JN2BEG6_input[6]),
    .A7(JN2BEG6_input[7]),
    .A8(JN2BEG6_input[8]),
    .A9(JN2BEG6_input[9]),
    .A10(JN2BEG6_input[10]),
    .A11(JN2BEG6_input[11]),
    .A12(JN2BEG6_input[12]),
    .A13(JN2BEG6_input[13]),
    .A14(JN2BEG6_input[14]),
    .A15(JN2BEG6_input[15]),
    .S0(ConfigBits[264+0]),
    .S0N(ConfigBits_N[264+0]),
    .S1(ConfigBits[264+1]),
    .S1N(ConfigBits_N[264+1]),
    .S2(ConfigBits[264+2]),
    .S2N(ConfigBits_N[264+2]),
    .S3(ConfigBits[264+3]),
    .S3N(ConfigBits_N[264+3]),
    .X(JN2BEG6)
);

 //switch matrix multiplexer JN2BEG7 MUX-16
assign JN2BEG7_input = {LG_O,LF_O,LE_O,LD_O,LC_O,LB_O,LA_O,W2END0,W1END2,W1END0,S2END0,S1END0,E1END7,E1END0,N2END0,N1END0};
cus_mux161 inst_cus_mux161_JN2BEG7 (
    .A0(JN2BEG7_input[0]),
    .A1(JN2BEG7_input[1]),
    .A2(JN2BEG7_input[2]),
    .A3(JN2BEG7_input[3]),
    .A4(JN2BEG7_input[4]),
    .A5(JN2BEG7_input[5]),
    .A6(JN2BEG7_input[6]),
    .A7(JN2BEG7_input[7]),
    .A8(JN2BEG7_input[8]),
    .A9(JN2BEG7_input[9]),
    .A10(JN2BEG7_input[10]),
    .A11(JN2BEG7_input[11]),
    .A12(JN2BEG7_input[12]),
    .A13(JN2BEG7_input[13]),
    .A14(JN2BEG7_input[14]),
    .A15(JN2BEG7_input[15]),
    .S0(ConfigBits[268+0]),
    .S0N(ConfigBits_N[268+0]),
    .S1(ConfigBits[268+1]),
    .S1N(ConfigBits_N[268+1]),
    .S2(ConfigBits[268+2]),
    .S2N(ConfigBits_N[268+2]),
    .S3(ConfigBits[268+3]),
    .S3N(ConfigBits_N[268+3]),
    .X(JN2BEG7)
);

 //switch matrix multiplexer JE2BEG0 MUX-16
assign JE2BEG0_input = {LH_O,LG_O,LF_O,LE_O,LD_O,LC_O,LB_O,W2END1,W1END4,S2END1,E1END7,E1END1,N2END1,N1END5,N1END3,N1END1};
cus_mux161 inst_cus_mux161_JE2BEG0 (
    .A0(JE2BEG0_input[0]),
    .A1(JE2BEG0_input[1]),
    .A2(JE2BEG0_input[2]),
    .A3(JE2BEG0_input[3]),
    .A4(JE2BEG0_input[4]),
    .A5(JE2BEG0_input[5]),
    .A6(JE2BEG0_input[6]),
    .A7(JE2BEG0_input[7]),
    .A8(JE2BEG0_input[8]),
    .A9(JE2BEG0_input[9]),
    .A10(JE2BEG0_input[10]),
    .A11(JE2BEG0_input[11]),
    .A12(JE2BEG0_input[12]),
    .A13(JE2BEG0_input[13]),
    .A14(JE2BEG0_input[14]),
    .A15(JE2BEG0_input[15]),
    .S0(ConfigBits[272+0]),
    .S0N(ConfigBits_N[272+0]),
    .S1(ConfigBits[272+1]),
    .S1N(ConfigBits_N[272+1]),
    .S2(ConfigBits[272+2]),
    .S2N(ConfigBits_N[272+2]),
    .S3(ConfigBits[272+3]),
    .S3N(ConfigBits_N[272+3]),
    .X(JE2BEG0)
);

 //switch matrix multiplexer JE2BEG1 MUX-16
assign JE2BEG1_input = {LH_O,LG_O,LF_O,LE_O,LD_O,LC_O,LA_O,W2END2,W1END5,S2END2,E2END2,E1END6,N2END2,N1END6,N1END2,N1END0};
cus_mux161 inst_cus_mux161_JE2BEG1 (
    .A0(JE2BEG1_input[0]),
    .A1(JE2BEG1_input[1]),
    .A2(JE2BEG1_input[2]),
    .A3(JE2BEG1_input[3]),
    .A4(JE2BEG1_input[4]),
    .A5(JE2BEG1_input[5]),
    .A6(JE2BEG1_input[6]),
    .A7(JE2BEG1_input[7]),
    .A8(JE2BEG1_input[8]),
    .A9(JE2BEG1_input[9]),
    .A10(JE2BEG1_input[10]),
    .A11(JE2BEG1_input[11]),
    .A12(JE2BEG1_input[12]),
    .A13(JE2BEG1_input[13]),
    .A14(JE2BEG1_input[14]),
    .A15(JE2BEG1_input[15]),
    .S0(ConfigBits[276+0]),
    .S0N(ConfigBits_N[276+0]),
    .S1(ConfigBits[276+1]),
    .S1N(ConfigBits_N[276+1]),
    .S2(ConfigBits[276+2]),
    .S2N(ConfigBits_N[276+2]),
    .S3(ConfigBits[276+3]),
    .S3N(ConfigBits_N[276+3]),
    .X(JE2BEG1)
);

 //switch matrix multiplexer JE2BEG2 MUX-16
assign JE2BEG2_input = {LH_O,LG_O,LF_O,LE_O,LD_O,LB_O,LA_O,W2END3,W1END7,S2END3,E2END3,E1END5,N2END3,N1END7,N1END3,N1END1};
cus_mux161 inst_cus_mux161_JE2BEG2 (
    .A0(JE2BEG2_input[0]),
    .A1(JE2BEG2_input[1]),
    .A2(JE2BEG2_input[2]),
    .A3(JE2BEG2_input[3]),
    .A4(JE2BEG2_input[4]),
    .A5(JE2BEG2_input[5]),
    .A6(JE2BEG2_input[6]),
    .A7(JE2BEG2_input[7]),
    .A8(JE2BEG2_input[8]),
    .A9(JE2BEG2_input[9]),
    .A10(JE2BEG2_input[10]),
    .A11(JE2BEG2_input[11]),
    .A12(JE2BEG2_input[12]),
    .A13(JE2BEG2_input[13]),
    .A14(JE2BEG2_input[14]),
    .A15(JE2BEG2_input[15]),
    .S0(ConfigBits[280+0]),
    .S0N(ConfigBits_N[280+0]),
    .S1(ConfigBits[280+1]),
    .S1N(ConfigBits_N[280+1]),
    .S2(ConfigBits[280+2]),
    .S2N(ConfigBits_N[280+2]),
    .S3(ConfigBits[280+3]),
    .S3N(ConfigBits_N[280+3]),
    .X(JE2BEG2)
);

 //switch matrix multiplexer JE2BEG3 MUX-16
assign JE2BEG3_input = {LH_O,LG_O,LF_O,LE_O,LC_O,LB_O,LA_O,W2END4,W1END6,S2END4,E2END4,E1END4,N2END4,N1END4,N1END2,N1END0};
cus_mux161 inst_cus_mux161_JE2BEG3 (
    .A0(JE2BEG3_input[0]),
    .A1(JE2BEG3_input[1]),
    .A2(JE2BEG3_input[2]),
    .A3(JE2BEG3_input[3]),
    .A4(JE2BEG3_input[4]),
    .A5(JE2BEG3_input[5]),
    .A6(JE2BEG3_input[6]),
    .A7(JE2BEG3_input[7]),
    .A8(JE2BEG3_input[8]),
    .A9(JE2BEG3_input[9]),
    .A10(JE2BEG3_input[10]),
    .A11(JE2BEG3_input[11]),
    .A12(JE2BEG3_input[12]),
    .A13(JE2BEG3_input[13]),
    .A14(JE2BEG3_input[14]),
    .A15(JE2BEG3_input[15]),
    .S0(ConfigBits[284+0]),
    .S0N(ConfigBits_N[284+0]),
    .S1(ConfigBits[284+1]),
    .S1N(ConfigBits_N[284+1]),
    .S2(ConfigBits[284+2]),
    .S2N(ConfigBits_N[284+2]),
    .S3(ConfigBits[284+3]),
    .S3N(ConfigBits_N[284+3]),
    .X(JE2BEG3)
);

 //switch matrix multiplexer JE2BEG4 MUX-16
assign JE2BEG4_input = {LH_O,LG_O,LF_O,LD_O,LC_O,LB_O,LA_O,W2END5,W1END1,S2END5,S1END3,S1END1,E2END5,E1END1,N2END5,N1END1};
cus_mux161 inst_cus_mux161_JE2BEG4 (
    .A0(JE2BEG4_input[0]),
    .A1(JE2BEG4_input[1]),
    .A2(JE2BEG4_input[2]),
    .A3(JE2BEG4_input[3]),
    .A4(JE2BEG4_input[4]),
    .A5(JE2BEG4_input[5]),
    .A6(JE2BEG4_input[6]),
    .A7(JE2BEG4_input[7]),
    .A8(JE2BEG4_input[8]),
    .A9(JE2BEG4_input[9]),
    .A10(JE2BEG4_input[10]),
    .A11(JE2BEG4_input[11]),
    .A12(JE2BEG4_input[12]),
    .A13(JE2BEG4_input[13]),
    .A14(JE2BEG4_input[14]),
    .A15(JE2BEG4_input[15]),
    .S0(ConfigBits[288+0]),
    .S0N(ConfigBits_N[288+0]),
    .S1(ConfigBits[288+1]),
    .S1N(ConfigBits_N[288+1]),
    .S2(ConfigBits[288+2]),
    .S2N(ConfigBits_N[288+2]),
    .S3(ConfigBits[288+3]),
    .S3N(ConfigBits_N[288+3]),
    .X(JE2BEG4)
);

 //switch matrix multiplexer JE2BEG5 MUX-16
assign JE2BEG5_input = {LH_O,LG_O,LE_O,LD_O,LC_O,LB_O,LA_O,W2END6,W1END2,S2END6,S1END2,S1END0,E2END6,E1END2,N2END6,N1END2};
cus_mux161 inst_cus_mux161_JE2BEG5 (
    .A0(JE2BEG5_input[0]),
    .A1(JE2BEG5_input[1]),
    .A2(JE2BEG5_input[2]),
    .A3(JE2BEG5_input[3]),
    .A4(JE2BEG5_input[4]),
    .A5(JE2BEG5_input[5]),
    .A6(JE2BEG5_input[6]),
    .A7(JE2BEG5_input[7]),
    .A8(JE2BEG5_input[8]),
    .A9(JE2BEG5_input[9]),
    .A10(JE2BEG5_input[10]),
    .A11(JE2BEG5_input[11]),
    .A12(JE2BEG5_input[12]),
    .A13(JE2BEG5_input[13]),
    .A14(JE2BEG5_input[14]),
    .A15(JE2BEG5_input[15]),
    .S0(ConfigBits[292+0]),
    .S0N(ConfigBits_N[292+0]),
    .S1(ConfigBits[292+1]),
    .S1N(ConfigBits_N[292+1]),
    .S2(ConfigBits[292+2]),
    .S2N(ConfigBits_N[292+2]),
    .S3(ConfigBits[292+3]),
    .S3N(ConfigBits_N[292+3]),
    .X(JE2BEG5)
);

 //switch matrix multiplexer JE2BEG6 MUX-16
assign JE2BEG6_input = {LH_O,LF_O,LE_O,LD_O,LC_O,LB_O,LA_O,W2END7,W1END3,S2END7,S1END3,S1END1,E2END7,E1END3,N2END7,N1END3};
cus_mux161 inst_cus_mux161_JE2BEG6 (
    .A0(JE2BEG6_input[0]),
    .A1(JE2BEG6_input[1]),
    .A2(JE2BEG6_input[2]),
    .A3(JE2BEG6_input[3]),
    .A4(JE2BEG6_input[4]),
    .A5(JE2BEG6_input[5]),
    .A6(JE2BEG6_input[6]),
    .A7(JE2BEG6_input[7]),
    .A8(JE2BEG6_input[8]),
    .A9(JE2BEG6_input[9]),
    .A10(JE2BEG6_input[10]),
    .A11(JE2BEG6_input[11]),
    .A12(JE2BEG6_input[12]),
    .A13(JE2BEG6_input[13]),
    .A14(JE2BEG6_input[14]),
    .A15(JE2BEG6_input[15]),
    .S0(ConfigBits[296+0]),
    .S0N(ConfigBits_N[296+0]),
    .S1(ConfigBits[296+1]),
    .S1N(ConfigBits_N[296+1]),
    .S2(ConfigBits[296+2]),
    .S2N(ConfigBits_N[296+2]),
    .S3(ConfigBits[296+3]),
    .S3N(ConfigBits_N[296+3]),
    .X(JE2BEG6)
);

 //switch matrix multiplexer JE2BEG7 MUX-16
assign JE2BEG7_input = {LG_O,LF_O,LE_O,LD_O,LC_O,LB_O,LA_O,W2END0,W1END0,S1END4,S1END2,S1END0,E2END0,E1END0,N2END0,N1END0};
cus_mux161 inst_cus_mux161_JE2BEG7 (
    .A0(JE2BEG7_input[0]),
    .A1(JE2BEG7_input[1]),
    .A2(JE2BEG7_input[2]),
    .A3(JE2BEG7_input[3]),
    .A4(JE2BEG7_input[4]),
    .A5(JE2BEG7_input[5]),
    .A6(JE2BEG7_input[6]),
    .A7(JE2BEG7_input[7]),
    .A8(JE2BEG7_input[8]),
    .A9(JE2BEG7_input[9]),
    .A10(JE2BEG7_input[10]),
    .A11(JE2BEG7_input[11]),
    .A12(JE2BEG7_input[12]),
    .A13(JE2BEG7_input[13]),
    .A14(JE2BEG7_input[14]),
    .A15(JE2BEG7_input[15]),
    .S0(ConfigBits[300+0]),
    .S0N(ConfigBits_N[300+0]),
    .S1(ConfigBits[300+1]),
    .S1N(ConfigBits_N[300+1]),
    .S2(ConfigBits[300+2]),
    .S2N(ConfigBits_N[300+2]),
    .S3(ConfigBits[300+3]),
    .S3N(ConfigBits_N[300+3]),
    .X(JE2BEG7)
);

 //switch matrix multiplexer JS2BEG0 MUX-16
assign JS2BEG0_input = {LH_O,LG_O,LF_O,LE_O,LD_O,LC_O,LB_O,W2END1,W1END4,S2END1,S1END1,E2END1,E1END7,E1END3,N1END5,N1END1};
cus_mux161 inst_cus_mux161_JS2BEG0 (
    .A0(JS2BEG0_input[0]),
    .A1(JS2BEG0_input[1]),
    .A2(JS2BEG0_input[2]),
    .A3(JS2BEG0_input[3]),
    .A4(JS2BEG0_input[4]),
    .A5(JS2BEG0_input[5]),
    .A6(JS2BEG0_input[6]),
    .A7(JS2BEG0_input[7]),
    .A8(JS2BEG0_input[8]),
    .A9(JS2BEG0_input[9]),
    .A10(JS2BEG0_input[10]),
    .A11(JS2BEG0_input[11]),
    .A12(JS2BEG0_input[12]),
    .A13(JS2BEG0_input[13]),
    .A14(JS2BEG0_input[14]),
    .A15(JS2BEG0_input[15]),
    .S0(ConfigBits[304+0]),
    .S0N(ConfigBits_N[304+0]),
    .S1(ConfigBits[304+1]),
    .S1N(ConfigBits_N[304+1]),
    .S2(ConfigBits[304+2]),
    .S2N(ConfigBits_N[304+2]),
    .S3(ConfigBits[304+3]),
    .S3N(ConfigBits_N[304+3]),
    .X(JS2BEG0)
);

 //switch matrix multiplexer JS2BEG1 MUX-16
assign JS2BEG1_input = {LH_O,LG_O,LF_O,LE_O,LD_O,LC_O,LA_O,W2END2,W1END5,S1END6,S1END2,E1END6,E1END2,E1END0,N1END6,N1END2};
cus_mux161 inst_cus_mux161_JS2BEG1 (
    .A0(JS2BEG1_input[0]),
    .A1(JS2BEG1_input[1]),
    .A2(JS2BEG1_input[2]),
    .A3(JS2BEG1_input[3]),
    .A4(JS2BEG1_input[4]),
    .A5(JS2BEG1_input[5]),
    .A6(JS2BEG1_input[6]),
    .A7(JS2BEG1_input[7]),
    .A8(JS2BEG1_input[8]),
    .A9(JS2BEG1_input[9]),
    .A10(JS2BEG1_input[10]),
    .A11(JS2BEG1_input[11]),
    .A12(JS2BEG1_input[12]),
    .A13(JS2BEG1_input[13]),
    .A14(JS2BEG1_input[14]),
    .A15(JS2BEG1_input[15]),
    .S0(ConfigBits[308+0]),
    .S0N(ConfigBits_N[308+0]),
    .S1(ConfigBits[308+1]),
    .S1N(ConfigBits_N[308+1]),
    .S2(ConfigBits[308+2]),
    .S2N(ConfigBits_N[308+2]),
    .S3(ConfigBits[308+3]),
    .S3N(ConfigBits_N[308+3]),
    .X(JS2BEG1)
);

 //switch matrix multiplexer JS2BEG2 MUX-16
assign JS2BEG2_input = {LH_O,LG_O,LF_O,LE_O,LD_O,LB_O,LA_O,W2END3,W1END7,S2END3,S1END3,E2END3,E1END5,E1END1,N1END7,N1END3};
cus_mux161 inst_cus_mux161_JS2BEG2 (
    .A0(JS2BEG2_input[0]),
    .A1(JS2BEG2_input[1]),
    .A2(JS2BEG2_input[2]),
    .A3(JS2BEG2_input[3]),
    .A4(JS2BEG2_input[4]),
    .A5(JS2BEG2_input[5]),
    .A6(JS2BEG2_input[6]),
    .A7(JS2BEG2_input[7]),
    .A8(JS2BEG2_input[8]),
    .A9(JS2BEG2_input[9]),
    .A10(JS2BEG2_input[10]),
    .A11(JS2BEG2_input[11]),
    .A12(JS2BEG2_input[12]),
    .A13(JS2BEG2_input[13]),
    .A14(JS2BEG2_input[14]),
    .A15(JS2BEG2_input[15]),
    .S0(ConfigBits[312+0]),
    .S0N(ConfigBits_N[312+0]),
    .S1(ConfigBits[312+1]),
    .S1N(ConfigBits_N[312+1]),
    .S2(ConfigBits[312+2]),
    .S2N(ConfigBits_N[312+2]),
    .S3(ConfigBits[312+3]),
    .S3N(ConfigBits_N[312+3]),
    .X(JS2BEG2)
);

 //switch matrix multiplexer JS2BEG3 MUX-16
assign JS2BEG3_input = {LH_O,LG_O,LF_O,LE_O,LC_O,LB_O,LA_O,W2END4,W1END6,S2END4,S1END0,E2END4,E1END4,E1END2,N2END4,N1END0};
cus_mux161 inst_cus_mux161_JS2BEG3 (
    .A0(JS2BEG3_input[0]),
    .A1(JS2BEG3_input[1]),
    .A2(JS2BEG3_input[2]),
    .A3(JS2BEG3_input[3]),
    .A4(JS2BEG3_input[4]),
    .A5(JS2BEG3_input[5]),
    .A6(JS2BEG3_input[6]),
    .A7(JS2BEG3_input[7]),
    .A8(JS2BEG3_input[8]),
    .A9(JS2BEG3_input[9]),
    .A10(JS2BEG3_input[10]),
    .A11(JS2BEG3_input[11]),
    .A12(JS2BEG3_input[12]),
    .A13(JS2BEG3_input[13]),
    .A14(JS2BEG3_input[14]),
    .A15(JS2BEG3_input[15]),
    .S0(ConfigBits[316+0]),
    .S0N(ConfigBits_N[316+0]),
    .S1(ConfigBits[316+1]),
    .S1N(ConfigBits_N[316+1]),
    .S2(ConfigBits[316+2]),
    .S2N(ConfigBits_N[316+2]),
    .S3(ConfigBits[316+3]),
    .S3N(ConfigBits_N[316+3]),
    .X(JS2BEG3)
);

 //switch matrix multiplexer JS2BEG4 MUX-16
assign JS2BEG4_input = {LH_O,LG_O,LF_O,LD_O,LC_O,LB_O,LA_O,W2END5,W1END3,W1END1,S2END5,S1END1,E2END5,E1END1,N2END5,N1END1};
cus_mux161 inst_cus_mux161_JS2BEG4 (
    .A0(JS2BEG4_input[0]),
    .A1(JS2BEG4_input[1]),
    .A2(JS2BEG4_input[2]),
    .A3(JS2BEG4_input[3]),
    .A4(JS2BEG4_input[4]),
    .A5(JS2BEG4_input[5]),
    .A6(JS2BEG4_input[6]),
    .A7(JS2BEG4_input[7]),
    .A8(JS2BEG4_input[8]),
    .A9(JS2BEG4_input[9]),
    .A10(JS2BEG4_input[10]),
    .A11(JS2BEG4_input[11]),
    .A12(JS2BEG4_input[12]),
    .A13(JS2BEG4_input[13]),
    .A14(JS2BEG4_input[14]),
    .A15(JS2BEG4_input[15]),
    .S0(ConfigBits[320+0]),
    .S0N(ConfigBits_N[320+0]),
    .S1(ConfigBits[320+1]),
    .S1N(ConfigBits_N[320+1]),
    .S2(ConfigBits[320+2]),
    .S2N(ConfigBits_N[320+2]),
    .S3(ConfigBits[320+3]),
    .S3N(ConfigBits_N[320+3]),
    .X(JS2BEG4)
);

 //switch matrix multiplexer JS2BEG5 MUX-16
assign JS2BEG5_input = {LH_O,LG_O,LE_O,LD_O,LC_O,LB_O,LA_O,W2END6,W1END2,W1END0,S2END6,S1END2,E2END6,E1END2,N2END6,N1END2};
cus_mux161 inst_cus_mux161_JS2BEG5 (
    .A0(JS2BEG5_input[0]),
    .A1(JS2BEG5_input[1]),
    .A2(JS2BEG5_input[2]),
    .A3(JS2BEG5_input[3]),
    .A4(JS2BEG5_input[4]),
    .A5(JS2BEG5_input[5]),
    .A6(JS2BEG5_input[6]),
    .A7(JS2BEG5_input[7]),
    .A8(JS2BEG5_input[8]),
    .A9(JS2BEG5_input[9]),
    .A10(JS2BEG5_input[10]),
    .A11(JS2BEG5_input[11]),
    .A12(JS2BEG5_input[12]),
    .A13(JS2BEG5_input[13]),
    .A14(JS2BEG5_input[14]),
    .A15(JS2BEG5_input[15]),
    .S0(ConfigBits[324+0]),
    .S0N(ConfigBits_N[324+0]),
    .S1(ConfigBits[324+1]),
    .S1N(ConfigBits_N[324+1]),
    .S2(ConfigBits[324+2]),
    .S2N(ConfigBits_N[324+2]),
    .S3(ConfigBits[324+3]),
    .S3N(ConfigBits_N[324+3]),
    .X(JS2BEG5)
);

 //switch matrix multiplexer JS2BEG6 MUX-16
assign JS2BEG6_input = {LH_O,LF_O,LE_O,LD_O,LC_O,LB_O,LA_O,W2END7,W1END3,W1END1,S2END7,S1END3,E2END7,E1END3,N2END7,N1END3};
cus_mux161 inst_cus_mux161_JS2BEG6 (
    .A0(JS2BEG6_input[0]),
    .A1(JS2BEG6_input[1]),
    .A2(JS2BEG6_input[2]),
    .A3(JS2BEG6_input[3]),
    .A4(JS2BEG6_input[4]),
    .A5(JS2BEG6_input[5]),
    .A6(JS2BEG6_input[6]),
    .A7(JS2BEG6_input[7]),
    .A8(JS2BEG6_input[8]),
    .A9(JS2BEG6_input[9]),
    .A10(JS2BEG6_input[10]),
    .A11(JS2BEG6_input[11]),
    .A12(JS2BEG6_input[12]),
    .A13(JS2BEG6_input[13]),
    .A14(JS2BEG6_input[14]),
    .A15(JS2BEG6_input[15]),
    .S0(ConfigBits[328+0]),
    .S0N(ConfigBits_N[328+0]),
    .S1(ConfigBits[328+1]),
    .S1N(ConfigBits_N[328+1]),
    .S2(ConfigBits[328+2]),
    .S2N(ConfigBits_N[328+2]),
    .S3(ConfigBits[328+3]),
    .S3N(ConfigBits_N[328+3]),
    .X(JS2BEG6)
);

 //switch matrix multiplexer JS2BEG7 MUX-16
assign JS2BEG7_input = {LG_O,LF_O,LE_O,LD_O,LC_O,LB_O,LA_O,W2END0,W1END2,W1END0,S2END0,S1END0,E2END0,E1END0,N2END0,N1END0};
cus_mux161 inst_cus_mux161_JS2BEG7 (
    .A0(JS2BEG7_input[0]),
    .A1(JS2BEG7_input[1]),
    .A2(JS2BEG7_input[2]),
    .A3(JS2BEG7_input[3]),
    .A4(JS2BEG7_input[4]),
    .A5(JS2BEG7_input[5]),
    .A6(JS2BEG7_input[6]),
    .A7(JS2BEG7_input[7]),
    .A8(JS2BEG7_input[8]),
    .A9(JS2BEG7_input[9]),
    .A10(JS2BEG7_input[10]),
    .A11(JS2BEG7_input[11]),
    .A12(JS2BEG7_input[12]),
    .A13(JS2BEG7_input[13]),
    .A14(JS2BEG7_input[14]),
    .A15(JS2BEG7_input[15]),
    .S0(ConfigBits[332+0]),
    .S0N(ConfigBits_N[332+0]),
    .S1(ConfigBits[332+1]),
    .S1N(ConfigBits_N[332+1]),
    .S2(ConfigBits[332+2]),
    .S2N(ConfigBits_N[332+2]),
    .S3(ConfigBits[332+3]),
    .S3N(ConfigBits_N[332+3]),
    .X(JS2BEG7)
);

 //switch matrix multiplexer JW2BEG0 MUX-16
assign JW2BEG0_input = {LH_O,LG_O,LF_O,LE_O,LD_O,LC_O,LB_O,W2END1,W1END4,S2END1,S1END1,E2END1,E1END7,N2END1,N1END3,N1END1};
cus_mux161 inst_cus_mux161_JW2BEG0 (
    .A0(JW2BEG0_input[0]),
    .A1(JW2BEG0_input[1]),
    .A2(JW2BEG0_input[2]),
    .A3(JW2BEG0_input[3]),
    .A4(JW2BEG0_input[4]),
    .A5(JW2BEG0_input[5]),
    .A6(JW2BEG0_input[6]),
    .A7(JW2BEG0_input[7]),
    .A8(JW2BEG0_input[8]),
    .A9(JW2BEG0_input[9]),
    .A10(JW2BEG0_input[10]),
    .A11(JW2BEG0_input[11]),
    .A12(JW2BEG0_input[12]),
    .A13(JW2BEG0_input[13]),
    .A14(JW2BEG0_input[14]),
    .A15(JW2BEG0_input[15]),
    .S0(ConfigBits[336+0]),
    .S0N(ConfigBits_N[336+0]),
    .S1(ConfigBits[336+1]),
    .S1N(ConfigBits_N[336+1]),
    .S2(ConfigBits[336+2]),
    .S2N(ConfigBits_N[336+2]),
    .S3(ConfigBits[336+3]),
    .S3N(ConfigBits_N[336+3]),
    .X(JW2BEG0)
);

 //switch matrix multiplexer JW2BEG1 MUX-16
assign JW2BEG1_input = {LH_O,LG_O,LF_O,LE_O,LD_O,LC_O,LA_O,W2END2,W1END5,S2END2,S1END2,E2END2,E1END6,N2END2,N1END2,N1END0};
cus_mux161 inst_cus_mux161_JW2BEG1 (
    .A0(JW2BEG1_input[0]),
    .A1(JW2BEG1_input[1]),
    .A2(JW2BEG1_input[2]),
    .A3(JW2BEG1_input[3]),
    .A4(JW2BEG1_input[4]),
    .A5(JW2BEG1_input[5]),
    .A6(JW2BEG1_input[6]),
    .A7(JW2BEG1_input[7]),
    .A8(JW2BEG1_input[8]),
    .A9(JW2BEG1_input[9]),
    .A10(JW2BEG1_input[10]),
    .A11(JW2BEG1_input[11]),
    .A12(JW2BEG1_input[12]),
    .A13(JW2BEG1_input[13]),
    .A14(JW2BEG1_input[14]),
    .A15(JW2BEG1_input[15]),
    .S0(ConfigBits[340+0]),
    .S0N(ConfigBits_N[340+0]),
    .S1(ConfigBits[340+1]),
    .S1N(ConfigBits_N[340+1]),
    .S2(ConfigBits[340+2]),
    .S2N(ConfigBits_N[340+2]),
    .S3(ConfigBits[340+3]),
    .S3N(ConfigBits_N[340+3]),
    .X(JW2BEG1)
);

 //switch matrix multiplexer JW2BEG2 MUX-16
assign JW2BEG2_input = {LH_O,LG_O,LF_O,LE_O,LD_O,LB_O,LA_O,W2END3,W1END7,S1END7,S1END3,E1END5,E1END3,N2END3,N1END3,N1END1};
cus_mux161 inst_cus_mux161_JW2BEG2 (
    .A0(JW2BEG2_input[0]),
    .A1(JW2BEG2_input[1]),
    .A2(JW2BEG2_input[2]),
    .A3(JW2BEG2_input[3]),
    .A4(JW2BEG2_input[4]),
    .A5(JW2BEG2_input[5]),
    .A6(JW2BEG2_input[6]),
    .A7(JW2BEG2_input[7]),
    .A8(JW2BEG2_input[8]),
    .A9(JW2BEG2_input[9]),
    .A10(JW2BEG2_input[10]),
    .A11(JW2BEG2_input[11]),
    .A12(JW2BEG2_input[12]),
    .A13(JW2BEG2_input[13]),
    .A14(JW2BEG2_input[14]),
    .A15(JW2BEG2_input[15]),
    .S0(ConfigBits[344+0]),
    .S0N(ConfigBits_N[344+0]),
    .S1(ConfigBits[344+1]),
    .S1N(ConfigBits_N[344+1]),
    .S2(ConfigBits[344+2]),
    .S2N(ConfigBits_N[344+2]),
    .S3(ConfigBits[344+3]),
    .S3N(ConfigBits_N[344+3]),
    .X(JW2BEG2)
);

 //switch matrix multiplexer JW2BEG3 MUX-16
assign JW2BEG3_input = {LH_O,LG_O,LF_O,LE_O,LC_O,LB_O,LA_O,W2END4,W1END6,S2END4,S1END0,E2END4,E1END4,N2END4,N1END2,N1END0};
cus_mux161 inst_cus_mux161_JW2BEG3 (
    .A0(JW2BEG3_input[0]),
    .A1(JW2BEG3_input[1]),
    .A2(JW2BEG3_input[2]),
    .A3(JW2BEG3_input[3]),
    .A4(JW2BEG3_input[4]),
    .A5(JW2BEG3_input[5]),
    .A6(JW2BEG3_input[6]),
    .A7(JW2BEG3_input[7]),
    .A8(JW2BEG3_input[8]),
    .A9(JW2BEG3_input[9]),
    .A10(JW2BEG3_input[10]),
    .A11(JW2BEG3_input[11]),
    .A12(JW2BEG3_input[12]),
    .A13(JW2BEG3_input[13]),
    .A14(JW2BEG3_input[14]),
    .A15(JW2BEG3_input[15]),
    .S0(ConfigBits[348+0]),
    .S0N(ConfigBits_N[348+0]),
    .S1(ConfigBits[348+1]),
    .S1N(ConfigBits_N[348+1]),
    .S2(ConfigBits[348+2]),
    .S2N(ConfigBits_N[348+2]),
    .S3(ConfigBits[348+3]),
    .S3N(ConfigBits_N[348+3]),
    .X(JW2BEG3)
);

 //switch matrix multiplexer JW2BEG4 MUX-16
assign JW2BEG4_input = {LH_O,LG_O,LF_O,LD_O,LC_O,LB_O,LA_O,W2END5,W1END1,S2END5,S1END3,S1END1,E2END5,E1END1,N2END5,N1END1};
cus_mux161 inst_cus_mux161_JW2BEG4 (
    .A0(JW2BEG4_input[0]),
    .A1(JW2BEG4_input[1]),
    .A2(JW2BEG4_input[2]),
    .A3(JW2BEG4_input[3]),
    .A4(JW2BEG4_input[4]),
    .A5(JW2BEG4_input[5]),
    .A6(JW2BEG4_input[6]),
    .A7(JW2BEG4_input[7]),
    .A8(JW2BEG4_input[8]),
    .A9(JW2BEG4_input[9]),
    .A10(JW2BEG4_input[10]),
    .A11(JW2BEG4_input[11]),
    .A12(JW2BEG4_input[12]),
    .A13(JW2BEG4_input[13]),
    .A14(JW2BEG4_input[14]),
    .A15(JW2BEG4_input[15]),
    .S0(ConfigBits[352+0]),
    .S0N(ConfigBits_N[352+0]),
    .S1(ConfigBits[352+1]),
    .S1N(ConfigBits_N[352+1]),
    .S2(ConfigBits[352+2]),
    .S2N(ConfigBits_N[352+2]),
    .S3(ConfigBits[352+3]),
    .S3N(ConfigBits_N[352+3]),
    .X(JW2BEG4)
);

 //switch matrix multiplexer JW2BEG5 MUX-16
assign JW2BEG5_input = {LH_O,LG_O,LE_O,LD_O,LC_O,LB_O,LA_O,W2END6,W1END2,S2END6,S1END2,S1END0,E2END6,E1END2,N2END6,N1END2};
cus_mux161 inst_cus_mux161_JW2BEG5 (
    .A0(JW2BEG5_input[0]),
    .A1(JW2BEG5_input[1]),
    .A2(JW2BEG5_input[2]),
    .A3(JW2BEG5_input[3]),
    .A4(JW2BEG5_input[4]),
    .A5(JW2BEG5_input[5]),
    .A6(JW2BEG5_input[6]),
    .A7(JW2BEG5_input[7]),
    .A8(JW2BEG5_input[8]),
    .A9(JW2BEG5_input[9]),
    .A10(JW2BEG5_input[10]),
    .A11(JW2BEG5_input[11]),
    .A12(JW2BEG5_input[12]),
    .A13(JW2BEG5_input[13]),
    .A14(JW2BEG5_input[14]),
    .A15(JW2BEG5_input[15]),
    .S0(ConfigBits[356+0]),
    .S0N(ConfigBits_N[356+0]),
    .S1(ConfigBits[356+1]),
    .S1N(ConfigBits_N[356+1]),
    .S2(ConfigBits[356+2]),
    .S2N(ConfigBits_N[356+2]),
    .S3(ConfigBits[356+3]),
    .S3N(ConfigBits_N[356+3]),
    .X(JW2BEG5)
);

 //switch matrix multiplexer JW2BEG6 MUX-16
assign JW2BEG6_input = {LH_O,LF_O,LE_O,LD_O,LC_O,LB_O,LA_O,W2END7,W1END3,S2END7,S1END3,S1END1,E2END7,E1END3,N2END7,N1END3};
cus_mux161 inst_cus_mux161_JW2BEG6 (
    .A0(JW2BEG6_input[0]),
    .A1(JW2BEG6_input[1]),
    .A2(JW2BEG6_input[2]),
    .A3(JW2BEG6_input[3]),
    .A4(JW2BEG6_input[4]),
    .A5(JW2BEG6_input[5]),
    .A6(JW2BEG6_input[6]),
    .A7(JW2BEG6_input[7]),
    .A8(JW2BEG6_input[8]),
    .A9(JW2BEG6_input[9]),
    .A10(JW2BEG6_input[10]),
    .A11(JW2BEG6_input[11]),
    .A12(JW2BEG6_input[12]),
    .A13(JW2BEG6_input[13]),
    .A14(JW2BEG6_input[14]),
    .A15(JW2BEG6_input[15]),
    .S0(ConfigBits[360+0]),
    .S0N(ConfigBits_N[360+0]),
    .S1(ConfigBits[360+1]),
    .S1N(ConfigBits_N[360+1]),
    .S2(ConfigBits[360+2]),
    .S2N(ConfigBits_N[360+2]),
    .S3(ConfigBits[360+3]),
    .S3N(ConfigBits_N[360+3]),
    .X(JW2BEG6)
);

 //switch matrix multiplexer JW2BEG7 MUX-16
assign JW2BEG7_input = {LG_O,LF_O,LE_O,LD_O,LC_O,LB_O,LA_O,W2END0,W1END0,S2END0,S1END2,S1END0,E2END0,E1END0,N1END4,N1END0};
cus_mux161 inst_cus_mux161_JW2BEG7 (
    .A0(JW2BEG7_input[0]),
    .A1(JW2BEG7_input[1]),
    .A2(JW2BEG7_input[2]),
    .A3(JW2BEG7_input[3]),
    .A4(JW2BEG7_input[4]),
    .A5(JW2BEG7_input[5]),
    .A6(JW2BEG7_input[6]),
    .A7(JW2BEG7_input[7]),
    .A8(JW2BEG7_input[8]),
    .A9(JW2BEG7_input[9]),
    .A10(JW2BEG7_input[10]),
    .A11(JW2BEG7_input[11]),
    .A12(JW2BEG7_input[12]),
    .A13(JW2BEG7_input[13]),
    .A14(JW2BEG7_input[14]),
    .A15(JW2BEG7_input[15]),
    .S0(ConfigBits[364+0]),
    .S0N(ConfigBits_N[364+0]),
    .S1(ConfigBits[364+1]),
    .S1N(ConfigBits_N[364+1]),
    .S2(ConfigBits[364+2]),
    .S2N(ConfigBits_N[364+2]),
    .S3(ConfigBits[364+3]),
    .S3N(ConfigBits_N[364+3]),
    .X(JW2BEG7)
);

 //switch matrix multiplexer J_l_AB_BEG0 MUX-4
assign J_l_AB_BEG0_input = {JN2END1,W1END0,S1END3,N1END7};
cus_mux41 inst_cus_mux41_J_l_AB_BEG0 (
    .A0(J_l_AB_BEG0_input[0]),
    .A1(J_l_AB_BEG0_input[1]),
    .A2(J_l_AB_BEG0_input[2]),
    .A3(J_l_AB_BEG0_input[3]),
    .S0(ConfigBits[368+0]),
    .S0N(ConfigBits_N[368+0]),
    .S1(ConfigBits[368+1]),
    .S1N(ConfigBits_N[368+1]),
    .X(J_l_AB_BEG0)
);

 //switch matrix multiplexer J_l_AB_BEG1 MUX-4
assign J_l_AB_BEG1_input = {JE2END1,W2END7,S1END2,E1END2};
cus_mux41 inst_cus_mux41_J_l_AB_BEG1 (
    .A0(J_l_AB_BEG1_input[0]),
    .A1(J_l_AB_BEG1_input[1]),
    .A2(J_l_AB_BEG1_input[2]),
    .A3(J_l_AB_BEG1_input[3]),
    .S0(ConfigBits[370+0]),
    .S0N(ConfigBits_N[370+0]),
    .S1(ConfigBits[370+1]),
    .S1N(ConfigBits_N[370+1]),
    .X(J_l_AB_BEG1)
);

 //switch matrix multiplexer J_l_AB_BEG2 MUX-4
assign J_l_AB_BEG2_input = {JS2END1,W1END1,E1END1,N1END1};
cus_mux41 inst_cus_mux41_J_l_AB_BEG2 (
    .A0(J_l_AB_BEG2_input[0]),
    .A1(J_l_AB_BEG2_input[1]),
    .A2(J_l_AB_BEG2_input[2]),
    .A3(J_l_AB_BEG2_input[3]),
    .S0(ConfigBits[372+0]),
    .S0N(ConfigBits_N[372+0]),
    .S1(ConfigBits[372+1]),
    .S1N(ConfigBits_N[372+1]),
    .X(J_l_AB_BEG2)
);

 //switch matrix multiplexer J_l_AB_BEG3 MUX-4
assign J_l_AB_BEG3_input = {JW2END1,S1END0,E1END6,N1END0};
cus_mux41 inst_cus_mux41_J_l_AB_BEG3 (
    .A0(J_l_AB_BEG3_input[0]),
    .A1(J_l_AB_BEG3_input[1]),
    .A2(J_l_AB_BEG3_input[2]),
    .A3(J_l_AB_BEG3_input[3]),
    .S0(ConfigBits[374+0]),
    .S0N(ConfigBits_N[374+0]),
    .S1(ConfigBits[374+1]),
    .S1N(ConfigBits_N[374+1]),
    .X(J_l_AB_BEG3)
);

 //switch matrix multiplexer J_l_CD_BEG0 MUX-4
assign J_l_CD_BEG0_input = {JN2END2,W1END2,S1END7,E2END3};
cus_mux41 inst_cus_mux41_J_l_CD_BEG0 (
    .A0(J_l_CD_BEG0_input[0]),
    .A1(J_l_CD_BEG0_input[1]),
    .A2(J_l_CD_BEG0_input[2]),
    .A3(J_l_CD_BEG0_input[3]),
    .S0(ConfigBits[376+0]),
    .S0N(ConfigBits_N[376+0]),
    .S1(ConfigBits[376+1]),
    .S1N(ConfigBits_N[376+1]),
    .X(J_l_CD_BEG0)
);

 //switch matrix multiplexer J_l_CD_BEG1 MUX-4
assign J_l_CD_BEG1_input = {JE2END2,W2END7,E2END2,N1END2};
cus_mux41 inst_cus_mux41_J_l_CD_BEG1 (
    .A0(J_l_CD_BEG1_input[0]),
    .A1(J_l_CD_BEG1_input[1]),
    .A2(J_l_CD_BEG1_input[2]),
    .A3(J_l_CD_BEG1_input[3]),
    .S0(ConfigBits[378+0]),
    .S0N(ConfigBits_N[378+0]),
    .S1(ConfigBits[378+1]),
    .S1N(ConfigBits_N[378+1]),
    .X(J_l_CD_BEG1)
);

 //switch matrix multiplexer J_l_CD_BEG2 MUX-4
assign J_l_CD_BEG2_input = {JS2END2,S1END1,E1END5,N1END5};
cus_mux41 inst_cus_mux41_J_l_CD_BEG2 (
    .A0(J_l_CD_BEG2_input[0]),
    .A1(J_l_CD_BEG2_input[1]),
    .A2(J_l_CD_BEG2_input[2]),
    .A3(J_l_CD_BEG2_input[3]),
    .S0(ConfigBits[380+0]),
    .S0N(ConfigBits_N[380+0]),
    .S1(ConfigBits[380+1]),
    .S1N(ConfigBits_N[380+1]),
    .X(J_l_CD_BEG2)
);

 //switch matrix multiplexer J_l_CD_BEG3 MUX-4
assign J_l_CD_BEG3_input = {JW2END2,W1END4,S1END4,N1END0};
cus_mux41 inst_cus_mux41_J_l_CD_BEG3 (
    .A0(J_l_CD_BEG3_input[0]),
    .A1(J_l_CD_BEG3_input[1]),
    .A2(J_l_CD_BEG3_input[2]),
    .A3(J_l_CD_BEG3_input[3]),
    .S0(ConfigBits[382+0]),
    .S0N(ConfigBits_N[382+0]),
    .S1(ConfigBits[382+1]),
    .S1N(ConfigBits_N[382+1]),
    .X(J_l_CD_BEG3)
);

 //switch matrix multiplexer J_l_EF_BEG0 MUX-4
assign J_l_EF_BEG0_input = {JN2END3,W2END3,E2END3,N1END3};
cus_mux41 inst_cus_mux41_J_l_EF_BEG0 (
    .A0(J_l_EF_BEG0_input[0]),
    .A1(J_l_EF_BEG0_input[1]),
    .A2(J_l_EF_BEG0_input[2]),
    .A3(J_l_EF_BEG0_input[3]),
    .S0(ConfigBits[384+0]),
    .S0N(ConfigBits_N[384+0]),
    .S1(ConfigBits[384+1]),
    .S1N(ConfigBits_N[384+1]),
    .X(J_l_EF_BEG0)
);

 //switch matrix multiplexer J_l_EF_BEG1 MUX-4
assign J_l_EF_BEG1_input = {JE2END3,S1END2,E2END2,N1END6};
cus_mux41 inst_cus_mux41_J_l_EF_BEG1 (
    .A0(J_l_EF_BEG1_input[0]),
    .A1(J_l_EF_BEG1_input[1]),
    .A2(J_l_EF_BEG1_input[2]),
    .A3(J_l_EF_BEG1_input[3]),
    .S0(ConfigBits[386+0]),
    .S0N(ConfigBits_N[386+0]),
    .S1(ConfigBits[386+1]),
    .S1N(ConfigBits_N[386+1]),
    .X(J_l_EF_BEG1)
);

 //switch matrix multiplexer J_l_EF_BEG2 MUX-4
assign J_l_EF_BEG2_input = {JS2END3,W2END4,S1END5,N1END1};
cus_mux41 inst_cus_mux41_J_l_EF_BEG2 (
    .A0(J_l_EF_BEG2_input[0]),
    .A1(J_l_EF_BEG2_input[1]),
    .A2(J_l_EF_BEG2_input[2]),
    .A3(J_l_EF_BEG2_input[3]),
    .S0(ConfigBits[388+0]),
    .S0N(ConfigBits_N[388+0]),
    .S1(ConfigBits[388+1]),
    .S1N(ConfigBits_N[388+1]),
    .X(J_l_EF_BEG2)
);

 //switch matrix multiplexer J_l_EF_BEG3 MUX-4
assign J_l_EF_BEG3_input = {JW2END3,W1END5,S1END0,E1END3};
cus_mux41 inst_cus_mux41_J_l_EF_BEG3 (
    .A0(J_l_EF_BEG3_input[0]),
    .A1(J_l_EF_BEG3_input[1]),
    .A2(J_l_EF_BEG3_input[2]),
    .A3(J_l_EF_BEG3_input[3]),
    .S0(ConfigBits[390+0]),
    .S0N(ConfigBits_N[390+0]),
    .S1(ConfigBits[390+1]),
    .S1N(ConfigBits_N[390+1]),
    .X(J_l_EF_BEG3)
);

 //switch matrix multiplexer J_l_GH_BEG0 MUX-4
assign J_l_GH_BEG0_input = {JN2END4,S1END3,E1END0,N1END3};
cus_mux41 inst_cus_mux41_J_l_GH_BEG0 (
    .A0(J_l_GH_BEG0_input[0]),
    .A1(J_l_GH_BEG0_input[1]),
    .A2(J_l_GH_BEG0_input[2]),
    .A3(J_l_GH_BEG0_input[3]),
    .S0(ConfigBits[392+0]),
    .S0N(ConfigBits_N[392+0]),
    .S1(ConfigBits[392+1]),
    .S1N(ConfigBits_N[392+1]),
    .X(J_l_GH_BEG0)
);

 //switch matrix multiplexer J_l_GH_BEG1 MUX-4
assign J_l_GH_BEG1_input = {JE2END4,W2END2,S1END6,N1END2};
cus_mux41 inst_cus_mux41_J_l_GH_BEG1 (
    .A0(J_l_GH_BEG1_input[0]),
    .A1(J_l_GH_BEG1_input[1]),
    .A2(J_l_GH_BEG1_input[2]),
    .A3(J_l_GH_BEG1_input[3]),
    .S0(ConfigBits[394+0]),
    .S0N(ConfigBits_N[394+0]),
    .S1(ConfigBits[394+1]),
    .S1N(ConfigBits_N[394+1]),
    .X(J_l_GH_BEG1)
);

 //switch matrix multiplexer J_l_GH_BEG2 MUX-4
assign J_l_GH_BEG2_input = {JS2END4,W1END3,S1END1,E1END7};
cus_mux41 inst_cus_mux41_J_l_GH_BEG2 (
    .A0(J_l_GH_BEG2_input[0]),
    .A1(J_l_GH_BEG2_input[1]),
    .A2(J_l_GH_BEG2_input[2]),
    .A3(J_l_GH_BEG2_input[3]),
    .S0(ConfigBits[396+0]),
    .S0N(ConfigBits_N[396+0]),
    .S1(ConfigBits[396+1]),
    .S1N(ConfigBits_N[396+1]),
    .X(J_l_GH_BEG2)
);

 //switch matrix multiplexer J_l_GH_BEG3 MUX-4
assign J_l_GH_BEG3_input = {JW2END4,W2END0,E1END4,N1END4};
cus_mux41 inst_cus_mux41_J_l_GH_BEG3 (
    .A0(J_l_GH_BEG3_input[0]),
    .A1(J_l_GH_BEG3_input[1]),
    .A2(J_l_GH_BEG3_input[2]),
    .A3(J_l_GH_BEG3_input[3]),
    .S0(ConfigBits[398+0]),
    .S0N(ConfigBits_N[398+0]),
    .S1(ConfigBits[398+1]),
    .S1N(ConfigBits_N[398+1]),
    .X(J_l_GH_BEG3)
);

 //switch matrix multiplexer GCLK_BEG0 MUX-4
assign GCLK_BEG0_input = {N_GBUF_END3,N_GBUF_END2,N_GBUF_END1,N_GBUF_END0};
cus_mux41 inst_cus_mux41_GCLK_BEG0 (
    .A0(GCLK_BEG0_input[0]),
    .A1(GCLK_BEG0_input[1]),
    .A2(GCLK_BEG0_input[2]),
    .A3(GCLK_BEG0_input[3]),
    .S0(ConfigBits[400+0]),
    .S0N(ConfigBits_N[400+0]),
    .S1(ConfigBits[400+1]),
    .S1N(ConfigBits_N[400+1]),
    .X(GCLK_BEG0)
);

 //switch matrix multiplexer GSR_BEG0 MUX-4
assign GSR_BEG0_input = {N_GBUF_END3,N_GBUF_END2,N_GBUF_END1,N_GBUF_END0};
cus_mux41 inst_cus_mux41_GSR_BEG0 (
    .A0(GSR_BEG0_input[0]),
    .A1(GSR_BEG0_input[1]),
    .A2(GSR_BEG0_input[2]),
    .A3(GSR_BEG0_input[3]),
    .S0(ConfigBits[402+0]),
    .S0N(ConfigBits_N[402+0]),
    .S1(ConfigBits[402+1]),
    .S1N(ConfigBits_N[402+1]),
    .X(GSR_BEG0)
);

 //switch matrix multiplexer GEN_BEG0 MUX-4
assign GEN_BEG0_input = {N_GBUF_END3,N_GBUF_END2,N_GBUF_END1,N_GBUF_END0};
cus_mux41 inst_cus_mux41_GEN_BEG0 (
    .A0(GEN_BEG0_input[0]),
    .A1(GEN_BEG0_input[1]),
    .A2(GEN_BEG0_input[2]),
    .A3(GEN_BEG0_input[3]),
    .S0(ConfigBits[404+0]),
    .S0N(ConfigBits_N[404+0]),
    .S1(ConfigBits[404+1]),
    .S1N(ConfigBits_N[404+1]),
    .X(GEN_BEG0)
);

 //switch matrix multiplexer J_SR_BEG0 MUX-9
assign J_SR_BEG0_input = {GSR_END0,JW2END1,JS2END1,JE2END1,JN2END1,J2MID_EFb_END0,J2MID_CDb_END0,J2MID_ABb_END0,J2MID_GHa_END0};
cus_mux161 inst_cus_mux161_J_SR_BEG0 (
    .A0(J_SR_BEG0_input[0]),
    .A1(J_SR_BEG0_input[1]),
    .A2(J_SR_BEG0_input[2]),
    .A3(J_SR_BEG0_input[3]),
    .A4(J_SR_BEG0_input[4]),
    .A5(J_SR_BEG0_input[5]),
    .A6(J_SR_BEG0_input[6]),
    .A7(J_SR_BEG0_input[7]),
    .A8(J_SR_BEG0_input[8]),
    .A9(GND0),
    .A10(GND0),
    .A11(GND0),
    .A12(GND0),
    .A13(GND0),
    .A14(GND0),
    .A15(GND0),
    .S0(ConfigBits[406+0]),
    .S0N(ConfigBits_N[406+0]),
    .S1(ConfigBits[406+1]),
    .S1N(ConfigBits_N[406+1]),
    .S2(ConfigBits[406+2]),
    .S2N(ConfigBits_N[406+2]),
    .S3(ConfigBits[406+3]),
    .S3N(ConfigBits_N[406+3]),
    .X(J_SR_BEG0)
);

 //switch matrix multiplexer J_EN_BEG0 MUX-9
assign J_EN_BEG0_input = {GEN_END0,JW2END2,JS2END2,JE2END2,JN2END2,J2MID_EFb_END3,J2MID_CDb_END3,J2MID_ABb_END3,J2MID_GHa_END3};
cus_mux161 inst_cus_mux161_J_EN_BEG0 (
    .A0(J_EN_BEG0_input[0]),
    .A1(J_EN_BEG0_input[1]),
    .A2(J_EN_BEG0_input[2]),
    .A3(J_EN_BEG0_input[3]),
    .A4(J_EN_BEG0_input[4]),
    .A5(J_EN_BEG0_input[5]),
    .A6(J_EN_BEG0_input[6]),
    .A7(J_EN_BEG0_input[7]),
    .A8(J_EN_BEG0_input[8]),
    .A9(GND0),
    .A10(GND0),
    .A11(GND0),
    .A12(GND0),
    .A13(GND0),
    .A14(GND0),
    .A15(GND0),
    .S0(ConfigBits[410+0]),
    .S0N(ConfigBits_N[410+0]),
    .S1(ConfigBits[410+1]),
    .S1N(ConfigBits_N[410+1]),
    .S2(ConfigBits[410+2]),
    .S2N(ConfigBits_N[410+2]),
    .S3(ConfigBits[410+3]),
    .S3N(ConfigBits_N[410+3]),
    .X(J_EN_BEG0)
);

endmodule
module LUT4x8_ha
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=566
    )
    (
 //N
        output  [3:0] N_GBUF_BEG,        //Port(Name=N_GBUF_BEG,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=4,Side=N)
        output  [7:0] N1BEG,        //Port(Name=N1BEG,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=8,Side=N)
        output  [7:0] N2BEG,        //Port(Name=N2BEG,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=8,Side=N)
        output  [7:0] N2BEGb,        //Port(Name=N2BEGb,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=8,Side=N)
        input  [7:0] S1END,        //Port(Name=S1END,IO=INPUT,XOffset=0,YOffset=1,WireCount=8,Side=N)
        input  [7:0] S2MID,        //Port(Name=S2MID,IO=INPUT,XOffset=0,YOffset=1,WireCount=8,Side=N)
        input  [7:0] S2END,        //Port(Name=S2END,IO=INPUT,XOffset=0,YOffset=1,WireCount=8,Side=N)
        output  [0:0] CO,        //Port(Name=CO,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=1,Side=N)
 //E
        output  [7:0] E1BEG,        //Port(Name=E1BEG,IO=OUTPUT,XOffset=1,YOffset=0,WireCount=8,Side=E)
        output  [7:0] E2BEG,        //Port(Name=E2BEG,IO=OUTPUT,XOffset=1,YOffset=0,WireCount=8,Side=E)
        output  [7:0] E2BEGb,        //Port(Name=E2BEGb,IO=OUTPUT,XOffset=1,YOffset=0,WireCount=8,Side=E)
        input  [7:0] W1END,        //Port(Name=W1END,IO=INPUT,XOffset=-1,YOffset=0,WireCount=8,Side=E)
        input  [7:0] W2MID,        //Port(Name=W2MID,IO=INPUT,XOffset=-1,YOffset=0,WireCount=8,Side=E)
        input  [7:0] W2END,        //Port(Name=W2END,IO=INPUT,XOffset=-1,YOffset=0,WireCount=8,Side=E)
 //W
        input  [7:0] E1END,        //Port(Name=E1END,IO=INPUT,XOffset=1,YOffset=0,WireCount=8,Side=W)
        input  [7:0] E2MID,        //Port(Name=E2MID,IO=INPUT,XOffset=1,YOffset=0,WireCount=8,Side=W)
        input  [7:0] E2END,        //Port(Name=E2END,IO=INPUT,XOffset=1,YOffset=0,WireCount=8,Side=W)
        output  [7:0] W1BEG,        //Port(Name=W1BEG,IO=OUTPUT,XOffset=-1,YOffset=0,WireCount=8,Side=W)
        output  [7:0] W2BEG,        //Port(Name=W2BEG,IO=OUTPUT,XOffset=-1,YOffset=0,WireCount=8,Side=W)
        output  [7:0] W2BEGb,        //Port(Name=W2BEGb,IO=OUTPUT,XOffset=-1,YOffset=0,WireCount=8,Side=W)
 //S
        input  [3:0] N_GBUF_END,        //Port(Name=N_GBUF_END,IO=INPUT,XOffset=0,YOffset=-1,WireCount=4,Side=S)
        input  [7:0] N1END,        //Port(Name=N1END,IO=INPUT,XOffset=0,YOffset=-1,WireCount=8,Side=S)
        input  [7:0] N2MID,        //Port(Name=N2MID,IO=INPUT,XOffset=0,YOffset=-1,WireCount=8,Side=S)
        input  [7:0] N2END,        //Port(Name=N2END,IO=INPUT,XOffset=0,YOffset=-1,WireCount=8,Side=S)
        output  [7:0] S1BEG,        //Port(Name=S1BEG,IO=OUTPUT,XOffset=0,YOffset=1,WireCount=8,Side=S)
        output  [7:0] S2BEG,        //Port(Name=S2BEG,IO=OUTPUT,XOffset=0,YOffset=1,WireCount=8,Side=S)
        output  [7:0] S2BEGb,        //Port(Name=S2BEGb,IO=OUTPUT,XOffset=0,YOffset=1,WireCount=8,Side=S)
        input  [0:0] CI,        //Port(Name=CI,IO=INPUT,XOffset=0,YOffset=-1,WireCount=1,Side=S)
    //Tile IO ports from BELs
        input  [FrameBitsPerRow-1:0] FrameData, //CONFIG_PORT
        output  [FrameBitsPerRow-1:0] FrameData_O,
        input  [MaxFramesPerCol-1:0] FrameStrobe, //CONFIG_PORT
        output  [MaxFramesPerCol-1:0] FrameStrobe_O
    //global
);
 //signal declarations
 //BEL ports (e.g., slices)
wire LA_I0;
wire LA_I1;
wire LA_I2;
wire LA_I3;
wire LA_Ci;
wire LA_SR;
wire LA_EN;
wire LA_CLK;
wire LA_O;
wire LA_Co;
wire LB_I0;
wire LB_I1;
wire LB_I2;
wire LB_I3;
wire LB_Ci;
wire LB_SR;
wire LB_EN;
wire LB_CLK;
wire LB_O;
wire LB_Co;
wire LC_I0;
wire LC_I1;
wire LC_I2;
wire LC_I3;
wire LC_Ci;
wire LC_SR;
wire LC_EN;
wire LC_CLK;
wire LC_O;
wire LC_Co;
wire LD_I0;
wire LD_I1;
wire LD_I2;
wire LD_I3;
wire LD_Ci;
wire LD_SR;
wire LD_EN;
wire LD_CLK;
wire LD_O;
wire LD_Co;
wire LE_I0;
wire LE_I1;
wire LE_I2;
wire LE_I3;
wire LE_Ci;
wire LE_SR;
wire LE_EN;
wire LE_CLK;
wire LE_O;
wire LE_Co;
wire LF_I0;
wire LF_I1;
wire LF_I2;
wire LF_I3;
wire LF_Ci;
wire LF_SR;
wire LF_EN;
wire LF_CLK;
wire LF_O;
wire LF_Co;
wire LG_I0;
wire LG_I1;
wire LG_I2;
wire LG_I3;
wire LG_Ci;
wire LG_SR;
wire LG_EN;
wire LG_CLK;
wire LG_O;
wire LG_Co;
wire LH_I0;
wire LH_I1;
wire LH_I2;
wire LH_I3;
wire LH_Ci;
wire LH_SR;
wire LH_EN;
wire LH_CLK;
wire LH_O;
wire LH_Co;
 //Jump wires
wire[4-1:0] J2MID_ABa_BEG;
wire[4-1:0] J2MID_CDa_BEG;
wire[4-1:0] J2MID_EFa_BEG;
wire[4-1:0] J2MID_GHa_BEG;
wire[4-1:0] J2MID_ABb_BEG;
wire[4-1:0] J2MID_CDb_BEG;
wire[4-1:0] J2MID_EFb_BEG;
wire[4-1:0] J2MID_GHb_BEG;
wire[4-1:0] J2END_AB_BEG;
wire[4-1:0] J2END_CD_BEG;
wire[4-1:0] J2END_EF_BEG;
wire[4-1:0] J2END_GH_BEG;
wire[8-1:0] JN2BEG;
wire[8-1:0] JE2BEG;
wire[8-1:0] JS2BEG;
wire[8-1:0] JW2BEG;
wire[4-1:0] J_l_AB_BEG;
wire[4-1:0] J_l_CD_BEG;
wire[4-1:0] J_l_EF_BEG;
wire[4-1:0] J_l_GH_BEG;
wire[1-1:0] GCLK_BEG;
wire[1-1:0] GSR_BEG;
wire[1-1:0] GEN_BEG;
wire[1-1:0] J_SR_BEG;
wire[1-1:0] J_EN_BEG;
 //internal configuration data signal to daisy-chain all BELs (if any and in the order they are listed in the fabric.csv)
wire[NoConfigBits-1:0] ConfigBits;
wire[NoConfigBits-1:0] ConfigBits_N;

 //Connection for outgoing wires
wire[FrameBitsPerRow-1:0] FrameData_i;
wire[FrameBitsPerRow-1:0] FrameData_O_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_O_i;

assign FrameData_O_i = FrameData_i;

my_buf data_inbuf_0 (
    .A(FrameData[0]),
    .X(FrameData_i[0])
);

my_buf data_inbuf_1 (
    .A(FrameData[1]),
    .X(FrameData_i[1])
);

my_buf data_inbuf_2 (
    .A(FrameData[2]),
    .X(FrameData_i[2])
);

my_buf data_inbuf_3 (
    .A(FrameData[3]),
    .X(FrameData_i[3])
);

my_buf data_inbuf_4 (
    .A(FrameData[4]),
    .X(FrameData_i[4])
);

my_buf data_inbuf_5 (
    .A(FrameData[5]),
    .X(FrameData_i[5])
);

my_buf data_inbuf_6 (
    .A(FrameData[6]),
    .X(FrameData_i[6])
);

my_buf data_inbuf_7 (
    .A(FrameData[7]),
    .X(FrameData_i[7])
);

my_buf data_inbuf_8 (
    .A(FrameData[8]),
    .X(FrameData_i[8])
);

my_buf data_inbuf_9 (
    .A(FrameData[9]),
    .X(FrameData_i[9])
);

my_buf data_inbuf_10 (
    .A(FrameData[10]),
    .X(FrameData_i[10])
);

my_buf data_inbuf_11 (
    .A(FrameData[11]),
    .X(FrameData_i[11])
);

my_buf data_inbuf_12 (
    .A(FrameData[12]),
    .X(FrameData_i[12])
);

my_buf data_inbuf_13 (
    .A(FrameData[13]),
    .X(FrameData_i[13])
);

my_buf data_inbuf_14 (
    .A(FrameData[14]),
    .X(FrameData_i[14])
);

my_buf data_inbuf_15 (
    .A(FrameData[15]),
    .X(FrameData_i[15])
);

my_buf data_inbuf_16 (
    .A(FrameData[16]),
    .X(FrameData_i[16])
);

my_buf data_inbuf_17 (
    .A(FrameData[17]),
    .X(FrameData_i[17])
);

my_buf data_inbuf_18 (
    .A(FrameData[18]),
    .X(FrameData_i[18])
);

my_buf data_inbuf_19 (
    .A(FrameData[19]),
    .X(FrameData_i[19])
);

my_buf data_inbuf_20 (
    .A(FrameData[20]),
    .X(FrameData_i[20])
);

my_buf data_inbuf_21 (
    .A(FrameData[21]),
    .X(FrameData_i[21])
);

my_buf data_inbuf_22 (
    .A(FrameData[22]),
    .X(FrameData_i[22])
);

my_buf data_inbuf_23 (
    .A(FrameData[23]),
    .X(FrameData_i[23])
);

my_buf data_inbuf_24 (
    .A(FrameData[24]),
    .X(FrameData_i[24])
);

my_buf data_inbuf_25 (
    .A(FrameData[25]),
    .X(FrameData_i[25])
);

my_buf data_inbuf_26 (
    .A(FrameData[26]),
    .X(FrameData_i[26])
);

my_buf data_inbuf_27 (
    .A(FrameData[27]),
    .X(FrameData_i[27])
);

my_buf data_inbuf_28 (
    .A(FrameData[28]),
    .X(FrameData_i[28])
);

my_buf data_inbuf_29 (
    .A(FrameData[29]),
    .X(FrameData_i[29])
);

my_buf data_inbuf_30 (
    .A(FrameData[30]),
    .X(FrameData_i[30])
);

my_buf data_inbuf_31 (
    .A(FrameData[31]),
    .X(FrameData_i[31])
);

my_buf data_outbuf_0 (
    .A(FrameData_O_i[0]),
    .X(FrameData_O[0])
);

my_buf data_outbuf_1 (
    .A(FrameData_O_i[1]),
    .X(FrameData_O[1])
);

my_buf data_outbuf_2 (
    .A(FrameData_O_i[2]),
    .X(FrameData_O[2])
);

my_buf data_outbuf_3 (
    .A(FrameData_O_i[3]),
    .X(FrameData_O[3])
);

my_buf data_outbuf_4 (
    .A(FrameData_O_i[4]),
    .X(FrameData_O[4])
);

my_buf data_outbuf_5 (
    .A(FrameData_O_i[5]),
    .X(FrameData_O[5])
);

my_buf data_outbuf_6 (
    .A(FrameData_O_i[6]),
    .X(FrameData_O[6])
);

my_buf data_outbuf_7 (
    .A(FrameData_O_i[7]),
    .X(FrameData_O[7])
);

my_buf data_outbuf_8 (
    .A(FrameData_O_i[8]),
    .X(FrameData_O[8])
);

my_buf data_outbuf_9 (
    .A(FrameData_O_i[9]),
    .X(FrameData_O[9])
);

my_buf data_outbuf_10 (
    .A(FrameData_O_i[10]),
    .X(FrameData_O[10])
);

my_buf data_outbuf_11 (
    .A(FrameData_O_i[11]),
    .X(FrameData_O[11])
);

my_buf data_outbuf_12 (
    .A(FrameData_O_i[12]),
    .X(FrameData_O[12])
);

my_buf data_outbuf_13 (
    .A(FrameData_O_i[13]),
    .X(FrameData_O[13])
);

my_buf data_outbuf_14 (
    .A(FrameData_O_i[14]),
    .X(FrameData_O[14])
);

my_buf data_outbuf_15 (
    .A(FrameData_O_i[15]),
    .X(FrameData_O[15])
);

my_buf data_outbuf_16 (
    .A(FrameData_O_i[16]),
    .X(FrameData_O[16])
);

my_buf data_outbuf_17 (
    .A(FrameData_O_i[17]),
    .X(FrameData_O[17])
);

my_buf data_outbuf_18 (
    .A(FrameData_O_i[18]),
    .X(FrameData_O[18])
);

my_buf data_outbuf_19 (
    .A(FrameData_O_i[19]),
    .X(FrameData_O[19])
);

my_buf data_outbuf_20 (
    .A(FrameData_O_i[20]),
    .X(FrameData_O[20])
);

my_buf data_outbuf_21 (
    .A(FrameData_O_i[21]),
    .X(FrameData_O[21])
);

my_buf data_outbuf_22 (
    .A(FrameData_O_i[22]),
    .X(FrameData_O[22])
);

my_buf data_outbuf_23 (
    .A(FrameData_O_i[23]),
    .X(FrameData_O[23])
);

my_buf data_outbuf_24 (
    .A(FrameData_O_i[24]),
    .X(FrameData_O[24])
);

my_buf data_outbuf_25 (
    .A(FrameData_O_i[25]),
    .X(FrameData_O[25])
);

my_buf data_outbuf_26 (
    .A(FrameData_O_i[26]),
    .X(FrameData_O[26])
);

my_buf data_outbuf_27 (
    .A(FrameData_O_i[27]),
    .X(FrameData_O[27])
);

my_buf data_outbuf_28 (
    .A(FrameData_O_i[28]),
    .X(FrameData_O[28])
);

my_buf data_outbuf_29 (
    .A(FrameData_O_i[29]),
    .X(FrameData_O[29])
);

my_buf data_outbuf_30 (
    .A(FrameData_O_i[30]),
    .X(FrameData_O[30])
);

my_buf data_outbuf_31 (
    .A(FrameData_O_i[31]),
    .X(FrameData_O[31])
);

assign FrameStrobe_O_i = FrameStrobe_i;

my_buf strobe_inbuf_0 (
    .A(FrameStrobe[0]),
    .X(FrameStrobe_i[0])
);

my_buf strobe_inbuf_1 (
    .A(FrameStrobe[1]),
    .X(FrameStrobe_i[1])
);

my_buf strobe_inbuf_2 (
    .A(FrameStrobe[2]),
    .X(FrameStrobe_i[2])
);

my_buf strobe_inbuf_3 (
    .A(FrameStrobe[3]),
    .X(FrameStrobe_i[3])
);

my_buf strobe_inbuf_4 (
    .A(FrameStrobe[4]),
    .X(FrameStrobe_i[4])
);

my_buf strobe_inbuf_5 (
    .A(FrameStrobe[5]),
    .X(FrameStrobe_i[5])
);

my_buf strobe_inbuf_6 (
    .A(FrameStrobe[6]),
    .X(FrameStrobe_i[6])
);

my_buf strobe_inbuf_7 (
    .A(FrameStrobe[7]),
    .X(FrameStrobe_i[7])
);

my_buf strobe_inbuf_8 (
    .A(FrameStrobe[8]),
    .X(FrameStrobe_i[8])
);

my_buf strobe_inbuf_9 (
    .A(FrameStrobe[9]),
    .X(FrameStrobe_i[9])
);

my_buf strobe_inbuf_10 (
    .A(FrameStrobe[10]),
    .X(FrameStrobe_i[10])
);

my_buf strobe_inbuf_11 (
    .A(FrameStrobe[11]),
    .X(FrameStrobe_i[11])
);

my_buf strobe_inbuf_12 (
    .A(FrameStrobe[12]),
    .X(FrameStrobe_i[12])
);

my_buf strobe_inbuf_13 (
    .A(FrameStrobe[13]),
    .X(FrameStrobe_i[13])
);

my_buf strobe_inbuf_14 (
    .A(FrameStrobe[14]),
    .X(FrameStrobe_i[14])
);

my_buf strobe_inbuf_15 (
    .A(FrameStrobe[15]),
    .X(FrameStrobe_i[15])
);

my_buf strobe_inbuf_16 (
    .A(FrameStrobe[16]),
    .X(FrameStrobe_i[16])
);

my_buf strobe_inbuf_17 (
    .A(FrameStrobe[17]),
    .X(FrameStrobe_i[17])
);

my_buf strobe_inbuf_18 (
    .A(FrameStrobe[18]),
    .X(FrameStrobe_i[18])
);

my_buf strobe_inbuf_19 (
    .A(FrameStrobe[19]),
    .X(FrameStrobe_i[19])
);

my_buf strobe_outbuf_0 (
    .A(FrameStrobe_O_i[0]),
    .X(FrameStrobe_O[0])
);

my_buf strobe_outbuf_1 (
    .A(FrameStrobe_O_i[1]),
    .X(FrameStrobe_O[1])
);

my_buf strobe_outbuf_2 (
    .A(FrameStrobe_O_i[2]),
    .X(FrameStrobe_O[2])
);

my_buf strobe_outbuf_3 (
    .A(FrameStrobe_O_i[3]),
    .X(FrameStrobe_O[3])
);

my_buf strobe_outbuf_4 (
    .A(FrameStrobe_O_i[4]),
    .X(FrameStrobe_O[4])
);

my_buf strobe_outbuf_5 (
    .A(FrameStrobe_O_i[5]),
    .X(FrameStrobe_O[5])
);

my_buf strobe_outbuf_6 (
    .A(FrameStrobe_O_i[6]),
    .X(FrameStrobe_O[6])
);

my_buf strobe_outbuf_7 (
    .A(FrameStrobe_O_i[7]),
    .X(FrameStrobe_O[7])
);

my_buf strobe_outbuf_8 (
    .A(FrameStrobe_O_i[8]),
    .X(FrameStrobe_O[8])
);

my_buf strobe_outbuf_9 (
    .A(FrameStrobe_O_i[9]),
    .X(FrameStrobe_O[9])
);

my_buf strobe_outbuf_10 (
    .A(FrameStrobe_O_i[10]),
    .X(FrameStrobe_O[10])
);

my_buf strobe_outbuf_11 (
    .A(FrameStrobe_O_i[11]),
    .X(FrameStrobe_O[11])
);

my_buf strobe_outbuf_12 (
    .A(FrameStrobe_O_i[12]),
    .X(FrameStrobe_O[12])
);

my_buf strobe_outbuf_13 (
    .A(FrameStrobe_O_i[13]),
    .X(FrameStrobe_O[13])
);

my_buf strobe_outbuf_14 (
    .A(FrameStrobe_O_i[14]),
    .X(FrameStrobe_O[14])
);

my_buf strobe_outbuf_15 (
    .A(FrameStrobe_O_i[15]),
    .X(FrameStrobe_O[15])
);

my_buf strobe_outbuf_16 (
    .A(FrameStrobe_O_i[16]),
    .X(FrameStrobe_O[16])
);

my_buf strobe_outbuf_17 (
    .A(FrameStrobe_O_i[17]),
    .X(FrameStrobe_O[17])
);

my_buf strobe_outbuf_18 (
    .A(FrameStrobe_O_i[18]),
    .X(FrameStrobe_O[18])
);

my_buf strobe_outbuf_19 (
    .A(FrameStrobe_O_i[19]),
    .X(FrameStrobe_O[19])
);


 //configuration storage latches
LUT4x8_ha_ConfigMem
`ifdef EMULATION
    #(
    .Emulate_Bitstream(Emulate_Bitstream)
    )
`endif
    Inst_LUT4x8_ha_ConfigMem
    (
    .FrameData(FrameData),
    .FrameStrobe(FrameStrobe),
    .ConfigBits(ConfigBits),
    .ConfigBits_N(ConfigBits_N)
);


 //BEL component instantiations
FABULOUS_LC Inst_LA_FABULOUS_LC (
    .I({LA_I3, LA_I2, LA_I1, LA_I0}),
    .O(LA_O),
    .Ci(LA_Ci),
    .Co(LA_Co),
    .SR(LA_SR),
    .EN(LA_EN),
    .CLK(LA_CLK),
    .ConfigBits(ConfigBits[19-1:0])
);

FABULOUS_LC Inst_LB_FABULOUS_LC (
    .I({LB_I3, LB_I2, LB_I1, LB_I0}),
    .O(LB_O),
    .Ci(LB_Ci),
    .Co(LB_Co),
    .SR(LB_SR),
    .EN(LB_EN),
    .CLK(LB_CLK),
    .ConfigBits(ConfigBits[38-1:19])
);

FABULOUS_LC Inst_LC_FABULOUS_LC (
    .I({LC_I3, LC_I2, LC_I1, LC_I0}),
    .O(LC_O),
    .Ci(LC_Ci),
    .Co(LC_Co),
    .SR(LC_SR),
    .EN(LC_EN),
    .CLK(LC_CLK),
    .ConfigBits(ConfigBits[57-1:38])
);

FABULOUS_LC Inst_LD_FABULOUS_LC (
    .I({LD_I3, LD_I2, LD_I1, LD_I0}),
    .O(LD_O),
    .Ci(LD_Ci),
    .Co(LD_Co),
    .SR(LD_SR),
    .EN(LD_EN),
    .CLK(LD_CLK),
    .ConfigBits(ConfigBits[76-1:57])
);

FABULOUS_LC Inst_LE_FABULOUS_LC (
    .I({LE_I3, LE_I2, LE_I1, LE_I0}),
    .O(LE_O),
    .Ci(LE_Ci),
    .Co(LE_Co),
    .SR(LE_SR),
    .EN(LE_EN),
    .CLK(LE_CLK),
    .ConfigBits(ConfigBits[95-1:76])
);

FABULOUS_LC Inst_LF_FABULOUS_LC (
    .I({LF_I3, LF_I2, LF_I1, LF_I0}),
    .O(LF_O),
    .Ci(LF_Ci),
    .Co(LF_Co),
    .SR(LF_SR),
    .EN(LF_EN),
    .CLK(LF_CLK),
    .ConfigBits(ConfigBits[114-1:95])
);

FABULOUS_LC Inst_LG_FABULOUS_LC (
    .I({LG_I3, LG_I2, LG_I1, LG_I0}),
    .O(LG_O),
    .Ci(LG_Ci),
    .Co(LG_Co),
    .SR(LG_SR),
    .EN(LG_EN),
    .CLK(LG_CLK),
    .ConfigBits(ConfigBits[133-1:114])
);

FABULOUS_LC Inst_LH_FABULOUS_LC (
    .I({LH_I3, LH_I2, LH_I1, LH_I0}),
    .O(LH_O),
    .Ci(LH_Ci),
    .Co(LH_Co),
    .SR(LH_SR),
    .EN(LH_EN),
    .CLK(LH_CLK),
    .ConfigBits(ConfigBits[152-1:133])
);

LUT4x8_ha_switch_matrix Inst_LUT4x8_ha_switch_matrix (
    .N_GBUF_END0(N_GBUF_END[0]),
    .N_GBUF_END1(N_GBUF_END[1]),
    .N_GBUF_END2(N_GBUF_END[2]),
    .N_GBUF_END3(N_GBUF_END[3]),
    .N1END0(N1END[0]),
    .N1END1(N1END[1]),
    .N1END2(N1END[2]),
    .N1END3(N1END[3]),
    .N1END4(N1END[4]),
    .N1END5(N1END[5]),
    .N1END6(N1END[6]),
    .N1END7(N1END[7]),
    .N2MID0(N2MID[0]),
    .N2MID1(N2MID[1]),
    .N2MID2(N2MID[2]),
    .N2MID3(N2MID[3]),
    .N2MID4(N2MID[4]),
    .N2MID5(N2MID[5]),
    .N2MID6(N2MID[6]),
    .N2MID7(N2MID[7]),
    .N2END0(N2END[0]),
    .N2END1(N2END[1]),
    .N2END2(N2END[2]),
    .N2END3(N2END[3]),
    .N2END4(N2END[4]),
    .N2END5(N2END[5]),
    .N2END6(N2END[6]),
    .N2END7(N2END[7]),
    .E1END0(E1END[0]),
    .E1END1(E1END[1]),
    .E1END2(E1END[2]),
    .E1END3(E1END[3]),
    .E1END4(E1END[4]),
    .E1END5(E1END[5]),
    .E1END6(E1END[6]),
    .E1END7(E1END[7]),
    .E2MID0(E2MID[0]),
    .E2MID1(E2MID[1]),
    .E2MID2(E2MID[2]),
    .E2MID3(E2MID[3]),
    .E2MID4(E2MID[4]),
    .E2MID5(E2MID[5]),
    .E2MID6(E2MID[6]),
    .E2MID7(E2MID[7]),
    .E2END0(E2END[0]),
    .E2END1(E2END[1]),
    .E2END2(E2END[2]),
    .E2END3(E2END[3]),
    .E2END4(E2END[4]),
    .E2END5(E2END[5]),
    .E2END6(E2END[6]),
    .E2END7(E2END[7]),
    .S1END0(S1END[0]),
    .S1END1(S1END[1]),
    .S1END2(S1END[2]),
    .S1END3(S1END[3]),
    .S1END4(S1END[4]),
    .S1END5(S1END[5]),
    .S1END6(S1END[6]),
    .S1END7(S1END[7]),
    .S2MID0(S2MID[0]),
    .S2MID1(S2MID[1]),
    .S2MID2(S2MID[2]),
    .S2MID3(S2MID[3]),
    .S2MID4(S2MID[4]),
    .S2MID5(S2MID[5]),
    .S2MID6(S2MID[6]),
    .S2MID7(S2MID[7]),
    .S2END0(S2END[0]),
    .S2END1(S2END[1]),
    .S2END2(S2END[2]),
    .S2END3(S2END[3]),
    .S2END4(S2END[4]),
    .S2END5(S2END[5]),
    .S2END6(S2END[6]),
    .S2END7(S2END[7]),
    .W1END0(W1END[0]),
    .W1END1(W1END[1]),
    .W1END2(W1END[2]),
    .W1END3(W1END[3]),
    .W1END4(W1END[4]),
    .W1END5(W1END[5]),
    .W1END6(W1END[6]),
    .W1END7(W1END[7]),
    .W2MID0(W2MID[0]),
    .W2MID1(W2MID[1]),
    .W2MID2(W2MID[2]),
    .W2MID3(W2MID[3]),
    .W2MID4(W2MID[4]),
    .W2MID5(W2MID[5]),
    .W2MID6(W2MID[6]),
    .W2MID7(W2MID[7]),
    .W2END0(W2END[0]),
    .W2END1(W2END[1]),
    .W2END2(W2END[2]),
    .W2END3(W2END[3]),
    .W2END4(W2END[4]),
    .W2END5(W2END[5]),
    .W2END6(W2END[6]),
    .W2END7(W2END[7]),
    .CI0(CI[0]),
    .LA_O(LA_O),
    .LA_Co(LA_Co),
    .LB_O(LB_O),
    .LB_Co(LB_Co),
    .LC_O(LC_O),
    .LC_Co(LC_Co),
    .LD_O(LD_O),
    .LD_Co(LD_Co),
    .LE_O(LE_O),
    .LE_Co(LE_Co),
    .LF_O(LF_O),
    .LF_Co(LF_Co),
    .LG_O(LG_O),
    .LG_Co(LG_Co),
    .LH_O(LH_O),
    .LH_Co(LH_Co),
    .J2MID_ABa_END0(J2MID_ABa_BEG[0]),
    .J2MID_ABa_END1(J2MID_ABa_BEG[1]),
    .J2MID_ABa_END2(J2MID_ABa_BEG[2]),
    .J2MID_ABa_END3(J2MID_ABa_BEG[3]),
    .J2MID_CDa_END0(J2MID_CDa_BEG[0]),
    .J2MID_CDa_END1(J2MID_CDa_BEG[1]),
    .J2MID_CDa_END2(J2MID_CDa_BEG[2]),
    .J2MID_CDa_END3(J2MID_CDa_BEG[3]),
    .J2MID_EFa_END0(J2MID_EFa_BEG[0]),
    .J2MID_EFa_END1(J2MID_EFa_BEG[1]),
    .J2MID_EFa_END2(J2MID_EFa_BEG[2]),
    .J2MID_EFa_END3(J2MID_EFa_BEG[3]),
    .J2MID_GHa_END0(J2MID_GHa_BEG[0]),
    .J2MID_GHa_END1(J2MID_GHa_BEG[1]),
    .J2MID_GHa_END2(J2MID_GHa_BEG[2]),
    .J2MID_GHa_END3(J2MID_GHa_BEG[3]),
    .J2MID_ABb_END0(J2MID_ABb_BEG[0]),
    .J2MID_ABb_END1(J2MID_ABb_BEG[1]),
    .J2MID_ABb_END2(J2MID_ABb_BEG[2]),
    .J2MID_ABb_END3(J2MID_ABb_BEG[3]),
    .J2MID_CDb_END0(J2MID_CDb_BEG[0]),
    .J2MID_CDb_END1(J2MID_CDb_BEG[1]),
    .J2MID_CDb_END2(J2MID_CDb_BEG[2]),
    .J2MID_CDb_END3(J2MID_CDb_BEG[3]),
    .J2MID_EFb_END0(J2MID_EFb_BEG[0]),
    .J2MID_EFb_END1(J2MID_EFb_BEG[1]),
    .J2MID_EFb_END2(J2MID_EFb_BEG[2]),
    .J2MID_EFb_END3(J2MID_EFb_BEG[3]),
    .J2MID_GHb_END0(J2MID_GHb_BEG[0]),
    .J2MID_GHb_END1(J2MID_GHb_BEG[1]),
    .J2MID_GHb_END2(J2MID_GHb_BEG[2]),
    .J2MID_GHb_END3(J2MID_GHb_BEG[3]),
    .J2END_AB_END0(J2END_AB_BEG[0]),
    .J2END_AB_END1(J2END_AB_BEG[1]),
    .J2END_AB_END2(J2END_AB_BEG[2]),
    .J2END_AB_END3(J2END_AB_BEG[3]),
    .J2END_CD_END0(J2END_CD_BEG[0]),
    .J2END_CD_END1(J2END_CD_BEG[1]),
    .J2END_CD_END2(J2END_CD_BEG[2]),
    .J2END_CD_END3(J2END_CD_BEG[3]),
    .J2END_EF_END0(J2END_EF_BEG[0]),
    .J2END_EF_END1(J2END_EF_BEG[1]),
    .J2END_EF_END2(J2END_EF_BEG[2]),
    .J2END_EF_END3(J2END_EF_BEG[3]),
    .J2END_GH_END0(J2END_GH_BEG[0]),
    .J2END_GH_END1(J2END_GH_BEG[1]),
    .J2END_GH_END2(J2END_GH_BEG[2]),
    .J2END_GH_END3(J2END_GH_BEG[3]),
    .JN2END0(JN2BEG[0]),
    .JN2END1(JN2BEG[1]),
    .JN2END2(JN2BEG[2]),
    .JN2END3(JN2BEG[3]),
    .JN2END4(JN2BEG[4]),
    .JN2END5(JN2BEG[5]),
    .JN2END6(JN2BEG[6]),
    .JN2END7(JN2BEG[7]),
    .JE2END0(JE2BEG[0]),
    .JE2END1(JE2BEG[1]),
    .JE2END2(JE2BEG[2]),
    .JE2END3(JE2BEG[3]),
    .JE2END4(JE2BEG[4]),
    .JE2END5(JE2BEG[5]),
    .JE2END6(JE2BEG[6]),
    .JE2END7(JE2BEG[7]),
    .JS2END0(JS2BEG[0]),
    .JS2END1(JS2BEG[1]),
    .JS2END2(JS2BEG[2]),
    .JS2END3(JS2BEG[3]),
    .JS2END4(JS2BEG[4]),
    .JS2END5(JS2BEG[5]),
    .JS2END6(JS2BEG[6]),
    .JS2END7(JS2BEG[7]),
    .JW2END0(JW2BEG[0]),
    .JW2END1(JW2BEG[1]),
    .JW2END2(JW2BEG[2]),
    .JW2END3(JW2BEG[3]),
    .JW2END4(JW2BEG[4]),
    .JW2END5(JW2BEG[5]),
    .JW2END6(JW2BEG[6]),
    .JW2END7(JW2BEG[7]),
    .J_l_AB_END0(J_l_AB_BEG[0]),
    .J_l_AB_END1(J_l_AB_BEG[1]),
    .J_l_AB_END2(J_l_AB_BEG[2]),
    .J_l_AB_END3(J_l_AB_BEG[3]),
    .J_l_CD_END0(J_l_CD_BEG[0]),
    .J_l_CD_END1(J_l_CD_BEG[1]),
    .J_l_CD_END2(J_l_CD_BEG[2]),
    .J_l_CD_END3(J_l_CD_BEG[3]),
    .J_l_EF_END0(J_l_EF_BEG[0]),
    .J_l_EF_END1(J_l_EF_BEG[1]),
    .J_l_EF_END2(J_l_EF_BEG[2]),
    .J_l_EF_END3(J_l_EF_BEG[3]),
    .J_l_GH_END0(J_l_GH_BEG[0]),
    .J_l_GH_END1(J_l_GH_BEG[1]),
    .J_l_GH_END2(J_l_GH_BEG[2]),
    .J_l_GH_END3(J_l_GH_BEG[3]),
    .GCLK_END0(GCLK_BEG[0]),
    .GSR_END0(GSR_BEG[0]),
    .GEN_END0(GEN_BEG[0]),
    .J_SR_END0(J_SR_BEG[0]),
    .J_EN_END0(J_EN_BEG[0]),
    .N_GBUF_BEG0(N_GBUF_BEG[0]),
    .N_GBUF_BEG1(N_GBUF_BEG[1]),
    .N_GBUF_BEG2(N_GBUF_BEG[2]),
    .N_GBUF_BEG3(N_GBUF_BEG[3]),
    .N1BEG0(N1BEG[0]),
    .N1BEG1(N1BEG[1]),
    .N1BEG2(N1BEG[2]),
    .N1BEG3(N1BEG[3]),
    .N1BEG4(N1BEG[4]),
    .N1BEG5(N1BEG[5]),
    .N1BEG6(N1BEG[6]),
    .N1BEG7(N1BEG[7]),
    .N2BEG0(N2BEG[0]),
    .N2BEG1(N2BEG[1]),
    .N2BEG2(N2BEG[2]),
    .N2BEG3(N2BEG[3]),
    .N2BEG4(N2BEG[4]),
    .N2BEG5(N2BEG[5]),
    .N2BEG6(N2BEG[6]),
    .N2BEG7(N2BEG[7]),
    .N2BEGb0(N2BEGb[0]),
    .N2BEGb1(N2BEGb[1]),
    .N2BEGb2(N2BEGb[2]),
    .N2BEGb3(N2BEGb[3]),
    .N2BEGb4(N2BEGb[4]),
    .N2BEGb5(N2BEGb[5]),
    .N2BEGb6(N2BEGb[6]),
    .N2BEGb7(N2BEGb[7]),
    .E1BEG0(E1BEG[0]),
    .E1BEG1(E1BEG[1]),
    .E1BEG2(E1BEG[2]),
    .E1BEG3(E1BEG[3]),
    .E1BEG4(E1BEG[4]),
    .E1BEG5(E1BEG[5]),
    .E1BEG6(E1BEG[6]),
    .E1BEG7(E1BEG[7]),
    .E2BEG0(E2BEG[0]),
    .E2BEG1(E2BEG[1]),
    .E2BEG2(E2BEG[2]),
    .E2BEG3(E2BEG[3]),
    .E2BEG4(E2BEG[4]),
    .E2BEG5(E2BEG[5]),
    .E2BEG6(E2BEG[6]),
    .E2BEG7(E2BEG[7]),
    .E2BEGb0(E2BEGb[0]),
    .E2BEGb1(E2BEGb[1]),
    .E2BEGb2(E2BEGb[2]),
    .E2BEGb3(E2BEGb[3]),
    .E2BEGb4(E2BEGb[4]),
    .E2BEGb5(E2BEGb[5]),
    .E2BEGb6(E2BEGb[6]),
    .E2BEGb7(E2BEGb[7]),
    .S1BEG0(S1BEG[0]),
    .S1BEG1(S1BEG[1]),
    .S1BEG2(S1BEG[2]),
    .S1BEG3(S1BEG[3]),
    .S1BEG4(S1BEG[4]),
    .S1BEG5(S1BEG[5]),
    .S1BEG6(S1BEG[6]),
    .S1BEG7(S1BEG[7]),
    .S2BEG0(S2BEG[0]),
    .S2BEG1(S2BEG[1]),
    .S2BEG2(S2BEG[2]),
    .S2BEG3(S2BEG[3]),
    .S2BEG4(S2BEG[4]),
    .S2BEG5(S2BEG[5]),
    .S2BEG6(S2BEG[6]),
    .S2BEG7(S2BEG[7]),
    .S2BEGb0(S2BEGb[0]),
    .S2BEGb1(S2BEGb[1]),
    .S2BEGb2(S2BEGb[2]),
    .S2BEGb3(S2BEGb[3]),
    .S2BEGb4(S2BEGb[4]),
    .S2BEGb5(S2BEGb[5]),
    .S2BEGb6(S2BEGb[6]),
    .S2BEGb7(S2BEGb[7]),
    .W1BEG0(W1BEG[0]),
    .W1BEG1(W1BEG[1]),
    .W1BEG2(W1BEG[2]),
    .W1BEG3(W1BEG[3]),
    .W1BEG4(W1BEG[4]),
    .W1BEG5(W1BEG[5]),
    .W1BEG6(W1BEG[6]),
    .W1BEG7(W1BEG[7]),
    .W2BEG0(W2BEG[0]),
    .W2BEG1(W2BEG[1]),
    .W2BEG2(W2BEG[2]),
    .W2BEG3(W2BEG[3]),
    .W2BEG4(W2BEG[4]),
    .W2BEG5(W2BEG[5]),
    .W2BEG6(W2BEG[6]),
    .W2BEG7(W2BEG[7]),
    .W2BEGb0(W2BEGb[0]),
    .W2BEGb1(W2BEGb[1]),
    .W2BEGb2(W2BEGb[2]),
    .W2BEGb3(W2BEGb[3]),
    .W2BEGb4(W2BEGb[4]),
    .W2BEGb5(W2BEGb[5]),
    .W2BEGb6(W2BEGb[6]),
    .W2BEGb7(W2BEGb[7]),
    .CO0(CO[0]),
    .LA_I0(LA_I0),
    .LA_I1(LA_I1),
    .LA_I2(LA_I2),
    .LA_I3(LA_I3),
    .LA_Ci(LA_Ci),
    .LA_SR(LA_SR),
    .LA_EN(LA_EN),
    .LA_CLK(LA_CLK),
    .LB_I0(LB_I0),
    .LB_I1(LB_I1),
    .LB_I2(LB_I2),
    .LB_I3(LB_I3),
    .LB_Ci(LB_Ci),
    .LB_SR(LB_SR),
    .LB_EN(LB_EN),
    .LB_CLK(LB_CLK),
    .LC_I0(LC_I0),
    .LC_I1(LC_I1),
    .LC_I2(LC_I2),
    .LC_I3(LC_I3),
    .LC_Ci(LC_Ci),
    .LC_SR(LC_SR),
    .LC_EN(LC_EN),
    .LC_CLK(LC_CLK),
    .LD_I0(LD_I0),
    .LD_I1(LD_I1),
    .LD_I2(LD_I2),
    .LD_I3(LD_I3),
    .LD_Ci(LD_Ci),
    .LD_SR(LD_SR),
    .LD_EN(LD_EN),
    .LD_CLK(LD_CLK),
    .LE_I0(LE_I0),
    .LE_I1(LE_I1),
    .LE_I2(LE_I2),
    .LE_I3(LE_I3),
    .LE_Ci(LE_Ci),
    .LE_SR(LE_SR),
    .LE_EN(LE_EN),
    .LE_CLK(LE_CLK),
    .LF_I0(LF_I0),
    .LF_I1(LF_I1),
    .LF_I2(LF_I2),
    .LF_I3(LF_I3),
    .LF_Ci(LF_Ci),
    .LF_SR(LF_SR),
    .LF_EN(LF_EN),
    .LF_CLK(LF_CLK),
    .LG_I0(LG_I0),
    .LG_I1(LG_I1),
    .LG_I2(LG_I2),
    .LG_I3(LG_I3),
    .LG_Ci(LG_Ci),
    .LG_SR(LG_SR),
    .LG_EN(LG_EN),
    .LG_CLK(LG_CLK),
    .LH_I0(LH_I0),
    .LH_I1(LH_I1),
    .LH_I2(LH_I2),
    .LH_I3(LH_I3),
    .LH_Ci(LH_Ci),
    .LH_SR(LH_SR),
    .LH_EN(LH_EN),
    .LH_CLK(LH_CLK),
    .J2MID_ABa_BEG0(J2MID_ABa_BEG[0]),
    .J2MID_ABa_BEG1(J2MID_ABa_BEG[1]),
    .J2MID_ABa_BEG2(J2MID_ABa_BEG[2]),
    .J2MID_ABa_BEG3(J2MID_ABa_BEG[3]),
    .J2MID_CDa_BEG0(J2MID_CDa_BEG[0]),
    .J2MID_CDa_BEG1(J2MID_CDa_BEG[1]),
    .J2MID_CDa_BEG2(J2MID_CDa_BEG[2]),
    .J2MID_CDa_BEG3(J2MID_CDa_BEG[3]),
    .J2MID_EFa_BEG0(J2MID_EFa_BEG[0]),
    .J2MID_EFa_BEG1(J2MID_EFa_BEG[1]),
    .J2MID_EFa_BEG2(J2MID_EFa_BEG[2]),
    .J2MID_EFa_BEG3(J2MID_EFa_BEG[3]),
    .J2MID_GHa_BEG0(J2MID_GHa_BEG[0]),
    .J2MID_GHa_BEG1(J2MID_GHa_BEG[1]),
    .J2MID_GHa_BEG2(J2MID_GHa_BEG[2]),
    .J2MID_GHa_BEG3(J2MID_GHa_BEG[3]),
    .J2MID_ABb_BEG0(J2MID_ABb_BEG[0]),
    .J2MID_ABb_BEG1(J2MID_ABb_BEG[1]),
    .J2MID_ABb_BEG2(J2MID_ABb_BEG[2]),
    .J2MID_ABb_BEG3(J2MID_ABb_BEG[3]),
    .J2MID_CDb_BEG0(J2MID_CDb_BEG[0]),
    .J2MID_CDb_BEG1(J2MID_CDb_BEG[1]),
    .J2MID_CDb_BEG2(J2MID_CDb_BEG[2]),
    .J2MID_CDb_BEG3(J2MID_CDb_BEG[3]),
    .J2MID_EFb_BEG0(J2MID_EFb_BEG[0]),
    .J2MID_EFb_BEG1(J2MID_EFb_BEG[1]),
    .J2MID_EFb_BEG2(J2MID_EFb_BEG[2]),
    .J2MID_EFb_BEG3(J2MID_EFb_BEG[3]),
    .J2MID_GHb_BEG0(J2MID_GHb_BEG[0]),
    .J2MID_GHb_BEG1(J2MID_GHb_BEG[1]),
    .J2MID_GHb_BEG2(J2MID_GHb_BEG[2]),
    .J2MID_GHb_BEG3(J2MID_GHb_BEG[3]),
    .J2END_AB_BEG0(J2END_AB_BEG[0]),
    .J2END_AB_BEG1(J2END_AB_BEG[1]),
    .J2END_AB_BEG2(J2END_AB_BEG[2]),
    .J2END_AB_BEG3(J2END_AB_BEG[3]),
    .J2END_CD_BEG0(J2END_CD_BEG[0]),
    .J2END_CD_BEG1(J2END_CD_BEG[1]),
    .J2END_CD_BEG2(J2END_CD_BEG[2]),
    .J2END_CD_BEG3(J2END_CD_BEG[3]),
    .J2END_EF_BEG0(J2END_EF_BEG[0]),
    .J2END_EF_BEG1(J2END_EF_BEG[1]),
    .J2END_EF_BEG2(J2END_EF_BEG[2]),
    .J2END_EF_BEG3(J2END_EF_BEG[3]),
    .J2END_GH_BEG0(J2END_GH_BEG[0]),
    .J2END_GH_BEG1(J2END_GH_BEG[1]),
    .J2END_GH_BEG2(J2END_GH_BEG[2]),
    .J2END_GH_BEG3(J2END_GH_BEG[3]),
    .JN2BEG0(JN2BEG[0]),
    .JN2BEG1(JN2BEG[1]),
    .JN2BEG2(JN2BEG[2]),
    .JN2BEG3(JN2BEG[3]),
    .JN2BEG4(JN2BEG[4]),
    .JN2BEG5(JN2BEG[5]),
    .JN2BEG6(JN2BEG[6]),
    .JN2BEG7(JN2BEG[7]),
    .JE2BEG0(JE2BEG[0]),
    .JE2BEG1(JE2BEG[1]),
    .JE2BEG2(JE2BEG[2]),
    .JE2BEG3(JE2BEG[3]),
    .JE2BEG4(JE2BEG[4]),
    .JE2BEG5(JE2BEG[5]),
    .JE2BEG6(JE2BEG[6]),
    .JE2BEG7(JE2BEG[7]),
    .JS2BEG0(JS2BEG[0]),
    .JS2BEG1(JS2BEG[1]),
    .JS2BEG2(JS2BEG[2]),
    .JS2BEG3(JS2BEG[3]),
    .JS2BEG4(JS2BEG[4]),
    .JS2BEG5(JS2BEG[5]),
    .JS2BEG6(JS2BEG[6]),
    .JS2BEG7(JS2BEG[7]),
    .JW2BEG0(JW2BEG[0]),
    .JW2BEG1(JW2BEG[1]),
    .JW2BEG2(JW2BEG[2]),
    .JW2BEG3(JW2BEG[3]),
    .JW2BEG4(JW2BEG[4]),
    .JW2BEG5(JW2BEG[5]),
    .JW2BEG6(JW2BEG[6]),
    .JW2BEG7(JW2BEG[7]),
    .J_l_AB_BEG0(J_l_AB_BEG[0]),
    .J_l_AB_BEG1(J_l_AB_BEG[1]),
    .J_l_AB_BEG2(J_l_AB_BEG[2]),
    .J_l_AB_BEG3(J_l_AB_BEG[3]),
    .J_l_CD_BEG0(J_l_CD_BEG[0]),
    .J_l_CD_BEG1(J_l_CD_BEG[1]),
    .J_l_CD_BEG2(J_l_CD_BEG[2]),
    .J_l_CD_BEG3(J_l_CD_BEG[3]),
    .J_l_EF_BEG0(J_l_EF_BEG[0]),
    .J_l_EF_BEG1(J_l_EF_BEG[1]),
    .J_l_EF_BEG2(J_l_EF_BEG[2]),
    .J_l_EF_BEG3(J_l_EF_BEG[3]),
    .J_l_GH_BEG0(J_l_GH_BEG[0]),
    .J_l_GH_BEG1(J_l_GH_BEG[1]),
    .J_l_GH_BEG2(J_l_GH_BEG[2]),
    .J_l_GH_BEG3(J_l_GH_BEG[3]),
    .GCLK_BEG0(GCLK_BEG[0]),
    .GSR_BEG0(GSR_BEG[0]),
    .GEN_BEG0(GEN_BEG[0]),
    .J_SR_BEG0(J_SR_BEG[0]),
    .J_EN_BEG0(J_EN_BEG[0]),
    .ConfigBits(ConfigBits[566-1:152]),
    .ConfigBits_N(ConfigBits_N[566-1:152])
);

endmodule
 // NumberOfConfigBits: 0
module NE_term_switch_matrix
    (
        input  N_GBUF_END0,
        input  N_GBUF_END1,
        input  N_GBUF_END2,
        input  N_GBUF_END3
 //global
);
parameter GND0 = 1'b0;
parameter GND = 1'b0;
parameter VCC0 = 1'b1;
parameter VCC = 1'b1;
parameter VDD0 = 1'b1;
parameter VDD = 1'b1;

 //The configuration bits (if any) are just a long shift register
 //This shift register is padded to an even number of flops/latches
endmodule
module NE_term
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32
    )
    (
 //S
        input  [3:0] N_GBUF_END,        //Port(Name=N_GBUF_END,IO=INPUT,XOffset=0,YOffset=-1,WireCount=4,Side=S)
    //Tile IO ports from BELs
        input  [FrameBitsPerRow-1:0] FrameData, //CONFIG_PORT
        output  [FrameBitsPerRow-1:0] FrameData_O,
        input  [MaxFramesPerCol-1:0] FrameStrobe, //CONFIG_PORT
        output  [MaxFramesPerCol-1:0] FrameStrobe_O
    //global
);
 //signal declarations
 //BEL ports (e.g., slices)
 //Jump wires
 //internal configuration data signal to daisy-chain all BELs (if any and in the order they are listed in the fabric.csv)

 //Connection for outgoing wires
wire[FrameBitsPerRow-1:0] FrameData_i;
wire[FrameBitsPerRow-1:0] FrameData_O_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_O_i;

assign FrameData_O_i = FrameData_i;

my_buf data_inbuf_0 (
    .A(FrameData[0]),
    .X(FrameData_i[0])
);

my_buf data_inbuf_1 (
    .A(FrameData[1]),
    .X(FrameData_i[1])
);

my_buf data_inbuf_2 (
    .A(FrameData[2]),
    .X(FrameData_i[2])
);

my_buf data_inbuf_3 (
    .A(FrameData[3]),
    .X(FrameData_i[3])
);

my_buf data_inbuf_4 (
    .A(FrameData[4]),
    .X(FrameData_i[4])
);

my_buf data_inbuf_5 (
    .A(FrameData[5]),
    .X(FrameData_i[5])
);

my_buf data_inbuf_6 (
    .A(FrameData[6]),
    .X(FrameData_i[6])
);

my_buf data_inbuf_7 (
    .A(FrameData[7]),
    .X(FrameData_i[7])
);

my_buf data_inbuf_8 (
    .A(FrameData[8]),
    .X(FrameData_i[8])
);

my_buf data_inbuf_9 (
    .A(FrameData[9]),
    .X(FrameData_i[9])
);

my_buf data_inbuf_10 (
    .A(FrameData[10]),
    .X(FrameData_i[10])
);

my_buf data_inbuf_11 (
    .A(FrameData[11]),
    .X(FrameData_i[11])
);

my_buf data_inbuf_12 (
    .A(FrameData[12]),
    .X(FrameData_i[12])
);

my_buf data_inbuf_13 (
    .A(FrameData[13]),
    .X(FrameData_i[13])
);

my_buf data_inbuf_14 (
    .A(FrameData[14]),
    .X(FrameData_i[14])
);

my_buf data_inbuf_15 (
    .A(FrameData[15]),
    .X(FrameData_i[15])
);

my_buf data_inbuf_16 (
    .A(FrameData[16]),
    .X(FrameData_i[16])
);

my_buf data_inbuf_17 (
    .A(FrameData[17]),
    .X(FrameData_i[17])
);

my_buf data_inbuf_18 (
    .A(FrameData[18]),
    .X(FrameData_i[18])
);

my_buf data_inbuf_19 (
    .A(FrameData[19]),
    .X(FrameData_i[19])
);

my_buf data_inbuf_20 (
    .A(FrameData[20]),
    .X(FrameData_i[20])
);

my_buf data_inbuf_21 (
    .A(FrameData[21]),
    .X(FrameData_i[21])
);

my_buf data_inbuf_22 (
    .A(FrameData[22]),
    .X(FrameData_i[22])
);

my_buf data_inbuf_23 (
    .A(FrameData[23]),
    .X(FrameData_i[23])
);

my_buf data_inbuf_24 (
    .A(FrameData[24]),
    .X(FrameData_i[24])
);

my_buf data_inbuf_25 (
    .A(FrameData[25]),
    .X(FrameData_i[25])
);

my_buf data_inbuf_26 (
    .A(FrameData[26]),
    .X(FrameData_i[26])
);

my_buf data_inbuf_27 (
    .A(FrameData[27]),
    .X(FrameData_i[27])
);

my_buf data_inbuf_28 (
    .A(FrameData[28]),
    .X(FrameData_i[28])
);

my_buf data_inbuf_29 (
    .A(FrameData[29]),
    .X(FrameData_i[29])
);

my_buf data_inbuf_30 (
    .A(FrameData[30]),
    .X(FrameData_i[30])
);

my_buf data_inbuf_31 (
    .A(FrameData[31]),
    .X(FrameData_i[31])
);

my_buf data_outbuf_0 (
    .A(FrameData_O_i[0]),
    .X(FrameData_O[0])
);

my_buf data_outbuf_1 (
    .A(FrameData_O_i[1]),
    .X(FrameData_O[1])
);

my_buf data_outbuf_2 (
    .A(FrameData_O_i[2]),
    .X(FrameData_O[2])
);

my_buf data_outbuf_3 (
    .A(FrameData_O_i[3]),
    .X(FrameData_O[3])
);

my_buf data_outbuf_4 (
    .A(FrameData_O_i[4]),
    .X(FrameData_O[4])
);

my_buf data_outbuf_5 (
    .A(FrameData_O_i[5]),
    .X(FrameData_O[5])
);

my_buf data_outbuf_6 (
    .A(FrameData_O_i[6]),
    .X(FrameData_O[6])
);

my_buf data_outbuf_7 (
    .A(FrameData_O_i[7]),
    .X(FrameData_O[7])
);

my_buf data_outbuf_8 (
    .A(FrameData_O_i[8]),
    .X(FrameData_O[8])
);

my_buf data_outbuf_9 (
    .A(FrameData_O_i[9]),
    .X(FrameData_O[9])
);

my_buf data_outbuf_10 (
    .A(FrameData_O_i[10]),
    .X(FrameData_O[10])
);

my_buf data_outbuf_11 (
    .A(FrameData_O_i[11]),
    .X(FrameData_O[11])
);

my_buf data_outbuf_12 (
    .A(FrameData_O_i[12]),
    .X(FrameData_O[12])
);

my_buf data_outbuf_13 (
    .A(FrameData_O_i[13]),
    .X(FrameData_O[13])
);

my_buf data_outbuf_14 (
    .A(FrameData_O_i[14]),
    .X(FrameData_O[14])
);

my_buf data_outbuf_15 (
    .A(FrameData_O_i[15]),
    .X(FrameData_O[15])
);

my_buf data_outbuf_16 (
    .A(FrameData_O_i[16]),
    .X(FrameData_O[16])
);

my_buf data_outbuf_17 (
    .A(FrameData_O_i[17]),
    .X(FrameData_O[17])
);

my_buf data_outbuf_18 (
    .A(FrameData_O_i[18]),
    .X(FrameData_O[18])
);

my_buf data_outbuf_19 (
    .A(FrameData_O_i[19]),
    .X(FrameData_O[19])
);

my_buf data_outbuf_20 (
    .A(FrameData_O_i[20]),
    .X(FrameData_O[20])
);

my_buf data_outbuf_21 (
    .A(FrameData_O_i[21]),
    .X(FrameData_O[21])
);

my_buf data_outbuf_22 (
    .A(FrameData_O_i[22]),
    .X(FrameData_O[22])
);

my_buf data_outbuf_23 (
    .A(FrameData_O_i[23]),
    .X(FrameData_O[23])
);

my_buf data_outbuf_24 (
    .A(FrameData_O_i[24]),
    .X(FrameData_O[24])
);

my_buf data_outbuf_25 (
    .A(FrameData_O_i[25]),
    .X(FrameData_O[25])
);

my_buf data_outbuf_26 (
    .A(FrameData_O_i[26]),
    .X(FrameData_O[26])
);

my_buf data_outbuf_27 (
    .A(FrameData_O_i[27]),
    .X(FrameData_O[27])
);

my_buf data_outbuf_28 (
    .A(FrameData_O_i[28]),
    .X(FrameData_O[28])
);

my_buf data_outbuf_29 (
    .A(FrameData_O_i[29]),
    .X(FrameData_O[29])
);

my_buf data_outbuf_30 (
    .A(FrameData_O_i[30]),
    .X(FrameData_O[30])
);

my_buf data_outbuf_31 (
    .A(FrameData_O_i[31]),
    .X(FrameData_O[31])
);

assign FrameStrobe_O_i = FrameStrobe_i;

my_buf strobe_inbuf_0 (
    .A(FrameStrobe[0]),
    .X(FrameStrobe_i[0])
);

my_buf strobe_inbuf_1 (
    .A(FrameStrobe[1]),
    .X(FrameStrobe_i[1])
);

my_buf strobe_inbuf_2 (
    .A(FrameStrobe[2]),
    .X(FrameStrobe_i[2])
);

my_buf strobe_inbuf_3 (
    .A(FrameStrobe[3]),
    .X(FrameStrobe_i[3])
);

my_buf strobe_inbuf_4 (
    .A(FrameStrobe[4]),
    .X(FrameStrobe_i[4])
);

my_buf strobe_inbuf_5 (
    .A(FrameStrobe[5]),
    .X(FrameStrobe_i[5])
);

my_buf strobe_inbuf_6 (
    .A(FrameStrobe[6]),
    .X(FrameStrobe_i[6])
);

my_buf strobe_inbuf_7 (
    .A(FrameStrobe[7]),
    .X(FrameStrobe_i[7])
);

my_buf strobe_inbuf_8 (
    .A(FrameStrobe[8]),
    .X(FrameStrobe_i[8])
);

my_buf strobe_inbuf_9 (
    .A(FrameStrobe[9]),
    .X(FrameStrobe_i[9])
);

my_buf strobe_inbuf_10 (
    .A(FrameStrobe[10]),
    .X(FrameStrobe_i[10])
);

my_buf strobe_inbuf_11 (
    .A(FrameStrobe[11]),
    .X(FrameStrobe_i[11])
);

my_buf strobe_inbuf_12 (
    .A(FrameStrobe[12]),
    .X(FrameStrobe_i[12])
);

my_buf strobe_inbuf_13 (
    .A(FrameStrobe[13]),
    .X(FrameStrobe_i[13])
);

my_buf strobe_inbuf_14 (
    .A(FrameStrobe[14]),
    .X(FrameStrobe_i[14])
);

my_buf strobe_inbuf_15 (
    .A(FrameStrobe[15]),
    .X(FrameStrobe_i[15])
);

my_buf strobe_inbuf_16 (
    .A(FrameStrobe[16]),
    .X(FrameStrobe_i[16])
);

my_buf strobe_inbuf_17 (
    .A(FrameStrobe[17]),
    .X(FrameStrobe_i[17])
);

my_buf strobe_inbuf_18 (
    .A(FrameStrobe[18]),
    .X(FrameStrobe_i[18])
);

my_buf strobe_inbuf_19 (
    .A(FrameStrobe[19]),
    .X(FrameStrobe_i[19])
);

my_buf strobe_outbuf_0 (
    .A(FrameStrobe_O_i[0]),
    .X(FrameStrobe_O[0])
);

my_buf strobe_outbuf_1 (
    .A(FrameStrobe_O_i[1]),
    .X(FrameStrobe_O[1])
);

my_buf strobe_outbuf_2 (
    .A(FrameStrobe_O_i[2]),
    .X(FrameStrobe_O[2])
);

my_buf strobe_outbuf_3 (
    .A(FrameStrobe_O_i[3]),
    .X(FrameStrobe_O[3])
);

my_buf strobe_outbuf_4 (
    .A(FrameStrobe_O_i[4]),
    .X(FrameStrobe_O[4])
);

my_buf strobe_outbuf_5 (
    .A(FrameStrobe_O_i[5]),
    .X(FrameStrobe_O[5])
);

my_buf strobe_outbuf_6 (
    .A(FrameStrobe_O_i[6]),
    .X(FrameStrobe_O[6])
);

my_buf strobe_outbuf_7 (
    .A(FrameStrobe_O_i[7]),
    .X(FrameStrobe_O[7])
);

my_buf strobe_outbuf_8 (
    .A(FrameStrobe_O_i[8]),
    .X(FrameStrobe_O[8])
);

my_buf strobe_outbuf_9 (
    .A(FrameStrobe_O_i[9]),
    .X(FrameStrobe_O[9])
);

my_buf strobe_outbuf_10 (
    .A(FrameStrobe_O_i[10]),
    .X(FrameStrobe_O[10])
);

my_buf strobe_outbuf_11 (
    .A(FrameStrobe_O_i[11]),
    .X(FrameStrobe_O[11])
);

my_buf strobe_outbuf_12 (
    .A(FrameStrobe_O_i[12]),
    .X(FrameStrobe_O[12])
);

my_buf strobe_outbuf_13 (
    .A(FrameStrobe_O_i[13]),
    .X(FrameStrobe_O[13])
);

my_buf strobe_outbuf_14 (
    .A(FrameStrobe_O_i[14]),
    .X(FrameStrobe_O[14])
);

my_buf strobe_outbuf_15 (
    .A(FrameStrobe_O_i[15]),
    .X(FrameStrobe_O[15])
);

my_buf strobe_outbuf_16 (
    .A(FrameStrobe_O_i[16]),
    .X(FrameStrobe_O[16])
);

my_buf strobe_outbuf_17 (
    .A(FrameStrobe_O_i[17]),
    .X(FrameStrobe_O[17])
);

my_buf strobe_outbuf_18 (
    .A(FrameStrobe_O_i[18]),
    .X(FrameStrobe_O[18])
);

my_buf strobe_outbuf_19 (
    .A(FrameStrobe_O_i[19]),
    .X(FrameStrobe_O[19])
);


NE_term_switch_matrix Inst_NE_term_switch_matrix (
    .N_GBUF_END0(N_GBUF_END[0]),
    .N_GBUF_END1(N_GBUF_END[1]),
    .N_GBUF_END2(N_GBUF_END[2]),
    .N_GBUF_END3(N_GBUF_END[3])
);

endmodule
module N_IO_ConfigMem
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=60
    )
    (
        input  [FrameBitsPerRow - 1:0] FrameData,
        input  [MaxFramesPerCol - 1:0] FrameStrobe,
        output  [NoConfigBits - 1:0] ConfigBits,
        output  [NoConfigBits - 1:0] ConfigBits_N
    );

`ifdef EMULATION
assign ConfigBits[59] = Emulate_Bitstream[31];
assign ConfigBits[58] = Emulate_Bitstream[30];
assign ConfigBits[57] = Emulate_Bitstream[29];
assign ConfigBits[56] = Emulate_Bitstream[28];
assign ConfigBits[55] = Emulate_Bitstream[27];
assign ConfigBits[54] = Emulate_Bitstream[26];
assign ConfigBits[53] = Emulate_Bitstream[25];
assign ConfigBits[52] = Emulate_Bitstream[24];
assign ConfigBits[51] = Emulate_Bitstream[23];
assign ConfigBits[50] = Emulate_Bitstream[22];
assign ConfigBits[49] = Emulate_Bitstream[21];
assign ConfigBits[48] = Emulate_Bitstream[20];
assign ConfigBits[47] = Emulate_Bitstream[19];
assign ConfigBits[46] = Emulate_Bitstream[18];
assign ConfigBits[45] = Emulate_Bitstream[17];
assign ConfigBits[44] = Emulate_Bitstream[16];
assign ConfigBits[43] = Emulate_Bitstream[15];
assign ConfigBits[42] = Emulate_Bitstream[14];
assign ConfigBits[41] = Emulate_Bitstream[13];
assign ConfigBits[40] = Emulate_Bitstream[12];
assign ConfigBits[39] = Emulate_Bitstream[11];
assign ConfigBits[38] = Emulate_Bitstream[10];
assign ConfigBits[37] = Emulate_Bitstream[9];
assign ConfigBits[36] = Emulate_Bitstream[8];
assign ConfigBits[35] = Emulate_Bitstream[7];
assign ConfigBits[34] = Emulate_Bitstream[6];
assign ConfigBits[33] = Emulate_Bitstream[5];
assign ConfigBits[32] = Emulate_Bitstream[4];
assign ConfigBits[31] = Emulate_Bitstream[3];
assign ConfigBits[30] = Emulate_Bitstream[2];
assign ConfigBits[29] = Emulate_Bitstream[1];
assign ConfigBits[28] = Emulate_Bitstream[0];
assign ConfigBits[27] = Emulate_Bitstream[63];
assign ConfigBits[26] = Emulate_Bitstream[62];
assign ConfigBits[25] = Emulate_Bitstream[61];
assign ConfigBits[24] = Emulate_Bitstream[60];
assign ConfigBits[23] = Emulate_Bitstream[59];
assign ConfigBits[22] = Emulate_Bitstream[58];
assign ConfigBits[21] = Emulate_Bitstream[57];
assign ConfigBits[20] = Emulate_Bitstream[56];
assign ConfigBits[19] = Emulate_Bitstream[55];
assign ConfigBits[18] = Emulate_Bitstream[54];
assign ConfigBits[17] = Emulate_Bitstream[53];
assign ConfigBits[16] = Emulate_Bitstream[52];
assign ConfigBits[15] = Emulate_Bitstream[51];
assign ConfigBits[14] = Emulate_Bitstream[50];
assign ConfigBits[13] = Emulate_Bitstream[49];
assign ConfigBits[12] = Emulate_Bitstream[48];
assign ConfigBits[11] = Emulate_Bitstream[47];
assign ConfigBits[10] = Emulate_Bitstream[46];
assign ConfigBits[9] = Emulate_Bitstream[45];
assign ConfigBits[8] = Emulate_Bitstream[44];
assign ConfigBits[7] = Emulate_Bitstream[43];
assign ConfigBits[6] = Emulate_Bitstream[42];
assign ConfigBits[5] = Emulate_Bitstream[41];
assign ConfigBits[4] = Emulate_Bitstream[40];
assign ConfigBits[3] = Emulate_Bitstream[39];
assign ConfigBits[2] = Emulate_Bitstream[38];
assign ConfigBits[1] = Emulate_Bitstream[37];
assign ConfigBits[0] = Emulate_Bitstream[36];
`else

 //instantiate frame latches
config_latch Inst_frame0_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[59]),
    .QN(ConfigBits_N[59])
);

config_latch Inst_frame0_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[58]),
    .QN(ConfigBits_N[58])
);

config_latch Inst_frame0_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[57]),
    .QN(ConfigBits_N[57])
);

config_latch Inst_frame0_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[56]),
    .QN(ConfigBits_N[56])
);

config_latch Inst_frame0_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[55]),
    .QN(ConfigBits_N[55])
);

config_latch Inst_frame0_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[54]),
    .QN(ConfigBits_N[54])
);

config_latch Inst_frame0_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[53]),
    .QN(ConfigBits_N[53])
);

config_latch Inst_frame0_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[52]),
    .QN(ConfigBits_N[52])
);

config_latch Inst_frame0_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[51]),
    .QN(ConfigBits_N[51])
);

config_latch Inst_frame0_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[50]),
    .QN(ConfigBits_N[50])
);

config_latch Inst_frame0_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[49]),
    .QN(ConfigBits_N[49])
);

config_latch Inst_frame0_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[48]),
    .QN(ConfigBits_N[48])
);

config_latch Inst_frame0_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[47]),
    .QN(ConfigBits_N[47])
);

config_latch Inst_frame0_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[46]),
    .QN(ConfigBits_N[46])
);

config_latch Inst_frame0_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[45]),
    .QN(ConfigBits_N[45])
);

config_latch Inst_frame0_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[44]),
    .QN(ConfigBits_N[44])
);

config_latch Inst_frame0_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[43]),
    .QN(ConfigBits_N[43])
);

config_latch Inst_frame0_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[42]),
    .QN(ConfigBits_N[42])
);

config_latch Inst_frame0_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[41]),
    .QN(ConfigBits_N[41])
);

config_latch Inst_frame0_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[40]),
    .QN(ConfigBits_N[40])
);

config_latch Inst_frame0_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[39]),
    .QN(ConfigBits_N[39])
);

config_latch Inst_frame0_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[38]),
    .QN(ConfigBits_N[38])
);

config_latch Inst_frame0_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[37]),
    .QN(ConfigBits_N[37])
);

config_latch Inst_frame0_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[36]),
    .QN(ConfigBits_N[36])
);

config_latch Inst_frame0_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[35]),
    .QN(ConfigBits_N[35])
);

config_latch Inst_frame0_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[34]),
    .QN(ConfigBits_N[34])
);

config_latch Inst_frame0_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[33]),
    .QN(ConfigBits_N[33])
);

config_latch Inst_frame0_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[32]),
    .QN(ConfigBits_N[32])
);

config_latch Inst_frame0_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[31]),
    .QN(ConfigBits_N[31])
);

config_latch Inst_frame0_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[30]),
    .QN(ConfigBits_N[30])
);

config_latch Inst_frame0_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[29]),
    .QN(ConfigBits_N[29])
);

config_latch Inst_frame0_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[28]),
    .QN(ConfigBits_N[28])
);

config_latch Inst_frame1_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[27]),
    .QN(ConfigBits_N[27])
);

config_latch Inst_frame1_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[26]),
    .QN(ConfigBits_N[26])
);

config_latch Inst_frame1_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[25]),
    .QN(ConfigBits_N[25])
);

config_latch Inst_frame1_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[24]),
    .QN(ConfigBits_N[24])
);

config_latch Inst_frame1_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[23]),
    .QN(ConfigBits_N[23])
);

config_latch Inst_frame1_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[22]),
    .QN(ConfigBits_N[22])
);

config_latch Inst_frame1_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[21]),
    .QN(ConfigBits_N[21])
);

config_latch Inst_frame1_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[20]),
    .QN(ConfigBits_N[20])
);

config_latch Inst_frame1_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[19]),
    .QN(ConfigBits_N[19])
);

config_latch Inst_frame1_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[18]),
    .QN(ConfigBits_N[18])
);

config_latch Inst_frame1_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[17]),
    .QN(ConfigBits_N[17])
);

config_latch Inst_frame1_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[16]),
    .QN(ConfigBits_N[16])
);

config_latch Inst_frame1_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[15]),
    .QN(ConfigBits_N[15])
);

config_latch Inst_frame1_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[14]),
    .QN(ConfigBits_N[14])
);

config_latch Inst_frame1_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[13]),
    .QN(ConfigBits_N[13])
);

config_latch Inst_frame1_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[12]),
    .QN(ConfigBits_N[12])
);

config_latch Inst_frame1_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[11]),
    .QN(ConfigBits_N[11])
);

config_latch Inst_frame1_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[10]),
    .QN(ConfigBits_N[10])
);

config_latch Inst_frame1_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[9]),
    .QN(ConfigBits_N[9])
);

config_latch Inst_frame1_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[8]),
    .QN(ConfigBits_N[8])
);

config_latch Inst_frame1_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[7]),
    .QN(ConfigBits_N[7])
);

config_latch Inst_frame1_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[6]),
    .QN(ConfigBits_N[6])
);

config_latch Inst_frame1_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[5]),
    .QN(ConfigBits_N[5])
);

config_latch Inst_frame1_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[4]),
    .QN(ConfigBits_N[4])
);

config_latch Inst_frame1_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[3]),
    .QN(ConfigBits_N[3])
);

config_latch Inst_frame1_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[2]),
    .QN(ConfigBits_N[2])
);

config_latch Inst_frame1_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[1]),
    .QN(ConfigBits_N[1])
);

config_latch Inst_frame1_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[0]),
    .QN(ConfigBits_N[0])
);

`endif
endmodule
 // NumberOfConfigBits: 57
module N_IO_switch_matrix
    #(
        parameter NoConfigBits=57
    )
    (
        input  N_GBUF_END0,
        input  N_GBUF_END1,
        input  N_GBUF_END2,
        input  N_GBUF_END3,
        input  N1END0,
        input  N1END1,
        input  N1END2,
        input  N1END3,
        input  N1END4,
        input  N1END5,
        input  N1END6,
        input  N1END7,
        input  N2MID0,
        input  N2MID1,
        input  N2MID2,
        input  N2MID3,
        input  N2MID4,
        input  N2MID5,
        input  N2MID6,
        input  N2MID7,
        input  N2END0,
        input  N2END1,
        input  N2END2,
        input  N2END3,
        input  N2END4,
        input  N2END5,
        input  N2END6,
        input  N2END7,
        input  Ci0,
        input  A_OUT,
        output  S1BEG0,
        output  S1BEG1,
        output  S1BEG2,
        output  S1BEG3,
        output  S1BEG4,
        output  S1BEG5,
        output  S1BEG6,
        output  S1BEG7,
        output  S2BEG0,
        output  S2BEG1,
        output  S2BEG2,
        output  S2BEG3,
        output  S2BEG4,
        output  S2BEG5,
        output  S2BEG6,
        output  S2BEG7,
        output  S2BEGb0,
        output  S2BEGb1,
        output  S2BEGb2,
        output  S2BEGb3,
        output  S2BEGb4,
        output  S2BEGb5,
        output  S2BEGb6,
        output  S2BEGb7,
        output  A_CLK,
        output  A_IN,
        output  A_EN,
 //global
        input  [NoConfigBits-1:0] ConfigBits,
        input  [NoConfigBits-1:0] ConfigBits_N
);
parameter GND0 = 1'b0;
parameter GND = 1'b0;
parameter VCC0 = 1'b1;
parameter VCC = 1'b1;
parameter VDD0 = 1'b1;
parameter VDD = 1'b1;

wire[4-1:0] S1BEG0_input;
wire[4-1:0] S1BEG1_input;
wire[4-1:0] S1BEG2_input;
wire[4-1:0] S1BEG3_input;
wire[4-1:0] S1BEG4_input;
wire[4-1:0] S1BEG5_input;
wire[4-1:0] S1BEG6_input;
wire[4-1:0] S1BEG7_input;
wire[4-1:0] S2BEG0_input;
wire[4-1:0] S2BEG1_input;
wire[4-1:0] S2BEG2_input;
wire[4-1:0] S2BEG3_input;
wire[4-1:0] S2BEG4_input;
wire[4-1:0] S2BEG5_input;
wire[4-1:0] S2BEG6_input;
wire[4-1:0] S2BEG7_input;
wire[4-1:0] S2BEGb0_input;
wire[4-1:0] S2BEGb1_input;
wire[4-1:0] S2BEGb2_input;
wire[4-1:0] S2BEGb3_input;
wire[4-1:0] S2BEGb4_input;
wire[4-1:0] S2BEGb5_input;
wire[4-1:0] S2BEGb6_input;
wire[4-1:0] S2BEGb7_input;
wire[4-1:0] A_CLK_input;
wire[16-1:0] A_IN_input;
wire[8-1:0] A_EN_input;
 //The configuration bits (if any) are just a long shift register
 //This shift register is padded to an even number of flops/latches
 //switch matrix multiplexer S1BEG0 MUX-4
assign S1BEG0_input = {A_OUT,N2END7,N2MID7,N1END7};
cus_mux41 inst_cus_mux41_S1BEG0 (
    .A0(S1BEG0_input[0]),
    .A1(S1BEG0_input[1]),
    .A2(S1BEG0_input[2]),
    .A3(S1BEG0_input[3]),
    .S0(ConfigBits[0+0]),
    .S0N(ConfigBits_N[0+0]),
    .S1(ConfigBits[0+1]),
    .S1N(ConfigBits_N[0+1]),
    .X(S1BEG0)
);

 //switch matrix multiplexer S1BEG1 MUX-4
assign S1BEG1_input = {A_OUT,N2END6,N2MID6,N1END6};
cus_mux41 inst_cus_mux41_S1BEG1 (
    .A0(S1BEG1_input[0]),
    .A1(S1BEG1_input[1]),
    .A2(S1BEG1_input[2]),
    .A3(S1BEG1_input[3]),
    .S0(ConfigBits[2+0]),
    .S0N(ConfigBits_N[2+0]),
    .S1(ConfigBits[2+1]),
    .S1N(ConfigBits_N[2+1]),
    .X(S1BEG1)
);

 //switch matrix multiplexer S1BEG2 MUX-4
assign S1BEG2_input = {A_OUT,N2END5,N2MID5,N1END5};
cus_mux41 inst_cus_mux41_S1BEG2 (
    .A0(S1BEG2_input[0]),
    .A1(S1BEG2_input[1]),
    .A2(S1BEG2_input[2]),
    .A3(S1BEG2_input[3]),
    .S0(ConfigBits[4+0]),
    .S0N(ConfigBits_N[4+0]),
    .S1(ConfigBits[4+1]),
    .S1N(ConfigBits_N[4+1]),
    .X(S1BEG2)
);

 //switch matrix multiplexer S1BEG3 MUX-4
assign S1BEG3_input = {A_OUT,N2END4,N2MID4,N1END4};
cus_mux41 inst_cus_mux41_S1BEG3 (
    .A0(S1BEG3_input[0]),
    .A1(S1BEG3_input[1]),
    .A2(S1BEG3_input[2]),
    .A3(S1BEG3_input[3]),
    .S0(ConfigBits[6+0]),
    .S0N(ConfigBits_N[6+0]),
    .S1(ConfigBits[6+1]),
    .S1N(ConfigBits_N[6+1]),
    .X(S1BEG3)
);

 //switch matrix multiplexer S1BEG4 MUX-4
assign S1BEG4_input = {A_OUT,N2END3,N2MID3,N1END3};
cus_mux41 inst_cus_mux41_S1BEG4 (
    .A0(S1BEG4_input[0]),
    .A1(S1BEG4_input[1]),
    .A2(S1BEG4_input[2]),
    .A3(S1BEG4_input[3]),
    .S0(ConfigBits[8+0]),
    .S0N(ConfigBits_N[8+0]),
    .S1(ConfigBits[8+1]),
    .S1N(ConfigBits_N[8+1]),
    .X(S1BEG4)
);

 //switch matrix multiplexer S1BEG5 MUX-4
assign S1BEG5_input = {A_OUT,N2END2,N2MID2,N1END2};
cus_mux41 inst_cus_mux41_S1BEG5 (
    .A0(S1BEG5_input[0]),
    .A1(S1BEG5_input[1]),
    .A2(S1BEG5_input[2]),
    .A3(S1BEG5_input[3]),
    .S0(ConfigBits[10+0]),
    .S0N(ConfigBits_N[10+0]),
    .S1(ConfigBits[10+1]),
    .S1N(ConfigBits_N[10+1]),
    .X(S1BEG5)
);

 //switch matrix multiplexer S1BEG6 MUX-4
assign S1BEG6_input = {A_OUT,N2END1,N2MID1,N1END1};
cus_mux41 inst_cus_mux41_S1BEG6 (
    .A0(S1BEG6_input[0]),
    .A1(S1BEG6_input[1]),
    .A2(S1BEG6_input[2]),
    .A3(S1BEG6_input[3]),
    .S0(ConfigBits[12+0]),
    .S0N(ConfigBits_N[12+0]),
    .S1(ConfigBits[12+1]),
    .S1N(ConfigBits_N[12+1]),
    .X(S1BEG6)
);

 //switch matrix multiplexer S1BEG7 MUX-4
assign S1BEG7_input = {A_OUT,N2END0,N2MID0,N1END0};
cus_mux41 inst_cus_mux41_S1BEG7 (
    .A0(S1BEG7_input[0]),
    .A1(S1BEG7_input[1]),
    .A2(S1BEG7_input[2]),
    .A3(S1BEG7_input[3]),
    .S0(ConfigBits[14+0]),
    .S0N(ConfigBits_N[14+0]),
    .S1(ConfigBits[14+1]),
    .S1N(ConfigBits_N[14+1]),
    .X(S1BEG7)
);

 //switch matrix multiplexer S2BEG0 MUX-4
assign S2BEG0_input = {A_OUT,N2END7,N2MID7,N1END7};
cus_mux41 inst_cus_mux41_S2BEG0 (
    .A0(S2BEG0_input[0]),
    .A1(S2BEG0_input[1]),
    .A2(S2BEG0_input[2]),
    .A3(S2BEG0_input[3]),
    .S0(ConfigBits[16+0]),
    .S0N(ConfigBits_N[16+0]),
    .S1(ConfigBits[16+1]),
    .S1N(ConfigBits_N[16+1]),
    .X(S2BEG0)
);

 //switch matrix multiplexer S2BEG1 MUX-4
assign S2BEG1_input = {A_OUT,N2END6,N2MID6,N1END6};
cus_mux41 inst_cus_mux41_S2BEG1 (
    .A0(S2BEG1_input[0]),
    .A1(S2BEG1_input[1]),
    .A2(S2BEG1_input[2]),
    .A3(S2BEG1_input[3]),
    .S0(ConfigBits[18+0]),
    .S0N(ConfigBits_N[18+0]),
    .S1(ConfigBits[18+1]),
    .S1N(ConfigBits_N[18+1]),
    .X(S2BEG1)
);

 //switch matrix multiplexer S2BEG2 MUX-4
assign S2BEG2_input = {A_OUT,N2END5,N2MID5,N1END5};
cus_mux41 inst_cus_mux41_S2BEG2 (
    .A0(S2BEG2_input[0]),
    .A1(S2BEG2_input[1]),
    .A2(S2BEG2_input[2]),
    .A3(S2BEG2_input[3]),
    .S0(ConfigBits[20+0]),
    .S0N(ConfigBits_N[20+0]),
    .S1(ConfigBits[20+1]),
    .S1N(ConfigBits_N[20+1]),
    .X(S2BEG2)
);

 //switch matrix multiplexer S2BEG3 MUX-4
assign S2BEG3_input = {A_OUT,N2END4,N2MID4,N1END4};
cus_mux41 inst_cus_mux41_S2BEG3 (
    .A0(S2BEG3_input[0]),
    .A1(S2BEG3_input[1]),
    .A2(S2BEG3_input[2]),
    .A3(S2BEG3_input[3]),
    .S0(ConfigBits[22+0]),
    .S0N(ConfigBits_N[22+0]),
    .S1(ConfigBits[22+1]),
    .S1N(ConfigBits_N[22+1]),
    .X(S2BEG3)
);

 //switch matrix multiplexer S2BEG4 MUX-4
assign S2BEG4_input = {A_OUT,N2END3,N2MID3,N1END3};
cus_mux41 inst_cus_mux41_S2BEG4 (
    .A0(S2BEG4_input[0]),
    .A1(S2BEG4_input[1]),
    .A2(S2BEG4_input[2]),
    .A3(S2BEG4_input[3]),
    .S0(ConfigBits[24+0]),
    .S0N(ConfigBits_N[24+0]),
    .S1(ConfigBits[24+1]),
    .S1N(ConfigBits_N[24+1]),
    .X(S2BEG4)
);

 //switch matrix multiplexer S2BEG5 MUX-4
assign S2BEG5_input = {A_OUT,N2END2,N2MID2,N1END2};
cus_mux41 inst_cus_mux41_S2BEG5 (
    .A0(S2BEG5_input[0]),
    .A1(S2BEG5_input[1]),
    .A2(S2BEG5_input[2]),
    .A3(S2BEG5_input[3]),
    .S0(ConfigBits[26+0]),
    .S0N(ConfigBits_N[26+0]),
    .S1(ConfigBits[26+1]),
    .S1N(ConfigBits_N[26+1]),
    .X(S2BEG5)
);

 //switch matrix multiplexer S2BEG6 MUX-4
assign S2BEG6_input = {A_OUT,N2END1,N2MID1,N1END1};
cus_mux41 inst_cus_mux41_S2BEG6 (
    .A0(S2BEG6_input[0]),
    .A1(S2BEG6_input[1]),
    .A2(S2BEG6_input[2]),
    .A3(S2BEG6_input[3]),
    .S0(ConfigBits[28+0]),
    .S0N(ConfigBits_N[28+0]),
    .S1(ConfigBits[28+1]),
    .S1N(ConfigBits_N[28+1]),
    .X(S2BEG6)
);

 //switch matrix multiplexer S2BEG7 MUX-4
assign S2BEG7_input = {A_OUT,N2END0,N2MID0,N1END0};
cus_mux41 inst_cus_mux41_S2BEG7 (
    .A0(S2BEG7_input[0]),
    .A1(S2BEG7_input[1]),
    .A2(S2BEG7_input[2]),
    .A3(S2BEG7_input[3]),
    .S0(ConfigBits[30+0]),
    .S0N(ConfigBits_N[30+0]),
    .S1(ConfigBits[30+1]),
    .S1N(ConfigBits_N[30+1]),
    .X(S2BEG7)
);

 //switch matrix multiplexer S2BEGb0 MUX-4
assign S2BEGb0_input = {A_OUT,N2END7,N2MID7,N1END7};
cus_mux41 inst_cus_mux41_S2BEGb0 (
    .A0(S2BEGb0_input[0]),
    .A1(S2BEGb0_input[1]),
    .A2(S2BEGb0_input[2]),
    .A3(S2BEGb0_input[3]),
    .S0(ConfigBits[32+0]),
    .S0N(ConfigBits_N[32+0]),
    .S1(ConfigBits[32+1]),
    .S1N(ConfigBits_N[32+1]),
    .X(S2BEGb0)
);

 //switch matrix multiplexer S2BEGb1 MUX-4
assign S2BEGb1_input = {A_OUT,N2END6,N2MID6,N1END6};
cus_mux41 inst_cus_mux41_S2BEGb1 (
    .A0(S2BEGb1_input[0]),
    .A1(S2BEGb1_input[1]),
    .A2(S2BEGb1_input[2]),
    .A3(S2BEGb1_input[3]),
    .S0(ConfigBits[34+0]),
    .S0N(ConfigBits_N[34+0]),
    .S1(ConfigBits[34+1]),
    .S1N(ConfigBits_N[34+1]),
    .X(S2BEGb1)
);

 //switch matrix multiplexer S2BEGb2 MUX-4
assign S2BEGb2_input = {A_OUT,N2END5,N2MID5,N1END5};
cus_mux41 inst_cus_mux41_S2BEGb2 (
    .A0(S2BEGb2_input[0]),
    .A1(S2BEGb2_input[1]),
    .A2(S2BEGb2_input[2]),
    .A3(S2BEGb2_input[3]),
    .S0(ConfigBits[36+0]),
    .S0N(ConfigBits_N[36+0]),
    .S1(ConfigBits[36+1]),
    .S1N(ConfigBits_N[36+1]),
    .X(S2BEGb2)
);

 //switch matrix multiplexer S2BEGb3 MUX-4
assign S2BEGb3_input = {A_OUT,N2END4,N2MID4,N1END4};
cus_mux41 inst_cus_mux41_S2BEGb3 (
    .A0(S2BEGb3_input[0]),
    .A1(S2BEGb3_input[1]),
    .A2(S2BEGb3_input[2]),
    .A3(S2BEGb3_input[3]),
    .S0(ConfigBits[38+0]),
    .S0N(ConfigBits_N[38+0]),
    .S1(ConfigBits[38+1]),
    .S1N(ConfigBits_N[38+1]),
    .X(S2BEGb3)
);

 //switch matrix multiplexer S2BEGb4 MUX-4
assign S2BEGb4_input = {A_OUT,N2END3,N2MID3,N1END3};
cus_mux41 inst_cus_mux41_S2BEGb4 (
    .A0(S2BEGb4_input[0]),
    .A1(S2BEGb4_input[1]),
    .A2(S2BEGb4_input[2]),
    .A3(S2BEGb4_input[3]),
    .S0(ConfigBits[40+0]),
    .S0N(ConfigBits_N[40+0]),
    .S1(ConfigBits[40+1]),
    .S1N(ConfigBits_N[40+1]),
    .X(S2BEGb4)
);

 //switch matrix multiplexer S2BEGb5 MUX-4
assign S2BEGb5_input = {A_OUT,N2END2,N2MID2,N1END2};
cus_mux41 inst_cus_mux41_S2BEGb5 (
    .A0(S2BEGb5_input[0]),
    .A1(S2BEGb5_input[1]),
    .A2(S2BEGb5_input[2]),
    .A3(S2BEGb5_input[3]),
    .S0(ConfigBits[42+0]),
    .S0N(ConfigBits_N[42+0]),
    .S1(ConfigBits[42+1]),
    .S1N(ConfigBits_N[42+1]),
    .X(S2BEGb5)
);

 //switch matrix multiplexer S2BEGb6 MUX-4
assign S2BEGb6_input = {A_OUT,N2END1,N2MID1,N1END1};
cus_mux41 inst_cus_mux41_S2BEGb6 (
    .A0(S2BEGb6_input[0]),
    .A1(S2BEGb6_input[1]),
    .A2(S2BEGb6_input[2]),
    .A3(S2BEGb6_input[3]),
    .S0(ConfigBits[44+0]),
    .S0N(ConfigBits_N[44+0]),
    .S1(ConfigBits[44+1]),
    .S1N(ConfigBits_N[44+1]),
    .X(S2BEGb6)
);

 //switch matrix multiplexer S2BEGb7 MUX-4
assign S2BEGb7_input = {A_OUT,N2END0,N2MID0,N1END0};
cus_mux41 inst_cus_mux41_S2BEGb7 (
    .A0(S2BEGb7_input[0]),
    .A1(S2BEGb7_input[1]),
    .A2(S2BEGb7_input[2]),
    .A3(S2BEGb7_input[3]),
    .S0(ConfigBits[46+0]),
    .S0N(ConfigBits_N[46+0]),
    .S1(ConfigBits[46+1]),
    .S1N(ConfigBits_N[46+1]),
    .X(S2BEGb7)
);

 //switch matrix multiplexer A_CLK MUX-4
assign A_CLK_input = {N_GBUF_END3,N_GBUF_END2,N_GBUF_END1,N_GBUF_END0};
cus_mux41 inst_cus_mux41_A_CLK (
    .A0(A_CLK_input[0]),
    .A1(A_CLK_input[1]),
    .A2(A_CLK_input[2]),
    .A3(A_CLK_input[3]),
    .S0(ConfigBits[48+0]),
    .S0N(ConfigBits_N[48+0]),
    .S1(ConfigBits[48+1]),
    .S1N(ConfigBits_N[48+1]),
    .X(A_CLK)
);

 //switch matrix multiplexer A_IN MUX-16
assign A_IN_input = {N2END7,N2END6,N2END5,N2END4,N2END3,N2END2,N2END1,N2END0,N1END7,N1END6,N1END5,N1END4,N1END3,N1END2,N1END1,N1END0};
cus_mux161 inst_cus_mux161_A_IN (
    .A0(A_IN_input[0]),
    .A1(A_IN_input[1]),
    .A2(A_IN_input[2]),
    .A3(A_IN_input[3]),
    .A4(A_IN_input[4]),
    .A5(A_IN_input[5]),
    .A6(A_IN_input[6]),
    .A7(A_IN_input[7]),
    .A8(A_IN_input[8]),
    .A9(A_IN_input[9]),
    .A10(A_IN_input[10]),
    .A11(A_IN_input[11]),
    .A12(A_IN_input[12]),
    .A13(A_IN_input[13]),
    .A14(A_IN_input[14]),
    .A15(A_IN_input[15]),
    .S0(ConfigBits[50+0]),
    .S0N(ConfigBits_N[50+0]),
    .S1(ConfigBits[50+1]),
    .S1N(ConfigBits_N[50+1]),
    .S2(ConfigBits[50+2]),
    .S2N(ConfigBits_N[50+2]),
    .S3(ConfigBits[50+3]),
    .S3N(ConfigBits_N[50+3]),
    .X(A_IN)
);

 //switch matrix multiplexer A_EN MUX-8
assign A_EN_input = {VCC0,GND0,N2END2,N2END0,N2MID7,N2MID4,N1END7,N1END3};
cus_mux81 inst_cus_mux81_A_EN (
    .A0(A_EN_input[0]),
    .A1(A_EN_input[1]),
    .A2(A_EN_input[2]),
    .A3(A_EN_input[3]),
    .A4(A_EN_input[4]),
    .A5(A_EN_input[5]),
    .A6(A_EN_input[6]),
    .A7(A_EN_input[7]),
    .S0(ConfigBits[54+0]),
    .S0N(ConfigBits_N[54+0]),
    .S1(ConfigBits[54+1]),
    .S1N(ConfigBits_N[54+1]),
    .S2(ConfigBits[54+2]),
    .S2N(ConfigBits_N[54+2]),
    .X(A_EN)
);

endmodule
module N_IO
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=60
    )
    (
 //S
        input  [3:0] N_GBUF_END,        //Port(Name=N_GBUF_END,IO=INPUT,XOffset=0,YOffset=-1,WireCount=4,Side=S)
        output  [7:0] S1BEG,        //Port(Name=S1BEG,IO=OUTPUT,XOffset=0,YOffset=1,WireCount=8,Side=S)
        output  [7:0] S2BEG,        //Port(Name=S2BEG,IO=OUTPUT,XOffset=0,YOffset=1,WireCount=8,Side=S)
        output  [7:0] S2BEGb,        //Port(Name=S2BEGb,IO=OUTPUT,XOffset=0,YOffset=1,WireCount=8,Side=S)
        input  [7:0] N1END,        //Port(Name=N1END,IO=INPUT,XOffset=0,YOffset=-1,WireCount=8,Side=S)
        input  [7:0] N2MID,        //Port(Name=N2MID,IO=INPUT,XOffset=0,YOffset=-1,WireCount=8,Side=S)
        input  [7:0] N2END,        //Port(Name=N2END,IO=INPUT,XOffset=0,YOffset=-1,WireCount=8,Side=S)
        input  [0:0] Ci,        //Port(Name=Ci,IO=INPUT,XOffset=0,YOffset=-1,WireCount=1,Side=S)
        input  A_OUT_top,
        output  A_IN_top,
        output  A_EN_top,
    //Tile IO ports from BELs
        input  [FrameBitsPerRow-1:0] FrameData, //CONFIG_PORT
        output  [FrameBitsPerRow-1:0] FrameData_O,
        input  [MaxFramesPerCol-1:0] FrameStrobe, //CONFIG_PORT
        output  [MaxFramesPerCol-1:0] FrameStrobe_O
    //global
);
 //signal declarations
 //BEL ports (e.g., slices)
wire A_CLK;
wire A_IN;
wire A_EN;
wire A_OUT;
 //Jump wires
 //internal configuration data signal to daisy-chain all BELs (if any and in the order they are listed in the fabric.csv)
wire[NoConfigBits-1:0] ConfigBits;
wire[NoConfigBits-1:0] ConfigBits_N;

 //Connection for outgoing wires
wire[FrameBitsPerRow-1:0] FrameData_i;
wire[FrameBitsPerRow-1:0] FrameData_O_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_O_i;

assign FrameData_O_i = FrameData_i;

my_buf data_inbuf_0 (
    .A(FrameData[0]),
    .X(FrameData_i[0])
);

my_buf data_inbuf_1 (
    .A(FrameData[1]),
    .X(FrameData_i[1])
);

my_buf data_inbuf_2 (
    .A(FrameData[2]),
    .X(FrameData_i[2])
);

my_buf data_inbuf_3 (
    .A(FrameData[3]),
    .X(FrameData_i[3])
);

my_buf data_inbuf_4 (
    .A(FrameData[4]),
    .X(FrameData_i[4])
);

my_buf data_inbuf_5 (
    .A(FrameData[5]),
    .X(FrameData_i[5])
);

my_buf data_inbuf_6 (
    .A(FrameData[6]),
    .X(FrameData_i[6])
);

my_buf data_inbuf_7 (
    .A(FrameData[7]),
    .X(FrameData_i[7])
);

my_buf data_inbuf_8 (
    .A(FrameData[8]),
    .X(FrameData_i[8])
);

my_buf data_inbuf_9 (
    .A(FrameData[9]),
    .X(FrameData_i[9])
);

my_buf data_inbuf_10 (
    .A(FrameData[10]),
    .X(FrameData_i[10])
);

my_buf data_inbuf_11 (
    .A(FrameData[11]),
    .X(FrameData_i[11])
);

my_buf data_inbuf_12 (
    .A(FrameData[12]),
    .X(FrameData_i[12])
);

my_buf data_inbuf_13 (
    .A(FrameData[13]),
    .X(FrameData_i[13])
);

my_buf data_inbuf_14 (
    .A(FrameData[14]),
    .X(FrameData_i[14])
);

my_buf data_inbuf_15 (
    .A(FrameData[15]),
    .X(FrameData_i[15])
);

my_buf data_inbuf_16 (
    .A(FrameData[16]),
    .X(FrameData_i[16])
);

my_buf data_inbuf_17 (
    .A(FrameData[17]),
    .X(FrameData_i[17])
);

my_buf data_inbuf_18 (
    .A(FrameData[18]),
    .X(FrameData_i[18])
);

my_buf data_inbuf_19 (
    .A(FrameData[19]),
    .X(FrameData_i[19])
);

my_buf data_inbuf_20 (
    .A(FrameData[20]),
    .X(FrameData_i[20])
);

my_buf data_inbuf_21 (
    .A(FrameData[21]),
    .X(FrameData_i[21])
);

my_buf data_inbuf_22 (
    .A(FrameData[22]),
    .X(FrameData_i[22])
);

my_buf data_inbuf_23 (
    .A(FrameData[23]),
    .X(FrameData_i[23])
);

my_buf data_inbuf_24 (
    .A(FrameData[24]),
    .X(FrameData_i[24])
);

my_buf data_inbuf_25 (
    .A(FrameData[25]),
    .X(FrameData_i[25])
);

my_buf data_inbuf_26 (
    .A(FrameData[26]),
    .X(FrameData_i[26])
);

my_buf data_inbuf_27 (
    .A(FrameData[27]),
    .X(FrameData_i[27])
);

my_buf data_inbuf_28 (
    .A(FrameData[28]),
    .X(FrameData_i[28])
);

my_buf data_inbuf_29 (
    .A(FrameData[29]),
    .X(FrameData_i[29])
);

my_buf data_inbuf_30 (
    .A(FrameData[30]),
    .X(FrameData_i[30])
);

my_buf data_inbuf_31 (
    .A(FrameData[31]),
    .X(FrameData_i[31])
);

my_buf data_outbuf_0 (
    .A(FrameData_O_i[0]),
    .X(FrameData_O[0])
);

my_buf data_outbuf_1 (
    .A(FrameData_O_i[1]),
    .X(FrameData_O[1])
);

my_buf data_outbuf_2 (
    .A(FrameData_O_i[2]),
    .X(FrameData_O[2])
);

my_buf data_outbuf_3 (
    .A(FrameData_O_i[3]),
    .X(FrameData_O[3])
);

my_buf data_outbuf_4 (
    .A(FrameData_O_i[4]),
    .X(FrameData_O[4])
);

my_buf data_outbuf_5 (
    .A(FrameData_O_i[5]),
    .X(FrameData_O[5])
);

my_buf data_outbuf_6 (
    .A(FrameData_O_i[6]),
    .X(FrameData_O[6])
);

my_buf data_outbuf_7 (
    .A(FrameData_O_i[7]),
    .X(FrameData_O[7])
);

my_buf data_outbuf_8 (
    .A(FrameData_O_i[8]),
    .X(FrameData_O[8])
);

my_buf data_outbuf_9 (
    .A(FrameData_O_i[9]),
    .X(FrameData_O[9])
);

my_buf data_outbuf_10 (
    .A(FrameData_O_i[10]),
    .X(FrameData_O[10])
);

my_buf data_outbuf_11 (
    .A(FrameData_O_i[11]),
    .X(FrameData_O[11])
);

my_buf data_outbuf_12 (
    .A(FrameData_O_i[12]),
    .X(FrameData_O[12])
);

my_buf data_outbuf_13 (
    .A(FrameData_O_i[13]),
    .X(FrameData_O[13])
);

my_buf data_outbuf_14 (
    .A(FrameData_O_i[14]),
    .X(FrameData_O[14])
);

my_buf data_outbuf_15 (
    .A(FrameData_O_i[15]),
    .X(FrameData_O[15])
);

my_buf data_outbuf_16 (
    .A(FrameData_O_i[16]),
    .X(FrameData_O[16])
);

my_buf data_outbuf_17 (
    .A(FrameData_O_i[17]),
    .X(FrameData_O[17])
);

my_buf data_outbuf_18 (
    .A(FrameData_O_i[18]),
    .X(FrameData_O[18])
);

my_buf data_outbuf_19 (
    .A(FrameData_O_i[19]),
    .X(FrameData_O[19])
);

my_buf data_outbuf_20 (
    .A(FrameData_O_i[20]),
    .X(FrameData_O[20])
);

my_buf data_outbuf_21 (
    .A(FrameData_O_i[21]),
    .X(FrameData_O[21])
);

my_buf data_outbuf_22 (
    .A(FrameData_O_i[22]),
    .X(FrameData_O[22])
);

my_buf data_outbuf_23 (
    .A(FrameData_O_i[23]),
    .X(FrameData_O[23])
);

my_buf data_outbuf_24 (
    .A(FrameData_O_i[24]),
    .X(FrameData_O[24])
);

my_buf data_outbuf_25 (
    .A(FrameData_O_i[25]),
    .X(FrameData_O[25])
);

my_buf data_outbuf_26 (
    .A(FrameData_O_i[26]),
    .X(FrameData_O[26])
);

my_buf data_outbuf_27 (
    .A(FrameData_O_i[27]),
    .X(FrameData_O[27])
);

my_buf data_outbuf_28 (
    .A(FrameData_O_i[28]),
    .X(FrameData_O[28])
);

my_buf data_outbuf_29 (
    .A(FrameData_O_i[29]),
    .X(FrameData_O[29])
);

my_buf data_outbuf_30 (
    .A(FrameData_O_i[30]),
    .X(FrameData_O[30])
);

my_buf data_outbuf_31 (
    .A(FrameData_O_i[31]),
    .X(FrameData_O[31])
);

assign FrameStrobe_O_i = FrameStrobe_i;

my_buf strobe_inbuf_0 (
    .A(FrameStrobe[0]),
    .X(FrameStrobe_i[0])
);

my_buf strobe_inbuf_1 (
    .A(FrameStrobe[1]),
    .X(FrameStrobe_i[1])
);

my_buf strobe_inbuf_2 (
    .A(FrameStrobe[2]),
    .X(FrameStrobe_i[2])
);

my_buf strobe_inbuf_3 (
    .A(FrameStrobe[3]),
    .X(FrameStrobe_i[3])
);

my_buf strobe_inbuf_4 (
    .A(FrameStrobe[4]),
    .X(FrameStrobe_i[4])
);

my_buf strobe_inbuf_5 (
    .A(FrameStrobe[5]),
    .X(FrameStrobe_i[5])
);

my_buf strobe_inbuf_6 (
    .A(FrameStrobe[6]),
    .X(FrameStrobe_i[6])
);

my_buf strobe_inbuf_7 (
    .A(FrameStrobe[7]),
    .X(FrameStrobe_i[7])
);

my_buf strobe_inbuf_8 (
    .A(FrameStrobe[8]),
    .X(FrameStrobe_i[8])
);

my_buf strobe_inbuf_9 (
    .A(FrameStrobe[9]),
    .X(FrameStrobe_i[9])
);

my_buf strobe_inbuf_10 (
    .A(FrameStrobe[10]),
    .X(FrameStrobe_i[10])
);

my_buf strobe_inbuf_11 (
    .A(FrameStrobe[11]),
    .X(FrameStrobe_i[11])
);

my_buf strobe_inbuf_12 (
    .A(FrameStrobe[12]),
    .X(FrameStrobe_i[12])
);

my_buf strobe_inbuf_13 (
    .A(FrameStrobe[13]),
    .X(FrameStrobe_i[13])
);

my_buf strobe_inbuf_14 (
    .A(FrameStrobe[14]),
    .X(FrameStrobe_i[14])
);

my_buf strobe_inbuf_15 (
    .A(FrameStrobe[15]),
    .X(FrameStrobe_i[15])
);

my_buf strobe_inbuf_16 (
    .A(FrameStrobe[16]),
    .X(FrameStrobe_i[16])
);

my_buf strobe_inbuf_17 (
    .A(FrameStrobe[17]),
    .X(FrameStrobe_i[17])
);

my_buf strobe_inbuf_18 (
    .A(FrameStrobe[18]),
    .X(FrameStrobe_i[18])
);

my_buf strobe_inbuf_19 (
    .A(FrameStrobe[19]),
    .X(FrameStrobe_i[19])
);

my_buf strobe_outbuf_0 (
    .A(FrameStrobe_O_i[0]),
    .X(FrameStrobe_O[0])
);

my_buf strobe_outbuf_1 (
    .A(FrameStrobe_O_i[1]),
    .X(FrameStrobe_O[1])
);

my_buf strobe_outbuf_2 (
    .A(FrameStrobe_O_i[2]),
    .X(FrameStrobe_O[2])
);

my_buf strobe_outbuf_3 (
    .A(FrameStrobe_O_i[3]),
    .X(FrameStrobe_O[3])
);

my_buf strobe_outbuf_4 (
    .A(FrameStrobe_O_i[4]),
    .X(FrameStrobe_O[4])
);

my_buf strobe_outbuf_5 (
    .A(FrameStrobe_O_i[5]),
    .X(FrameStrobe_O[5])
);

my_buf strobe_outbuf_6 (
    .A(FrameStrobe_O_i[6]),
    .X(FrameStrobe_O[6])
);

my_buf strobe_outbuf_7 (
    .A(FrameStrobe_O_i[7]),
    .X(FrameStrobe_O[7])
);

my_buf strobe_outbuf_8 (
    .A(FrameStrobe_O_i[8]),
    .X(FrameStrobe_O[8])
);

my_buf strobe_outbuf_9 (
    .A(FrameStrobe_O_i[9]),
    .X(FrameStrobe_O[9])
);

my_buf strobe_outbuf_10 (
    .A(FrameStrobe_O_i[10]),
    .X(FrameStrobe_O[10])
);

my_buf strobe_outbuf_11 (
    .A(FrameStrobe_O_i[11]),
    .X(FrameStrobe_O[11])
);

my_buf strobe_outbuf_12 (
    .A(FrameStrobe_O_i[12]),
    .X(FrameStrobe_O[12])
);

my_buf strobe_outbuf_13 (
    .A(FrameStrobe_O_i[13]),
    .X(FrameStrobe_O[13])
);

my_buf strobe_outbuf_14 (
    .A(FrameStrobe_O_i[14]),
    .X(FrameStrobe_O[14])
);

my_buf strobe_outbuf_15 (
    .A(FrameStrobe_O_i[15]),
    .X(FrameStrobe_O[15])
);

my_buf strobe_outbuf_16 (
    .A(FrameStrobe_O_i[16]),
    .X(FrameStrobe_O[16])
);

my_buf strobe_outbuf_17 (
    .A(FrameStrobe_O_i[17]),
    .X(FrameStrobe_O[17])
);

my_buf strobe_outbuf_18 (
    .A(FrameStrobe_O_i[18]),
    .X(FrameStrobe_O[18])
);

my_buf strobe_outbuf_19 (
    .A(FrameStrobe_O_i[19]),
    .X(FrameStrobe_O[19])
);


 //configuration storage latches
N_IO_ConfigMem
`ifdef EMULATION
    #(
    .Emulate_Bitstream(Emulate_Bitstream)
    )
`endif
    Inst_N_IO_ConfigMem
    (
    .FrameData(FrameData),
    .FrameStrobe(FrameStrobe),
    .ConfigBits(ConfigBits),
    .ConfigBits_N(ConfigBits_N)
);


 //BEL component instantiations
IOBUF Inst_A_IOBUF (
    .CLK(A_CLK),
    .IN(A_IN),
    .EN(A_EN),
    .OUT(A_OUT),
    .IN_top(A_IN_top),
    .EN_top(A_EN_top),
    .OUT_top(A_OUT_top),
    .ConfigBits(ConfigBits[3-1:0])
);

N_IO_switch_matrix Inst_N_IO_switch_matrix (
    .N_GBUF_END0(N_GBUF_END[0]),
    .N_GBUF_END1(N_GBUF_END[1]),
    .N_GBUF_END2(N_GBUF_END[2]),
    .N_GBUF_END3(N_GBUF_END[3]),
    .N1END0(N1END[0]),
    .N1END1(N1END[1]),
    .N1END2(N1END[2]),
    .N1END3(N1END[3]),
    .N1END4(N1END[4]),
    .N1END5(N1END[5]),
    .N1END6(N1END[6]),
    .N1END7(N1END[7]),
    .N2MID0(N2MID[0]),
    .N2MID1(N2MID[1]),
    .N2MID2(N2MID[2]),
    .N2MID3(N2MID[3]),
    .N2MID4(N2MID[4]),
    .N2MID5(N2MID[5]),
    .N2MID6(N2MID[6]),
    .N2MID7(N2MID[7]),
    .N2END0(N2END[0]),
    .N2END1(N2END[1]),
    .N2END2(N2END[2]),
    .N2END3(N2END[3]),
    .N2END4(N2END[4]),
    .N2END5(N2END[5]),
    .N2END6(N2END[6]),
    .N2END7(N2END[7]),
    .Ci0(Ci[0]),
    .A_OUT(A_OUT),
    .S1BEG0(S1BEG[0]),
    .S1BEG1(S1BEG[1]),
    .S1BEG2(S1BEG[2]),
    .S1BEG3(S1BEG[3]),
    .S1BEG4(S1BEG[4]),
    .S1BEG5(S1BEG[5]),
    .S1BEG6(S1BEG[6]),
    .S1BEG7(S1BEG[7]),
    .S2BEG0(S2BEG[0]),
    .S2BEG1(S2BEG[1]),
    .S2BEG2(S2BEG[2]),
    .S2BEG3(S2BEG[3]),
    .S2BEG4(S2BEG[4]),
    .S2BEG5(S2BEG[5]),
    .S2BEG6(S2BEG[6]),
    .S2BEG7(S2BEG[7]),
    .S2BEGb0(S2BEGb[0]),
    .S2BEGb1(S2BEGb[1]),
    .S2BEGb2(S2BEGb[2]),
    .S2BEGb3(S2BEGb[3]),
    .S2BEGb4(S2BEGb[4]),
    .S2BEGb5(S2BEGb[5]),
    .S2BEGb6(S2BEGb[6]),
    .S2BEGb7(S2BEGb[7]),
    .A_CLK(A_CLK),
    .A_IN(A_IN),
    .A_EN(A_EN),
    .ConfigBits(ConfigBits[60-1:3]),
    .ConfigBits_N(ConfigBits_N[60-1:3])
);

endmodule
module N_term_ConfigMem
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=48
    )
    (
        input  [FrameBitsPerRow - 1:0] FrameData,
        input  [MaxFramesPerCol - 1:0] FrameStrobe,
        output  [NoConfigBits - 1:0] ConfigBits,
        output  [NoConfigBits - 1:0] ConfigBits_N
    );

`ifdef EMULATION
assign ConfigBits[47] = Emulate_Bitstream[31];
assign ConfigBits[46] = Emulate_Bitstream[30];
assign ConfigBits[45] = Emulate_Bitstream[29];
assign ConfigBits[44] = Emulate_Bitstream[28];
assign ConfigBits[43] = Emulate_Bitstream[27];
assign ConfigBits[42] = Emulate_Bitstream[26];
assign ConfigBits[41] = Emulate_Bitstream[25];
assign ConfigBits[40] = Emulate_Bitstream[24];
assign ConfigBits[39] = Emulate_Bitstream[23];
assign ConfigBits[38] = Emulate_Bitstream[22];
assign ConfigBits[37] = Emulate_Bitstream[21];
assign ConfigBits[36] = Emulate_Bitstream[20];
assign ConfigBits[35] = Emulate_Bitstream[19];
assign ConfigBits[34] = Emulate_Bitstream[18];
assign ConfigBits[33] = Emulate_Bitstream[17];
assign ConfigBits[32] = Emulate_Bitstream[16];
assign ConfigBits[31] = Emulate_Bitstream[15];
assign ConfigBits[30] = Emulate_Bitstream[14];
assign ConfigBits[29] = Emulate_Bitstream[13];
assign ConfigBits[28] = Emulate_Bitstream[12];
assign ConfigBits[27] = Emulate_Bitstream[11];
assign ConfigBits[26] = Emulate_Bitstream[10];
assign ConfigBits[25] = Emulate_Bitstream[9];
assign ConfigBits[24] = Emulate_Bitstream[8];
assign ConfigBits[23] = Emulate_Bitstream[7];
assign ConfigBits[22] = Emulate_Bitstream[6];
assign ConfigBits[21] = Emulate_Bitstream[5];
assign ConfigBits[20] = Emulate_Bitstream[4];
assign ConfigBits[19] = Emulate_Bitstream[3];
assign ConfigBits[18] = Emulate_Bitstream[2];
assign ConfigBits[17] = Emulate_Bitstream[1];
assign ConfigBits[16] = Emulate_Bitstream[0];
assign ConfigBits[15] = Emulate_Bitstream[63];
assign ConfigBits[14] = Emulate_Bitstream[62];
assign ConfigBits[13] = Emulate_Bitstream[61];
assign ConfigBits[12] = Emulate_Bitstream[60];
assign ConfigBits[11] = Emulate_Bitstream[59];
assign ConfigBits[10] = Emulate_Bitstream[58];
assign ConfigBits[9] = Emulate_Bitstream[57];
assign ConfigBits[8] = Emulate_Bitstream[56];
assign ConfigBits[7] = Emulate_Bitstream[55];
assign ConfigBits[6] = Emulate_Bitstream[54];
assign ConfigBits[5] = Emulate_Bitstream[53];
assign ConfigBits[4] = Emulate_Bitstream[52];
assign ConfigBits[3] = Emulate_Bitstream[51];
assign ConfigBits[2] = Emulate_Bitstream[50];
assign ConfigBits[1] = Emulate_Bitstream[49];
assign ConfigBits[0] = Emulate_Bitstream[48];
`else

 //instantiate frame latches
config_latch Inst_frame0_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[47]),
    .QN(ConfigBits_N[47])
);

config_latch Inst_frame0_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[46]),
    .QN(ConfigBits_N[46])
);

config_latch Inst_frame0_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[45]),
    .QN(ConfigBits_N[45])
);

config_latch Inst_frame0_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[44]),
    .QN(ConfigBits_N[44])
);

config_latch Inst_frame0_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[43]),
    .QN(ConfigBits_N[43])
);

config_latch Inst_frame0_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[42]),
    .QN(ConfigBits_N[42])
);

config_latch Inst_frame0_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[41]),
    .QN(ConfigBits_N[41])
);

config_latch Inst_frame0_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[40]),
    .QN(ConfigBits_N[40])
);

config_latch Inst_frame0_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[39]),
    .QN(ConfigBits_N[39])
);

config_latch Inst_frame0_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[38]),
    .QN(ConfigBits_N[38])
);

config_latch Inst_frame0_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[37]),
    .QN(ConfigBits_N[37])
);

config_latch Inst_frame0_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[36]),
    .QN(ConfigBits_N[36])
);

config_latch Inst_frame0_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[35]),
    .QN(ConfigBits_N[35])
);

config_latch Inst_frame0_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[34]),
    .QN(ConfigBits_N[34])
);

config_latch Inst_frame0_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[33]),
    .QN(ConfigBits_N[33])
);

config_latch Inst_frame0_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[32]),
    .QN(ConfigBits_N[32])
);

config_latch Inst_frame0_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[31]),
    .QN(ConfigBits_N[31])
);

config_latch Inst_frame0_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[30]),
    .QN(ConfigBits_N[30])
);

config_latch Inst_frame0_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[29]),
    .QN(ConfigBits_N[29])
);

config_latch Inst_frame0_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[28]),
    .QN(ConfigBits_N[28])
);

config_latch Inst_frame0_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[27]),
    .QN(ConfigBits_N[27])
);

config_latch Inst_frame0_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[26]),
    .QN(ConfigBits_N[26])
);

config_latch Inst_frame0_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[25]),
    .QN(ConfigBits_N[25])
);

config_latch Inst_frame0_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[24]),
    .QN(ConfigBits_N[24])
);

config_latch Inst_frame0_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[23]),
    .QN(ConfigBits_N[23])
);

config_latch Inst_frame0_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[22]),
    .QN(ConfigBits_N[22])
);

config_latch Inst_frame0_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[21]),
    .QN(ConfigBits_N[21])
);

config_latch Inst_frame0_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[20]),
    .QN(ConfigBits_N[20])
);

config_latch Inst_frame0_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[19]),
    .QN(ConfigBits_N[19])
);

config_latch Inst_frame0_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[18]),
    .QN(ConfigBits_N[18])
);

config_latch Inst_frame0_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[17]),
    .QN(ConfigBits_N[17])
);

config_latch Inst_frame0_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[16]),
    .QN(ConfigBits_N[16])
);

config_latch Inst_frame1_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[15]),
    .QN(ConfigBits_N[15])
);

config_latch Inst_frame1_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[14]),
    .QN(ConfigBits_N[14])
);

config_latch Inst_frame1_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[13]),
    .QN(ConfigBits_N[13])
);

config_latch Inst_frame1_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[12]),
    .QN(ConfigBits_N[12])
);

config_latch Inst_frame1_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[11]),
    .QN(ConfigBits_N[11])
);

config_latch Inst_frame1_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[10]),
    .QN(ConfigBits_N[10])
);

config_latch Inst_frame1_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[9]),
    .QN(ConfigBits_N[9])
);

config_latch Inst_frame1_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[8]),
    .QN(ConfigBits_N[8])
);

config_latch Inst_frame1_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[7]),
    .QN(ConfigBits_N[7])
);

config_latch Inst_frame1_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[6]),
    .QN(ConfigBits_N[6])
);

config_latch Inst_frame1_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[5]),
    .QN(ConfigBits_N[5])
);

config_latch Inst_frame1_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[4]),
    .QN(ConfigBits_N[4])
);

config_latch Inst_frame1_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[3]),
    .QN(ConfigBits_N[3])
);

config_latch Inst_frame1_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[2]),
    .QN(ConfigBits_N[2])
);

config_latch Inst_frame1_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[1]),
    .QN(ConfigBits_N[1])
);

config_latch Inst_frame1_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[0]),
    .QN(ConfigBits_N[0])
);

`endif
endmodule
 // NumberOfConfigBits: 48
module N_term_switch_matrix
    #(
        parameter NoConfigBits=48
    )
    (
        input  N_GBUF_END0,
        input  N_GBUF_END1,
        input  N_GBUF_END2,
        input  N_GBUF_END3,
        input  N1END0,
        input  N1END1,
        input  N1END2,
        input  N1END3,
        input  N1END4,
        input  N1END5,
        input  N1END6,
        input  N1END7,
        input  N2MID0,
        input  N2MID1,
        input  N2MID2,
        input  N2MID3,
        input  N2MID4,
        input  N2MID5,
        input  N2MID6,
        input  N2MID7,
        input  N2END0,
        input  N2END1,
        input  N2END2,
        input  N2END3,
        input  N2END4,
        input  N2END5,
        input  N2END6,
        input  N2END7,
        input  Ci0,
        output  S1BEG0,
        output  S1BEG1,
        output  S1BEG2,
        output  S1BEG3,
        output  S1BEG4,
        output  S1BEG5,
        output  S1BEG6,
        output  S1BEG7,
        output  S2BEG0,
        output  S2BEG1,
        output  S2BEG2,
        output  S2BEG3,
        output  S2BEG4,
        output  S2BEG5,
        output  S2BEG6,
        output  S2BEG7,
        output  S2BEGb0,
        output  S2BEGb1,
        output  S2BEGb2,
        output  S2BEGb3,
        output  S2BEGb4,
        output  S2BEGb5,
        output  S2BEGb6,
        output  S2BEGb7,
 //global
        input  [NoConfigBits-1:0] ConfigBits,
        input  [NoConfigBits-1:0] ConfigBits_N
);
parameter GND0 = 1'b0;
parameter GND = 1'b0;
parameter VCC0 = 1'b1;
parameter VCC = 1'b1;
parameter VDD0 = 1'b1;
parameter VDD = 1'b1;

wire[4-1:0] S1BEG0_input;
wire[4-1:0] S1BEG1_input;
wire[4-1:0] S1BEG2_input;
wire[4-1:0] S1BEG3_input;
wire[4-1:0] S1BEG4_input;
wire[4-1:0] S1BEG5_input;
wire[4-1:0] S1BEG6_input;
wire[4-1:0] S1BEG7_input;
wire[4-1:0] S2BEG0_input;
wire[4-1:0] S2BEG1_input;
wire[4-1:0] S2BEG2_input;
wire[4-1:0] S2BEG3_input;
wire[4-1:0] S2BEG4_input;
wire[4-1:0] S2BEG5_input;
wire[4-1:0] S2BEG6_input;
wire[4-1:0] S2BEG7_input;
wire[4-1:0] S2BEGb0_input;
wire[4-1:0] S2BEGb1_input;
wire[4-1:0] S2BEGb2_input;
wire[4-1:0] S2BEGb3_input;
wire[4-1:0] S2BEGb4_input;
wire[4-1:0] S2BEGb5_input;
wire[4-1:0] S2BEGb6_input;
wire[4-1:0] S2BEGb7_input;
 //The configuration bits (if any) are just a long shift register
 //This shift register is padded to an even number of flops/latches
 //switch matrix multiplexer S1BEG0 MUX-4
assign S1BEG0_input = {N2END7,N2MID7,N1END7,N1END5};
cus_mux41 inst_cus_mux41_S1BEG0 (
    .A0(S1BEG0_input[0]),
    .A1(S1BEG0_input[1]),
    .A2(S1BEG0_input[2]),
    .A3(S1BEG0_input[3]),
    .S0(ConfigBits[0+0]),
    .S0N(ConfigBits_N[0+0]),
    .S1(ConfigBits[0+1]),
    .S1N(ConfigBits_N[0+1]),
    .X(S1BEG0)
);

 //switch matrix multiplexer S1BEG1 MUX-4
assign S1BEG1_input = {N2END6,N2MID6,N1END6,N1END3};
cus_mux41 inst_cus_mux41_S1BEG1 (
    .A0(S1BEG1_input[0]),
    .A1(S1BEG1_input[1]),
    .A2(S1BEG1_input[2]),
    .A3(S1BEG1_input[3]),
    .S0(ConfigBits[2+0]),
    .S0N(ConfigBits_N[2+0]),
    .S1(ConfigBits[2+1]),
    .S1N(ConfigBits_N[2+1]),
    .X(S1BEG1)
);

 //switch matrix multiplexer S1BEG2 MUX-4
assign S1BEG2_input = {N2END5,N2END1,N2MID5,N1END5};
cus_mux41 inst_cus_mux41_S1BEG2 (
    .A0(S1BEG2_input[0]),
    .A1(S1BEG2_input[1]),
    .A2(S1BEG2_input[2]),
    .A3(S1BEG2_input[3]),
    .S0(ConfigBits[4+0]),
    .S0N(ConfigBits_N[4+0]),
    .S1(ConfigBits[4+1]),
    .S1N(ConfigBits_N[4+1]),
    .X(S1BEG2)
);

 //switch matrix multiplexer S1BEG3 MUX-4
assign S1BEG3_input = {N2END6,N2END4,N2MID4,N1END4};
cus_mux41 inst_cus_mux41_S1BEG3 (
    .A0(S1BEG3_input[0]),
    .A1(S1BEG3_input[1]),
    .A2(S1BEG3_input[2]),
    .A3(S1BEG3_input[3]),
    .S0(ConfigBits[6+0]),
    .S0N(ConfigBits_N[6+0]),
    .S1(ConfigBits[6+1]),
    .S1N(ConfigBits_N[6+1]),
    .X(S1BEG3)
);

 //switch matrix multiplexer S1BEG4 MUX-4
assign S1BEG4_input = {N2END3,N2MID3,N2MID0,N1END3};
cus_mux41 inst_cus_mux41_S1BEG4 (
    .A0(S1BEG4_input[0]),
    .A1(S1BEG4_input[1]),
    .A2(S1BEG4_input[2]),
    .A3(S1BEG4_input[3]),
    .S0(ConfigBits[8+0]),
    .S0N(ConfigBits_N[8+0]),
    .S1(ConfigBits[8+1]),
    .S1N(ConfigBits_N[8+1]),
    .X(S1BEG4)
);

 //switch matrix multiplexer S1BEG5 MUX-4
assign S1BEG5_input = {Ci0,N2END2,N2MID2,N1END2};
cus_mux41 inst_cus_mux41_S1BEG5 (
    .A0(S1BEG5_input[0]),
    .A1(S1BEG5_input[1]),
    .A2(S1BEG5_input[2]),
    .A3(S1BEG5_input[3]),
    .S0(ConfigBits[10+0]),
    .S0N(ConfigBits_N[10+0]),
    .S1(ConfigBits[10+1]),
    .S1N(ConfigBits_N[10+1]),
    .X(S1BEG5)
);

 //switch matrix multiplexer S1BEG6 MUX-4
assign S1BEG6_input = {VCC0,N2END1,N2MID1,N1END1};
cus_mux41 inst_cus_mux41_S1BEG6 (
    .A0(S1BEG6_input[0]),
    .A1(S1BEG6_input[1]),
    .A2(S1BEG6_input[2]),
    .A3(S1BEG6_input[3]),
    .S0(ConfigBits[12+0]),
    .S0N(ConfigBits_N[12+0]),
    .S1(ConfigBits[12+1]),
    .S1N(ConfigBits_N[12+1]),
    .X(S1BEG6)
);

 //switch matrix multiplexer S1BEG7 MUX-4
assign S1BEG7_input = {GND0,N2END0,N2MID0,N1END0};
cus_mux41 inst_cus_mux41_S1BEG7 (
    .A0(S1BEG7_input[0]),
    .A1(S1BEG7_input[1]),
    .A2(S1BEG7_input[2]),
    .A3(S1BEG7_input[3]),
    .S0(ConfigBits[14+0]),
    .S0N(ConfigBits_N[14+0]),
    .S1(ConfigBits[14+1]),
    .S1N(ConfigBits_N[14+1]),
    .X(S1BEG7)
);

 //switch matrix multiplexer S2BEG0 MUX-4
assign S2BEG0_input = {N2END7,N2MID7,N1END7,N1END5};
cus_mux41 inst_cus_mux41_S2BEG0 (
    .A0(S2BEG0_input[0]),
    .A1(S2BEG0_input[1]),
    .A2(S2BEG0_input[2]),
    .A3(S2BEG0_input[3]),
    .S0(ConfigBits[16+0]),
    .S0N(ConfigBits_N[16+0]),
    .S1(ConfigBits[16+1]),
    .S1N(ConfigBits_N[16+1]),
    .X(S2BEG0)
);

 //switch matrix multiplexer S2BEG1 MUX-4
assign S2BEG1_input = {N2END6,N2MID6,N1END6,N1END3};
cus_mux41 inst_cus_mux41_S2BEG1 (
    .A0(S2BEG1_input[0]),
    .A1(S2BEG1_input[1]),
    .A2(S2BEG1_input[2]),
    .A3(S2BEG1_input[3]),
    .S0(ConfigBits[18+0]),
    .S0N(ConfigBits_N[18+0]),
    .S1(ConfigBits[18+1]),
    .S1N(ConfigBits_N[18+1]),
    .X(S2BEG1)
);

 //switch matrix multiplexer S2BEG2 MUX-4
assign S2BEG2_input = {N2END5,N2END1,N2MID5,N1END5};
cus_mux41 inst_cus_mux41_S2BEG2 (
    .A0(S2BEG2_input[0]),
    .A1(S2BEG2_input[1]),
    .A2(S2BEG2_input[2]),
    .A3(S2BEG2_input[3]),
    .S0(ConfigBits[20+0]),
    .S0N(ConfigBits_N[20+0]),
    .S1(ConfigBits[20+1]),
    .S1N(ConfigBits_N[20+1]),
    .X(S2BEG2)
);

 //switch matrix multiplexer S2BEG3 MUX-4
assign S2BEG3_input = {N2END6,N2END4,N2MID4,N1END4};
cus_mux41 inst_cus_mux41_S2BEG3 (
    .A0(S2BEG3_input[0]),
    .A1(S2BEG3_input[1]),
    .A2(S2BEG3_input[2]),
    .A3(S2BEG3_input[3]),
    .S0(ConfigBits[22+0]),
    .S0N(ConfigBits_N[22+0]),
    .S1(ConfigBits[22+1]),
    .S1N(ConfigBits_N[22+1]),
    .X(S2BEG3)
);

 //switch matrix multiplexer S2BEG4 MUX-4
assign S2BEG4_input = {N2END3,N2MID3,N2MID0,N1END3};
cus_mux41 inst_cus_mux41_S2BEG4 (
    .A0(S2BEG4_input[0]),
    .A1(S2BEG4_input[1]),
    .A2(S2BEG4_input[2]),
    .A3(S2BEG4_input[3]),
    .S0(ConfigBits[24+0]),
    .S0N(ConfigBits_N[24+0]),
    .S1(ConfigBits[24+1]),
    .S1N(ConfigBits_N[24+1]),
    .X(S2BEG4)
);

 //switch matrix multiplexer S2BEG5 MUX-4
assign S2BEG5_input = {Ci0,N2END2,N2MID2,N1END2};
cus_mux41 inst_cus_mux41_S2BEG5 (
    .A0(S2BEG5_input[0]),
    .A1(S2BEG5_input[1]),
    .A2(S2BEG5_input[2]),
    .A3(S2BEG5_input[3]),
    .S0(ConfigBits[26+0]),
    .S0N(ConfigBits_N[26+0]),
    .S1(ConfigBits[26+1]),
    .S1N(ConfigBits_N[26+1]),
    .X(S2BEG5)
);

 //switch matrix multiplexer S2BEG6 MUX-4
assign S2BEG6_input = {VCC0,N2END1,N2MID1,N1END1};
cus_mux41 inst_cus_mux41_S2BEG6 (
    .A0(S2BEG6_input[0]),
    .A1(S2BEG6_input[1]),
    .A2(S2BEG6_input[2]),
    .A3(S2BEG6_input[3]),
    .S0(ConfigBits[28+0]),
    .S0N(ConfigBits_N[28+0]),
    .S1(ConfigBits[28+1]),
    .S1N(ConfigBits_N[28+1]),
    .X(S2BEG6)
);

 //switch matrix multiplexer S2BEG7 MUX-4
assign S2BEG7_input = {GND0,N2END0,N2MID0,N1END0};
cus_mux41 inst_cus_mux41_S2BEG7 (
    .A0(S2BEG7_input[0]),
    .A1(S2BEG7_input[1]),
    .A2(S2BEG7_input[2]),
    .A3(S2BEG7_input[3]),
    .S0(ConfigBits[30+0]),
    .S0N(ConfigBits_N[30+0]),
    .S1(ConfigBits[30+1]),
    .S1N(ConfigBits_N[30+1]),
    .X(S2BEG7)
);

 //switch matrix multiplexer S2BEGb0 MUX-4
assign S2BEGb0_input = {N2END7,N2MID7,N1END7,N1END5};
cus_mux41 inst_cus_mux41_S2BEGb0 (
    .A0(S2BEGb0_input[0]),
    .A1(S2BEGb0_input[1]),
    .A2(S2BEGb0_input[2]),
    .A3(S2BEGb0_input[3]),
    .S0(ConfigBits[32+0]),
    .S0N(ConfigBits_N[32+0]),
    .S1(ConfigBits[32+1]),
    .S1N(ConfigBits_N[32+1]),
    .X(S2BEGb0)
);

 //switch matrix multiplexer S2BEGb1 MUX-4
assign S2BEGb1_input = {N2END6,N2MID6,N1END6,N1END3};
cus_mux41 inst_cus_mux41_S2BEGb1 (
    .A0(S2BEGb1_input[0]),
    .A1(S2BEGb1_input[1]),
    .A2(S2BEGb1_input[2]),
    .A3(S2BEGb1_input[3]),
    .S0(ConfigBits[34+0]),
    .S0N(ConfigBits_N[34+0]),
    .S1(ConfigBits[34+1]),
    .S1N(ConfigBits_N[34+1]),
    .X(S2BEGb1)
);

 //switch matrix multiplexer S2BEGb2 MUX-4
assign S2BEGb2_input = {N2END5,N2END1,N2MID5,N1END5};
cus_mux41 inst_cus_mux41_S2BEGb2 (
    .A0(S2BEGb2_input[0]),
    .A1(S2BEGb2_input[1]),
    .A2(S2BEGb2_input[2]),
    .A3(S2BEGb2_input[3]),
    .S0(ConfigBits[36+0]),
    .S0N(ConfigBits_N[36+0]),
    .S1(ConfigBits[36+1]),
    .S1N(ConfigBits_N[36+1]),
    .X(S2BEGb2)
);

 //switch matrix multiplexer S2BEGb3 MUX-4
assign S2BEGb3_input = {N2END6,N2END4,N2MID4,N1END4};
cus_mux41 inst_cus_mux41_S2BEGb3 (
    .A0(S2BEGb3_input[0]),
    .A1(S2BEGb3_input[1]),
    .A2(S2BEGb3_input[2]),
    .A3(S2BEGb3_input[3]),
    .S0(ConfigBits[38+0]),
    .S0N(ConfigBits_N[38+0]),
    .S1(ConfigBits[38+1]),
    .S1N(ConfigBits_N[38+1]),
    .X(S2BEGb3)
);

 //switch matrix multiplexer S2BEGb4 MUX-4
assign S2BEGb4_input = {N2END3,N2MID3,N2MID0,N1END3};
cus_mux41 inst_cus_mux41_S2BEGb4 (
    .A0(S2BEGb4_input[0]),
    .A1(S2BEGb4_input[1]),
    .A2(S2BEGb4_input[2]),
    .A3(S2BEGb4_input[3]),
    .S0(ConfigBits[40+0]),
    .S0N(ConfigBits_N[40+0]),
    .S1(ConfigBits[40+1]),
    .S1N(ConfigBits_N[40+1]),
    .X(S2BEGb4)
);

 //switch matrix multiplexer S2BEGb5 MUX-4
assign S2BEGb5_input = {Ci0,N2END2,N2MID2,N1END2};
cus_mux41 inst_cus_mux41_S2BEGb5 (
    .A0(S2BEGb5_input[0]),
    .A1(S2BEGb5_input[1]),
    .A2(S2BEGb5_input[2]),
    .A3(S2BEGb5_input[3]),
    .S0(ConfigBits[42+0]),
    .S0N(ConfigBits_N[42+0]),
    .S1(ConfigBits[42+1]),
    .S1N(ConfigBits_N[42+1]),
    .X(S2BEGb5)
);

 //switch matrix multiplexer S2BEGb6 MUX-4
assign S2BEGb6_input = {VCC0,N2END1,N2MID1,N1END1};
cus_mux41 inst_cus_mux41_S2BEGb6 (
    .A0(S2BEGb6_input[0]),
    .A1(S2BEGb6_input[1]),
    .A2(S2BEGb6_input[2]),
    .A3(S2BEGb6_input[3]),
    .S0(ConfigBits[44+0]),
    .S0N(ConfigBits_N[44+0]),
    .S1(ConfigBits[44+1]),
    .S1N(ConfigBits_N[44+1]),
    .X(S2BEGb6)
);

 //switch matrix multiplexer S2BEGb7 MUX-4
assign S2BEGb7_input = {GND0,N2END0,N2MID0,N1END0};
cus_mux41 inst_cus_mux41_S2BEGb7 (
    .A0(S2BEGb7_input[0]),
    .A1(S2BEGb7_input[1]),
    .A2(S2BEGb7_input[2]),
    .A3(S2BEGb7_input[3]),
    .S0(ConfigBits[46+0]),
    .S0N(ConfigBits_N[46+0]),
    .S1(ConfigBits[46+1]),
    .S1N(ConfigBits_N[46+1]),
    .X(S2BEGb7)
);

endmodule
module N_term
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=48
    )
    (
 //S
        input  [3:0] N_GBUF_END,        //Port(Name=N_GBUF_END,IO=INPUT,XOffset=0,YOffset=-1,WireCount=4,Side=S)
        output  [7:0] S1BEG,        //Port(Name=S1BEG,IO=OUTPUT,XOffset=0,YOffset=1,WireCount=8,Side=S)
        output  [7:0] S2BEG,        //Port(Name=S2BEG,IO=OUTPUT,XOffset=0,YOffset=1,WireCount=8,Side=S)
        output  [7:0] S2BEGb,        //Port(Name=S2BEGb,IO=OUTPUT,XOffset=0,YOffset=1,WireCount=8,Side=S)
        input  [7:0] N1END,        //Port(Name=N1END,IO=INPUT,XOffset=0,YOffset=-1,WireCount=8,Side=S)
        input  [7:0] N2MID,        //Port(Name=N2MID,IO=INPUT,XOffset=0,YOffset=-1,WireCount=8,Side=S)
        input  [7:0] N2END,        //Port(Name=N2END,IO=INPUT,XOffset=0,YOffset=-1,WireCount=8,Side=S)
        input  [0:0] Ci,        //Port(Name=Ci,IO=INPUT,XOffset=0,YOffset=-1,WireCount=1,Side=S)
    //Tile IO ports from BELs
        input  [FrameBitsPerRow-1:0] FrameData, //CONFIG_PORT
        output  [FrameBitsPerRow-1:0] FrameData_O,
        input  [MaxFramesPerCol-1:0] FrameStrobe, //CONFIG_PORT
        output  [MaxFramesPerCol-1:0] FrameStrobe_O
    //global
);
 //signal declarations
 //BEL ports (e.g., slices)
 //Jump wires
 //internal configuration data signal to daisy-chain all BELs (if any and in the order they are listed in the fabric.csv)
wire[NoConfigBits-1:0] ConfigBits;
wire[NoConfigBits-1:0] ConfigBits_N;

 //Connection for outgoing wires
wire[FrameBitsPerRow-1:0] FrameData_i;
wire[FrameBitsPerRow-1:0] FrameData_O_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_O_i;

assign FrameData_O_i = FrameData_i;

my_buf data_inbuf_0 (
    .A(FrameData[0]),
    .X(FrameData_i[0])
);

my_buf data_inbuf_1 (
    .A(FrameData[1]),
    .X(FrameData_i[1])
);

my_buf data_inbuf_2 (
    .A(FrameData[2]),
    .X(FrameData_i[2])
);

my_buf data_inbuf_3 (
    .A(FrameData[3]),
    .X(FrameData_i[3])
);

my_buf data_inbuf_4 (
    .A(FrameData[4]),
    .X(FrameData_i[4])
);

my_buf data_inbuf_5 (
    .A(FrameData[5]),
    .X(FrameData_i[5])
);

my_buf data_inbuf_6 (
    .A(FrameData[6]),
    .X(FrameData_i[6])
);

my_buf data_inbuf_7 (
    .A(FrameData[7]),
    .X(FrameData_i[7])
);

my_buf data_inbuf_8 (
    .A(FrameData[8]),
    .X(FrameData_i[8])
);

my_buf data_inbuf_9 (
    .A(FrameData[9]),
    .X(FrameData_i[9])
);

my_buf data_inbuf_10 (
    .A(FrameData[10]),
    .X(FrameData_i[10])
);

my_buf data_inbuf_11 (
    .A(FrameData[11]),
    .X(FrameData_i[11])
);

my_buf data_inbuf_12 (
    .A(FrameData[12]),
    .X(FrameData_i[12])
);

my_buf data_inbuf_13 (
    .A(FrameData[13]),
    .X(FrameData_i[13])
);

my_buf data_inbuf_14 (
    .A(FrameData[14]),
    .X(FrameData_i[14])
);

my_buf data_inbuf_15 (
    .A(FrameData[15]),
    .X(FrameData_i[15])
);

my_buf data_inbuf_16 (
    .A(FrameData[16]),
    .X(FrameData_i[16])
);

my_buf data_inbuf_17 (
    .A(FrameData[17]),
    .X(FrameData_i[17])
);

my_buf data_inbuf_18 (
    .A(FrameData[18]),
    .X(FrameData_i[18])
);

my_buf data_inbuf_19 (
    .A(FrameData[19]),
    .X(FrameData_i[19])
);

my_buf data_inbuf_20 (
    .A(FrameData[20]),
    .X(FrameData_i[20])
);

my_buf data_inbuf_21 (
    .A(FrameData[21]),
    .X(FrameData_i[21])
);

my_buf data_inbuf_22 (
    .A(FrameData[22]),
    .X(FrameData_i[22])
);

my_buf data_inbuf_23 (
    .A(FrameData[23]),
    .X(FrameData_i[23])
);

my_buf data_inbuf_24 (
    .A(FrameData[24]),
    .X(FrameData_i[24])
);

my_buf data_inbuf_25 (
    .A(FrameData[25]),
    .X(FrameData_i[25])
);

my_buf data_inbuf_26 (
    .A(FrameData[26]),
    .X(FrameData_i[26])
);

my_buf data_inbuf_27 (
    .A(FrameData[27]),
    .X(FrameData_i[27])
);

my_buf data_inbuf_28 (
    .A(FrameData[28]),
    .X(FrameData_i[28])
);

my_buf data_inbuf_29 (
    .A(FrameData[29]),
    .X(FrameData_i[29])
);

my_buf data_inbuf_30 (
    .A(FrameData[30]),
    .X(FrameData_i[30])
);

my_buf data_inbuf_31 (
    .A(FrameData[31]),
    .X(FrameData_i[31])
);

my_buf data_outbuf_0 (
    .A(FrameData_O_i[0]),
    .X(FrameData_O[0])
);

my_buf data_outbuf_1 (
    .A(FrameData_O_i[1]),
    .X(FrameData_O[1])
);

my_buf data_outbuf_2 (
    .A(FrameData_O_i[2]),
    .X(FrameData_O[2])
);

my_buf data_outbuf_3 (
    .A(FrameData_O_i[3]),
    .X(FrameData_O[3])
);

my_buf data_outbuf_4 (
    .A(FrameData_O_i[4]),
    .X(FrameData_O[4])
);

my_buf data_outbuf_5 (
    .A(FrameData_O_i[5]),
    .X(FrameData_O[5])
);

my_buf data_outbuf_6 (
    .A(FrameData_O_i[6]),
    .X(FrameData_O[6])
);

my_buf data_outbuf_7 (
    .A(FrameData_O_i[7]),
    .X(FrameData_O[7])
);

my_buf data_outbuf_8 (
    .A(FrameData_O_i[8]),
    .X(FrameData_O[8])
);

my_buf data_outbuf_9 (
    .A(FrameData_O_i[9]),
    .X(FrameData_O[9])
);

my_buf data_outbuf_10 (
    .A(FrameData_O_i[10]),
    .X(FrameData_O[10])
);

my_buf data_outbuf_11 (
    .A(FrameData_O_i[11]),
    .X(FrameData_O[11])
);

my_buf data_outbuf_12 (
    .A(FrameData_O_i[12]),
    .X(FrameData_O[12])
);

my_buf data_outbuf_13 (
    .A(FrameData_O_i[13]),
    .X(FrameData_O[13])
);

my_buf data_outbuf_14 (
    .A(FrameData_O_i[14]),
    .X(FrameData_O[14])
);

my_buf data_outbuf_15 (
    .A(FrameData_O_i[15]),
    .X(FrameData_O[15])
);

my_buf data_outbuf_16 (
    .A(FrameData_O_i[16]),
    .X(FrameData_O[16])
);

my_buf data_outbuf_17 (
    .A(FrameData_O_i[17]),
    .X(FrameData_O[17])
);

my_buf data_outbuf_18 (
    .A(FrameData_O_i[18]),
    .X(FrameData_O[18])
);

my_buf data_outbuf_19 (
    .A(FrameData_O_i[19]),
    .X(FrameData_O[19])
);

my_buf data_outbuf_20 (
    .A(FrameData_O_i[20]),
    .X(FrameData_O[20])
);

my_buf data_outbuf_21 (
    .A(FrameData_O_i[21]),
    .X(FrameData_O[21])
);

my_buf data_outbuf_22 (
    .A(FrameData_O_i[22]),
    .X(FrameData_O[22])
);

my_buf data_outbuf_23 (
    .A(FrameData_O_i[23]),
    .X(FrameData_O[23])
);

my_buf data_outbuf_24 (
    .A(FrameData_O_i[24]),
    .X(FrameData_O[24])
);

my_buf data_outbuf_25 (
    .A(FrameData_O_i[25]),
    .X(FrameData_O[25])
);

my_buf data_outbuf_26 (
    .A(FrameData_O_i[26]),
    .X(FrameData_O[26])
);

my_buf data_outbuf_27 (
    .A(FrameData_O_i[27]),
    .X(FrameData_O[27])
);

my_buf data_outbuf_28 (
    .A(FrameData_O_i[28]),
    .X(FrameData_O[28])
);

my_buf data_outbuf_29 (
    .A(FrameData_O_i[29]),
    .X(FrameData_O[29])
);

my_buf data_outbuf_30 (
    .A(FrameData_O_i[30]),
    .X(FrameData_O[30])
);

my_buf data_outbuf_31 (
    .A(FrameData_O_i[31]),
    .X(FrameData_O[31])
);

assign FrameStrobe_O_i = FrameStrobe_i;

my_buf strobe_inbuf_0 (
    .A(FrameStrobe[0]),
    .X(FrameStrobe_i[0])
);

my_buf strobe_inbuf_1 (
    .A(FrameStrobe[1]),
    .X(FrameStrobe_i[1])
);

my_buf strobe_inbuf_2 (
    .A(FrameStrobe[2]),
    .X(FrameStrobe_i[2])
);

my_buf strobe_inbuf_3 (
    .A(FrameStrobe[3]),
    .X(FrameStrobe_i[3])
);

my_buf strobe_inbuf_4 (
    .A(FrameStrobe[4]),
    .X(FrameStrobe_i[4])
);

my_buf strobe_inbuf_5 (
    .A(FrameStrobe[5]),
    .X(FrameStrobe_i[5])
);

my_buf strobe_inbuf_6 (
    .A(FrameStrobe[6]),
    .X(FrameStrobe_i[6])
);

my_buf strobe_inbuf_7 (
    .A(FrameStrobe[7]),
    .X(FrameStrobe_i[7])
);

my_buf strobe_inbuf_8 (
    .A(FrameStrobe[8]),
    .X(FrameStrobe_i[8])
);

my_buf strobe_inbuf_9 (
    .A(FrameStrobe[9]),
    .X(FrameStrobe_i[9])
);

my_buf strobe_inbuf_10 (
    .A(FrameStrobe[10]),
    .X(FrameStrobe_i[10])
);

my_buf strobe_inbuf_11 (
    .A(FrameStrobe[11]),
    .X(FrameStrobe_i[11])
);

my_buf strobe_inbuf_12 (
    .A(FrameStrobe[12]),
    .X(FrameStrobe_i[12])
);

my_buf strobe_inbuf_13 (
    .A(FrameStrobe[13]),
    .X(FrameStrobe_i[13])
);

my_buf strobe_inbuf_14 (
    .A(FrameStrobe[14]),
    .X(FrameStrobe_i[14])
);

my_buf strobe_inbuf_15 (
    .A(FrameStrobe[15]),
    .X(FrameStrobe_i[15])
);

my_buf strobe_inbuf_16 (
    .A(FrameStrobe[16]),
    .X(FrameStrobe_i[16])
);

my_buf strobe_inbuf_17 (
    .A(FrameStrobe[17]),
    .X(FrameStrobe_i[17])
);

my_buf strobe_inbuf_18 (
    .A(FrameStrobe[18]),
    .X(FrameStrobe_i[18])
);

my_buf strobe_inbuf_19 (
    .A(FrameStrobe[19]),
    .X(FrameStrobe_i[19])
);

my_buf strobe_outbuf_0 (
    .A(FrameStrobe_O_i[0]),
    .X(FrameStrobe_O[0])
);

my_buf strobe_outbuf_1 (
    .A(FrameStrobe_O_i[1]),
    .X(FrameStrobe_O[1])
);

my_buf strobe_outbuf_2 (
    .A(FrameStrobe_O_i[2]),
    .X(FrameStrobe_O[2])
);

my_buf strobe_outbuf_3 (
    .A(FrameStrobe_O_i[3]),
    .X(FrameStrobe_O[3])
);

my_buf strobe_outbuf_4 (
    .A(FrameStrobe_O_i[4]),
    .X(FrameStrobe_O[4])
);

my_buf strobe_outbuf_5 (
    .A(FrameStrobe_O_i[5]),
    .X(FrameStrobe_O[5])
);

my_buf strobe_outbuf_6 (
    .A(FrameStrobe_O_i[6]),
    .X(FrameStrobe_O[6])
);

my_buf strobe_outbuf_7 (
    .A(FrameStrobe_O_i[7]),
    .X(FrameStrobe_O[7])
);

my_buf strobe_outbuf_8 (
    .A(FrameStrobe_O_i[8]),
    .X(FrameStrobe_O[8])
);

my_buf strobe_outbuf_9 (
    .A(FrameStrobe_O_i[9]),
    .X(FrameStrobe_O[9])
);

my_buf strobe_outbuf_10 (
    .A(FrameStrobe_O_i[10]),
    .X(FrameStrobe_O[10])
);

my_buf strobe_outbuf_11 (
    .A(FrameStrobe_O_i[11]),
    .X(FrameStrobe_O[11])
);

my_buf strobe_outbuf_12 (
    .A(FrameStrobe_O_i[12]),
    .X(FrameStrobe_O[12])
);

my_buf strobe_outbuf_13 (
    .A(FrameStrobe_O_i[13]),
    .X(FrameStrobe_O[13])
);

my_buf strobe_outbuf_14 (
    .A(FrameStrobe_O_i[14]),
    .X(FrameStrobe_O[14])
);

my_buf strobe_outbuf_15 (
    .A(FrameStrobe_O_i[15]),
    .X(FrameStrobe_O[15])
);

my_buf strobe_outbuf_16 (
    .A(FrameStrobe_O_i[16]),
    .X(FrameStrobe_O[16])
);

my_buf strobe_outbuf_17 (
    .A(FrameStrobe_O_i[17]),
    .X(FrameStrobe_O[17])
);

my_buf strobe_outbuf_18 (
    .A(FrameStrobe_O_i[18]),
    .X(FrameStrobe_O[18])
);

my_buf strobe_outbuf_19 (
    .A(FrameStrobe_O_i[19]),
    .X(FrameStrobe_O[19])
);


 //configuration storage latches
N_term_ConfigMem
`ifdef EMULATION
    #(
    .Emulate_Bitstream(Emulate_Bitstream)
    )
`endif
    Inst_N_term_ConfigMem
    (
    .FrameData(FrameData),
    .FrameStrobe(FrameStrobe),
    .ConfigBits(ConfigBits),
    .ConfigBits_N(ConfigBits_N)
);

N_term_switch_matrix Inst_N_term_switch_matrix (
    .N_GBUF_END0(N_GBUF_END[0]),
    .N_GBUF_END1(N_GBUF_END[1]),
    .N_GBUF_END2(N_GBUF_END[2]),
    .N_GBUF_END3(N_GBUF_END[3]),
    .N1END0(N1END[0]),
    .N1END1(N1END[1]),
    .N1END2(N1END[2]),
    .N1END3(N1END[3]),
    .N1END4(N1END[4]),
    .N1END5(N1END[5]),
    .N1END6(N1END[6]),
    .N1END7(N1END[7]),
    .N2MID0(N2MID[0]),
    .N2MID1(N2MID[1]),
    .N2MID2(N2MID[2]),
    .N2MID3(N2MID[3]),
    .N2MID4(N2MID[4]),
    .N2MID5(N2MID[5]),
    .N2MID6(N2MID[6]),
    .N2MID7(N2MID[7]),
    .N2END0(N2END[0]),
    .N2END1(N2END[1]),
    .N2END2(N2END[2]),
    .N2END3(N2END[3]),
    .N2END4(N2END[4]),
    .N2END5(N2END[5]),
    .N2END6(N2END[6]),
    .N2END7(N2END[7]),
    .Ci0(Ci[0]),
    .S1BEG0(S1BEG[0]),
    .S1BEG1(S1BEG[1]),
    .S1BEG2(S1BEG[2]),
    .S1BEG3(S1BEG[3]),
    .S1BEG4(S1BEG[4]),
    .S1BEG5(S1BEG[5]),
    .S1BEG6(S1BEG[6]),
    .S1BEG7(S1BEG[7]),
    .S2BEG0(S2BEG[0]),
    .S2BEG1(S2BEG[1]),
    .S2BEG2(S2BEG[2]),
    .S2BEG3(S2BEG[3]),
    .S2BEG4(S2BEG[4]),
    .S2BEG5(S2BEG[5]),
    .S2BEG6(S2BEG[6]),
    .S2BEG7(S2BEG[7]),
    .S2BEGb0(S2BEGb[0]),
    .S2BEGb1(S2BEGb[1]),
    .S2BEGb2(S2BEGb[2]),
    .S2BEGb3(S2BEGb[3]),
    .S2BEGb4(S2BEGb[4]),
    .S2BEGb5(S2BEGb[5]),
    .S2BEGb6(S2BEGb[6]),
    .S2BEGb7(S2BEGb[7]),
    .ConfigBits(ConfigBits[48-1:0]),
    .ConfigBits_N(ConfigBits_N[48-1:0])
);

endmodule
module NW_term_ConfigMem
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=4
    )
    (
        input  [FrameBitsPerRow - 1:0] FrameData,
        input  [MaxFramesPerCol - 1:0] FrameStrobe,
        output  [NoConfigBits - 1:0] ConfigBits,
        output  [NoConfigBits - 1:0] ConfigBits_N
    );

`ifdef EMULATION
assign ConfigBits[3] = Emulate_Bitstream[31];
assign ConfigBits[2] = Emulate_Bitstream[30];
assign ConfigBits[1] = Emulate_Bitstream[29];
assign ConfigBits[0] = Emulate_Bitstream[28];
`else

 //instantiate frame latches
config_latch Inst_frame0_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[3]),
    .QN(ConfigBits_N[3])
);

config_latch Inst_frame0_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[2]),
    .QN(ConfigBits_N[2])
);

config_latch Inst_frame0_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[1]),
    .QN(ConfigBits_N[1])
);

config_latch Inst_frame0_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[0]),
    .QN(ConfigBits_N[0])
);

`endif
endmodule
 // NumberOfConfigBits: 4
module NW_term_switch_matrix
    #(
        parameter NoConfigBits=4
    )
    (
        input  N_GBUF_END0,
        input  N_GBUF_END1,
        input  N_GBUF_END2,
        input  N_GBUF_END3,
        output  S_GBUF_FEED_BEG0,
        output  S_GBUF_FEED_BEG1,
        output  S_GBUF_FEED_BEG2,
        output  S_GBUF_FEED_BEG3,
 //global
        input  [NoConfigBits-1:0] ConfigBits,
        input  [NoConfigBits-1:0] ConfigBits_N
);
parameter GND0 = 1'b0;
parameter GND = 1'b0;
parameter VCC0 = 1'b1;
parameter VCC = 1'b1;
parameter VDD0 = 1'b1;
parameter VDD = 1'b1;

wire[2-1:0] S_GBUF_FEED_BEG0_input;
wire[2-1:0] S_GBUF_FEED_BEG1_input;
wire[2-1:0] S_GBUF_FEED_BEG2_input;
wire[2-1:0] S_GBUF_FEED_BEG3_input;
 //The configuration bits (if any) are just a long shift register
 //This shift register is padded to an even number of flops/latches
 //switch matrix multiplexer S_GBUF_FEED_BEG0 MUX-2
assign S_GBUF_FEED_BEG0_input = {VCC0,GND0};
cus_mux21 inst_cus_mux21_S_GBUF_FEED_BEG0 (
    .A0(S_GBUF_FEED_BEG0_input[0]),
    .A1(S_GBUF_FEED_BEG0_input[1]),
    .S(ConfigBits[0+0]),
    .X(S_GBUF_FEED_BEG0)
);

 //switch matrix multiplexer S_GBUF_FEED_BEG1 MUX-2
assign S_GBUF_FEED_BEG1_input = {VCC0,GND0};
cus_mux21 inst_cus_mux21_S_GBUF_FEED_BEG1 (
    .A0(S_GBUF_FEED_BEG1_input[0]),
    .A1(S_GBUF_FEED_BEG1_input[1]),
    .S(ConfigBits[1+0]),
    .X(S_GBUF_FEED_BEG1)
);

 //switch matrix multiplexer S_GBUF_FEED_BEG2 MUX-2
assign S_GBUF_FEED_BEG2_input = {VCC0,GND0};
cus_mux21 inst_cus_mux21_S_GBUF_FEED_BEG2 (
    .A0(S_GBUF_FEED_BEG2_input[0]),
    .A1(S_GBUF_FEED_BEG2_input[1]),
    .S(ConfigBits[2+0]),
    .X(S_GBUF_FEED_BEG2)
);

 //switch matrix multiplexer S_GBUF_FEED_BEG3 MUX-2
assign S_GBUF_FEED_BEG3_input = {VCC0,GND0};
cus_mux21 inst_cus_mux21_S_GBUF_FEED_BEG3 (
    .A0(S_GBUF_FEED_BEG3_input[0]),
    .A1(S_GBUF_FEED_BEG3_input[1]),
    .S(ConfigBits[3+0]),
    .X(S_GBUF_FEED_BEG3)
);

endmodule
module NW_term
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=4
    )
    (
 //S
        output  [3:0] S_GBUF_FEED_BEG,        //Port(Name=S_GBUF_FEED_BEG,IO=OUTPUT,XOffset=0,YOffset=1,WireCount=4,Side=S)
        input  [3:0] N_GBUF_END,        //Port(Name=N_GBUF_END,IO=INPUT,XOffset=0,YOffset=-1,WireCount=4,Side=S)
    //Tile IO ports from BELs
        input  [FrameBitsPerRow-1:0] FrameData, //CONFIG_PORT
        output  [FrameBitsPerRow-1:0] FrameData_O,
        input  [MaxFramesPerCol-1:0] FrameStrobe, //CONFIG_PORT
        output  [MaxFramesPerCol-1:0] FrameStrobe_O
    //global
);
 //signal declarations
 //BEL ports (e.g., slices)
 //Jump wires
 //internal configuration data signal to daisy-chain all BELs (if any and in the order they are listed in the fabric.csv)
wire[NoConfigBits-1:0] ConfigBits;
wire[NoConfigBits-1:0] ConfigBits_N;

 //Connection for outgoing wires
wire[FrameBitsPerRow-1:0] FrameData_i;
wire[FrameBitsPerRow-1:0] FrameData_O_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_O_i;

assign FrameData_O_i = FrameData_i;

my_buf data_inbuf_0 (
    .A(FrameData[0]),
    .X(FrameData_i[0])
);

my_buf data_inbuf_1 (
    .A(FrameData[1]),
    .X(FrameData_i[1])
);

my_buf data_inbuf_2 (
    .A(FrameData[2]),
    .X(FrameData_i[2])
);

my_buf data_inbuf_3 (
    .A(FrameData[3]),
    .X(FrameData_i[3])
);

my_buf data_inbuf_4 (
    .A(FrameData[4]),
    .X(FrameData_i[4])
);

my_buf data_inbuf_5 (
    .A(FrameData[5]),
    .X(FrameData_i[5])
);

my_buf data_inbuf_6 (
    .A(FrameData[6]),
    .X(FrameData_i[6])
);

my_buf data_inbuf_7 (
    .A(FrameData[7]),
    .X(FrameData_i[7])
);

my_buf data_inbuf_8 (
    .A(FrameData[8]),
    .X(FrameData_i[8])
);

my_buf data_inbuf_9 (
    .A(FrameData[9]),
    .X(FrameData_i[9])
);

my_buf data_inbuf_10 (
    .A(FrameData[10]),
    .X(FrameData_i[10])
);

my_buf data_inbuf_11 (
    .A(FrameData[11]),
    .X(FrameData_i[11])
);

my_buf data_inbuf_12 (
    .A(FrameData[12]),
    .X(FrameData_i[12])
);

my_buf data_inbuf_13 (
    .A(FrameData[13]),
    .X(FrameData_i[13])
);

my_buf data_inbuf_14 (
    .A(FrameData[14]),
    .X(FrameData_i[14])
);

my_buf data_inbuf_15 (
    .A(FrameData[15]),
    .X(FrameData_i[15])
);

my_buf data_inbuf_16 (
    .A(FrameData[16]),
    .X(FrameData_i[16])
);

my_buf data_inbuf_17 (
    .A(FrameData[17]),
    .X(FrameData_i[17])
);

my_buf data_inbuf_18 (
    .A(FrameData[18]),
    .X(FrameData_i[18])
);

my_buf data_inbuf_19 (
    .A(FrameData[19]),
    .X(FrameData_i[19])
);

my_buf data_inbuf_20 (
    .A(FrameData[20]),
    .X(FrameData_i[20])
);

my_buf data_inbuf_21 (
    .A(FrameData[21]),
    .X(FrameData_i[21])
);

my_buf data_inbuf_22 (
    .A(FrameData[22]),
    .X(FrameData_i[22])
);

my_buf data_inbuf_23 (
    .A(FrameData[23]),
    .X(FrameData_i[23])
);

my_buf data_inbuf_24 (
    .A(FrameData[24]),
    .X(FrameData_i[24])
);

my_buf data_inbuf_25 (
    .A(FrameData[25]),
    .X(FrameData_i[25])
);

my_buf data_inbuf_26 (
    .A(FrameData[26]),
    .X(FrameData_i[26])
);

my_buf data_inbuf_27 (
    .A(FrameData[27]),
    .X(FrameData_i[27])
);

my_buf data_inbuf_28 (
    .A(FrameData[28]),
    .X(FrameData_i[28])
);

my_buf data_inbuf_29 (
    .A(FrameData[29]),
    .X(FrameData_i[29])
);

my_buf data_inbuf_30 (
    .A(FrameData[30]),
    .X(FrameData_i[30])
);

my_buf data_inbuf_31 (
    .A(FrameData[31]),
    .X(FrameData_i[31])
);

my_buf data_outbuf_0 (
    .A(FrameData_O_i[0]),
    .X(FrameData_O[0])
);

my_buf data_outbuf_1 (
    .A(FrameData_O_i[1]),
    .X(FrameData_O[1])
);

my_buf data_outbuf_2 (
    .A(FrameData_O_i[2]),
    .X(FrameData_O[2])
);

my_buf data_outbuf_3 (
    .A(FrameData_O_i[3]),
    .X(FrameData_O[3])
);

my_buf data_outbuf_4 (
    .A(FrameData_O_i[4]),
    .X(FrameData_O[4])
);

my_buf data_outbuf_5 (
    .A(FrameData_O_i[5]),
    .X(FrameData_O[5])
);

my_buf data_outbuf_6 (
    .A(FrameData_O_i[6]),
    .X(FrameData_O[6])
);

my_buf data_outbuf_7 (
    .A(FrameData_O_i[7]),
    .X(FrameData_O[7])
);

my_buf data_outbuf_8 (
    .A(FrameData_O_i[8]),
    .X(FrameData_O[8])
);

my_buf data_outbuf_9 (
    .A(FrameData_O_i[9]),
    .X(FrameData_O[9])
);

my_buf data_outbuf_10 (
    .A(FrameData_O_i[10]),
    .X(FrameData_O[10])
);

my_buf data_outbuf_11 (
    .A(FrameData_O_i[11]),
    .X(FrameData_O[11])
);

my_buf data_outbuf_12 (
    .A(FrameData_O_i[12]),
    .X(FrameData_O[12])
);

my_buf data_outbuf_13 (
    .A(FrameData_O_i[13]),
    .X(FrameData_O[13])
);

my_buf data_outbuf_14 (
    .A(FrameData_O_i[14]),
    .X(FrameData_O[14])
);

my_buf data_outbuf_15 (
    .A(FrameData_O_i[15]),
    .X(FrameData_O[15])
);

my_buf data_outbuf_16 (
    .A(FrameData_O_i[16]),
    .X(FrameData_O[16])
);

my_buf data_outbuf_17 (
    .A(FrameData_O_i[17]),
    .X(FrameData_O[17])
);

my_buf data_outbuf_18 (
    .A(FrameData_O_i[18]),
    .X(FrameData_O[18])
);

my_buf data_outbuf_19 (
    .A(FrameData_O_i[19]),
    .X(FrameData_O[19])
);

my_buf data_outbuf_20 (
    .A(FrameData_O_i[20]),
    .X(FrameData_O[20])
);

my_buf data_outbuf_21 (
    .A(FrameData_O_i[21]),
    .X(FrameData_O[21])
);

my_buf data_outbuf_22 (
    .A(FrameData_O_i[22]),
    .X(FrameData_O[22])
);

my_buf data_outbuf_23 (
    .A(FrameData_O_i[23]),
    .X(FrameData_O[23])
);

my_buf data_outbuf_24 (
    .A(FrameData_O_i[24]),
    .X(FrameData_O[24])
);

my_buf data_outbuf_25 (
    .A(FrameData_O_i[25]),
    .X(FrameData_O[25])
);

my_buf data_outbuf_26 (
    .A(FrameData_O_i[26]),
    .X(FrameData_O[26])
);

my_buf data_outbuf_27 (
    .A(FrameData_O_i[27]),
    .X(FrameData_O[27])
);

my_buf data_outbuf_28 (
    .A(FrameData_O_i[28]),
    .X(FrameData_O[28])
);

my_buf data_outbuf_29 (
    .A(FrameData_O_i[29]),
    .X(FrameData_O[29])
);

my_buf data_outbuf_30 (
    .A(FrameData_O_i[30]),
    .X(FrameData_O[30])
);

my_buf data_outbuf_31 (
    .A(FrameData_O_i[31]),
    .X(FrameData_O[31])
);

assign FrameStrobe_O_i = FrameStrobe_i;

my_buf strobe_inbuf_0 (
    .A(FrameStrobe[0]),
    .X(FrameStrobe_i[0])
);

my_buf strobe_inbuf_1 (
    .A(FrameStrobe[1]),
    .X(FrameStrobe_i[1])
);

my_buf strobe_inbuf_2 (
    .A(FrameStrobe[2]),
    .X(FrameStrobe_i[2])
);

my_buf strobe_inbuf_3 (
    .A(FrameStrobe[3]),
    .X(FrameStrobe_i[3])
);

my_buf strobe_inbuf_4 (
    .A(FrameStrobe[4]),
    .X(FrameStrobe_i[4])
);

my_buf strobe_inbuf_5 (
    .A(FrameStrobe[5]),
    .X(FrameStrobe_i[5])
);

my_buf strobe_inbuf_6 (
    .A(FrameStrobe[6]),
    .X(FrameStrobe_i[6])
);

my_buf strobe_inbuf_7 (
    .A(FrameStrobe[7]),
    .X(FrameStrobe_i[7])
);

my_buf strobe_inbuf_8 (
    .A(FrameStrobe[8]),
    .X(FrameStrobe_i[8])
);

my_buf strobe_inbuf_9 (
    .A(FrameStrobe[9]),
    .X(FrameStrobe_i[9])
);

my_buf strobe_inbuf_10 (
    .A(FrameStrobe[10]),
    .X(FrameStrobe_i[10])
);

my_buf strobe_inbuf_11 (
    .A(FrameStrobe[11]),
    .X(FrameStrobe_i[11])
);

my_buf strobe_inbuf_12 (
    .A(FrameStrobe[12]),
    .X(FrameStrobe_i[12])
);

my_buf strobe_inbuf_13 (
    .A(FrameStrobe[13]),
    .X(FrameStrobe_i[13])
);

my_buf strobe_inbuf_14 (
    .A(FrameStrobe[14]),
    .X(FrameStrobe_i[14])
);

my_buf strobe_inbuf_15 (
    .A(FrameStrobe[15]),
    .X(FrameStrobe_i[15])
);

my_buf strobe_inbuf_16 (
    .A(FrameStrobe[16]),
    .X(FrameStrobe_i[16])
);

my_buf strobe_inbuf_17 (
    .A(FrameStrobe[17]),
    .X(FrameStrobe_i[17])
);

my_buf strobe_inbuf_18 (
    .A(FrameStrobe[18]),
    .X(FrameStrobe_i[18])
);

my_buf strobe_inbuf_19 (
    .A(FrameStrobe[19]),
    .X(FrameStrobe_i[19])
);

my_buf strobe_outbuf_0 (
    .A(FrameStrobe_O_i[0]),
    .X(FrameStrobe_O[0])
);

my_buf strobe_outbuf_1 (
    .A(FrameStrobe_O_i[1]),
    .X(FrameStrobe_O[1])
);

my_buf strobe_outbuf_2 (
    .A(FrameStrobe_O_i[2]),
    .X(FrameStrobe_O[2])
);

my_buf strobe_outbuf_3 (
    .A(FrameStrobe_O_i[3]),
    .X(FrameStrobe_O[3])
);

my_buf strobe_outbuf_4 (
    .A(FrameStrobe_O_i[4]),
    .X(FrameStrobe_O[4])
);

my_buf strobe_outbuf_5 (
    .A(FrameStrobe_O_i[5]),
    .X(FrameStrobe_O[5])
);

my_buf strobe_outbuf_6 (
    .A(FrameStrobe_O_i[6]),
    .X(FrameStrobe_O[6])
);

my_buf strobe_outbuf_7 (
    .A(FrameStrobe_O_i[7]),
    .X(FrameStrobe_O[7])
);

my_buf strobe_outbuf_8 (
    .A(FrameStrobe_O_i[8]),
    .X(FrameStrobe_O[8])
);

my_buf strobe_outbuf_9 (
    .A(FrameStrobe_O_i[9]),
    .X(FrameStrobe_O[9])
);

my_buf strobe_outbuf_10 (
    .A(FrameStrobe_O_i[10]),
    .X(FrameStrobe_O[10])
);

my_buf strobe_outbuf_11 (
    .A(FrameStrobe_O_i[11]),
    .X(FrameStrobe_O[11])
);

my_buf strobe_outbuf_12 (
    .A(FrameStrobe_O_i[12]),
    .X(FrameStrobe_O[12])
);

my_buf strobe_outbuf_13 (
    .A(FrameStrobe_O_i[13]),
    .X(FrameStrobe_O[13])
);

my_buf strobe_outbuf_14 (
    .A(FrameStrobe_O_i[14]),
    .X(FrameStrobe_O[14])
);

my_buf strobe_outbuf_15 (
    .A(FrameStrobe_O_i[15]),
    .X(FrameStrobe_O[15])
);

my_buf strobe_outbuf_16 (
    .A(FrameStrobe_O_i[16]),
    .X(FrameStrobe_O[16])
);

my_buf strobe_outbuf_17 (
    .A(FrameStrobe_O_i[17]),
    .X(FrameStrobe_O[17])
);

my_buf strobe_outbuf_18 (
    .A(FrameStrobe_O_i[18]),
    .X(FrameStrobe_O[18])
);

my_buf strobe_outbuf_19 (
    .A(FrameStrobe_O_i[19]),
    .X(FrameStrobe_O[19])
);


 //configuration storage latches
NW_term_ConfigMem
`ifdef EMULATION
    #(
    .Emulate_Bitstream(Emulate_Bitstream)
    )
`endif
    Inst_NW_term_ConfigMem
    (
    .FrameData(FrameData),
    .FrameStrobe(FrameStrobe),
    .ConfigBits(ConfigBits),
    .ConfigBits_N(ConfigBits_N)
);

NW_term_switch_matrix Inst_NW_term_switch_matrix (
    .N_GBUF_END0(N_GBUF_END[0]),
    .N_GBUF_END1(N_GBUF_END[1]),
    .N_GBUF_END2(N_GBUF_END[2]),
    .N_GBUF_END3(N_GBUF_END[3]),
    .S_GBUF_FEED_BEG0(S_GBUF_FEED_BEG[0]),
    .S_GBUF_FEED_BEG1(S_GBUF_FEED_BEG[1]),
    .S_GBUF_FEED_BEG2(S_GBUF_FEED_BEG[2]),
    .S_GBUF_FEED_BEG3(S_GBUF_FEED_BEG[3]),
    .ConfigBits(ConfigBits[4-1:0]),
    .ConfigBits_N(ConfigBits_N[4-1:0])
);

endmodule
module SE_term_ConfigMem
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=4
    )
    (
        input  [FrameBitsPerRow - 1:0] FrameData,
        input  [MaxFramesPerCol - 1:0] FrameStrobe,
        output  [NoConfigBits - 1:0] ConfigBits,
        output  [NoConfigBits - 1:0] ConfigBits_N
    );

`ifdef EMULATION
assign ConfigBits[3] = Emulate_Bitstream[31];
assign ConfigBits[2] = Emulate_Bitstream[30];
assign ConfigBits[1] = Emulate_Bitstream[29];
assign ConfigBits[0] = Emulate_Bitstream[28];
`else

 //instantiate frame latches
config_latch Inst_frame0_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[3]),
    .QN(ConfigBits_N[3])
);

config_latch Inst_frame0_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[2]),
    .QN(ConfigBits_N[2])
);

config_latch Inst_frame0_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[1]),
    .QN(ConfigBits_N[1])
);

config_latch Inst_frame0_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[0]),
    .QN(ConfigBits_N[0])
);

`endif
endmodule
 // NumberOfConfigBits: 4
module SE_term_switch_matrix
    #(
        parameter NoConfigBits=4
    )
    (
        input  E_GBUF_END0,
        input  E_GBUF_END1,
        input  E_GBUF_END2,
        input  E_GBUF_END3,
        output  W_GBUF_FEED_BEG0,
        output  W_GBUF_FEED_BEG1,
        output  W_GBUF_FEED_BEG2,
        output  W_GBUF_FEED_BEG3,
        output  N_GBUF_BEG0,
        output  N_GBUF_BEG1,
        output  N_GBUF_BEG2,
        output  N_GBUF_BEG3,
 //global
        input  [NoConfigBits-1:0] ConfigBits,
        input  [NoConfigBits-1:0] ConfigBits_N
);
parameter GND0 = 1'b0;
parameter GND = 1'b0;
parameter VCC0 = 1'b1;
parameter VCC = 1'b1;
parameter VDD0 = 1'b1;
parameter VDD = 1'b1;

wire[2-1:0] W_GBUF_FEED_BEG0_input;
wire[2-1:0] W_GBUF_FEED_BEG1_input;
wire[2-1:0] W_GBUF_FEED_BEG2_input;
wire[2-1:0] W_GBUF_FEED_BEG3_input;
 //The configuration bits (if any) are just a long shift register
 //This shift register is padded to an even number of flops/latches
 //switch matrix multiplexer W_GBUF_FEED_BEG0 MUX-2
assign W_GBUF_FEED_BEG0_input = {VCC0,GND0};
cus_mux21 inst_cus_mux21_W_GBUF_FEED_BEG0 (
    .A0(W_GBUF_FEED_BEG0_input[0]),
    .A1(W_GBUF_FEED_BEG0_input[1]),
    .S(ConfigBits[0+0]),
    .X(W_GBUF_FEED_BEG0)
);

 //switch matrix multiplexer W_GBUF_FEED_BEG1 MUX-2
assign W_GBUF_FEED_BEG1_input = {VCC0,GND0};
cus_mux21 inst_cus_mux21_W_GBUF_FEED_BEG1 (
    .A0(W_GBUF_FEED_BEG1_input[0]),
    .A1(W_GBUF_FEED_BEG1_input[1]),
    .S(ConfigBits[1+0]),
    .X(W_GBUF_FEED_BEG1)
);

 //switch matrix multiplexer W_GBUF_FEED_BEG2 MUX-2
assign W_GBUF_FEED_BEG2_input = {VCC0,GND0};
cus_mux21 inst_cus_mux21_W_GBUF_FEED_BEG2 (
    .A0(W_GBUF_FEED_BEG2_input[0]),
    .A1(W_GBUF_FEED_BEG2_input[1]),
    .S(ConfigBits[2+0]),
    .X(W_GBUF_FEED_BEG2)
);

 //switch matrix multiplexer W_GBUF_FEED_BEG3 MUX-2
assign W_GBUF_FEED_BEG3_input = {VCC0,GND0};
cus_mux21 inst_cus_mux21_W_GBUF_FEED_BEG3 (
    .A0(W_GBUF_FEED_BEG3_input[0]),
    .A1(W_GBUF_FEED_BEG3_input[1]),
    .S(ConfigBits[3+0]),
    .X(W_GBUF_FEED_BEG3)
);

 //switch matrix multiplexer N_GBUF_BEG0 MUX-1
assign N_GBUF_BEG0 = E_GBUF_END0;

 //switch matrix multiplexer N_GBUF_BEG1 MUX-1
assign N_GBUF_BEG1 = E_GBUF_END1;

 //switch matrix multiplexer N_GBUF_BEG2 MUX-1
assign N_GBUF_BEG2 = E_GBUF_END2;

 //switch matrix multiplexer N_GBUF_BEG3 MUX-1
assign N_GBUF_BEG3 = E_GBUF_END3;

endmodule
module SE_term
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=4
    )
    (
 //N
        output  [3:0] N_GBUF_BEG,        //Port(Name=N_GBUF_BEG,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=4,Side=N)
 //W
        output  [3:0] W_GBUF_FEED_BEG,        //Port(Name=W_GBUF_FEED_BEG,IO=OUTPUT,XOffset=-1,YOffset=0,WireCount=4,Side=W)
        input  [3:0] E_GBUF_END,        //Port(Name=E_GBUF_END,IO=INPUT,XOffset=1,YOffset=0,WireCount=4,Side=W)
    //Tile IO ports from BELs
        input  [FrameBitsPerRow-1:0] FrameData, //CONFIG_PORT
        output  [FrameBitsPerRow-1:0] FrameData_O,
        input  [MaxFramesPerCol-1:0] FrameStrobe, //CONFIG_PORT
        output  [MaxFramesPerCol-1:0] FrameStrobe_O
    //global
);
 //signal declarations
 //BEL ports (e.g., slices)
 //Jump wires
 //internal configuration data signal to daisy-chain all BELs (if any and in the order they are listed in the fabric.csv)
wire[NoConfigBits-1:0] ConfigBits;
wire[NoConfigBits-1:0] ConfigBits_N;

 //Connection for outgoing wires
wire[FrameBitsPerRow-1:0] FrameData_i;
wire[FrameBitsPerRow-1:0] FrameData_O_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_O_i;

assign FrameData_O_i = FrameData_i;

my_buf data_inbuf_0 (
    .A(FrameData[0]),
    .X(FrameData_i[0])
);

my_buf data_inbuf_1 (
    .A(FrameData[1]),
    .X(FrameData_i[1])
);

my_buf data_inbuf_2 (
    .A(FrameData[2]),
    .X(FrameData_i[2])
);

my_buf data_inbuf_3 (
    .A(FrameData[3]),
    .X(FrameData_i[3])
);

my_buf data_inbuf_4 (
    .A(FrameData[4]),
    .X(FrameData_i[4])
);

my_buf data_inbuf_5 (
    .A(FrameData[5]),
    .X(FrameData_i[5])
);

my_buf data_inbuf_6 (
    .A(FrameData[6]),
    .X(FrameData_i[6])
);

my_buf data_inbuf_7 (
    .A(FrameData[7]),
    .X(FrameData_i[7])
);

my_buf data_inbuf_8 (
    .A(FrameData[8]),
    .X(FrameData_i[8])
);

my_buf data_inbuf_9 (
    .A(FrameData[9]),
    .X(FrameData_i[9])
);

my_buf data_inbuf_10 (
    .A(FrameData[10]),
    .X(FrameData_i[10])
);

my_buf data_inbuf_11 (
    .A(FrameData[11]),
    .X(FrameData_i[11])
);

my_buf data_inbuf_12 (
    .A(FrameData[12]),
    .X(FrameData_i[12])
);

my_buf data_inbuf_13 (
    .A(FrameData[13]),
    .X(FrameData_i[13])
);

my_buf data_inbuf_14 (
    .A(FrameData[14]),
    .X(FrameData_i[14])
);

my_buf data_inbuf_15 (
    .A(FrameData[15]),
    .X(FrameData_i[15])
);

my_buf data_inbuf_16 (
    .A(FrameData[16]),
    .X(FrameData_i[16])
);

my_buf data_inbuf_17 (
    .A(FrameData[17]),
    .X(FrameData_i[17])
);

my_buf data_inbuf_18 (
    .A(FrameData[18]),
    .X(FrameData_i[18])
);

my_buf data_inbuf_19 (
    .A(FrameData[19]),
    .X(FrameData_i[19])
);

my_buf data_inbuf_20 (
    .A(FrameData[20]),
    .X(FrameData_i[20])
);

my_buf data_inbuf_21 (
    .A(FrameData[21]),
    .X(FrameData_i[21])
);

my_buf data_inbuf_22 (
    .A(FrameData[22]),
    .X(FrameData_i[22])
);

my_buf data_inbuf_23 (
    .A(FrameData[23]),
    .X(FrameData_i[23])
);

my_buf data_inbuf_24 (
    .A(FrameData[24]),
    .X(FrameData_i[24])
);

my_buf data_inbuf_25 (
    .A(FrameData[25]),
    .X(FrameData_i[25])
);

my_buf data_inbuf_26 (
    .A(FrameData[26]),
    .X(FrameData_i[26])
);

my_buf data_inbuf_27 (
    .A(FrameData[27]),
    .X(FrameData_i[27])
);

my_buf data_inbuf_28 (
    .A(FrameData[28]),
    .X(FrameData_i[28])
);

my_buf data_inbuf_29 (
    .A(FrameData[29]),
    .X(FrameData_i[29])
);

my_buf data_inbuf_30 (
    .A(FrameData[30]),
    .X(FrameData_i[30])
);

my_buf data_inbuf_31 (
    .A(FrameData[31]),
    .X(FrameData_i[31])
);

my_buf data_outbuf_0 (
    .A(FrameData_O_i[0]),
    .X(FrameData_O[0])
);

my_buf data_outbuf_1 (
    .A(FrameData_O_i[1]),
    .X(FrameData_O[1])
);

my_buf data_outbuf_2 (
    .A(FrameData_O_i[2]),
    .X(FrameData_O[2])
);

my_buf data_outbuf_3 (
    .A(FrameData_O_i[3]),
    .X(FrameData_O[3])
);

my_buf data_outbuf_4 (
    .A(FrameData_O_i[4]),
    .X(FrameData_O[4])
);

my_buf data_outbuf_5 (
    .A(FrameData_O_i[5]),
    .X(FrameData_O[5])
);

my_buf data_outbuf_6 (
    .A(FrameData_O_i[6]),
    .X(FrameData_O[6])
);

my_buf data_outbuf_7 (
    .A(FrameData_O_i[7]),
    .X(FrameData_O[7])
);

my_buf data_outbuf_8 (
    .A(FrameData_O_i[8]),
    .X(FrameData_O[8])
);

my_buf data_outbuf_9 (
    .A(FrameData_O_i[9]),
    .X(FrameData_O[9])
);

my_buf data_outbuf_10 (
    .A(FrameData_O_i[10]),
    .X(FrameData_O[10])
);

my_buf data_outbuf_11 (
    .A(FrameData_O_i[11]),
    .X(FrameData_O[11])
);

my_buf data_outbuf_12 (
    .A(FrameData_O_i[12]),
    .X(FrameData_O[12])
);

my_buf data_outbuf_13 (
    .A(FrameData_O_i[13]),
    .X(FrameData_O[13])
);

my_buf data_outbuf_14 (
    .A(FrameData_O_i[14]),
    .X(FrameData_O[14])
);

my_buf data_outbuf_15 (
    .A(FrameData_O_i[15]),
    .X(FrameData_O[15])
);

my_buf data_outbuf_16 (
    .A(FrameData_O_i[16]),
    .X(FrameData_O[16])
);

my_buf data_outbuf_17 (
    .A(FrameData_O_i[17]),
    .X(FrameData_O[17])
);

my_buf data_outbuf_18 (
    .A(FrameData_O_i[18]),
    .X(FrameData_O[18])
);

my_buf data_outbuf_19 (
    .A(FrameData_O_i[19]),
    .X(FrameData_O[19])
);

my_buf data_outbuf_20 (
    .A(FrameData_O_i[20]),
    .X(FrameData_O[20])
);

my_buf data_outbuf_21 (
    .A(FrameData_O_i[21]),
    .X(FrameData_O[21])
);

my_buf data_outbuf_22 (
    .A(FrameData_O_i[22]),
    .X(FrameData_O[22])
);

my_buf data_outbuf_23 (
    .A(FrameData_O_i[23]),
    .X(FrameData_O[23])
);

my_buf data_outbuf_24 (
    .A(FrameData_O_i[24]),
    .X(FrameData_O[24])
);

my_buf data_outbuf_25 (
    .A(FrameData_O_i[25]),
    .X(FrameData_O[25])
);

my_buf data_outbuf_26 (
    .A(FrameData_O_i[26]),
    .X(FrameData_O[26])
);

my_buf data_outbuf_27 (
    .A(FrameData_O_i[27]),
    .X(FrameData_O[27])
);

my_buf data_outbuf_28 (
    .A(FrameData_O_i[28]),
    .X(FrameData_O[28])
);

my_buf data_outbuf_29 (
    .A(FrameData_O_i[29]),
    .X(FrameData_O[29])
);

my_buf data_outbuf_30 (
    .A(FrameData_O_i[30]),
    .X(FrameData_O[30])
);

my_buf data_outbuf_31 (
    .A(FrameData_O_i[31]),
    .X(FrameData_O[31])
);

assign FrameStrobe_O_i = FrameStrobe_i;

my_buf strobe_inbuf_0 (
    .A(FrameStrobe[0]),
    .X(FrameStrobe_i[0])
);

my_buf strobe_inbuf_1 (
    .A(FrameStrobe[1]),
    .X(FrameStrobe_i[1])
);

my_buf strobe_inbuf_2 (
    .A(FrameStrobe[2]),
    .X(FrameStrobe_i[2])
);

my_buf strobe_inbuf_3 (
    .A(FrameStrobe[3]),
    .X(FrameStrobe_i[3])
);

my_buf strobe_inbuf_4 (
    .A(FrameStrobe[4]),
    .X(FrameStrobe_i[4])
);

my_buf strobe_inbuf_5 (
    .A(FrameStrobe[5]),
    .X(FrameStrobe_i[5])
);

my_buf strobe_inbuf_6 (
    .A(FrameStrobe[6]),
    .X(FrameStrobe_i[6])
);

my_buf strobe_inbuf_7 (
    .A(FrameStrobe[7]),
    .X(FrameStrobe_i[7])
);

my_buf strobe_inbuf_8 (
    .A(FrameStrobe[8]),
    .X(FrameStrobe_i[8])
);

my_buf strobe_inbuf_9 (
    .A(FrameStrobe[9]),
    .X(FrameStrobe_i[9])
);

my_buf strobe_inbuf_10 (
    .A(FrameStrobe[10]),
    .X(FrameStrobe_i[10])
);

my_buf strobe_inbuf_11 (
    .A(FrameStrobe[11]),
    .X(FrameStrobe_i[11])
);

my_buf strobe_inbuf_12 (
    .A(FrameStrobe[12]),
    .X(FrameStrobe_i[12])
);

my_buf strobe_inbuf_13 (
    .A(FrameStrobe[13]),
    .X(FrameStrobe_i[13])
);

my_buf strobe_inbuf_14 (
    .A(FrameStrobe[14]),
    .X(FrameStrobe_i[14])
);

my_buf strobe_inbuf_15 (
    .A(FrameStrobe[15]),
    .X(FrameStrobe_i[15])
);

my_buf strobe_inbuf_16 (
    .A(FrameStrobe[16]),
    .X(FrameStrobe_i[16])
);

my_buf strobe_inbuf_17 (
    .A(FrameStrobe[17]),
    .X(FrameStrobe_i[17])
);

my_buf strobe_inbuf_18 (
    .A(FrameStrobe[18]),
    .X(FrameStrobe_i[18])
);

my_buf strobe_inbuf_19 (
    .A(FrameStrobe[19]),
    .X(FrameStrobe_i[19])
);

my_buf strobe_outbuf_0 (
    .A(FrameStrobe_O_i[0]),
    .X(FrameStrobe_O[0])
);

my_buf strobe_outbuf_1 (
    .A(FrameStrobe_O_i[1]),
    .X(FrameStrobe_O[1])
);

my_buf strobe_outbuf_2 (
    .A(FrameStrobe_O_i[2]),
    .X(FrameStrobe_O[2])
);

my_buf strobe_outbuf_3 (
    .A(FrameStrobe_O_i[3]),
    .X(FrameStrobe_O[3])
);

my_buf strobe_outbuf_4 (
    .A(FrameStrobe_O_i[4]),
    .X(FrameStrobe_O[4])
);

my_buf strobe_outbuf_5 (
    .A(FrameStrobe_O_i[5]),
    .X(FrameStrobe_O[5])
);

my_buf strobe_outbuf_6 (
    .A(FrameStrobe_O_i[6]),
    .X(FrameStrobe_O[6])
);

my_buf strobe_outbuf_7 (
    .A(FrameStrobe_O_i[7]),
    .X(FrameStrobe_O[7])
);

my_buf strobe_outbuf_8 (
    .A(FrameStrobe_O_i[8]),
    .X(FrameStrobe_O[8])
);

my_buf strobe_outbuf_9 (
    .A(FrameStrobe_O_i[9]),
    .X(FrameStrobe_O[9])
);

my_buf strobe_outbuf_10 (
    .A(FrameStrobe_O_i[10]),
    .X(FrameStrobe_O[10])
);

my_buf strobe_outbuf_11 (
    .A(FrameStrobe_O_i[11]),
    .X(FrameStrobe_O[11])
);

my_buf strobe_outbuf_12 (
    .A(FrameStrobe_O_i[12]),
    .X(FrameStrobe_O[12])
);

my_buf strobe_outbuf_13 (
    .A(FrameStrobe_O_i[13]),
    .X(FrameStrobe_O[13])
);

my_buf strobe_outbuf_14 (
    .A(FrameStrobe_O_i[14]),
    .X(FrameStrobe_O[14])
);

my_buf strobe_outbuf_15 (
    .A(FrameStrobe_O_i[15]),
    .X(FrameStrobe_O[15])
);

my_buf strobe_outbuf_16 (
    .A(FrameStrobe_O_i[16]),
    .X(FrameStrobe_O[16])
);

my_buf strobe_outbuf_17 (
    .A(FrameStrobe_O_i[17]),
    .X(FrameStrobe_O[17])
);

my_buf strobe_outbuf_18 (
    .A(FrameStrobe_O_i[18]),
    .X(FrameStrobe_O[18])
);

my_buf strobe_outbuf_19 (
    .A(FrameStrobe_O_i[19]),
    .X(FrameStrobe_O[19])
);


 //configuration storage latches
SE_term_ConfigMem
`ifdef EMULATION
    #(
    .Emulate_Bitstream(Emulate_Bitstream)
    )
`endif
    Inst_SE_term_ConfigMem
    (
    .FrameData(FrameData),
    .FrameStrobe(FrameStrobe),
    .ConfigBits(ConfigBits),
    .ConfigBits_N(ConfigBits_N)
);

SE_term_switch_matrix Inst_SE_term_switch_matrix (
    .E_GBUF_END0(E_GBUF_END[0]),
    .E_GBUF_END1(E_GBUF_END[1]),
    .E_GBUF_END2(E_GBUF_END[2]),
    .E_GBUF_END3(E_GBUF_END[3]),
    .W_GBUF_FEED_BEG0(W_GBUF_FEED_BEG[0]),
    .W_GBUF_FEED_BEG1(W_GBUF_FEED_BEG[1]),
    .W_GBUF_FEED_BEG2(W_GBUF_FEED_BEG[2]),
    .W_GBUF_FEED_BEG3(W_GBUF_FEED_BEG[3]),
    .N_GBUF_BEG0(N_GBUF_BEG[0]),
    .N_GBUF_BEG1(N_GBUF_BEG[1]),
    .N_GBUF_BEG2(N_GBUF_BEG[2]),
    .N_GBUF_BEG3(N_GBUF_BEG[3]),
    .ConfigBits(ConfigBits[4-1:0]),
    .ConfigBits_N(ConfigBits_N[4-1:0])
);

endmodule
module S_IO2_ConfigMem
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=84
    )
    (
        input  [FrameBitsPerRow - 1:0] FrameData,
        input  [MaxFramesPerCol - 1:0] FrameStrobe,
        output  [NoConfigBits - 1:0] ConfigBits,
        output  [NoConfigBits - 1:0] ConfigBits_N
    );

`ifdef EMULATION
assign ConfigBits[83] = Emulate_Bitstream[31];
assign ConfigBits[82] = Emulate_Bitstream[30];
assign ConfigBits[81] = Emulate_Bitstream[29];
assign ConfigBits[80] = Emulate_Bitstream[28];
assign ConfigBits[79] = Emulate_Bitstream[27];
assign ConfigBits[78] = Emulate_Bitstream[26];
assign ConfigBits[77] = Emulate_Bitstream[25];
assign ConfigBits[76] = Emulate_Bitstream[24];
assign ConfigBits[75] = Emulate_Bitstream[23];
assign ConfigBits[74] = Emulate_Bitstream[22];
assign ConfigBits[73] = Emulate_Bitstream[21];
assign ConfigBits[72] = Emulate_Bitstream[20];
assign ConfigBits[71] = Emulate_Bitstream[19];
assign ConfigBits[70] = Emulate_Bitstream[18];
assign ConfigBits[69] = Emulate_Bitstream[17];
assign ConfigBits[68] = Emulate_Bitstream[16];
assign ConfigBits[67] = Emulate_Bitstream[15];
assign ConfigBits[66] = Emulate_Bitstream[14];
assign ConfigBits[65] = Emulate_Bitstream[13];
assign ConfigBits[64] = Emulate_Bitstream[12];
assign ConfigBits[63] = Emulate_Bitstream[11];
assign ConfigBits[62] = Emulate_Bitstream[10];
assign ConfigBits[61] = Emulate_Bitstream[9];
assign ConfigBits[60] = Emulate_Bitstream[8];
assign ConfigBits[59] = Emulate_Bitstream[7];
assign ConfigBits[58] = Emulate_Bitstream[6];
assign ConfigBits[57] = Emulate_Bitstream[5];
assign ConfigBits[56] = Emulate_Bitstream[4];
assign ConfigBits[55] = Emulate_Bitstream[3];
assign ConfigBits[54] = Emulate_Bitstream[2];
assign ConfigBits[53] = Emulate_Bitstream[1];
assign ConfigBits[52] = Emulate_Bitstream[0];
assign ConfigBits[51] = Emulate_Bitstream[63];
assign ConfigBits[50] = Emulate_Bitstream[62];
assign ConfigBits[49] = Emulate_Bitstream[61];
assign ConfigBits[48] = Emulate_Bitstream[60];
assign ConfigBits[47] = Emulate_Bitstream[59];
assign ConfigBits[46] = Emulate_Bitstream[58];
assign ConfigBits[45] = Emulate_Bitstream[57];
assign ConfigBits[44] = Emulate_Bitstream[56];
assign ConfigBits[43] = Emulate_Bitstream[55];
assign ConfigBits[42] = Emulate_Bitstream[54];
assign ConfigBits[41] = Emulate_Bitstream[53];
assign ConfigBits[40] = Emulate_Bitstream[52];
assign ConfigBits[39] = Emulate_Bitstream[51];
assign ConfigBits[38] = Emulate_Bitstream[50];
assign ConfigBits[37] = Emulate_Bitstream[49];
assign ConfigBits[36] = Emulate_Bitstream[48];
assign ConfigBits[35] = Emulate_Bitstream[47];
assign ConfigBits[34] = Emulate_Bitstream[46];
assign ConfigBits[33] = Emulate_Bitstream[45];
assign ConfigBits[32] = Emulate_Bitstream[44];
assign ConfigBits[31] = Emulate_Bitstream[43];
assign ConfigBits[30] = Emulate_Bitstream[42];
assign ConfigBits[29] = Emulate_Bitstream[41];
assign ConfigBits[28] = Emulate_Bitstream[40];
assign ConfigBits[27] = Emulate_Bitstream[39];
assign ConfigBits[26] = Emulate_Bitstream[38];
assign ConfigBits[25] = Emulate_Bitstream[37];
assign ConfigBits[24] = Emulate_Bitstream[36];
assign ConfigBits[23] = Emulate_Bitstream[35];
assign ConfigBits[22] = Emulate_Bitstream[34];
assign ConfigBits[21] = Emulate_Bitstream[33];
assign ConfigBits[20] = Emulate_Bitstream[32];
assign ConfigBits[19] = Emulate_Bitstream[95];
assign ConfigBits[18] = Emulate_Bitstream[94];
assign ConfigBits[17] = Emulate_Bitstream[93];
assign ConfigBits[16] = Emulate_Bitstream[92];
assign ConfigBits[15] = Emulate_Bitstream[91];
assign ConfigBits[14] = Emulate_Bitstream[90];
assign ConfigBits[13] = Emulate_Bitstream[89];
assign ConfigBits[12] = Emulate_Bitstream[88];
assign ConfigBits[11] = Emulate_Bitstream[87];
assign ConfigBits[10] = Emulate_Bitstream[86];
assign ConfigBits[9] = Emulate_Bitstream[85];
assign ConfigBits[8] = Emulate_Bitstream[84];
assign ConfigBits[7] = Emulate_Bitstream[83];
assign ConfigBits[6] = Emulate_Bitstream[82];
assign ConfigBits[5] = Emulate_Bitstream[81];
assign ConfigBits[4] = Emulate_Bitstream[80];
assign ConfigBits[3] = Emulate_Bitstream[79];
assign ConfigBits[2] = Emulate_Bitstream[78];
assign ConfigBits[1] = Emulate_Bitstream[77];
assign ConfigBits[0] = Emulate_Bitstream[76];
`else

 //instantiate frame latches
config_latch Inst_frame0_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[83]),
    .QN(ConfigBits_N[83])
);

config_latch Inst_frame0_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[82]),
    .QN(ConfigBits_N[82])
);

config_latch Inst_frame0_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[81]),
    .QN(ConfigBits_N[81])
);

config_latch Inst_frame0_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[80]),
    .QN(ConfigBits_N[80])
);

config_latch Inst_frame0_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[79]),
    .QN(ConfigBits_N[79])
);

config_latch Inst_frame0_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[78]),
    .QN(ConfigBits_N[78])
);

config_latch Inst_frame0_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[77]),
    .QN(ConfigBits_N[77])
);

config_latch Inst_frame0_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[76]),
    .QN(ConfigBits_N[76])
);

config_latch Inst_frame0_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[75]),
    .QN(ConfigBits_N[75])
);

config_latch Inst_frame0_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[74]),
    .QN(ConfigBits_N[74])
);

config_latch Inst_frame0_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[73]),
    .QN(ConfigBits_N[73])
);

config_latch Inst_frame0_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[72]),
    .QN(ConfigBits_N[72])
);

config_latch Inst_frame0_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[71]),
    .QN(ConfigBits_N[71])
);

config_latch Inst_frame0_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[70]),
    .QN(ConfigBits_N[70])
);

config_latch Inst_frame0_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[69]),
    .QN(ConfigBits_N[69])
);

config_latch Inst_frame0_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[68]),
    .QN(ConfigBits_N[68])
);

config_latch Inst_frame0_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[67]),
    .QN(ConfigBits_N[67])
);

config_latch Inst_frame0_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[66]),
    .QN(ConfigBits_N[66])
);

config_latch Inst_frame0_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[65]),
    .QN(ConfigBits_N[65])
);

config_latch Inst_frame0_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[64]),
    .QN(ConfigBits_N[64])
);

config_latch Inst_frame0_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[63]),
    .QN(ConfigBits_N[63])
);

config_latch Inst_frame0_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[62]),
    .QN(ConfigBits_N[62])
);

config_latch Inst_frame0_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[61]),
    .QN(ConfigBits_N[61])
);

config_latch Inst_frame0_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[60]),
    .QN(ConfigBits_N[60])
);

config_latch Inst_frame0_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[59]),
    .QN(ConfigBits_N[59])
);

config_latch Inst_frame0_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[58]),
    .QN(ConfigBits_N[58])
);

config_latch Inst_frame0_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[57]),
    .QN(ConfigBits_N[57])
);

config_latch Inst_frame0_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[56]),
    .QN(ConfigBits_N[56])
);

config_latch Inst_frame0_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[55]),
    .QN(ConfigBits_N[55])
);

config_latch Inst_frame0_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[54]),
    .QN(ConfigBits_N[54])
);

config_latch Inst_frame0_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[53]),
    .QN(ConfigBits_N[53])
);

config_latch Inst_frame0_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[52]),
    .QN(ConfigBits_N[52])
);

config_latch Inst_frame1_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[51]),
    .QN(ConfigBits_N[51])
);

config_latch Inst_frame1_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[50]),
    .QN(ConfigBits_N[50])
);

config_latch Inst_frame1_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[49]),
    .QN(ConfigBits_N[49])
);

config_latch Inst_frame1_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[48]),
    .QN(ConfigBits_N[48])
);

config_latch Inst_frame1_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[47]),
    .QN(ConfigBits_N[47])
);

config_latch Inst_frame1_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[46]),
    .QN(ConfigBits_N[46])
);

config_latch Inst_frame1_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[45]),
    .QN(ConfigBits_N[45])
);

config_latch Inst_frame1_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[44]),
    .QN(ConfigBits_N[44])
);

config_latch Inst_frame1_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[43]),
    .QN(ConfigBits_N[43])
);

config_latch Inst_frame1_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[42]),
    .QN(ConfigBits_N[42])
);

config_latch Inst_frame1_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[41]),
    .QN(ConfigBits_N[41])
);

config_latch Inst_frame1_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[40]),
    .QN(ConfigBits_N[40])
);

config_latch Inst_frame1_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[39]),
    .QN(ConfigBits_N[39])
);

config_latch Inst_frame1_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[38]),
    .QN(ConfigBits_N[38])
);

config_latch Inst_frame1_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[37]),
    .QN(ConfigBits_N[37])
);

config_latch Inst_frame1_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[36]),
    .QN(ConfigBits_N[36])
);

config_latch Inst_frame1_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[35]),
    .QN(ConfigBits_N[35])
);

config_latch Inst_frame1_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[34]),
    .QN(ConfigBits_N[34])
);

config_latch Inst_frame1_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[33]),
    .QN(ConfigBits_N[33])
);

config_latch Inst_frame1_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[32]),
    .QN(ConfigBits_N[32])
);

config_latch Inst_frame1_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[31]),
    .QN(ConfigBits_N[31])
);

config_latch Inst_frame1_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[30]),
    .QN(ConfigBits_N[30])
);

config_latch Inst_frame1_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[29]),
    .QN(ConfigBits_N[29])
);

config_latch Inst_frame1_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[28]),
    .QN(ConfigBits_N[28])
);

config_latch Inst_frame1_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[27]),
    .QN(ConfigBits_N[27])
);

config_latch Inst_frame1_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[26]),
    .QN(ConfigBits_N[26])
);

config_latch Inst_frame1_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[25]),
    .QN(ConfigBits_N[25])
);

config_latch Inst_frame1_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[24]),
    .QN(ConfigBits_N[24])
);

config_latch Inst_frame1_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[23]),
    .QN(ConfigBits_N[23])
);

config_latch Inst_frame1_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[22]),
    .QN(ConfigBits_N[22])
);

config_latch Inst_frame1_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[21]),
    .QN(ConfigBits_N[21])
);

config_latch Inst_frame1_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[20]),
    .QN(ConfigBits_N[20])
);

config_latch Inst_frame2_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[19]),
    .QN(ConfigBits_N[19])
);

config_latch Inst_frame2_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[18]),
    .QN(ConfigBits_N[18])
);

config_latch Inst_frame2_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[17]),
    .QN(ConfigBits_N[17])
);

config_latch Inst_frame2_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[16]),
    .QN(ConfigBits_N[16])
);

config_latch Inst_frame2_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[15]),
    .QN(ConfigBits_N[15])
);

config_latch Inst_frame2_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[14]),
    .QN(ConfigBits_N[14])
);

config_latch Inst_frame2_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[13]),
    .QN(ConfigBits_N[13])
);

config_latch Inst_frame2_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[12]),
    .QN(ConfigBits_N[12])
);

config_latch Inst_frame2_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[11]),
    .QN(ConfigBits_N[11])
);

config_latch Inst_frame2_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[10]),
    .QN(ConfigBits_N[10])
);

config_latch Inst_frame2_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[9]),
    .QN(ConfigBits_N[9])
);

config_latch Inst_frame2_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[8]),
    .QN(ConfigBits_N[8])
);

config_latch Inst_frame2_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[7]),
    .QN(ConfigBits_N[7])
);

config_latch Inst_frame2_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[6]),
    .QN(ConfigBits_N[6])
);

config_latch Inst_frame2_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[5]),
    .QN(ConfigBits_N[5])
);

config_latch Inst_frame2_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[4]),
    .QN(ConfigBits_N[4])
);

config_latch Inst_frame2_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[3]),
    .QN(ConfigBits_N[3])
);

config_latch Inst_frame2_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[2]),
    .QN(ConfigBits_N[2])
);

config_latch Inst_frame2_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[1]),
    .QN(ConfigBits_N[1])
);

config_latch Inst_frame2_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[0]),
    .QN(ConfigBits_N[0])
);

`endif
endmodule
 // NumberOfConfigBits: 78
module S_IO2_switch_matrix
    #(
        parameter NoConfigBits=78
    )
    (
        input  W_GBUF_FEED_END0,
        input  W_GBUF_FEED_END1,
        input  W_GBUF_FEED_END2,
        input  W_GBUF_FEED_END3,
        input  E_GBUF_END0,
        input  E_GBUF_END1,
        input  E_GBUF_END2,
        input  E_GBUF_END3,
        input  S1END0,
        input  S1END1,
        input  S1END2,
        input  S1END3,
        input  S1END4,
        input  S1END5,
        input  S1END6,
        input  S1END7,
        input  S2MID0,
        input  S2MID1,
        input  S2MID2,
        input  S2MID3,
        input  S2MID4,
        input  S2MID5,
        input  S2MID6,
        input  S2MID7,
        input  S2END0,
        input  S2END1,
        input  S2END2,
        input  S2END3,
        input  S2END4,
        input  S2END5,
        input  S2END6,
        input  S2END7,
        input  A_OUT,
        input  B_OUT,
        output  W_GBUF_FEED_BEG0,
        output  W_GBUF_FEED_BEG1,
        output  W_GBUF_FEED_BEG2,
        output  W_GBUF_FEED_BEG3,
        output  N_GBUF_BEG0,
        output  N_GBUF_BEG1,
        output  N_GBUF_BEG2,
        output  N_GBUF_BEG3,
        output  E_GBUF_BEG0,
        output  E_GBUF_BEG1,
        output  E_GBUF_BEG2,
        output  E_GBUF_BEG3,
        output  N1BEG0,
        output  N1BEG1,
        output  N1BEG2,
        output  N1BEG3,
        output  N1BEG4,
        output  N1BEG5,
        output  N1BEG6,
        output  N1BEG7,
        output  N2BEG0,
        output  N2BEG1,
        output  N2BEG2,
        output  N2BEG3,
        output  N2BEG4,
        output  N2BEG5,
        output  N2BEG6,
        output  N2BEG7,
        output  N2BEGb0,
        output  N2BEGb1,
        output  N2BEGb2,
        output  N2BEGb3,
        output  N2BEGb4,
        output  N2BEGb5,
        output  N2BEGb6,
        output  N2BEGb7,
        output  Co0,
        output  A_CLK,
        output  A_IN,
        output  A_EN,
        output  B_CLK,
        output  B_IN,
        output  B_EN,
 //global
        input  [NoConfigBits-1:0] ConfigBits,
        input  [NoConfigBits-1:0] ConfigBits_N
);
parameter GND0 = 1'b0;
parameter GND = 1'b0;
parameter VCC0 = 1'b1;
parameter VCC = 1'b1;
parameter VDD0 = 1'b1;
parameter VDD = 1'b1;

wire[5-1:0] W_GBUF_FEED_BEG0_input;
wire[5-1:0] W_GBUF_FEED_BEG1_input;
wire[5-1:0] W_GBUF_FEED_BEG2_input;
wire[5-1:0] W_GBUF_FEED_BEG3_input;
wire[4-1:0] N1BEG0_input;
wire[4-1:0] N1BEG1_input;
wire[4-1:0] N1BEG2_input;
wire[4-1:0] N1BEG3_input;
wire[4-1:0] N1BEG4_input;
wire[4-1:0] N1BEG5_input;
wire[4-1:0] N1BEG6_input;
wire[4-1:0] N1BEG7_input;
wire[4-1:0] N2BEG0_input;
wire[4-1:0] N2BEG1_input;
wire[4-1:0] N2BEG2_input;
wire[4-1:0] N2BEG3_input;
wire[4-1:0] N2BEG4_input;
wire[4-1:0] N2BEG5_input;
wire[4-1:0] N2BEG6_input;
wire[4-1:0] N2BEG7_input;
wire[4-1:0] N2BEGb0_input;
wire[4-1:0] N2BEGb1_input;
wire[4-1:0] N2BEGb2_input;
wire[4-1:0] N2BEGb3_input;
wire[4-1:0] N2BEGb4_input;
wire[4-1:0] N2BEGb5_input;
wire[4-1:0] N2BEGb6_input;
wire[4-1:0] N2BEGb7_input;
wire[4-1:0] A_CLK_input;
wire[16-1:0] A_IN_input;
wire[8-1:0] A_EN_input;
wire[4-1:0] B_CLK_input;
wire[16-1:0] B_IN_input;
wire[8-1:0] B_EN_input;
 //The configuration bits (if any) are just a long shift register
 //This shift register is padded to an even number of flops/latches
 //switch matrix multiplexer W_GBUF_FEED_BEG0 MUX-5
assign W_GBUF_FEED_BEG0_input = {B_OUT,A_OUT,S2END7,S1END1,W_GBUF_FEED_END0};
cus_mux81 inst_cus_mux81_W_GBUF_FEED_BEG0 (
    .A0(W_GBUF_FEED_BEG0_input[0]),
    .A1(W_GBUF_FEED_BEG0_input[1]),
    .A2(W_GBUF_FEED_BEG0_input[2]),
    .A3(W_GBUF_FEED_BEG0_input[3]),
    .A4(W_GBUF_FEED_BEG0_input[4]),
    .A5(GND0),
    .A6(GND0),
    .A7(GND0),
    .S0(ConfigBits[0+0]),
    .S0N(ConfigBits_N[0+0]),
    .S1(ConfigBits[0+1]),
    .S1N(ConfigBits_N[0+1]),
    .S2(ConfigBits[0+2]),
    .S2N(ConfigBits_N[0+2]),
    .X(W_GBUF_FEED_BEG0)
);

 //switch matrix multiplexer W_GBUF_FEED_BEG1 MUX-5
assign W_GBUF_FEED_BEG1_input = {B_OUT,A_OUT,S2END6,S1END2,W_GBUF_FEED_END1};
cus_mux81 inst_cus_mux81_W_GBUF_FEED_BEG1 (
    .A0(W_GBUF_FEED_BEG1_input[0]),
    .A1(W_GBUF_FEED_BEG1_input[1]),
    .A2(W_GBUF_FEED_BEG1_input[2]),
    .A3(W_GBUF_FEED_BEG1_input[3]),
    .A4(W_GBUF_FEED_BEG1_input[4]),
    .A5(GND0),
    .A6(GND0),
    .A7(GND0),
    .S0(ConfigBits[3+0]),
    .S0N(ConfigBits_N[3+0]),
    .S1(ConfigBits[3+1]),
    .S1N(ConfigBits_N[3+1]),
    .S2(ConfigBits[3+2]),
    .S2N(ConfigBits_N[3+2]),
    .X(W_GBUF_FEED_BEG1)
);

 //switch matrix multiplexer W_GBUF_FEED_BEG2 MUX-5
assign W_GBUF_FEED_BEG2_input = {B_OUT,A_OUT,S2END5,S1END3,W_GBUF_FEED_END2};
cus_mux81 inst_cus_mux81_W_GBUF_FEED_BEG2 (
    .A0(W_GBUF_FEED_BEG2_input[0]),
    .A1(W_GBUF_FEED_BEG2_input[1]),
    .A2(W_GBUF_FEED_BEG2_input[2]),
    .A3(W_GBUF_FEED_BEG2_input[3]),
    .A4(W_GBUF_FEED_BEG2_input[4]),
    .A5(GND0),
    .A6(GND0),
    .A7(GND0),
    .S0(ConfigBits[6+0]),
    .S0N(ConfigBits_N[6+0]),
    .S1(ConfigBits[6+1]),
    .S1N(ConfigBits_N[6+1]),
    .S2(ConfigBits[6+2]),
    .S2N(ConfigBits_N[6+2]),
    .X(W_GBUF_FEED_BEG2)
);

 //switch matrix multiplexer W_GBUF_FEED_BEG3 MUX-5
assign W_GBUF_FEED_BEG3_input = {B_OUT,A_OUT,S2END4,S1END0,W_GBUF_FEED_END3};
cus_mux81 inst_cus_mux81_W_GBUF_FEED_BEG3 (
    .A0(W_GBUF_FEED_BEG3_input[0]),
    .A1(W_GBUF_FEED_BEG3_input[1]),
    .A2(W_GBUF_FEED_BEG3_input[2]),
    .A3(W_GBUF_FEED_BEG3_input[3]),
    .A4(W_GBUF_FEED_BEG3_input[4]),
    .A5(GND0),
    .A6(GND0),
    .A7(GND0),
    .S0(ConfigBits[9+0]),
    .S0N(ConfigBits_N[9+0]),
    .S1(ConfigBits[9+1]),
    .S1N(ConfigBits_N[9+1]),
    .S2(ConfigBits[9+2]),
    .S2N(ConfigBits_N[9+2]),
    .X(W_GBUF_FEED_BEG3)
);

 //switch matrix multiplexer N_GBUF_BEG0 MUX-1
assign N_GBUF_BEG0 = E_GBUF_END0;

 //switch matrix multiplexer N_GBUF_BEG1 MUX-1
assign N_GBUF_BEG1 = E_GBUF_END1;

 //switch matrix multiplexer N_GBUF_BEG2 MUX-1
assign N_GBUF_BEG2 = E_GBUF_END2;

 //switch matrix multiplexer N_GBUF_BEG3 MUX-1
assign N_GBUF_BEG3 = E_GBUF_END3;

 //switch matrix multiplexer E_GBUF_BEG0 MUX-1
assign E_GBUF_BEG0 = E_GBUF_END0;

 //switch matrix multiplexer E_GBUF_BEG1 MUX-1
assign E_GBUF_BEG1 = E_GBUF_END1;

 //switch matrix multiplexer E_GBUF_BEG2 MUX-1
assign E_GBUF_BEG2 = E_GBUF_END2;

 //switch matrix multiplexer E_GBUF_BEG3 MUX-1
assign E_GBUF_BEG3 = E_GBUF_END3;

 //switch matrix multiplexer N1BEG0 MUX-4
assign N1BEG0_input = {A_OUT,S2END7,S2MID7,S1END7};
cus_mux41 inst_cus_mux41_N1BEG0 (
    .A0(N1BEG0_input[0]),
    .A1(N1BEG0_input[1]),
    .A2(N1BEG0_input[2]),
    .A3(N1BEG0_input[3]),
    .S0(ConfigBits[12+0]),
    .S0N(ConfigBits_N[12+0]),
    .S1(ConfigBits[12+1]),
    .S1N(ConfigBits_N[12+1]),
    .X(N1BEG0)
);

 //switch matrix multiplexer N1BEG1 MUX-4
assign N1BEG1_input = {B_OUT,S2END6,S2MID6,S1END6};
cus_mux41 inst_cus_mux41_N1BEG1 (
    .A0(N1BEG1_input[0]),
    .A1(N1BEG1_input[1]),
    .A2(N1BEG1_input[2]),
    .A3(N1BEG1_input[3]),
    .S0(ConfigBits[14+0]),
    .S0N(ConfigBits_N[14+0]),
    .S1(ConfigBits[14+1]),
    .S1N(ConfigBits_N[14+1]),
    .X(N1BEG1)
);

 //switch matrix multiplexer N1BEG2 MUX-4
assign N1BEG2_input = {A_OUT,S2END5,S2MID5,S1END5};
cus_mux41 inst_cus_mux41_N1BEG2 (
    .A0(N1BEG2_input[0]),
    .A1(N1BEG2_input[1]),
    .A2(N1BEG2_input[2]),
    .A3(N1BEG2_input[3]),
    .S0(ConfigBits[16+0]),
    .S0N(ConfigBits_N[16+0]),
    .S1(ConfigBits[16+1]),
    .S1N(ConfigBits_N[16+1]),
    .X(N1BEG2)
);

 //switch matrix multiplexer N1BEG3 MUX-4
assign N1BEG3_input = {B_OUT,S2END4,S2MID4,S1END4};
cus_mux41 inst_cus_mux41_N1BEG3 (
    .A0(N1BEG3_input[0]),
    .A1(N1BEG3_input[1]),
    .A2(N1BEG3_input[2]),
    .A3(N1BEG3_input[3]),
    .S0(ConfigBits[18+0]),
    .S0N(ConfigBits_N[18+0]),
    .S1(ConfigBits[18+1]),
    .S1N(ConfigBits_N[18+1]),
    .X(N1BEG3)
);

 //switch matrix multiplexer N1BEG4 MUX-4
assign N1BEG4_input = {A_OUT,S2END3,S2MID3,S1END3};
cus_mux41 inst_cus_mux41_N1BEG4 (
    .A0(N1BEG4_input[0]),
    .A1(N1BEG4_input[1]),
    .A2(N1BEG4_input[2]),
    .A3(N1BEG4_input[3]),
    .S0(ConfigBits[20+0]),
    .S0N(ConfigBits_N[20+0]),
    .S1(ConfigBits[20+1]),
    .S1N(ConfigBits_N[20+1]),
    .X(N1BEG4)
);

 //switch matrix multiplexer N1BEG5 MUX-4
assign N1BEG5_input = {B_OUT,S2END2,S2MID2,S1END2};
cus_mux41 inst_cus_mux41_N1BEG5 (
    .A0(N1BEG5_input[0]),
    .A1(N1BEG5_input[1]),
    .A2(N1BEG5_input[2]),
    .A3(N1BEG5_input[3]),
    .S0(ConfigBits[22+0]),
    .S0N(ConfigBits_N[22+0]),
    .S1(ConfigBits[22+1]),
    .S1N(ConfigBits_N[22+1]),
    .X(N1BEG5)
);

 //switch matrix multiplexer N1BEG6 MUX-4
assign N1BEG6_input = {A_OUT,S2END1,S2MID1,S1END1};
cus_mux41 inst_cus_mux41_N1BEG6 (
    .A0(N1BEG6_input[0]),
    .A1(N1BEG6_input[1]),
    .A2(N1BEG6_input[2]),
    .A3(N1BEG6_input[3]),
    .S0(ConfigBits[24+0]),
    .S0N(ConfigBits_N[24+0]),
    .S1(ConfigBits[24+1]),
    .S1N(ConfigBits_N[24+1]),
    .X(N1BEG6)
);

 //switch matrix multiplexer N1BEG7 MUX-4
assign N1BEG7_input = {B_OUT,S2END0,S2MID0,S1END0};
cus_mux41 inst_cus_mux41_N1BEG7 (
    .A0(N1BEG7_input[0]),
    .A1(N1BEG7_input[1]),
    .A2(N1BEG7_input[2]),
    .A3(N1BEG7_input[3]),
    .S0(ConfigBits[26+0]),
    .S0N(ConfigBits_N[26+0]),
    .S1(ConfigBits[26+1]),
    .S1N(ConfigBits_N[26+1]),
    .X(N1BEG7)
);

 //switch matrix multiplexer N2BEG0 MUX-4
assign N2BEG0_input = {A_OUT,S2END7,S2MID7,S1END7};
cus_mux41 inst_cus_mux41_N2BEG0 (
    .A0(N2BEG0_input[0]),
    .A1(N2BEG0_input[1]),
    .A2(N2BEG0_input[2]),
    .A3(N2BEG0_input[3]),
    .S0(ConfigBits[28+0]),
    .S0N(ConfigBits_N[28+0]),
    .S1(ConfigBits[28+1]),
    .S1N(ConfigBits_N[28+1]),
    .X(N2BEG0)
);

 //switch matrix multiplexer N2BEG1 MUX-4
assign N2BEG1_input = {B_OUT,S2END6,S2MID6,S1END6};
cus_mux41 inst_cus_mux41_N2BEG1 (
    .A0(N2BEG1_input[0]),
    .A1(N2BEG1_input[1]),
    .A2(N2BEG1_input[2]),
    .A3(N2BEG1_input[3]),
    .S0(ConfigBits[30+0]),
    .S0N(ConfigBits_N[30+0]),
    .S1(ConfigBits[30+1]),
    .S1N(ConfigBits_N[30+1]),
    .X(N2BEG1)
);

 //switch matrix multiplexer N2BEG2 MUX-4
assign N2BEG2_input = {A_OUT,S2END5,S2MID5,S1END5};
cus_mux41 inst_cus_mux41_N2BEG2 (
    .A0(N2BEG2_input[0]),
    .A1(N2BEG2_input[1]),
    .A2(N2BEG2_input[2]),
    .A3(N2BEG2_input[3]),
    .S0(ConfigBits[32+0]),
    .S0N(ConfigBits_N[32+0]),
    .S1(ConfigBits[32+1]),
    .S1N(ConfigBits_N[32+1]),
    .X(N2BEG2)
);

 //switch matrix multiplexer N2BEG3 MUX-4
assign N2BEG3_input = {B_OUT,S2END4,S2MID4,S1END4};
cus_mux41 inst_cus_mux41_N2BEG3 (
    .A0(N2BEG3_input[0]),
    .A1(N2BEG3_input[1]),
    .A2(N2BEG3_input[2]),
    .A3(N2BEG3_input[3]),
    .S0(ConfigBits[34+0]),
    .S0N(ConfigBits_N[34+0]),
    .S1(ConfigBits[34+1]),
    .S1N(ConfigBits_N[34+1]),
    .X(N2BEG3)
);

 //switch matrix multiplexer N2BEG4 MUX-4
assign N2BEG4_input = {A_OUT,S2END3,S2MID3,S1END3};
cus_mux41 inst_cus_mux41_N2BEG4 (
    .A0(N2BEG4_input[0]),
    .A1(N2BEG4_input[1]),
    .A2(N2BEG4_input[2]),
    .A3(N2BEG4_input[3]),
    .S0(ConfigBits[36+0]),
    .S0N(ConfigBits_N[36+0]),
    .S1(ConfigBits[36+1]),
    .S1N(ConfigBits_N[36+1]),
    .X(N2BEG4)
);

 //switch matrix multiplexer N2BEG5 MUX-4
assign N2BEG5_input = {B_OUT,S2END2,S2MID2,S1END2};
cus_mux41 inst_cus_mux41_N2BEG5 (
    .A0(N2BEG5_input[0]),
    .A1(N2BEG5_input[1]),
    .A2(N2BEG5_input[2]),
    .A3(N2BEG5_input[3]),
    .S0(ConfigBits[38+0]),
    .S0N(ConfigBits_N[38+0]),
    .S1(ConfigBits[38+1]),
    .S1N(ConfigBits_N[38+1]),
    .X(N2BEG5)
);

 //switch matrix multiplexer N2BEG6 MUX-4
assign N2BEG6_input = {A_OUT,S2END1,S2MID1,S1END1};
cus_mux41 inst_cus_mux41_N2BEG6 (
    .A0(N2BEG6_input[0]),
    .A1(N2BEG6_input[1]),
    .A2(N2BEG6_input[2]),
    .A3(N2BEG6_input[3]),
    .S0(ConfigBits[40+0]),
    .S0N(ConfigBits_N[40+0]),
    .S1(ConfigBits[40+1]),
    .S1N(ConfigBits_N[40+1]),
    .X(N2BEG6)
);

 //switch matrix multiplexer N2BEG7 MUX-4
assign N2BEG7_input = {B_OUT,S2END0,S2MID0,S1END0};
cus_mux41 inst_cus_mux41_N2BEG7 (
    .A0(N2BEG7_input[0]),
    .A1(N2BEG7_input[1]),
    .A2(N2BEG7_input[2]),
    .A3(N2BEG7_input[3]),
    .S0(ConfigBits[42+0]),
    .S0N(ConfigBits_N[42+0]),
    .S1(ConfigBits[42+1]),
    .S1N(ConfigBits_N[42+1]),
    .X(N2BEG7)
);

 //switch matrix multiplexer N2BEGb0 MUX-4
assign N2BEGb0_input = {B_OUT,S2END7,S2MID7,S1END7};
cus_mux41 inst_cus_mux41_N2BEGb0 (
    .A0(N2BEGb0_input[0]),
    .A1(N2BEGb0_input[1]),
    .A2(N2BEGb0_input[2]),
    .A3(N2BEGb0_input[3]),
    .S0(ConfigBits[44+0]),
    .S0N(ConfigBits_N[44+0]),
    .S1(ConfigBits[44+1]),
    .S1N(ConfigBits_N[44+1]),
    .X(N2BEGb0)
);

 //switch matrix multiplexer N2BEGb1 MUX-4
assign N2BEGb1_input = {A_OUT,S2END6,S2MID6,S1END6};
cus_mux41 inst_cus_mux41_N2BEGb1 (
    .A0(N2BEGb1_input[0]),
    .A1(N2BEGb1_input[1]),
    .A2(N2BEGb1_input[2]),
    .A3(N2BEGb1_input[3]),
    .S0(ConfigBits[46+0]),
    .S0N(ConfigBits_N[46+0]),
    .S1(ConfigBits[46+1]),
    .S1N(ConfigBits_N[46+1]),
    .X(N2BEGb1)
);

 //switch matrix multiplexer N2BEGb2 MUX-4
assign N2BEGb2_input = {B_OUT,S2END5,S2MID5,S1END5};
cus_mux41 inst_cus_mux41_N2BEGb2 (
    .A0(N2BEGb2_input[0]),
    .A1(N2BEGb2_input[1]),
    .A2(N2BEGb2_input[2]),
    .A3(N2BEGb2_input[3]),
    .S0(ConfigBits[48+0]),
    .S0N(ConfigBits_N[48+0]),
    .S1(ConfigBits[48+1]),
    .S1N(ConfigBits_N[48+1]),
    .X(N2BEGb2)
);

 //switch matrix multiplexer N2BEGb3 MUX-4
assign N2BEGb3_input = {A_OUT,S2END4,S2MID4,S1END4};
cus_mux41 inst_cus_mux41_N2BEGb3 (
    .A0(N2BEGb3_input[0]),
    .A1(N2BEGb3_input[1]),
    .A2(N2BEGb3_input[2]),
    .A3(N2BEGb3_input[3]),
    .S0(ConfigBits[50+0]),
    .S0N(ConfigBits_N[50+0]),
    .S1(ConfigBits[50+1]),
    .S1N(ConfigBits_N[50+1]),
    .X(N2BEGb3)
);

 //switch matrix multiplexer N2BEGb4 MUX-4
assign N2BEGb4_input = {B_OUT,S2END3,S2MID3,S1END3};
cus_mux41 inst_cus_mux41_N2BEGb4 (
    .A0(N2BEGb4_input[0]),
    .A1(N2BEGb4_input[1]),
    .A2(N2BEGb4_input[2]),
    .A3(N2BEGb4_input[3]),
    .S0(ConfigBits[52+0]),
    .S0N(ConfigBits_N[52+0]),
    .S1(ConfigBits[52+1]),
    .S1N(ConfigBits_N[52+1]),
    .X(N2BEGb4)
);

 //switch matrix multiplexer N2BEGb5 MUX-4
assign N2BEGb5_input = {A_OUT,S2END2,S2MID2,S1END2};
cus_mux41 inst_cus_mux41_N2BEGb5 (
    .A0(N2BEGb5_input[0]),
    .A1(N2BEGb5_input[1]),
    .A2(N2BEGb5_input[2]),
    .A3(N2BEGb5_input[3]),
    .S0(ConfigBits[54+0]),
    .S0N(ConfigBits_N[54+0]),
    .S1(ConfigBits[54+1]),
    .S1N(ConfigBits_N[54+1]),
    .X(N2BEGb5)
);

 //switch matrix multiplexer N2BEGb6 MUX-4
assign N2BEGb6_input = {B_OUT,S2END1,S2MID1,S1END1};
cus_mux41 inst_cus_mux41_N2BEGb6 (
    .A0(N2BEGb6_input[0]),
    .A1(N2BEGb6_input[1]),
    .A2(N2BEGb6_input[2]),
    .A3(N2BEGb6_input[3]),
    .S0(ConfigBits[56+0]),
    .S0N(ConfigBits_N[56+0]),
    .S1(ConfigBits[56+1]),
    .S1N(ConfigBits_N[56+1]),
    .X(N2BEGb6)
);

 //switch matrix multiplexer N2BEGb7 MUX-4
assign N2BEGb7_input = {A_OUT,S2END0,S2MID0,S1END0};
cus_mux41 inst_cus_mux41_N2BEGb7 (
    .A0(N2BEGb7_input[0]),
    .A1(N2BEGb7_input[1]),
    .A2(N2BEGb7_input[2]),
    .A3(N2BEGb7_input[3]),
    .S0(ConfigBits[58+0]),
    .S0N(ConfigBits_N[58+0]),
    .S1(ConfigBits[58+1]),
    .S1N(ConfigBits_N[58+1]),
    .X(N2BEGb7)
);

 //switch matrix multiplexer Co0 MUX-1
assign Co0 = GND0;

 //switch matrix multiplexer A_CLK MUX-4
assign A_CLK_input = {E_GBUF_END3,E_GBUF_END2,E_GBUF_END1,E_GBUF_END0};
cus_mux41 inst_cus_mux41_A_CLK (
    .A0(A_CLK_input[0]),
    .A1(A_CLK_input[1]),
    .A2(A_CLK_input[2]),
    .A3(A_CLK_input[3]),
    .S0(ConfigBits[60+0]),
    .S0N(ConfigBits_N[60+0]),
    .S1(ConfigBits[60+1]),
    .S1N(ConfigBits_N[60+1]),
    .X(A_CLK)
);

 //switch matrix multiplexer A_IN MUX-16
assign A_IN_input = {VCC0,GND0,S2END7,S2END6,S2END5,S2MID2,S2MID1,S2MID0,S1END7,S1END6,S1END5,S1END4,S1END3,S1END2,S1END1,S1END0};
cus_mux161 inst_cus_mux161_A_IN (
    .A0(A_IN_input[0]),
    .A1(A_IN_input[1]),
    .A2(A_IN_input[2]),
    .A3(A_IN_input[3]),
    .A4(A_IN_input[4]),
    .A5(A_IN_input[5]),
    .A6(A_IN_input[6]),
    .A7(A_IN_input[7]),
    .A8(A_IN_input[8]),
    .A9(A_IN_input[9]),
    .A10(A_IN_input[10]),
    .A11(A_IN_input[11]),
    .A12(A_IN_input[12]),
    .A13(A_IN_input[13]),
    .A14(A_IN_input[14]),
    .A15(A_IN_input[15]),
    .S0(ConfigBits[62+0]),
    .S0N(ConfigBits_N[62+0]),
    .S1(ConfigBits[62+1]),
    .S1N(ConfigBits_N[62+1]),
    .S2(ConfigBits[62+2]),
    .S2N(ConfigBits_N[62+2]),
    .S3(ConfigBits[62+3]),
    .S3N(ConfigBits_N[62+3]),
    .X(A_IN)
);

 //switch matrix multiplexer A_EN MUX-8
assign A_EN_input = {VCC0,GND0,S2END2,S2END0,S2MID7,S2MID4,S1END7,S1END3};
cus_mux81 inst_cus_mux81_A_EN (
    .A0(A_EN_input[0]),
    .A1(A_EN_input[1]),
    .A2(A_EN_input[2]),
    .A3(A_EN_input[3]),
    .A4(A_EN_input[4]),
    .A5(A_EN_input[5]),
    .A6(A_EN_input[6]),
    .A7(A_EN_input[7]),
    .S0(ConfigBits[66+0]),
    .S0N(ConfigBits_N[66+0]),
    .S1(ConfigBits[66+1]),
    .S1N(ConfigBits_N[66+1]),
    .S2(ConfigBits[66+2]),
    .S2N(ConfigBits_N[66+2]),
    .X(A_EN)
);

 //switch matrix multiplexer B_CLK MUX-4
assign B_CLK_input = {E_GBUF_END3,E_GBUF_END2,E_GBUF_END1,E_GBUF_END0};
cus_mux41 inst_cus_mux41_B_CLK (
    .A0(B_CLK_input[0]),
    .A1(B_CLK_input[1]),
    .A2(B_CLK_input[2]),
    .A3(B_CLK_input[3]),
    .S0(ConfigBits[69+0]),
    .S0N(ConfigBits_N[69+0]),
    .S1(ConfigBits[69+1]),
    .S1N(ConfigBits_N[69+1]),
    .X(B_CLK)
);

 //switch matrix multiplexer B_IN MUX-16
assign B_IN_input = {VCC0,GND0,S2END7,S2END6,S2END5,S2MID2,S2MID1,S2MID0,S1END7,S1END6,S1END5,S1END4,S1END3,S1END2,S1END1,S1END0};
cus_mux161 inst_cus_mux161_B_IN (
    .A0(B_IN_input[0]),
    .A1(B_IN_input[1]),
    .A2(B_IN_input[2]),
    .A3(B_IN_input[3]),
    .A4(B_IN_input[4]),
    .A5(B_IN_input[5]),
    .A6(B_IN_input[6]),
    .A7(B_IN_input[7]),
    .A8(B_IN_input[8]),
    .A9(B_IN_input[9]),
    .A10(B_IN_input[10]),
    .A11(B_IN_input[11]),
    .A12(B_IN_input[12]),
    .A13(B_IN_input[13]),
    .A14(B_IN_input[14]),
    .A15(B_IN_input[15]),
    .S0(ConfigBits[71+0]),
    .S0N(ConfigBits_N[71+0]),
    .S1(ConfigBits[71+1]),
    .S1N(ConfigBits_N[71+1]),
    .S2(ConfigBits[71+2]),
    .S2N(ConfigBits_N[71+2]),
    .S3(ConfigBits[71+3]),
    .S3N(ConfigBits_N[71+3]),
    .X(B_IN)
);

 //switch matrix multiplexer B_EN MUX-8
assign B_EN_input = {VCC0,GND0,S2END2,S2END0,S2MID7,S2MID4,S1END7,S1END3};
cus_mux81 inst_cus_mux81_B_EN (
    .A0(B_EN_input[0]),
    .A1(B_EN_input[1]),
    .A2(B_EN_input[2]),
    .A3(B_EN_input[3]),
    .A4(B_EN_input[4]),
    .A5(B_EN_input[5]),
    .A6(B_EN_input[6]),
    .A7(B_EN_input[7]),
    .S0(ConfigBits[75+0]),
    .S0N(ConfigBits_N[75+0]),
    .S1(ConfigBits[75+1]),
    .S1N(ConfigBits_N[75+1]),
    .S2(ConfigBits[75+2]),
    .S2N(ConfigBits_N[75+2]),
    .X(B_EN)
);

endmodule
module S_IO2
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=84
    )
    (
 //N
        output  [3:0] N_GBUF_BEG,        //Port(Name=N_GBUF_BEG,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=4,Side=N)
        output  [7:0] N1BEG,        //Port(Name=N1BEG,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=8,Side=N)
        output  [7:0] N2BEG,        //Port(Name=N2BEG,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=8,Side=N)
        output  [7:0] N2BEGb,        //Port(Name=N2BEGb,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=8,Side=N)
        input  [7:0] S1END,        //Port(Name=S1END,IO=INPUT,XOffset=0,YOffset=1,WireCount=8,Side=N)
        input  [7:0] S2MID,        //Port(Name=S2MID,IO=INPUT,XOffset=0,YOffset=1,WireCount=8,Side=N)
        input  [7:0] S2END,        //Port(Name=S2END,IO=INPUT,XOffset=0,YOffset=1,WireCount=8,Side=N)
        output  [0:0] Co,        //Port(Name=Co,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=1,Side=N)
 //E
        input  [3:0] W_GBUF_FEED_END,        //Port(Name=W_GBUF_FEED_END,IO=INPUT,XOffset=-1,YOffset=0,WireCount=4,Side=E)
        output  [3:0] E_GBUF_BEG,        //Port(Name=E_GBUF_BEG,IO=OUTPUT,XOffset=1,YOffset=0,WireCount=4,Side=E)
 //W
        output  [3:0] W_GBUF_FEED_BEG,        //Port(Name=W_GBUF_FEED_BEG,IO=OUTPUT,XOffset=-1,YOffset=0,WireCount=4,Side=W)
        input  [3:0] E_GBUF_END,        //Port(Name=E_GBUF_END,IO=INPUT,XOffset=1,YOffset=0,WireCount=4,Side=W)
        input  A_OUT_top,
        output  A_IN_top,
        output  A_EN_top,
        input  B_OUT_top,
        output  B_IN_top,
        output  B_EN_top,
    //Tile IO ports from BELs
        input  [FrameBitsPerRow-1:0] FrameData, //CONFIG_PORT
        output  [FrameBitsPerRow-1:0] FrameData_O,
        input  [MaxFramesPerCol-1:0] FrameStrobe, //CONFIG_PORT
        output  [MaxFramesPerCol-1:0] FrameStrobe_O
    //global
);
 //signal declarations
 //BEL ports (e.g., slices)
wire A_CLK;
wire A_IN;
wire A_EN;
wire A_OUT;
wire B_CLK;
wire B_IN;
wire B_EN;
wire B_OUT;
 //Jump wires
 //internal configuration data signal to daisy-chain all BELs (if any and in the order they are listed in the fabric.csv)
wire[NoConfigBits-1:0] ConfigBits;
wire[NoConfigBits-1:0] ConfigBits_N;

 //Connection for outgoing wires
wire[FrameBitsPerRow-1:0] FrameData_i;
wire[FrameBitsPerRow-1:0] FrameData_O_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_O_i;

assign FrameData_O_i = FrameData_i;

my_buf data_inbuf_0 (
    .A(FrameData[0]),
    .X(FrameData_i[0])
);

my_buf data_inbuf_1 (
    .A(FrameData[1]),
    .X(FrameData_i[1])
);

my_buf data_inbuf_2 (
    .A(FrameData[2]),
    .X(FrameData_i[2])
);

my_buf data_inbuf_3 (
    .A(FrameData[3]),
    .X(FrameData_i[3])
);

my_buf data_inbuf_4 (
    .A(FrameData[4]),
    .X(FrameData_i[4])
);

my_buf data_inbuf_5 (
    .A(FrameData[5]),
    .X(FrameData_i[5])
);

my_buf data_inbuf_6 (
    .A(FrameData[6]),
    .X(FrameData_i[6])
);

my_buf data_inbuf_7 (
    .A(FrameData[7]),
    .X(FrameData_i[7])
);

my_buf data_inbuf_8 (
    .A(FrameData[8]),
    .X(FrameData_i[8])
);

my_buf data_inbuf_9 (
    .A(FrameData[9]),
    .X(FrameData_i[9])
);

my_buf data_inbuf_10 (
    .A(FrameData[10]),
    .X(FrameData_i[10])
);

my_buf data_inbuf_11 (
    .A(FrameData[11]),
    .X(FrameData_i[11])
);

my_buf data_inbuf_12 (
    .A(FrameData[12]),
    .X(FrameData_i[12])
);

my_buf data_inbuf_13 (
    .A(FrameData[13]),
    .X(FrameData_i[13])
);

my_buf data_inbuf_14 (
    .A(FrameData[14]),
    .X(FrameData_i[14])
);

my_buf data_inbuf_15 (
    .A(FrameData[15]),
    .X(FrameData_i[15])
);

my_buf data_inbuf_16 (
    .A(FrameData[16]),
    .X(FrameData_i[16])
);

my_buf data_inbuf_17 (
    .A(FrameData[17]),
    .X(FrameData_i[17])
);

my_buf data_inbuf_18 (
    .A(FrameData[18]),
    .X(FrameData_i[18])
);

my_buf data_inbuf_19 (
    .A(FrameData[19]),
    .X(FrameData_i[19])
);

my_buf data_inbuf_20 (
    .A(FrameData[20]),
    .X(FrameData_i[20])
);

my_buf data_inbuf_21 (
    .A(FrameData[21]),
    .X(FrameData_i[21])
);

my_buf data_inbuf_22 (
    .A(FrameData[22]),
    .X(FrameData_i[22])
);

my_buf data_inbuf_23 (
    .A(FrameData[23]),
    .X(FrameData_i[23])
);

my_buf data_inbuf_24 (
    .A(FrameData[24]),
    .X(FrameData_i[24])
);

my_buf data_inbuf_25 (
    .A(FrameData[25]),
    .X(FrameData_i[25])
);

my_buf data_inbuf_26 (
    .A(FrameData[26]),
    .X(FrameData_i[26])
);

my_buf data_inbuf_27 (
    .A(FrameData[27]),
    .X(FrameData_i[27])
);

my_buf data_inbuf_28 (
    .A(FrameData[28]),
    .X(FrameData_i[28])
);

my_buf data_inbuf_29 (
    .A(FrameData[29]),
    .X(FrameData_i[29])
);

my_buf data_inbuf_30 (
    .A(FrameData[30]),
    .X(FrameData_i[30])
);

my_buf data_inbuf_31 (
    .A(FrameData[31]),
    .X(FrameData_i[31])
);

my_buf data_outbuf_0 (
    .A(FrameData_O_i[0]),
    .X(FrameData_O[0])
);

my_buf data_outbuf_1 (
    .A(FrameData_O_i[1]),
    .X(FrameData_O[1])
);

my_buf data_outbuf_2 (
    .A(FrameData_O_i[2]),
    .X(FrameData_O[2])
);

my_buf data_outbuf_3 (
    .A(FrameData_O_i[3]),
    .X(FrameData_O[3])
);

my_buf data_outbuf_4 (
    .A(FrameData_O_i[4]),
    .X(FrameData_O[4])
);

my_buf data_outbuf_5 (
    .A(FrameData_O_i[5]),
    .X(FrameData_O[5])
);

my_buf data_outbuf_6 (
    .A(FrameData_O_i[6]),
    .X(FrameData_O[6])
);

my_buf data_outbuf_7 (
    .A(FrameData_O_i[7]),
    .X(FrameData_O[7])
);

my_buf data_outbuf_8 (
    .A(FrameData_O_i[8]),
    .X(FrameData_O[8])
);

my_buf data_outbuf_9 (
    .A(FrameData_O_i[9]),
    .X(FrameData_O[9])
);

my_buf data_outbuf_10 (
    .A(FrameData_O_i[10]),
    .X(FrameData_O[10])
);

my_buf data_outbuf_11 (
    .A(FrameData_O_i[11]),
    .X(FrameData_O[11])
);

my_buf data_outbuf_12 (
    .A(FrameData_O_i[12]),
    .X(FrameData_O[12])
);

my_buf data_outbuf_13 (
    .A(FrameData_O_i[13]),
    .X(FrameData_O[13])
);

my_buf data_outbuf_14 (
    .A(FrameData_O_i[14]),
    .X(FrameData_O[14])
);

my_buf data_outbuf_15 (
    .A(FrameData_O_i[15]),
    .X(FrameData_O[15])
);

my_buf data_outbuf_16 (
    .A(FrameData_O_i[16]),
    .X(FrameData_O[16])
);

my_buf data_outbuf_17 (
    .A(FrameData_O_i[17]),
    .X(FrameData_O[17])
);

my_buf data_outbuf_18 (
    .A(FrameData_O_i[18]),
    .X(FrameData_O[18])
);

my_buf data_outbuf_19 (
    .A(FrameData_O_i[19]),
    .X(FrameData_O[19])
);

my_buf data_outbuf_20 (
    .A(FrameData_O_i[20]),
    .X(FrameData_O[20])
);

my_buf data_outbuf_21 (
    .A(FrameData_O_i[21]),
    .X(FrameData_O[21])
);

my_buf data_outbuf_22 (
    .A(FrameData_O_i[22]),
    .X(FrameData_O[22])
);

my_buf data_outbuf_23 (
    .A(FrameData_O_i[23]),
    .X(FrameData_O[23])
);

my_buf data_outbuf_24 (
    .A(FrameData_O_i[24]),
    .X(FrameData_O[24])
);

my_buf data_outbuf_25 (
    .A(FrameData_O_i[25]),
    .X(FrameData_O[25])
);

my_buf data_outbuf_26 (
    .A(FrameData_O_i[26]),
    .X(FrameData_O[26])
);

my_buf data_outbuf_27 (
    .A(FrameData_O_i[27]),
    .X(FrameData_O[27])
);

my_buf data_outbuf_28 (
    .A(FrameData_O_i[28]),
    .X(FrameData_O[28])
);

my_buf data_outbuf_29 (
    .A(FrameData_O_i[29]),
    .X(FrameData_O[29])
);

my_buf data_outbuf_30 (
    .A(FrameData_O_i[30]),
    .X(FrameData_O[30])
);

my_buf data_outbuf_31 (
    .A(FrameData_O_i[31]),
    .X(FrameData_O[31])
);

assign FrameStrobe_O_i = FrameStrobe_i;

my_buf strobe_inbuf_0 (
    .A(FrameStrobe[0]),
    .X(FrameStrobe_i[0])
);

my_buf strobe_inbuf_1 (
    .A(FrameStrobe[1]),
    .X(FrameStrobe_i[1])
);

my_buf strobe_inbuf_2 (
    .A(FrameStrobe[2]),
    .X(FrameStrobe_i[2])
);

my_buf strobe_inbuf_3 (
    .A(FrameStrobe[3]),
    .X(FrameStrobe_i[3])
);

my_buf strobe_inbuf_4 (
    .A(FrameStrobe[4]),
    .X(FrameStrobe_i[4])
);

my_buf strobe_inbuf_5 (
    .A(FrameStrobe[5]),
    .X(FrameStrobe_i[5])
);

my_buf strobe_inbuf_6 (
    .A(FrameStrobe[6]),
    .X(FrameStrobe_i[6])
);

my_buf strobe_inbuf_7 (
    .A(FrameStrobe[7]),
    .X(FrameStrobe_i[7])
);

my_buf strobe_inbuf_8 (
    .A(FrameStrobe[8]),
    .X(FrameStrobe_i[8])
);

my_buf strobe_inbuf_9 (
    .A(FrameStrobe[9]),
    .X(FrameStrobe_i[9])
);

my_buf strobe_inbuf_10 (
    .A(FrameStrobe[10]),
    .X(FrameStrobe_i[10])
);

my_buf strobe_inbuf_11 (
    .A(FrameStrobe[11]),
    .X(FrameStrobe_i[11])
);

my_buf strobe_inbuf_12 (
    .A(FrameStrobe[12]),
    .X(FrameStrobe_i[12])
);

my_buf strobe_inbuf_13 (
    .A(FrameStrobe[13]),
    .X(FrameStrobe_i[13])
);

my_buf strobe_inbuf_14 (
    .A(FrameStrobe[14]),
    .X(FrameStrobe_i[14])
);

my_buf strobe_inbuf_15 (
    .A(FrameStrobe[15]),
    .X(FrameStrobe_i[15])
);

my_buf strobe_inbuf_16 (
    .A(FrameStrobe[16]),
    .X(FrameStrobe_i[16])
);

my_buf strobe_inbuf_17 (
    .A(FrameStrobe[17]),
    .X(FrameStrobe_i[17])
);

my_buf strobe_inbuf_18 (
    .A(FrameStrobe[18]),
    .X(FrameStrobe_i[18])
);

my_buf strobe_inbuf_19 (
    .A(FrameStrobe[19]),
    .X(FrameStrobe_i[19])
);

my_buf strobe_outbuf_0 (
    .A(FrameStrobe_O_i[0]),
    .X(FrameStrobe_O[0])
);

my_buf strobe_outbuf_1 (
    .A(FrameStrobe_O_i[1]),
    .X(FrameStrobe_O[1])
);

my_buf strobe_outbuf_2 (
    .A(FrameStrobe_O_i[2]),
    .X(FrameStrobe_O[2])
);

my_buf strobe_outbuf_3 (
    .A(FrameStrobe_O_i[3]),
    .X(FrameStrobe_O[3])
);

my_buf strobe_outbuf_4 (
    .A(FrameStrobe_O_i[4]),
    .X(FrameStrobe_O[4])
);

my_buf strobe_outbuf_5 (
    .A(FrameStrobe_O_i[5]),
    .X(FrameStrobe_O[5])
);

my_buf strobe_outbuf_6 (
    .A(FrameStrobe_O_i[6]),
    .X(FrameStrobe_O[6])
);

my_buf strobe_outbuf_7 (
    .A(FrameStrobe_O_i[7]),
    .X(FrameStrobe_O[7])
);

my_buf strobe_outbuf_8 (
    .A(FrameStrobe_O_i[8]),
    .X(FrameStrobe_O[8])
);

my_buf strobe_outbuf_9 (
    .A(FrameStrobe_O_i[9]),
    .X(FrameStrobe_O[9])
);

my_buf strobe_outbuf_10 (
    .A(FrameStrobe_O_i[10]),
    .X(FrameStrobe_O[10])
);

my_buf strobe_outbuf_11 (
    .A(FrameStrobe_O_i[11]),
    .X(FrameStrobe_O[11])
);

my_buf strobe_outbuf_12 (
    .A(FrameStrobe_O_i[12]),
    .X(FrameStrobe_O[12])
);

my_buf strobe_outbuf_13 (
    .A(FrameStrobe_O_i[13]),
    .X(FrameStrobe_O[13])
);

my_buf strobe_outbuf_14 (
    .A(FrameStrobe_O_i[14]),
    .X(FrameStrobe_O[14])
);

my_buf strobe_outbuf_15 (
    .A(FrameStrobe_O_i[15]),
    .X(FrameStrobe_O[15])
);

my_buf strobe_outbuf_16 (
    .A(FrameStrobe_O_i[16]),
    .X(FrameStrobe_O[16])
);

my_buf strobe_outbuf_17 (
    .A(FrameStrobe_O_i[17]),
    .X(FrameStrobe_O[17])
);

my_buf strobe_outbuf_18 (
    .A(FrameStrobe_O_i[18]),
    .X(FrameStrobe_O[18])
);

my_buf strobe_outbuf_19 (
    .A(FrameStrobe_O_i[19]),
    .X(FrameStrobe_O[19])
);


 //configuration storage latches
S_IO2_ConfigMem
`ifdef EMULATION
    #(
    .Emulate_Bitstream(Emulate_Bitstream)
    )
`endif
    Inst_S_IO2_ConfigMem
    (
    .FrameData(FrameData),
    .FrameStrobe(FrameStrobe),
    .ConfigBits(ConfigBits),
    .ConfigBits_N(ConfigBits_N)
);


 //BEL component instantiations
IOBUF Inst_A_IOBUF (
    .CLK(A_CLK),
    .IN(A_IN),
    .EN(A_EN),
    .OUT(A_OUT),
    .IN_top(A_IN_top),
    .EN_top(A_EN_top),
    .OUT_top(A_OUT_top),
    .ConfigBits(ConfigBits[3-1:0])
);

IOBUF Inst_B_IOBUF (
    .CLK(B_CLK),
    .IN(B_IN),
    .EN(B_EN),
    .OUT(B_OUT),
    .IN_top(B_IN_top),
    .EN_top(B_EN_top),
    .OUT_top(B_OUT_top),
    .ConfigBits(ConfigBits[6-1:3])
);

S_IO2_switch_matrix Inst_S_IO2_switch_matrix (
    .W_GBUF_FEED_END0(W_GBUF_FEED_END[0]),
    .W_GBUF_FEED_END1(W_GBUF_FEED_END[1]),
    .W_GBUF_FEED_END2(W_GBUF_FEED_END[2]),
    .W_GBUF_FEED_END3(W_GBUF_FEED_END[3]),
    .E_GBUF_END0(E_GBUF_END[0]),
    .E_GBUF_END1(E_GBUF_END[1]),
    .E_GBUF_END2(E_GBUF_END[2]),
    .E_GBUF_END3(E_GBUF_END[3]),
    .S1END0(S1END[0]),
    .S1END1(S1END[1]),
    .S1END2(S1END[2]),
    .S1END3(S1END[3]),
    .S1END4(S1END[4]),
    .S1END5(S1END[5]),
    .S1END6(S1END[6]),
    .S1END7(S1END[7]),
    .S2MID0(S2MID[0]),
    .S2MID1(S2MID[1]),
    .S2MID2(S2MID[2]),
    .S2MID3(S2MID[3]),
    .S2MID4(S2MID[4]),
    .S2MID5(S2MID[5]),
    .S2MID6(S2MID[6]),
    .S2MID7(S2MID[7]),
    .S2END0(S2END[0]),
    .S2END1(S2END[1]),
    .S2END2(S2END[2]),
    .S2END3(S2END[3]),
    .S2END4(S2END[4]),
    .S2END5(S2END[5]),
    .S2END6(S2END[6]),
    .S2END7(S2END[7]),
    .A_OUT(A_OUT),
    .B_OUT(B_OUT),
    .W_GBUF_FEED_BEG0(W_GBUF_FEED_BEG[0]),
    .W_GBUF_FEED_BEG1(W_GBUF_FEED_BEG[1]),
    .W_GBUF_FEED_BEG2(W_GBUF_FEED_BEG[2]),
    .W_GBUF_FEED_BEG3(W_GBUF_FEED_BEG[3]),
    .N_GBUF_BEG0(N_GBUF_BEG[0]),
    .N_GBUF_BEG1(N_GBUF_BEG[1]),
    .N_GBUF_BEG2(N_GBUF_BEG[2]),
    .N_GBUF_BEG3(N_GBUF_BEG[3]),
    .E_GBUF_BEG0(E_GBUF_BEG[0]),
    .E_GBUF_BEG1(E_GBUF_BEG[1]),
    .E_GBUF_BEG2(E_GBUF_BEG[2]),
    .E_GBUF_BEG3(E_GBUF_BEG[3]),
    .N1BEG0(N1BEG[0]),
    .N1BEG1(N1BEG[1]),
    .N1BEG2(N1BEG[2]),
    .N1BEG3(N1BEG[3]),
    .N1BEG4(N1BEG[4]),
    .N1BEG5(N1BEG[5]),
    .N1BEG6(N1BEG[6]),
    .N1BEG7(N1BEG[7]),
    .N2BEG0(N2BEG[0]),
    .N2BEG1(N2BEG[1]),
    .N2BEG2(N2BEG[2]),
    .N2BEG3(N2BEG[3]),
    .N2BEG4(N2BEG[4]),
    .N2BEG5(N2BEG[5]),
    .N2BEG6(N2BEG[6]),
    .N2BEG7(N2BEG[7]),
    .N2BEGb0(N2BEGb[0]),
    .N2BEGb1(N2BEGb[1]),
    .N2BEGb2(N2BEGb[2]),
    .N2BEGb3(N2BEGb[3]),
    .N2BEGb4(N2BEGb[4]),
    .N2BEGb5(N2BEGb[5]),
    .N2BEGb6(N2BEGb[6]),
    .N2BEGb7(N2BEGb[7]),
    .Co0(Co[0]),
    .A_CLK(A_CLK),
    .A_IN(A_IN),
    .A_EN(A_EN),
    .B_CLK(B_CLK),
    .B_IN(B_IN),
    .B_EN(B_EN),
    .ConfigBits(ConfigBits[84-1:6]),
    .ConfigBits_N(ConfigBits_N[84-1:6])
);

endmodule
module S_IO4_ConfigMem
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=108
    )
    (
        input  [FrameBitsPerRow - 1:0] FrameData,
        input  [MaxFramesPerCol - 1:0] FrameStrobe,
        output  [NoConfigBits - 1:0] ConfigBits,
        output  [NoConfigBits - 1:0] ConfigBits_N
    );

`ifdef EMULATION
assign ConfigBits[107] = Emulate_Bitstream[31];
assign ConfigBits[106] = Emulate_Bitstream[30];
assign ConfigBits[105] = Emulate_Bitstream[29];
assign ConfigBits[104] = Emulate_Bitstream[28];
assign ConfigBits[103] = Emulate_Bitstream[27];
assign ConfigBits[102] = Emulate_Bitstream[26];
assign ConfigBits[101] = Emulate_Bitstream[25];
assign ConfigBits[100] = Emulate_Bitstream[24];
assign ConfigBits[99] = Emulate_Bitstream[23];
assign ConfigBits[98] = Emulate_Bitstream[22];
assign ConfigBits[97] = Emulate_Bitstream[21];
assign ConfigBits[96] = Emulate_Bitstream[20];
assign ConfigBits[95] = Emulate_Bitstream[19];
assign ConfigBits[94] = Emulate_Bitstream[18];
assign ConfigBits[93] = Emulate_Bitstream[17];
assign ConfigBits[92] = Emulate_Bitstream[16];
assign ConfigBits[91] = Emulate_Bitstream[15];
assign ConfigBits[90] = Emulate_Bitstream[14];
assign ConfigBits[89] = Emulate_Bitstream[13];
assign ConfigBits[88] = Emulate_Bitstream[12];
assign ConfigBits[87] = Emulate_Bitstream[11];
assign ConfigBits[86] = Emulate_Bitstream[10];
assign ConfigBits[85] = Emulate_Bitstream[9];
assign ConfigBits[84] = Emulate_Bitstream[8];
assign ConfigBits[83] = Emulate_Bitstream[7];
assign ConfigBits[82] = Emulate_Bitstream[6];
assign ConfigBits[81] = Emulate_Bitstream[5];
assign ConfigBits[80] = Emulate_Bitstream[4];
assign ConfigBits[79] = Emulate_Bitstream[3];
assign ConfigBits[78] = Emulate_Bitstream[2];
assign ConfigBits[77] = Emulate_Bitstream[1];
assign ConfigBits[76] = Emulate_Bitstream[0];
assign ConfigBits[75] = Emulate_Bitstream[63];
assign ConfigBits[74] = Emulate_Bitstream[62];
assign ConfigBits[73] = Emulate_Bitstream[61];
assign ConfigBits[72] = Emulate_Bitstream[60];
assign ConfigBits[71] = Emulate_Bitstream[59];
assign ConfigBits[70] = Emulate_Bitstream[58];
assign ConfigBits[69] = Emulate_Bitstream[57];
assign ConfigBits[68] = Emulate_Bitstream[56];
assign ConfigBits[67] = Emulate_Bitstream[55];
assign ConfigBits[66] = Emulate_Bitstream[54];
assign ConfigBits[65] = Emulate_Bitstream[53];
assign ConfigBits[64] = Emulate_Bitstream[52];
assign ConfigBits[63] = Emulate_Bitstream[51];
assign ConfigBits[62] = Emulate_Bitstream[50];
assign ConfigBits[61] = Emulate_Bitstream[49];
assign ConfigBits[60] = Emulate_Bitstream[48];
assign ConfigBits[59] = Emulate_Bitstream[47];
assign ConfigBits[58] = Emulate_Bitstream[46];
assign ConfigBits[57] = Emulate_Bitstream[45];
assign ConfigBits[56] = Emulate_Bitstream[44];
assign ConfigBits[55] = Emulate_Bitstream[43];
assign ConfigBits[54] = Emulate_Bitstream[42];
assign ConfigBits[53] = Emulate_Bitstream[41];
assign ConfigBits[52] = Emulate_Bitstream[40];
assign ConfigBits[51] = Emulate_Bitstream[39];
assign ConfigBits[50] = Emulate_Bitstream[38];
assign ConfigBits[49] = Emulate_Bitstream[37];
assign ConfigBits[48] = Emulate_Bitstream[36];
assign ConfigBits[47] = Emulate_Bitstream[35];
assign ConfigBits[46] = Emulate_Bitstream[34];
assign ConfigBits[45] = Emulate_Bitstream[33];
assign ConfigBits[44] = Emulate_Bitstream[32];
assign ConfigBits[43] = Emulate_Bitstream[95];
assign ConfigBits[42] = Emulate_Bitstream[94];
assign ConfigBits[41] = Emulate_Bitstream[93];
assign ConfigBits[40] = Emulate_Bitstream[92];
assign ConfigBits[39] = Emulate_Bitstream[91];
assign ConfigBits[38] = Emulate_Bitstream[90];
assign ConfigBits[37] = Emulate_Bitstream[89];
assign ConfigBits[36] = Emulate_Bitstream[88];
assign ConfigBits[35] = Emulate_Bitstream[87];
assign ConfigBits[34] = Emulate_Bitstream[86];
assign ConfigBits[33] = Emulate_Bitstream[85];
assign ConfigBits[32] = Emulate_Bitstream[84];
assign ConfigBits[31] = Emulate_Bitstream[83];
assign ConfigBits[30] = Emulate_Bitstream[82];
assign ConfigBits[29] = Emulate_Bitstream[81];
assign ConfigBits[28] = Emulate_Bitstream[80];
assign ConfigBits[27] = Emulate_Bitstream[79];
assign ConfigBits[26] = Emulate_Bitstream[78];
assign ConfigBits[25] = Emulate_Bitstream[77];
assign ConfigBits[24] = Emulate_Bitstream[76];
assign ConfigBits[23] = Emulate_Bitstream[75];
assign ConfigBits[22] = Emulate_Bitstream[74];
assign ConfigBits[21] = Emulate_Bitstream[73];
assign ConfigBits[20] = Emulate_Bitstream[72];
assign ConfigBits[19] = Emulate_Bitstream[71];
assign ConfigBits[18] = Emulate_Bitstream[70];
assign ConfigBits[17] = Emulate_Bitstream[69];
assign ConfigBits[16] = Emulate_Bitstream[68];
assign ConfigBits[15] = Emulate_Bitstream[67];
assign ConfigBits[14] = Emulate_Bitstream[66];
assign ConfigBits[13] = Emulate_Bitstream[65];
assign ConfigBits[12] = Emulate_Bitstream[64];
assign ConfigBits[11] = Emulate_Bitstream[127];
assign ConfigBits[10] = Emulate_Bitstream[126];
assign ConfigBits[9] = Emulate_Bitstream[125];
assign ConfigBits[8] = Emulate_Bitstream[124];
assign ConfigBits[7] = Emulate_Bitstream[123];
assign ConfigBits[6] = Emulate_Bitstream[122];
assign ConfigBits[5] = Emulate_Bitstream[121];
assign ConfigBits[4] = Emulate_Bitstream[120];
assign ConfigBits[3] = Emulate_Bitstream[119];
assign ConfigBits[2] = Emulate_Bitstream[118];
assign ConfigBits[1] = Emulate_Bitstream[117];
assign ConfigBits[0] = Emulate_Bitstream[116];
`else

 //instantiate frame latches
config_latch Inst_frame0_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[107]),
    .QN(ConfigBits_N[107])
);

config_latch Inst_frame0_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[106]),
    .QN(ConfigBits_N[106])
);

config_latch Inst_frame0_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[105]),
    .QN(ConfigBits_N[105])
);

config_latch Inst_frame0_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[104]),
    .QN(ConfigBits_N[104])
);

config_latch Inst_frame0_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[103]),
    .QN(ConfigBits_N[103])
);

config_latch Inst_frame0_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[102]),
    .QN(ConfigBits_N[102])
);

config_latch Inst_frame0_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[101]),
    .QN(ConfigBits_N[101])
);

config_latch Inst_frame0_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[100]),
    .QN(ConfigBits_N[100])
);

config_latch Inst_frame0_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[99]),
    .QN(ConfigBits_N[99])
);

config_latch Inst_frame0_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[98]),
    .QN(ConfigBits_N[98])
);

config_latch Inst_frame0_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[97]),
    .QN(ConfigBits_N[97])
);

config_latch Inst_frame0_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[96]),
    .QN(ConfigBits_N[96])
);

config_latch Inst_frame0_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[95]),
    .QN(ConfigBits_N[95])
);

config_latch Inst_frame0_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[94]),
    .QN(ConfigBits_N[94])
);

config_latch Inst_frame0_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[93]),
    .QN(ConfigBits_N[93])
);

config_latch Inst_frame0_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[92]),
    .QN(ConfigBits_N[92])
);

config_latch Inst_frame0_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[91]),
    .QN(ConfigBits_N[91])
);

config_latch Inst_frame0_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[90]),
    .QN(ConfigBits_N[90])
);

config_latch Inst_frame0_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[89]),
    .QN(ConfigBits_N[89])
);

config_latch Inst_frame0_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[88]),
    .QN(ConfigBits_N[88])
);

config_latch Inst_frame0_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[87]),
    .QN(ConfigBits_N[87])
);

config_latch Inst_frame0_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[86]),
    .QN(ConfigBits_N[86])
);

config_latch Inst_frame0_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[85]),
    .QN(ConfigBits_N[85])
);

config_latch Inst_frame0_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[84]),
    .QN(ConfigBits_N[84])
);

config_latch Inst_frame0_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[83]),
    .QN(ConfigBits_N[83])
);

config_latch Inst_frame0_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[82]),
    .QN(ConfigBits_N[82])
);

config_latch Inst_frame0_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[81]),
    .QN(ConfigBits_N[81])
);

config_latch Inst_frame0_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[80]),
    .QN(ConfigBits_N[80])
);

config_latch Inst_frame0_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[79]),
    .QN(ConfigBits_N[79])
);

config_latch Inst_frame0_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[78]),
    .QN(ConfigBits_N[78])
);

config_latch Inst_frame0_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[77]),
    .QN(ConfigBits_N[77])
);

config_latch Inst_frame0_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[76]),
    .QN(ConfigBits_N[76])
);

config_latch Inst_frame1_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[75]),
    .QN(ConfigBits_N[75])
);

config_latch Inst_frame1_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[74]),
    .QN(ConfigBits_N[74])
);

config_latch Inst_frame1_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[73]),
    .QN(ConfigBits_N[73])
);

config_latch Inst_frame1_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[72]),
    .QN(ConfigBits_N[72])
);

config_latch Inst_frame1_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[71]),
    .QN(ConfigBits_N[71])
);

config_latch Inst_frame1_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[70]),
    .QN(ConfigBits_N[70])
);

config_latch Inst_frame1_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[69]),
    .QN(ConfigBits_N[69])
);

config_latch Inst_frame1_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[68]),
    .QN(ConfigBits_N[68])
);

config_latch Inst_frame1_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[67]),
    .QN(ConfigBits_N[67])
);

config_latch Inst_frame1_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[66]),
    .QN(ConfigBits_N[66])
);

config_latch Inst_frame1_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[65]),
    .QN(ConfigBits_N[65])
);

config_latch Inst_frame1_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[64]),
    .QN(ConfigBits_N[64])
);

config_latch Inst_frame1_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[63]),
    .QN(ConfigBits_N[63])
);

config_latch Inst_frame1_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[62]),
    .QN(ConfigBits_N[62])
);

config_latch Inst_frame1_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[61]),
    .QN(ConfigBits_N[61])
);

config_latch Inst_frame1_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[60]),
    .QN(ConfigBits_N[60])
);

config_latch Inst_frame1_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[59]),
    .QN(ConfigBits_N[59])
);

config_latch Inst_frame1_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[58]),
    .QN(ConfigBits_N[58])
);

config_latch Inst_frame1_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[57]),
    .QN(ConfigBits_N[57])
);

config_latch Inst_frame1_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[56]),
    .QN(ConfigBits_N[56])
);

config_latch Inst_frame1_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[55]),
    .QN(ConfigBits_N[55])
);

config_latch Inst_frame1_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[54]),
    .QN(ConfigBits_N[54])
);

config_latch Inst_frame1_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[53]),
    .QN(ConfigBits_N[53])
);

config_latch Inst_frame1_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[52]),
    .QN(ConfigBits_N[52])
);

config_latch Inst_frame1_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[51]),
    .QN(ConfigBits_N[51])
);

config_latch Inst_frame1_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[50]),
    .QN(ConfigBits_N[50])
);

config_latch Inst_frame1_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[49]),
    .QN(ConfigBits_N[49])
);

config_latch Inst_frame1_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[48]),
    .QN(ConfigBits_N[48])
);

config_latch Inst_frame1_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[47]),
    .QN(ConfigBits_N[47])
);

config_latch Inst_frame1_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[46]),
    .QN(ConfigBits_N[46])
);

config_latch Inst_frame1_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[45]),
    .QN(ConfigBits_N[45])
);

config_latch Inst_frame1_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[44]),
    .QN(ConfigBits_N[44])
);

config_latch Inst_frame2_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[43]),
    .QN(ConfigBits_N[43])
);

config_latch Inst_frame2_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[42]),
    .QN(ConfigBits_N[42])
);

config_latch Inst_frame2_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[41]),
    .QN(ConfigBits_N[41])
);

config_latch Inst_frame2_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[40]),
    .QN(ConfigBits_N[40])
);

config_latch Inst_frame2_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[39]),
    .QN(ConfigBits_N[39])
);

config_latch Inst_frame2_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[38]),
    .QN(ConfigBits_N[38])
);

config_latch Inst_frame2_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[37]),
    .QN(ConfigBits_N[37])
);

config_latch Inst_frame2_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[36]),
    .QN(ConfigBits_N[36])
);

config_latch Inst_frame2_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[35]),
    .QN(ConfigBits_N[35])
);

config_latch Inst_frame2_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[34]),
    .QN(ConfigBits_N[34])
);

config_latch Inst_frame2_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[33]),
    .QN(ConfigBits_N[33])
);

config_latch Inst_frame2_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[32]),
    .QN(ConfigBits_N[32])
);

config_latch Inst_frame2_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[31]),
    .QN(ConfigBits_N[31])
);

config_latch Inst_frame2_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[30]),
    .QN(ConfigBits_N[30])
);

config_latch Inst_frame2_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[29]),
    .QN(ConfigBits_N[29])
);

config_latch Inst_frame2_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[28]),
    .QN(ConfigBits_N[28])
);

config_latch Inst_frame2_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[27]),
    .QN(ConfigBits_N[27])
);

config_latch Inst_frame2_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[26]),
    .QN(ConfigBits_N[26])
);

config_latch Inst_frame2_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[25]),
    .QN(ConfigBits_N[25])
);

config_latch Inst_frame2_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[24]),
    .QN(ConfigBits_N[24])
);

config_latch Inst_frame2_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[23]),
    .QN(ConfigBits_N[23])
);

config_latch Inst_frame2_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[22]),
    .QN(ConfigBits_N[22])
);

config_latch Inst_frame2_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[21]),
    .QN(ConfigBits_N[21])
);

config_latch Inst_frame2_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[20]),
    .QN(ConfigBits_N[20])
);

config_latch Inst_frame2_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[19]),
    .QN(ConfigBits_N[19])
);

config_latch Inst_frame2_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[18]),
    .QN(ConfigBits_N[18])
);

config_latch Inst_frame2_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[17]),
    .QN(ConfigBits_N[17])
);

config_latch Inst_frame2_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[16]),
    .QN(ConfigBits_N[16])
);

config_latch Inst_frame2_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[15]),
    .QN(ConfigBits_N[15])
);

config_latch Inst_frame2_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[14]),
    .QN(ConfigBits_N[14])
);

config_latch Inst_frame2_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[13]),
    .QN(ConfigBits_N[13])
);

config_latch Inst_frame2_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[12]),
    .QN(ConfigBits_N[12])
);

config_latch Inst_frame3_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[11]),
    .QN(ConfigBits_N[11])
);

config_latch Inst_frame3_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[10]),
    .QN(ConfigBits_N[10])
);

config_latch Inst_frame3_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[9]),
    .QN(ConfigBits_N[9])
);

config_latch Inst_frame3_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[8]),
    .QN(ConfigBits_N[8])
);

config_latch Inst_frame3_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[7]),
    .QN(ConfigBits_N[7])
);

config_latch Inst_frame3_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[6]),
    .QN(ConfigBits_N[6])
);

config_latch Inst_frame3_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[5]),
    .QN(ConfigBits_N[5])
);

config_latch Inst_frame3_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[4]),
    .QN(ConfigBits_N[4])
);

config_latch Inst_frame3_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[3]),
    .QN(ConfigBits_N[3])
);

config_latch Inst_frame3_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[2]),
    .QN(ConfigBits_N[2])
);

config_latch Inst_frame3_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[1]),
    .QN(ConfigBits_N[1])
);

config_latch Inst_frame3_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[0]),
    .QN(ConfigBits_N[0])
);

`endif
endmodule
 // NumberOfConfigBits: 96
module S_IO4_switch_matrix
    #(
        parameter NoConfigBits=96
    )
    (
        input  W_GBUF_FEED_END0,
        input  W_GBUF_FEED_END1,
        input  W_GBUF_FEED_END2,
        input  W_GBUF_FEED_END3,
        input  E_GBUF_END0,
        input  E_GBUF_END1,
        input  E_GBUF_END2,
        input  E_GBUF_END3,
        input  S1END0,
        input  S1END1,
        input  S1END2,
        input  S1END3,
        input  S1END4,
        input  S1END5,
        input  S1END6,
        input  S1END7,
        input  S2MID0,
        input  S2MID1,
        input  S2MID2,
        input  S2MID3,
        input  S2MID4,
        input  S2MID5,
        input  S2MID6,
        input  S2MID7,
        input  S2END0,
        input  S2END1,
        input  S2END2,
        input  S2END3,
        input  S2END4,
        input  S2END5,
        input  S2END6,
        input  S2END7,
        input  A_OUT,
        input  B_OUT,
        input  C_OUT,
        input  D_OUT,
        output  W_GBUF_FEED_BEG0,
        output  W_GBUF_FEED_BEG1,
        output  W_GBUF_FEED_BEG2,
        output  W_GBUF_FEED_BEG3,
        output  N_GBUF_BEG0,
        output  N_GBUF_BEG1,
        output  N_GBUF_BEG2,
        output  N_GBUF_BEG3,
        output  E_GBUF_BEG0,
        output  E_GBUF_BEG1,
        output  E_GBUF_BEG2,
        output  E_GBUF_BEG3,
        output  N1BEG0,
        output  N1BEG1,
        output  N1BEG2,
        output  N1BEG3,
        output  N1BEG4,
        output  N1BEG5,
        output  N1BEG6,
        output  N1BEG7,
        output  N2BEG0,
        output  N2BEG1,
        output  N2BEG2,
        output  N2BEG3,
        output  N2BEG4,
        output  N2BEG5,
        output  N2BEG6,
        output  N2BEG7,
        output  N2BEGb0,
        output  N2BEGb1,
        output  N2BEGb2,
        output  N2BEGb3,
        output  N2BEGb4,
        output  N2BEGb5,
        output  N2BEGb6,
        output  N2BEGb7,
        output  Co0,
        output  A_CLK,
        output  A_IN,
        output  A_EN,
        output  B_CLK,
        output  B_IN,
        output  B_EN,
        output  C_CLK,
        output  C_IN,
        output  C_EN,
        output  D_CLK,
        output  D_IN,
        output  D_EN,
 //global
        input  [NoConfigBits-1:0] ConfigBits,
        input  [NoConfigBits-1:0] ConfigBits_N
);
parameter GND0 = 1'b0;
parameter GND = 1'b0;
parameter VCC0 = 1'b1;
parameter VCC = 1'b1;
parameter VDD0 = 1'b1;
parameter VDD = 1'b1;

wire[7-1:0] W_GBUF_FEED_BEG0_input;
wire[7-1:0] W_GBUF_FEED_BEG1_input;
wire[7-1:0] W_GBUF_FEED_BEG2_input;
wire[7-1:0] W_GBUF_FEED_BEG3_input;
wire[4-1:0] N1BEG0_input;
wire[4-1:0] N1BEG1_input;
wire[4-1:0] N1BEG2_input;
wire[4-1:0] N1BEG3_input;
wire[4-1:0] N1BEG4_input;
wire[4-1:0] N1BEG5_input;
wire[4-1:0] N1BEG6_input;
wire[4-1:0] N1BEG7_input;
wire[4-1:0] N2BEG0_input;
wire[4-1:0] N2BEG1_input;
wire[4-1:0] N2BEG2_input;
wire[4-1:0] N2BEG3_input;
wire[4-1:0] N2BEG4_input;
wire[4-1:0] N2BEG5_input;
wire[4-1:0] N2BEG6_input;
wire[4-1:0] N2BEG7_input;
wire[4-1:0] N2BEGb0_input;
wire[4-1:0] N2BEGb1_input;
wire[4-1:0] N2BEGb2_input;
wire[4-1:0] N2BEGb3_input;
wire[4-1:0] N2BEGb4_input;
wire[4-1:0] N2BEGb5_input;
wire[4-1:0] N2BEGb6_input;
wire[4-1:0] N2BEGb7_input;
wire[4-1:0] A_CLK_input;
wire[16-1:0] A_IN_input;
wire[8-1:0] A_EN_input;
wire[4-1:0] B_CLK_input;
wire[16-1:0] B_IN_input;
wire[8-1:0] B_EN_input;
wire[4-1:0] C_CLK_input;
wire[16-1:0] C_IN_input;
wire[8-1:0] C_EN_input;
wire[4-1:0] D_CLK_input;
wire[16-1:0] D_IN_input;
wire[8-1:0] D_EN_input;
 //The configuration bits (if any) are just a long shift register
 //This shift register is padded to an even number of flops/latches
 //switch matrix multiplexer W_GBUF_FEED_BEG0 MUX-7
assign W_GBUF_FEED_BEG0_input = {D_OUT,C_OUT,B_OUT,A_OUT,S2END7,S1END1,W_GBUF_FEED_END0};
cus_mux81 inst_cus_mux81_W_GBUF_FEED_BEG0 (
    .A0(W_GBUF_FEED_BEG0_input[0]),
    .A1(W_GBUF_FEED_BEG0_input[1]),
    .A2(W_GBUF_FEED_BEG0_input[2]),
    .A3(W_GBUF_FEED_BEG0_input[3]),
    .A4(W_GBUF_FEED_BEG0_input[4]),
    .A5(W_GBUF_FEED_BEG0_input[5]),
    .A6(W_GBUF_FEED_BEG0_input[6]),
    .A7(GND0),
    .S0(ConfigBits[0+0]),
    .S0N(ConfigBits_N[0+0]),
    .S1(ConfigBits[0+1]),
    .S1N(ConfigBits_N[0+1]),
    .S2(ConfigBits[0+2]),
    .S2N(ConfigBits_N[0+2]),
    .X(W_GBUF_FEED_BEG0)
);

 //switch matrix multiplexer W_GBUF_FEED_BEG1 MUX-7
assign W_GBUF_FEED_BEG1_input = {D_OUT,C_OUT,B_OUT,A_OUT,S2END6,S1END2,W_GBUF_FEED_END1};
cus_mux81 inst_cus_mux81_W_GBUF_FEED_BEG1 (
    .A0(W_GBUF_FEED_BEG1_input[0]),
    .A1(W_GBUF_FEED_BEG1_input[1]),
    .A2(W_GBUF_FEED_BEG1_input[2]),
    .A3(W_GBUF_FEED_BEG1_input[3]),
    .A4(W_GBUF_FEED_BEG1_input[4]),
    .A5(W_GBUF_FEED_BEG1_input[5]),
    .A6(W_GBUF_FEED_BEG1_input[6]),
    .A7(GND0),
    .S0(ConfigBits[3+0]),
    .S0N(ConfigBits_N[3+0]),
    .S1(ConfigBits[3+1]),
    .S1N(ConfigBits_N[3+1]),
    .S2(ConfigBits[3+2]),
    .S2N(ConfigBits_N[3+2]),
    .X(W_GBUF_FEED_BEG1)
);

 //switch matrix multiplexer W_GBUF_FEED_BEG2 MUX-7
assign W_GBUF_FEED_BEG2_input = {D_OUT,C_OUT,B_OUT,A_OUT,S2END5,S1END3,W_GBUF_FEED_END2};
cus_mux81 inst_cus_mux81_W_GBUF_FEED_BEG2 (
    .A0(W_GBUF_FEED_BEG2_input[0]),
    .A1(W_GBUF_FEED_BEG2_input[1]),
    .A2(W_GBUF_FEED_BEG2_input[2]),
    .A3(W_GBUF_FEED_BEG2_input[3]),
    .A4(W_GBUF_FEED_BEG2_input[4]),
    .A5(W_GBUF_FEED_BEG2_input[5]),
    .A6(W_GBUF_FEED_BEG2_input[6]),
    .A7(GND0),
    .S0(ConfigBits[6+0]),
    .S0N(ConfigBits_N[6+0]),
    .S1(ConfigBits[6+1]),
    .S1N(ConfigBits_N[6+1]),
    .S2(ConfigBits[6+2]),
    .S2N(ConfigBits_N[6+2]),
    .X(W_GBUF_FEED_BEG2)
);

 //switch matrix multiplexer W_GBUF_FEED_BEG3 MUX-7
assign W_GBUF_FEED_BEG3_input = {D_OUT,C_OUT,B_OUT,A_OUT,S2END4,S1END0,W_GBUF_FEED_END3};
cus_mux81 inst_cus_mux81_W_GBUF_FEED_BEG3 (
    .A0(W_GBUF_FEED_BEG3_input[0]),
    .A1(W_GBUF_FEED_BEG3_input[1]),
    .A2(W_GBUF_FEED_BEG3_input[2]),
    .A3(W_GBUF_FEED_BEG3_input[3]),
    .A4(W_GBUF_FEED_BEG3_input[4]),
    .A5(W_GBUF_FEED_BEG3_input[5]),
    .A6(W_GBUF_FEED_BEG3_input[6]),
    .A7(GND0),
    .S0(ConfigBits[9+0]),
    .S0N(ConfigBits_N[9+0]),
    .S1(ConfigBits[9+1]),
    .S1N(ConfigBits_N[9+1]),
    .S2(ConfigBits[9+2]),
    .S2N(ConfigBits_N[9+2]),
    .X(W_GBUF_FEED_BEG3)
);

 //switch matrix multiplexer N_GBUF_BEG0 MUX-1
assign N_GBUF_BEG0 = E_GBUF_END0;

 //switch matrix multiplexer N_GBUF_BEG1 MUX-1
assign N_GBUF_BEG1 = E_GBUF_END1;

 //switch matrix multiplexer N_GBUF_BEG2 MUX-1
assign N_GBUF_BEG2 = E_GBUF_END2;

 //switch matrix multiplexer N_GBUF_BEG3 MUX-1
assign N_GBUF_BEG3 = E_GBUF_END3;

 //switch matrix multiplexer E_GBUF_BEG0 MUX-1
assign E_GBUF_BEG0 = E_GBUF_END0;

 //switch matrix multiplexer E_GBUF_BEG1 MUX-1
assign E_GBUF_BEG1 = E_GBUF_END1;

 //switch matrix multiplexer E_GBUF_BEG2 MUX-1
assign E_GBUF_BEG2 = E_GBUF_END2;

 //switch matrix multiplexer E_GBUF_BEG3 MUX-1
assign E_GBUF_BEG3 = E_GBUF_END3;

 //switch matrix multiplexer N1BEG0 MUX-4
assign N1BEG0_input = {A_OUT,S2END7,S2MID7,S1END7};
cus_mux41 inst_cus_mux41_N1BEG0 (
    .A0(N1BEG0_input[0]),
    .A1(N1BEG0_input[1]),
    .A2(N1BEG0_input[2]),
    .A3(N1BEG0_input[3]),
    .S0(ConfigBits[12+0]),
    .S0N(ConfigBits_N[12+0]),
    .S1(ConfigBits[12+1]),
    .S1N(ConfigBits_N[12+1]),
    .X(N1BEG0)
);

 //switch matrix multiplexer N1BEG1 MUX-4
assign N1BEG1_input = {B_OUT,S2END6,S2MID6,S1END6};
cus_mux41 inst_cus_mux41_N1BEG1 (
    .A0(N1BEG1_input[0]),
    .A1(N1BEG1_input[1]),
    .A2(N1BEG1_input[2]),
    .A3(N1BEG1_input[3]),
    .S0(ConfigBits[14+0]),
    .S0N(ConfigBits_N[14+0]),
    .S1(ConfigBits[14+1]),
    .S1N(ConfigBits_N[14+1]),
    .X(N1BEG1)
);

 //switch matrix multiplexer N1BEG2 MUX-4
assign N1BEG2_input = {C_OUT,S2END5,S2MID5,S1END5};
cus_mux41 inst_cus_mux41_N1BEG2 (
    .A0(N1BEG2_input[0]),
    .A1(N1BEG2_input[1]),
    .A2(N1BEG2_input[2]),
    .A3(N1BEG2_input[3]),
    .S0(ConfigBits[16+0]),
    .S0N(ConfigBits_N[16+0]),
    .S1(ConfigBits[16+1]),
    .S1N(ConfigBits_N[16+1]),
    .X(N1BEG2)
);

 //switch matrix multiplexer N1BEG3 MUX-4
assign N1BEG3_input = {D_OUT,S2END4,S2MID4,S1END4};
cus_mux41 inst_cus_mux41_N1BEG3 (
    .A0(N1BEG3_input[0]),
    .A1(N1BEG3_input[1]),
    .A2(N1BEG3_input[2]),
    .A3(N1BEG3_input[3]),
    .S0(ConfigBits[18+0]),
    .S0N(ConfigBits_N[18+0]),
    .S1(ConfigBits[18+1]),
    .S1N(ConfigBits_N[18+1]),
    .X(N1BEG3)
);

 //switch matrix multiplexer N1BEG4 MUX-4
assign N1BEG4_input = {A_OUT,S2END3,S2MID3,S1END3};
cus_mux41 inst_cus_mux41_N1BEG4 (
    .A0(N1BEG4_input[0]),
    .A1(N1BEG4_input[1]),
    .A2(N1BEG4_input[2]),
    .A3(N1BEG4_input[3]),
    .S0(ConfigBits[20+0]),
    .S0N(ConfigBits_N[20+0]),
    .S1(ConfigBits[20+1]),
    .S1N(ConfigBits_N[20+1]),
    .X(N1BEG4)
);

 //switch matrix multiplexer N1BEG5 MUX-4
assign N1BEG5_input = {B_OUT,S2END2,S2MID2,S1END2};
cus_mux41 inst_cus_mux41_N1BEG5 (
    .A0(N1BEG5_input[0]),
    .A1(N1BEG5_input[1]),
    .A2(N1BEG5_input[2]),
    .A3(N1BEG5_input[3]),
    .S0(ConfigBits[22+0]),
    .S0N(ConfigBits_N[22+0]),
    .S1(ConfigBits[22+1]),
    .S1N(ConfigBits_N[22+1]),
    .X(N1BEG5)
);

 //switch matrix multiplexer N1BEG6 MUX-4
assign N1BEG6_input = {C_OUT,S2END1,S2MID1,S1END1};
cus_mux41 inst_cus_mux41_N1BEG6 (
    .A0(N1BEG6_input[0]),
    .A1(N1BEG6_input[1]),
    .A2(N1BEG6_input[2]),
    .A3(N1BEG6_input[3]),
    .S0(ConfigBits[24+0]),
    .S0N(ConfigBits_N[24+0]),
    .S1(ConfigBits[24+1]),
    .S1N(ConfigBits_N[24+1]),
    .X(N1BEG6)
);

 //switch matrix multiplexer N1BEG7 MUX-4
assign N1BEG7_input = {D_OUT,S2END0,S2MID0,S1END0};
cus_mux41 inst_cus_mux41_N1BEG7 (
    .A0(N1BEG7_input[0]),
    .A1(N1BEG7_input[1]),
    .A2(N1BEG7_input[2]),
    .A3(N1BEG7_input[3]),
    .S0(ConfigBits[26+0]),
    .S0N(ConfigBits_N[26+0]),
    .S1(ConfigBits[26+1]),
    .S1N(ConfigBits_N[26+1]),
    .X(N1BEG7)
);

 //switch matrix multiplexer N2BEG0 MUX-4
assign N2BEG0_input = {A_OUT,S2END7,S2MID7,S1END7};
cus_mux41 inst_cus_mux41_N2BEG0 (
    .A0(N2BEG0_input[0]),
    .A1(N2BEG0_input[1]),
    .A2(N2BEG0_input[2]),
    .A3(N2BEG0_input[3]),
    .S0(ConfigBits[28+0]),
    .S0N(ConfigBits_N[28+0]),
    .S1(ConfigBits[28+1]),
    .S1N(ConfigBits_N[28+1]),
    .X(N2BEG0)
);

 //switch matrix multiplexer N2BEG1 MUX-4
assign N2BEG1_input = {B_OUT,S2END6,S2MID6,S1END6};
cus_mux41 inst_cus_mux41_N2BEG1 (
    .A0(N2BEG1_input[0]),
    .A1(N2BEG1_input[1]),
    .A2(N2BEG1_input[2]),
    .A3(N2BEG1_input[3]),
    .S0(ConfigBits[30+0]),
    .S0N(ConfigBits_N[30+0]),
    .S1(ConfigBits[30+1]),
    .S1N(ConfigBits_N[30+1]),
    .X(N2BEG1)
);

 //switch matrix multiplexer N2BEG2 MUX-4
assign N2BEG2_input = {C_OUT,S2END5,S2MID5,S1END5};
cus_mux41 inst_cus_mux41_N2BEG2 (
    .A0(N2BEG2_input[0]),
    .A1(N2BEG2_input[1]),
    .A2(N2BEG2_input[2]),
    .A3(N2BEG2_input[3]),
    .S0(ConfigBits[32+0]),
    .S0N(ConfigBits_N[32+0]),
    .S1(ConfigBits[32+1]),
    .S1N(ConfigBits_N[32+1]),
    .X(N2BEG2)
);

 //switch matrix multiplexer N2BEG3 MUX-4
assign N2BEG3_input = {D_OUT,S2END4,S2MID4,S1END4};
cus_mux41 inst_cus_mux41_N2BEG3 (
    .A0(N2BEG3_input[0]),
    .A1(N2BEG3_input[1]),
    .A2(N2BEG3_input[2]),
    .A3(N2BEG3_input[3]),
    .S0(ConfigBits[34+0]),
    .S0N(ConfigBits_N[34+0]),
    .S1(ConfigBits[34+1]),
    .S1N(ConfigBits_N[34+1]),
    .X(N2BEG3)
);

 //switch matrix multiplexer N2BEG4 MUX-4
assign N2BEG4_input = {A_OUT,S2END3,S2MID3,S1END3};
cus_mux41 inst_cus_mux41_N2BEG4 (
    .A0(N2BEG4_input[0]),
    .A1(N2BEG4_input[1]),
    .A2(N2BEG4_input[2]),
    .A3(N2BEG4_input[3]),
    .S0(ConfigBits[36+0]),
    .S0N(ConfigBits_N[36+0]),
    .S1(ConfigBits[36+1]),
    .S1N(ConfigBits_N[36+1]),
    .X(N2BEG4)
);

 //switch matrix multiplexer N2BEG5 MUX-4
assign N2BEG5_input = {B_OUT,S2END2,S2MID2,S1END2};
cus_mux41 inst_cus_mux41_N2BEG5 (
    .A0(N2BEG5_input[0]),
    .A1(N2BEG5_input[1]),
    .A2(N2BEG5_input[2]),
    .A3(N2BEG5_input[3]),
    .S0(ConfigBits[38+0]),
    .S0N(ConfigBits_N[38+0]),
    .S1(ConfigBits[38+1]),
    .S1N(ConfigBits_N[38+1]),
    .X(N2BEG5)
);

 //switch matrix multiplexer N2BEG6 MUX-4
assign N2BEG6_input = {C_OUT,S2END1,S2MID1,S1END1};
cus_mux41 inst_cus_mux41_N2BEG6 (
    .A0(N2BEG6_input[0]),
    .A1(N2BEG6_input[1]),
    .A2(N2BEG6_input[2]),
    .A3(N2BEG6_input[3]),
    .S0(ConfigBits[40+0]),
    .S0N(ConfigBits_N[40+0]),
    .S1(ConfigBits[40+1]),
    .S1N(ConfigBits_N[40+1]),
    .X(N2BEG6)
);

 //switch matrix multiplexer N2BEG7 MUX-4
assign N2BEG7_input = {D_OUT,S2END0,S2MID0,S1END0};
cus_mux41 inst_cus_mux41_N2BEG7 (
    .A0(N2BEG7_input[0]),
    .A1(N2BEG7_input[1]),
    .A2(N2BEG7_input[2]),
    .A3(N2BEG7_input[3]),
    .S0(ConfigBits[42+0]),
    .S0N(ConfigBits_N[42+0]),
    .S1(ConfigBits[42+1]),
    .S1N(ConfigBits_N[42+1]),
    .X(N2BEG7)
);

 //switch matrix multiplexer N2BEGb0 MUX-4
assign N2BEGb0_input = {D_OUT,S2END7,S2MID7,S1END7};
cus_mux41 inst_cus_mux41_N2BEGb0 (
    .A0(N2BEGb0_input[0]),
    .A1(N2BEGb0_input[1]),
    .A2(N2BEGb0_input[2]),
    .A3(N2BEGb0_input[3]),
    .S0(ConfigBits[44+0]),
    .S0N(ConfigBits_N[44+0]),
    .S1(ConfigBits[44+1]),
    .S1N(ConfigBits_N[44+1]),
    .X(N2BEGb0)
);

 //switch matrix multiplexer N2BEGb1 MUX-4
assign N2BEGb1_input = {C_OUT,S2END6,S2MID6,S1END6};
cus_mux41 inst_cus_mux41_N2BEGb1 (
    .A0(N2BEGb1_input[0]),
    .A1(N2BEGb1_input[1]),
    .A2(N2BEGb1_input[2]),
    .A3(N2BEGb1_input[3]),
    .S0(ConfigBits[46+0]),
    .S0N(ConfigBits_N[46+0]),
    .S1(ConfigBits[46+1]),
    .S1N(ConfigBits_N[46+1]),
    .X(N2BEGb1)
);

 //switch matrix multiplexer N2BEGb2 MUX-4
assign N2BEGb2_input = {C_OUT,S2END5,S2MID5,S1END5};
cus_mux41 inst_cus_mux41_N2BEGb2 (
    .A0(N2BEGb2_input[0]),
    .A1(N2BEGb2_input[1]),
    .A2(N2BEGb2_input[2]),
    .A3(N2BEGb2_input[3]),
    .S0(ConfigBits[48+0]),
    .S0N(ConfigBits_N[48+0]),
    .S1(ConfigBits[48+1]),
    .S1N(ConfigBits_N[48+1]),
    .X(N2BEGb2)
);

 //switch matrix multiplexer N2BEGb3 MUX-4
assign N2BEGb3_input = {A_OUT,S2END4,S2MID4,S1END4};
cus_mux41 inst_cus_mux41_N2BEGb3 (
    .A0(N2BEGb3_input[0]),
    .A1(N2BEGb3_input[1]),
    .A2(N2BEGb3_input[2]),
    .A3(N2BEGb3_input[3]),
    .S0(ConfigBits[50+0]),
    .S0N(ConfigBits_N[50+0]),
    .S1(ConfigBits[50+1]),
    .S1N(ConfigBits_N[50+1]),
    .X(N2BEGb3)
);

 //switch matrix multiplexer N2BEGb4 MUX-4
assign N2BEGb4_input = {D_OUT,S2END3,S2MID3,S1END3};
cus_mux41 inst_cus_mux41_N2BEGb4 (
    .A0(N2BEGb4_input[0]),
    .A1(N2BEGb4_input[1]),
    .A2(N2BEGb4_input[2]),
    .A3(N2BEGb4_input[3]),
    .S0(ConfigBits[52+0]),
    .S0N(ConfigBits_N[52+0]),
    .S1(ConfigBits[52+1]),
    .S1N(ConfigBits_N[52+1]),
    .X(N2BEGb4)
);

 //switch matrix multiplexer N2BEGb5 MUX-4
assign N2BEGb5_input = {C_OUT,S2END2,S2MID2,S1END2};
cus_mux41 inst_cus_mux41_N2BEGb5 (
    .A0(N2BEGb5_input[0]),
    .A1(N2BEGb5_input[1]),
    .A2(N2BEGb5_input[2]),
    .A3(N2BEGb5_input[3]),
    .S0(ConfigBits[54+0]),
    .S0N(ConfigBits_N[54+0]),
    .S1(ConfigBits[54+1]),
    .S1N(ConfigBits_N[54+1]),
    .X(N2BEGb5)
);

 //switch matrix multiplexer N2BEGb6 MUX-4
assign N2BEGb6_input = {B_OUT,S2END1,S2MID1,S1END1};
cus_mux41 inst_cus_mux41_N2BEGb6 (
    .A0(N2BEGb6_input[0]),
    .A1(N2BEGb6_input[1]),
    .A2(N2BEGb6_input[2]),
    .A3(N2BEGb6_input[3]),
    .S0(ConfigBits[56+0]),
    .S0N(ConfigBits_N[56+0]),
    .S1(ConfigBits[56+1]),
    .S1N(ConfigBits_N[56+1]),
    .X(N2BEGb6)
);

 //switch matrix multiplexer N2BEGb7 MUX-4
assign N2BEGb7_input = {A_OUT,S2END0,S2MID0,S1END0};
cus_mux41 inst_cus_mux41_N2BEGb7 (
    .A0(N2BEGb7_input[0]),
    .A1(N2BEGb7_input[1]),
    .A2(N2BEGb7_input[2]),
    .A3(N2BEGb7_input[3]),
    .S0(ConfigBits[58+0]),
    .S0N(ConfigBits_N[58+0]),
    .S1(ConfigBits[58+1]),
    .S1N(ConfigBits_N[58+1]),
    .X(N2BEGb7)
);

 //switch matrix multiplexer Co0 MUX-1
assign Co0 = GND0;

 //switch matrix multiplexer A_CLK MUX-4
assign A_CLK_input = {E_GBUF_END3,E_GBUF_END2,E_GBUF_END1,E_GBUF_END0};
cus_mux41 inst_cus_mux41_A_CLK (
    .A0(A_CLK_input[0]),
    .A1(A_CLK_input[1]),
    .A2(A_CLK_input[2]),
    .A3(A_CLK_input[3]),
    .S0(ConfigBits[60+0]),
    .S0N(ConfigBits_N[60+0]),
    .S1(ConfigBits[60+1]),
    .S1N(ConfigBits_N[60+1]),
    .X(A_CLK)
);

 //switch matrix multiplexer A_IN MUX-16
assign A_IN_input = {VCC0,GND0,S2END7,S2END6,S2END5,S2MID2,S2MID1,S2MID0,S1END7,S1END6,S1END5,S1END4,S1END3,S1END2,S1END1,S1END0};
cus_mux161 inst_cus_mux161_A_IN (
    .A0(A_IN_input[0]),
    .A1(A_IN_input[1]),
    .A2(A_IN_input[2]),
    .A3(A_IN_input[3]),
    .A4(A_IN_input[4]),
    .A5(A_IN_input[5]),
    .A6(A_IN_input[6]),
    .A7(A_IN_input[7]),
    .A8(A_IN_input[8]),
    .A9(A_IN_input[9]),
    .A10(A_IN_input[10]),
    .A11(A_IN_input[11]),
    .A12(A_IN_input[12]),
    .A13(A_IN_input[13]),
    .A14(A_IN_input[14]),
    .A15(A_IN_input[15]),
    .S0(ConfigBits[62+0]),
    .S0N(ConfigBits_N[62+0]),
    .S1(ConfigBits[62+1]),
    .S1N(ConfigBits_N[62+1]),
    .S2(ConfigBits[62+2]),
    .S2N(ConfigBits_N[62+2]),
    .S3(ConfigBits[62+3]),
    .S3N(ConfigBits_N[62+3]),
    .X(A_IN)
);

 //switch matrix multiplexer A_EN MUX-8
assign A_EN_input = {VCC0,GND0,S2END2,S2END0,S2MID7,S2MID4,S1END7,S1END3};
cus_mux81 inst_cus_mux81_A_EN (
    .A0(A_EN_input[0]),
    .A1(A_EN_input[1]),
    .A2(A_EN_input[2]),
    .A3(A_EN_input[3]),
    .A4(A_EN_input[4]),
    .A5(A_EN_input[5]),
    .A6(A_EN_input[6]),
    .A7(A_EN_input[7]),
    .S0(ConfigBits[66+0]),
    .S0N(ConfigBits_N[66+0]),
    .S1(ConfigBits[66+1]),
    .S1N(ConfigBits_N[66+1]),
    .S2(ConfigBits[66+2]),
    .S2N(ConfigBits_N[66+2]),
    .X(A_EN)
);

 //switch matrix multiplexer B_CLK MUX-4
assign B_CLK_input = {E_GBUF_END3,E_GBUF_END2,E_GBUF_END1,E_GBUF_END0};
cus_mux41 inst_cus_mux41_B_CLK (
    .A0(B_CLK_input[0]),
    .A1(B_CLK_input[1]),
    .A2(B_CLK_input[2]),
    .A3(B_CLK_input[3]),
    .S0(ConfigBits[69+0]),
    .S0N(ConfigBits_N[69+0]),
    .S1(ConfigBits[69+1]),
    .S1N(ConfigBits_N[69+1]),
    .X(B_CLK)
);

 //switch matrix multiplexer B_IN MUX-16
assign B_IN_input = {VCC0,GND0,S2END7,S2END6,S2END5,S2MID2,S2MID1,S2MID0,S1END7,S1END6,S1END5,S1END4,S1END3,S1END2,S1END1,S1END0};
cus_mux161 inst_cus_mux161_B_IN (
    .A0(B_IN_input[0]),
    .A1(B_IN_input[1]),
    .A2(B_IN_input[2]),
    .A3(B_IN_input[3]),
    .A4(B_IN_input[4]),
    .A5(B_IN_input[5]),
    .A6(B_IN_input[6]),
    .A7(B_IN_input[7]),
    .A8(B_IN_input[8]),
    .A9(B_IN_input[9]),
    .A10(B_IN_input[10]),
    .A11(B_IN_input[11]),
    .A12(B_IN_input[12]),
    .A13(B_IN_input[13]),
    .A14(B_IN_input[14]),
    .A15(B_IN_input[15]),
    .S0(ConfigBits[71+0]),
    .S0N(ConfigBits_N[71+0]),
    .S1(ConfigBits[71+1]),
    .S1N(ConfigBits_N[71+1]),
    .S2(ConfigBits[71+2]),
    .S2N(ConfigBits_N[71+2]),
    .S3(ConfigBits[71+3]),
    .S3N(ConfigBits_N[71+3]),
    .X(B_IN)
);

 //switch matrix multiplexer B_EN MUX-8
assign B_EN_input = {VCC0,GND0,S2END2,S2END0,S2MID7,S2MID4,S1END7,S1END3};
cus_mux81 inst_cus_mux81_B_EN (
    .A0(B_EN_input[0]),
    .A1(B_EN_input[1]),
    .A2(B_EN_input[2]),
    .A3(B_EN_input[3]),
    .A4(B_EN_input[4]),
    .A5(B_EN_input[5]),
    .A6(B_EN_input[6]),
    .A7(B_EN_input[7]),
    .S0(ConfigBits[75+0]),
    .S0N(ConfigBits_N[75+0]),
    .S1(ConfigBits[75+1]),
    .S1N(ConfigBits_N[75+1]),
    .S2(ConfigBits[75+2]),
    .S2N(ConfigBits_N[75+2]),
    .X(B_EN)
);

 //switch matrix multiplexer C_CLK MUX-4
assign C_CLK_input = {E_GBUF_END3,E_GBUF_END2,E_GBUF_END1,E_GBUF_END0};
cus_mux41 inst_cus_mux41_C_CLK (
    .A0(C_CLK_input[0]),
    .A1(C_CLK_input[1]),
    .A2(C_CLK_input[2]),
    .A3(C_CLK_input[3]),
    .S0(ConfigBits[78+0]),
    .S0N(ConfigBits_N[78+0]),
    .S1(ConfigBits[78+1]),
    .S1N(ConfigBits_N[78+1]),
    .X(C_CLK)
);

 //switch matrix multiplexer C_IN MUX-16
assign C_IN_input = {VCC0,GND0,S2END7,S2END6,S2END5,S2MID2,S2MID1,S2MID0,S1END7,S1END6,S1END5,S1END4,S1END3,S1END2,S1END1,S1END0};
cus_mux161 inst_cus_mux161_C_IN (
    .A0(C_IN_input[0]),
    .A1(C_IN_input[1]),
    .A2(C_IN_input[2]),
    .A3(C_IN_input[3]),
    .A4(C_IN_input[4]),
    .A5(C_IN_input[5]),
    .A6(C_IN_input[6]),
    .A7(C_IN_input[7]),
    .A8(C_IN_input[8]),
    .A9(C_IN_input[9]),
    .A10(C_IN_input[10]),
    .A11(C_IN_input[11]),
    .A12(C_IN_input[12]),
    .A13(C_IN_input[13]),
    .A14(C_IN_input[14]),
    .A15(C_IN_input[15]),
    .S0(ConfigBits[80+0]),
    .S0N(ConfigBits_N[80+0]),
    .S1(ConfigBits[80+1]),
    .S1N(ConfigBits_N[80+1]),
    .S2(ConfigBits[80+2]),
    .S2N(ConfigBits_N[80+2]),
    .S3(ConfigBits[80+3]),
    .S3N(ConfigBits_N[80+3]),
    .X(C_IN)
);

 //switch matrix multiplexer C_EN MUX-8
assign C_EN_input = {VCC0,GND0,S2END2,S2END0,S2MID7,S2MID4,S1END7,S1END3};
cus_mux81 inst_cus_mux81_C_EN (
    .A0(C_EN_input[0]),
    .A1(C_EN_input[1]),
    .A2(C_EN_input[2]),
    .A3(C_EN_input[3]),
    .A4(C_EN_input[4]),
    .A5(C_EN_input[5]),
    .A6(C_EN_input[6]),
    .A7(C_EN_input[7]),
    .S0(ConfigBits[84+0]),
    .S0N(ConfigBits_N[84+0]),
    .S1(ConfigBits[84+1]),
    .S1N(ConfigBits_N[84+1]),
    .S2(ConfigBits[84+2]),
    .S2N(ConfigBits_N[84+2]),
    .X(C_EN)
);

 //switch matrix multiplexer D_CLK MUX-4
assign D_CLK_input = {E_GBUF_END3,E_GBUF_END2,E_GBUF_END1,E_GBUF_END0};
cus_mux41 inst_cus_mux41_D_CLK (
    .A0(D_CLK_input[0]),
    .A1(D_CLK_input[1]),
    .A2(D_CLK_input[2]),
    .A3(D_CLK_input[3]),
    .S0(ConfigBits[87+0]),
    .S0N(ConfigBits_N[87+0]),
    .S1(ConfigBits[87+1]),
    .S1N(ConfigBits_N[87+1]),
    .X(D_CLK)
);

 //switch matrix multiplexer D_IN MUX-16
assign D_IN_input = {VCC0,GND0,S2END7,S2END6,S2END5,S2MID2,S2MID1,S2MID0,S1END7,S1END6,S1END5,S1END4,S1END3,S1END2,S1END1,S1END0};
cus_mux161 inst_cus_mux161_D_IN (
    .A0(D_IN_input[0]),
    .A1(D_IN_input[1]),
    .A2(D_IN_input[2]),
    .A3(D_IN_input[3]),
    .A4(D_IN_input[4]),
    .A5(D_IN_input[5]),
    .A6(D_IN_input[6]),
    .A7(D_IN_input[7]),
    .A8(D_IN_input[8]),
    .A9(D_IN_input[9]),
    .A10(D_IN_input[10]),
    .A11(D_IN_input[11]),
    .A12(D_IN_input[12]),
    .A13(D_IN_input[13]),
    .A14(D_IN_input[14]),
    .A15(D_IN_input[15]),
    .S0(ConfigBits[89+0]),
    .S0N(ConfigBits_N[89+0]),
    .S1(ConfigBits[89+1]),
    .S1N(ConfigBits_N[89+1]),
    .S2(ConfigBits[89+2]),
    .S2N(ConfigBits_N[89+2]),
    .S3(ConfigBits[89+3]),
    .S3N(ConfigBits_N[89+3]),
    .X(D_IN)
);

 //switch matrix multiplexer D_EN MUX-8
assign D_EN_input = {VCC0,GND0,S2END2,S2END0,S2MID7,S2MID4,S1END7,S1END3};
cus_mux81 inst_cus_mux81_D_EN (
    .A0(D_EN_input[0]),
    .A1(D_EN_input[1]),
    .A2(D_EN_input[2]),
    .A3(D_EN_input[3]),
    .A4(D_EN_input[4]),
    .A5(D_EN_input[5]),
    .A6(D_EN_input[6]),
    .A7(D_EN_input[7]),
    .S0(ConfigBits[93+0]),
    .S0N(ConfigBits_N[93+0]),
    .S1(ConfigBits[93+1]),
    .S1N(ConfigBits_N[93+1]),
    .S2(ConfigBits[93+2]),
    .S2N(ConfigBits_N[93+2]),
    .X(D_EN)
);

endmodule
module S_IO4
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=108
    )
    (
 //N
        output  [3:0] N_GBUF_BEG,        //Port(Name=N_GBUF_BEG,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=4,Side=N)
        output  [7:0] N1BEG,        //Port(Name=N1BEG,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=8,Side=N)
        output  [7:0] N2BEG,        //Port(Name=N2BEG,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=8,Side=N)
        output  [7:0] N2BEGb,        //Port(Name=N2BEGb,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=8,Side=N)
        input  [7:0] S1END,        //Port(Name=S1END,IO=INPUT,XOffset=0,YOffset=1,WireCount=8,Side=N)
        input  [7:0] S2MID,        //Port(Name=S2MID,IO=INPUT,XOffset=0,YOffset=1,WireCount=8,Side=N)
        input  [7:0] S2END,        //Port(Name=S2END,IO=INPUT,XOffset=0,YOffset=1,WireCount=8,Side=N)
        output  [0:0] Co,        //Port(Name=Co,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=1,Side=N)
 //E
        input  [3:0] W_GBUF_FEED_END,        //Port(Name=W_GBUF_FEED_END,IO=INPUT,XOffset=-1,YOffset=0,WireCount=4,Side=E)
        output  [3:0] E_GBUF_BEG,        //Port(Name=E_GBUF_BEG,IO=OUTPUT,XOffset=1,YOffset=0,WireCount=4,Side=E)
 //W
        output  [3:0] W_GBUF_FEED_BEG,        //Port(Name=W_GBUF_FEED_BEG,IO=OUTPUT,XOffset=-1,YOffset=0,WireCount=4,Side=W)
        input  [3:0] E_GBUF_END,        //Port(Name=E_GBUF_END,IO=INPUT,XOffset=1,YOffset=0,WireCount=4,Side=W)
        input  A_OUT_top,
        output  A_IN_top,
        output  A_EN_top,
        input  B_OUT_top,
        output  B_IN_top,
        output  B_EN_top,
        input  C_OUT_top,
        output  C_IN_top,
        output  C_EN_top,
        input  D_OUT_top,
        output  D_IN_top,
        output  D_EN_top,
    //Tile IO ports from BELs
        input  [FrameBitsPerRow-1:0] FrameData, //CONFIG_PORT
        output  [FrameBitsPerRow-1:0] FrameData_O,
        input  [MaxFramesPerCol-1:0] FrameStrobe, //CONFIG_PORT
        output  [MaxFramesPerCol-1:0] FrameStrobe_O
    //global
);
 //signal declarations
 //BEL ports (e.g., slices)
wire A_CLK;
wire A_IN;
wire A_EN;
wire A_OUT;
wire B_CLK;
wire B_IN;
wire B_EN;
wire B_OUT;
wire C_CLK;
wire C_IN;
wire C_EN;
wire C_OUT;
wire D_CLK;
wire D_IN;
wire D_EN;
wire D_OUT;
 //Jump wires
 //internal configuration data signal to daisy-chain all BELs (if any and in the order they are listed in the fabric.csv)
wire[NoConfigBits-1:0] ConfigBits;
wire[NoConfigBits-1:0] ConfigBits_N;

 //Connection for outgoing wires
wire[FrameBitsPerRow-1:0] FrameData_i;
wire[FrameBitsPerRow-1:0] FrameData_O_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_O_i;

assign FrameData_O_i = FrameData_i;

my_buf data_inbuf_0 (
    .A(FrameData[0]),
    .X(FrameData_i[0])
);

my_buf data_inbuf_1 (
    .A(FrameData[1]),
    .X(FrameData_i[1])
);

my_buf data_inbuf_2 (
    .A(FrameData[2]),
    .X(FrameData_i[2])
);

my_buf data_inbuf_3 (
    .A(FrameData[3]),
    .X(FrameData_i[3])
);

my_buf data_inbuf_4 (
    .A(FrameData[4]),
    .X(FrameData_i[4])
);

my_buf data_inbuf_5 (
    .A(FrameData[5]),
    .X(FrameData_i[5])
);

my_buf data_inbuf_6 (
    .A(FrameData[6]),
    .X(FrameData_i[6])
);

my_buf data_inbuf_7 (
    .A(FrameData[7]),
    .X(FrameData_i[7])
);

my_buf data_inbuf_8 (
    .A(FrameData[8]),
    .X(FrameData_i[8])
);

my_buf data_inbuf_9 (
    .A(FrameData[9]),
    .X(FrameData_i[9])
);

my_buf data_inbuf_10 (
    .A(FrameData[10]),
    .X(FrameData_i[10])
);

my_buf data_inbuf_11 (
    .A(FrameData[11]),
    .X(FrameData_i[11])
);

my_buf data_inbuf_12 (
    .A(FrameData[12]),
    .X(FrameData_i[12])
);

my_buf data_inbuf_13 (
    .A(FrameData[13]),
    .X(FrameData_i[13])
);

my_buf data_inbuf_14 (
    .A(FrameData[14]),
    .X(FrameData_i[14])
);

my_buf data_inbuf_15 (
    .A(FrameData[15]),
    .X(FrameData_i[15])
);

my_buf data_inbuf_16 (
    .A(FrameData[16]),
    .X(FrameData_i[16])
);

my_buf data_inbuf_17 (
    .A(FrameData[17]),
    .X(FrameData_i[17])
);

my_buf data_inbuf_18 (
    .A(FrameData[18]),
    .X(FrameData_i[18])
);

my_buf data_inbuf_19 (
    .A(FrameData[19]),
    .X(FrameData_i[19])
);

my_buf data_inbuf_20 (
    .A(FrameData[20]),
    .X(FrameData_i[20])
);

my_buf data_inbuf_21 (
    .A(FrameData[21]),
    .X(FrameData_i[21])
);

my_buf data_inbuf_22 (
    .A(FrameData[22]),
    .X(FrameData_i[22])
);

my_buf data_inbuf_23 (
    .A(FrameData[23]),
    .X(FrameData_i[23])
);

my_buf data_inbuf_24 (
    .A(FrameData[24]),
    .X(FrameData_i[24])
);

my_buf data_inbuf_25 (
    .A(FrameData[25]),
    .X(FrameData_i[25])
);

my_buf data_inbuf_26 (
    .A(FrameData[26]),
    .X(FrameData_i[26])
);

my_buf data_inbuf_27 (
    .A(FrameData[27]),
    .X(FrameData_i[27])
);

my_buf data_inbuf_28 (
    .A(FrameData[28]),
    .X(FrameData_i[28])
);

my_buf data_inbuf_29 (
    .A(FrameData[29]),
    .X(FrameData_i[29])
);

my_buf data_inbuf_30 (
    .A(FrameData[30]),
    .X(FrameData_i[30])
);

my_buf data_inbuf_31 (
    .A(FrameData[31]),
    .X(FrameData_i[31])
);

my_buf data_outbuf_0 (
    .A(FrameData_O_i[0]),
    .X(FrameData_O[0])
);

my_buf data_outbuf_1 (
    .A(FrameData_O_i[1]),
    .X(FrameData_O[1])
);

my_buf data_outbuf_2 (
    .A(FrameData_O_i[2]),
    .X(FrameData_O[2])
);

my_buf data_outbuf_3 (
    .A(FrameData_O_i[3]),
    .X(FrameData_O[3])
);

my_buf data_outbuf_4 (
    .A(FrameData_O_i[4]),
    .X(FrameData_O[4])
);

my_buf data_outbuf_5 (
    .A(FrameData_O_i[5]),
    .X(FrameData_O[5])
);

my_buf data_outbuf_6 (
    .A(FrameData_O_i[6]),
    .X(FrameData_O[6])
);

my_buf data_outbuf_7 (
    .A(FrameData_O_i[7]),
    .X(FrameData_O[7])
);

my_buf data_outbuf_8 (
    .A(FrameData_O_i[8]),
    .X(FrameData_O[8])
);

my_buf data_outbuf_9 (
    .A(FrameData_O_i[9]),
    .X(FrameData_O[9])
);

my_buf data_outbuf_10 (
    .A(FrameData_O_i[10]),
    .X(FrameData_O[10])
);

my_buf data_outbuf_11 (
    .A(FrameData_O_i[11]),
    .X(FrameData_O[11])
);

my_buf data_outbuf_12 (
    .A(FrameData_O_i[12]),
    .X(FrameData_O[12])
);

my_buf data_outbuf_13 (
    .A(FrameData_O_i[13]),
    .X(FrameData_O[13])
);

my_buf data_outbuf_14 (
    .A(FrameData_O_i[14]),
    .X(FrameData_O[14])
);

my_buf data_outbuf_15 (
    .A(FrameData_O_i[15]),
    .X(FrameData_O[15])
);

my_buf data_outbuf_16 (
    .A(FrameData_O_i[16]),
    .X(FrameData_O[16])
);

my_buf data_outbuf_17 (
    .A(FrameData_O_i[17]),
    .X(FrameData_O[17])
);

my_buf data_outbuf_18 (
    .A(FrameData_O_i[18]),
    .X(FrameData_O[18])
);

my_buf data_outbuf_19 (
    .A(FrameData_O_i[19]),
    .X(FrameData_O[19])
);

my_buf data_outbuf_20 (
    .A(FrameData_O_i[20]),
    .X(FrameData_O[20])
);

my_buf data_outbuf_21 (
    .A(FrameData_O_i[21]),
    .X(FrameData_O[21])
);

my_buf data_outbuf_22 (
    .A(FrameData_O_i[22]),
    .X(FrameData_O[22])
);

my_buf data_outbuf_23 (
    .A(FrameData_O_i[23]),
    .X(FrameData_O[23])
);

my_buf data_outbuf_24 (
    .A(FrameData_O_i[24]),
    .X(FrameData_O[24])
);

my_buf data_outbuf_25 (
    .A(FrameData_O_i[25]),
    .X(FrameData_O[25])
);

my_buf data_outbuf_26 (
    .A(FrameData_O_i[26]),
    .X(FrameData_O[26])
);

my_buf data_outbuf_27 (
    .A(FrameData_O_i[27]),
    .X(FrameData_O[27])
);

my_buf data_outbuf_28 (
    .A(FrameData_O_i[28]),
    .X(FrameData_O[28])
);

my_buf data_outbuf_29 (
    .A(FrameData_O_i[29]),
    .X(FrameData_O[29])
);

my_buf data_outbuf_30 (
    .A(FrameData_O_i[30]),
    .X(FrameData_O[30])
);

my_buf data_outbuf_31 (
    .A(FrameData_O_i[31]),
    .X(FrameData_O[31])
);

assign FrameStrobe_O_i = FrameStrobe_i;

my_buf strobe_inbuf_0 (
    .A(FrameStrobe[0]),
    .X(FrameStrobe_i[0])
);

my_buf strobe_inbuf_1 (
    .A(FrameStrobe[1]),
    .X(FrameStrobe_i[1])
);

my_buf strobe_inbuf_2 (
    .A(FrameStrobe[2]),
    .X(FrameStrobe_i[2])
);

my_buf strobe_inbuf_3 (
    .A(FrameStrobe[3]),
    .X(FrameStrobe_i[3])
);

my_buf strobe_inbuf_4 (
    .A(FrameStrobe[4]),
    .X(FrameStrobe_i[4])
);

my_buf strobe_inbuf_5 (
    .A(FrameStrobe[5]),
    .X(FrameStrobe_i[5])
);

my_buf strobe_inbuf_6 (
    .A(FrameStrobe[6]),
    .X(FrameStrobe_i[6])
);

my_buf strobe_inbuf_7 (
    .A(FrameStrobe[7]),
    .X(FrameStrobe_i[7])
);

my_buf strobe_inbuf_8 (
    .A(FrameStrobe[8]),
    .X(FrameStrobe_i[8])
);

my_buf strobe_inbuf_9 (
    .A(FrameStrobe[9]),
    .X(FrameStrobe_i[9])
);

my_buf strobe_inbuf_10 (
    .A(FrameStrobe[10]),
    .X(FrameStrobe_i[10])
);

my_buf strobe_inbuf_11 (
    .A(FrameStrobe[11]),
    .X(FrameStrobe_i[11])
);

my_buf strobe_inbuf_12 (
    .A(FrameStrobe[12]),
    .X(FrameStrobe_i[12])
);

my_buf strobe_inbuf_13 (
    .A(FrameStrobe[13]),
    .X(FrameStrobe_i[13])
);

my_buf strobe_inbuf_14 (
    .A(FrameStrobe[14]),
    .X(FrameStrobe_i[14])
);

my_buf strobe_inbuf_15 (
    .A(FrameStrobe[15]),
    .X(FrameStrobe_i[15])
);

my_buf strobe_inbuf_16 (
    .A(FrameStrobe[16]),
    .X(FrameStrobe_i[16])
);

my_buf strobe_inbuf_17 (
    .A(FrameStrobe[17]),
    .X(FrameStrobe_i[17])
);

my_buf strobe_inbuf_18 (
    .A(FrameStrobe[18]),
    .X(FrameStrobe_i[18])
);

my_buf strobe_inbuf_19 (
    .A(FrameStrobe[19]),
    .X(FrameStrobe_i[19])
);

my_buf strobe_outbuf_0 (
    .A(FrameStrobe_O_i[0]),
    .X(FrameStrobe_O[0])
);

my_buf strobe_outbuf_1 (
    .A(FrameStrobe_O_i[1]),
    .X(FrameStrobe_O[1])
);

my_buf strobe_outbuf_2 (
    .A(FrameStrobe_O_i[2]),
    .X(FrameStrobe_O[2])
);

my_buf strobe_outbuf_3 (
    .A(FrameStrobe_O_i[3]),
    .X(FrameStrobe_O[3])
);

my_buf strobe_outbuf_4 (
    .A(FrameStrobe_O_i[4]),
    .X(FrameStrobe_O[4])
);

my_buf strobe_outbuf_5 (
    .A(FrameStrobe_O_i[5]),
    .X(FrameStrobe_O[5])
);

my_buf strobe_outbuf_6 (
    .A(FrameStrobe_O_i[6]),
    .X(FrameStrobe_O[6])
);

my_buf strobe_outbuf_7 (
    .A(FrameStrobe_O_i[7]),
    .X(FrameStrobe_O[7])
);

my_buf strobe_outbuf_8 (
    .A(FrameStrobe_O_i[8]),
    .X(FrameStrobe_O[8])
);

my_buf strobe_outbuf_9 (
    .A(FrameStrobe_O_i[9]),
    .X(FrameStrobe_O[9])
);

my_buf strobe_outbuf_10 (
    .A(FrameStrobe_O_i[10]),
    .X(FrameStrobe_O[10])
);

my_buf strobe_outbuf_11 (
    .A(FrameStrobe_O_i[11]),
    .X(FrameStrobe_O[11])
);

my_buf strobe_outbuf_12 (
    .A(FrameStrobe_O_i[12]),
    .X(FrameStrobe_O[12])
);

my_buf strobe_outbuf_13 (
    .A(FrameStrobe_O_i[13]),
    .X(FrameStrobe_O[13])
);

my_buf strobe_outbuf_14 (
    .A(FrameStrobe_O_i[14]),
    .X(FrameStrobe_O[14])
);

my_buf strobe_outbuf_15 (
    .A(FrameStrobe_O_i[15]),
    .X(FrameStrobe_O[15])
);

my_buf strobe_outbuf_16 (
    .A(FrameStrobe_O_i[16]),
    .X(FrameStrobe_O[16])
);

my_buf strobe_outbuf_17 (
    .A(FrameStrobe_O_i[17]),
    .X(FrameStrobe_O[17])
);

my_buf strobe_outbuf_18 (
    .A(FrameStrobe_O_i[18]),
    .X(FrameStrobe_O[18])
);

my_buf strobe_outbuf_19 (
    .A(FrameStrobe_O_i[19]),
    .X(FrameStrobe_O[19])
);


 //configuration storage latches
S_IO4_ConfigMem
`ifdef EMULATION
    #(
    .Emulate_Bitstream(Emulate_Bitstream)
    )
`endif
    Inst_S_IO4_ConfigMem
    (
    .FrameData(FrameData),
    .FrameStrobe(FrameStrobe),
    .ConfigBits(ConfigBits),
    .ConfigBits_N(ConfigBits_N)
);


 //BEL component instantiations
IOBUF Inst_A_IOBUF (
    .CLK(A_CLK),
    .IN(A_IN),
    .EN(A_EN),
    .OUT(A_OUT),
    .IN_top(A_IN_top),
    .EN_top(A_EN_top),
    .OUT_top(A_OUT_top),
    .ConfigBits(ConfigBits[3-1:0])
);

IOBUF Inst_B_IOBUF (
    .CLK(B_CLK),
    .IN(B_IN),
    .EN(B_EN),
    .OUT(B_OUT),
    .IN_top(B_IN_top),
    .EN_top(B_EN_top),
    .OUT_top(B_OUT_top),
    .ConfigBits(ConfigBits[6-1:3])
);

IOBUF Inst_C_IOBUF (
    .CLK(C_CLK),
    .IN(C_IN),
    .EN(C_EN),
    .OUT(C_OUT),
    .IN_top(C_IN_top),
    .EN_top(C_EN_top),
    .OUT_top(C_OUT_top),
    .ConfigBits(ConfigBits[9-1:6])
);

IOBUF Inst_D_IOBUF (
    .CLK(D_CLK),
    .IN(D_IN),
    .EN(D_EN),
    .OUT(D_OUT),
    .IN_top(D_IN_top),
    .EN_top(D_EN_top),
    .OUT_top(D_OUT_top),
    .ConfigBits(ConfigBits[12-1:9])
);

S_IO4_switch_matrix Inst_S_IO4_switch_matrix (
    .W_GBUF_FEED_END0(W_GBUF_FEED_END[0]),
    .W_GBUF_FEED_END1(W_GBUF_FEED_END[1]),
    .W_GBUF_FEED_END2(W_GBUF_FEED_END[2]),
    .W_GBUF_FEED_END3(W_GBUF_FEED_END[3]),
    .E_GBUF_END0(E_GBUF_END[0]),
    .E_GBUF_END1(E_GBUF_END[1]),
    .E_GBUF_END2(E_GBUF_END[2]),
    .E_GBUF_END3(E_GBUF_END[3]),
    .S1END0(S1END[0]),
    .S1END1(S1END[1]),
    .S1END2(S1END[2]),
    .S1END3(S1END[3]),
    .S1END4(S1END[4]),
    .S1END5(S1END[5]),
    .S1END6(S1END[6]),
    .S1END7(S1END[7]),
    .S2MID0(S2MID[0]),
    .S2MID1(S2MID[1]),
    .S2MID2(S2MID[2]),
    .S2MID3(S2MID[3]),
    .S2MID4(S2MID[4]),
    .S2MID5(S2MID[5]),
    .S2MID6(S2MID[6]),
    .S2MID7(S2MID[7]),
    .S2END0(S2END[0]),
    .S2END1(S2END[1]),
    .S2END2(S2END[2]),
    .S2END3(S2END[3]),
    .S2END4(S2END[4]),
    .S2END5(S2END[5]),
    .S2END6(S2END[6]),
    .S2END7(S2END[7]),
    .A_OUT(A_OUT),
    .B_OUT(B_OUT),
    .C_OUT(C_OUT),
    .D_OUT(D_OUT),
    .W_GBUF_FEED_BEG0(W_GBUF_FEED_BEG[0]),
    .W_GBUF_FEED_BEG1(W_GBUF_FEED_BEG[1]),
    .W_GBUF_FEED_BEG2(W_GBUF_FEED_BEG[2]),
    .W_GBUF_FEED_BEG3(W_GBUF_FEED_BEG[3]),
    .N_GBUF_BEG0(N_GBUF_BEG[0]),
    .N_GBUF_BEG1(N_GBUF_BEG[1]),
    .N_GBUF_BEG2(N_GBUF_BEG[2]),
    .N_GBUF_BEG3(N_GBUF_BEG[3]),
    .E_GBUF_BEG0(E_GBUF_BEG[0]),
    .E_GBUF_BEG1(E_GBUF_BEG[1]),
    .E_GBUF_BEG2(E_GBUF_BEG[2]),
    .E_GBUF_BEG3(E_GBUF_BEG[3]),
    .N1BEG0(N1BEG[0]),
    .N1BEG1(N1BEG[1]),
    .N1BEG2(N1BEG[2]),
    .N1BEG3(N1BEG[3]),
    .N1BEG4(N1BEG[4]),
    .N1BEG5(N1BEG[5]),
    .N1BEG6(N1BEG[6]),
    .N1BEG7(N1BEG[7]),
    .N2BEG0(N2BEG[0]),
    .N2BEG1(N2BEG[1]),
    .N2BEG2(N2BEG[2]),
    .N2BEG3(N2BEG[3]),
    .N2BEG4(N2BEG[4]),
    .N2BEG5(N2BEG[5]),
    .N2BEG6(N2BEG[6]),
    .N2BEG7(N2BEG[7]),
    .N2BEGb0(N2BEGb[0]),
    .N2BEGb1(N2BEGb[1]),
    .N2BEGb2(N2BEGb[2]),
    .N2BEGb3(N2BEGb[3]),
    .N2BEGb4(N2BEGb[4]),
    .N2BEGb5(N2BEGb[5]),
    .N2BEGb6(N2BEGb[6]),
    .N2BEGb7(N2BEGb[7]),
    .Co0(Co[0]),
    .A_CLK(A_CLK),
    .A_IN(A_IN),
    .A_EN(A_EN),
    .B_CLK(B_CLK),
    .B_IN(B_IN),
    .B_EN(B_EN),
    .C_CLK(C_CLK),
    .C_IN(C_IN),
    .C_EN(C_EN),
    .D_CLK(D_CLK),
    .D_IN(D_IN),
    .D_EN(D_EN),
    .ConfigBits(ConfigBits[108-1:12]),
    .ConfigBits_N(ConfigBits_N[108-1:12])
);

endmodule
module S_IO_ConfigMem
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=68
    )
    (
        input  [FrameBitsPerRow - 1:0] FrameData,
        input  [MaxFramesPerCol - 1:0] FrameStrobe,
        output  [NoConfigBits - 1:0] ConfigBits,
        output  [NoConfigBits - 1:0] ConfigBits_N
    );

`ifdef EMULATION
assign ConfigBits[67] = Emulate_Bitstream[31];
assign ConfigBits[66] = Emulate_Bitstream[30];
assign ConfigBits[65] = Emulate_Bitstream[29];
assign ConfigBits[64] = Emulate_Bitstream[28];
assign ConfigBits[63] = Emulate_Bitstream[27];
assign ConfigBits[62] = Emulate_Bitstream[26];
assign ConfigBits[61] = Emulate_Bitstream[25];
assign ConfigBits[60] = Emulate_Bitstream[24];
assign ConfigBits[59] = Emulate_Bitstream[23];
assign ConfigBits[58] = Emulate_Bitstream[22];
assign ConfigBits[57] = Emulate_Bitstream[21];
assign ConfigBits[56] = Emulate_Bitstream[20];
assign ConfigBits[55] = Emulate_Bitstream[19];
assign ConfigBits[54] = Emulate_Bitstream[18];
assign ConfigBits[53] = Emulate_Bitstream[17];
assign ConfigBits[52] = Emulate_Bitstream[16];
assign ConfigBits[51] = Emulate_Bitstream[15];
assign ConfigBits[50] = Emulate_Bitstream[14];
assign ConfigBits[49] = Emulate_Bitstream[13];
assign ConfigBits[48] = Emulate_Bitstream[12];
assign ConfigBits[47] = Emulate_Bitstream[11];
assign ConfigBits[46] = Emulate_Bitstream[10];
assign ConfigBits[45] = Emulate_Bitstream[9];
assign ConfigBits[44] = Emulate_Bitstream[8];
assign ConfigBits[43] = Emulate_Bitstream[7];
assign ConfigBits[42] = Emulate_Bitstream[6];
assign ConfigBits[41] = Emulate_Bitstream[5];
assign ConfigBits[40] = Emulate_Bitstream[4];
assign ConfigBits[39] = Emulate_Bitstream[3];
assign ConfigBits[38] = Emulate_Bitstream[2];
assign ConfigBits[37] = Emulate_Bitstream[1];
assign ConfigBits[36] = Emulate_Bitstream[0];
assign ConfigBits[35] = Emulate_Bitstream[63];
assign ConfigBits[34] = Emulate_Bitstream[62];
assign ConfigBits[33] = Emulate_Bitstream[61];
assign ConfigBits[32] = Emulate_Bitstream[60];
assign ConfigBits[31] = Emulate_Bitstream[59];
assign ConfigBits[30] = Emulate_Bitstream[58];
assign ConfigBits[29] = Emulate_Bitstream[57];
assign ConfigBits[28] = Emulate_Bitstream[56];
assign ConfigBits[27] = Emulate_Bitstream[55];
assign ConfigBits[26] = Emulate_Bitstream[54];
assign ConfigBits[25] = Emulate_Bitstream[53];
assign ConfigBits[24] = Emulate_Bitstream[52];
assign ConfigBits[23] = Emulate_Bitstream[51];
assign ConfigBits[22] = Emulate_Bitstream[50];
assign ConfigBits[21] = Emulate_Bitstream[49];
assign ConfigBits[20] = Emulate_Bitstream[48];
assign ConfigBits[19] = Emulate_Bitstream[47];
assign ConfigBits[18] = Emulate_Bitstream[46];
assign ConfigBits[17] = Emulate_Bitstream[45];
assign ConfigBits[16] = Emulate_Bitstream[44];
assign ConfigBits[15] = Emulate_Bitstream[43];
assign ConfigBits[14] = Emulate_Bitstream[42];
assign ConfigBits[13] = Emulate_Bitstream[41];
assign ConfigBits[12] = Emulate_Bitstream[40];
assign ConfigBits[11] = Emulate_Bitstream[39];
assign ConfigBits[10] = Emulate_Bitstream[38];
assign ConfigBits[9] = Emulate_Bitstream[37];
assign ConfigBits[8] = Emulate_Bitstream[36];
assign ConfigBits[7] = Emulate_Bitstream[35];
assign ConfigBits[6] = Emulate_Bitstream[34];
assign ConfigBits[5] = Emulate_Bitstream[33];
assign ConfigBits[4] = Emulate_Bitstream[32];
assign ConfigBits[3] = Emulate_Bitstream[95];
assign ConfigBits[2] = Emulate_Bitstream[94];
assign ConfigBits[1] = Emulate_Bitstream[93];
assign ConfigBits[0] = Emulate_Bitstream[92];
`else

 //instantiate frame latches
config_latch Inst_frame0_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[67]),
    .QN(ConfigBits_N[67])
);

config_latch Inst_frame0_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[66]),
    .QN(ConfigBits_N[66])
);

config_latch Inst_frame0_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[65]),
    .QN(ConfigBits_N[65])
);

config_latch Inst_frame0_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[64]),
    .QN(ConfigBits_N[64])
);

config_latch Inst_frame0_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[63]),
    .QN(ConfigBits_N[63])
);

config_latch Inst_frame0_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[62]),
    .QN(ConfigBits_N[62])
);

config_latch Inst_frame0_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[61]),
    .QN(ConfigBits_N[61])
);

config_latch Inst_frame0_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[60]),
    .QN(ConfigBits_N[60])
);

config_latch Inst_frame0_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[59]),
    .QN(ConfigBits_N[59])
);

config_latch Inst_frame0_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[58]),
    .QN(ConfigBits_N[58])
);

config_latch Inst_frame0_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[57]),
    .QN(ConfigBits_N[57])
);

config_latch Inst_frame0_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[56]),
    .QN(ConfigBits_N[56])
);

config_latch Inst_frame0_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[55]),
    .QN(ConfigBits_N[55])
);

config_latch Inst_frame0_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[54]),
    .QN(ConfigBits_N[54])
);

config_latch Inst_frame0_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[53]),
    .QN(ConfigBits_N[53])
);

config_latch Inst_frame0_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[52]),
    .QN(ConfigBits_N[52])
);

config_latch Inst_frame0_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[51]),
    .QN(ConfigBits_N[51])
);

config_latch Inst_frame0_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[50]),
    .QN(ConfigBits_N[50])
);

config_latch Inst_frame0_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[49]),
    .QN(ConfigBits_N[49])
);

config_latch Inst_frame0_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[48]),
    .QN(ConfigBits_N[48])
);

config_latch Inst_frame0_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[47]),
    .QN(ConfigBits_N[47])
);

config_latch Inst_frame0_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[46]),
    .QN(ConfigBits_N[46])
);

config_latch Inst_frame0_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[45]),
    .QN(ConfigBits_N[45])
);

config_latch Inst_frame0_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[44]),
    .QN(ConfigBits_N[44])
);

config_latch Inst_frame0_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[43]),
    .QN(ConfigBits_N[43])
);

config_latch Inst_frame0_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[42]),
    .QN(ConfigBits_N[42])
);

config_latch Inst_frame0_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[41]),
    .QN(ConfigBits_N[41])
);

config_latch Inst_frame0_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[40]),
    .QN(ConfigBits_N[40])
);

config_latch Inst_frame0_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[39]),
    .QN(ConfigBits_N[39])
);

config_latch Inst_frame0_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[38]),
    .QN(ConfigBits_N[38])
);

config_latch Inst_frame0_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[37]),
    .QN(ConfigBits_N[37])
);

config_latch Inst_frame0_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[36]),
    .QN(ConfigBits_N[36])
);

config_latch Inst_frame1_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[35]),
    .QN(ConfigBits_N[35])
);

config_latch Inst_frame1_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[34]),
    .QN(ConfigBits_N[34])
);

config_latch Inst_frame1_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[33]),
    .QN(ConfigBits_N[33])
);

config_latch Inst_frame1_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[32]),
    .QN(ConfigBits_N[32])
);

config_latch Inst_frame1_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[31]),
    .QN(ConfigBits_N[31])
);

config_latch Inst_frame1_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[30]),
    .QN(ConfigBits_N[30])
);

config_latch Inst_frame1_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[29]),
    .QN(ConfigBits_N[29])
);

config_latch Inst_frame1_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[28]),
    .QN(ConfigBits_N[28])
);

config_latch Inst_frame1_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[27]),
    .QN(ConfigBits_N[27])
);

config_latch Inst_frame1_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[26]),
    .QN(ConfigBits_N[26])
);

config_latch Inst_frame1_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[25]),
    .QN(ConfigBits_N[25])
);

config_latch Inst_frame1_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[24]),
    .QN(ConfigBits_N[24])
);

config_latch Inst_frame1_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[23]),
    .QN(ConfigBits_N[23])
);

config_latch Inst_frame1_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[22]),
    .QN(ConfigBits_N[22])
);

config_latch Inst_frame1_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[21]),
    .QN(ConfigBits_N[21])
);

config_latch Inst_frame1_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[20]),
    .QN(ConfigBits_N[20])
);

config_latch Inst_frame1_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[19]),
    .QN(ConfigBits_N[19])
);

config_latch Inst_frame1_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[18]),
    .QN(ConfigBits_N[18])
);

config_latch Inst_frame1_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[17]),
    .QN(ConfigBits_N[17])
);

config_latch Inst_frame1_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[16]),
    .QN(ConfigBits_N[16])
);

config_latch Inst_frame1_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[15]),
    .QN(ConfigBits_N[15])
);

config_latch Inst_frame1_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[14]),
    .QN(ConfigBits_N[14])
);

config_latch Inst_frame1_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[13]),
    .QN(ConfigBits_N[13])
);

config_latch Inst_frame1_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[12]),
    .QN(ConfigBits_N[12])
);

config_latch Inst_frame1_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[11]),
    .QN(ConfigBits_N[11])
);

config_latch Inst_frame1_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[10]),
    .QN(ConfigBits_N[10])
);

config_latch Inst_frame1_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[9]),
    .QN(ConfigBits_N[9])
);

config_latch Inst_frame1_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[8]),
    .QN(ConfigBits_N[8])
);

config_latch Inst_frame1_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[7]),
    .QN(ConfigBits_N[7])
);

config_latch Inst_frame1_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[6]),
    .QN(ConfigBits_N[6])
);

config_latch Inst_frame1_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[5]),
    .QN(ConfigBits_N[5])
);

config_latch Inst_frame1_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[4]),
    .QN(ConfigBits_N[4])
);

config_latch Inst_frame2_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[3]),
    .QN(ConfigBits_N[3])
);

config_latch Inst_frame2_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[2]),
    .QN(ConfigBits_N[2])
);

config_latch Inst_frame2_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[1]),
    .QN(ConfigBits_N[1])
);

config_latch Inst_frame2_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[0]),
    .QN(ConfigBits_N[0])
);

`endif
endmodule
 // NumberOfConfigBits: 65
module S_IO_switch_matrix
    #(
        parameter NoConfigBits=65
    )
    (
        input  W_GBUF_FEED_END0,
        input  W_GBUF_FEED_END1,
        input  W_GBUF_FEED_END2,
        input  W_GBUF_FEED_END3,
        input  E_GBUF_END0,
        input  E_GBUF_END1,
        input  E_GBUF_END2,
        input  E_GBUF_END3,
        input  S1END0,
        input  S1END1,
        input  S1END2,
        input  S1END3,
        input  S1END4,
        input  S1END5,
        input  S1END6,
        input  S1END7,
        input  S2MID0,
        input  S2MID1,
        input  S2MID2,
        input  S2MID3,
        input  S2MID4,
        input  S2MID5,
        input  S2MID6,
        input  S2MID7,
        input  S2END0,
        input  S2END1,
        input  S2END2,
        input  S2END3,
        input  S2END4,
        input  S2END5,
        input  S2END6,
        input  S2END7,
        input  A_OUT,
        output  W_GBUF_FEED_BEG0,
        output  W_GBUF_FEED_BEG1,
        output  W_GBUF_FEED_BEG2,
        output  W_GBUF_FEED_BEG3,
        output  N_GBUF_BEG0,
        output  N_GBUF_BEG1,
        output  N_GBUF_BEG2,
        output  N_GBUF_BEG3,
        output  E_GBUF_BEG0,
        output  E_GBUF_BEG1,
        output  E_GBUF_BEG2,
        output  E_GBUF_BEG3,
        output  N1BEG0,
        output  N1BEG1,
        output  N1BEG2,
        output  N1BEG3,
        output  N1BEG4,
        output  N1BEG5,
        output  N1BEG6,
        output  N1BEG7,
        output  N2BEG0,
        output  N2BEG1,
        output  N2BEG2,
        output  N2BEG3,
        output  N2BEG4,
        output  N2BEG5,
        output  N2BEG6,
        output  N2BEG7,
        output  N2BEGb0,
        output  N2BEGb1,
        output  N2BEGb2,
        output  N2BEGb3,
        output  N2BEGb4,
        output  N2BEGb5,
        output  N2BEGb6,
        output  N2BEGb7,
        output  Co0,
        output  A_CLK,
        output  A_IN,
        output  A_EN,
 //global
        input  [NoConfigBits-1:0] ConfigBits,
        input  [NoConfigBits-1:0] ConfigBits_N
);
parameter GND0 = 1'b0;
parameter GND = 1'b0;
parameter VCC0 = 1'b1;
parameter VCC = 1'b1;
parameter VDD0 = 1'b1;
parameter VDD = 1'b1;

wire[4-1:0] W_GBUF_FEED_BEG0_input;
wire[4-1:0] W_GBUF_FEED_BEG1_input;
wire[4-1:0] W_GBUF_FEED_BEG2_input;
wire[4-1:0] W_GBUF_FEED_BEG3_input;
wire[4-1:0] N1BEG0_input;
wire[4-1:0] N1BEG1_input;
wire[4-1:0] N1BEG2_input;
wire[4-1:0] N1BEG3_input;
wire[4-1:0] N1BEG4_input;
wire[4-1:0] N1BEG5_input;
wire[4-1:0] N1BEG6_input;
wire[4-1:0] N1BEG7_input;
wire[4-1:0] N2BEG0_input;
wire[4-1:0] N2BEG1_input;
wire[4-1:0] N2BEG2_input;
wire[4-1:0] N2BEG3_input;
wire[4-1:0] N2BEG4_input;
wire[4-1:0] N2BEG5_input;
wire[4-1:0] N2BEG6_input;
wire[4-1:0] N2BEG7_input;
wire[4-1:0] N2BEGb0_input;
wire[4-1:0] N2BEGb1_input;
wire[4-1:0] N2BEGb2_input;
wire[4-1:0] N2BEGb3_input;
wire[4-1:0] N2BEGb4_input;
wire[4-1:0] N2BEGb5_input;
wire[4-1:0] N2BEGb6_input;
wire[4-1:0] N2BEGb7_input;
wire[4-1:0] A_CLK_input;
wire[16-1:0] A_IN_input;
wire[8-1:0] A_EN_input;
 //The configuration bits (if any) are just a long shift register
 //This shift register is padded to an even number of flops/latches
 //switch matrix multiplexer W_GBUF_FEED_BEG0 MUX-4
assign W_GBUF_FEED_BEG0_input = {A_OUT,S2END7,S1END1,W_GBUF_FEED_END0};
cus_mux41 inst_cus_mux41_W_GBUF_FEED_BEG0 (
    .A0(W_GBUF_FEED_BEG0_input[0]),
    .A1(W_GBUF_FEED_BEG0_input[1]),
    .A2(W_GBUF_FEED_BEG0_input[2]),
    .A3(W_GBUF_FEED_BEG0_input[3]),
    .S0(ConfigBits[0+0]),
    .S0N(ConfigBits_N[0+0]),
    .S1(ConfigBits[0+1]),
    .S1N(ConfigBits_N[0+1]),
    .X(W_GBUF_FEED_BEG0)
);

 //switch matrix multiplexer W_GBUF_FEED_BEG1 MUX-4
assign W_GBUF_FEED_BEG1_input = {A_OUT,S2END6,S1END2,W_GBUF_FEED_END1};
cus_mux41 inst_cus_mux41_W_GBUF_FEED_BEG1 (
    .A0(W_GBUF_FEED_BEG1_input[0]),
    .A1(W_GBUF_FEED_BEG1_input[1]),
    .A2(W_GBUF_FEED_BEG1_input[2]),
    .A3(W_GBUF_FEED_BEG1_input[3]),
    .S0(ConfigBits[2+0]),
    .S0N(ConfigBits_N[2+0]),
    .S1(ConfigBits[2+1]),
    .S1N(ConfigBits_N[2+1]),
    .X(W_GBUF_FEED_BEG1)
);

 //switch matrix multiplexer W_GBUF_FEED_BEG2 MUX-4
assign W_GBUF_FEED_BEG2_input = {A_OUT,S2END5,S1END3,W_GBUF_FEED_END2};
cus_mux41 inst_cus_mux41_W_GBUF_FEED_BEG2 (
    .A0(W_GBUF_FEED_BEG2_input[0]),
    .A1(W_GBUF_FEED_BEG2_input[1]),
    .A2(W_GBUF_FEED_BEG2_input[2]),
    .A3(W_GBUF_FEED_BEG2_input[3]),
    .S0(ConfigBits[4+0]),
    .S0N(ConfigBits_N[4+0]),
    .S1(ConfigBits[4+1]),
    .S1N(ConfigBits_N[4+1]),
    .X(W_GBUF_FEED_BEG2)
);

 //switch matrix multiplexer W_GBUF_FEED_BEG3 MUX-4
assign W_GBUF_FEED_BEG3_input = {A_OUT,S2END4,S1END0,W_GBUF_FEED_END3};
cus_mux41 inst_cus_mux41_W_GBUF_FEED_BEG3 (
    .A0(W_GBUF_FEED_BEG3_input[0]),
    .A1(W_GBUF_FEED_BEG3_input[1]),
    .A2(W_GBUF_FEED_BEG3_input[2]),
    .A3(W_GBUF_FEED_BEG3_input[3]),
    .S0(ConfigBits[6+0]),
    .S0N(ConfigBits_N[6+0]),
    .S1(ConfigBits[6+1]),
    .S1N(ConfigBits_N[6+1]),
    .X(W_GBUF_FEED_BEG3)
);

 //switch matrix multiplexer N_GBUF_BEG0 MUX-1
assign N_GBUF_BEG0 = E_GBUF_END0;

 //switch matrix multiplexer N_GBUF_BEG1 MUX-1
assign N_GBUF_BEG1 = E_GBUF_END1;

 //switch matrix multiplexer N_GBUF_BEG2 MUX-1
assign N_GBUF_BEG2 = E_GBUF_END2;

 //switch matrix multiplexer N_GBUF_BEG3 MUX-1
assign N_GBUF_BEG3 = E_GBUF_END3;

 //switch matrix multiplexer E_GBUF_BEG0 MUX-1
assign E_GBUF_BEG0 = E_GBUF_END0;

 //switch matrix multiplexer E_GBUF_BEG1 MUX-1
assign E_GBUF_BEG1 = E_GBUF_END1;

 //switch matrix multiplexer E_GBUF_BEG2 MUX-1
assign E_GBUF_BEG2 = E_GBUF_END2;

 //switch matrix multiplexer E_GBUF_BEG3 MUX-1
assign E_GBUF_BEG3 = E_GBUF_END3;

 //switch matrix multiplexer N1BEG0 MUX-4
assign N1BEG0_input = {A_OUT,S2END7,S2MID7,S1END7};
cus_mux41 inst_cus_mux41_N1BEG0 (
    .A0(N1BEG0_input[0]),
    .A1(N1BEG0_input[1]),
    .A2(N1BEG0_input[2]),
    .A3(N1BEG0_input[3]),
    .S0(ConfigBits[8+0]),
    .S0N(ConfigBits_N[8+0]),
    .S1(ConfigBits[8+1]),
    .S1N(ConfigBits_N[8+1]),
    .X(N1BEG0)
);

 //switch matrix multiplexer N1BEG1 MUX-4
assign N1BEG1_input = {A_OUT,S2END6,S2MID6,S1END6};
cus_mux41 inst_cus_mux41_N1BEG1 (
    .A0(N1BEG1_input[0]),
    .A1(N1BEG1_input[1]),
    .A2(N1BEG1_input[2]),
    .A3(N1BEG1_input[3]),
    .S0(ConfigBits[10+0]),
    .S0N(ConfigBits_N[10+0]),
    .S1(ConfigBits[10+1]),
    .S1N(ConfigBits_N[10+1]),
    .X(N1BEG1)
);

 //switch matrix multiplexer N1BEG2 MUX-4
assign N1BEG2_input = {A_OUT,S2END5,S2MID5,S1END5};
cus_mux41 inst_cus_mux41_N1BEG2 (
    .A0(N1BEG2_input[0]),
    .A1(N1BEG2_input[1]),
    .A2(N1BEG2_input[2]),
    .A3(N1BEG2_input[3]),
    .S0(ConfigBits[12+0]),
    .S0N(ConfigBits_N[12+0]),
    .S1(ConfigBits[12+1]),
    .S1N(ConfigBits_N[12+1]),
    .X(N1BEG2)
);

 //switch matrix multiplexer N1BEG3 MUX-4
assign N1BEG3_input = {A_OUT,S2END4,S2MID4,S1END4};
cus_mux41 inst_cus_mux41_N1BEG3 (
    .A0(N1BEG3_input[0]),
    .A1(N1BEG3_input[1]),
    .A2(N1BEG3_input[2]),
    .A3(N1BEG3_input[3]),
    .S0(ConfigBits[14+0]),
    .S0N(ConfigBits_N[14+0]),
    .S1(ConfigBits[14+1]),
    .S1N(ConfigBits_N[14+1]),
    .X(N1BEG3)
);

 //switch matrix multiplexer N1BEG4 MUX-4
assign N1BEG4_input = {A_OUT,S2END3,S2MID3,S1END3};
cus_mux41 inst_cus_mux41_N1BEG4 (
    .A0(N1BEG4_input[0]),
    .A1(N1BEG4_input[1]),
    .A2(N1BEG4_input[2]),
    .A3(N1BEG4_input[3]),
    .S0(ConfigBits[16+0]),
    .S0N(ConfigBits_N[16+0]),
    .S1(ConfigBits[16+1]),
    .S1N(ConfigBits_N[16+1]),
    .X(N1BEG4)
);

 //switch matrix multiplexer N1BEG5 MUX-4
assign N1BEG5_input = {A_OUT,S2END2,S2MID2,S1END2};
cus_mux41 inst_cus_mux41_N1BEG5 (
    .A0(N1BEG5_input[0]),
    .A1(N1BEG5_input[1]),
    .A2(N1BEG5_input[2]),
    .A3(N1BEG5_input[3]),
    .S0(ConfigBits[18+0]),
    .S0N(ConfigBits_N[18+0]),
    .S1(ConfigBits[18+1]),
    .S1N(ConfigBits_N[18+1]),
    .X(N1BEG5)
);

 //switch matrix multiplexer N1BEG6 MUX-4
assign N1BEG6_input = {A_OUT,S2END1,S2MID1,S1END1};
cus_mux41 inst_cus_mux41_N1BEG6 (
    .A0(N1BEG6_input[0]),
    .A1(N1BEG6_input[1]),
    .A2(N1BEG6_input[2]),
    .A3(N1BEG6_input[3]),
    .S0(ConfigBits[20+0]),
    .S0N(ConfigBits_N[20+0]),
    .S1(ConfigBits[20+1]),
    .S1N(ConfigBits_N[20+1]),
    .X(N1BEG6)
);

 //switch matrix multiplexer N1BEG7 MUX-4
assign N1BEG7_input = {A_OUT,S2END0,S2MID0,S1END0};
cus_mux41 inst_cus_mux41_N1BEG7 (
    .A0(N1BEG7_input[0]),
    .A1(N1BEG7_input[1]),
    .A2(N1BEG7_input[2]),
    .A3(N1BEG7_input[3]),
    .S0(ConfigBits[22+0]),
    .S0N(ConfigBits_N[22+0]),
    .S1(ConfigBits[22+1]),
    .S1N(ConfigBits_N[22+1]),
    .X(N1BEG7)
);

 //switch matrix multiplexer N2BEG0 MUX-4
assign N2BEG0_input = {A_OUT,S2END7,S2MID7,S1END7};
cus_mux41 inst_cus_mux41_N2BEG0 (
    .A0(N2BEG0_input[0]),
    .A1(N2BEG0_input[1]),
    .A2(N2BEG0_input[2]),
    .A3(N2BEG0_input[3]),
    .S0(ConfigBits[24+0]),
    .S0N(ConfigBits_N[24+0]),
    .S1(ConfigBits[24+1]),
    .S1N(ConfigBits_N[24+1]),
    .X(N2BEG0)
);

 //switch matrix multiplexer N2BEG1 MUX-4
assign N2BEG1_input = {A_OUT,S2END6,S2MID6,S1END6};
cus_mux41 inst_cus_mux41_N2BEG1 (
    .A0(N2BEG1_input[0]),
    .A1(N2BEG1_input[1]),
    .A2(N2BEG1_input[2]),
    .A3(N2BEG1_input[3]),
    .S0(ConfigBits[26+0]),
    .S0N(ConfigBits_N[26+0]),
    .S1(ConfigBits[26+1]),
    .S1N(ConfigBits_N[26+1]),
    .X(N2BEG1)
);

 //switch matrix multiplexer N2BEG2 MUX-4
assign N2BEG2_input = {A_OUT,S2END5,S2MID5,S1END5};
cus_mux41 inst_cus_mux41_N2BEG2 (
    .A0(N2BEG2_input[0]),
    .A1(N2BEG2_input[1]),
    .A2(N2BEG2_input[2]),
    .A3(N2BEG2_input[3]),
    .S0(ConfigBits[28+0]),
    .S0N(ConfigBits_N[28+0]),
    .S1(ConfigBits[28+1]),
    .S1N(ConfigBits_N[28+1]),
    .X(N2BEG2)
);

 //switch matrix multiplexer N2BEG3 MUX-4
assign N2BEG3_input = {A_OUT,S2END4,S2MID4,S1END4};
cus_mux41 inst_cus_mux41_N2BEG3 (
    .A0(N2BEG3_input[0]),
    .A1(N2BEG3_input[1]),
    .A2(N2BEG3_input[2]),
    .A3(N2BEG3_input[3]),
    .S0(ConfigBits[30+0]),
    .S0N(ConfigBits_N[30+0]),
    .S1(ConfigBits[30+1]),
    .S1N(ConfigBits_N[30+1]),
    .X(N2BEG3)
);

 //switch matrix multiplexer N2BEG4 MUX-4
assign N2BEG4_input = {A_OUT,S2END3,S2MID3,S1END3};
cus_mux41 inst_cus_mux41_N2BEG4 (
    .A0(N2BEG4_input[0]),
    .A1(N2BEG4_input[1]),
    .A2(N2BEG4_input[2]),
    .A3(N2BEG4_input[3]),
    .S0(ConfigBits[32+0]),
    .S0N(ConfigBits_N[32+0]),
    .S1(ConfigBits[32+1]),
    .S1N(ConfigBits_N[32+1]),
    .X(N2BEG4)
);

 //switch matrix multiplexer N2BEG5 MUX-4
assign N2BEG5_input = {A_OUT,S2END2,S2MID2,S1END2};
cus_mux41 inst_cus_mux41_N2BEG5 (
    .A0(N2BEG5_input[0]),
    .A1(N2BEG5_input[1]),
    .A2(N2BEG5_input[2]),
    .A3(N2BEG5_input[3]),
    .S0(ConfigBits[34+0]),
    .S0N(ConfigBits_N[34+0]),
    .S1(ConfigBits[34+1]),
    .S1N(ConfigBits_N[34+1]),
    .X(N2BEG5)
);

 //switch matrix multiplexer N2BEG6 MUX-4
assign N2BEG6_input = {A_OUT,S2END1,S2MID1,S1END1};
cus_mux41 inst_cus_mux41_N2BEG6 (
    .A0(N2BEG6_input[0]),
    .A1(N2BEG6_input[1]),
    .A2(N2BEG6_input[2]),
    .A3(N2BEG6_input[3]),
    .S0(ConfigBits[36+0]),
    .S0N(ConfigBits_N[36+0]),
    .S1(ConfigBits[36+1]),
    .S1N(ConfigBits_N[36+1]),
    .X(N2BEG6)
);

 //switch matrix multiplexer N2BEG7 MUX-4
assign N2BEG7_input = {A_OUT,S2END0,S2MID0,S1END0};
cus_mux41 inst_cus_mux41_N2BEG7 (
    .A0(N2BEG7_input[0]),
    .A1(N2BEG7_input[1]),
    .A2(N2BEG7_input[2]),
    .A3(N2BEG7_input[3]),
    .S0(ConfigBits[38+0]),
    .S0N(ConfigBits_N[38+0]),
    .S1(ConfigBits[38+1]),
    .S1N(ConfigBits_N[38+1]),
    .X(N2BEG7)
);

 //switch matrix multiplexer N2BEGb0 MUX-4
assign N2BEGb0_input = {A_OUT,S2END7,S2MID7,S1END7};
cus_mux41 inst_cus_mux41_N2BEGb0 (
    .A0(N2BEGb0_input[0]),
    .A1(N2BEGb0_input[1]),
    .A2(N2BEGb0_input[2]),
    .A3(N2BEGb0_input[3]),
    .S0(ConfigBits[40+0]),
    .S0N(ConfigBits_N[40+0]),
    .S1(ConfigBits[40+1]),
    .S1N(ConfigBits_N[40+1]),
    .X(N2BEGb0)
);

 //switch matrix multiplexer N2BEGb1 MUX-4
assign N2BEGb1_input = {A_OUT,S2END6,S2MID6,S1END6};
cus_mux41 inst_cus_mux41_N2BEGb1 (
    .A0(N2BEGb1_input[0]),
    .A1(N2BEGb1_input[1]),
    .A2(N2BEGb1_input[2]),
    .A3(N2BEGb1_input[3]),
    .S0(ConfigBits[42+0]),
    .S0N(ConfigBits_N[42+0]),
    .S1(ConfigBits[42+1]),
    .S1N(ConfigBits_N[42+1]),
    .X(N2BEGb1)
);

 //switch matrix multiplexer N2BEGb2 MUX-4
assign N2BEGb2_input = {A_OUT,S2END5,S2MID5,S1END5};
cus_mux41 inst_cus_mux41_N2BEGb2 (
    .A0(N2BEGb2_input[0]),
    .A1(N2BEGb2_input[1]),
    .A2(N2BEGb2_input[2]),
    .A3(N2BEGb2_input[3]),
    .S0(ConfigBits[44+0]),
    .S0N(ConfigBits_N[44+0]),
    .S1(ConfigBits[44+1]),
    .S1N(ConfigBits_N[44+1]),
    .X(N2BEGb2)
);

 //switch matrix multiplexer N2BEGb3 MUX-4
assign N2BEGb3_input = {A_OUT,S2END4,S2MID4,S1END4};
cus_mux41 inst_cus_mux41_N2BEGb3 (
    .A0(N2BEGb3_input[0]),
    .A1(N2BEGb3_input[1]),
    .A2(N2BEGb3_input[2]),
    .A3(N2BEGb3_input[3]),
    .S0(ConfigBits[46+0]),
    .S0N(ConfigBits_N[46+0]),
    .S1(ConfigBits[46+1]),
    .S1N(ConfigBits_N[46+1]),
    .X(N2BEGb3)
);

 //switch matrix multiplexer N2BEGb4 MUX-4
assign N2BEGb4_input = {A_OUT,S2END3,S2MID3,S1END3};
cus_mux41 inst_cus_mux41_N2BEGb4 (
    .A0(N2BEGb4_input[0]),
    .A1(N2BEGb4_input[1]),
    .A2(N2BEGb4_input[2]),
    .A3(N2BEGb4_input[3]),
    .S0(ConfigBits[48+0]),
    .S0N(ConfigBits_N[48+0]),
    .S1(ConfigBits[48+1]),
    .S1N(ConfigBits_N[48+1]),
    .X(N2BEGb4)
);

 //switch matrix multiplexer N2BEGb5 MUX-4
assign N2BEGb5_input = {A_OUT,S2END2,S2MID2,S1END2};
cus_mux41 inst_cus_mux41_N2BEGb5 (
    .A0(N2BEGb5_input[0]),
    .A1(N2BEGb5_input[1]),
    .A2(N2BEGb5_input[2]),
    .A3(N2BEGb5_input[3]),
    .S0(ConfigBits[50+0]),
    .S0N(ConfigBits_N[50+0]),
    .S1(ConfigBits[50+1]),
    .S1N(ConfigBits_N[50+1]),
    .X(N2BEGb5)
);

 //switch matrix multiplexer N2BEGb6 MUX-4
assign N2BEGb6_input = {A_OUT,S2END1,S2MID1,S1END1};
cus_mux41 inst_cus_mux41_N2BEGb6 (
    .A0(N2BEGb6_input[0]),
    .A1(N2BEGb6_input[1]),
    .A2(N2BEGb6_input[2]),
    .A3(N2BEGb6_input[3]),
    .S0(ConfigBits[52+0]),
    .S0N(ConfigBits_N[52+0]),
    .S1(ConfigBits[52+1]),
    .S1N(ConfigBits_N[52+1]),
    .X(N2BEGb6)
);

 //switch matrix multiplexer N2BEGb7 MUX-4
assign N2BEGb7_input = {A_OUT,S2END0,S2MID0,S1END0};
cus_mux41 inst_cus_mux41_N2BEGb7 (
    .A0(N2BEGb7_input[0]),
    .A1(N2BEGb7_input[1]),
    .A2(N2BEGb7_input[2]),
    .A3(N2BEGb7_input[3]),
    .S0(ConfigBits[54+0]),
    .S0N(ConfigBits_N[54+0]),
    .S1(ConfigBits[54+1]),
    .S1N(ConfigBits_N[54+1]),
    .X(N2BEGb7)
);

 //switch matrix multiplexer Co0 MUX-1
assign Co0 = GND0;

 //switch matrix multiplexer A_CLK MUX-4
assign A_CLK_input = {E_GBUF_END3,E_GBUF_END2,E_GBUF_END1,E_GBUF_END0};
cus_mux41 inst_cus_mux41_A_CLK (
    .A0(A_CLK_input[0]),
    .A1(A_CLK_input[1]),
    .A2(A_CLK_input[2]),
    .A3(A_CLK_input[3]),
    .S0(ConfigBits[56+0]),
    .S0N(ConfigBits_N[56+0]),
    .S1(ConfigBits[56+1]),
    .S1N(ConfigBits_N[56+1]),
    .X(A_CLK)
);

 //switch matrix multiplexer A_IN MUX-16
assign A_IN_input = {VCC0,GND0,S2END7,S2END6,S2END5,S2MID2,S2MID1,S2MID0,S1END7,S1END6,S1END5,S1END4,S1END3,S1END2,S1END1,S1END0};
cus_mux161 inst_cus_mux161_A_IN (
    .A0(A_IN_input[0]),
    .A1(A_IN_input[1]),
    .A2(A_IN_input[2]),
    .A3(A_IN_input[3]),
    .A4(A_IN_input[4]),
    .A5(A_IN_input[5]),
    .A6(A_IN_input[6]),
    .A7(A_IN_input[7]),
    .A8(A_IN_input[8]),
    .A9(A_IN_input[9]),
    .A10(A_IN_input[10]),
    .A11(A_IN_input[11]),
    .A12(A_IN_input[12]),
    .A13(A_IN_input[13]),
    .A14(A_IN_input[14]),
    .A15(A_IN_input[15]),
    .S0(ConfigBits[58+0]),
    .S0N(ConfigBits_N[58+0]),
    .S1(ConfigBits[58+1]),
    .S1N(ConfigBits_N[58+1]),
    .S2(ConfigBits[58+2]),
    .S2N(ConfigBits_N[58+2]),
    .S3(ConfigBits[58+3]),
    .S3N(ConfigBits_N[58+3]),
    .X(A_IN)
);

 //switch matrix multiplexer A_EN MUX-8
assign A_EN_input = {VCC0,GND0,S2END2,S2END0,S2MID7,S2MID4,S1END7,S1END3};
cus_mux81 inst_cus_mux81_A_EN (
    .A0(A_EN_input[0]),
    .A1(A_EN_input[1]),
    .A2(A_EN_input[2]),
    .A3(A_EN_input[3]),
    .A4(A_EN_input[4]),
    .A5(A_EN_input[5]),
    .A6(A_EN_input[6]),
    .A7(A_EN_input[7]),
    .S0(ConfigBits[62+0]),
    .S0N(ConfigBits_N[62+0]),
    .S1(ConfigBits[62+1]),
    .S1N(ConfigBits_N[62+1]),
    .S2(ConfigBits[62+2]),
    .S2N(ConfigBits_N[62+2]),
    .X(A_EN)
);

endmodule
module S_IO
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=68
    )
    (
 //N
        output  [3:0] N_GBUF_BEG,        //Port(Name=N_GBUF_BEG,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=4,Side=N)
        output  [7:0] N1BEG,        //Port(Name=N1BEG,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=8,Side=N)
        output  [7:0] N2BEG,        //Port(Name=N2BEG,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=8,Side=N)
        output  [7:0] N2BEGb,        //Port(Name=N2BEGb,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=8,Side=N)
        input  [7:0] S1END,        //Port(Name=S1END,IO=INPUT,XOffset=0,YOffset=1,WireCount=8,Side=N)
        input  [7:0] S2MID,        //Port(Name=S2MID,IO=INPUT,XOffset=0,YOffset=1,WireCount=8,Side=N)
        input  [7:0] S2END,        //Port(Name=S2END,IO=INPUT,XOffset=0,YOffset=1,WireCount=8,Side=N)
        output  [0:0] Co,        //Port(Name=Co,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=1,Side=N)
 //E
        input  [3:0] W_GBUF_FEED_END,        //Port(Name=W_GBUF_FEED_END,IO=INPUT,XOffset=-1,YOffset=0,WireCount=4,Side=E)
        output  [3:0] E_GBUF_BEG,        //Port(Name=E_GBUF_BEG,IO=OUTPUT,XOffset=1,YOffset=0,WireCount=4,Side=E)
 //W
        output  [3:0] W_GBUF_FEED_BEG,        //Port(Name=W_GBUF_FEED_BEG,IO=OUTPUT,XOffset=-1,YOffset=0,WireCount=4,Side=W)
        input  [3:0] E_GBUF_END,        //Port(Name=E_GBUF_END,IO=INPUT,XOffset=1,YOffset=0,WireCount=4,Side=W)
        input  A_OUT_top,
        output  A_IN_top,
        output  A_EN_top,
    //Tile IO ports from BELs
        input  [FrameBitsPerRow-1:0] FrameData, //CONFIG_PORT
        output  [FrameBitsPerRow-1:0] FrameData_O,
        input  [MaxFramesPerCol-1:0] FrameStrobe, //CONFIG_PORT
        output  [MaxFramesPerCol-1:0] FrameStrobe_O
    //global
);
 //signal declarations
 //BEL ports (e.g., slices)
wire A_CLK;
wire A_IN;
wire A_EN;
wire A_OUT;
 //Jump wires
 //internal configuration data signal to daisy-chain all BELs (if any and in the order they are listed in the fabric.csv)
wire[NoConfigBits-1:0] ConfigBits;
wire[NoConfigBits-1:0] ConfigBits_N;

 //Connection for outgoing wires
wire[FrameBitsPerRow-1:0] FrameData_i;
wire[FrameBitsPerRow-1:0] FrameData_O_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_O_i;

assign FrameData_O_i = FrameData_i;

my_buf data_inbuf_0 (
    .A(FrameData[0]),
    .X(FrameData_i[0])
);

my_buf data_inbuf_1 (
    .A(FrameData[1]),
    .X(FrameData_i[1])
);

my_buf data_inbuf_2 (
    .A(FrameData[2]),
    .X(FrameData_i[2])
);

my_buf data_inbuf_3 (
    .A(FrameData[3]),
    .X(FrameData_i[3])
);

my_buf data_inbuf_4 (
    .A(FrameData[4]),
    .X(FrameData_i[4])
);

my_buf data_inbuf_5 (
    .A(FrameData[5]),
    .X(FrameData_i[5])
);

my_buf data_inbuf_6 (
    .A(FrameData[6]),
    .X(FrameData_i[6])
);

my_buf data_inbuf_7 (
    .A(FrameData[7]),
    .X(FrameData_i[7])
);

my_buf data_inbuf_8 (
    .A(FrameData[8]),
    .X(FrameData_i[8])
);

my_buf data_inbuf_9 (
    .A(FrameData[9]),
    .X(FrameData_i[9])
);

my_buf data_inbuf_10 (
    .A(FrameData[10]),
    .X(FrameData_i[10])
);

my_buf data_inbuf_11 (
    .A(FrameData[11]),
    .X(FrameData_i[11])
);

my_buf data_inbuf_12 (
    .A(FrameData[12]),
    .X(FrameData_i[12])
);

my_buf data_inbuf_13 (
    .A(FrameData[13]),
    .X(FrameData_i[13])
);

my_buf data_inbuf_14 (
    .A(FrameData[14]),
    .X(FrameData_i[14])
);

my_buf data_inbuf_15 (
    .A(FrameData[15]),
    .X(FrameData_i[15])
);

my_buf data_inbuf_16 (
    .A(FrameData[16]),
    .X(FrameData_i[16])
);

my_buf data_inbuf_17 (
    .A(FrameData[17]),
    .X(FrameData_i[17])
);

my_buf data_inbuf_18 (
    .A(FrameData[18]),
    .X(FrameData_i[18])
);

my_buf data_inbuf_19 (
    .A(FrameData[19]),
    .X(FrameData_i[19])
);

my_buf data_inbuf_20 (
    .A(FrameData[20]),
    .X(FrameData_i[20])
);

my_buf data_inbuf_21 (
    .A(FrameData[21]),
    .X(FrameData_i[21])
);

my_buf data_inbuf_22 (
    .A(FrameData[22]),
    .X(FrameData_i[22])
);

my_buf data_inbuf_23 (
    .A(FrameData[23]),
    .X(FrameData_i[23])
);

my_buf data_inbuf_24 (
    .A(FrameData[24]),
    .X(FrameData_i[24])
);

my_buf data_inbuf_25 (
    .A(FrameData[25]),
    .X(FrameData_i[25])
);

my_buf data_inbuf_26 (
    .A(FrameData[26]),
    .X(FrameData_i[26])
);

my_buf data_inbuf_27 (
    .A(FrameData[27]),
    .X(FrameData_i[27])
);

my_buf data_inbuf_28 (
    .A(FrameData[28]),
    .X(FrameData_i[28])
);

my_buf data_inbuf_29 (
    .A(FrameData[29]),
    .X(FrameData_i[29])
);

my_buf data_inbuf_30 (
    .A(FrameData[30]),
    .X(FrameData_i[30])
);

my_buf data_inbuf_31 (
    .A(FrameData[31]),
    .X(FrameData_i[31])
);

my_buf data_outbuf_0 (
    .A(FrameData_O_i[0]),
    .X(FrameData_O[0])
);

my_buf data_outbuf_1 (
    .A(FrameData_O_i[1]),
    .X(FrameData_O[1])
);

my_buf data_outbuf_2 (
    .A(FrameData_O_i[2]),
    .X(FrameData_O[2])
);

my_buf data_outbuf_3 (
    .A(FrameData_O_i[3]),
    .X(FrameData_O[3])
);

my_buf data_outbuf_4 (
    .A(FrameData_O_i[4]),
    .X(FrameData_O[4])
);

my_buf data_outbuf_5 (
    .A(FrameData_O_i[5]),
    .X(FrameData_O[5])
);

my_buf data_outbuf_6 (
    .A(FrameData_O_i[6]),
    .X(FrameData_O[6])
);

my_buf data_outbuf_7 (
    .A(FrameData_O_i[7]),
    .X(FrameData_O[7])
);

my_buf data_outbuf_8 (
    .A(FrameData_O_i[8]),
    .X(FrameData_O[8])
);

my_buf data_outbuf_9 (
    .A(FrameData_O_i[9]),
    .X(FrameData_O[9])
);

my_buf data_outbuf_10 (
    .A(FrameData_O_i[10]),
    .X(FrameData_O[10])
);

my_buf data_outbuf_11 (
    .A(FrameData_O_i[11]),
    .X(FrameData_O[11])
);

my_buf data_outbuf_12 (
    .A(FrameData_O_i[12]),
    .X(FrameData_O[12])
);

my_buf data_outbuf_13 (
    .A(FrameData_O_i[13]),
    .X(FrameData_O[13])
);

my_buf data_outbuf_14 (
    .A(FrameData_O_i[14]),
    .X(FrameData_O[14])
);

my_buf data_outbuf_15 (
    .A(FrameData_O_i[15]),
    .X(FrameData_O[15])
);

my_buf data_outbuf_16 (
    .A(FrameData_O_i[16]),
    .X(FrameData_O[16])
);

my_buf data_outbuf_17 (
    .A(FrameData_O_i[17]),
    .X(FrameData_O[17])
);

my_buf data_outbuf_18 (
    .A(FrameData_O_i[18]),
    .X(FrameData_O[18])
);

my_buf data_outbuf_19 (
    .A(FrameData_O_i[19]),
    .X(FrameData_O[19])
);

my_buf data_outbuf_20 (
    .A(FrameData_O_i[20]),
    .X(FrameData_O[20])
);

my_buf data_outbuf_21 (
    .A(FrameData_O_i[21]),
    .X(FrameData_O[21])
);

my_buf data_outbuf_22 (
    .A(FrameData_O_i[22]),
    .X(FrameData_O[22])
);

my_buf data_outbuf_23 (
    .A(FrameData_O_i[23]),
    .X(FrameData_O[23])
);

my_buf data_outbuf_24 (
    .A(FrameData_O_i[24]),
    .X(FrameData_O[24])
);

my_buf data_outbuf_25 (
    .A(FrameData_O_i[25]),
    .X(FrameData_O[25])
);

my_buf data_outbuf_26 (
    .A(FrameData_O_i[26]),
    .X(FrameData_O[26])
);

my_buf data_outbuf_27 (
    .A(FrameData_O_i[27]),
    .X(FrameData_O[27])
);

my_buf data_outbuf_28 (
    .A(FrameData_O_i[28]),
    .X(FrameData_O[28])
);

my_buf data_outbuf_29 (
    .A(FrameData_O_i[29]),
    .X(FrameData_O[29])
);

my_buf data_outbuf_30 (
    .A(FrameData_O_i[30]),
    .X(FrameData_O[30])
);

my_buf data_outbuf_31 (
    .A(FrameData_O_i[31]),
    .X(FrameData_O[31])
);

assign FrameStrobe_O_i = FrameStrobe_i;

my_buf strobe_inbuf_0 (
    .A(FrameStrobe[0]),
    .X(FrameStrobe_i[0])
);

my_buf strobe_inbuf_1 (
    .A(FrameStrobe[1]),
    .X(FrameStrobe_i[1])
);

my_buf strobe_inbuf_2 (
    .A(FrameStrobe[2]),
    .X(FrameStrobe_i[2])
);

my_buf strobe_inbuf_3 (
    .A(FrameStrobe[3]),
    .X(FrameStrobe_i[3])
);

my_buf strobe_inbuf_4 (
    .A(FrameStrobe[4]),
    .X(FrameStrobe_i[4])
);

my_buf strobe_inbuf_5 (
    .A(FrameStrobe[5]),
    .X(FrameStrobe_i[5])
);

my_buf strobe_inbuf_6 (
    .A(FrameStrobe[6]),
    .X(FrameStrobe_i[6])
);

my_buf strobe_inbuf_7 (
    .A(FrameStrobe[7]),
    .X(FrameStrobe_i[7])
);

my_buf strobe_inbuf_8 (
    .A(FrameStrobe[8]),
    .X(FrameStrobe_i[8])
);

my_buf strobe_inbuf_9 (
    .A(FrameStrobe[9]),
    .X(FrameStrobe_i[9])
);

my_buf strobe_inbuf_10 (
    .A(FrameStrobe[10]),
    .X(FrameStrobe_i[10])
);

my_buf strobe_inbuf_11 (
    .A(FrameStrobe[11]),
    .X(FrameStrobe_i[11])
);

my_buf strobe_inbuf_12 (
    .A(FrameStrobe[12]),
    .X(FrameStrobe_i[12])
);

my_buf strobe_inbuf_13 (
    .A(FrameStrobe[13]),
    .X(FrameStrobe_i[13])
);

my_buf strobe_inbuf_14 (
    .A(FrameStrobe[14]),
    .X(FrameStrobe_i[14])
);

my_buf strobe_inbuf_15 (
    .A(FrameStrobe[15]),
    .X(FrameStrobe_i[15])
);

my_buf strobe_inbuf_16 (
    .A(FrameStrobe[16]),
    .X(FrameStrobe_i[16])
);

my_buf strobe_inbuf_17 (
    .A(FrameStrobe[17]),
    .X(FrameStrobe_i[17])
);

my_buf strobe_inbuf_18 (
    .A(FrameStrobe[18]),
    .X(FrameStrobe_i[18])
);

my_buf strobe_inbuf_19 (
    .A(FrameStrobe[19]),
    .X(FrameStrobe_i[19])
);

my_buf strobe_outbuf_0 (
    .A(FrameStrobe_O_i[0]),
    .X(FrameStrobe_O[0])
);

my_buf strobe_outbuf_1 (
    .A(FrameStrobe_O_i[1]),
    .X(FrameStrobe_O[1])
);

my_buf strobe_outbuf_2 (
    .A(FrameStrobe_O_i[2]),
    .X(FrameStrobe_O[2])
);

my_buf strobe_outbuf_3 (
    .A(FrameStrobe_O_i[3]),
    .X(FrameStrobe_O[3])
);

my_buf strobe_outbuf_4 (
    .A(FrameStrobe_O_i[4]),
    .X(FrameStrobe_O[4])
);

my_buf strobe_outbuf_5 (
    .A(FrameStrobe_O_i[5]),
    .X(FrameStrobe_O[5])
);

my_buf strobe_outbuf_6 (
    .A(FrameStrobe_O_i[6]),
    .X(FrameStrobe_O[6])
);

my_buf strobe_outbuf_7 (
    .A(FrameStrobe_O_i[7]),
    .X(FrameStrobe_O[7])
);

my_buf strobe_outbuf_8 (
    .A(FrameStrobe_O_i[8]),
    .X(FrameStrobe_O[8])
);

my_buf strobe_outbuf_9 (
    .A(FrameStrobe_O_i[9]),
    .X(FrameStrobe_O[9])
);

my_buf strobe_outbuf_10 (
    .A(FrameStrobe_O_i[10]),
    .X(FrameStrobe_O[10])
);

my_buf strobe_outbuf_11 (
    .A(FrameStrobe_O_i[11]),
    .X(FrameStrobe_O[11])
);

my_buf strobe_outbuf_12 (
    .A(FrameStrobe_O_i[12]),
    .X(FrameStrobe_O[12])
);

my_buf strobe_outbuf_13 (
    .A(FrameStrobe_O_i[13]),
    .X(FrameStrobe_O[13])
);

my_buf strobe_outbuf_14 (
    .A(FrameStrobe_O_i[14]),
    .X(FrameStrobe_O[14])
);

my_buf strobe_outbuf_15 (
    .A(FrameStrobe_O_i[15]),
    .X(FrameStrobe_O[15])
);

my_buf strobe_outbuf_16 (
    .A(FrameStrobe_O_i[16]),
    .X(FrameStrobe_O[16])
);

my_buf strobe_outbuf_17 (
    .A(FrameStrobe_O_i[17]),
    .X(FrameStrobe_O[17])
);

my_buf strobe_outbuf_18 (
    .A(FrameStrobe_O_i[18]),
    .X(FrameStrobe_O[18])
);

my_buf strobe_outbuf_19 (
    .A(FrameStrobe_O_i[19]),
    .X(FrameStrobe_O[19])
);


 //configuration storage latches
S_IO_ConfigMem
`ifdef EMULATION
    #(
    .Emulate_Bitstream(Emulate_Bitstream)
    )
`endif
    Inst_S_IO_ConfigMem
    (
    .FrameData(FrameData),
    .FrameStrobe(FrameStrobe),
    .ConfigBits(ConfigBits),
    .ConfigBits_N(ConfigBits_N)
);


 //BEL component instantiations
IOBUF Inst_A_IOBUF (
    .CLK(A_CLK),
    .IN(A_IN),
    .EN(A_EN),
    .OUT(A_OUT),
    .IN_top(A_IN_top),
    .EN_top(A_EN_top),
    .OUT_top(A_OUT_top),
    .ConfigBits(ConfigBits[3-1:0])
);

S_IO_switch_matrix Inst_S_IO_switch_matrix (
    .W_GBUF_FEED_END0(W_GBUF_FEED_END[0]),
    .W_GBUF_FEED_END1(W_GBUF_FEED_END[1]),
    .W_GBUF_FEED_END2(W_GBUF_FEED_END[2]),
    .W_GBUF_FEED_END3(W_GBUF_FEED_END[3]),
    .E_GBUF_END0(E_GBUF_END[0]),
    .E_GBUF_END1(E_GBUF_END[1]),
    .E_GBUF_END2(E_GBUF_END[2]),
    .E_GBUF_END3(E_GBUF_END[3]),
    .S1END0(S1END[0]),
    .S1END1(S1END[1]),
    .S1END2(S1END[2]),
    .S1END3(S1END[3]),
    .S1END4(S1END[4]),
    .S1END5(S1END[5]),
    .S1END6(S1END[6]),
    .S1END7(S1END[7]),
    .S2MID0(S2MID[0]),
    .S2MID1(S2MID[1]),
    .S2MID2(S2MID[2]),
    .S2MID3(S2MID[3]),
    .S2MID4(S2MID[4]),
    .S2MID5(S2MID[5]),
    .S2MID6(S2MID[6]),
    .S2MID7(S2MID[7]),
    .S2END0(S2END[0]),
    .S2END1(S2END[1]),
    .S2END2(S2END[2]),
    .S2END3(S2END[3]),
    .S2END4(S2END[4]),
    .S2END5(S2END[5]),
    .S2END6(S2END[6]),
    .S2END7(S2END[7]),
    .A_OUT(A_OUT),
    .W_GBUF_FEED_BEG0(W_GBUF_FEED_BEG[0]),
    .W_GBUF_FEED_BEG1(W_GBUF_FEED_BEG[1]),
    .W_GBUF_FEED_BEG2(W_GBUF_FEED_BEG[2]),
    .W_GBUF_FEED_BEG3(W_GBUF_FEED_BEG[3]),
    .N_GBUF_BEG0(N_GBUF_BEG[0]),
    .N_GBUF_BEG1(N_GBUF_BEG[1]),
    .N_GBUF_BEG2(N_GBUF_BEG[2]),
    .N_GBUF_BEG3(N_GBUF_BEG[3]),
    .E_GBUF_BEG0(E_GBUF_BEG[0]),
    .E_GBUF_BEG1(E_GBUF_BEG[1]),
    .E_GBUF_BEG2(E_GBUF_BEG[2]),
    .E_GBUF_BEG3(E_GBUF_BEG[3]),
    .N1BEG0(N1BEG[0]),
    .N1BEG1(N1BEG[1]),
    .N1BEG2(N1BEG[2]),
    .N1BEG3(N1BEG[3]),
    .N1BEG4(N1BEG[4]),
    .N1BEG5(N1BEG[5]),
    .N1BEG6(N1BEG[6]),
    .N1BEG7(N1BEG[7]),
    .N2BEG0(N2BEG[0]),
    .N2BEG1(N2BEG[1]),
    .N2BEG2(N2BEG[2]),
    .N2BEG3(N2BEG[3]),
    .N2BEG4(N2BEG[4]),
    .N2BEG5(N2BEG[5]),
    .N2BEG6(N2BEG[6]),
    .N2BEG7(N2BEG[7]),
    .N2BEGb0(N2BEGb[0]),
    .N2BEGb1(N2BEGb[1]),
    .N2BEGb2(N2BEGb[2]),
    .N2BEGb3(N2BEGb[3]),
    .N2BEGb4(N2BEGb[4]),
    .N2BEGb5(N2BEGb[5]),
    .N2BEGb6(N2BEGb[6]),
    .N2BEGb7(N2BEGb[7]),
    .Co0(Co[0]),
    .A_CLK(A_CLK),
    .A_IN(A_IN),
    .A_EN(A_EN),
    .ConfigBits(ConfigBits[68-1:3]),
    .ConfigBits_N(ConfigBits_N[68-1:3])
);

endmodule
module S_term_ConfigMem
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=56
    )
    (
        input  [FrameBitsPerRow - 1:0] FrameData,
        input  [MaxFramesPerCol - 1:0] FrameStrobe,
        output  [NoConfigBits - 1:0] ConfigBits,
        output  [NoConfigBits - 1:0] ConfigBits_N
    );

`ifdef EMULATION
assign ConfigBits[55] = Emulate_Bitstream[31];
assign ConfigBits[54] = Emulate_Bitstream[30];
assign ConfigBits[53] = Emulate_Bitstream[29];
assign ConfigBits[52] = Emulate_Bitstream[28];
assign ConfigBits[51] = Emulate_Bitstream[27];
assign ConfigBits[50] = Emulate_Bitstream[26];
assign ConfigBits[49] = Emulate_Bitstream[25];
assign ConfigBits[48] = Emulate_Bitstream[24];
assign ConfigBits[47] = Emulate_Bitstream[23];
assign ConfigBits[46] = Emulate_Bitstream[22];
assign ConfigBits[45] = Emulate_Bitstream[21];
assign ConfigBits[44] = Emulate_Bitstream[20];
assign ConfigBits[43] = Emulate_Bitstream[19];
assign ConfigBits[42] = Emulate_Bitstream[18];
assign ConfigBits[41] = Emulate_Bitstream[17];
assign ConfigBits[40] = Emulate_Bitstream[16];
assign ConfigBits[39] = Emulate_Bitstream[15];
assign ConfigBits[38] = Emulate_Bitstream[14];
assign ConfigBits[37] = Emulate_Bitstream[13];
assign ConfigBits[36] = Emulate_Bitstream[12];
assign ConfigBits[35] = Emulate_Bitstream[11];
assign ConfigBits[34] = Emulate_Bitstream[10];
assign ConfigBits[33] = Emulate_Bitstream[9];
assign ConfigBits[32] = Emulate_Bitstream[8];
assign ConfigBits[31] = Emulate_Bitstream[7];
assign ConfigBits[30] = Emulate_Bitstream[6];
assign ConfigBits[29] = Emulate_Bitstream[5];
assign ConfigBits[28] = Emulate_Bitstream[4];
assign ConfigBits[27] = Emulate_Bitstream[3];
assign ConfigBits[26] = Emulate_Bitstream[2];
assign ConfigBits[25] = Emulate_Bitstream[1];
assign ConfigBits[24] = Emulate_Bitstream[0];
assign ConfigBits[23] = Emulate_Bitstream[63];
assign ConfigBits[22] = Emulate_Bitstream[62];
assign ConfigBits[21] = Emulate_Bitstream[61];
assign ConfigBits[20] = Emulate_Bitstream[60];
assign ConfigBits[19] = Emulate_Bitstream[59];
assign ConfigBits[18] = Emulate_Bitstream[58];
assign ConfigBits[17] = Emulate_Bitstream[57];
assign ConfigBits[16] = Emulate_Bitstream[56];
assign ConfigBits[15] = Emulate_Bitstream[55];
assign ConfigBits[14] = Emulate_Bitstream[54];
assign ConfigBits[13] = Emulate_Bitstream[53];
assign ConfigBits[12] = Emulate_Bitstream[52];
assign ConfigBits[11] = Emulate_Bitstream[51];
assign ConfigBits[10] = Emulate_Bitstream[50];
assign ConfigBits[9] = Emulate_Bitstream[49];
assign ConfigBits[8] = Emulate_Bitstream[48];
assign ConfigBits[7] = Emulate_Bitstream[47];
assign ConfigBits[6] = Emulate_Bitstream[46];
assign ConfigBits[5] = Emulate_Bitstream[45];
assign ConfigBits[4] = Emulate_Bitstream[44];
assign ConfigBits[3] = Emulate_Bitstream[43];
assign ConfigBits[2] = Emulate_Bitstream[42];
assign ConfigBits[1] = Emulate_Bitstream[41];
assign ConfigBits[0] = Emulate_Bitstream[40];
`else

 //instantiate frame latches
config_latch Inst_frame0_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[55]),
    .QN(ConfigBits_N[55])
);

config_latch Inst_frame0_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[54]),
    .QN(ConfigBits_N[54])
);

config_latch Inst_frame0_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[53]),
    .QN(ConfigBits_N[53])
);

config_latch Inst_frame0_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[52]),
    .QN(ConfigBits_N[52])
);

config_latch Inst_frame0_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[51]),
    .QN(ConfigBits_N[51])
);

config_latch Inst_frame0_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[50]),
    .QN(ConfigBits_N[50])
);

config_latch Inst_frame0_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[49]),
    .QN(ConfigBits_N[49])
);

config_latch Inst_frame0_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[48]),
    .QN(ConfigBits_N[48])
);

config_latch Inst_frame0_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[47]),
    .QN(ConfigBits_N[47])
);

config_latch Inst_frame0_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[46]),
    .QN(ConfigBits_N[46])
);

config_latch Inst_frame0_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[45]),
    .QN(ConfigBits_N[45])
);

config_latch Inst_frame0_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[44]),
    .QN(ConfigBits_N[44])
);

config_latch Inst_frame0_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[43]),
    .QN(ConfigBits_N[43])
);

config_latch Inst_frame0_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[42]),
    .QN(ConfigBits_N[42])
);

config_latch Inst_frame0_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[41]),
    .QN(ConfigBits_N[41])
);

config_latch Inst_frame0_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[40]),
    .QN(ConfigBits_N[40])
);

config_latch Inst_frame0_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[39]),
    .QN(ConfigBits_N[39])
);

config_latch Inst_frame0_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[38]),
    .QN(ConfigBits_N[38])
);

config_latch Inst_frame0_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[37]),
    .QN(ConfigBits_N[37])
);

config_latch Inst_frame0_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[36]),
    .QN(ConfigBits_N[36])
);

config_latch Inst_frame0_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[35]),
    .QN(ConfigBits_N[35])
);

config_latch Inst_frame0_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[34]),
    .QN(ConfigBits_N[34])
);

config_latch Inst_frame0_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[33]),
    .QN(ConfigBits_N[33])
);

config_latch Inst_frame0_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[32]),
    .QN(ConfigBits_N[32])
);

config_latch Inst_frame0_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[31]),
    .QN(ConfigBits_N[31])
);

config_latch Inst_frame0_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[30]),
    .QN(ConfigBits_N[30])
);

config_latch Inst_frame0_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[29]),
    .QN(ConfigBits_N[29])
);

config_latch Inst_frame0_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[28]),
    .QN(ConfigBits_N[28])
);

config_latch Inst_frame0_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[27]),
    .QN(ConfigBits_N[27])
);

config_latch Inst_frame0_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[26]),
    .QN(ConfigBits_N[26])
);

config_latch Inst_frame0_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[25]),
    .QN(ConfigBits_N[25])
);

config_latch Inst_frame0_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[24]),
    .QN(ConfigBits_N[24])
);

config_latch Inst_frame1_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[23]),
    .QN(ConfigBits_N[23])
);

config_latch Inst_frame1_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[22]),
    .QN(ConfigBits_N[22])
);

config_latch Inst_frame1_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[21]),
    .QN(ConfigBits_N[21])
);

config_latch Inst_frame1_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[20]),
    .QN(ConfigBits_N[20])
);

config_latch Inst_frame1_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[19]),
    .QN(ConfigBits_N[19])
);

config_latch Inst_frame1_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[18]),
    .QN(ConfigBits_N[18])
);

config_latch Inst_frame1_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[17]),
    .QN(ConfigBits_N[17])
);

config_latch Inst_frame1_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[16]),
    .QN(ConfigBits_N[16])
);

config_latch Inst_frame1_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[15]),
    .QN(ConfigBits_N[15])
);

config_latch Inst_frame1_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[14]),
    .QN(ConfigBits_N[14])
);

config_latch Inst_frame1_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[13]),
    .QN(ConfigBits_N[13])
);

config_latch Inst_frame1_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[12]),
    .QN(ConfigBits_N[12])
);

config_latch Inst_frame1_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[11]),
    .QN(ConfigBits_N[11])
);

config_latch Inst_frame1_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[10]),
    .QN(ConfigBits_N[10])
);

config_latch Inst_frame1_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[9]),
    .QN(ConfigBits_N[9])
);

config_latch Inst_frame1_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[8]),
    .QN(ConfigBits_N[8])
);

config_latch Inst_frame1_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[7]),
    .QN(ConfigBits_N[7])
);

config_latch Inst_frame1_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[6]),
    .QN(ConfigBits_N[6])
);

config_latch Inst_frame1_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[5]),
    .QN(ConfigBits_N[5])
);

config_latch Inst_frame1_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[4]),
    .QN(ConfigBits_N[4])
);

config_latch Inst_frame1_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[3]),
    .QN(ConfigBits_N[3])
);

config_latch Inst_frame1_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[2]),
    .QN(ConfigBits_N[2])
);

config_latch Inst_frame1_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[1]),
    .QN(ConfigBits_N[1])
);

config_latch Inst_frame1_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[0]),
    .QN(ConfigBits_N[0])
);

`endif
endmodule
 // NumberOfConfigBits: 56
module S_term_switch_matrix
    #(
        parameter NoConfigBits=56
    )
    (
        input  W_GBUF_FEED_END0,
        input  W_GBUF_FEED_END1,
        input  W_GBUF_FEED_END2,
        input  W_GBUF_FEED_END3,
        input  E_GBUF_END0,
        input  E_GBUF_END1,
        input  E_GBUF_END2,
        input  E_GBUF_END3,
        input  S1END0,
        input  S1END1,
        input  S1END2,
        input  S1END3,
        input  S1END4,
        input  S1END5,
        input  S1END6,
        input  S1END7,
        input  S2MID0,
        input  S2MID1,
        input  S2MID2,
        input  S2MID3,
        input  S2MID4,
        input  S2MID5,
        input  S2MID6,
        input  S2MID7,
        input  S2END0,
        input  S2END1,
        input  S2END2,
        input  S2END3,
        input  S2END4,
        input  S2END5,
        input  S2END6,
        input  S2END7,
        output  W_GBUF_FEED_BEG0,
        output  W_GBUF_FEED_BEG1,
        output  W_GBUF_FEED_BEG2,
        output  W_GBUF_FEED_BEG3,
        output  N_GBUF_BEG0,
        output  N_GBUF_BEG1,
        output  N_GBUF_BEG2,
        output  N_GBUF_BEG3,
        output  E_GBUF_BEG0,
        output  E_GBUF_BEG1,
        output  E_GBUF_BEG2,
        output  E_GBUF_BEG3,
        output  N1BEG0,
        output  N1BEG1,
        output  N1BEG2,
        output  N1BEG3,
        output  N1BEG4,
        output  N1BEG5,
        output  N1BEG6,
        output  N1BEG7,
        output  N2BEG0,
        output  N2BEG1,
        output  N2BEG2,
        output  N2BEG3,
        output  N2BEG4,
        output  N2BEG5,
        output  N2BEG6,
        output  N2BEG7,
        output  N2BEGb0,
        output  N2BEGb1,
        output  N2BEGb2,
        output  N2BEGb3,
        output  N2BEGb4,
        output  N2BEGb5,
        output  N2BEGb6,
        output  N2BEGb7,
        output  Co0,
 //global
        input  [NoConfigBits-1:0] ConfigBits,
        input  [NoConfigBits-1:0] ConfigBits_N
);
parameter GND0 = 1'b0;
parameter GND = 1'b0;
parameter VCC0 = 1'b1;
parameter VCC = 1'b1;
parameter VDD0 = 1'b1;
parameter VDD = 1'b1;

wire[4-1:0] W_GBUF_FEED_BEG0_input;
wire[4-1:0] W_GBUF_FEED_BEG1_input;
wire[4-1:0] W_GBUF_FEED_BEG2_input;
wire[4-1:0] W_GBUF_FEED_BEG3_input;
wire[4-1:0] N1BEG0_input;
wire[4-1:0] N1BEG1_input;
wire[4-1:0] N1BEG2_input;
wire[4-1:0] N1BEG3_input;
wire[4-1:0] N1BEG4_input;
wire[4-1:0] N1BEG5_input;
wire[4-1:0] N1BEG6_input;
wire[4-1:0] N1BEG7_input;
wire[4-1:0] N2BEG0_input;
wire[4-1:0] N2BEG1_input;
wire[4-1:0] N2BEG2_input;
wire[4-1:0] N2BEG3_input;
wire[4-1:0] N2BEG4_input;
wire[4-1:0] N2BEG5_input;
wire[4-1:0] N2BEG6_input;
wire[4-1:0] N2BEG7_input;
wire[4-1:0] N2BEGb0_input;
wire[4-1:0] N2BEGb1_input;
wire[4-1:0] N2BEGb2_input;
wire[4-1:0] N2BEGb3_input;
wire[4-1:0] N2BEGb4_input;
wire[4-1:0] N2BEGb5_input;
wire[4-1:0] N2BEGb6_input;
wire[4-1:0] N2BEGb7_input;
 //The configuration bits (if any) are just a long shift register
 //This shift register is padded to an even number of flops/latches
 //switch matrix multiplexer W_GBUF_FEED_BEG0 MUX-4
assign W_GBUF_FEED_BEG0_input = {S2END7,S1END6,S1END1,W_GBUF_FEED_END0};
cus_mux41 inst_cus_mux41_W_GBUF_FEED_BEG0 (
    .A0(W_GBUF_FEED_BEG0_input[0]),
    .A1(W_GBUF_FEED_BEG0_input[1]),
    .A2(W_GBUF_FEED_BEG0_input[2]),
    .A3(W_GBUF_FEED_BEG0_input[3]),
    .S0(ConfigBits[0+0]),
    .S0N(ConfigBits_N[0+0]),
    .S1(ConfigBits[0+1]),
    .S1N(ConfigBits_N[0+1]),
    .X(W_GBUF_FEED_BEG0)
);

 //switch matrix multiplexer W_GBUF_FEED_BEG1 MUX-4
assign W_GBUF_FEED_BEG1_input = {S2END6,S1END7,S1END2,W_GBUF_FEED_END1};
cus_mux41 inst_cus_mux41_W_GBUF_FEED_BEG1 (
    .A0(W_GBUF_FEED_BEG1_input[0]),
    .A1(W_GBUF_FEED_BEG1_input[1]),
    .A2(W_GBUF_FEED_BEG1_input[2]),
    .A3(W_GBUF_FEED_BEG1_input[3]),
    .S0(ConfigBits[2+0]),
    .S0N(ConfigBits_N[2+0]),
    .S1(ConfigBits[2+1]),
    .S1N(ConfigBits_N[2+1]),
    .X(W_GBUF_FEED_BEG1)
);

 //switch matrix multiplexer W_GBUF_FEED_BEG2 MUX-4
assign W_GBUF_FEED_BEG2_input = {S2END5,S1END5,S1END3,W_GBUF_FEED_END2};
cus_mux41 inst_cus_mux41_W_GBUF_FEED_BEG2 (
    .A0(W_GBUF_FEED_BEG2_input[0]),
    .A1(W_GBUF_FEED_BEG2_input[1]),
    .A2(W_GBUF_FEED_BEG2_input[2]),
    .A3(W_GBUF_FEED_BEG2_input[3]),
    .S0(ConfigBits[4+0]),
    .S0N(ConfigBits_N[4+0]),
    .S1(ConfigBits[4+1]),
    .S1N(ConfigBits_N[4+1]),
    .X(W_GBUF_FEED_BEG2)
);

 //switch matrix multiplexer W_GBUF_FEED_BEG3 MUX-4
assign W_GBUF_FEED_BEG3_input = {S2END4,S1END4,S1END0,W_GBUF_FEED_END3};
cus_mux41 inst_cus_mux41_W_GBUF_FEED_BEG3 (
    .A0(W_GBUF_FEED_BEG3_input[0]),
    .A1(W_GBUF_FEED_BEG3_input[1]),
    .A2(W_GBUF_FEED_BEG3_input[2]),
    .A3(W_GBUF_FEED_BEG3_input[3]),
    .S0(ConfigBits[6+0]),
    .S0N(ConfigBits_N[6+0]),
    .S1(ConfigBits[6+1]),
    .S1N(ConfigBits_N[6+1]),
    .X(W_GBUF_FEED_BEG3)
);

 //switch matrix multiplexer N_GBUF_BEG0 MUX-1
assign N_GBUF_BEG0 = E_GBUF_END0;

 //switch matrix multiplexer N_GBUF_BEG1 MUX-1
assign N_GBUF_BEG1 = E_GBUF_END1;

 //switch matrix multiplexer N_GBUF_BEG2 MUX-1
assign N_GBUF_BEG2 = E_GBUF_END2;

 //switch matrix multiplexer N_GBUF_BEG3 MUX-1
assign N_GBUF_BEG3 = E_GBUF_END3;

 //switch matrix multiplexer E_GBUF_BEG0 MUX-1
assign E_GBUF_BEG0 = E_GBUF_END0;

 //switch matrix multiplexer E_GBUF_BEG1 MUX-1
assign E_GBUF_BEG1 = E_GBUF_END1;

 //switch matrix multiplexer E_GBUF_BEG2 MUX-1
assign E_GBUF_BEG2 = E_GBUF_END2;

 //switch matrix multiplexer E_GBUF_BEG3 MUX-1
assign E_GBUF_BEG3 = E_GBUF_END3;

 //switch matrix multiplexer N1BEG0 MUX-4
assign N1BEG0_input = {S2END7,S2MID7,S1END7,S1END5};
cus_mux41 inst_cus_mux41_N1BEG0 (
    .A0(N1BEG0_input[0]),
    .A1(N1BEG0_input[1]),
    .A2(N1BEG0_input[2]),
    .A3(N1BEG0_input[3]),
    .S0(ConfigBits[8+0]),
    .S0N(ConfigBits_N[8+0]),
    .S1(ConfigBits[8+1]),
    .S1N(ConfigBits_N[8+1]),
    .X(N1BEG0)
);

 //switch matrix multiplexer N1BEG1 MUX-4
assign N1BEG1_input = {S2END6,S2MID6,S1END6,S1END3};
cus_mux41 inst_cus_mux41_N1BEG1 (
    .A0(N1BEG1_input[0]),
    .A1(N1BEG1_input[1]),
    .A2(N1BEG1_input[2]),
    .A3(N1BEG1_input[3]),
    .S0(ConfigBits[10+0]),
    .S0N(ConfigBits_N[10+0]),
    .S1(ConfigBits[10+1]),
    .S1N(ConfigBits_N[10+1]),
    .X(N1BEG1)
);

 //switch matrix multiplexer N1BEG2 MUX-4
assign N1BEG2_input = {S2END5,S2END1,S2MID5,S1END5};
cus_mux41 inst_cus_mux41_N1BEG2 (
    .A0(N1BEG2_input[0]),
    .A1(N1BEG2_input[1]),
    .A2(N1BEG2_input[2]),
    .A3(N1BEG2_input[3]),
    .S0(ConfigBits[12+0]),
    .S0N(ConfigBits_N[12+0]),
    .S1(ConfigBits[12+1]),
    .S1N(ConfigBits_N[12+1]),
    .X(N1BEG2)
);

 //switch matrix multiplexer N1BEG3 MUX-4
assign N1BEG3_input = {S2END6,S2END4,S2MID4,S1END4};
cus_mux41 inst_cus_mux41_N1BEG3 (
    .A0(N1BEG3_input[0]),
    .A1(N1BEG3_input[1]),
    .A2(N1BEG3_input[2]),
    .A3(N1BEG3_input[3]),
    .S0(ConfigBits[14+0]),
    .S0N(ConfigBits_N[14+0]),
    .S1(ConfigBits[14+1]),
    .S1N(ConfigBits_N[14+1]),
    .X(N1BEG3)
);

 //switch matrix multiplexer N1BEG4 MUX-4
assign N1BEG4_input = {S2END3,S2MID3,S2MID0,S1END3};
cus_mux41 inst_cus_mux41_N1BEG4 (
    .A0(N1BEG4_input[0]),
    .A1(N1BEG4_input[1]),
    .A2(N1BEG4_input[2]),
    .A3(N1BEG4_input[3]),
    .S0(ConfigBits[16+0]),
    .S0N(ConfigBits_N[16+0]),
    .S1(ConfigBits[16+1]),
    .S1N(ConfigBits_N[16+1]),
    .X(N1BEG4)
);

 //switch matrix multiplexer N1BEG5 MUX-4
assign N1BEG5_input = {S2END2,S2MID7,S2MID2,S1END2};
cus_mux41 inst_cus_mux41_N1BEG5 (
    .A0(N1BEG5_input[0]),
    .A1(N1BEG5_input[1]),
    .A2(N1BEG5_input[2]),
    .A3(N1BEG5_input[3]),
    .S0(ConfigBits[18+0]),
    .S0N(ConfigBits_N[18+0]),
    .S1(ConfigBits[18+1]),
    .S1N(ConfigBits_N[18+1]),
    .X(N1BEG5)
);

 //switch matrix multiplexer N1BEG6 MUX-4
assign N1BEG6_input = {VCC0,S2END1,S2MID1,S1END1};
cus_mux41 inst_cus_mux41_N1BEG6 (
    .A0(N1BEG6_input[0]),
    .A1(N1BEG6_input[1]),
    .A2(N1BEG6_input[2]),
    .A3(N1BEG6_input[3]),
    .S0(ConfigBits[20+0]),
    .S0N(ConfigBits_N[20+0]),
    .S1(ConfigBits[20+1]),
    .S1N(ConfigBits_N[20+1]),
    .X(N1BEG6)
);

 //switch matrix multiplexer N1BEG7 MUX-4
assign N1BEG7_input = {GND0,S2END0,S2MID0,S1END0};
cus_mux41 inst_cus_mux41_N1BEG7 (
    .A0(N1BEG7_input[0]),
    .A1(N1BEG7_input[1]),
    .A2(N1BEG7_input[2]),
    .A3(N1BEG7_input[3]),
    .S0(ConfigBits[22+0]),
    .S0N(ConfigBits_N[22+0]),
    .S1(ConfigBits[22+1]),
    .S1N(ConfigBits_N[22+1]),
    .X(N1BEG7)
);

 //switch matrix multiplexer N2BEG0 MUX-4
assign N2BEG0_input = {S2END7,S2MID7,S1END7,S1END5};
cus_mux41 inst_cus_mux41_N2BEG0 (
    .A0(N2BEG0_input[0]),
    .A1(N2BEG0_input[1]),
    .A2(N2BEG0_input[2]),
    .A3(N2BEG0_input[3]),
    .S0(ConfigBits[24+0]),
    .S0N(ConfigBits_N[24+0]),
    .S1(ConfigBits[24+1]),
    .S1N(ConfigBits_N[24+1]),
    .X(N2BEG0)
);

 //switch matrix multiplexer N2BEG1 MUX-4
assign N2BEG1_input = {S2END6,S2MID6,S1END6,S1END3};
cus_mux41 inst_cus_mux41_N2BEG1 (
    .A0(N2BEG1_input[0]),
    .A1(N2BEG1_input[1]),
    .A2(N2BEG1_input[2]),
    .A3(N2BEG1_input[3]),
    .S0(ConfigBits[26+0]),
    .S0N(ConfigBits_N[26+0]),
    .S1(ConfigBits[26+1]),
    .S1N(ConfigBits_N[26+1]),
    .X(N2BEG1)
);

 //switch matrix multiplexer N2BEG2 MUX-4
assign N2BEG2_input = {S2END5,S2END1,S2MID5,S1END5};
cus_mux41 inst_cus_mux41_N2BEG2 (
    .A0(N2BEG2_input[0]),
    .A1(N2BEG2_input[1]),
    .A2(N2BEG2_input[2]),
    .A3(N2BEG2_input[3]),
    .S0(ConfigBits[28+0]),
    .S0N(ConfigBits_N[28+0]),
    .S1(ConfigBits[28+1]),
    .S1N(ConfigBits_N[28+1]),
    .X(N2BEG2)
);

 //switch matrix multiplexer N2BEG3 MUX-4
assign N2BEG3_input = {S2END6,S2END4,S2MID4,S1END4};
cus_mux41 inst_cus_mux41_N2BEG3 (
    .A0(N2BEG3_input[0]),
    .A1(N2BEG3_input[1]),
    .A2(N2BEG3_input[2]),
    .A3(N2BEG3_input[3]),
    .S0(ConfigBits[30+0]),
    .S0N(ConfigBits_N[30+0]),
    .S1(ConfigBits[30+1]),
    .S1N(ConfigBits_N[30+1]),
    .X(N2BEG3)
);

 //switch matrix multiplexer N2BEG4 MUX-4
assign N2BEG4_input = {S2END3,S2MID3,S2MID0,S1END3};
cus_mux41 inst_cus_mux41_N2BEG4 (
    .A0(N2BEG4_input[0]),
    .A1(N2BEG4_input[1]),
    .A2(N2BEG4_input[2]),
    .A3(N2BEG4_input[3]),
    .S0(ConfigBits[32+0]),
    .S0N(ConfigBits_N[32+0]),
    .S1(ConfigBits[32+1]),
    .S1N(ConfigBits_N[32+1]),
    .X(N2BEG4)
);

 //switch matrix multiplexer N2BEG5 MUX-4
assign N2BEG5_input = {S2END2,S2MID7,S2MID2,S1END2};
cus_mux41 inst_cus_mux41_N2BEG5 (
    .A0(N2BEG5_input[0]),
    .A1(N2BEG5_input[1]),
    .A2(N2BEG5_input[2]),
    .A3(N2BEG5_input[3]),
    .S0(ConfigBits[34+0]),
    .S0N(ConfigBits_N[34+0]),
    .S1(ConfigBits[34+1]),
    .S1N(ConfigBits_N[34+1]),
    .X(N2BEG5)
);

 //switch matrix multiplexer N2BEG6 MUX-4
assign N2BEG6_input = {VCC0,S2END1,S2MID1,S1END1};
cus_mux41 inst_cus_mux41_N2BEG6 (
    .A0(N2BEG6_input[0]),
    .A1(N2BEG6_input[1]),
    .A2(N2BEG6_input[2]),
    .A3(N2BEG6_input[3]),
    .S0(ConfigBits[36+0]),
    .S0N(ConfigBits_N[36+0]),
    .S1(ConfigBits[36+1]),
    .S1N(ConfigBits_N[36+1]),
    .X(N2BEG6)
);

 //switch matrix multiplexer N2BEG7 MUX-4
assign N2BEG7_input = {GND0,S2END0,S2MID0,S1END0};
cus_mux41 inst_cus_mux41_N2BEG7 (
    .A0(N2BEG7_input[0]),
    .A1(N2BEG7_input[1]),
    .A2(N2BEG7_input[2]),
    .A3(N2BEG7_input[3]),
    .S0(ConfigBits[38+0]),
    .S0N(ConfigBits_N[38+0]),
    .S1(ConfigBits[38+1]),
    .S1N(ConfigBits_N[38+1]),
    .X(N2BEG7)
);

 //switch matrix multiplexer N2BEGb0 MUX-4
assign N2BEGb0_input = {S2END7,S2MID7,S1END7,S1END5};
cus_mux41 inst_cus_mux41_N2BEGb0 (
    .A0(N2BEGb0_input[0]),
    .A1(N2BEGb0_input[1]),
    .A2(N2BEGb0_input[2]),
    .A3(N2BEGb0_input[3]),
    .S0(ConfigBits[40+0]),
    .S0N(ConfigBits_N[40+0]),
    .S1(ConfigBits[40+1]),
    .S1N(ConfigBits_N[40+1]),
    .X(N2BEGb0)
);

 //switch matrix multiplexer N2BEGb1 MUX-4
assign N2BEGb1_input = {S2END6,S2MID6,S1END6,S1END3};
cus_mux41 inst_cus_mux41_N2BEGb1 (
    .A0(N2BEGb1_input[0]),
    .A1(N2BEGb1_input[1]),
    .A2(N2BEGb1_input[2]),
    .A3(N2BEGb1_input[3]),
    .S0(ConfigBits[42+0]),
    .S0N(ConfigBits_N[42+0]),
    .S1(ConfigBits[42+1]),
    .S1N(ConfigBits_N[42+1]),
    .X(N2BEGb1)
);

 //switch matrix multiplexer N2BEGb2 MUX-4
assign N2BEGb2_input = {S2END5,S2END1,S2MID5,S1END5};
cus_mux41 inst_cus_mux41_N2BEGb2 (
    .A0(N2BEGb2_input[0]),
    .A1(N2BEGb2_input[1]),
    .A2(N2BEGb2_input[2]),
    .A3(N2BEGb2_input[3]),
    .S0(ConfigBits[44+0]),
    .S0N(ConfigBits_N[44+0]),
    .S1(ConfigBits[44+1]),
    .S1N(ConfigBits_N[44+1]),
    .X(N2BEGb2)
);

 //switch matrix multiplexer N2BEGb3 MUX-4
assign N2BEGb3_input = {S2END6,S2END4,S2MID4,S1END4};
cus_mux41 inst_cus_mux41_N2BEGb3 (
    .A0(N2BEGb3_input[0]),
    .A1(N2BEGb3_input[1]),
    .A2(N2BEGb3_input[2]),
    .A3(N2BEGb3_input[3]),
    .S0(ConfigBits[46+0]),
    .S0N(ConfigBits_N[46+0]),
    .S1(ConfigBits[46+1]),
    .S1N(ConfigBits_N[46+1]),
    .X(N2BEGb3)
);

 //switch matrix multiplexer N2BEGb4 MUX-4
assign N2BEGb4_input = {S2END3,S2MID3,S2MID0,S1END3};
cus_mux41 inst_cus_mux41_N2BEGb4 (
    .A0(N2BEGb4_input[0]),
    .A1(N2BEGb4_input[1]),
    .A2(N2BEGb4_input[2]),
    .A3(N2BEGb4_input[3]),
    .S0(ConfigBits[48+0]),
    .S0N(ConfigBits_N[48+0]),
    .S1(ConfigBits[48+1]),
    .S1N(ConfigBits_N[48+1]),
    .X(N2BEGb4)
);

 //switch matrix multiplexer N2BEGb5 MUX-4
assign N2BEGb5_input = {S2END2,S2MID7,S2MID2,S1END2};
cus_mux41 inst_cus_mux41_N2BEGb5 (
    .A0(N2BEGb5_input[0]),
    .A1(N2BEGb5_input[1]),
    .A2(N2BEGb5_input[2]),
    .A3(N2BEGb5_input[3]),
    .S0(ConfigBits[50+0]),
    .S0N(ConfigBits_N[50+0]),
    .S1(ConfigBits[50+1]),
    .S1N(ConfigBits_N[50+1]),
    .X(N2BEGb5)
);

 //switch matrix multiplexer N2BEGb6 MUX-4
assign N2BEGb6_input = {VCC0,S2END1,S2MID1,S1END1};
cus_mux41 inst_cus_mux41_N2BEGb6 (
    .A0(N2BEGb6_input[0]),
    .A1(N2BEGb6_input[1]),
    .A2(N2BEGb6_input[2]),
    .A3(N2BEGb6_input[3]),
    .S0(ConfigBits[52+0]),
    .S0N(ConfigBits_N[52+0]),
    .S1(ConfigBits[52+1]),
    .S1N(ConfigBits_N[52+1]),
    .X(N2BEGb6)
);

 //switch matrix multiplexer N2BEGb7 MUX-4
assign N2BEGb7_input = {GND0,S2END0,S2MID0,S1END0};
cus_mux41 inst_cus_mux41_N2BEGb7 (
    .A0(N2BEGb7_input[0]),
    .A1(N2BEGb7_input[1]),
    .A2(N2BEGb7_input[2]),
    .A3(N2BEGb7_input[3]),
    .S0(ConfigBits[54+0]),
    .S0N(ConfigBits_N[54+0]),
    .S1(ConfigBits[54+1]),
    .S1N(ConfigBits_N[54+1]),
    .X(N2BEGb7)
);

 //switch matrix multiplexer Co0 MUX-1
assign Co0 = GND0;

endmodule
module S_term
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=56
    )
    (
 //N
        output  [3:0] N_GBUF_BEG,        //Port(Name=N_GBUF_BEG,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=4,Side=N)
        output  [7:0] N1BEG,        //Port(Name=N1BEG,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=8,Side=N)
        output  [7:0] N2BEG,        //Port(Name=N2BEG,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=8,Side=N)
        output  [7:0] N2BEGb,        //Port(Name=N2BEGb,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=8,Side=N)
        input  [7:0] S1END,        //Port(Name=S1END,IO=INPUT,XOffset=0,YOffset=1,WireCount=8,Side=N)
        input  [7:0] S2MID,        //Port(Name=S2MID,IO=INPUT,XOffset=0,YOffset=1,WireCount=8,Side=N)
        input  [7:0] S2END,        //Port(Name=S2END,IO=INPUT,XOffset=0,YOffset=1,WireCount=8,Side=N)
        output  [0:0] Co,        //Port(Name=Co,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=1,Side=N)
 //E
        input  [3:0] W_GBUF_FEED_END,        //Port(Name=W_GBUF_FEED_END,IO=INPUT,XOffset=-1,YOffset=0,WireCount=4,Side=E)
        output  [3:0] E_GBUF_BEG,        //Port(Name=E_GBUF_BEG,IO=OUTPUT,XOffset=1,YOffset=0,WireCount=4,Side=E)
 //W
        output  [3:0] W_GBUF_FEED_BEG,        //Port(Name=W_GBUF_FEED_BEG,IO=OUTPUT,XOffset=-1,YOffset=0,WireCount=4,Side=W)
        input  [3:0] E_GBUF_END,        //Port(Name=E_GBUF_END,IO=INPUT,XOffset=1,YOffset=0,WireCount=4,Side=W)
    //Tile IO ports from BELs
        input  [FrameBitsPerRow-1:0] FrameData, //CONFIG_PORT
        output  [FrameBitsPerRow-1:0] FrameData_O,
        input  [MaxFramesPerCol-1:0] FrameStrobe, //CONFIG_PORT
        output  [MaxFramesPerCol-1:0] FrameStrobe_O
    //global
);
 //signal declarations
 //BEL ports (e.g., slices)
 //Jump wires
 //internal configuration data signal to daisy-chain all BELs (if any and in the order they are listed in the fabric.csv)
wire[NoConfigBits-1:0] ConfigBits;
wire[NoConfigBits-1:0] ConfigBits_N;

 //Connection for outgoing wires
wire[FrameBitsPerRow-1:0] FrameData_i;
wire[FrameBitsPerRow-1:0] FrameData_O_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_O_i;

assign FrameData_O_i = FrameData_i;

my_buf data_inbuf_0 (
    .A(FrameData[0]),
    .X(FrameData_i[0])
);

my_buf data_inbuf_1 (
    .A(FrameData[1]),
    .X(FrameData_i[1])
);

my_buf data_inbuf_2 (
    .A(FrameData[2]),
    .X(FrameData_i[2])
);

my_buf data_inbuf_3 (
    .A(FrameData[3]),
    .X(FrameData_i[3])
);

my_buf data_inbuf_4 (
    .A(FrameData[4]),
    .X(FrameData_i[4])
);

my_buf data_inbuf_5 (
    .A(FrameData[5]),
    .X(FrameData_i[5])
);

my_buf data_inbuf_6 (
    .A(FrameData[6]),
    .X(FrameData_i[6])
);

my_buf data_inbuf_7 (
    .A(FrameData[7]),
    .X(FrameData_i[7])
);

my_buf data_inbuf_8 (
    .A(FrameData[8]),
    .X(FrameData_i[8])
);

my_buf data_inbuf_9 (
    .A(FrameData[9]),
    .X(FrameData_i[9])
);

my_buf data_inbuf_10 (
    .A(FrameData[10]),
    .X(FrameData_i[10])
);

my_buf data_inbuf_11 (
    .A(FrameData[11]),
    .X(FrameData_i[11])
);

my_buf data_inbuf_12 (
    .A(FrameData[12]),
    .X(FrameData_i[12])
);

my_buf data_inbuf_13 (
    .A(FrameData[13]),
    .X(FrameData_i[13])
);

my_buf data_inbuf_14 (
    .A(FrameData[14]),
    .X(FrameData_i[14])
);

my_buf data_inbuf_15 (
    .A(FrameData[15]),
    .X(FrameData_i[15])
);

my_buf data_inbuf_16 (
    .A(FrameData[16]),
    .X(FrameData_i[16])
);

my_buf data_inbuf_17 (
    .A(FrameData[17]),
    .X(FrameData_i[17])
);

my_buf data_inbuf_18 (
    .A(FrameData[18]),
    .X(FrameData_i[18])
);

my_buf data_inbuf_19 (
    .A(FrameData[19]),
    .X(FrameData_i[19])
);

my_buf data_inbuf_20 (
    .A(FrameData[20]),
    .X(FrameData_i[20])
);

my_buf data_inbuf_21 (
    .A(FrameData[21]),
    .X(FrameData_i[21])
);

my_buf data_inbuf_22 (
    .A(FrameData[22]),
    .X(FrameData_i[22])
);

my_buf data_inbuf_23 (
    .A(FrameData[23]),
    .X(FrameData_i[23])
);

my_buf data_inbuf_24 (
    .A(FrameData[24]),
    .X(FrameData_i[24])
);

my_buf data_inbuf_25 (
    .A(FrameData[25]),
    .X(FrameData_i[25])
);

my_buf data_inbuf_26 (
    .A(FrameData[26]),
    .X(FrameData_i[26])
);

my_buf data_inbuf_27 (
    .A(FrameData[27]),
    .X(FrameData_i[27])
);

my_buf data_inbuf_28 (
    .A(FrameData[28]),
    .X(FrameData_i[28])
);

my_buf data_inbuf_29 (
    .A(FrameData[29]),
    .X(FrameData_i[29])
);

my_buf data_inbuf_30 (
    .A(FrameData[30]),
    .X(FrameData_i[30])
);

my_buf data_inbuf_31 (
    .A(FrameData[31]),
    .X(FrameData_i[31])
);

my_buf data_outbuf_0 (
    .A(FrameData_O_i[0]),
    .X(FrameData_O[0])
);

my_buf data_outbuf_1 (
    .A(FrameData_O_i[1]),
    .X(FrameData_O[1])
);

my_buf data_outbuf_2 (
    .A(FrameData_O_i[2]),
    .X(FrameData_O[2])
);

my_buf data_outbuf_3 (
    .A(FrameData_O_i[3]),
    .X(FrameData_O[3])
);

my_buf data_outbuf_4 (
    .A(FrameData_O_i[4]),
    .X(FrameData_O[4])
);

my_buf data_outbuf_5 (
    .A(FrameData_O_i[5]),
    .X(FrameData_O[5])
);

my_buf data_outbuf_6 (
    .A(FrameData_O_i[6]),
    .X(FrameData_O[6])
);

my_buf data_outbuf_7 (
    .A(FrameData_O_i[7]),
    .X(FrameData_O[7])
);

my_buf data_outbuf_8 (
    .A(FrameData_O_i[8]),
    .X(FrameData_O[8])
);

my_buf data_outbuf_9 (
    .A(FrameData_O_i[9]),
    .X(FrameData_O[9])
);

my_buf data_outbuf_10 (
    .A(FrameData_O_i[10]),
    .X(FrameData_O[10])
);

my_buf data_outbuf_11 (
    .A(FrameData_O_i[11]),
    .X(FrameData_O[11])
);

my_buf data_outbuf_12 (
    .A(FrameData_O_i[12]),
    .X(FrameData_O[12])
);

my_buf data_outbuf_13 (
    .A(FrameData_O_i[13]),
    .X(FrameData_O[13])
);

my_buf data_outbuf_14 (
    .A(FrameData_O_i[14]),
    .X(FrameData_O[14])
);

my_buf data_outbuf_15 (
    .A(FrameData_O_i[15]),
    .X(FrameData_O[15])
);

my_buf data_outbuf_16 (
    .A(FrameData_O_i[16]),
    .X(FrameData_O[16])
);

my_buf data_outbuf_17 (
    .A(FrameData_O_i[17]),
    .X(FrameData_O[17])
);

my_buf data_outbuf_18 (
    .A(FrameData_O_i[18]),
    .X(FrameData_O[18])
);

my_buf data_outbuf_19 (
    .A(FrameData_O_i[19]),
    .X(FrameData_O[19])
);

my_buf data_outbuf_20 (
    .A(FrameData_O_i[20]),
    .X(FrameData_O[20])
);

my_buf data_outbuf_21 (
    .A(FrameData_O_i[21]),
    .X(FrameData_O[21])
);

my_buf data_outbuf_22 (
    .A(FrameData_O_i[22]),
    .X(FrameData_O[22])
);

my_buf data_outbuf_23 (
    .A(FrameData_O_i[23]),
    .X(FrameData_O[23])
);

my_buf data_outbuf_24 (
    .A(FrameData_O_i[24]),
    .X(FrameData_O[24])
);

my_buf data_outbuf_25 (
    .A(FrameData_O_i[25]),
    .X(FrameData_O[25])
);

my_buf data_outbuf_26 (
    .A(FrameData_O_i[26]),
    .X(FrameData_O[26])
);

my_buf data_outbuf_27 (
    .A(FrameData_O_i[27]),
    .X(FrameData_O[27])
);

my_buf data_outbuf_28 (
    .A(FrameData_O_i[28]),
    .X(FrameData_O[28])
);

my_buf data_outbuf_29 (
    .A(FrameData_O_i[29]),
    .X(FrameData_O[29])
);

my_buf data_outbuf_30 (
    .A(FrameData_O_i[30]),
    .X(FrameData_O[30])
);

my_buf data_outbuf_31 (
    .A(FrameData_O_i[31]),
    .X(FrameData_O[31])
);

assign FrameStrobe_O_i = FrameStrobe_i;

my_buf strobe_inbuf_0 (
    .A(FrameStrobe[0]),
    .X(FrameStrobe_i[0])
);

my_buf strobe_inbuf_1 (
    .A(FrameStrobe[1]),
    .X(FrameStrobe_i[1])
);

my_buf strobe_inbuf_2 (
    .A(FrameStrobe[2]),
    .X(FrameStrobe_i[2])
);

my_buf strobe_inbuf_3 (
    .A(FrameStrobe[3]),
    .X(FrameStrobe_i[3])
);

my_buf strobe_inbuf_4 (
    .A(FrameStrobe[4]),
    .X(FrameStrobe_i[4])
);

my_buf strobe_inbuf_5 (
    .A(FrameStrobe[5]),
    .X(FrameStrobe_i[5])
);

my_buf strobe_inbuf_6 (
    .A(FrameStrobe[6]),
    .X(FrameStrobe_i[6])
);

my_buf strobe_inbuf_7 (
    .A(FrameStrobe[7]),
    .X(FrameStrobe_i[7])
);

my_buf strobe_inbuf_8 (
    .A(FrameStrobe[8]),
    .X(FrameStrobe_i[8])
);

my_buf strobe_inbuf_9 (
    .A(FrameStrobe[9]),
    .X(FrameStrobe_i[9])
);

my_buf strobe_inbuf_10 (
    .A(FrameStrobe[10]),
    .X(FrameStrobe_i[10])
);

my_buf strobe_inbuf_11 (
    .A(FrameStrobe[11]),
    .X(FrameStrobe_i[11])
);

my_buf strobe_inbuf_12 (
    .A(FrameStrobe[12]),
    .X(FrameStrobe_i[12])
);

my_buf strobe_inbuf_13 (
    .A(FrameStrobe[13]),
    .X(FrameStrobe_i[13])
);

my_buf strobe_inbuf_14 (
    .A(FrameStrobe[14]),
    .X(FrameStrobe_i[14])
);

my_buf strobe_inbuf_15 (
    .A(FrameStrobe[15]),
    .X(FrameStrobe_i[15])
);

my_buf strobe_inbuf_16 (
    .A(FrameStrobe[16]),
    .X(FrameStrobe_i[16])
);

my_buf strobe_inbuf_17 (
    .A(FrameStrobe[17]),
    .X(FrameStrobe_i[17])
);

my_buf strobe_inbuf_18 (
    .A(FrameStrobe[18]),
    .X(FrameStrobe_i[18])
);

my_buf strobe_inbuf_19 (
    .A(FrameStrobe[19]),
    .X(FrameStrobe_i[19])
);

my_buf strobe_outbuf_0 (
    .A(FrameStrobe_O_i[0]),
    .X(FrameStrobe_O[0])
);

my_buf strobe_outbuf_1 (
    .A(FrameStrobe_O_i[1]),
    .X(FrameStrobe_O[1])
);

my_buf strobe_outbuf_2 (
    .A(FrameStrobe_O_i[2]),
    .X(FrameStrobe_O[2])
);

my_buf strobe_outbuf_3 (
    .A(FrameStrobe_O_i[3]),
    .X(FrameStrobe_O[3])
);

my_buf strobe_outbuf_4 (
    .A(FrameStrobe_O_i[4]),
    .X(FrameStrobe_O[4])
);

my_buf strobe_outbuf_5 (
    .A(FrameStrobe_O_i[5]),
    .X(FrameStrobe_O[5])
);

my_buf strobe_outbuf_6 (
    .A(FrameStrobe_O_i[6]),
    .X(FrameStrobe_O[6])
);

my_buf strobe_outbuf_7 (
    .A(FrameStrobe_O_i[7]),
    .X(FrameStrobe_O[7])
);

my_buf strobe_outbuf_8 (
    .A(FrameStrobe_O_i[8]),
    .X(FrameStrobe_O[8])
);

my_buf strobe_outbuf_9 (
    .A(FrameStrobe_O_i[9]),
    .X(FrameStrobe_O[9])
);

my_buf strobe_outbuf_10 (
    .A(FrameStrobe_O_i[10]),
    .X(FrameStrobe_O[10])
);

my_buf strobe_outbuf_11 (
    .A(FrameStrobe_O_i[11]),
    .X(FrameStrobe_O[11])
);

my_buf strobe_outbuf_12 (
    .A(FrameStrobe_O_i[12]),
    .X(FrameStrobe_O[12])
);

my_buf strobe_outbuf_13 (
    .A(FrameStrobe_O_i[13]),
    .X(FrameStrobe_O[13])
);

my_buf strobe_outbuf_14 (
    .A(FrameStrobe_O_i[14]),
    .X(FrameStrobe_O[14])
);

my_buf strobe_outbuf_15 (
    .A(FrameStrobe_O_i[15]),
    .X(FrameStrobe_O[15])
);

my_buf strobe_outbuf_16 (
    .A(FrameStrobe_O_i[16]),
    .X(FrameStrobe_O[16])
);

my_buf strobe_outbuf_17 (
    .A(FrameStrobe_O_i[17]),
    .X(FrameStrobe_O[17])
);

my_buf strobe_outbuf_18 (
    .A(FrameStrobe_O_i[18]),
    .X(FrameStrobe_O[18])
);

my_buf strobe_outbuf_19 (
    .A(FrameStrobe_O_i[19]),
    .X(FrameStrobe_O[19])
);


 //configuration storage latches
S_term_ConfigMem
`ifdef EMULATION
    #(
    .Emulate_Bitstream(Emulate_Bitstream)
    )
`endif
    Inst_S_term_ConfigMem
    (
    .FrameData(FrameData),
    .FrameStrobe(FrameStrobe),
    .ConfigBits(ConfigBits),
    .ConfigBits_N(ConfigBits_N)
);

S_term_switch_matrix Inst_S_term_switch_matrix (
    .W_GBUF_FEED_END0(W_GBUF_FEED_END[0]),
    .W_GBUF_FEED_END1(W_GBUF_FEED_END[1]),
    .W_GBUF_FEED_END2(W_GBUF_FEED_END[2]),
    .W_GBUF_FEED_END3(W_GBUF_FEED_END[3]),
    .E_GBUF_END0(E_GBUF_END[0]),
    .E_GBUF_END1(E_GBUF_END[1]),
    .E_GBUF_END2(E_GBUF_END[2]),
    .E_GBUF_END3(E_GBUF_END[3]),
    .S1END0(S1END[0]),
    .S1END1(S1END[1]),
    .S1END2(S1END[2]),
    .S1END3(S1END[3]),
    .S1END4(S1END[4]),
    .S1END5(S1END[5]),
    .S1END6(S1END[6]),
    .S1END7(S1END[7]),
    .S2MID0(S2MID[0]),
    .S2MID1(S2MID[1]),
    .S2MID2(S2MID[2]),
    .S2MID3(S2MID[3]),
    .S2MID4(S2MID[4]),
    .S2MID5(S2MID[5]),
    .S2MID6(S2MID[6]),
    .S2MID7(S2MID[7]),
    .S2END0(S2END[0]),
    .S2END1(S2END[1]),
    .S2END2(S2END[2]),
    .S2END3(S2END[3]),
    .S2END4(S2END[4]),
    .S2END5(S2END[5]),
    .S2END6(S2END[6]),
    .S2END7(S2END[7]),
    .W_GBUF_FEED_BEG0(W_GBUF_FEED_BEG[0]),
    .W_GBUF_FEED_BEG1(W_GBUF_FEED_BEG[1]),
    .W_GBUF_FEED_BEG2(W_GBUF_FEED_BEG[2]),
    .W_GBUF_FEED_BEG3(W_GBUF_FEED_BEG[3]),
    .N_GBUF_BEG0(N_GBUF_BEG[0]),
    .N_GBUF_BEG1(N_GBUF_BEG[1]),
    .N_GBUF_BEG2(N_GBUF_BEG[2]),
    .N_GBUF_BEG3(N_GBUF_BEG[3]),
    .E_GBUF_BEG0(E_GBUF_BEG[0]),
    .E_GBUF_BEG1(E_GBUF_BEG[1]),
    .E_GBUF_BEG2(E_GBUF_BEG[2]),
    .E_GBUF_BEG3(E_GBUF_BEG[3]),
    .N1BEG0(N1BEG[0]),
    .N1BEG1(N1BEG[1]),
    .N1BEG2(N1BEG[2]),
    .N1BEG3(N1BEG[3]),
    .N1BEG4(N1BEG[4]),
    .N1BEG5(N1BEG[5]),
    .N1BEG6(N1BEG[6]),
    .N1BEG7(N1BEG[7]),
    .N2BEG0(N2BEG[0]),
    .N2BEG1(N2BEG[1]),
    .N2BEG2(N2BEG[2]),
    .N2BEG3(N2BEG[3]),
    .N2BEG4(N2BEG[4]),
    .N2BEG5(N2BEG[5]),
    .N2BEG6(N2BEG[6]),
    .N2BEG7(N2BEG[7]),
    .N2BEGb0(N2BEGb[0]),
    .N2BEGb1(N2BEGb[1]),
    .N2BEGb2(N2BEGb[2]),
    .N2BEGb3(N2BEGb[3]),
    .N2BEGb4(N2BEGb[4]),
    .N2BEGb5(N2BEGb[5]),
    .N2BEGb6(N2BEGb[6]),
    .N2BEGb7(N2BEGb[7]),
    .Co0(Co[0]),
    .ConfigBits(ConfigBits[56-1:0]),
    .ConfigBits_N(ConfigBits_N[56-1:0])
);

endmodule
module SW_term_ConfigMem
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=20
    )
    (
        input  [FrameBitsPerRow - 1:0] FrameData,
        input  [MaxFramesPerCol - 1:0] FrameStrobe,
        output  [NoConfigBits - 1:0] ConfigBits,
        output  [NoConfigBits - 1:0] ConfigBits_N
    );

`ifdef EMULATION
assign ConfigBits[19] = Emulate_Bitstream[31];
assign ConfigBits[18] = Emulate_Bitstream[30];
assign ConfigBits[17] = Emulate_Bitstream[29];
assign ConfigBits[16] = Emulate_Bitstream[28];
assign ConfigBits[15] = Emulate_Bitstream[27];
assign ConfigBits[14] = Emulate_Bitstream[26];
assign ConfigBits[13] = Emulate_Bitstream[25];
assign ConfigBits[12] = Emulate_Bitstream[24];
assign ConfigBits[11] = Emulate_Bitstream[23];
assign ConfigBits[10] = Emulate_Bitstream[22];
assign ConfigBits[9] = Emulate_Bitstream[21];
assign ConfigBits[8] = Emulate_Bitstream[20];
assign ConfigBits[7] = Emulate_Bitstream[19];
assign ConfigBits[6] = Emulate_Bitstream[18];
assign ConfigBits[5] = Emulate_Bitstream[17];
assign ConfigBits[4] = Emulate_Bitstream[16];
assign ConfigBits[3] = Emulate_Bitstream[15];
assign ConfigBits[2] = Emulate_Bitstream[14];
assign ConfigBits[1] = Emulate_Bitstream[13];
assign ConfigBits[0] = Emulate_Bitstream[12];
`else

 //instantiate frame latches
config_latch Inst_frame0_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[19]),
    .QN(ConfigBits_N[19])
);

config_latch Inst_frame0_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[18]),
    .QN(ConfigBits_N[18])
);

config_latch Inst_frame0_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[17]),
    .QN(ConfigBits_N[17])
);

config_latch Inst_frame0_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[16]),
    .QN(ConfigBits_N[16])
);

config_latch Inst_frame0_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[15]),
    .QN(ConfigBits_N[15])
);

config_latch Inst_frame0_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[14]),
    .QN(ConfigBits_N[14])
);

config_latch Inst_frame0_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[13]),
    .QN(ConfigBits_N[13])
);

config_latch Inst_frame0_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[12]),
    .QN(ConfigBits_N[12])
);

config_latch Inst_frame0_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[11]),
    .QN(ConfigBits_N[11])
);

config_latch Inst_frame0_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[10]),
    .QN(ConfigBits_N[10])
);

config_latch Inst_frame0_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[9]),
    .QN(ConfigBits_N[9])
);

config_latch Inst_frame0_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[8]),
    .QN(ConfigBits_N[8])
);

config_latch Inst_frame0_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[7]),
    .QN(ConfigBits_N[7])
);

config_latch Inst_frame0_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[6]),
    .QN(ConfigBits_N[6])
);

config_latch Inst_frame0_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[5]),
    .QN(ConfigBits_N[5])
);

config_latch Inst_frame0_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[4]),
    .QN(ConfigBits_N[4])
);

config_latch Inst_frame0_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[3]),
    .QN(ConfigBits_N[3])
);

config_latch Inst_frame0_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[2]),
    .QN(ConfigBits_N[2])
);

config_latch Inst_frame0_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[1]),
    .QN(ConfigBits_N[1])
);

config_latch Inst_frame0_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[0]),
    .QN(ConfigBits_N[0])
);

`endif
endmodule
 // NumberOfConfigBits: 16
module SW_term_switch_matrix
    #(
        parameter NoConfigBits=16
    )
    (
        input  S_GBUF_FEED_END0,
        input  S_GBUF_FEED_END1,
        input  S_GBUF_FEED_END2,
        input  S_GBUF_FEED_END3,
        input  W_GBUF_FEED_END0,
        input  W_GBUF_FEED_END1,
        input  W_GBUF_FEED_END2,
        input  W_GBUF_FEED_END3,
        input  GBUF_A_OUT,
        input  GBUF_B_OUT,
        input  GBUF_C_OUT,
        input  GBUF_D_OUT,
        input  SYS_RESET_RESET,
        output  N_GBUF_BEG0,
        output  N_GBUF_BEG1,
        output  N_GBUF_BEG2,
        output  N_GBUF_BEG3,
        output  E_GBUF_BEG0,
        output  E_GBUF_BEG1,
        output  E_GBUF_BEG2,
        output  E_GBUF_BEG3,
        output  GBUF_A_IN,
        output  GBUF_B_IN,
        output  GBUF_C_IN,
        output  GBUF_D_IN,
 //global
        input  [NoConfigBits-1:0] ConfigBits,
        input  [NoConfigBits-1:0] ConfigBits_N
);
parameter GND0 = 1'b0;
parameter GND = 1'b0;
parameter VCC0 = 1'b1;
parameter VCC = 1'b1;
parameter VDD0 = 1'b1;
parameter VDD = 1'b1;

wire[9-1:0] GBUF_A_IN_input;
wire[9-1:0] GBUF_B_IN_input;
wire[9-1:0] GBUF_C_IN_input;
wire[9-1:0] GBUF_D_IN_input;
 //The configuration bits (if any) are just a long shift register
 //This shift register is padded to an even number of flops/latches
 //switch matrix multiplexer N_GBUF_BEG0 MUX-1
assign N_GBUF_BEG0 = GBUF_A_OUT;

 //switch matrix multiplexer N_GBUF_BEG1 MUX-1
assign N_GBUF_BEG1 = GBUF_B_OUT;

 //switch matrix multiplexer N_GBUF_BEG2 MUX-1
assign N_GBUF_BEG2 = GBUF_C_OUT;

 //switch matrix multiplexer N_GBUF_BEG3 MUX-1
assign N_GBUF_BEG3 = GBUF_D_OUT;

 //switch matrix multiplexer E_GBUF_BEG0 MUX-1
assign E_GBUF_BEG0 = GBUF_A_OUT;

 //switch matrix multiplexer E_GBUF_BEG1 MUX-1
assign E_GBUF_BEG1 = GBUF_B_OUT;

 //switch matrix multiplexer E_GBUF_BEG2 MUX-1
assign E_GBUF_BEG2 = GBUF_C_OUT;

 //switch matrix multiplexer E_GBUF_BEG3 MUX-1
assign E_GBUF_BEG3 = GBUF_D_OUT;

 //switch matrix multiplexer GBUF_A_IN MUX-9
assign GBUF_A_IN_input = {SYS_RESET_RESET,W_GBUF_FEED_END3,W_GBUF_FEED_END2,W_GBUF_FEED_END1,W_GBUF_FEED_END0,S_GBUF_FEED_END3,S_GBUF_FEED_END2,S_GBUF_FEED_END1,S_GBUF_FEED_END0};
cus_mux161 inst_cus_mux161_GBUF_A_IN (
    .A0(GBUF_A_IN_input[0]),
    .A1(GBUF_A_IN_input[1]),
    .A2(GBUF_A_IN_input[2]),
    .A3(GBUF_A_IN_input[3]),
    .A4(GBUF_A_IN_input[4]),
    .A5(GBUF_A_IN_input[5]),
    .A6(GBUF_A_IN_input[6]),
    .A7(GBUF_A_IN_input[7]),
    .A8(GBUF_A_IN_input[8]),
    .A9(GND0),
    .A10(GND0),
    .A11(GND0),
    .A12(GND0),
    .A13(GND0),
    .A14(GND0),
    .A15(GND0),
    .S0(ConfigBits[0+0]),
    .S0N(ConfigBits_N[0+0]),
    .S1(ConfigBits[0+1]),
    .S1N(ConfigBits_N[0+1]),
    .S2(ConfigBits[0+2]),
    .S2N(ConfigBits_N[0+2]),
    .S3(ConfigBits[0+3]),
    .S3N(ConfigBits_N[0+3]),
    .X(GBUF_A_IN)
);

 //switch matrix multiplexer GBUF_B_IN MUX-9
assign GBUF_B_IN_input = {SYS_RESET_RESET,W_GBUF_FEED_END3,W_GBUF_FEED_END2,W_GBUF_FEED_END1,W_GBUF_FEED_END0,S_GBUF_FEED_END3,S_GBUF_FEED_END2,S_GBUF_FEED_END1,S_GBUF_FEED_END0};
cus_mux161 inst_cus_mux161_GBUF_B_IN (
    .A0(GBUF_B_IN_input[0]),
    .A1(GBUF_B_IN_input[1]),
    .A2(GBUF_B_IN_input[2]),
    .A3(GBUF_B_IN_input[3]),
    .A4(GBUF_B_IN_input[4]),
    .A5(GBUF_B_IN_input[5]),
    .A6(GBUF_B_IN_input[6]),
    .A7(GBUF_B_IN_input[7]),
    .A8(GBUF_B_IN_input[8]),
    .A9(GND0),
    .A10(GND0),
    .A11(GND0),
    .A12(GND0),
    .A13(GND0),
    .A14(GND0),
    .A15(GND0),
    .S0(ConfigBits[4+0]),
    .S0N(ConfigBits_N[4+0]),
    .S1(ConfigBits[4+1]),
    .S1N(ConfigBits_N[4+1]),
    .S2(ConfigBits[4+2]),
    .S2N(ConfigBits_N[4+2]),
    .S3(ConfigBits[4+3]),
    .S3N(ConfigBits_N[4+3]),
    .X(GBUF_B_IN)
);

 //switch matrix multiplexer GBUF_C_IN MUX-9
assign GBUF_C_IN_input = {SYS_RESET_RESET,W_GBUF_FEED_END3,W_GBUF_FEED_END2,W_GBUF_FEED_END1,W_GBUF_FEED_END0,S_GBUF_FEED_END3,S_GBUF_FEED_END2,S_GBUF_FEED_END1,S_GBUF_FEED_END0};
cus_mux161 inst_cus_mux161_GBUF_C_IN (
    .A0(GBUF_C_IN_input[0]),
    .A1(GBUF_C_IN_input[1]),
    .A2(GBUF_C_IN_input[2]),
    .A3(GBUF_C_IN_input[3]),
    .A4(GBUF_C_IN_input[4]),
    .A5(GBUF_C_IN_input[5]),
    .A6(GBUF_C_IN_input[6]),
    .A7(GBUF_C_IN_input[7]),
    .A8(GBUF_C_IN_input[8]),
    .A9(GND0),
    .A10(GND0),
    .A11(GND0),
    .A12(GND0),
    .A13(GND0),
    .A14(GND0),
    .A15(GND0),
    .S0(ConfigBits[8+0]),
    .S0N(ConfigBits_N[8+0]),
    .S1(ConfigBits[8+1]),
    .S1N(ConfigBits_N[8+1]),
    .S2(ConfigBits[8+2]),
    .S2N(ConfigBits_N[8+2]),
    .S3(ConfigBits[8+3]),
    .S3N(ConfigBits_N[8+3]),
    .X(GBUF_C_IN)
);

 //switch matrix multiplexer GBUF_D_IN MUX-9
assign GBUF_D_IN_input = {SYS_RESET_RESET,W_GBUF_FEED_END3,W_GBUF_FEED_END2,W_GBUF_FEED_END1,W_GBUF_FEED_END0,S_GBUF_FEED_END3,S_GBUF_FEED_END2,S_GBUF_FEED_END1,S_GBUF_FEED_END0};
cus_mux161 inst_cus_mux161_GBUF_D_IN (
    .A0(GBUF_D_IN_input[0]),
    .A1(GBUF_D_IN_input[1]),
    .A2(GBUF_D_IN_input[2]),
    .A3(GBUF_D_IN_input[3]),
    .A4(GBUF_D_IN_input[4]),
    .A5(GBUF_D_IN_input[5]),
    .A6(GBUF_D_IN_input[6]),
    .A7(GBUF_D_IN_input[7]),
    .A8(GBUF_D_IN_input[8]),
    .A9(GND0),
    .A10(GND0),
    .A11(GND0),
    .A12(GND0),
    .A13(GND0),
    .A14(GND0),
    .A15(GND0),
    .S0(ConfigBits[12+0]),
    .S0N(ConfigBits_N[12+0]),
    .S1(ConfigBits[12+1]),
    .S1N(ConfigBits_N[12+1]),
    .S2(ConfigBits[12+2]),
    .S2N(ConfigBits_N[12+2]),
    .S3(ConfigBits[12+3]),
    .S3N(ConfigBits_N[12+3]),
    .X(GBUF_D_IN)
);

endmodule
module SW_term
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=20
    )
    (
 //N
        input  [3:0] S_GBUF_FEED_END,        //Port(Name=S_GBUF_FEED_END,IO=INPUT,XOffset=0,YOffset=1,WireCount=4,Side=N)
        output  [3:0] N_GBUF_BEG,        //Port(Name=N_GBUF_BEG,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=4,Side=N)
 //E
        input  [3:0] W_GBUF_FEED_END,        //Port(Name=W_GBUF_FEED_END,IO=INPUT,XOffset=-1,YOffset=0,WireCount=4,Side=E)
        output  [3:0] E_GBUF_BEG,        //Port(Name=E_GBUF_BEG,IO=OUTPUT,XOffset=1,YOffset=0,WireCount=4,Side=E)
        input  SYS_RESET_RESET_top,
    //Tile IO ports from BELs
        input  [FrameBitsPerRow-1:0] FrameData, //CONFIG_PORT
        output  [FrameBitsPerRow-1:0] FrameData_O,
        input  [MaxFramesPerCol-1:0] FrameStrobe, //CONFIG_PORT
        output  [MaxFramesPerCol-1:0] FrameStrobe_O
    //global
);
 //signal declarations
 //BEL ports (e.g., slices)
wire GBUF_A_IN;
wire GBUF_A_OUT;
wire GBUF_B_IN;
wire GBUF_B_OUT;
wire GBUF_C_IN;
wire GBUF_C_OUT;
wire GBUF_D_IN;
wire GBUF_D_OUT;
wire SYS_RESET_RESET;
 //Jump wires
 //internal configuration data signal to daisy-chain all BELs (if any and in the order they are listed in the fabric.csv)
wire[NoConfigBits-1:0] ConfigBits;
wire[NoConfigBits-1:0] ConfigBits_N;

 //Connection for outgoing wires
wire[FrameBitsPerRow-1:0] FrameData_i;
wire[FrameBitsPerRow-1:0] FrameData_O_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_O_i;

assign FrameData_O_i = FrameData_i;

my_buf data_inbuf_0 (
    .A(FrameData[0]),
    .X(FrameData_i[0])
);

my_buf data_inbuf_1 (
    .A(FrameData[1]),
    .X(FrameData_i[1])
);

my_buf data_inbuf_2 (
    .A(FrameData[2]),
    .X(FrameData_i[2])
);

my_buf data_inbuf_3 (
    .A(FrameData[3]),
    .X(FrameData_i[3])
);

my_buf data_inbuf_4 (
    .A(FrameData[4]),
    .X(FrameData_i[4])
);

my_buf data_inbuf_5 (
    .A(FrameData[5]),
    .X(FrameData_i[5])
);

my_buf data_inbuf_6 (
    .A(FrameData[6]),
    .X(FrameData_i[6])
);

my_buf data_inbuf_7 (
    .A(FrameData[7]),
    .X(FrameData_i[7])
);

my_buf data_inbuf_8 (
    .A(FrameData[8]),
    .X(FrameData_i[8])
);

my_buf data_inbuf_9 (
    .A(FrameData[9]),
    .X(FrameData_i[9])
);

my_buf data_inbuf_10 (
    .A(FrameData[10]),
    .X(FrameData_i[10])
);

my_buf data_inbuf_11 (
    .A(FrameData[11]),
    .X(FrameData_i[11])
);

my_buf data_inbuf_12 (
    .A(FrameData[12]),
    .X(FrameData_i[12])
);

my_buf data_inbuf_13 (
    .A(FrameData[13]),
    .X(FrameData_i[13])
);

my_buf data_inbuf_14 (
    .A(FrameData[14]),
    .X(FrameData_i[14])
);

my_buf data_inbuf_15 (
    .A(FrameData[15]),
    .X(FrameData_i[15])
);

my_buf data_inbuf_16 (
    .A(FrameData[16]),
    .X(FrameData_i[16])
);

my_buf data_inbuf_17 (
    .A(FrameData[17]),
    .X(FrameData_i[17])
);

my_buf data_inbuf_18 (
    .A(FrameData[18]),
    .X(FrameData_i[18])
);

my_buf data_inbuf_19 (
    .A(FrameData[19]),
    .X(FrameData_i[19])
);

my_buf data_inbuf_20 (
    .A(FrameData[20]),
    .X(FrameData_i[20])
);

my_buf data_inbuf_21 (
    .A(FrameData[21]),
    .X(FrameData_i[21])
);

my_buf data_inbuf_22 (
    .A(FrameData[22]),
    .X(FrameData_i[22])
);

my_buf data_inbuf_23 (
    .A(FrameData[23]),
    .X(FrameData_i[23])
);

my_buf data_inbuf_24 (
    .A(FrameData[24]),
    .X(FrameData_i[24])
);

my_buf data_inbuf_25 (
    .A(FrameData[25]),
    .X(FrameData_i[25])
);

my_buf data_inbuf_26 (
    .A(FrameData[26]),
    .X(FrameData_i[26])
);

my_buf data_inbuf_27 (
    .A(FrameData[27]),
    .X(FrameData_i[27])
);

my_buf data_inbuf_28 (
    .A(FrameData[28]),
    .X(FrameData_i[28])
);

my_buf data_inbuf_29 (
    .A(FrameData[29]),
    .X(FrameData_i[29])
);

my_buf data_inbuf_30 (
    .A(FrameData[30]),
    .X(FrameData_i[30])
);

my_buf data_inbuf_31 (
    .A(FrameData[31]),
    .X(FrameData_i[31])
);

my_buf data_outbuf_0 (
    .A(FrameData_O_i[0]),
    .X(FrameData_O[0])
);

my_buf data_outbuf_1 (
    .A(FrameData_O_i[1]),
    .X(FrameData_O[1])
);

my_buf data_outbuf_2 (
    .A(FrameData_O_i[2]),
    .X(FrameData_O[2])
);

my_buf data_outbuf_3 (
    .A(FrameData_O_i[3]),
    .X(FrameData_O[3])
);

my_buf data_outbuf_4 (
    .A(FrameData_O_i[4]),
    .X(FrameData_O[4])
);

my_buf data_outbuf_5 (
    .A(FrameData_O_i[5]),
    .X(FrameData_O[5])
);

my_buf data_outbuf_6 (
    .A(FrameData_O_i[6]),
    .X(FrameData_O[6])
);

my_buf data_outbuf_7 (
    .A(FrameData_O_i[7]),
    .X(FrameData_O[7])
);

my_buf data_outbuf_8 (
    .A(FrameData_O_i[8]),
    .X(FrameData_O[8])
);

my_buf data_outbuf_9 (
    .A(FrameData_O_i[9]),
    .X(FrameData_O[9])
);

my_buf data_outbuf_10 (
    .A(FrameData_O_i[10]),
    .X(FrameData_O[10])
);

my_buf data_outbuf_11 (
    .A(FrameData_O_i[11]),
    .X(FrameData_O[11])
);

my_buf data_outbuf_12 (
    .A(FrameData_O_i[12]),
    .X(FrameData_O[12])
);

my_buf data_outbuf_13 (
    .A(FrameData_O_i[13]),
    .X(FrameData_O[13])
);

my_buf data_outbuf_14 (
    .A(FrameData_O_i[14]),
    .X(FrameData_O[14])
);

my_buf data_outbuf_15 (
    .A(FrameData_O_i[15]),
    .X(FrameData_O[15])
);

my_buf data_outbuf_16 (
    .A(FrameData_O_i[16]),
    .X(FrameData_O[16])
);

my_buf data_outbuf_17 (
    .A(FrameData_O_i[17]),
    .X(FrameData_O[17])
);

my_buf data_outbuf_18 (
    .A(FrameData_O_i[18]),
    .X(FrameData_O[18])
);

my_buf data_outbuf_19 (
    .A(FrameData_O_i[19]),
    .X(FrameData_O[19])
);

my_buf data_outbuf_20 (
    .A(FrameData_O_i[20]),
    .X(FrameData_O[20])
);

my_buf data_outbuf_21 (
    .A(FrameData_O_i[21]),
    .X(FrameData_O[21])
);

my_buf data_outbuf_22 (
    .A(FrameData_O_i[22]),
    .X(FrameData_O[22])
);

my_buf data_outbuf_23 (
    .A(FrameData_O_i[23]),
    .X(FrameData_O[23])
);

my_buf data_outbuf_24 (
    .A(FrameData_O_i[24]),
    .X(FrameData_O[24])
);

my_buf data_outbuf_25 (
    .A(FrameData_O_i[25]),
    .X(FrameData_O[25])
);

my_buf data_outbuf_26 (
    .A(FrameData_O_i[26]),
    .X(FrameData_O[26])
);

my_buf data_outbuf_27 (
    .A(FrameData_O_i[27]),
    .X(FrameData_O[27])
);

my_buf data_outbuf_28 (
    .A(FrameData_O_i[28]),
    .X(FrameData_O[28])
);

my_buf data_outbuf_29 (
    .A(FrameData_O_i[29]),
    .X(FrameData_O[29])
);

my_buf data_outbuf_30 (
    .A(FrameData_O_i[30]),
    .X(FrameData_O[30])
);

my_buf data_outbuf_31 (
    .A(FrameData_O_i[31]),
    .X(FrameData_O[31])
);

assign FrameStrobe_O_i = FrameStrobe_i;

my_buf strobe_inbuf_0 (
    .A(FrameStrobe[0]),
    .X(FrameStrobe_i[0])
);

my_buf strobe_inbuf_1 (
    .A(FrameStrobe[1]),
    .X(FrameStrobe_i[1])
);

my_buf strobe_inbuf_2 (
    .A(FrameStrobe[2]),
    .X(FrameStrobe_i[2])
);

my_buf strobe_inbuf_3 (
    .A(FrameStrobe[3]),
    .X(FrameStrobe_i[3])
);

my_buf strobe_inbuf_4 (
    .A(FrameStrobe[4]),
    .X(FrameStrobe_i[4])
);

my_buf strobe_inbuf_5 (
    .A(FrameStrobe[5]),
    .X(FrameStrobe_i[5])
);

my_buf strobe_inbuf_6 (
    .A(FrameStrobe[6]),
    .X(FrameStrobe_i[6])
);

my_buf strobe_inbuf_7 (
    .A(FrameStrobe[7]),
    .X(FrameStrobe_i[7])
);

my_buf strobe_inbuf_8 (
    .A(FrameStrobe[8]),
    .X(FrameStrobe_i[8])
);

my_buf strobe_inbuf_9 (
    .A(FrameStrobe[9]),
    .X(FrameStrobe_i[9])
);

my_buf strobe_inbuf_10 (
    .A(FrameStrobe[10]),
    .X(FrameStrobe_i[10])
);

my_buf strobe_inbuf_11 (
    .A(FrameStrobe[11]),
    .X(FrameStrobe_i[11])
);

my_buf strobe_inbuf_12 (
    .A(FrameStrobe[12]),
    .X(FrameStrobe_i[12])
);

my_buf strobe_inbuf_13 (
    .A(FrameStrobe[13]),
    .X(FrameStrobe_i[13])
);

my_buf strobe_inbuf_14 (
    .A(FrameStrobe[14]),
    .X(FrameStrobe_i[14])
);

my_buf strobe_inbuf_15 (
    .A(FrameStrobe[15]),
    .X(FrameStrobe_i[15])
);

my_buf strobe_inbuf_16 (
    .A(FrameStrobe[16]),
    .X(FrameStrobe_i[16])
);

my_buf strobe_inbuf_17 (
    .A(FrameStrobe[17]),
    .X(FrameStrobe_i[17])
);

my_buf strobe_inbuf_18 (
    .A(FrameStrobe[18]),
    .X(FrameStrobe_i[18])
);

my_buf strobe_inbuf_19 (
    .A(FrameStrobe[19]),
    .X(FrameStrobe_i[19])
);

my_buf strobe_outbuf_0 (
    .A(FrameStrobe_O_i[0]),
    .X(FrameStrobe_O[0])
);

my_buf strobe_outbuf_1 (
    .A(FrameStrobe_O_i[1]),
    .X(FrameStrobe_O[1])
);

my_buf strobe_outbuf_2 (
    .A(FrameStrobe_O_i[2]),
    .X(FrameStrobe_O[2])
);

my_buf strobe_outbuf_3 (
    .A(FrameStrobe_O_i[3]),
    .X(FrameStrobe_O[3])
);

my_buf strobe_outbuf_4 (
    .A(FrameStrobe_O_i[4]),
    .X(FrameStrobe_O[4])
);

my_buf strobe_outbuf_5 (
    .A(FrameStrobe_O_i[5]),
    .X(FrameStrobe_O[5])
);

my_buf strobe_outbuf_6 (
    .A(FrameStrobe_O_i[6]),
    .X(FrameStrobe_O[6])
);

my_buf strobe_outbuf_7 (
    .A(FrameStrobe_O_i[7]),
    .X(FrameStrobe_O[7])
);

my_buf strobe_outbuf_8 (
    .A(FrameStrobe_O_i[8]),
    .X(FrameStrobe_O[8])
);

my_buf strobe_outbuf_9 (
    .A(FrameStrobe_O_i[9]),
    .X(FrameStrobe_O[9])
);

my_buf strobe_outbuf_10 (
    .A(FrameStrobe_O_i[10]),
    .X(FrameStrobe_O[10])
);

my_buf strobe_outbuf_11 (
    .A(FrameStrobe_O_i[11]),
    .X(FrameStrobe_O[11])
);

my_buf strobe_outbuf_12 (
    .A(FrameStrobe_O_i[12]),
    .X(FrameStrobe_O[12])
);

my_buf strobe_outbuf_13 (
    .A(FrameStrobe_O_i[13]),
    .X(FrameStrobe_O[13])
);

my_buf strobe_outbuf_14 (
    .A(FrameStrobe_O_i[14]),
    .X(FrameStrobe_O[14])
);

my_buf strobe_outbuf_15 (
    .A(FrameStrobe_O_i[15]),
    .X(FrameStrobe_O[15])
);

my_buf strobe_outbuf_16 (
    .A(FrameStrobe_O_i[16]),
    .X(FrameStrobe_O[16])
);

my_buf strobe_outbuf_17 (
    .A(FrameStrobe_O_i[17]),
    .X(FrameStrobe_O[17])
);

my_buf strobe_outbuf_18 (
    .A(FrameStrobe_O_i[18]),
    .X(FrameStrobe_O[18])
);

my_buf strobe_outbuf_19 (
    .A(FrameStrobe_O_i[19]),
    .X(FrameStrobe_O[19])
);


 //configuration storage latches
SW_term_ConfigMem
`ifdef EMULATION
    #(
    .Emulate_Bitstream(Emulate_Bitstream)
    )
`endif
    Inst_SW_term_ConfigMem
    (
    .FrameData(FrameData),
    .FrameStrobe(FrameStrobe),
    .ConfigBits(ConfigBits),
    .ConfigBits_N(ConfigBits_N)
);


 //BEL component instantiations
GBUF Inst_GBUF_A_GBUF (
    .IN(GBUF_A_IN),
    .OUT(GBUF_A_OUT),
    .ConfigBits(ConfigBits[1-1:0])
);

GBUF Inst_GBUF_B_GBUF (
    .IN(GBUF_B_IN),
    .OUT(GBUF_B_OUT),
    .ConfigBits(ConfigBits[2-1:1])
);

GBUF Inst_GBUF_C_GBUF (
    .IN(GBUF_C_IN),
    .OUT(GBUF_C_OUT),
    .ConfigBits(ConfigBits[3-1:2])
);

GBUF Inst_GBUF_D_GBUF (
    .IN(GBUF_D_IN),
    .OUT(GBUF_D_OUT),
    .ConfigBits(ConfigBits[4-1:3])
);

SYS_RESET Inst_SYS_RESET_SYS_RESET (
    .RESET(SYS_RESET_RESET),
    .RESET_top(SYS_RESET_RESET_top)
);

SW_term_switch_matrix Inst_SW_term_switch_matrix (
    .S_GBUF_FEED_END0(S_GBUF_FEED_END[0]),
    .S_GBUF_FEED_END1(S_GBUF_FEED_END[1]),
    .S_GBUF_FEED_END2(S_GBUF_FEED_END[2]),
    .S_GBUF_FEED_END3(S_GBUF_FEED_END[3]),
    .W_GBUF_FEED_END0(W_GBUF_FEED_END[0]),
    .W_GBUF_FEED_END1(W_GBUF_FEED_END[1]),
    .W_GBUF_FEED_END2(W_GBUF_FEED_END[2]),
    .W_GBUF_FEED_END3(W_GBUF_FEED_END[3]),
    .GBUF_A_OUT(GBUF_A_OUT),
    .GBUF_B_OUT(GBUF_B_OUT),
    .GBUF_C_OUT(GBUF_C_OUT),
    .GBUF_D_OUT(GBUF_D_OUT),
    .SYS_RESET_RESET(SYS_RESET_RESET),
    .N_GBUF_BEG0(N_GBUF_BEG[0]),
    .N_GBUF_BEG1(N_GBUF_BEG[1]),
    .N_GBUF_BEG2(N_GBUF_BEG[2]),
    .N_GBUF_BEG3(N_GBUF_BEG[3]),
    .E_GBUF_BEG0(E_GBUF_BEG[0]),
    .E_GBUF_BEG1(E_GBUF_BEG[1]),
    .E_GBUF_BEG2(E_GBUF_BEG[2]),
    .E_GBUF_BEG3(E_GBUF_BEG[3]),
    .GBUF_A_IN(GBUF_A_IN),
    .GBUF_B_IN(GBUF_B_IN),
    .GBUF_C_IN(GBUF_C_IN),
    .GBUF_D_IN(GBUF_D_IN),
    .ConfigBits(ConfigBits[20-1:4]),
    .ConfigBits_N(ConfigBits_N[20-1:4])
);

endmodule
module W_IO2_ConfigMem
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=80
    )
    (
        input  [FrameBitsPerRow - 1:0] FrameData,
        input  [MaxFramesPerCol - 1:0] FrameStrobe,
        output  [NoConfigBits - 1:0] ConfigBits,
        output  [NoConfigBits - 1:0] ConfigBits_N
    );

`ifdef EMULATION
assign ConfigBits[79] = Emulate_Bitstream[31];
assign ConfigBits[78] = Emulate_Bitstream[30];
assign ConfigBits[77] = Emulate_Bitstream[29];
assign ConfigBits[76] = Emulate_Bitstream[28];
assign ConfigBits[75] = Emulate_Bitstream[27];
assign ConfigBits[74] = Emulate_Bitstream[26];
assign ConfigBits[73] = Emulate_Bitstream[25];
assign ConfigBits[72] = Emulate_Bitstream[24];
assign ConfigBits[71] = Emulate_Bitstream[23];
assign ConfigBits[70] = Emulate_Bitstream[22];
assign ConfigBits[69] = Emulate_Bitstream[21];
assign ConfigBits[68] = Emulate_Bitstream[20];
assign ConfigBits[67] = Emulate_Bitstream[19];
assign ConfigBits[66] = Emulate_Bitstream[18];
assign ConfigBits[65] = Emulate_Bitstream[17];
assign ConfigBits[64] = Emulate_Bitstream[16];
assign ConfigBits[63] = Emulate_Bitstream[15];
assign ConfigBits[62] = Emulate_Bitstream[14];
assign ConfigBits[61] = Emulate_Bitstream[13];
assign ConfigBits[60] = Emulate_Bitstream[12];
assign ConfigBits[59] = Emulate_Bitstream[11];
assign ConfigBits[58] = Emulate_Bitstream[10];
assign ConfigBits[57] = Emulate_Bitstream[9];
assign ConfigBits[56] = Emulate_Bitstream[8];
assign ConfigBits[55] = Emulate_Bitstream[7];
assign ConfigBits[54] = Emulate_Bitstream[6];
assign ConfigBits[53] = Emulate_Bitstream[5];
assign ConfigBits[52] = Emulate_Bitstream[4];
assign ConfigBits[51] = Emulate_Bitstream[3];
assign ConfigBits[50] = Emulate_Bitstream[2];
assign ConfigBits[49] = Emulate_Bitstream[1];
assign ConfigBits[48] = Emulate_Bitstream[0];
assign ConfigBits[47] = Emulate_Bitstream[63];
assign ConfigBits[46] = Emulate_Bitstream[62];
assign ConfigBits[45] = Emulate_Bitstream[61];
assign ConfigBits[44] = Emulate_Bitstream[60];
assign ConfigBits[43] = Emulate_Bitstream[59];
assign ConfigBits[42] = Emulate_Bitstream[58];
assign ConfigBits[41] = Emulate_Bitstream[57];
assign ConfigBits[40] = Emulate_Bitstream[56];
assign ConfigBits[39] = Emulate_Bitstream[55];
assign ConfigBits[38] = Emulate_Bitstream[54];
assign ConfigBits[37] = Emulate_Bitstream[53];
assign ConfigBits[36] = Emulate_Bitstream[52];
assign ConfigBits[35] = Emulate_Bitstream[51];
assign ConfigBits[34] = Emulate_Bitstream[50];
assign ConfigBits[33] = Emulate_Bitstream[49];
assign ConfigBits[32] = Emulate_Bitstream[48];
assign ConfigBits[31] = Emulate_Bitstream[47];
assign ConfigBits[30] = Emulate_Bitstream[46];
assign ConfigBits[29] = Emulate_Bitstream[45];
assign ConfigBits[28] = Emulate_Bitstream[44];
assign ConfigBits[27] = Emulate_Bitstream[43];
assign ConfigBits[26] = Emulate_Bitstream[42];
assign ConfigBits[25] = Emulate_Bitstream[41];
assign ConfigBits[24] = Emulate_Bitstream[40];
assign ConfigBits[23] = Emulate_Bitstream[39];
assign ConfigBits[22] = Emulate_Bitstream[38];
assign ConfigBits[21] = Emulate_Bitstream[37];
assign ConfigBits[20] = Emulate_Bitstream[36];
assign ConfigBits[19] = Emulate_Bitstream[35];
assign ConfigBits[18] = Emulate_Bitstream[34];
assign ConfigBits[17] = Emulate_Bitstream[33];
assign ConfigBits[16] = Emulate_Bitstream[32];
assign ConfigBits[15] = Emulate_Bitstream[95];
assign ConfigBits[14] = Emulate_Bitstream[94];
assign ConfigBits[13] = Emulate_Bitstream[93];
assign ConfigBits[12] = Emulate_Bitstream[92];
assign ConfigBits[11] = Emulate_Bitstream[91];
assign ConfigBits[10] = Emulate_Bitstream[90];
assign ConfigBits[9] = Emulate_Bitstream[89];
assign ConfigBits[8] = Emulate_Bitstream[88];
assign ConfigBits[7] = Emulate_Bitstream[87];
assign ConfigBits[6] = Emulate_Bitstream[86];
assign ConfigBits[5] = Emulate_Bitstream[85];
assign ConfigBits[4] = Emulate_Bitstream[84];
assign ConfigBits[3] = Emulate_Bitstream[83];
assign ConfigBits[2] = Emulate_Bitstream[82];
assign ConfigBits[1] = Emulate_Bitstream[81];
assign ConfigBits[0] = Emulate_Bitstream[80];
`else

 //instantiate frame latches
config_latch Inst_frame0_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[79]),
    .QN(ConfigBits_N[79])
);

config_latch Inst_frame0_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[78]),
    .QN(ConfigBits_N[78])
);

config_latch Inst_frame0_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[77]),
    .QN(ConfigBits_N[77])
);

config_latch Inst_frame0_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[76]),
    .QN(ConfigBits_N[76])
);

config_latch Inst_frame0_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[75]),
    .QN(ConfigBits_N[75])
);

config_latch Inst_frame0_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[74]),
    .QN(ConfigBits_N[74])
);

config_latch Inst_frame0_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[73]),
    .QN(ConfigBits_N[73])
);

config_latch Inst_frame0_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[72]),
    .QN(ConfigBits_N[72])
);

config_latch Inst_frame0_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[71]),
    .QN(ConfigBits_N[71])
);

config_latch Inst_frame0_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[70]),
    .QN(ConfigBits_N[70])
);

config_latch Inst_frame0_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[69]),
    .QN(ConfigBits_N[69])
);

config_latch Inst_frame0_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[68]),
    .QN(ConfigBits_N[68])
);

config_latch Inst_frame0_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[67]),
    .QN(ConfigBits_N[67])
);

config_latch Inst_frame0_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[66]),
    .QN(ConfigBits_N[66])
);

config_latch Inst_frame0_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[65]),
    .QN(ConfigBits_N[65])
);

config_latch Inst_frame0_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[64]),
    .QN(ConfigBits_N[64])
);

config_latch Inst_frame0_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[63]),
    .QN(ConfigBits_N[63])
);

config_latch Inst_frame0_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[62]),
    .QN(ConfigBits_N[62])
);

config_latch Inst_frame0_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[61]),
    .QN(ConfigBits_N[61])
);

config_latch Inst_frame0_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[60]),
    .QN(ConfigBits_N[60])
);

config_latch Inst_frame0_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[59]),
    .QN(ConfigBits_N[59])
);

config_latch Inst_frame0_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[58]),
    .QN(ConfigBits_N[58])
);

config_latch Inst_frame0_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[57]),
    .QN(ConfigBits_N[57])
);

config_latch Inst_frame0_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[56]),
    .QN(ConfigBits_N[56])
);

config_latch Inst_frame0_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[55]),
    .QN(ConfigBits_N[55])
);

config_latch Inst_frame0_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[54]),
    .QN(ConfigBits_N[54])
);

config_latch Inst_frame0_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[53]),
    .QN(ConfigBits_N[53])
);

config_latch Inst_frame0_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[52]),
    .QN(ConfigBits_N[52])
);

config_latch Inst_frame0_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[51]),
    .QN(ConfigBits_N[51])
);

config_latch Inst_frame0_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[50]),
    .QN(ConfigBits_N[50])
);

config_latch Inst_frame0_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[49]),
    .QN(ConfigBits_N[49])
);

config_latch Inst_frame0_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[48]),
    .QN(ConfigBits_N[48])
);

config_latch Inst_frame1_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[47]),
    .QN(ConfigBits_N[47])
);

config_latch Inst_frame1_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[46]),
    .QN(ConfigBits_N[46])
);

config_latch Inst_frame1_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[45]),
    .QN(ConfigBits_N[45])
);

config_latch Inst_frame1_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[44]),
    .QN(ConfigBits_N[44])
);

config_latch Inst_frame1_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[43]),
    .QN(ConfigBits_N[43])
);

config_latch Inst_frame1_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[42]),
    .QN(ConfigBits_N[42])
);

config_latch Inst_frame1_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[41]),
    .QN(ConfigBits_N[41])
);

config_latch Inst_frame1_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[40]),
    .QN(ConfigBits_N[40])
);

config_latch Inst_frame1_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[39]),
    .QN(ConfigBits_N[39])
);

config_latch Inst_frame1_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[38]),
    .QN(ConfigBits_N[38])
);

config_latch Inst_frame1_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[37]),
    .QN(ConfigBits_N[37])
);

config_latch Inst_frame1_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[36]),
    .QN(ConfigBits_N[36])
);

config_latch Inst_frame1_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[35]),
    .QN(ConfigBits_N[35])
);

config_latch Inst_frame1_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[34]),
    .QN(ConfigBits_N[34])
);

config_latch Inst_frame1_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[33]),
    .QN(ConfigBits_N[33])
);

config_latch Inst_frame1_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[32]),
    .QN(ConfigBits_N[32])
);

config_latch Inst_frame1_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[31]),
    .QN(ConfigBits_N[31])
);

config_latch Inst_frame1_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[30]),
    .QN(ConfigBits_N[30])
);

config_latch Inst_frame1_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[29]),
    .QN(ConfigBits_N[29])
);

config_latch Inst_frame1_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[28]),
    .QN(ConfigBits_N[28])
);

config_latch Inst_frame1_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[27]),
    .QN(ConfigBits_N[27])
);

config_latch Inst_frame1_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[26]),
    .QN(ConfigBits_N[26])
);

config_latch Inst_frame1_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[25]),
    .QN(ConfigBits_N[25])
);

config_latch Inst_frame1_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[24]),
    .QN(ConfigBits_N[24])
);

config_latch Inst_frame1_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[23]),
    .QN(ConfigBits_N[23])
);

config_latch Inst_frame1_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[22]),
    .QN(ConfigBits_N[22])
);

config_latch Inst_frame1_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[21]),
    .QN(ConfigBits_N[21])
);

config_latch Inst_frame1_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[20]),
    .QN(ConfigBits_N[20])
);

config_latch Inst_frame1_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[19]),
    .QN(ConfigBits_N[19])
);

config_latch Inst_frame1_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[18]),
    .QN(ConfigBits_N[18])
);

config_latch Inst_frame1_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[17]),
    .QN(ConfigBits_N[17])
);

config_latch Inst_frame1_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[16]),
    .QN(ConfigBits_N[16])
);

config_latch Inst_frame2_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[15]),
    .QN(ConfigBits_N[15])
);

config_latch Inst_frame2_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[14]),
    .QN(ConfigBits_N[14])
);

config_latch Inst_frame2_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[13]),
    .QN(ConfigBits_N[13])
);

config_latch Inst_frame2_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[12]),
    .QN(ConfigBits_N[12])
);

config_latch Inst_frame2_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[11]),
    .QN(ConfigBits_N[11])
);

config_latch Inst_frame2_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[10]),
    .QN(ConfigBits_N[10])
);

config_latch Inst_frame2_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[9]),
    .QN(ConfigBits_N[9])
);

config_latch Inst_frame2_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[8]),
    .QN(ConfigBits_N[8])
);

config_latch Inst_frame2_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[7]),
    .QN(ConfigBits_N[7])
);

config_latch Inst_frame2_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[6]),
    .QN(ConfigBits_N[6])
);

config_latch Inst_frame2_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[5]),
    .QN(ConfigBits_N[5])
);

config_latch Inst_frame2_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[4]),
    .QN(ConfigBits_N[4])
);

config_latch Inst_frame2_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[3]),
    .QN(ConfigBits_N[3])
);

config_latch Inst_frame2_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[2]),
    .QN(ConfigBits_N[2])
);

config_latch Inst_frame2_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[1]),
    .QN(ConfigBits_N[1])
);

config_latch Inst_frame2_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[0]),
    .QN(ConfigBits_N[0])
);

`endif
endmodule
 // NumberOfConfigBits: 74
module W_IO2_switch_matrix
    #(
        parameter NoConfigBits=74
    )
    (
        input  S_GBUF_FEED_END0,
        input  S_GBUF_FEED_END1,
        input  S_GBUF_FEED_END2,
        input  S_GBUF_FEED_END3,
        input  N_GBUF_END0,
        input  N_GBUF_END1,
        input  N_GBUF_END2,
        input  N_GBUF_END3,
        input  W1END0,
        input  W1END1,
        input  W1END2,
        input  W1END3,
        input  W1END4,
        input  W1END5,
        input  W1END6,
        input  W1END7,
        input  W2MID0,
        input  W2MID1,
        input  W2MID2,
        input  W2MID3,
        input  W2MID4,
        input  W2MID5,
        input  W2MID6,
        input  W2MID7,
        input  W2END0,
        input  W2END1,
        input  W2END2,
        input  W2END3,
        input  W2END4,
        input  W2END5,
        input  W2END6,
        input  W2END7,
        input  A_OUT,
        input  B_OUT,
        output  S_GBUF_FEED_BEG0,
        output  S_GBUF_FEED_BEG1,
        output  S_GBUF_FEED_BEG2,
        output  S_GBUF_FEED_BEG3,
        output  N_GBUF_BEG0,
        output  N_GBUF_BEG1,
        output  N_GBUF_BEG2,
        output  N_GBUF_BEG3,
        output  E1BEG0,
        output  E1BEG1,
        output  E1BEG2,
        output  E1BEG3,
        output  E1BEG4,
        output  E1BEG5,
        output  E1BEG6,
        output  E1BEG7,
        output  E2BEG0,
        output  E2BEG1,
        output  E2BEG2,
        output  E2BEG3,
        output  E2BEG4,
        output  E2BEG5,
        output  E2BEG6,
        output  E2BEG7,
        output  E2BEGb0,
        output  E2BEGb1,
        output  E2BEGb2,
        output  E2BEGb3,
        output  E2BEGb4,
        output  E2BEGb5,
        output  E2BEGb6,
        output  E2BEGb7,
        output  A_CLK,
        output  A_IN,
        output  A_EN,
        output  B_CLK,
        output  B_IN,
        output  B_EN,
 //global
        input  [NoConfigBits-1:0] ConfigBits,
        input  [NoConfigBits-1:0] ConfigBits_N
);
parameter GND0 = 1'b0;
parameter GND = 1'b0;
parameter VCC0 = 1'b1;
parameter VCC = 1'b1;
parameter VDD0 = 1'b1;
parameter VDD = 1'b1;

wire[4-1:0] S_GBUF_FEED_BEG0_input;
wire[4-1:0] S_GBUF_FEED_BEG1_input;
wire[4-1:0] S_GBUF_FEED_BEG2_input;
wire[4-1:0] S_GBUF_FEED_BEG3_input;
wire[4-1:0] E1BEG0_input;
wire[4-1:0] E1BEG1_input;
wire[4-1:0] E1BEG2_input;
wire[4-1:0] E1BEG3_input;
wire[4-1:0] E1BEG4_input;
wire[4-1:0] E1BEG5_input;
wire[4-1:0] E1BEG6_input;
wire[4-1:0] E1BEG7_input;
wire[4-1:0] E2BEG0_input;
wire[4-1:0] E2BEG1_input;
wire[4-1:0] E2BEG2_input;
wire[4-1:0] E2BEG3_input;
wire[4-1:0] E2BEG4_input;
wire[4-1:0] E2BEG5_input;
wire[4-1:0] E2BEG6_input;
wire[4-1:0] E2BEG7_input;
wire[4-1:0] E2BEGb0_input;
wire[4-1:0] E2BEGb1_input;
wire[4-1:0] E2BEGb2_input;
wire[4-1:0] E2BEGb3_input;
wire[4-1:0] E2BEGb4_input;
wire[4-1:0] E2BEGb5_input;
wire[4-1:0] E2BEGb6_input;
wire[4-1:0] E2BEGb7_input;
wire[4-1:0] A_CLK_input;
wire[16-1:0] A_IN_input;
wire[8-1:0] A_EN_input;
wire[4-1:0] B_CLK_input;
wire[16-1:0] B_IN_input;
wire[8-1:0] B_EN_input;
 //The configuration bits (if any) are just a long shift register
 //This shift register is padded to an even number of flops/latches
 //switch matrix multiplexer S_GBUF_FEED_BEG0 MUX-4
assign S_GBUF_FEED_BEG0_input = {A_OUT,W2END7,W1END1,S_GBUF_FEED_END0};
cus_mux41 inst_cus_mux41_S_GBUF_FEED_BEG0 (
    .A0(S_GBUF_FEED_BEG0_input[0]),
    .A1(S_GBUF_FEED_BEG0_input[1]),
    .A2(S_GBUF_FEED_BEG0_input[2]),
    .A3(S_GBUF_FEED_BEG0_input[3]),
    .S0(ConfigBits[0+0]),
    .S0N(ConfigBits_N[0+0]),
    .S1(ConfigBits[0+1]),
    .S1N(ConfigBits_N[0+1]),
    .X(S_GBUF_FEED_BEG0)
);

 //switch matrix multiplexer S_GBUF_FEED_BEG1 MUX-4
assign S_GBUF_FEED_BEG1_input = {B_OUT,W2END6,W1END2,S_GBUF_FEED_END1};
cus_mux41 inst_cus_mux41_S_GBUF_FEED_BEG1 (
    .A0(S_GBUF_FEED_BEG1_input[0]),
    .A1(S_GBUF_FEED_BEG1_input[1]),
    .A2(S_GBUF_FEED_BEG1_input[2]),
    .A3(S_GBUF_FEED_BEG1_input[3]),
    .S0(ConfigBits[2+0]),
    .S0N(ConfigBits_N[2+0]),
    .S1(ConfigBits[2+1]),
    .S1N(ConfigBits_N[2+1]),
    .X(S_GBUF_FEED_BEG1)
);

 //switch matrix multiplexer S_GBUF_FEED_BEG2 MUX-4
assign S_GBUF_FEED_BEG2_input = {A_OUT,W2END5,W1END3,S_GBUF_FEED_END2};
cus_mux41 inst_cus_mux41_S_GBUF_FEED_BEG2 (
    .A0(S_GBUF_FEED_BEG2_input[0]),
    .A1(S_GBUF_FEED_BEG2_input[1]),
    .A2(S_GBUF_FEED_BEG2_input[2]),
    .A3(S_GBUF_FEED_BEG2_input[3]),
    .S0(ConfigBits[4+0]),
    .S0N(ConfigBits_N[4+0]),
    .S1(ConfigBits[4+1]),
    .S1N(ConfigBits_N[4+1]),
    .X(S_GBUF_FEED_BEG2)
);

 //switch matrix multiplexer S_GBUF_FEED_BEG3 MUX-4
assign S_GBUF_FEED_BEG3_input = {B_OUT,W2END4,W1END0,S_GBUF_FEED_END3};
cus_mux41 inst_cus_mux41_S_GBUF_FEED_BEG3 (
    .A0(S_GBUF_FEED_BEG3_input[0]),
    .A1(S_GBUF_FEED_BEG3_input[1]),
    .A2(S_GBUF_FEED_BEG3_input[2]),
    .A3(S_GBUF_FEED_BEG3_input[3]),
    .S0(ConfigBits[6+0]),
    .S0N(ConfigBits_N[6+0]),
    .S1(ConfigBits[6+1]),
    .S1N(ConfigBits_N[6+1]),
    .X(S_GBUF_FEED_BEG3)
);

 //switch matrix multiplexer N_GBUF_BEG0 MUX-1
assign N_GBUF_BEG0 = N_GBUF_END0;

 //switch matrix multiplexer N_GBUF_BEG1 MUX-1
assign N_GBUF_BEG1 = N_GBUF_END1;

 //switch matrix multiplexer N_GBUF_BEG2 MUX-1
assign N_GBUF_BEG2 = N_GBUF_END2;

 //switch matrix multiplexer N_GBUF_BEG3 MUX-1
assign N_GBUF_BEG3 = N_GBUF_END3;

 //switch matrix multiplexer E1BEG0 MUX-4
assign E1BEG0_input = {A_OUT,W2END7,W2MID7,W1END7};
cus_mux41 inst_cus_mux41_E1BEG0 (
    .A0(E1BEG0_input[0]),
    .A1(E1BEG0_input[1]),
    .A2(E1BEG0_input[2]),
    .A3(E1BEG0_input[3]),
    .S0(ConfigBits[8+0]),
    .S0N(ConfigBits_N[8+0]),
    .S1(ConfigBits[8+1]),
    .S1N(ConfigBits_N[8+1]),
    .X(E1BEG0)
);

 //switch matrix multiplexer E1BEG1 MUX-4
assign E1BEG1_input = {B_OUT,W2END6,W2MID6,W1END6};
cus_mux41 inst_cus_mux41_E1BEG1 (
    .A0(E1BEG1_input[0]),
    .A1(E1BEG1_input[1]),
    .A2(E1BEG1_input[2]),
    .A3(E1BEG1_input[3]),
    .S0(ConfigBits[10+0]),
    .S0N(ConfigBits_N[10+0]),
    .S1(ConfigBits[10+1]),
    .S1N(ConfigBits_N[10+1]),
    .X(E1BEG1)
);

 //switch matrix multiplexer E1BEG2 MUX-4
assign E1BEG2_input = {A_OUT,W2END5,W2MID5,W1END5};
cus_mux41 inst_cus_mux41_E1BEG2 (
    .A0(E1BEG2_input[0]),
    .A1(E1BEG2_input[1]),
    .A2(E1BEG2_input[2]),
    .A3(E1BEG2_input[3]),
    .S0(ConfigBits[12+0]),
    .S0N(ConfigBits_N[12+0]),
    .S1(ConfigBits[12+1]),
    .S1N(ConfigBits_N[12+1]),
    .X(E1BEG2)
);

 //switch matrix multiplexer E1BEG3 MUX-4
assign E1BEG3_input = {B_OUT,W2END4,W2MID4,W1END4};
cus_mux41 inst_cus_mux41_E1BEG3 (
    .A0(E1BEG3_input[0]),
    .A1(E1BEG3_input[1]),
    .A2(E1BEG3_input[2]),
    .A3(E1BEG3_input[3]),
    .S0(ConfigBits[14+0]),
    .S0N(ConfigBits_N[14+0]),
    .S1(ConfigBits[14+1]),
    .S1N(ConfigBits_N[14+1]),
    .X(E1BEG3)
);

 //switch matrix multiplexer E1BEG4 MUX-4
assign E1BEG4_input = {A_OUT,W2END3,W2MID3,W1END3};
cus_mux41 inst_cus_mux41_E1BEG4 (
    .A0(E1BEG4_input[0]),
    .A1(E1BEG4_input[1]),
    .A2(E1BEG4_input[2]),
    .A3(E1BEG4_input[3]),
    .S0(ConfigBits[16+0]),
    .S0N(ConfigBits_N[16+0]),
    .S1(ConfigBits[16+1]),
    .S1N(ConfigBits_N[16+1]),
    .X(E1BEG4)
);

 //switch matrix multiplexer E1BEG5 MUX-4
assign E1BEG5_input = {B_OUT,W2END2,W2MID2,W1END2};
cus_mux41 inst_cus_mux41_E1BEG5 (
    .A0(E1BEG5_input[0]),
    .A1(E1BEG5_input[1]),
    .A2(E1BEG5_input[2]),
    .A3(E1BEG5_input[3]),
    .S0(ConfigBits[18+0]),
    .S0N(ConfigBits_N[18+0]),
    .S1(ConfigBits[18+1]),
    .S1N(ConfigBits_N[18+1]),
    .X(E1BEG5)
);

 //switch matrix multiplexer E1BEG6 MUX-4
assign E1BEG6_input = {A_OUT,W2END1,W2MID1,W1END1};
cus_mux41 inst_cus_mux41_E1BEG6 (
    .A0(E1BEG6_input[0]),
    .A1(E1BEG6_input[1]),
    .A2(E1BEG6_input[2]),
    .A3(E1BEG6_input[3]),
    .S0(ConfigBits[20+0]),
    .S0N(ConfigBits_N[20+0]),
    .S1(ConfigBits[20+1]),
    .S1N(ConfigBits_N[20+1]),
    .X(E1BEG6)
);

 //switch matrix multiplexer E1BEG7 MUX-4
assign E1BEG7_input = {B_OUT,W2END0,W2MID0,W1END0};
cus_mux41 inst_cus_mux41_E1BEG7 (
    .A0(E1BEG7_input[0]),
    .A1(E1BEG7_input[1]),
    .A2(E1BEG7_input[2]),
    .A3(E1BEG7_input[3]),
    .S0(ConfigBits[22+0]),
    .S0N(ConfigBits_N[22+0]),
    .S1(ConfigBits[22+1]),
    .S1N(ConfigBits_N[22+1]),
    .X(E1BEG7)
);

 //switch matrix multiplexer E2BEG0 MUX-4
assign E2BEG0_input = {A_OUT,W2END7,W2MID7,W1END7};
cus_mux41 inst_cus_mux41_E2BEG0 (
    .A0(E2BEG0_input[0]),
    .A1(E2BEG0_input[1]),
    .A2(E2BEG0_input[2]),
    .A3(E2BEG0_input[3]),
    .S0(ConfigBits[24+0]),
    .S0N(ConfigBits_N[24+0]),
    .S1(ConfigBits[24+1]),
    .S1N(ConfigBits_N[24+1]),
    .X(E2BEG0)
);

 //switch matrix multiplexer E2BEG1 MUX-4
assign E2BEG1_input = {B_OUT,W2END6,W2MID6,W1END6};
cus_mux41 inst_cus_mux41_E2BEG1 (
    .A0(E2BEG1_input[0]),
    .A1(E2BEG1_input[1]),
    .A2(E2BEG1_input[2]),
    .A3(E2BEG1_input[3]),
    .S0(ConfigBits[26+0]),
    .S0N(ConfigBits_N[26+0]),
    .S1(ConfigBits[26+1]),
    .S1N(ConfigBits_N[26+1]),
    .X(E2BEG1)
);

 //switch matrix multiplexer E2BEG2 MUX-4
assign E2BEG2_input = {A_OUT,W2END5,W2MID5,W1END5};
cus_mux41 inst_cus_mux41_E2BEG2 (
    .A0(E2BEG2_input[0]),
    .A1(E2BEG2_input[1]),
    .A2(E2BEG2_input[2]),
    .A3(E2BEG2_input[3]),
    .S0(ConfigBits[28+0]),
    .S0N(ConfigBits_N[28+0]),
    .S1(ConfigBits[28+1]),
    .S1N(ConfigBits_N[28+1]),
    .X(E2BEG2)
);

 //switch matrix multiplexer E2BEG3 MUX-4
assign E2BEG3_input = {B_OUT,W2END4,W2MID4,W1END4};
cus_mux41 inst_cus_mux41_E2BEG3 (
    .A0(E2BEG3_input[0]),
    .A1(E2BEG3_input[1]),
    .A2(E2BEG3_input[2]),
    .A3(E2BEG3_input[3]),
    .S0(ConfigBits[30+0]),
    .S0N(ConfigBits_N[30+0]),
    .S1(ConfigBits[30+1]),
    .S1N(ConfigBits_N[30+1]),
    .X(E2BEG3)
);

 //switch matrix multiplexer E2BEG4 MUX-4
assign E2BEG4_input = {A_OUT,W2END3,W2MID3,W1END3};
cus_mux41 inst_cus_mux41_E2BEG4 (
    .A0(E2BEG4_input[0]),
    .A1(E2BEG4_input[1]),
    .A2(E2BEG4_input[2]),
    .A3(E2BEG4_input[3]),
    .S0(ConfigBits[32+0]),
    .S0N(ConfigBits_N[32+0]),
    .S1(ConfigBits[32+1]),
    .S1N(ConfigBits_N[32+1]),
    .X(E2BEG4)
);

 //switch matrix multiplexer E2BEG5 MUX-4
assign E2BEG5_input = {B_OUT,W2END2,W2MID2,W1END2};
cus_mux41 inst_cus_mux41_E2BEG5 (
    .A0(E2BEG5_input[0]),
    .A1(E2BEG5_input[1]),
    .A2(E2BEG5_input[2]),
    .A3(E2BEG5_input[3]),
    .S0(ConfigBits[34+0]),
    .S0N(ConfigBits_N[34+0]),
    .S1(ConfigBits[34+1]),
    .S1N(ConfigBits_N[34+1]),
    .X(E2BEG5)
);

 //switch matrix multiplexer E2BEG6 MUX-4
assign E2BEG6_input = {A_OUT,W2END1,W2MID1,W1END1};
cus_mux41 inst_cus_mux41_E2BEG6 (
    .A0(E2BEG6_input[0]),
    .A1(E2BEG6_input[1]),
    .A2(E2BEG6_input[2]),
    .A3(E2BEG6_input[3]),
    .S0(ConfigBits[36+0]),
    .S0N(ConfigBits_N[36+0]),
    .S1(ConfigBits[36+1]),
    .S1N(ConfigBits_N[36+1]),
    .X(E2BEG6)
);

 //switch matrix multiplexer E2BEG7 MUX-4
assign E2BEG7_input = {B_OUT,W2END0,W2MID0,W1END0};
cus_mux41 inst_cus_mux41_E2BEG7 (
    .A0(E2BEG7_input[0]),
    .A1(E2BEG7_input[1]),
    .A2(E2BEG7_input[2]),
    .A3(E2BEG7_input[3]),
    .S0(ConfigBits[38+0]),
    .S0N(ConfigBits_N[38+0]),
    .S1(ConfigBits[38+1]),
    .S1N(ConfigBits_N[38+1]),
    .X(E2BEG7)
);

 //switch matrix multiplexer E2BEGb0 MUX-4
assign E2BEGb0_input = {B_OUT,W2END7,W2MID7,W1END7};
cus_mux41 inst_cus_mux41_E2BEGb0 (
    .A0(E2BEGb0_input[0]),
    .A1(E2BEGb0_input[1]),
    .A2(E2BEGb0_input[2]),
    .A3(E2BEGb0_input[3]),
    .S0(ConfigBits[40+0]),
    .S0N(ConfigBits_N[40+0]),
    .S1(ConfigBits[40+1]),
    .S1N(ConfigBits_N[40+1]),
    .X(E2BEGb0)
);

 //switch matrix multiplexer E2BEGb1 MUX-4
assign E2BEGb1_input = {A_OUT,W2END6,W2MID6,W1END6};
cus_mux41 inst_cus_mux41_E2BEGb1 (
    .A0(E2BEGb1_input[0]),
    .A1(E2BEGb1_input[1]),
    .A2(E2BEGb1_input[2]),
    .A3(E2BEGb1_input[3]),
    .S0(ConfigBits[42+0]),
    .S0N(ConfigBits_N[42+0]),
    .S1(ConfigBits[42+1]),
    .S1N(ConfigBits_N[42+1]),
    .X(E2BEGb1)
);

 //switch matrix multiplexer E2BEGb2 MUX-4
assign E2BEGb2_input = {B_OUT,W2END5,W2MID5,W1END5};
cus_mux41 inst_cus_mux41_E2BEGb2 (
    .A0(E2BEGb2_input[0]),
    .A1(E2BEGb2_input[1]),
    .A2(E2BEGb2_input[2]),
    .A3(E2BEGb2_input[3]),
    .S0(ConfigBits[44+0]),
    .S0N(ConfigBits_N[44+0]),
    .S1(ConfigBits[44+1]),
    .S1N(ConfigBits_N[44+1]),
    .X(E2BEGb2)
);

 //switch matrix multiplexer E2BEGb3 MUX-4
assign E2BEGb3_input = {A_OUT,W2END4,W2MID4,W1END4};
cus_mux41 inst_cus_mux41_E2BEGb3 (
    .A0(E2BEGb3_input[0]),
    .A1(E2BEGb3_input[1]),
    .A2(E2BEGb3_input[2]),
    .A3(E2BEGb3_input[3]),
    .S0(ConfigBits[46+0]),
    .S0N(ConfigBits_N[46+0]),
    .S1(ConfigBits[46+1]),
    .S1N(ConfigBits_N[46+1]),
    .X(E2BEGb3)
);

 //switch matrix multiplexer E2BEGb4 MUX-4
assign E2BEGb4_input = {B_OUT,W2END3,W2MID3,W1END3};
cus_mux41 inst_cus_mux41_E2BEGb4 (
    .A0(E2BEGb4_input[0]),
    .A1(E2BEGb4_input[1]),
    .A2(E2BEGb4_input[2]),
    .A3(E2BEGb4_input[3]),
    .S0(ConfigBits[48+0]),
    .S0N(ConfigBits_N[48+0]),
    .S1(ConfigBits[48+1]),
    .S1N(ConfigBits_N[48+1]),
    .X(E2BEGb4)
);

 //switch matrix multiplexer E2BEGb5 MUX-4
assign E2BEGb5_input = {A_OUT,W2END2,W2MID2,W1END2};
cus_mux41 inst_cus_mux41_E2BEGb5 (
    .A0(E2BEGb5_input[0]),
    .A1(E2BEGb5_input[1]),
    .A2(E2BEGb5_input[2]),
    .A3(E2BEGb5_input[3]),
    .S0(ConfigBits[50+0]),
    .S0N(ConfigBits_N[50+0]),
    .S1(ConfigBits[50+1]),
    .S1N(ConfigBits_N[50+1]),
    .X(E2BEGb5)
);

 //switch matrix multiplexer E2BEGb6 MUX-4
assign E2BEGb6_input = {B_OUT,W2END1,W2MID1,W1END1};
cus_mux41 inst_cus_mux41_E2BEGb6 (
    .A0(E2BEGb6_input[0]),
    .A1(E2BEGb6_input[1]),
    .A2(E2BEGb6_input[2]),
    .A3(E2BEGb6_input[3]),
    .S0(ConfigBits[52+0]),
    .S0N(ConfigBits_N[52+0]),
    .S1(ConfigBits[52+1]),
    .S1N(ConfigBits_N[52+1]),
    .X(E2BEGb6)
);

 //switch matrix multiplexer E2BEGb7 MUX-4
assign E2BEGb7_input = {A_OUT,W2END0,W2MID0,W1END0};
cus_mux41 inst_cus_mux41_E2BEGb7 (
    .A0(E2BEGb7_input[0]),
    .A1(E2BEGb7_input[1]),
    .A2(E2BEGb7_input[2]),
    .A3(E2BEGb7_input[3]),
    .S0(ConfigBits[54+0]),
    .S0N(ConfigBits_N[54+0]),
    .S1(ConfigBits[54+1]),
    .S1N(ConfigBits_N[54+1]),
    .X(E2BEGb7)
);

 //switch matrix multiplexer A_CLK MUX-4
assign A_CLK_input = {N_GBUF_END3,N_GBUF_END2,N_GBUF_END1,N_GBUF_END0};
cus_mux41 inst_cus_mux41_A_CLK (
    .A0(A_CLK_input[0]),
    .A1(A_CLK_input[1]),
    .A2(A_CLK_input[2]),
    .A3(A_CLK_input[3]),
    .S0(ConfigBits[56+0]),
    .S0N(ConfigBits_N[56+0]),
    .S1(ConfigBits[56+1]),
    .S1N(ConfigBits_N[56+1]),
    .X(A_CLK)
);

 //switch matrix multiplexer A_IN MUX-16
assign A_IN_input = {VCC0,GND0,W2END7,W2END6,W2END5,W2MID2,W2MID1,W2MID0,W1END7,W1END6,W1END5,W1END4,W1END3,W1END2,W1END1,W1END0};
cus_mux161 inst_cus_mux161_A_IN (
    .A0(A_IN_input[0]),
    .A1(A_IN_input[1]),
    .A2(A_IN_input[2]),
    .A3(A_IN_input[3]),
    .A4(A_IN_input[4]),
    .A5(A_IN_input[5]),
    .A6(A_IN_input[6]),
    .A7(A_IN_input[7]),
    .A8(A_IN_input[8]),
    .A9(A_IN_input[9]),
    .A10(A_IN_input[10]),
    .A11(A_IN_input[11]),
    .A12(A_IN_input[12]),
    .A13(A_IN_input[13]),
    .A14(A_IN_input[14]),
    .A15(A_IN_input[15]),
    .S0(ConfigBits[58+0]),
    .S0N(ConfigBits_N[58+0]),
    .S1(ConfigBits[58+1]),
    .S1N(ConfigBits_N[58+1]),
    .S2(ConfigBits[58+2]),
    .S2N(ConfigBits_N[58+2]),
    .S3(ConfigBits[58+3]),
    .S3N(ConfigBits_N[58+3]),
    .X(A_IN)
);

 //switch matrix multiplexer A_EN MUX-8
assign A_EN_input = {VCC0,GND0,W2END2,W2END0,W2MID7,W2MID4,W1END7,W1END3};
cus_mux81 inst_cus_mux81_A_EN (
    .A0(A_EN_input[0]),
    .A1(A_EN_input[1]),
    .A2(A_EN_input[2]),
    .A3(A_EN_input[3]),
    .A4(A_EN_input[4]),
    .A5(A_EN_input[5]),
    .A6(A_EN_input[6]),
    .A7(A_EN_input[7]),
    .S0(ConfigBits[62+0]),
    .S0N(ConfigBits_N[62+0]),
    .S1(ConfigBits[62+1]),
    .S1N(ConfigBits_N[62+1]),
    .S2(ConfigBits[62+2]),
    .S2N(ConfigBits_N[62+2]),
    .X(A_EN)
);

 //switch matrix multiplexer B_CLK MUX-4
assign B_CLK_input = {N_GBUF_END3,N_GBUF_END2,N_GBUF_END1,N_GBUF_END0};
cus_mux41 inst_cus_mux41_B_CLK (
    .A0(B_CLK_input[0]),
    .A1(B_CLK_input[1]),
    .A2(B_CLK_input[2]),
    .A3(B_CLK_input[3]),
    .S0(ConfigBits[65+0]),
    .S0N(ConfigBits_N[65+0]),
    .S1(ConfigBits[65+1]),
    .S1N(ConfigBits_N[65+1]),
    .X(B_CLK)
);

 //switch matrix multiplexer B_IN MUX-16
assign B_IN_input = {VCC0,GND0,W2END7,W2END6,W2END5,W2MID2,W2MID1,W2MID0,W1END7,W1END6,W1END5,W1END4,W1END3,W1END2,W1END1,W1END0};
cus_mux161 inst_cus_mux161_B_IN (
    .A0(B_IN_input[0]),
    .A1(B_IN_input[1]),
    .A2(B_IN_input[2]),
    .A3(B_IN_input[3]),
    .A4(B_IN_input[4]),
    .A5(B_IN_input[5]),
    .A6(B_IN_input[6]),
    .A7(B_IN_input[7]),
    .A8(B_IN_input[8]),
    .A9(B_IN_input[9]),
    .A10(B_IN_input[10]),
    .A11(B_IN_input[11]),
    .A12(B_IN_input[12]),
    .A13(B_IN_input[13]),
    .A14(B_IN_input[14]),
    .A15(B_IN_input[15]),
    .S0(ConfigBits[67+0]),
    .S0N(ConfigBits_N[67+0]),
    .S1(ConfigBits[67+1]),
    .S1N(ConfigBits_N[67+1]),
    .S2(ConfigBits[67+2]),
    .S2N(ConfigBits_N[67+2]),
    .S3(ConfigBits[67+3]),
    .S3N(ConfigBits_N[67+3]),
    .X(B_IN)
);

 //switch matrix multiplexer B_EN MUX-8
assign B_EN_input = {VCC0,GND0,W2END2,W2END0,W2MID7,W2MID4,W1END7,W1END3};
cus_mux81 inst_cus_mux81_B_EN (
    .A0(B_EN_input[0]),
    .A1(B_EN_input[1]),
    .A2(B_EN_input[2]),
    .A3(B_EN_input[3]),
    .A4(B_EN_input[4]),
    .A5(B_EN_input[5]),
    .A6(B_EN_input[6]),
    .A7(B_EN_input[7]),
    .S0(ConfigBits[71+0]),
    .S0N(ConfigBits_N[71+0]),
    .S1(ConfigBits[71+1]),
    .S1N(ConfigBits_N[71+1]),
    .S2(ConfigBits[71+2]),
    .S2N(ConfigBits_N[71+2]),
    .X(B_EN)
);

endmodule
module W_IO2
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=80
    )
    (
 //N
        input  [3:0] S_GBUF_FEED_END,        //Port(Name=S_GBUF_FEED_END,IO=INPUT,XOffset=0,YOffset=1,WireCount=4,Side=N)
        output  [3:0] N_GBUF_BEG,        //Port(Name=N_GBUF_BEG,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=4,Side=N)
 //E
        output  [7:0] E1BEG,        //Port(Name=E1BEG,IO=OUTPUT,XOffset=1,YOffset=0,WireCount=8,Side=E)
        output  [7:0] E2BEG,        //Port(Name=E2BEG,IO=OUTPUT,XOffset=1,YOffset=0,WireCount=8,Side=E)
        output  [7:0] E2BEGb,        //Port(Name=E2BEGb,IO=OUTPUT,XOffset=1,YOffset=0,WireCount=8,Side=E)
        input  [7:0] W1END,        //Port(Name=W1END,IO=INPUT,XOffset=-1,YOffset=0,WireCount=8,Side=E)
        input  [7:0] W2MID,        //Port(Name=W2MID,IO=INPUT,XOffset=-1,YOffset=0,WireCount=8,Side=E)
        input  [7:0] W2END,        //Port(Name=W2END,IO=INPUT,XOffset=-1,YOffset=0,WireCount=8,Side=E)
 //S
        output  [3:0] S_GBUF_FEED_BEG,        //Port(Name=S_GBUF_FEED_BEG,IO=OUTPUT,XOffset=0,YOffset=1,WireCount=4,Side=S)
        input  [3:0] N_GBUF_END,        //Port(Name=N_GBUF_END,IO=INPUT,XOffset=0,YOffset=-1,WireCount=4,Side=S)
        input  A_OUT_top,
        output  A_IN_top,
        output  A_EN_top,
        input  B_OUT_top,
        output  B_IN_top,
        output  B_EN_top,
    //Tile IO ports from BELs
        input  [FrameBitsPerRow-1:0] FrameData, //CONFIG_PORT
        output  [FrameBitsPerRow-1:0] FrameData_O,
        input  [MaxFramesPerCol-1:0] FrameStrobe, //CONFIG_PORT
        output  [MaxFramesPerCol-1:0] FrameStrobe_O
    //global
);
 //signal declarations
 //BEL ports (e.g., slices)
wire A_CLK;
wire A_IN;
wire A_EN;
wire A_OUT;
wire B_CLK;
wire B_IN;
wire B_EN;
wire B_OUT;
 //Jump wires
 //internal configuration data signal to daisy-chain all BELs (if any and in the order they are listed in the fabric.csv)
wire[NoConfigBits-1:0] ConfigBits;
wire[NoConfigBits-1:0] ConfigBits_N;

 //Connection for outgoing wires
wire[FrameBitsPerRow-1:0] FrameData_i;
wire[FrameBitsPerRow-1:0] FrameData_O_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_O_i;

assign FrameData_O_i = FrameData_i;

my_buf data_inbuf_0 (
    .A(FrameData[0]),
    .X(FrameData_i[0])
);

my_buf data_inbuf_1 (
    .A(FrameData[1]),
    .X(FrameData_i[1])
);

my_buf data_inbuf_2 (
    .A(FrameData[2]),
    .X(FrameData_i[2])
);

my_buf data_inbuf_3 (
    .A(FrameData[3]),
    .X(FrameData_i[3])
);

my_buf data_inbuf_4 (
    .A(FrameData[4]),
    .X(FrameData_i[4])
);

my_buf data_inbuf_5 (
    .A(FrameData[5]),
    .X(FrameData_i[5])
);

my_buf data_inbuf_6 (
    .A(FrameData[6]),
    .X(FrameData_i[6])
);

my_buf data_inbuf_7 (
    .A(FrameData[7]),
    .X(FrameData_i[7])
);

my_buf data_inbuf_8 (
    .A(FrameData[8]),
    .X(FrameData_i[8])
);

my_buf data_inbuf_9 (
    .A(FrameData[9]),
    .X(FrameData_i[9])
);

my_buf data_inbuf_10 (
    .A(FrameData[10]),
    .X(FrameData_i[10])
);

my_buf data_inbuf_11 (
    .A(FrameData[11]),
    .X(FrameData_i[11])
);

my_buf data_inbuf_12 (
    .A(FrameData[12]),
    .X(FrameData_i[12])
);

my_buf data_inbuf_13 (
    .A(FrameData[13]),
    .X(FrameData_i[13])
);

my_buf data_inbuf_14 (
    .A(FrameData[14]),
    .X(FrameData_i[14])
);

my_buf data_inbuf_15 (
    .A(FrameData[15]),
    .X(FrameData_i[15])
);

my_buf data_inbuf_16 (
    .A(FrameData[16]),
    .X(FrameData_i[16])
);

my_buf data_inbuf_17 (
    .A(FrameData[17]),
    .X(FrameData_i[17])
);

my_buf data_inbuf_18 (
    .A(FrameData[18]),
    .X(FrameData_i[18])
);

my_buf data_inbuf_19 (
    .A(FrameData[19]),
    .X(FrameData_i[19])
);

my_buf data_inbuf_20 (
    .A(FrameData[20]),
    .X(FrameData_i[20])
);

my_buf data_inbuf_21 (
    .A(FrameData[21]),
    .X(FrameData_i[21])
);

my_buf data_inbuf_22 (
    .A(FrameData[22]),
    .X(FrameData_i[22])
);

my_buf data_inbuf_23 (
    .A(FrameData[23]),
    .X(FrameData_i[23])
);

my_buf data_inbuf_24 (
    .A(FrameData[24]),
    .X(FrameData_i[24])
);

my_buf data_inbuf_25 (
    .A(FrameData[25]),
    .X(FrameData_i[25])
);

my_buf data_inbuf_26 (
    .A(FrameData[26]),
    .X(FrameData_i[26])
);

my_buf data_inbuf_27 (
    .A(FrameData[27]),
    .X(FrameData_i[27])
);

my_buf data_inbuf_28 (
    .A(FrameData[28]),
    .X(FrameData_i[28])
);

my_buf data_inbuf_29 (
    .A(FrameData[29]),
    .X(FrameData_i[29])
);

my_buf data_inbuf_30 (
    .A(FrameData[30]),
    .X(FrameData_i[30])
);

my_buf data_inbuf_31 (
    .A(FrameData[31]),
    .X(FrameData_i[31])
);

my_buf data_outbuf_0 (
    .A(FrameData_O_i[0]),
    .X(FrameData_O[0])
);

my_buf data_outbuf_1 (
    .A(FrameData_O_i[1]),
    .X(FrameData_O[1])
);

my_buf data_outbuf_2 (
    .A(FrameData_O_i[2]),
    .X(FrameData_O[2])
);

my_buf data_outbuf_3 (
    .A(FrameData_O_i[3]),
    .X(FrameData_O[3])
);

my_buf data_outbuf_4 (
    .A(FrameData_O_i[4]),
    .X(FrameData_O[4])
);

my_buf data_outbuf_5 (
    .A(FrameData_O_i[5]),
    .X(FrameData_O[5])
);

my_buf data_outbuf_6 (
    .A(FrameData_O_i[6]),
    .X(FrameData_O[6])
);

my_buf data_outbuf_7 (
    .A(FrameData_O_i[7]),
    .X(FrameData_O[7])
);

my_buf data_outbuf_8 (
    .A(FrameData_O_i[8]),
    .X(FrameData_O[8])
);

my_buf data_outbuf_9 (
    .A(FrameData_O_i[9]),
    .X(FrameData_O[9])
);

my_buf data_outbuf_10 (
    .A(FrameData_O_i[10]),
    .X(FrameData_O[10])
);

my_buf data_outbuf_11 (
    .A(FrameData_O_i[11]),
    .X(FrameData_O[11])
);

my_buf data_outbuf_12 (
    .A(FrameData_O_i[12]),
    .X(FrameData_O[12])
);

my_buf data_outbuf_13 (
    .A(FrameData_O_i[13]),
    .X(FrameData_O[13])
);

my_buf data_outbuf_14 (
    .A(FrameData_O_i[14]),
    .X(FrameData_O[14])
);

my_buf data_outbuf_15 (
    .A(FrameData_O_i[15]),
    .X(FrameData_O[15])
);

my_buf data_outbuf_16 (
    .A(FrameData_O_i[16]),
    .X(FrameData_O[16])
);

my_buf data_outbuf_17 (
    .A(FrameData_O_i[17]),
    .X(FrameData_O[17])
);

my_buf data_outbuf_18 (
    .A(FrameData_O_i[18]),
    .X(FrameData_O[18])
);

my_buf data_outbuf_19 (
    .A(FrameData_O_i[19]),
    .X(FrameData_O[19])
);

my_buf data_outbuf_20 (
    .A(FrameData_O_i[20]),
    .X(FrameData_O[20])
);

my_buf data_outbuf_21 (
    .A(FrameData_O_i[21]),
    .X(FrameData_O[21])
);

my_buf data_outbuf_22 (
    .A(FrameData_O_i[22]),
    .X(FrameData_O[22])
);

my_buf data_outbuf_23 (
    .A(FrameData_O_i[23]),
    .X(FrameData_O[23])
);

my_buf data_outbuf_24 (
    .A(FrameData_O_i[24]),
    .X(FrameData_O[24])
);

my_buf data_outbuf_25 (
    .A(FrameData_O_i[25]),
    .X(FrameData_O[25])
);

my_buf data_outbuf_26 (
    .A(FrameData_O_i[26]),
    .X(FrameData_O[26])
);

my_buf data_outbuf_27 (
    .A(FrameData_O_i[27]),
    .X(FrameData_O[27])
);

my_buf data_outbuf_28 (
    .A(FrameData_O_i[28]),
    .X(FrameData_O[28])
);

my_buf data_outbuf_29 (
    .A(FrameData_O_i[29]),
    .X(FrameData_O[29])
);

my_buf data_outbuf_30 (
    .A(FrameData_O_i[30]),
    .X(FrameData_O[30])
);

my_buf data_outbuf_31 (
    .A(FrameData_O_i[31]),
    .X(FrameData_O[31])
);

assign FrameStrobe_O_i = FrameStrobe_i;

my_buf strobe_inbuf_0 (
    .A(FrameStrobe[0]),
    .X(FrameStrobe_i[0])
);

my_buf strobe_inbuf_1 (
    .A(FrameStrobe[1]),
    .X(FrameStrobe_i[1])
);

my_buf strobe_inbuf_2 (
    .A(FrameStrobe[2]),
    .X(FrameStrobe_i[2])
);

my_buf strobe_inbuf_3 (
    .A(FrameStrobe[3]),
    .X(FrameStrobe_i[3])
);

my_buf strobe_inbuf_4 (
    .A(FrameStrobe[4]),
    .X(FrameStrobe_i[4])
);

my_buf strobe_inbuf_5 (
    .A(FrameStrobe[5]),
    .X(FrameStrobe_i[5])
);

my_buf strobe_inbuf_6 (
    .A(FrameStrobe[6]),
    .X(FrameStrobe_i[6])
);

my_buf strobe_inbuf_7 (
    .A(FrameStrobe[7]),
    .X(FrameStrobe_i[7])
);

my_buf strobe_inbuf_8 (
    .A(FrameStrobe[8]),
    .X(FrameStrobe_i[8])
);

my_buf strobe_inbuf_9 (
    .A(FrameStrobe[9]),
    .X(FrameStrobe_i[9])
);

my_buf strobe_inbuf_10 (
    .A(FrameStrobe[10]),
    .X(FrameStrobe_i[10])
);

my_buf strobe_inbuf_11 (
    .A(FrameStrobe[11]),
    .X(FrameStrobe_i[11])
);

my_buf strobe_inbuf_12 (
    .A(FrameStrobe[12]),
    .X(FrameStrobe_i[12])
);

my_buf strobe_inbuf_13 (
    .A(FrameStrobe[13]),
    .X(FrameStrobe_i[13])
);

my_buf strobe_inbuf_14 (
    .A(FrameStrobe[14]),
    .X(FrameStrobe_i[14])
);

my_buf strobe_inbuf_15 (
    .A(FrameStrobe[15]),
    .X(FrameStrobe_i[15])
);

my_buf strobe_inbuf_16 (
    .A(FrameStrobe[16]),
    .X(FrameStrobe_i[16])
);

my_buf strobe_inbuf_17 (
    .A(FrameStrobe[17]),
    .X(FrameStrobe_i[17])
);

my_buf strobe_inbuf_18 (
    .A(FrameStrobe[18]),
    .X(FrameStrobe_i[18])
);

my_buf strobe_inbuf_19 (
    .A(FrameStrobe[19]),
    .X(FrameStrobe_i[19])
);

my_buf strobe_outbuf_0 (
    .A(FrameStrobe_O_i[0]),
    .X(FrameStrobe_O[0])
);

my_buf strobe_outbuf_1 (
    .A(FrameStrobe_O_i[1]),
    .X(FrameStrobe_O[1])
);

my_buf strobe_outbuf_2 (
    .A(FrameStrobe_O_i[2]),
    .X(FrameStrobe_O[2])
);

my_buf strobe_outbuf_3 (
    .A(FrameStrobe_O_i[3]),
    .X(FrameStrobe_O[3])
);

my_buf strobe_outbuf_4 (
    .A(FrameStrobe_O_i[4]),
    .X(FrameStrobe_O[4])
);

my_buf strobe_outbuf_5 (
    .A(FrameStrobe_O_i[5]),
    .X(FrameStrobe_O[5])
);

my_buf strobe_outbuf_6 (
    .A(FrameStrobe_O_i[6]),
    .X(FrameStrobe_O[6])
);

my_buf strobe_outbuf_7 (
    .A(FrameStrobe_O_i[7]),
    .X(FrameStrobe_O[7])
);

my_buf strobe_outbuf_8 (
    .A(FrameStrobe_O_i[8]),
    .X(FrameStrobe_O[8])
);

my_buf strobe_outbuf_9 (
    .A(FrameStrobe_O_i[9]),
    .X(FrameStrobe_O[9])
);

my_buf strobe_outbuf_10 (
    .A(FrameStrobe_O_i[10]),
    .X(FrameStrobe_O[10])
);

my_buf strobe_outbuf_11 (
    .A(FrameStrobe_O_i[11]),
    .X(FrameStrobe_O[11])
);

my_buf strobe_outbuf_12 (
    .A(FrameStrobe_O_i[12]),
    .X(FrameStrobe_O[12])
);

my_buf strobe_outbuf_13 (
    .A(FrameStrobe_O_i[13]),
    .X(FrameStrobe_O[13])
);

my_buf strobe_outbuf_14 (
    .A(FrameStrobe_O_i[14]),
    .X(FrameStrobe_O[14])
);

my_buf strobe_outbuf_15 (
    .A(FrameStrobe_O_i[15]),
    .X(FrameStrobe_O[15])
);

my_buf strobe_outbuf_16 (
    .A(FrameStrobe_O_i[16]),
    .X(FrameStrobe_O[16])
);

my_buf strobe_outbuf_17 (
    .A(FrameStrobe_O_i[17]),
    .X(FrameStrobe_O[17])
);

my_buf strobe_outbuf_18 (
    .A(FrameStrobe_O_i[18]),
    .X(FrameStrobe_O[18])
);

my_buf strobe_outbuf_19 (
    .A(FrameStrobe_O_i[19]),
    .X(FrameStrobe_O[19])
);


 //configuration storage latches
W_IO2_ConfigMem
`ifdef EMULATION
    #(
    .Emulate_Bitstream(Emulate_Bitstream)
    )
`endif
    Inst_W_IO2_ConfigMem
    (
    .FrameData(FrameData),
    .FrameStrobe(FrameStrobe),
    .ConfigBits(ConfigBits),
    .ConfigBits_N(ConfigBits_N)
);


 //BEL component instantiations
IOBUF Inst_A_IOBUF (
    .CLK(A_CLK),
    .IN(A_IN),
    .EN(A_EN),
    .OUT(A_OUT),
    .IN_top(A_IN_top),
    .EN_top(A_EN_top),
    .OUT_top(A_OUT_top),
    .ConfigBits(ConfigBits[3-1:0])
);

IOBUF Inst_B_IOBUF (
    .CLK(B_CLK),
    .IN(B_IN),
    .EN(B_EN),
    .OUT(B_OUT),
    .IN_top(B_IN_top),
    .EN_top(B_EN_top),
    .OUT_top(B_OUT_top),
    .ConfigBits(ConfigBits[6-1:3])
);

W_IO2_switch_matrix Inst_W_IO2_switch_matrix (
    .S_GBUF_FEED_END0(S_GBUF_FEED_END[0]),
    .S_GBUF_FEED_END1(S_GBUF_FEED_END[1]),
    .S_GBUF_FEED_END2(S_GBUF_FEED_END[2]),
    .S_GBUF_FEED_END3(S_GBUF_FEED_END[3]),
    .N_GBUF_END0(N_GBUF_END[0]),
    .N_GBUF_END1(N_GBUF_END[1]),
    .N_GBUF_END2(N_GBUF_END[2]),
    .N_GBUF_END3(N_GBUF_END[3]),
    .W1END0(W1END[0]),
    .W1END1(W1END[1]),
    .W1END2(W1END[2]),
    .W1END3(W1END[3]),
    .W1END4(W1END[4]),
    .W1END5(W1END[5]),
    .W1END6(W1END[6]),
    .W1END7(W1END[7]),
    .W2MID0(W2MID[0]),
    .W2MID1(W2MID[1]),
    .W2MID2(W2MID[2]),
    .W2MID3(W2MID[3]),
    .W2MID4(W2MID[4]),
    .W2MID5(W2MID[5]),
    .W2MID6(W2MID[6]),
    .W2MID7(W2MID[7]),
    .W2END0(W2END[0]),
    .W2END1(W2END[1]),
    .W2END2(W2END[2]),
    .W2END3(W2END[3]),
    .W2END4(W2END[4]),
    .W2END5(W2END[5]),
    .W2END6(W2END[6]),
    .W2END7(W2END[7]),
    .A_OUT(A_OUT),
    .B_OUT(B_OUT),
    .S_GBUF_FEED_BEG0(S_GBUF_FEED_BEG[0]),
    .S_GBUF_FEED_BEG1(S_GBUF_FEED_BEG[1]),
    .S_GBUF_FEED_BEG2(S_GBUF_FEED_BEG[2]),
    .S_GBUF_FEED_BEG3(S_GBUF_FEED_BEG[3]),
    .N_GBUF_BEG0(N_GBUF_BEG[0]),
    .N_GBUF_BEG1(N_GBUF_BEG[1]),
    .N_GBUF_BEG2(N_GBUF_BEG[2]),
    .N_GBUF_BEG3(N_GBUF_BEG[3]),
    .E1BEG0(E1BEG[0]),
    .E1BEG1(E1BEG[1]),
    .E1BEG2(E1BEG[2]),
    .E1BEG3(E1BEG[3]),
    .E1BEG4(E1BEG[4]),
    .E1BEG5(E1BEG[5]),
    .E1BEG6(E1BEG[6]),
    .E1BEG7(E1BEG[7]),
    .E2BEG0(E2BEG[0]),
    .E2BEG1(E2BEG[1]),
    .E2BEG2(E2BEG[2]),
    .E2BEG3(E2BEG[3]),
    .E2BEG4(E2BEG[4]),
    .E2BEG5(E2BEG[5]),
    .E2BEG6(E2BEG[6]),
    .E2BEG7(E2BEG[7]),
    .E2BEGb0(E2BEGb[0]),
    .E2BEGb1(E2BEGb[1]),
    .E2BEGb2(E2BEGb[2]),
    .E2BEGb3(E2BEGb[3]),
    .E2BEGb4(E2BEGb[4]),
    .E2BEGb5(E2BEGb[5]),
    .E2BEGb6(E2BEGb[6]),
    .E2BEGb7(E2BEGb[7]),
    .A_CLK(A_CLK),
    .A_IN(A_IN),
    .A_EN(A_EN),
    .B_CLK(B_CLK),
    .B_IN(B_IN),
    .B_EN(B_EN),
    .ConfigBits(ConfigBits[80-1:6]),
    .ConfigBits_N(ConfigBits_N[80-1:6])
);

endmodule
module W_IO4_ConfigMem
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=104
    )
    (
        input  [FrameBitsPerRow - 1:0] FrameData,
        input  [MaxFramesPerCol - 1:0] FrameStrobe,
        output  [NoConfigBits - 1:0] ConfigBits,
        output  [NoConfigBits - 1:0] ConfigBits_N
    );

`ifdef EMULATION
assign ConfigBits[103] = Emulate_Bitstream[31];
assign ConfigBits[102] = Emulate_Bitstream[30];
assign ConfigBits[101] = Emulate_Bitstream[29];
assign ConfigBits[100] = Emulate_Bitstream[28];
assign ConfigBits[99] = Emulate_Bitstream[27];
assign ConfigBits[98] = Emulate_Bitstream[26];
assign ConfigBits[97] = Emulate_Bitstream[25];
assign ConfigBits[96] = Emulate_Bitstream[24];
assign ConfigBits[95] = Emulate_Bitstream[23];
assign ConfigBits[94] = Emulate_Bitstream[22];
assign ConfigBits[93] = Emulate_Bitstream[21];
assign ConfigBits[92] = Emulate_Bitstream[20];
assign ConfigBits[91] = Emulate_Bitstream[19];
assign ConfigBits[90] = Emulate_Bitstream[18];
assign ConfigBits[89] = Emulate_Bitstream[17];
assign ConfigBits[88] = Emulate_Bitstream[16];
assign ConfigBits[87] = Emulate_Bitstream[15];
assign ConfigBits[86] = Emulate_Bitstream[14];
assign ConfigBits[85] = Emulate_Bitstream[13];
assign ConfigBits[84] = Emulate_Bitstream[12];
assign ConfigBits[83] = Emulate_Bitstream[11];
assign ConfigBits[82] = Emulate_Bitstream[10];
assign ConfigBits[81] = Emulate_Bitstream[9];
assign ConfigBits[80] = Emulate_Bitstream[8];
assign ConfigBits[79] = Emulate_Bitstream[7];
assign ConfigBits[78] = Emulate_Bitstream[6];
assign ConfigBits[77] = Emulate_Bitstream[5];
assign ConfigBits[76] = Emulate_Bitstream[4];
assign ConfigBits[75] = Emulate_Bitstream[3];
assign ConfigBits[74] = Emulate_Bitstream[2];
assign ConfigBits[73] = Emulate_Bitstream[1];
assign ConfigBits[72] = Emulate_Bitstream[0];
assign ConfigBits[71] = Emulate_Bitstream[63];
assign ConfigBits[70] = Emulate_Bitstream[62];
assign ConfigBits[69] = Emulate_Bitstream[61];
assign ConfigBits[68] = Emulate_Bitstream[60];
assign ConfigBits[67] = Emulate_Bitstream[59];
assign ConfigBits[66] = Emulate_Bitstream[58];
assign ConfigBits[65] = Emulate_Bitstream[57];
assign ConfigBits[64] = Emulate_Bitstream[56];
assign ConfigBits[63] = Emulate_Bitstream[55];
assign ConfigBits[62] = Emulate_Bitstream[54];
assign ConfigBits[61] = Emulate_Bitstream[53];
assign ConfigBits[60] = Emulate_Bitstream[52];
assign ConfigBits[59] = Emulate_Bitstream[51];
assign ConfigBits[58] = Emulate_Bitstream[50];
assign ConfigBits[57] = Emulate_Bitstream[49];
assign ConfigBits[56] = Emulate_Bitstream[48];
assign ConfigBits[55] = Emulate_Bitstream[47];
assign ConfigBits[54] = Emulate_Bitstream[46];
assign ConfigBits[53] = Emulate_Bitstream[45];
assign ConfigBits[52] = Emulate_Bitstream[44];
assign ConfigBits[51] = Emulate_Bitstream[43];
assign ConfigBits[50] = Emulate_Bitstream[42];
assign ConfigBits[49] = Emulate_Bitstream[41];
assign ConfigBits[48] = Emulate_Bitstream[40];
assign ConfigBits[47] = Emulate_Bitstream[39];
assign ConfigBits[46] = Emulate_Bitstream[38];
assign ConfigBits[45] = Emulate_Bitstream[37];
assign ConfigBits[44] = Emulate_Bitstream[36];
assign ConfigBits[43] = Emulate_Bitstream[35];
assign ConfigBits[42] = Emulate_Bitstream[34];
assign ConfigBits[41] = Emulate_Bitstream[33];
assign ConfigBits[40] = Emulate_Bitstream[32];
assign ConfigBits[39] = Emulate_Bitstream[95];
assign ConfigBits[38] = Emulate_Bitstream[94];
assign ConfigBits[37] = Emulate_Bitstream[93];
assign ConfigBits[36] = Emulate_Bitstream[92];
assign ConfigBits[35] = Emulate_Bitstream[91];
assign ConfigBits[34] = Emulate_Bitstream[90];
assign ConfigBits[33] = Emulate_Bitstream[89];
assign ConfigBits[32] = Emulate_Bitstream[88];
assign ConfigBits[31] = Emulate_Bitstream[87];
assign ConfigBits[30] = Emulate_Bitstream[86];
assign ConfigBits[29] = Emulate_Bitstream[85];
assign ConfigBits[28] = Emulate_Bitstream[84];
assign ConfigBits[27] = Emulate_Bitstream[83];
assign ConfigBits[26] = Emulate_Bitstream[82];
assign ConfigBits[25] = Emulate_Bitstream[81];
assign ConfigBits[24] = Emulate_Bitstream[80];
assign ConfigBits[23] = Emulate_Bitstream[79];
assign ConfigBits[22] = Emulate_Bitstream[78];
assign ConfigBits[21] = Emulate_Bitstream[77];
assign ConfigBits[20] = Emulate_Bitstream[76];
assign ConfigBits[19] = Emulate_Bitstream[75];
assign ConfigBits[18] = Emulate_Bitstream[74];
assign ConfigBits[17] = Emulate_Bitstream[73];
assign ConfigBits[16] = Emulate_Bitstream[72];
assign ConfigBits[15] = Emulate_Bitstream[71];
assign ConfigBits[14] = Emulate_Bitstream[70];
assign ConfigBits[13] = Emulate_Bitstream[69];
assign ConfigBits[12] = Emulate_Bitstream[68];
assign ConfigBits[11] = Emulate_Bitstream[67];
assign ConfigBits[10] = Emulate_Bitstream[66];
assign ConfigBits[9] = Emulate_Bitstream[65];
assign ConfigBits[8] = Emulate_Bitstream[64];
assign ConfigBits[7] = Emulate_Bitstream[127];
assign ConfigBits[6] = Emulate_Bitstream[126];
assign ConfigBits[5] = Emulate_Bitstream[125];
assign ConfigBits[4] = Emulate_Bitstream[124];
assign ConfigBits[3] = Emulate_Bitstream[123];
assign ConfigBits[2] = Emulate_Bitstream[122];
assign ConfigBits[1] = Emulate_Bitstream[121];
assign ConfigBits[0] = Emulate_Bitstream[120];
`else

 //instantiate frame latches
config_latch Inst_frame0_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[103]),
    .QN(ConfigBits_N[103])
);

config_latch Inst_frame0_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[102]),
    .QN(ConfigBits_N[102])
);

config_latch Inst_frame0_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[101]),
    .QN(ConfigBits_N[101])
);

config_latch Inst_frame0_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[100]),
    .QN(ConfigBits_N[100])
);

config_latch Inst_frame0_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[99]),
    .QN(ConfigBits_N[99])
);

config_latch Inst_frame0_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[98]),
    .QN(ConfigBits_N[98])
);

config_latch Inst_frame0_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[97]),
    .QN(ConfigBits_N[97])
);

config_latch Inst_frame0_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[96]),
    .QN(ConfigBits_N[96])
);

config_latch Inst_frame0_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[95]),
    .QN(ConfigBits_N[95])
);

config_latch Inst_frame0_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[94]),
    .QN(ConfigBits_N[94])
);

config_latch Inst_frame0_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[93]),
    .QN(ConfigBits_N[93])
);

config_latch Inst_frame0_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[92]),
    .QN(ConfigBits_N[92])
);

config_latch Inst_frame0_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[91]),
    .QN(ConfigBits_N[91])
);

config_latch Inst_frame0_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[90]),
    .QN(ConfigBits_N[90])
);

config_latch Inst_frame0_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[89]),
    .QN(ConfigBits_N[89])
);

config_latch Inst_frame0_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[88]),
    .QN(ConfigBits_N[88])
);

config_latch Inst_frame0_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[87]),
    .QN(ConfigBits_N[87])
);

config_latch Inst_frame0_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[86]),
    .QN(ConfigBits_N[86])
);

config_latch Inst_frame0_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[85]),
    .QN(ConfigBits_N[85])
);

config_latch Inst_frame0_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[84]),
    .QN(ConfigBits_N[84])
);

config_latch Inst_frame0_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[83]),
    .QN(ConfigBits_N[83])
);

config_latch Inst_frame0_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[82]),
    .QN(ConfigBits_N[82])
);

config_latch Inst_frame0_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[81]),
    .QN(ConfigBits_N[81])
);

config_latch Inst_frame0_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[80]),
    .QN(ConfigBits_N[80])
);

config_latch Inst_frame0_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[79]),
    .QN(ConfigBits_N[79])
);

config_latch Inst_frame0_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[78]),
    .QN(ConfigBits_N[78])
);

config_latch Inst_frame0_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[77]),
    .QN(ConfigBits_N[77])
);

config_latch Inst_frame0_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[76]),
    .QN(ConfigBits_N[76])
);

config_latch Inst_frame0_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[75]),
    .QN(ConfigBits_N[75])
);

config_latch Inst_frame0_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[74]),
    .QN(ConfigBits_N[74])
);

config_latch Inst_frame0_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[73]),
    .QN(ConfigBits_N[73])
);

config_latch Inst_frame0_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[72]),
    .QN(ConfigBits_N[72])
);

config_latch Inst_frame1_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[71]),
    .QN(ConfigBits_N[71])
);

config_latch Inst_frame1_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[70]),
    .QN(ConfigBits_N[70])
);

config_latch Inst_frame1_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[69]),
    .QN(ConfigBits_N[69])
);

config_latch Inst_frame1_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[68]),
    .QN(ConfigBits_N[68])
);

config_latch Inst_frame1_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[67]),
    .QN(ConfigBits_N[67])
);

config_latch Inst_frame1_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[66]),
    .QN(ConfigBits_N[66])
);

config_latch Inst_frame1_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[65]),
    .QN(ConfigBits_N[65])
);

config_latch Inst_frame1_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[64]),
    .QN(ConfigBits_N[64])
);

config_latch Inst_frame1_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[63]),
    .QN(ConfigBits_N[63])
);

config_latch Inst_frame1_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[62]),
    .QN(ConfigBits_N[62])
);

config_latch Inst_frame1_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[61]),
    .QN(ConfigBits_N[61])
);

config_latch Inst_frame1_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[60]),
    .QN(ConfigBits_N[60])
);

config_latch Inst_frame1_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[59]),
    .QN(ConfigBits_N[59])
);

config_latch Inst_frame1_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[58]),
    .QN(ConfigBits_N[58])
);

config_latch Inst_frame1_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[57]),
    .QN(ConfigBits_N[57])
);

config_latch Inst_frame1_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[56]),
    .QN(ConfigBits_N[56])
);

config_latch Inst_frame1_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[55]),
    .QN(ConfigBits_N[55])
);

config_latch Inst_frame1_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[54]),
    .QN(ConfigBits_N[54])
);

config_latch Inst_frame1_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[53]),
    .QN(ConfigBits_N[53])
);

config_latch Inst_frame1_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[52]),
    .QN(ConfigBits_N[52])
);

config_latch Inst_frame1_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[51]),
    .QN(ConfigBits_N[51])
);

config_latch Inst_frame1_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[50]),
    .QN(ConfigBits_N[50])
);

config_latch Inst_frame1_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[49]),
    .QN(ConfigBits_N[49])
);

config_latch Inst_frame1_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[48]),
    .QN(ConfigBits_N[48])
);

config_latch Inst_frame1_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[47]),
    .QN(ConfigBits_N[47])
);

config_latch Inst_frame1_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[46]),
    .QN(ConfigBits_N[46])
);

config_latch Inst_frame1_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[45]),
    .QN(ConfigBits_N[45])
);

config_latch Inst_frame1_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[44]),
    .QN(ConfigBits_N[44])
);

config_latch Inst_frame1_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[43]),
    .QN(ConfigBits_N[43])
);

config_latch Inst_frame1_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[42]),
    .QN(ConfigBits_N[42])
);

config_latch Inst_frame1_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[41]),
    .QN(ConfigBits_N[41])
);

config_latch Inst_frame1_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[40]),
    .QN(ConfigBits_N[40])
);

config_latch Inst_frame2_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[39]),
    .QN(ConfigBits_N[39])
);

config_latch Inst_frame2_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[38]),
    .QN(ConfigBits_N[38])
);

config_latch Inst_frame2_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[37]),
    .QN(ConfigBits_N[37])
);

config_latch Inst_frame2_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[36]),
    .QN(ConfigBits_N[36])
);

config_latch Inst_frame2_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[35]),
    .QN(ConfigBits_N[35])
);

config_latch Inst_frame2_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[34]),
    .QN(ConfigBits_N[34])
);

config_latch Inst_frame2_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[33]),
    .QN(ConfigBits_N[33])
);

config_latch Inst_frame2_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[32]),
    .QN(ConfigBits_N[32])
);

config_latch Inst_frame2_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[31]),
    .QN(ConfigBits_N[31])
);

config_latch Inst_frame2_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[30]),
    .QN(ConfigBits_N[30])
);

config_latch Inst_frame2_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[29]),
    .QN(ConfigBits_N[29])
);

config_latch Inst_frame2_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[28]),
    .QN(ConfigBits_N[28])
);

config_latch Inst_frame2_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[27]),
    .QN(ConfigBits_N[27])
);

config_latch Inst_frame2_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[26]),
    .QN(ConfigBits_N[26])
);

config_latch Inst_frame2_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[25]),
    .QN(ConfigBits_N[25])
);

config_latch Inst_frame2_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[24]),
    .QN(ConfigBits_N[24])
);

config_latch Inst_frame2_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[23]),
    .QN(ConfigBits_N[23])
);

config_latch Inst_frame2_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[22]),
    .QN(ConfigBits_N[22])
);

config_latch Inst_frame2_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[21]),
    .QN(ConfigBits_N[21])
);

config_latch Inst_frame2_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[20]),
    .QN(ConfigBits_N[20])
);

config_latch Inst_frame2_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[19]),
    .QN(ConfigBits_N[19])
);

config_latch Inst_frame2_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[18]),
    .QN(ConfigBits_N[18])
);

config_latch Inst_frame2_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[17]),
    .QN(ConfigBits_N[17])
);

config_latch Inst_frame2_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[16]),
    .QN(ConfigBits_N[16])
);

config_latch Inst_frame2_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[15]),
    .QN(ConfigBits_N[15])
);

config_latch Inst_frame2_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[14]),
    .QN(ConfigBits_N[14])
);

config_latch Inst_frame2_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[13]),
    .QN(ConfigBits_N[13])
);

config_latch Inst_frame2_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[12]),
    .QN(ConfigBits_N[12])
);

config_latch Inst_frame2_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[11]),
    .QN(ConfigBits_N[11])
);

config_latch Inst_frame2_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[10]),
    .QN(ConfigBits_N[10])
);

config_latch Inst_frame2_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[9]),
    .QN(ConfigBits_N[9])
);

config_latch Inst_frame2_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[8]),
    .QN(ConfigBits_N[8])
);

config_latch Inst_frame3_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[7]),
    .QN(ConfigBits_N[7])
);

config_latch Inst_frame3_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[6]),
    .QN(ConfigBits_N[6])
);

config_latch Inst_frame3_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[5]),
    .QN(ConfigBits_N[5])
);

config_latch Inst_frame3_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[4]),
    .QN(ConfigBits_N[4])
);

config_latch Inst_frame3_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[3]),
    .QN(ConfigBits_N[3])
);

config_latch Inst_frame3_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[2]),
    .QN(ConfigBits_N[2])
);

config_latch Inst_frame3_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[1]),
    .QN(ConfigBits_N[1])
);

config_latch Inst_frame3_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[3]),
    .Q(ConfigBits[0]),
    .QN(ConfigBits_N[0])
);

`endif
endmodule
 // NumberOfConfigBits: 92
module W_IO4_switch_matrix
    #(
        parameter NoConfigBits=92
    )
    (
        input  S_GBUF_FEED_END0,
        input  S_GBUF_FEED_END1,
        input  S_GBUF_FEED_END2,
        input  S_GBUF_FEED_END3,
        input  N_GBUF_END0,
        input  N_GBUF_END1,
        input  N_GBUF_END2,
        input  N_GBUF_END3,
        input  W1END0,
        input  W1END1,
        input  W1END2,
        input  W1END3,
        input  W1END4,
        input  W1END5,
        input  W1END6,
        input  W1END7,
        input  W2MID0,
        input  W2MID1,
        input  W2MID2,
        input  W2MID3,
        input  W2MID4,
        input  W2MID5,
        input  W2MID6,
        input  W2MID7,
        input  W2END0,
        input  W2END1,
        input  W2END2,
        input  W2END3,
        input  W2END4,
        input  W2END5,
        input  W2END6,
        input  W2END7,
        input  A_OUT,
        input  B_OUT,
        input  C_OUT,
        input  D_OUT,
        output  S_GBUF_FEED_BEG0,
        output  S_GBUF_FEED_BEG1,
        output  S_GBUF_FEED_BEG2,
        output  S_GBUF_FEED_BEG3,
        output  N_GBUF_BEG0,
        output  N_GBUF_BEG1,
        output  N_GBUF_BEG2,
        output  N_GBUF_BEG3,
        output  E1BEG0,
        output  E1BEG1,
        output  E1BEG2,
        output  E1BEG3,
        output  E1BEG4,
        output  E1BEG5,
        output  E1BEG6,
        output  E1BEG7,
        output  E2BEG0,
        output  E2BEG1,
        output  E2BEG2,
        output  E2BEG3,
        output  E2BEG4,
        output  E2BEG5,
        output  E2BEG6,
        output  E2BEG7,
        output  E2BEGb0,
        output  E2BEGb1,
        output  E2BEGb2,
        output  E2BEGb3,
        output  E2BEGb4,
        output  E2BEGb5,
        output  E2BEGb6,
        output  E2BEGb7,
        output  A_CLK,
        output  A_IN,
        output  A_EN,
        output  B_CLK,
        output  B_IN,
        output  B_EN,
        output  C_CLK,
        output  C_IN,
        output  C_EN,
        output  D_CLK,
        output  D_IN,
        output  D_EN,
 //global
        input  [NoConfigBits-1:0] ConfigBits,
        input  [NoConfigBits-1:0] ConfigBits_N
);
parameter GND0 = 1'b0;
parameter GND = 1'b0;
parameter VCC0 = 1'b1;
parameter VCC = 1'b1;
parameter VDD0 = 1'b1;
parameter VDD = 1'b1;

wire[4-1:0] S_GBUF_FEED_BEG0_input;
wire[4-1:0] S_GBUF_FEED_BEG1_input;
wire[4-1:0] S_GBUF_FEED_BEG2_input;
wire[4-1:0] S_GBUF_FEED_BEG3_input;
wire[4-1:0] E1BEG0_input;
wire[4-1:0] E1BEG1_input;
wire[4-1:0] E1BEG2_input;
wire[4-1:0] E1BEG3_input;
wire[4-1:0] E1BEG4_input;
wire[4-1:0] E1BEG5_input;
wire[4-1:0] E1BEG6_input;
wire[4-1:0] E1BEG7_input;
wire[4-1:0] E2BEG0_input;
wire[4-1:0] E2BEG1_input;
wire[4-1:0] E2BEG2_input;
wire[4-1:0] E2BEG3_input;
wire[4-1:0] E2BEG4_input;
wire[4-1:0] E2BEG5_input;
wire[4-1:0] E2BEG6_input;
wire[4-1:0] E2BEG7_input;
wire[4-1:0] E2BEGb0_input;
wire[4-1:0] E2BEGb1_input;
wire[4-1:0] E2BEGb2_input;
wire[4-1:0] E2BEGb3_input;
wire[4-1:0] E2BEGb4_input;
wire[4-1:0] E2BEGb5_input;
wire[4-1:0] E2BEGb6_input;
wire[4-1:0] E2BEGb7_input;
wire[4-1:0] A_CLK_input;
wire[16-1:0] A_IN_input;
wire[8-1:0] A_EN_input;
wire[4-1:0] B_CLK_input;
wire[16-1:0] B_IN_input;
wire[8-1:0] B_EN_input;
wire[4-1:0] C_CLK_input;
wire[16-1:0] C_IN_input;
wire[8-1:0] C_EN_input;
wire[4-1:0] D_CLK_input;
wire[16-1:0] D_IN_input;
wire[8-1:0] D_EN_input;
 //The configuration bits (if any) are just a long shift register
 //This shift register is padded to an even number of flops/latches
 //switch matrix multiplexer S_GBUF_FEED_BEG0 MUX-4
assign S_GBUF_FEED_BEG0_input = {A_OUT,W2END7,W1END1,S_GBUF_FEED_END0};
cus_mux41 inst_cus_mux41_S_GBUF_FEED_BEG0 (
    .A0(S_GBUF_FEED_BEG0_input[0]),
    .A1(S_GBUF_FEED_BEG0_input[1]),
    .A2(S_GBUF_FEED_BEG0_input[2]),
    .A3(S_GBUF_FEED_BEG0_input[3]),
    .S0(ConfigBits[0+0]),
    .S0N(ConfigBits_N[0+0]),
    .S1(ConfigBits[0+1]),
    .S1N(ConfigBits_N[0+1]),
    .X(S_GBUF_FEED_BEG0)
);

 //switch matrix multiplexer S_GBUF_FEED_BEG1 MUX-4
assign S_GBUF_FEED_BEG1_input = {B_OUT,W2END6,W1END2,S_GBUF_FEED_END1};
cus_mux41 inst_cus_mux41_S_GBUF_FEED_BEG1 (
    .A0(S_GBUF_FEED_BEG1_input[0]),
    .A1(S_GBUF_FEED_BEG1_input[1]),
    .A2(S_GBUF_FEED_BEG1_input[2]),
    .A3(S_GBUF_FEED_BEG1_input[3]),
    .S0(ConfigBits[2+0]),
    .S0N(ConfigBits_N[2+0]),
    .S1(ConfigBits[2+1]),
    .S1N(ConfigBits_N[2+1]),
    .X(S_GBUF_FEED_BEG1)
);

 //switch matrix multiplexer S_GBUF_FEED_BEG2 MUX-4
assign S_GBUF_FEED_BEG2_input = {C_OUT,W2END5,W1END3,S_GBUF_FEED_END2};
cus_mux41 inst_cus_mux41_S_GBUF_FEED_BEG2 (
    .A0(S_GBUF_FEED_BEG2_input[0]),
    .A1(S_GBUF_FEED_BEG2_input[1]),
    .A2(S_GBUF_FEED_BEG2_input[2]),
    .A3(S_GBUF_FEED_BEG2_input[3]),
    .S0(ConfigBits[4+0]),
    .S0N(ConfigBits_N[4+0]),
    .S1(ConfigBits[4+1]),
    .S1N(ConfigBits_N[4+1]),
    .X(S_GBUF_FEED_BEG2)
);

 //switch matrix multiplexer S_GBUF_FEED_BEG3 MUX-4
assign S_GBUF_FEED_BEG3_input = {D_OUT,W2END4,W1END0,S_GBUF_FEED_END3};
cus_mux41 inst_cus_mux41_S_GBUF_FEED_BEG3 (
    .A0(S_GBUF_FEED_BEG3_input[0]),
    .A1(S_GBUF_FEED_BEG3_input[1]),
    .A2(S_GBUF_FEED_BEG3_input[2]),
    .A3(S_GBUF_FEED_BEG3_input[3]),
    .S0(ConfigBits[6+0]),
    .S0N(ConfigBits_N[6+0]),
    .S1(ConfigBits[6+1]),
    .S1N(ConfigBits_N[6+1]),
    .X(S_GBUF_FEED_BEG3)
);

 //switch matrix multiplexer N_GBUF_BEG0 MUX-1
assign N_GBUF_BEG0 = N_GBUF_END0;

 //switch matrix multiplexer N_GBUF_BEG1 MUX-1
assign N_GBUF_BEG1 = N_GBUF_END1;

 //switch matrix multiplexer N_GBUF_BEG2 MUX-1
assign N_GBUF_BEG2 = N_GBUF_END2;

 //switch matrix multiplexer N_GBUF_BEG3 MUX-1
assign N_GBUF_BEG3 = N_GBUF_END3;

 //switch matrix multiplexer E1BEG0 MUX-4
assign E1BEG0_input = {A_OUT,W2END7,W2MID7,W1END7};
cus_mux41 inst_cus_mux41_E1BEG0 (
    .A0(E1BEG0_input[0]),
    .A1(E1BEG0_input[1]),
    .A2(E1BEG0_input[2]),
    .A3(E1BEG0_input[3]),
    .S0(ConfigBits[8+0]),
    .S0N(ConfigBits_N[8+0]),
    .S1(ConfigBits[8+1]),
    .S1N(ConfigBits_N[8+1]),
    .X(E1BEG0)
);

 //switch matrix multiplexer E1BEG1 MUX-4
assign E1BEG1_input = {B_OUT,W2END6,W2MID6,W1END6};
cus_mux41 inst_cus_mux41_E1BEG1 (
    .A0(E1BEG1_input[0]),
    .A1(E1BEG1_input[1]),
    .A2(E1BEG1_input[2]),
    .A3(E1BEG1_input[3]),
    .S0(ConfigBits[10+0]),
    .S0N(ConfigBits_N[10+0]),
    .S1(ConfigBits[10+1]),
    .S1N(ConfigBits_N[10+1]),
    .X(E1BEG1)
);

 //switch matrix multiplexer E1BEG2 MUX-4
assign E1BEG2_input = {C_OUT,W2END5,W2MID5,W1END5};
cus_mux41 inst_cus_mux41_E1BEG2 (
    .A0(E1BEG2_input[0]),
    .A1(E1BEG2_input[1]),
    .A2(E1BEG2_input[2]),
    .A3(E1BEG2_input[3]),
    .S0(ConfigBits[12+0]),
    .S0N(ConfigBits_N[12+0]),
    .S1(ConfigBits[12+1]),
    .S1N(ConfigBits_N[12+1]),
    .X(E1BEG2)
);

 //switch matrix multiplexer E1BEG3 MUX-4
assign E1BEG3_input = {D_OUT,W2END4,W2MID4,W1END4};
cus_mux41 inst_cus_mux41_E1BEG3 (
    .A0(E1BEG3_input[0]),
    .A1(E1BEG3_input[1]),
    .A2(E1BEG3_input[2]),
    .A3(E1BEG3_input[3]),
    .S0(ConfigBits[14+0]),
    .S0N(ConfigBits_N[14+0]),
    .S1(ConfigBits[14+1]),
    .S1N(ConfigBits_N[14+1]),
    .X(E1BEG3)
);

 //switch matrix multiplexer E1BEG4 MUX-4
assign E1BEG4_input = {A_OUT,W2END3,W2MID3,W1END3};
cus_mux41 inst_cus_mux41_E1BEG4 (
    .A0(E1BEG4_input[0]),
    .A1(E1BEG4_input[1]),
    .A2(E1BEG4_input[2]),
    .A3(E1BEG4_input[3]),
    .S0(ConfigBits[16+0]),
    .S0N(ConfigBits_N[16+0]),
    .S1(ConfigBits[16+1]),
    .S1N(ConfigBits_N[16+1]),
    .X(E1BEG4)
);

 //switch matrix multiplexer E1BEG5 MUX-4
assign E1BEG5_input = {B_OUT,W2END2,W2MID2,W1END2};
cus_mux41 inst_cus_mux41_E1BEG5 (
    .A0(E1BEG5_input[0]),
    .A1(E1BEG5_input[1]),
    .A2(E1BEG5_input[2]),
    .A3(E1BEG5_input[3]),
    .S0(ConfigBits[18+0]),
    .S0N(ConfigBits_N[18+0]),
    .S1(ConfigBits[18+1]),
    .S1N(ConfigBits_N[18+1]),
    .X(E1BEG5)
);

 //switch matrix multiplexer E1BEG6 MUX-4
assign E1BEG6_input = {C_OUT,W2END1,W2MID1,W1END1};
cus_mux41 inst_cus_mux41_E1BEG6 (
    .A0(E1BEG6_input[0]),
    .A1(E1BEG6_input[1]),
    .A2(E1BEG6_input[2]),
    .A3(E1BEG6_input[3]),
    .S0(ConfigBits[20+0]),
    .S0N(ConfigBits_N[20+0]),
    .S1(ConfigBits[20+1]),
    .S1N(ConfigBits_N[20+1]),
    .X(E1BEG6)
);

 //switch matrix multiplexer E1BEG7 MUX-4
assign E1BEG7_input = {D_OUT,W2END0,W2MID0,W1END0};
cus_mux41 inst_cus_mux41_E1BEG7 (
    .A0(E1BEG7_input[0]),
    .A1(E1BEG7_input[1]),
    .A2(E1BEG7_input[2]),
    .A3(E1BEG7_input[3]),
    .S0(ConfigBits[22+0]),
    .S0N(ConfigBits_N[22+0]),
    .S1(ConfigBits[22+1]),
    .S1N(ConfigBits_N[22+1]),
    .X(E1BEG7)
);

 //switch matrix multiplexer E2BEG0 MUX-4
assign E2BEG0_input = {A_OUT,W2END7,W2MID7,W1END7};
cus_mux41 inst_cus_mux41_E2BEG0 (
    .A0(E2BEG0_input[0]),
    .A1(E2BEG0_input[1]),
    .A2(E2BEG0_input[2]),
    .A3(E2BEG0_input[3]),
    .S0(ConfigBits[24+0]),
    .S0N(ConfigBits_N[24+0]),
    .S1(ConfigBits[24+1]),
    .S1N(ConfigBits_N[24+1]),
    .X(E2BEG0)
);

 //switch matrix multiplexer E2BEG1 MUX-4
assign E2BEG1_input = {B_OUT,W2END6,W2MID6,W1END6};
cus_mux41 inst_cus_mux41_E2BEG1 (
    .A0(E2BEG1_input[0]),
    .A1(E2BEG1_input[1]),
    .A2(E2BEG1_input[2]),
    .A3(E2BEG1_input[3]),
    .S0(ConfigBits[26+0]),
    .S0N(ConfigBits_N[26+0]),
    .S1(ConfigBits[26+1]),
    .S1N(ConfigBits_N[26+1]),
    .X(E2BEG1)
);

 //switch matrix multiplexer E2BEG2 MUX-4
assign E2BEG2_input = {C_OUT,W2END5,W2MID5,W1END5};
cus_mux41 inst_cus_mux41_E2BEG2 (
    .A0(E2BEG2_input[0]),
    .A1(E2BEG2_input[1]),
    .A2(E2BEG2_input[2]),
    .A3(E2BEG2_input[3]),
    .S0(ConfigBits[28+0]),
    .S0N(ConfigBits_N[28+0]),
    .S1(ConfigBits[28+1]),
    .S1N(ConfigBits_N[28+1]),
    .X(E2BEG2)
);

 //switch matrix multiplexer E2BEG3 MUX-4
assign E2BEG3_input = {D_OUT,W2END4,W2MID4,W1END4};
cus_mux41 inst_cus_mux41_E2BEG3 (
    .A0(E2BEG3_input[0]),
    .A1(E2BEG3_input[1]),
    .A2(E2BEG3_input[2]),
    .A3(E2BEG3_input[3]),
    .S0(ConfigBits[30+0]),
    .S0N(ConfigBits_N[30+0]),
    .S1(ConfigBits[30+1]),
    .S1N(ConfigBits_N[30+1]),
    .X(E2BEG3)
);

 //switch matrix multiplexer E2BEG4 MUX-4
assign E2BEG4_input = {A_OUT,W2END3,W2MID3,W1END3};
cus_mux41 inst_cus_mux41_E2BEG4 (
    .A0(E2BEG4_input[0]),
    .A1(E2BEG4_input[1]),
    .A2(E2BEG4_input[2]),
    .A3(E2BEG4_input[3]),
    .S0(ConfigBits[32+0]),
    .S0N(ConfigBits_N[32+0]),
    .S1(ConfigBits[32+1]),
    .S1N(ConfigBits_N[32+1]),
    .X(E2BEG4)
);

 //switch matrix multiplexer E2BEG5 MUX-4
assign E2BEG5_input = {B_OUT,W2END2,W2MID2,W1END2};
cus_mux41 inst_cus_mux41_E2BEG5 (
    .A0(E2BEG5_input[0]),
    .A1(E2BEG5_input[1]),
    .A2(E2BEG5_input[2]),
    .A3(E2BEG5_input[3]),
    .S0(ConfigBits[34+0]),
    .S0N(ConfigBits_N[34+0]),
    .S1(ConfigBits[34+1]),
    .S1N(ConfigBits_N[34+1]),
    .X(E2BEG5)
);

 //switch matrix multiplexer E2BEG6 MUX-4
assign E2BEG6_input = {C_OUT,W2END1,W2MID1,W1END1};
cus_mux41 inst_cus_mux41_E2BEG6 (
    .A0(E2BEG6_input[0]),
    .A1(E2BEG6_input[1]),
    .A2(E2BEG6_input[2]),
    .A3(E2BEG6_input[3]),
    .S0(ConfigBits[36+0]),
    .S0N(ConfigBits_N[36+0]),
    .S1(ConfigBits[36+1]),
    .S1N(ConfigBits_N[36+1]),
    .X(E2BEG6)
);

 //switch matrix multiplexer E2BEG7 MUX-4
assign E2BEG7_input = {D_OUT,W2END0,W2MID0,W1END0};
cus_mux41 inst_cus_mux41_E2BEG7 (
    .A0(E2BEG7_input[0]),
    .A1(E2BEG7_input[1]),
    .A2(E2BEG7_input[2]),
    .A3(E2BEG7_input[3]),
    .S0(ConfigBits[38+0]),
    .S0N(ConfigBits_N[38+0]),
    .S1(ConfigBits[38+1]),
    .S1N(ConfigBits_N[38+1]),
    .X(E2BEG7)
);

 //switch matrix multiplexer E2BEGb0 MUX-4
assign E2BEGb0_input = {D_OUT,W2END7,W2MID7,W1END7};
cus_mux41 inst_cus_mux41_E2BEGb0 (
    .A0(E2BEGb0_input[0]),
    .A1(E2BEGb0_input[1]),
    .A2(E2BEGb0_input[2]),
    .A3(E2BEGb0_input[3]),
    .S0(ConfigBits[40+0]),
    .S0N(ConfigBits_N[40+0]),
    .S1(ConfigBits[40+1]),
    .S1N(ConfigBits_N[40+1]),
    .X(E2BEGb0)
);

 //switch matrix multiplexer E2BEGb1 MUX-4
assign E2BEGb1_input = {C_OUT,W2END6,W2MID6,W1END6};
cus_mux41 inst_cus_mux41_E2BEGb1 (
    .A0(E2BEGb1_input[0]),
    .A1(E2BEGb1_input[1]),
    .A2(E2BEGb1_input[2]),
    .A3(E2BEGb1_input[3]),
    .S0(ConfigBits[42+0]),
    .S0N(ConfigBits_N[42+0]),
    .S1(ConfigBits[42+1]),
    .S1N(ConfigBits_N[42+1]),
    .X(E2BEGb1)
);

 //switch matrix multiplexer E2BEGb2 MUX-4
assign E2BEGb2_input = {C_OUT,W2END5,W2MID5,W1END5};
cus_mux41 inst_cus_mux41_E2BEGb2 (
    .A0(E2BEGb2_input[0]),
    .A1(E2BEGb2_input[1]),
    .A2(E2BEGb2_input[2]),
    .A3(E2BEGb2_input[3]),
    .S0(ConfigBits[44+0]),
    .S0N(ConfigBits_N[44+0]),
    .S1(ConfigBits[44+1]),
    .S1N(ConfigBits_N[44+1]),
    .X(E2BEGb2)
);

 //switch matrix multiplexer E2BEGb3 MUX-4
assign E2BEGb3_input = {A_OUT,W2END4,W2MID4,W1END4};
cus_mux41 inst_cus_mux41_E2BEGb3 (
    .A0(E2BEGb3_input[0]),
    .A1(E2BEGb3_input[1]),
    .A2(E2BEGb3_input[2]),
    .A3(E2BEGb3_input[3]),
    .S0(ConfigBits[46+0]),
    .S0N(ConfigBits_N[46+0]),
    .S1(ConfigBits[46+1]),
    .S1N(ConfigBits_N[46+1]),
    .X(E2BEGb3)
);

 //switch matrix multiplexer E2BEGb4 MUX-4
assign E2BEGb4_input = {D_OUT,W2END3,W2MID3,W1END3};
cus_mux41 inst_cus_mux41_E2BEGb4 (
    .A0(E2BEGb4_input[0]),
    .A1(E2BEGb4_input[1]),
    .A2(E2BEGb4_input[2]),
    .A3(E2BEGb4_input[3]),
    .S0(ConfigBits[48+0]),
    .S0N(ConfigBits_N[48+0]),
    .S1(ConfigBits[48+1]),
    .S1N(ConfigBits_N[48+1]),
    .X(E2BEGb4)
);

 //switch matrix multiplexer E2BEGb5 MUX-4
assign E2BEGb5_input = {C_OUT,W2END2,W2MID2,W1END2};
cus_mux41 inst_cus_mux41_E2BEGb5 (
    .A0(E2BEGb5_input[0]),
    .A1(E2BEGb5_input[1]),
    .A2(E2BEGb5_input[2]),
    .A3(E2BEGb5_input[3]),
    .S0(ConfigBits[50+0]),
    .S0N(ConfigBits_N[50+0]),
    .S1(ConfigBits[50+1]),
    .S1N(ConfigBits_N[50+1]),
    .X(E2BEGb5)
);

 //switch matrix multiplexer E2BEGb6 MUX-4
assign E2BEGb6_input = {B_OUT,W2END1,W2MID1,W1END1};
cus_mux41 inst_cus_mux41_E2BEGb6 (
    .A0(E2BEGb6_input[0]),
    .A1(E2BEGb6_input[1]),
    .A2(E2BEGb6_input[2]),
    .A3(E2BEGb6_input[3]),
    .S0(ConfigBits[52+0]),
    .S0N(ConfigBits_N[52+0]),
    .S1(ConfigBits[52+1]),
    .S1N(ConfigBits_N[52+1]),
    .X(E2BEGb6)
);

 //switch matrix multiplexer E2BEGb7 MUX-4
assign E2BEGb7_input = {A_OUT,W2END0,W2MID0,W1END0};
cus_mux41 inst_cus_mux41_E2BEGb7 (
    .A0(E2BEGb7_input[0]),
    .A1(E2BEGb7_input[1]),
    .A2(E2BEGb7_input[2]),
    .A3(E2BEGb7_input[3]),
    .S0(ConfigBits[54+0]),
    .S0N(ConfigBits_N[54+0]),
    .S1(ConfigBits[54+1]),
    .S1N(ConfigBits_N[54+1]),
    .X(E2BEGb7)
);

 //switch matrix multiplexer A_CLK MUX-4
assign A_CLK_input = {N_GBUF_END3,N_GBUF_END2,N_GBUF_END1,N_GBUF_END0};
cus_mux41 inst_cus_mux41_A_CLK (
    .A0(A_CLK_input[0]),
    .A1(A_CLK_input[1]),
    .A2(A_CLK_input[2]),
    .A3(A_CLK_input[3]),
    .S0(ConfigBits[56+0]),
    .S0N(ConfigBits_N[56+0]),
    .S1(ConfigBits[56+1]),
    .S1N(ConfigBits_N[56+1]),
    .X(A_CLK)
);

 //switch matrix multiplexer A_IN MUX-16
assign A_IN_input = {VCC0,GND0,W2END7,W2END6,W2END5,W2MID2,W2MID1,W2MID0,W1END7,W1END6,W1END5,W1END4,W1END3,W1END2,W1END1,W1END0};
cus_mux161 inst_cus_mux161_A_IN (
    .A0(A_IN_input[0]),
    .A1(A_IN_input[1]),
    .A2(A_IN_input[2]),
    .A3(A_IN_input[3]),
    .A4(A_IN_input[4]),
    .A5(A_IN_input[5]),
    .A6(A_IN_input[6]),
    .A7(A_IN_input[7]),
    .A8(A_IN_input[8]),
    .A9(A_IN_input[9]),
    .A10(A_IN_input[10]),
    .A11(A_IN_input[11]),
    .A12(A_IN_input[12]),
    .A13(A_IN_input[13]),
    .A14(A_IN_input[14]),
    .A15(A_IN_input[15]),
    .S0(ConfigBits[58+0]),
    .S0N(ConfigBits_N[58+0]),
    .S1(ConfigBits[58+1]),
    .S1N(ConfigBits_N[58+1]),
    .S2(ConfigBits[58+2]),
    .S2N(ConfigBits_N[58+2]),
    .S3(ConfigBits[58+3]),
    .S3N(ConfigBits_N[58+3]),
    .X(A_IN)
);

 //switch matrix multiplexer A_EN MUX-8
assign A_EN_input = {VCC0,GND0,W2END2,W2END0,W2MID7,W2MID4,W1END7,W1END3};
cus_mux81 inst_cus_mux81_A_EN (
    .A0(A_EN_input[0]),
    .A1(A_EN_input[1]),
    .A2(A_EN_input[2]),
    .A3(A_EN_input[3]),
    .A4(A_EN_input[4]),
    .A5(A_EN_input[5]),
    .A6(A_EN_input[6]),
    .A7(A_EN_input[7]),
    .S0(ConfigBits[62+0]),
    .S0N(ConfigBits_N[62+0]),
    .S1(ConfigBits[62+1]),
    .S1N(ConfigBits_N[62+1]),
    .S2(ConfigBits[62+2]),
    .S2N(ConfigBits_N[62+2]),
    .X(A_EN)
);

 //switch matrix multiplexer B_CLK MUX-4
assign B_CLK_input = {N_GBUF_END3,N_GBUF_END2,N_GBUF_END1,N_GBUF_END0};
cus_mux41 inst_cus_mux41_B_CLK (
    .A0(B_CLK_input[0]),
    .A1(B_CLK_input[1]),
    .A2(B_CLK_input[2]),
    .A3(B_CLK_input[3]),
    .S0(ConfigBits[65+0]),
    .S0N(ConfigBits_N[65+0]),
    .S1(ConfigBits[65+1]),
    .S1N(ConfigBits_N[65+1]),
    .X(B_CLK)
);

 //switch matrix multiplexer B_IN MUX-16
assign B_IN_input = {VCC0,GND0,W2END7,W2END6,W2END5,W2MID2,W2MID1,W2MID0,W1END7,W1END6,W1END5,W1END4,W1END3,W1END2,W1END1,W1END0};
cus_mux161 inst_cus_mux161_B_IN (
    .A0(B_IN_input[0]),
    .A1(B_IN_input[1]),
    .A2(B_IN_input[2]),
    .A3(B_IN_input[3]),
    .A4(B_IN_input[4]),
    .A5(B_IN_input[5]),
    .A6(B_IN_input[6]),
    .A7(B_IN_input[7]),
    .A8(B_IN_input[8]),
    .A9(B_IN_input[9]),
    .A10(B_IN_input[10]),
    .A11(B_IN_input[11]),
    .A12(B_IN_input[12]),
    .A13(B_IN_input[13]),
    .A14(B_IN_input[14]),
    .A15(B_IN_input[15]),
    .S0(ConfigBits[67+0]),
    .S0N(ConfigBits_N[67+0]),
    .S1(ConfigBits[67+1]),
    .S1N(ConfigBits_N[67+1]),
    .S2(ConfigBits[67+2]),
    .S2N(ConfigBits_N[67+2]),
    .S3(ConfigBits[67+3]),
    .S3N(ConfigBits_N[67+3]),
    .X(B_IN)
);

 //switch matrix multiplexer B_EN MUX-8
assign B_EN_input = {VCC0,GND0,W2END2,W2END0,W2MID7,W2MID4,W1END7,W1END3};
cus_mux81 inst_cus_mux81_B_EN (
    .A0(B_EN_input[0]),
    .A1(B_EN_input[1]),
    .A2(B_EN_input[2]),
    .A3(B_EN_input[3]),
    .A4(B_EN_input[4]),
    .A5(B_EN_input[5]),
    .A6(B_EN_input[6]),
    .A7(B_EN_input[7]),
    .S0(ConfigBits[71+0]),
    .S0N(ConfigBits_N[71+0]),
    .S1(ConfigBits[71+1]),
    .S1N(ConfigBits_N[71+1]),
    .S2(ConfigBits[71+2]),
    .S2N(ConfigBits_N[71+2]),
    .X(B_EN)
);

 //switch matrix multiplexer C_CLK MUX-4
assign C_CLK_input = {N_GBUF_END3,N_GBUF_END2,N_GBUF_END1,N_GBUF_END0};
cus_mux41 inst_cus_mux41_C_CLK (
    .A0(C_CLK_input[0]),
    .A1(C_CLK_input[1]),
    .A2(C_CLK_input[2]),
    .A3(C_CLK_input[3]),
    .S0(ConfigBits[74+0]),
    .S0N(ConfigBits_N[74+0]),
    .S1(ConfigBits[74+1]),
    .S1N(ConfigBits_N[74+1]),
    .X(C_CLK)
);

 //switch matrix multiplexer C_IN MUX-16
assign C_IN_input = {VCC0,GND0,W2END7,W2END6,W2END5,W2MID2,W2MID1,W2MID0,W1END7,W1END6,W1END5,W1END4,W1END3,W1END2,W1END1,W1END0};
cus_mux161 inst_cus_mux161_C_IN (
    .A0(C_IN_input[0]),
    .A1(C_IN_input[1]),
    .A2(C_IN_input[2]),
    .A3(C_IN_input[3]),
    .A4(C_IN_input[4]),
    .A5(C_IN_input[5]),
    .A6(C_IN_input[6]),
    .A7(C_IN_input[7]),
    .A8(C_IN_input[8]),
    .A9(C_IN_input[9]),
    .A10(C_IN_input[10]),
    .A11(C_IN_input[11]),
    .A12(C_IN_input[12]),
    .A13(C_IN_input[13]),
    .A14(C_IN_input[14]),
    .A15(C_IN_input[15]),
    .S0(ConfigBits[76+0]),
    .S0N(ConfigBits_N[76+0]),
    .S1(ConfigBits[76+1]),
    .S1N(ConfigBits_N[76+1]),
    .S2(ConfigBits[76+2]),
    .S2N(ConfigBits_N[76+2]),
    .S3(ConfigBits[76+3]),
    .S3N(ConfigBits_N[76+3]),
    .X(C_IN)
);

 //switch matrix multiplexer C_EN MUX-8
assign C_EN_input = {VCC0,GND0,W2END2,W2END0,W2MID7,W2MID4,W1END7,W1END3};
cus_mux81 inst_cus_mux81_C_EN (
    .A0(C_EN_input[0]),
    .A1(C_EN_input[1]),
    .A2(C_EN_input[2]),
    .A3(C_EN_input[3]),
    .A4(C_EN_input[4]),
    .A5(C_EN_input[5]),
    .A6(C_EN_input[6]),
    .A7(C_EN_input[7]),
    .S0(ConfigBits[80+0]),
    .S0N(ConfigBits_N[80+0]),
    .S1(ConfigBits[80+1]),
    .S1N(ConfigBits_N[80+1]),
    .S2(ConfigBits[80+2]),
    .S2N(ConfigBits_N[80+2]),
    .X(C_EN)
);

 //switch matrix multiplexer D_CLK MUX-4
assign D_CLK_input = {N_GBUF_END3,N_GBUF_END2,N_GBUF_END1,N_GBUF_END0};
cus_mux41 inst_cus_mux41_D_CLK (
    .A0(D_CLK_input[0]),
    .A1(D_CLK_input[1]),
    .A2(D_CLK_input[2]),
    .A3(D_CLK_input[3]),
    .S0(ConfigBits[83+0]),
    .S0N(ConfigBits_N[83+0]),
    .S1(ConfigBits[83+1]),
    .S1N(ConfigBits_N[83+1]),
    .X(D_CLK)
);

 //switch matrix multiplexer D_IN MUX-16
assign D_IN_input = {VCC0,GND0,W2END7,W2END6,W2END5,W2MID2,W2MID1,W2MID0,W1END7,W1END6,W1END5,W1END4,W1END3,W1END2,W1END1,W1END0};
cus_mux161 inst_cus_mux161_D_IN (
    .A0(D_IN_input[0]),
    .A1(D_IN_input[1]),
    .A2(D_IN_input[2]),
    .A3(D_IN_input[3]),
    .A4(D_IN_input[4]),
    .A5(D_IN_input[5]),
    .A6(D_IN_input[6]),
    .A7(D_IN_input[7]),
    .A8(D_IN_input[8]),
    .A9(D_IN_input[9]),
    .A10(D_IN_input[10]),
    .A11(D_IN_input[11]),
    .A12(D_IN_input[12]),
    .A13(D_IN_input[13]),
    .A14(D_IN_input[14]),
    .A15(D_IN_input[15]),
    .S0(ConfigBits[85+0]),
    .S0N(ConfigBits_N[85+0]),
    .S1(ConfigBits[85+1]),
    .S1N(ConfigBits_N[85+1]),
    .S2(ConfigBits[85+2]),
    .S2N(ConfigBits_N[85+2]),
    .S3(ConfigBits[85+3]),
    .S3N(ConfigBits_N[85+3]),
    .X(D_IN)
);

 //switch matrix multiplexer D_EN MUX-8
assign D_EN_input = {VCC0,GND0,W2END2,W2END0,W2MID7,W2MID4,W1END7,W1END3};
cus_mux81 inst_cus_mux81_D_EN (
    .A0(D_EN_input[0]),
    .A1(D_EN_input[1]),
    .A2(D_EN_input[2]),
    .A3(D_EN_input[3]),
    .A4(D_EN_input[4]),
    .A5(D_EN_input[5]),
    .A6(D_EN_input[6]),
    .A7(D_EN_input[7]),
    .S0(ConfigBits[89+0]),
    .S0N(ConfigBits_N[89+0]),
    .S1(ConfigBits[89+1]),
    .S1N(ConfigBits_N[89+1]),
    .S2(ConfigBits[89+2]),
    .S2N(ConfigBits_N[89+2]),
    .X(D_EN)
);

endmodule
module W_IO4
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=104
    )
    (
 //N
        input  [3:0] S_GBUF_FEED_END,        //Port(Name=S_GBUF_FEED_END,IO=INPUT,XOffset=0,YOffset=1,WireCount=4,Side=N)
        output  [3:0] N_GBUF_BEG,        //Port(Name=N_GBUF_BEG,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=4,Side=N)
 //E
        output  [7:0] E1BEG,        //Port(Name=E1BEG,IO=OUTPUT,XOffset=1,YOffset=0,WireCount=8,Side=E)
        output  [7:0] E2BEG,        //Port(Name=E2BEG,IO=OUTPUT,XOffset=1,YOffset=0,WireCount=8,Side=E)
        output  [7:0] E2BEGb,        //Port(Name=E2BEGb,IO=OUTPUT,XOffset=1,YOffset=0,WireCount=8,Side=E)
        input  [7:0] W1END,        //Port(Name=W1END,IO=INPUT,XOffset=-1,YOffset=0,WireCount=8,Side=E)
        input  [7:0] W2MID,        //Port(Name=W2MID,IO=INPUT,XOffset=-1,YOffset=0,WireCount=8,Side=E)
        input  [7:0] W2END,        //Port(Name=W2END,IO=INPUT,XOffset=-1,YOffset=0,WireCount=8,Side=E)
 //S
        output  [3:0] S_GBUF_FEED_BEG,        //Port(Name=S_GBUF_FEED_BEG,IO=OUTPUT,XOffset=0,YOffset=1,WireCount=4,Side=S)
        input  [3:0] N_GBUF_END,        //Port(Name=N_GBUF_END,IO=INPUT,XOffset=0,YOffset=-1,WireCount=4,Side=S)
        input  A_OUT_top,
        output  A_IN_top,
        output  A_EN_top,
        input  B_OUT_top,
        output  B_IN_top,
        output  B_EN_top,
        input  C_OUT_top,
        output  C_IN_top,
        output  C_EN_top,
        input  D_OUT_top,
        output  D_IN_top,
        output  D_EN_top,
    //Tile IO ports from BELs
        input  [FrameBitsPerRow-1:0] FrameData, //CONFIG_PORT
        output  [FrameBitsPerRow-1:0] FrameData_O,
        input  [MaxFramesPerCol-1:0] FrameStrobe, //CONFIG_PORT
        output  [MaxFramesPerCol-1:0] FrameStrobe_O
    //global
);
 //signal declarations
 //BEL ports (e.g., slices)
wire A_CLK;
wire A_IN;
wire A_EN;
wire A_OUT;
wire B_CLK;
wire B_IN;
wire B_EN;
wire B_OUT;
wire C_CLK;
wire C_IN;
wire C_EN;
wire C_OUT;
wire D_CLK;
wire D_IN;
wire D_EN;
wire D_OUT;
 //Jump wires
 //internal configuration data signal to daisy-chain all BELs (if any and in the order they are listed in the fabric.csv)
wire[NoConfigBits-1:0] ConfigBits;
wire[NoConfigBits-1:0] ConfigBits_N;

 //Connection for outgoing wires
wire[FrameBitsPerRow-1:0] FrameData_i;
wire[FrameBitsPerRow-1:0] FrameData_O_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_O_i;

assign FrameData_O_i = FrameData_i;

my_buf data_inbuf_0 (
    .A(FrameData[0]),
    .X(FrameData_i[0])
);

my_buf data_inbuf_1 (
    .A(FrameData[1]),
    .X(FrameData_i[1])
);

my_buf data_inbuf_2 (
    .A(FrameData[2]),
    .X(FrameData_i[2])
);

my_buf data_inbuf_3 (
    .A(FrameData[3]),
    .X(FrameData_i[3])
);

my_buf data_inbuf_4 (
    .A(FrameData[4]),
    .X(FrameData_i[4])
);

my_buf data_inbuf_5 (
    .A(FrameData[5]),
    .X(FrameData_i[5])
);

my_buf data_inbuf_6 (
    .A(FrameData[6]),
    .X(FrameData_i[6])
);

my_buf data_inbuf_7 (
    .A(FrameData[7]),
    .X(FrameData_i[7])
);

my_buf data_inbuf_8 (
    .A(FrameData[8]),
    .X(FrameData_i[8])
);

my_buf data_inbuf_9 (
    .A(FrameData[9]),
    .X(FrameData_i[9])
);

my_buf data_inbuf_10 (
    .A(FrameData[10]),
    .X(FrameData_i[10])
);

my_buf data_inbuf_11 (
    .A(FrameData[11]),
    .X(FrameData_i[11])
);

my_buf data_inbuf_12 (
    .A(FrameData[12]),
    .X(FrameData_i[12])
);

my_buf data_inbuf_13 (
    .A(FrameData[13]),
    .X(FrameData_i[13])
);

my_buf data_inbuf_14 (
    .A(FrameData[14]),
    .X(FrameData_i[14])
);

my_buf data_inbuf_15 (
    .A(FrameData[15]),
    .X(FrameData_i[15])
);

my_buf data_inbuf_16 (
    .A(FrameData[16]),
    .X(FrameData_i[16])
);

my_buf data_inbuf_17 (
    .A(FrameData[17]),
    .X(FrameData_i[17])
);

my_buf data_inbuf_18 (
    .A(FrameData[18]),
    .X(FrameData_i[18])
);

my_buf data_inbuf_19 (
    .A(FrameData[19]),
    .X(FrameData_i[19])
);

my_buf data_inbuf_20 (
    .A(FrameData[20]),
    .X(FrameData_i[20])
);

my_buf data_inbuf_21 (
    .A(FrameData[21]),
    .X(FrameData_i[21])
);

my_buf data_inbuf_22 (
    .A(FrameData[22]),
    .X(FrameData_i[22])
);

my_buf data_inbuf_23 (
    .A(FrameData[23]),
    .X(FrameData_i[23])
);

my_buf data_inbuf_24 (
    .A(FrameData[24]),
    .X(FrameData_i[24])
);

my_buf data_inbuf_25 (
    .A(FrameData[25]),
    .X(FrameData_i[25])
);

my_buf data_inbuf_26 (
    .A(FrameData[26]),
    .X(FrameData_i[26])
);

my_buf data_inbuf_27 (
    .A(FrameData[27]),
    .X(FrameData_i[27])
);

my_buf data_inbuf_28 (
    .A(FrameData[28]),
    .X(FrameData_i[28])
);

my_buf data_inbuf_29 (
    .A(FrameData[29]),
    .X(FrameData_i[29])
);

my_buf data_inbuf_30 (
    .A(FrameData[30]),
    .X(FrameData_i[30])
);

my_buf data_inbuf_31 (
    .A(FrameData[31]),
    .X(FrameData_i[31])
);

my_buf data_outbuf_0 (
    .A(FrameData_O_i[0]),
    .X(FrameData_O[0])
);

my_buf data_outbuf_1 (
    .A(FrameData_O_i[1]),
    .X(FrameData_O[1])
);

my_buf data_outbuf_2 (
    .A(FrameData_O_i[2]),
    .X(FrameData_O[2])
);

my_buf data_outbuf_3 (
    .A(FrameData_O_i[3]),
    .X(FrameData_O[3])
);

my_buf data_outbuf_4 (
    .A(FrameData_O_i[4]),
    .X(FrameData_O[4])
);

my_buf data_outbuf_5 (
    .A(FrameData_O_i[5]),
    .X(FrameData_O[5])
);

my_buf data_outbuf_6 (
    .A(FrameData_O_i[6]),
    .X(FrameData_O[6])
);

my_buf data_outbuf_7 (
    .A(FrameData_O_i[7]),
    .X(FrameData_O[7])
);

my_buf data_outbuf_8 (
    .A(FrameData_O_i[8]),
    .X(FrameData_O[8])
);

my_buf data_outbuf_9 (
    .A(FrameData_O_i[9]),
    .X(FrameData_O[9])
);

my_buf data_outbuf_10 (
    .A(FrameData_O_i[10]),
    .X(FrameData_O[10])
);

my_buf data_outbuf_11 (
    .A(FrameData_O_i[11]),
    .X(FrameData_O[11])
);

my_buf data_outbuf_12 (
    .A(FrameData_O_i[12]),
    .X(FrameData_O[12])
);

my_buf data_outbuf_13 (
    .A(FrameData_O_i[13]),
    .X(FrameData_O[13])
);

my_buf data_outbuf_14 (
    .A(FrameData_O_i[14]),
    .X(FrameData_O[14])
);

my_buf data_outbuf_15 (
    .A(FrameData_O_i[15]),
    .X(FrameData_O[15])
);

my_buf data_outbuf_16 (
    .A(FrameData_O_i[16]),
    .X(FrameData_O[16])
);

my_buf data_outbuf_17 (
    .A(FrameData_O_i[17]),
    .X(FrameData_O[17])
);

my_buf data_outbuf_18 (
    .A(FrameData_O_i[18]),
    .X(FrameData_O[18])
);

my_buf data_outbuf_19 (
    .A(FrameData_O_i[19]),
    .X(FrameData_O[19])
);

my_buf data_outbuf_20 (
    .A(FrameData_O_i[20]),
    .X(FrameData_O[20])
);

my_buf data_outbuf_21 (
    .A(FrameData_O_i[21]),
    .X(FrameData_O[21])
);

my_buf data_outbuf_22 (
    .A(FrameData_O_i[22]),
    .X(FrameData_O[22])
);

my_buf data_outbuf_23 (
    .A(FrameData_O_i[23]),
    .X(FrameData_O[23])
);

my_buf data_outbuf_24 (
    .A(FrameData_O_i[24]),
    .X(FrameData_O[24])
);

my_buf data_outbuf_25 (
    .A(FrameData_O_i[25]),
    .X(FrameData_O[25])
);

my_buf data_outbuf_26 (
    .A(FrameData_O_i[26]),
    .X(FrameData_O[26])
);

my_buf data_outbuf_27 (
    .A(FrameData_O_i[27]),
    .X(FrameData_O[27])
);

my_buf data_outbuf_28 (
    .A(FrameData_O_i[28]),
    .X(FrameData_O[28])
);

my_buf data_outbuf_29 (
    .A(FrameData_O_i[29]),
    .X(FrameData_O[29])
);

my_buf data_outbuf_30 (
    .A(FrameData_O_i[30]),
    .X(FrameData_O[30])
);

my_buf data_outbuf_31 (
    .A(FrameData_O_i[31]),
    .X(FrameData_O[31])
);

assign FrameStrobe_O_i = FrameStrobe_i;

my_buf strobe_inbuf_0 (
    .A(FrameStrobe[0]),
    .X(FrameStrobe_i[0])
);

my_buf strobe_inbuf_1 (
    .A(FrameStrobe[1]),
    .X(FrameStrobe_i[1])
);

my_buf strobe_inbuf_2 (
    .A(FrameStrobe[2]),
    .X(FrameStrobe_i[2])
);

my_buf strobe_inbuf_3 (
    .A(FrameStrobe[3]),
    .X(FrameStrobe_i[3])
);

my_buf strobe_inbuf_4 (
    .A(FrameStrobe[4]),
    .X(FrameStrobe_i[4])
);

my_buf strobe_inbuf_5 (
    .A(FrameStrobe[5]),
    .X(FrameStrobe_i[5])
);

my_buf strobe_inbuf_6 (
    .A(FrameStrobe[6]),
    .X(FrameStrobe_i[6])
);

my_buf strobe_inbuf_7 (
    .A(FrameStrobe[7]),
    .X(FrameStrobe_i[7])
);

my_buf strobe_inbuf_8 (
    .A(FrameStrobe[8]),
    .X(FrameStrobe_i[8])
);

my_buf strobe_inbuf_9 (
    .A(FrameStrobe[9]),
    .X(FrameStrobe_i[9])
);

my_buf strobe_inbuf_10 (
    .A(FrameStrobe[10]),
    .X(FrameStrobe_i[10])
);

my_buf strobe_inbuf_11 (
    .A(FrameStrobe[11]),
    .X(FrameStrobe_i[11])
);

my_buf strobe_inbuf_12 (
    .A(FrameStrobe[12]),
    .X(FrameStrobe_i[12])
);

my_buf strobe_inbuf_13 (
    .A(FrameStrobe[13]),
    .X(FrameStrobe_i[13])
);

my_buf strobe_inbuf_14 (
    .A(FrameStrobe[14]),
    .X(FrameStrobe_i[14])
);

my_buf strobe_inbuf_15 (
    .A(FrameStrobe[15]),
    .X(FrameStrobe_i[15])
);

my_buf strobe_inbuf_16 (
    .A(FrameStrobe[16]),
    .X(FrameStrobe_i[16])
);

my_buf strobe_inbuf_17 (
    .A(FrameStrobe[17]),
    .X(FrameStrobe_i[17])
);

my_buf strobe_inbuf_18 (
    .A(FrameStrobe[18]),
    .X(FrameStrobe_i[18])
);

my_buf strobe_inbuf_19 (
    .A(FrameStrobe[19]),
    .X(FrameStrobe_i[19])
);

my_buf strobe_outbuf_0 (
    .A(FrameStrobe_O_i[0]),
    .X(FrameStrobe_O[0])
);

my_buf strobe_outbuf_1 (
    .A(FrameStrobe_O_i[1]),
    .X(FrameStrobe_O[1])
);

my_buf strobe_outbuf_2 (
    .A(FrameStrobe_O_i[2]),
    .X(FrameStrobe_O[2])
);

my_buf strobe_outbuf_3 (
    .A(FrameStrobe_O_i[3]),
    .X(FrameStrobe_O[3])
);

my_buf strobe_outbuf_4 (
    .A(FrameStrobe_O_i[4]),
    .X(FrameStrobe_O[4])
);

my_buf strobe_outbuf_5 (
    .A(FrameStrobe_O_i[5]),
    .X(FrameStrobe_O[5])
);

my_buf strobe_outbuf_6 (
    .A(FrameStrobe_O_i[6]),
    .X(FrameStrobe_O[6])
);

my_buf strobe_outbuf_7 (
    .A(FrameStrobe_O_i[7]),
    .X(FrameStrobe_O[7])
);

my_buf strobe_outbuf_8 (
    .A(FrameStrobe_O_i[8]),
    .X(FrameStrobe_O[8])
);

my_buf strobe_outbuf_9 (
    .A(FrameStrobe_O_i[9]),
    .X(FrameStrobe_O[9])
);

my_buf strobe_outbuf_10 (
    .A(FrameStrobe_O_i[10]),
    .X(FrameStrobe_O[10])
);

my_buf strobe_outbuf_11 (
    .A(FrameStrobe_O_i[11]),
    .X(FrameStrobe_O[11])
);

my_buf strobe_outbuf_12 (
    .A(FrameStrobe_O_i[12]),
    .X(FrameStrobe_O[12])
);

my_buf strobe_outbuf_13 (
    .A(FrameStrobe_O_i[13]),
    .X(FrameStrobe_O[13])
);

my_buf strobe_outbuf_14 (
    .A(FrameStrobe_O_i[14]),
    .X(FrameStrobe_O[14])
);

my_buf strobe_outbuf_15 (
    .A(FrameStrobe_O_i[15]),
    .X(FrameStrobe_O[15])
);

my_buf strobe_outbuf_16 (
    .A(FrameStrobe_O_i[16]),
    .X(FrameStrobe_O[16])
);

my_buf strobe_outbuf_17 (
    .A(FrameStrobe_O_i[17]),
    .X(FrameStrobe_O[17])
);

my_buf strobe_outbuf_18 (
    .A(FrameStrobe_O_i[18]),
    .X(FrameStrobe_O[18])
);

my_buf strobe_outbuf_19 (
    .A(FrameStrobe_O_i[19]),
    .X(FrameStrobe_O[19])
);


 //configuration storage latches
W_IO4_ConfigMem
`ifdef EMULATION
    #(
    .Emulate_Bitstream(Emulate_Bitstream)
    )
`endif
    Inst_W_IO4_ConfigMem
    (
    .FrameData(FrameData),
    .FrameStrobe(FrameStrobe),
    .ConfigBits(ConfigBits),
    .ConfigBits_N(ConfigBits_N)
);


 //BEL component instantiations
IOBUF Inst_A_IOBUF (
    .CLK(A_CLK),
    .IN(A_IN),
    .EN(A_EN),
    .OUT(A_OUT),
    .IN_top(A_IN_top),
    .EN_top(A_EN_top),
    .OUT_top(A_OUT_top),
    .ConfigBits(ConfigBits[3-1:0])
);

IOBUF Inst_B_IOBUF (
    .CLK(B_CLK),
    .IN(B_IN),
    .EN(B_EN),
    .OUT(B_OUT),
    .IN_top(B_IN_top),
    .EN_top(B_EN_top),
    .OUT_top(B_OUT_top),
    .ConfigBits(ConfigBits[6-1:3])
);

IOBUF Inst_C_IOBUF (
    .CLK(C_CLK),
    .IN(C_IN),
    .EN(C_EN),
    .OUT(C_OUT),
    .IN_top(C_IN_top),
    .EN_top(C_EN_top),
    .OUT_top(C_OUT_top),
    .ConfigBits(ConfigBits[9-1:6])
);

IOBUF Inst_D_IOBUF (
    .CLK(D_CLK),
    .IN(D_IN),
    .EN(D_EN),
    .OUT(D_OUT),
    .IN_top(D_IN_top),
    .EN_top(D_EN_top),
    .OUT_top(D_OUT_top),
    .ConfigBits(ConfigBits[12-1:9])
);

W_IO4_switch_matrix Inst_W_IO4_switch_matrix (
    .S_GBUF_FEED_END0(S_GBUF_FEED_END[0]),
    .S_GBUF_FEED_END1(S_GBUF_FEED_END[1]),
    .S_GBUF_FEED_END2(S_GBUF_FEED_END[2]),
    .S_GBUF_FEED_END3(S_GBUF_FEED_END[3]),
    .N_GBUF_END0(N_GBUF_END[0]),
    .N_GBUF_END1(N_GBUF_END[1]),
    .N_GBUF_END2(N_GBUF_END[2]),
    .N_GBUF_END3(N_GBUF_END[3]),
    .W1END0(W1END[0]),
    .W1END1(W1END[1]),
    .W1END2(W1END[2]),
    .W1END3(W1END[3]),
    .W1END4(W1END[4]),
    .W1END5(W1END[5]),
    .W1END6(W1END[6]),
    .W1END7(W1END[7]),
    .W2MID0(W2MID[0]),
    .W2MID1(W2MID[1]),
    .W2MID2(W2MID[2]),
    .W2MID3(W2MID[3]),
    .W2MID4(W2MID[4]),
    .W2MID5(W2MID[5]),
    .W2MID6(W2MID[6]),
    .W2MID7(W2MID[7]),
    .W2END0(W2END[0]),
    .W2END1(W2END[1]),
    .W2END2(W2END[2]),
    .W2END3(W2END[3]),
    .W2END4(W2END[4]),
    .W2END5(W2END[5]),
    .W2END6(W2END[6]),
    .W2END7(W2END[7]),
    .A_OUT(A_OUT),
    .B_OUT(B_OUT),
    .C_OUT(C_OUT),
    .D_OUT(D_OUT),
    .S_GBUF_FEED_BEG0(S_GBUF_FEED_BEG[0]),
    .S_GBUF_FEED_BEG1(S_GBUF_FEED_BEG[1]),
    .S_GBUF_FEED_BEG2(S_GBUF_FEED_BEG[2]),
    .S_GBUF_FEED_BEG3(S_GBUF_FEED_BEG[3]),
    .N_GBUF_BEG0(N_GBUF_BEG[0]),
    .N_GBUF_BEG1(N_GBUF_BEG[1]),
    .N_GBUF_BEG2(N_GBUF_BEG[2]),
    .N_GBUF_BEG3(N_GBUF_BEG[3]),
    .E1BEG0(E1BEG[0]),
    .E1BEG1(E1BEG[1]),
    .E1BEG2(E1BEG[2]),
    .E1BEG3(E1BEG[3]),
    .E1BEG4(E1BEG[4]),
    .E1BEG5(E1BEG[5]),
    .E1BEG6(E1BEG[6]),
    .E1BEG7(E1BEG[7]),
    .E2BEG0(E2BEG[0]),
    .E2BEG1(E2BEG[1]),
    .E2BEG2(E2BEG[2]),
    .E2BEG3(E2BEG[3]),
    .E2BEG4(E2BEG[4]),
    .E2BEG5(E2BEG[5]),
    .E2BEG6(E2BEG[6]),
    .E2BEG7(E2BEG[7]),
    .E2BEGb0(E2BEGb[0]),
    .E2BEGb1(E2BEGb[1]),
    .E2BEGb2(E2BEGb[2]),
    .E2BEGb3(E2BEGb[3]),
    .E2BEGb4(E2BEGb[4]),
    .E2BEGb5(E2BEGb[5]),
    .E2BEGb6(E2BEGb[6]),
    .E2BEGb7(E2BEGb[7]),
    .A_CLK(A_CLK),
    .A_IN(A_IN),
    .A_EN(A_EN),
    .B_CLK(B_CLK),
    .B_IN(B_IN),
    .B_EN(B_EN),
    .C_CLK(C_CLK),
    .C_IN(C_IN),
    .C_EN(C_EN),
    .D_CLK(D_CLK),
    .D_IN(D_IN),
    .D_EN(D_EN),
    .ConfigBits(ConfigBits[104-1:12]),
    .ConfigBits_N(ConfigBits_N[104-1:12])
);

endmodule
module W_IO_ConfigMem
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=68
    )
    (
        input  [FrameBitsPerRow - 1:0] FrameData,
        input  [MaxFramesPerCol - 1:0] FrameStrobe,
        output  [NoConfigBits - 1:0] ConfigBits,
        output  [NoConfigBits - 1:0] ConfigBits_N
    );

`ifdef EMULATION
assign ConfigBits[67] = Emulate_Bitstream[31];
assign ConfigBits[66] = Emulate_Bitstream[30];
assign ConfigBits[65] = Emulate_Bitstream[29];
assign ConfigBits[64] = Emulate_Bitstream[28];
assign ConfigBits[63] = Emulate_Bitstream[27];
assign ConfigBits[62] = Emulate_Bitstream[26];
assign ConfigBits[61] = Emulate_Bitstream[25];
assign ConfigBits[60] = Emulate_Bitstream[24];
assign ConfigBits[59] = Emulate_Bitstream[23];
assign ConfigBits[58] = Emulate_Bitstream[22];
assign ConfigBits[57] = Emulate_Bitstream[21];
assign ConfigBits[56] = Emulate_Bitstream[20];
assign ConfigBits[55] = Emulate_Bitstream[19];
assign ConfigBits[54] = Emulate_Bitstream[18];
assign ConfigBits[53] = Emulate_Bitstream[17];
assign ConfigBits[52] = Emulate_Bitstream[16];
assign ConfigBits[51] = Emulate_Bitstream[15];
assign ConfigBits[50] = Emulate_Bitstream[14];
assign ConfigBits[49] = Emulate_Bitstream[13];
assign ConfigBits[48] = Emulate_Bitstream[12];
assign ConfigBits[47] = Emulate_Bitstream[11];
assign ConfigBits[46] = Emulate_Bitstream[10];
assign ConfigBits[45] = Emulate_Bitstream[9];
assign ConfigBits[44] = Emulate_Bitstream[8];
assign ConfigBits[43] = Emulate_Bitstream[7];
assign ConfigBits[42] = Emulate_Bitstream[6];
assign ConfigBits[41] = Emulate_Bitstream[5];
assign ConfigBits[40] = Emulate_Bitstream[4];
assign ConfigBits[39] = Emulate_Bitstream[3];
assign ConfigBits[38] = Emulate_Bitstream[2];
assign ConfigBits[37] = Emulate_Bitstream[1];
assign ConfigBits[36] = Emulate_Bitstream[0];
assign ConfigBits[35] = Emulate_Bitstream[63];
assign ConfigBits[34] = Emulate_Bitstream[62];
assign ConfigBits[33] = Emulate_Bitstream[61];
assign ConfigBits[32] = Emulate_Bitstream[60];
assign ConfigBits[31] = Emulate_Bitstream[59];
assign ConfigBits[30] = Emulate_Bitstream[58];
assign ConfigBits[29] = Emulate_Bitstream[57];
assign ConfigBits[28] = Emulate_Bitstream[56];
assign ConfigBits[27] = Emulate_Bitstream[55];
assign ConfigBits[26] = Emulate_Bitstream[54];
assign ConfigBits[25] = Emulate_Bitstream[53];
assign ConfigBits[24] = Emulate_Bitstream[52];
assign ConfigBits[23] = Emulate_Bitstream[51];
assign ConfigBits[22] = Emulate_Bitstream[50];
assign ConfigBits[21] = Emulate_Bitstream[49];
assign ConfigBits[20] = Emulate_Bitstream[48];
assign ConfigBits[19] = Emulate_Bitstream[47];
assign ConfigBits[18] = Emulate_Bitstream[46];
assign ConfigBits[17] = Emulate_Bitstream[45];
assign ConfigBits[16] = Emulate_Bitstream[44];
assign ConfigBits[15] = Emulate_Bitstream[43];
assign ConfigBits[14] = Emulate_Bitstream[42];
assign ConfigBits[13] = Emulate_Bitstream[41];
assign ConfigBits[12] = Emulate_Bitstream[40];
assign ConfigBits[11] = Emulate_Bitstream[39];
assign ConfigBits[10] = Emulate_Bitstream[38];
assign ConfigBits[9] = Emulate_Bitstream[37];
assign ConfigBits[8] = Emulate_Bitstream[36];
assign ConfigBits[7] = Emulate_Bitstream[35];
assign ConfigBits[6] = Emulate_Bitstream[34];
assign ConfigBits[5] = Emulate_Bitstream[33];
assign ConfigBits[4] = Emulate_Bitstream[32];
assign ConfigBits[3] = Emulate_Bitstream[95];
assign ConfigBits[2] = Emulate_Bitstream[94];
assign ConfigBits[1] = Emulate_Bitstream[93];
assign ConfigBits[0] = Emulate_Bitstream[92];
`else

 //instantiate frame latches
config_latch Inst_frame0_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[67]),
    .QN(ConfigBits_N[67])
);

config_latch Inst_frame0_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[66]),
    .QN(ConfigBits_N[66])
);

config_latch Inst_frame0_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[65]),
    .QN(ConfigBits_N[65])
);

config_latch Inst_frame0_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[64]),
    .QN(ConfigBits_N[64])
);

config_latch Inst_frame0_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[63]),
    .QN(ConfigBits_N[63])
);

config_latch Inst_frame0_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[62]),
    .QN(ConfigBits_N[62])
);

config_latch Inst_frame0_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[61]),
    .QN(ConfigBits_N[61])
);

config_latch Inst_frame0_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[60]),
    .QN(ConfigBits_N[60])
);

config_latch Inst_frame0_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[59]),
    .QN(ConfigBits_N[59])
);

config_latch Inst_frame0_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[58]),
    .QN(ConfigBits_N[58])
);

config_latch Inst_frame0_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[57]),
    .QN(ConfigBits_N[57])
);

config_latch Inst_frame0_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[56]),
    .QN(ConfigBits_N[56])
);

config_latch Inst_frame0_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[55]),
    .QN(ConfigBits_N[55])
);

config_latch Inst_frame0_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[54]),
    .QN(ConfigBits_N[54])
);

config_latch Inst_frame0_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[53]),
    .QN(ConfigBits_N[53])
);

config_latch Inst_frame0_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[52]),
    .QN(ConfigBits_N[52])
);

config_latch Inst_frame0_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[51]),
    .QN(ConfigBits_N[51])
);

config_latch Inst_frame0_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[50]),
    .QN(ConfigBits_N[50])
);

config_latch Inst_frame0_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[49]),
    .QN(ConfigBits_N[49])
);

config_latch Inst_frame0_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[48]),
    .QN(ConfigBits_N[48])
);

config_latch Inst_frame0_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[47]),
    .QN(ConfigBits_N[47])
);

config_latch Inst_frame0_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[46]),
    .QN(ConfigBits_N[46])
);

config_latch Inst_frame0_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[45]),
    .QN(ConfigBits_N[45])
);

config_latch Inst_frame0_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[44]),
    .QN(ConfigBits_N[44])
);

config_latch Inst_frame0_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[43]),
    .QN(ConfigBits_N[43])
);

config_latch Inst_frame0_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[42]),
    .QN(ConfigBits_N[42])
);

config_latch Inst_frame0_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[41]),
    .QN(ConfigBits_N[41])
);

config_latch Inst_frame0_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[40]),
    .QN(ConfigBits_N[40])
);

config_latch Inst_frame0_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[39]),
    .QN(ConfigBits_N[39])
);

config_latch Inst_frame0_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[38]),
    .QN(ConfigBits_N[38])
);

config_latch Inst_frame0_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[37]),
    .QN(ConfigBits_N[37])
);

config_latch Inst_frame0_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[0]),
    .Q(ConfigBits[36]),
    .QN(ConfigBits_N[36])
);

config_latch Inst_frame1_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[35]),
    .QN(ConfigBits_N[35])
);

config_latch Inst_frame1_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[34]),
    .QN(ConfigBits_N[34])
);

config_latch Inst_frame1_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[33]),
    .QN(ConfigBits_N[33])
);

config_latch Inst_frame1_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[32]),
    .QN(ConfigBits_N[32])
);

config_latch Inst_frame1_bit27 (
    .D(FrameData[27]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[31]),
    .QN(ConfigBits_N[31])
);

config_latch Inst_frame1_bit26 (
    .D(FrameData[26]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[30]),
    .QN(ConfigBits_N[30])
);

config_latch Inst_frame1_bit25 (
    .D(FrameData[25]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[29]),
    .QN(ConfigBits_N[29])
);

config_latch Inst_frame1_bit24 (
    .D(FrameData[24]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[28]),
    .QN(ConfigBits_N[28])
);

config_latch Inst_frame1_bit23 (
    .D(FrameData[23]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[27]),
    .QN(ConfigBits_N[27])
);

config_latch Inst_frame1_bit22 (
    .D(FrameData[22]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[26]),
    .QN(ConfigBits_N[26])
);

config_latch Inst_frame1_bit21 (
    .D(FrameData[21]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[25]),
    .QN(ConfigBits_N[25])
);

config_latch Inst_frame1_bit20 (
    .D(FrameData[20]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[24]),
    .QN(ConfigBits_N[24])
);

config_latch Inst_frame1_bit19 (
    .D(FrameData[19]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[23]),
    .QN(ConfigBits_N[23])
);

config_latch Inst_frame1_bit18 (
    .D(FrameData[18]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[22]),
    .QN(ConfigBits_N[22])
);

config_latch Inst_frame1_bit17 (
    .D(FrameData[17]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[21]),
    .QN(ConfigBits_N[21])
);

config_latch Inst_frame1_bit16 (
    .D(FrameData[16]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[20]),
    .QN(ConfigBits_N[20])
);

config_latch Inst_frame1_bit15 (
    .D(FrameData[15]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[19]),
    .QN(ConfigBits_N[19])
);

config_latch Inst_frame1_bit14 (
    .D(FrameData[14]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[18]),
    .QN(ConfigBits_N[18])
);

config_latch Inst_frame1_bit13 (
    .D(FrameData[13]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[17]),
    .QN(ConfigBits_N[17])
);

config_latch Inst_frame1_bit12 (
    .D(FrameData[12]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[16]),
    .QN(ConfigBits_N[16])
);

config_latch Inst_frame1_bit11 (
    .D(FrameData[11]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[15]),
    .QN(ConfigBits_N[15])
);

config_latch Inst_frame1_bit10 (
    .D(FrameData[10]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[14]),
    .QN(ConfigBits_N[14])
);

config_latch Inst_frame1_bit9 (
    .D(FrameData[9]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[13]),
    .QN(ConfigBits_N[13])
);

config_latch Inst_frame1_bit8 (
    .D(FrameData[8]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[12]),
    .QN(ConfigBits_N[12])
);

config_latch Inst_frame1_bit7 (
    .D(FrameData[7]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[11]),
    .QN(ConfigBits_N[11])
);

config_latch Inst_frame1_bit6 (
    .D(FrameData[6]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[10]),
    .QN(ConfigBits_N[10])
);

config_latch Inst_frame1_bit5 (
    .D(FrameData[5]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[9]),
    .QN(ConfigBits_N[9])
);

config_latch Inst_frame1_bit4 (
    .D(FrameData[4]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[8]),
    .QN(ConfigBits_N[8])
);

config_latch Inst_frame1_bit3 (
    .D(FrameData[3]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[7]),
    .QN(ConfigBits_N[7])
);

config_latch Inst_frame1_bit2 (
    .D(FrameData[2]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[6]),
    .QN(ConfigBits_N[6])
);

config_latch Inst_frame1_bit1 (
    .D(FrameData[1]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[5]),
    .QN(ConfigBits_N[5])
);

config_latch Inst_frame1_bit0 (
    .D(FrameData[0]),
    .E(FrameStrobe[1]),
    .Q(ConfigBits[4]),
    .QN(ConfigBits_N[4])
);

config_latch Inst_frame2_bit31 (
    .D(FrameData[31]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[3]),
    .QN(ConfigBits_N[3])
);

config_latch Inst_frame2_bit30 (
    .D(FrameData[30]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[2]),
    .QN(ConfigBits_N[2])
);

config_latch Inst_frame2_bit29 (
    .D(FrameData[29]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[1]),
    .QN(ConfigBits_N[1])
);

config_latch Inst_frame2_bit28 (
    .D(FrameData[28]),
    .E(FrameStrobe[2]),
    .Q(ConfigBits[0]),
    .QN(ConfigBits_N[0])
);

`endif
endmodule
 // NumberOfConfigBits: 65
module W_IO_switch_matrix
    #(
        parameter NoConfigBits=65
    )
    (
        input  S_GBUF_FEED_END0,
        input  S_GBUF_FEED_END1,
        input  S_GBUF_FEED_END2,
        input  S_GBUF_FEED_END3,
        input  N_GBUF_END0,
        input  N_GBUF_END1,
        input  N_GBUF_END2,
        input  N_GBUF_END3,
        input  W1END0,
        input  W1END1,
        input  W1END2,
        input  W1END3,
        input  W1END4,
        input  W1END5,
        input  W1END6,
        input  W1END7,
        input  W2MID0,
        input  W2MID1,
        input  W2MID2,
        input  W2MID3,
        input  W2MID4,
        input  W2MID5,
        input  W2MID6,
        input  W2MID7,
        input  W2END0,
        input  W2END1,
        input  W2END2,
        input  W2END3,
        input  W2END4,
        input  W2END5,
        input  W2END6,
        input  W2END7,
        input  A_OUT,
        output  S_GBUF_FEED_BEG0,
        output  S_GBUF_FEED_BEG1,
        output  S_GBUF_FEED_BEG2,
        output  S_GBUF_FEED_BEG3,
        output  N_GBUF_BEG0,
        output  N_GBUF_BEG1,
        output  N_GBUF_BEG2,
        output  N_GBUF_BEG3,
        output  E1BEG0,
        output  E1BEG1,
        output  E1BEG2,
        output  E1BEG3,
        output  E1BEG4,
        output  E1BEG5,
        output  E1BEG6,
        output  E1BEG7,
        output  E2BEG0,
        output  E2BEG1,
        output  E2BEG2,
        output  E2BEG3,
        output  E2BEG4,
        output  E2BEG5,
        output  E2BEG6,
        output  E2BEG7,
        output  E2BEGb0,
        output  E2BEGb1,
        output  E2BEGb2,
        output  E2BEGb3,
        output  E2BEGb4,
        output  E2BEGb5,
        output  E2BEGb6,
        output  E2BEGb7,
        output  A_CLK,
        output  A_IN,
        output  A_EN,
 //global
        input  [NoConfigBits-1:0] ConfigBits,
        input  [NoConfigBits-1:0] ConfigBits_N
);
parameter GND0 = 1'b0;
parameter GND = 1'b0;
parameter VCC0 = 1'b1;
parameter VCC = 1'b1;
parameter VDD0 = 1'b1;
parameter VDD = 1'b1;

wire[4-1:0] S_GBUF_FEED_BEG0_input;
wire[4-1:0] S_GBUF_FEED_BEG1_input;
wire[4-1:0] S_GBUF_FEED_BEG2_input;
wire[4-1:0] S_GBUF_FEED_BEG3_input;
wire[4-1:0] E1BEG0_input;
wire[4-1:0] E1BEG1_input;
wire[4-1:0] E1BEG2_input;
wire[4-1:0] E1BEG3_input;
wire[4-1:0] E1BEG4_input;
wire[4-1:0] E1BEG5_input;
wire[4-1:0] E1BEG6_input;
wire[4-1:0] E1BEG7_input;
wire[4-1:0] E2BEG0_input;
wire[4-1:0] E2BEG1_input;
wire[4-1:0] E2BEG2_input;
wire[4-1:0] E2BEG3_input;
wire[4-1:0] E2BEG4_input;
wire[4-1:0] E2BEG5_input;
wire[4-1:0] E2BEG6_input;
wire[4-1:0] E2BEG7_input;
wire[4-1:0] E2BEGb0_input;
wire[4-1:0] E2BEGb1_input;
wire[4-1:0] E2BEGb2_input;
wire[4-1:0] E2BEGb3_input;
wire[4-1:0] E2BEGb4_input;
wire[4-1:0] E2BEGb5_input;
wire[4-1:0] E2BEGb6_input;
wire[4-1:0] E2BEGb7_input;
wire[4-1:0] A_CLK_input;
wire[16-1:0] A_IN_input;
wire[8-1:0] A_EN_input;
 //The configuration bits (if any) are just a long shift register
 //This shift register is padded to an even number of flops/latches
 //switch matrix multiplexer S_GBUF_FEED_BEG0 MUX-4
assign S_GBUF_FEED_BEG0_input = {A_OUT,W2END7,W1END1,S_GBUF_FEED_END0};
cus_mux41 inst_cus_mux41_S_GBUF_FEED_BEG0 (
    .A0(S_GBUF_FEED_BEG0_input[0]),
    .A1(S_GBUF_FEED_BEG0_input[1]),
    .A2(S_GBUF_FEED_BEG0_input[2]),
    .A3(S_GBUF_FEED_BEG0_input[3]),
    .S0(ConfigBits[0+0]),
    .S0N(ConfigBits_N[0+0]),
    .S1(ConfigBits[0+1]),
    .S1N(ConfigBits_N[0+1]),
    .X(S_GBUF_FEED_BEG0)
);

 //switch matrix multiplexer S_GBUF_FEED_BEG1 MUX-4
assign S_GBUF_FEED_BEG1_input = {A_OUT,W2END6,W1END2,S_GBUF_FEED_END1};
cus_mux41 inst_cus_mux41_S_GBUF_FEED_BEG1 (
    .A0(S_GBUF_FEED_BEG1_input[0]),
    .A1(S_GBUF_FEED_BEG1_input[1]),
    .A2(S_GBUF_FEED_BEG1_input[2]),
    .A3(S_GBUF_FEED_BEG1_input[3]),
    .S0(ConfigBits[2+0]),
    .S0N(ConfigBits_N[2+0]),
    .S1(ConfigBits[2+1]),
    .S1N(ConfigBits_N[2+1]),
    .X(S_GBUF_FEED_BEG1)
);

 //switch matrix multiplexer S_GBUF_FEED_BEG2 MUX-4
assign S_GBUF_FEED_BEG2_input = {A_OUT,W2END5,W1END3,S_GBUF_FEED_END2};
cus_mux41 inst_cus_mux41_S_GBUF_FEED_BEG2 (
    .A0(S_GBUF_FEED_BEG2_input[0]),
    .A1(S_GBUF_FEED_BEG2_input[1]),
    .A2(S_GBUF_FEED_BEG2_input[2]),
    .A3(S_GBUF_FEED_BEG2_input[3]),
    .S0(ConfigBits[4+0]),
    .S0N(ConfigBits_N[4+0]),
    .S1(ConfigBits[4+1]),
    .S1N(ConfigBits_N[4+1]),
    .X(S_GBUF_FEED_BEG2)
);

 //switch matrix multiplexer S_GBUF_FEED_BEG3 MUX-4
assign S_GBUF_FEED_BEG3_input = {A_OUT,W2END4,W1END0,S_GBUF_FEED_END3};
cus_mux41 inst_cus_mux41_S_GBUF_FEED_BEG3 (
    .A0(S_GBUF_FEED_BEG3_input[0]),
    .A1(S_GBUF_FEED_BEG3_input[1]),
    .A2(S_GBUF_FEED_BEG3_input[2]),
    .A3(S_GBUF_FEED_BEG3_input[3]),
    .S0(ConfigBits[6+0]),
    .S0N(ConfigBits_N[6+0]),
    .S1(ConfigBits[6+1]),
    .S1N(ConfigBits_N[6+1]),
    .X(S_GBUF_FEED_BEG3)
);

 //switch matrix multiplexer N_GBUF_BEG0 MUX-1
assign N_GBUF_BEG0 = N_GBUF_END0;

 //switch matrix multiplexer N_GBUF_BEG1 MUX-1
assign N_GBUF_BEG1 = N_GBUF_END1;

 //switch matrix multiplexer N_GBUF_BEG2 MUX-1
assign N_GBUF_BEG2 = N_GBUF_END2;

 //switch matrix multiplexer N_GBUF_BEG3 MUX-1
assign N_GBUF_BEG3 = N_GBUF_END3;

 //switch matrix multiplexer E1BEG0 MUX-4
assign E1BEG0_input = {A_OUT,W2END7,W2MID7,W1END7};
cus_mux41 inst_cus_mux41_E1BEG0 (
    .A0(E1BEG0_input[0]),
    .A1(E1BEG0_input[1]),
    .A2(E1BEG0_input[2]),
    .A3(E1BEG0_input[3]),
    .S0(ConfigBits[8+0]),
    .S0N(ConfigBits_N[8+0]),
    .S1(ConfigBits[8+1]),
    .S1N(ConfigBits_N[8+1]),
    .X(E1BEG0)
);

 //switch matrix multiplexer E1BEG1 MUX-4
assign E1BEG1_input = {A_OUT,W2END6,W2MID6,W1END6};
cus_mux41 inst_cus_mux41_E1BEG1 (
    .A0(E1BEG1_input[0]),
    .A1(E1BEG1_input[1]),
    .A2(E1BEG1_input[2]),
    .A3(E1BEG1_input[3]),
    .S0(ConfigBits[10+0]),
    .S0N(ConfigBits_N[10+0]),
    .S1(ConfigBits[10+1]),
    .S1N(ConfigBits_N[10+1]),
    .X(E1BEG1)
);

 //switch matrix multiplexer E1BEG2 MUX-4
assign E1BEG2_input = {A_OUT,W2END5,W2MID5,W1END5};
cus_mux41 inst_cus_mux41_E1BEG2 (
    .A0(E1BEG2_input[0]),
    .A1(E1BEG2_input[1]),
    .A2(E1BEG2_input[2]),
    .A3(E1BEG2_input[3]),
    .S0(ConfigBits[12+0]),
    .S0N(ConfigBits_N[12+0]),
    .S1(ConfigBits[12+1]),
    .S1N(ConfigBits_N[12+1]),
    .X(E1BEG2)
);

 //switch matrix multiplexer E1BEG3 MUX-4
assign E1BEG3_input = {A_OUT,W2END4,W2MID4,W1END4};
cus_mux41 inst_cus_mux41_E1BEG3 (
    .A0(E1BEG3_input[0]),
    .A1(E1BEG3_input[1]),
    .A2(E1BEG3_input[2]),
    .A3(E1BEG3_input[3]),
    .S0(ConfigBits[14+0]),
    .S0N(ConfigBits_N[14+0]),
    .S1(ConfigBits[14+1]),
    .S1N(ConfigBits_N[14+1]),
    .X(E1BEG3)
);

 //switch matrix multiplexer E1BEG4 MUX-4
assign E1BEG4_input = {A_OUT,W2END3,W2MID3,W1END3};
cus_mux41 inst_cus_mux41_E1BEG4 (
    .A0(E1BEG4_input[0]),
    .A1(E1BEG4_input[1]),
    .A2(E1BEG4_input[2]),
    .A3(E1BEG4_input[3]),
    .S0(ConfigBits[16+0]),
    .S0N(ConfigBits_N[16+0]),
    .S1(ConfigBits[16+1]),
    .S1N(ConfigBits_N[16+1]),
    .X(E1BEG4)
);

 //switch matrix multiplexer E1BEG5 MUX-4
assign E1BEG5_input = {A_OUT,W2END2,W2MID2,W1END2};
cus_mux41 inst_cus_mux41_E1BEG5 (
    .A0(E1BEG5_input[0]),
    .A1(E1BEG5_input[1]),
    .A2(E1BEG5_input[2]),
    .A3(E1BEG5_input[3]),
    .S0(ConfigBits[18+0]),
    .S0N(ConfigBits_N[18+0]),
    .S1(ConfigBits[18+1]),
    .S1N(ConfigBits_N[18+1]),
    .X(E1BEG5)
);

 //switch matrix multiplexer E1BEG6 MUX-4
assign E1BEG6_input = {A_OUT,W2END1,W2MID1,W1END1};
cus_mux41 inst_cus_mux41_E1BEG6 (
    .A0(E1BEG6_input[0]),
    .A1(E1BEG6_input[1]),
    .A2(E1BEG6_input[2]),
    .A3(E1BEG6_input[3]),
    .S0(ConfigBits[20+0]),
    .S0N(ConfigBits_N[20+0]),
    .S1(ConfigBits[20+1]),
    .S1N(ConfigBits_N[20+1]),
    .X(E1BEG6)
);

 //switch matrix multiplexer E1BEG7 MUX-4
assign E1BEG7_input = {A_OUT,W2END0,W2MID0,W1END0};
cus_mux41 inst_cus_mux41_E1BEG7 (
    .A0(E1BEG7_input[0]),
    .A1(E1BEG7_input[1]),
    .A2(E1BEG7_input[2]),
    .A3(E1BEG7_input[3]),
    .S0(ConfigBits[22+0]),
    .S0N(ConfigBits_N[22+0]),
    .S1(ConfigBits[22+1]),
    .S1N(ConfigBits_N[22+1]),
    .X(E1BEG7)
);

 //switch matrix multiplexer E2BEG0 MUX-4
assign E2BEG0_input = {A_OUT,W2END7,W2MID7,W1END7};
cus_mux41 inst_cus_mux41_E2BEG0 (
    .A0(E2BEG0_input[0]),
    .A1(E2BEG0_input[1]),
    .A2(E2BEG0_input[2]),
    .A3(E2BEG0_input[3]),
    .S0(ConfigBits[24+0]),
    .S0N(ConfigBits_N[24+0]),
    .S1(ConfigBits[24+1]),
    .S1N(ConfigBits_N[24+1]),
    .X(E2BEG0)
);

 //switch matrix multiplexer E2BEG1 MUX-4
assign E2BEG1_input = {A_OUT,W2END6,W2MID6,W1END6};
cus_mux41 inst_cus_mux41_E2BEG1 (
    .A0(E2BEG1_input[0]),
    .A1(E2BEG1_input[1]),
    .A2(E2BEG1_input[2]),
    .A3(E2BEG1_input[3]),
    .S0(ConfigBits[26+0]),
    .S0N(ConfigBits_N[26+0]),
    .S1(ConfigBits[26+1]),
    .S1N(ConfigBits_N[26+1]),
    .X(E2BEG1)
);

 //switch matrix multiplexer E2BEG2 MUX-4
assign E2BEG2_input = {A_OUT,W2END5,W2MID5,W1END5};
cus_mux41 inst_cus_mux41_E2BEG2 (
    .A0(E2BEG2_input[0]),
    .A1(E2BEG2_input[1]),
    .A2(E2BEG2_input[2]),
    .A3(E2BEG2_input[3]),
    .S0(ConfigBits[28+0]),
    .S0N(ConfigBits_N[28+0]),
    .S1(ConfigBits[28+1]),
    .S1N(ConfigBits_N[28+1]),
    .X(E2BEG2)
);

 //switch matrix multiplexer E2BEG3 MUX-4
assign E2BEG3_input = {A_OUT,W2END4,W2MID4,W1END4};
cus_mux41 inst_cus_mux41_E2BEG3 (
    .A0(E2BEG3_input[0]),
    .A1(E2BEG3_input[1]),
    .A2(E2BEG3_input[2]),
    .A3(E2BEG3_input[3]),
    .S0(ConfigBits[30+0]),
    .S0N(ConfigBits_N[30+0]),
    .S1(ConfigBits[30+1]),
    .S1N(ConfigBits_N[30+1]),
    .X(E2BEG3)
);

 //switch matrix multiplexer E2BEG4 MUX-4
assign E2BEG4_input = {A_OUT,W2END3,W2MID3,W1END3};
cus_mux41 inst_cus_mux41_E2BEG4 (
    .A0(E2BEG4_input[0]),
    .A1(E2BEG4_input[1]),
    .A2(E2BEG4_input[2]),
    .A3(E2BEG4_input[3]),
    .S0(ConfigBits[32+0]),
    .S0N(ConfigBits_N[32+0]),
    .S1(ConfigBits[32+1]),
    .S1N(ConfigBits_N[32+1]),
    .X(E2BEG4)
);

 //switch matrix multiplexer E2BEG5 MUX-4
assign E2BEG5_input = {A_OUT,W2END2,W2MID2,W1END2};
cus_mux41 inst_cus_mux41_E2BEG5 (
    .A0(E2BEG5_input[0]),
    .A1(E2BEG5_input[1]),
    .A2(E2BEG5_input[2]),
    .A3(E2BEG5_input[3]),
    .S0(ConfigBits[34+0]),
    .S0N(ConfigBits_N[34+0]),
    .S1(ConfigBits[34+1]),
    .S1N(ConfigBits_N[34+1]),
    .X(E2BEG5)
);

 //switch matrix multiplexer E2BEG6 MUX-4
assign E2BEG6_input = {A_OUT,W2END1,W2MID1,W1END1};
cus_mux41 inst_cus_mux41_E2BEG6 (
    .A0(E2BEG6_input[0]),
    .A1(E2BEG6_input[1]),
    .A2(E2BEG6_input[2]),
    .A3(E2BEG6_input[3]),
    .S0(ConfigBits[36+0]),
    .S0N(ConfigBits_N[36+0]),
    .S1(ConfigBits[36+1]),
    .S1N(ConfigBits_N[36+1]),
    .X(E2BEG6)
);

 //switch matrix multiplexer E2BEG7 MUX-4
assign E2BEG7_input = {A_OUT,W2END0,W2MID0,W1END0};
cus_mux41 inst_cus_mux41_E2BEG7 (
    .A0(E2BEG7_input[0]),
    .A1(E2BEG7_input[1]),
    .A2(E2BEG7_input[2]),
    .A3(E2BEG7_input[3]),
    .S0(ConfigBits[38+0]),
    .S0N(ConfigBits_N[38+0]),
    .S1(ConfigBits[38+1]),
    .S1N(ConfigBits_N[38+1]),
    .X(E2BEG7)
);

 //switch matrix multiplexer E2BEGb0 MUX-4
assign E2BEGb0_input = {A_OUT,W2END7,W2MID7,W1END7};
cus_mux41 inst_cus_mux41_E2BEGb0 (
    .A0(E2BEGb0_input[0]),
    .A1(E2BEGb0_input[1]),
    .A2(E2BEGb0_input[2]),
    .A3(E2BEGb0_input[3]),
    .S0(ConfigBits[40+0]),
    .S0N(ConfigBits_N[40+0]),
    .S1(ConfigBits[40+1]),
    .S1N(ConfigBits_N[40+1]),
    .X(E2BEGb0)
);

 //switch matrix multiplexer E2BEGb1 MUX-4
assign E2BEGb1_input = {A_OUT,W2END6,W2MID6,W1END6};
cus_mux41 inst_cus_mux41_E2BEGb1 (
    .A0(E2BEGb1_input[0]),
    .A1(E2BEGb1_input[1]),
    .A2(E2BEGb1_input[2]),
    .A3(E2BEGb1_input[3]),
    .S0(ConfigBits[42+0]),
    .S0N(ConfigBits_N[42+0]),
    .S1(ConfigBits[42+1]),
    .S1N(ConfigBits_N[42+1]),
    .X(E2BEGb1)
);

 //switch matrix multiplexer E2BEGb2 MUX-4
assign E2BEGb2_input = {A_OUT,W2END5,W2MID5,W1END5};
cus_mux41 inst_cus_mux41_E2BEGb2 (
    .A0(E2BEGb2_input[0]),
    .A1(E2BEGb2_input[1]),
    .A2(E2BEGb2_input[2]),
    .A3(E2BEGb2_input[3]),
    .S0(ConfigBits[44+0]),
    .S0N(ConfigBits_N[44+0]),
    .S1(ConfigBits[44+1]),
    .S1N(ConfigBits_N[44+1]),
    .X(E2BEGb2)
);

 //switch matrix multiplexer E2BEGb3 MUX-4
assign E2BEGb3_input = {A_OUT,W2END4,W2MID4,W1END4};
cus_mux41 inst_cus_mux41_E2BEGb3 (
    .A0(E2BEGb3_input[0]),
    .A1(E2BEGb3_input[1]),
    .A2(E2BEGb3_input[2]),
    .A3(E2BEGb3_input[3]),
    .S0(ConfigBits[46+0]),
    .S0N(ConfigBits_N[46+0]),
    .S1(ConfigBits[46+1]),
    .S1N(ConfigBits_N[46+1]),
    .X(E2BEGb3)
);

 //switch matrix multiplexer E2BEGb4 MUX-4
assign E2BEGb4_input = {A_OUT,W2END3,W2MID3,W1END3};
cus_mux41 inst_cus_mux41_E2BEGb4 (
    .A0(E2BEGb4_input[0]),
    .A1(E2BEGb4_input[1]),
    .A2(E2BEGb4_input[2]),
    .A3(E2BEGb4_input[3]),
    .S0(ConfigBits[48+0]),
    .S0N(ConfigBits_N[48+0]),
    .S1(ConfigBits[48+1]),
    .S1N(ConfigBits_N[48+1]),
    .X(E2BEGb4)
);

 //switch matrix multiplexer E2BEGb5 MUX-4
assign E2BEGb5_input = {A_OUT,W2END2,W2MID2,W1END2};
cus_mux41 inst_cus_mux41_E2BEGb5 (
    .A0(E2BEGb5_input[0]),
    .A1(E2BEGb5_input[1]),
    .A2(E2BEGb5_input[2]),
    .A3(E2BEGb5_input[3]),
    .S0(ConfigBits[50+0]),
    .S0N(ConfigBits_N[50+0]),
    .S1(ConfigBits[50+1]),
    .S1N(ConfigBits_N[50+1]),
    .X(E2BEGb5)
);

 //switch matrix multiplexer E2BEGb6 MUX-4
assign E2BEGb6_input = {A_OUT,W2END1,W2MID1,W1END1};
cus_mux41 inst_cus_mux41_E2BEGb6 (
    .A0(E2BEGb6_input[0]),
    .A1(E2BEGb6_input[1]),
    .A2(E2BEGb6_input[2]),
    .A3(E2BEGb6_input[3]),
    .S0(ConfigBits[52+0]),
    .S0N(ConfigBits_N[52+0]),
    .S1(ConfigBits[52+1]),
    .S1N(ConfigBits_N[52+1]),
    .X(E2BEGb6)
);

 //switch matrix multiplexer E2BEGb7 MUX-4
assign E2BEGb7_input = {A_OUT,W2END0,W2MID0,W1END0};
cus_mux41 inst_cus_mux41_E2BEGb7 (
    .A0(E2BEGb7_input[0]),
    .A1(E2BEGb7_input[1]),
    .A2(E2BEGb7_input[2]),
    .A3(E2BEGb7_input[3]),
    .S0(ConfigBits[54+0]),
    .S0N(ConfigBits_N[54+0]),
    .S1(ConfigBits[54+1]),
    .S1N(ConfigBits_N[54+1]),
    .X(E2BEGb7)
);

 //switch matrix multiplexer A_CLK MUX-4
assign A_CLK_input = {N_GBUF_END3,N_GBUF_END2,N_GBUF_END1,N_GBUF_END0};
cus_mux41 inst_cus_mux41_A_CLK (
    .A0(A_CLK_input[0]),
    .A1(A_CLK_input[1]),
    .A2(A_CLK_input[2]),
    .A3(A_CLK_input[3]),
    .S0(ConfigBits[56+0]),
    .S0N(ConfigBits_N[56+0]),
    .S1(ConfigBits[56+1]),
    .S1N(ConfigBits_N[56+1]),
    .X(A_CLK)
);

 //switch matrix multiplexer A_IN MUX-16
assign A_IN_input = {VCC0,GND0,W2END7,W2END6,W2END5,W2MID2,W2MID1,W2MID0,W1END7,W1END6,W1END5,W1END4,W1END3,W1END2,W1END1,W1END0};
cus_mux161 inst_cus_mux161_A_IN (
    .A0(A_IN_input[0]),
    .A1(A_IN_input[1]),
    .A2(A_IN_input[2]),
    .A3(A_IN_input[3]),
    .A4(A_IN_input[4]),
    .A5(A_IN_input[5]),
    .A6(A_IN_input[6]),
    .A7(A_IN_input[7]),
    .A8(A_IN_input[8]),
    .A9(A_IN_input[9]),
    .A10(A_IN_input[10]),
    .A11(A_IN_input[11]),
    .A12(A_IN_input[12]),
    .A13(A_IN_input[13]),
    .A14(A_IN_input[14]),
    .A15(A_IN_input[15]),
    .S0(ConfigBits[58+0]),
    .S0N(ConfigBits_N[58+0]),
    .S1(ConfigBits[58+1]),
    .S1N(ConfigBits_N[58+1]),
    .S2(ConfigBits[58+2]),
    .S2N(ConfigBits_N[58+2]),
    .S3(ConfigBits[58+3]),
    .S3N(ConfigBits_N[58+3]),
    .X(A_IN)
);

 //switch matrix multiplexer A_EN MUX-8
assign A_EN_input = {VCC0,GND0,W2END2,W2END0,W2MID7,W2MID4,W1END7,W1END3};
cus_mux81 inst_cus_mux81_A_EN (
    .A0(A_EN_input[0]),
    .A1(A_EN_input[1]),
    .A2(A_EN_input[2]),
    .A3(A_EN_input[3]),
    .A4(A_EN_input[4]),
    .A5(A_EN_input[5]),
    .A6(A_EN_input[6]),
    .A7(A_EN_input[7]),
    .S0(ConfigBits[62+0]),
    .S0N(ConfigBits_N[62+0]),
    .S1(ConfigBits[62+1]),
    .S1N(ConfigBits_N[62+1]),
    .S2(ConfigBits[62+2]),
    .S2N(ConfigBits_N[62+2]),
    .X(A_EN)
);

endmodule
module W_IO
    #(
`ifdef EMULATION
        parameter [639:0] Emulate_Bitstream=640'b0,
`endif
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32,
        parameter NoConfigBits=68
    )
    (
 //N
        input  [3:0] S_GBUF_FEED_END,        //Port(Name=S_GBUF_FEED_END,IO=INPUT,XOffset=0,YOffset=1,WireCount=4,Side=N)
        output  [3:0] N_GBUF_BEG,        //Port(Name=N_GBUF_BEG,IO=OUTPUT,XOffset=0,YOffset=-1,WireCount=4,Side=N)
 //E
        output  [7:0] E1BEG,        //Port(Name=E1BEG,IO=OUTPUT,XOffset=1,YOffset=0,WireCount=8,Side=E)
        output  [7:0] E2BEG,        //Port(Name=E2BEG,IO=OUTPUT,XOffset=1,YOffset=0,WireCount=8,Side=E)
        output  [7:0] E2BEGb,        //Port(Name=E2BEGb,IO=OUTPUT,XOffset=1,YOffset=0,WireCount=8,Side=E)
        input  [7:0] W1END,        //Port(Name=W1END,IO=INPUT,XOffset=-1,YOffset=0,WireCount=8,Side=E)
        input  [7:0] W2MID,        //Port(Name=W2MID,IO=INPUT,XOffset=-1,YOffset=0,WireCount=8,Side=E)
        input  [7:0] W2END,        //Port(Name=W2END,IO=INPUT,XOffset=-1,YOffset=0,WireCount=8,Side=E)
 //S
        output  [3:0] S_GBUF_FEED_BEG,        //Port(Name=S_GBUF_FEED_BEG,IO=OUTPUT,XOffset=0,YOffset=1,WireCount=4,Side=S)
        input  [3:0] N_GBUF_END,        //Port(Name=N_GBUF_END,IO=INPUT,XOffset=0,YOffset=-1,WireCount=4,Side=S)
        input  A_OUT_top,
        output  A_IN_top,
        output  A_EN_top,
    //Tile IO ports from BELs
        input  [FrameBitsPerRow-1:0] FrameData, //CONFIG_PORT
        output  [FrameBitsPerRow-1:0] FrameData_O,
        input  [MaxFramesPerCol-1:0] FrameStrobe, //CONFIG_PORT
        output  [MaxFramesPerCol-1:0] FrameStrobe_O
    //global
);
 //signal declarations
 //BEL ports (e.g., slices)
wire A_CLK;
wire A_IN;
wire A_EN;
wire A_OUT;
 //Jump wires
 //internal configuration data signal to daisy-chain all BELs (if any and in the order they are listed in the fabric.csv)
wire[NoConfigBits-1:0] ConfigBits;
wire[NoConfigBits-1:0] ConfigBits_N;

 //Connection for outgoing wires
wire[FrameBitsPerRow-1:0] FrameData_i;
wire[FrameBitsPerRow-1:0] FrameData_O_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_i;
wire[MaxFramesPerCol-1:0] FrameStrobe_O_i;

assign FrameData_O_i = FrameData_i;

my_buf data_inbuf_0 (
    .A(FrameData[0]),
    .X(FrameData_i[0])
);

my_buf data_inbuf_1 (
    .A(FrameData[1]),
    .X(FrameData_i[1])
);

my_buf data_inbuf_2 (
    .A(FrameData[2]),
    .X(FrameData_i[2])
);

my_buf data_inbuf_3 (
    .A(FrameData[3]),
    .X(FrameData_i[3])
);

my_buf data_inbuf_4 (
    .A(FrameData[4]),
    .X(FrameData_i[4])
);

my_buf data_inbuf_5 (
    .A(FrameData[5]),
    .X(FrameData_i[5])
);

my_buf data_inbuf_6 (
    .A(FrameData[6]),
    .X(FrameData_i[6])
);

my_buf data_inbuf_7 (
    .A(FrameData[7]),
    .X(FrameData_i[7])
);

my_buf data_inbuf_8 (
    .A(FrameData[8]),
    .X(FrameData_i[8])
);

my_buf data_inbuf_9 (
    .A(FrameData[9]),
    .X(FrameData_i[9])
);

my_buf data_inbuf_10 (
    .A(FrameData[10]),
    .X(FrameData_i[10])
);

my_buf data_inbuf_11 (
    .A(FrameData[11]),
    .X(FrameData_i[11])
);

my_buf data_inbuf_12 (
    .A(FrameData[12]),
    .X(FrameData_i[12])
);

my_buf data_inbuf_13 (
    .A(FrameData[13]),
    .X(FrameData_i[13])
);

my_buf data_inbuf_14 (
    .A(FrameData[14]),
    .X(FrameData_i[14])
);

my_buf data_inbuf_15 (
    .A(FrameData[15]),
    .X(FrameData_i[15])
);

my_buf data_inbuf_16 (
    .A(FrameData[16]),
    .X(FrameData_i[16])
);

my_buf data_inbuf_17 (
    .A(FrameData[17]),
    .X(FrameData_i[17])
);

my_buf data_inbuf_18 (
    .A(FrameData[18]),
    .X(FrameData_i[18])
);

my_buf data_inbuf_19 (
    .A(FrameData[19]),
    .X(FrameData_i[19])
);

my_buf data_inbuf_20 (
    .A(FrameData[20]),
    .X(FrameData_i[20])
);

my_buf data_inbuf_21 (
    .A(FrameData[21]),
    .X(FrameData_i[21])
);

my_buf data_inbuf_22 (
    .A(FrameData[22]),
    .X(FrameData_i[22])
);

my_buf data_inbuf_23 (
    .A(FrameData[23]),
    .X(FrameData_i[23])
);

my_buf data_inbuf_24 (
    .A(FrameData[24]),
    .X(FrameData_i[24])
);

my_buf data_inbuf_25 (
    .A(FrameData[25]),
    .X(FrameData_i[25])
);

my_buf data_inbuf_26 (
    .A(FrameData[26]),
    .X(FrameData_i[26])
);

my_buf data_inbuf_27 (
    .A(FrameData[27]),
    .X(FrameData_i[27])
);

my_buf data_inbuf_28 (
    .A(FrameData[28]),
    .X(FrameData_i[28])
);

my_buf data_inbuf_29 (
    .A(FrameData[29]),
    .X(FrameData_i[29])
);

my_buf data_inbuf_30 (
    .A(FrameData[30]),
    .X(FrameData_i[30])
);

my_buf data_inbuf_31 (
    .A(FrameData[31]),
    .X(FrameData_i[31])
);

my_buf data_outbuf_0 (
    .A(FrameData_O_i[0]),
    .X(FrameData_O[0])
);

my_buf data_outbuf_1 (
    .A(FrameData_O_i[1]),
    .X(FrameData_O[1])
);

my_buf data_outbuf_2 (
    .A(FrameData_O_i[2]),
    .X(FrameData_O[2])
);

my_buf data_outbuf_3 (
    .A(FrameData_O_i[3]),
    .X(FrameData_O[3])
);

my_buf data_outbuf_4 (
    .A(FrameData_O_i[4]),
    .X(FrameData_O[4])
);

my_buf data_outbuf_5 (
    .A(FrameData_O_i[5]),
    .X(FrameData_O[5])
);

my_buf data_outbuf_6 (
    .A(FrameData_O_i[6]),
    .X(FrameData_O[6])
);

my_buf data_outbuf_7 (
    .A(FrameData_O_i[7]),
    .X(FrameData_O[7])
);

my_buf data_outbuf_8 (
    .A(FrameData_O_i[8]),
    .X(FrameData_O[8])
);

my_buf data_outbuf_9 (
    .A(FrameData_O_i[9]),
    .X(FrameData_O[9])
);

my_buf data_outbuf_10 (
    .A(FrameData_O_i[10]),
    .X(FrameData_O[10])
);

my_buf data_outbuf_11 (
    .A(FrameData_O_i[11]),
    .X(FrameData_O[11])
);

my_buf data_outbuf_12 (
    .A(FrameData_O_i[12]),
    .X(FrameData_O[12])
);

my_buf data_outbuf_13 (
    .A(FrameData_O_i[13]),
    .X(FrameData_O[13])
);

my_buf data_outbuf_14 (
    .A(FrameData_O_i[14]),
    .X(FrameData_O[14])
);

my_buf data_outbuf_15 (
    .A(FrameData_O_i[15]),
    .X(FrameData_O[15])
);

my_buf data_outbuf_16 (
    .A(FrameData_O_i[16]),
    .X(FrameData_O[16])
);

my_buf data_outbuf_17 (
    .A(FrameData_O_i[17]),
    .X(FrameData_O[17])
);

my_buf data_outbuf_18 (
    .A(FrameData_O_i[18]),
    .X(FrameData_O[18])
);

my_buf data_outbuf_19 (
    .A(FrameData_O_i[19]),
    .X(FrameData_O[19])
);

my_buf data_outbuf_20 (
    .A(FrameData_O_i[20]),
    .X(FrameData_O[20])
);

my_buf data_outbuf_21 (
    .A(FrameData_O_i[21]),
    .X(FrameData_O[21])
);

my_buf data_outbuf_22 (
    .A(FrameData_O_i[22]),
    .X(FrameData_O[22])
);

my_buf data_outbuf_23 (
    .A(FrameData_O_i[23]),
    .X(FrameData_O[23])
);

my_buf data_outbuf_24 (
    .A(FrameData_O_i[24]),
    .X(FrameData_O[24])
);

my_buf data_outbuf_25 (
    .A(FrameData_O_i[25]),
    .X(FrameData_O[25])
);

my_buf data_outbuf_26 (
    .A(FrameData_O_i[26]),
    .X(FrameData_O[26])
);

my_buf data_outbuf_27 (
    .A(FrameData_O_i[27]),
    .X(FrameData_O[27])
);

my_buf data_outbuf_28 (
    .A(FrameData_O_i[28]),
    .X(FrameData_O[28])
);

my_buf data_outbuf_29 (
    .A(FrameData_O_i[29]),
    .X(FrameData_O[29])
);

my_buf data_outbuf_30 (
    .A(FrameData_O_i[30]),
    .X(FrameData_O[30])
);

my_buf data_outbuf_31 (
    .A(FrameData_O_i[31]),
    .X(FrameData_O[31])
);

assign FrameStrobe_O_i = FrameStrobe_i;

my_buf strobe_inbuf_0 (
    .A(FrameStrobe[0]),
    .X(FrameStrobe_i[0])
);

my_buf strobe_inbuf_1 (
    .A(FrameStrobe[1]),
    .X(FrameStrobe_i[1])
);

my_buf strobe_inbuf_2 (
    .A(FrameStrobe[2]),
    .X(FrameStrobe_i[2])
);

my_buf strobe_inbuf_3 (
    .A(FrameStrobe[3]),
    .X(FrameStrobe_i[3])
);

my_buf strobe_inbuf_4 (
    .A(FrameStrobe[4]),
    .X(FrameStrobe_i[4])
);

my_buf strobe_inbuf_5 (
    .A(FrameStrobe[5]),
    .X(FrameStrobe_i[5])
);

my_buf strobe_inbuf_6 (
    .A(FrameStrobe[6]),
    .X(FrameStrobe_i[6])
);

my_buf strobe_inbuf_7 (
    .A(FrameStrobe[7]),
    .X(FrameStrobe_i[7])
);

my_buf strobe_inbuf_8 (
    .A(FrameStrobe[8]),
    .X(FrameStrobe_i[8])
);

my_buf strobe_inbuf_9 (
    .A(FrameStrobe[9]),
    .X(FrameStrobe_i[9])
);

my_buf strobe_inbuf_10 (
    .A(FrameStrobe[10]),
    .X(FrameStrobe_i[10])
);

my_buf strobe_inbuf_11 (
    .A(FrameStrobe[11]),
    .X(FrameStrobe_i[11])
);

my_buf strobe_inbuf_12 (
    .A(FrameStrobe[12]),
    .X(FrameStrobe_i[12])
);

my_buf strobe_inbuf_13 (
    .A(FrameStrobe[13]),
    .X(FrameStrobe_i[13])
);

my_buf strobe_inbuf_14 (
    .A(FrameStrobe[14]),
    .X(FrameStrobe_i[14])
);

my_buf strobe_inbuf_15 (
    .A(FrameStrobe[15]),
    .X(FrameStrobe_i[15])
);

my_buf strobe_inbuf_16 (
    .A(FrameStrobe[16]),
    .X(FrameStrobe_i[16])
);

my_buf strobe_inbuf_17 (
    .A(FrameStrobe[17]),
    .X(FrameStrobe_i[17])
);

my_buf strobe_inbuf_18 (
    .A(FrameStrobe[18]),
    .X(FrameStrobe_i[18])
);

my_buf strobe_inbuf_19 (
    .A(FrameStrobe[19]),
    .X(FrameStrobe_i[19])
);

my_buf strobe_outbuf_0 (
    .A(FrameStrobe_O_i[0]),
    .X(FrameStrobe_O[0])
);

my_buf strobe_outbuf_1 (
    .A(FrameStrobe_O_i[1]),
    .X(FrameStrobe_O[1])
);

my_buf strobe_outbuf_2 (
    .A(FrameStrobe_O_i[2]),
    .X(FrameStrobe_O[2])
);

my_buf strobe_outbuf_3 (
    .A(FrameStrobe_O_i[3]),
    .X(FrameStrobe_O[3])
);

my_buf strobe_outbuf_4 (
    .A(FrameStrobe_O_i[4]),
    .X(FrameStrobe_O[4])
);

my_buf strobe_outbuf_5 (
    .A(FrameStrobe_O_i[5]),
    .X(FrameStrobe_O[5])
);

my_buf strobe_outbuf_6 (
    .A(FrameStrobe_O_i[6]),
    .X(FrameStrobe_O[6])
);

my_buf strobe_outbuf_7 (
    .A(FrameStrobe_O_i[7]),
    .X(FrameStrobe_O[7])
);

my_buf strobe_outbuf_8 (
    .A(FrameStrobe_O_i[8]),
    .X(FrameStrobe_O[8])
);

my_buf strobe_outbuf_9 (
    .A(FrameStrobe_O_i[9]),
    .X(FrameStrobe_O[9])
);

my_buf strobe_outbuf_10 (
    .A(FrameStrobe_O_i[10]),
    .X(FrameStrobe_O[10])
);

my_buf strobe_outbuf_11 (
    .A(FrameStrobe_O_i[11]),
    .X(FrameStrobe_O[11])
);

my_buf strobe_outbuf_12 (
    .A(FrameStrobe_O_i[12]),
    .X(FrameStrobe_O[12])
);

my_buf strobe_outbuf_13 (
    .A(FrameStrobe_O_i[13]),
    .X(FrameStrobe_O[13])
);

my_buf strobe_outbuf_14 (
    .A(FrameStrobe_O_i[14]),
    .X(FrameStrobe_O[14])
);

my_buf strobe_outbuf_15 (
    .A(FrameStrobe_O_i[15]),
    .X(FrameStrobe_O[15])
);

my_buf strobe_outbuf_16 (
    .A(FrameStrobe_O_i[16]),
    .X(FrameStrobe_O[16])
);

my_buf strobe_outbuf_17 (
    .A(FrameStrobe_O_i[17]),
    .X(FrameStrobe_O[17])
);

my_buf strobe_outbuf_18 (
    .A(FrameStrobe_O_i[18]),
    .X(FrameStrobe_O[18])
);

my_buf strobe_outbuf_19 (
    .A(FrameStrobe_O_i[19]),
    .X(FrameStrobe_O[19])
);


 //configuration storage latches
W_IO_ConfigMem
`ifdef EMULATION
    #(
    .Emulate_Bitstream(Emulate_Bitstream)
    )
`endif
    Inst_W_IO_ConfigMem
    (
    .FrameData(FrameData),
    .FrameStrobe(FrameStrobe),
    .ConfigBits(ConfigBits),
    .ConfigBits_N(ConfigBits_N)
);


 //BEL component instantiations
IOBUF Inst_A_IOBUF (
    .CLK(A_CLK),
    .IN(A_IN),
    .EN(A_EN),
    .OUT(A_OUT),
    .IN_top(A_IN_top),
    .EN_top(A_EN_top),
    .OUT_top(A_OUT_top),
    .ConfigBits(ConfigBits[3-1:0])
);

W_IO_switch_matrix Inst_W_IO_switch_matrix (
    .S_GBUF_FEED_END0(S_GBUF_FEED_END[0]),
    .S_GBUF_FEED_END1(S_GBUF_FEED_END[1]),
    .S_GBUF_FEED_END2(S_GBUF_FEED_END[2]),
    .S_GBUF_FEED_END3(S_GBUF_FEED_END[3]),
    .N_GBUF_END0(N_GBUF_END[0]),
    .N_GBUF_END1(N_GBUF_END[1]),
    .N_GBUF_END2(N_GBUF_END[2]),
    .N_GBUF_END3(N_GBUF_END[3]),
    .W1END0(W1END[0]),
    .W1END1(W1END[1]),
    .W1END2(W1END[2]),
    .W1END3(W1END[3]),
    .W1END4(W1END[4]),
    .W1END5(W1END[5]),
    .W1END6(W1END[6]),
    .W1END7(W1END[7]),
    .W2MID0(W2MID[0]),
    .W2MID1(W2MID[1]),
    .W2MID2(W2MID[2]),
    .W2MID3(W2MID[3]),
    .W2MID4(W2MID[4]),
    .W2MID5(W2MID[5]),
    .W2MID6(W2MID[6]),
    .W2MID7(W2MID[7]),
    .W2END0(W2END[0]),
    .W2END1(W2END[1]),
    .W2END2(W2END[2]),
    .W2END3(W2END[3]),
    .W2END4(W2END[4]),
    .W2END5(W2END[5]),
    .W2END6(W2END[6]),
    .W2END7(W2END[7]),
    .A_OUT(A_OUT),
    .S_GBUF_FEED_BEG0(S_GBUF_FEED_BEG[0]),
    .S_GBUF_FEED_BEG1(S_GBUF_FEED_BEG[1]),
    .S_GBUF_FEED_BEG2(S_GBUF_FEED_BEG[2]),
    .S_GBUF_FEED_BEG3(S_GBUF_FEED_BEG[3]),
    .N_GBUF_BEG0(N_GBUF_BEG[0]),
    .N_GBUF_BEG1(N_GBUF_BEG[1]),
    .N_GBUF_BEG2(N_GBUF_BEG[2]),
    .N_GBUF_BEG3(N_GBUF_BEG[3]),
    .E1BEG0(E1BEG[0]),
    .E1BEG1(E1BEG[1]),
    .E1BEG2(E1BEG[2]),
    .E1BEG3(E1BEG[3]),
    .E1BEG4(E1BEG[4]),
    .E1BEG5(E1BEG[5]),
    .E1BEG6(E1BEG[6]),
    .E1BEG7(E1BEG[7]),
    .E2BEG0(E2BEG[0]),
    .E2BEG1(E2BEG[1]),
    .E2BEG2(E2BEG[2]),
    .E2BEG3(E2BEG[3]),
    .E2BEG4(E2BEG[4]),
    .E2BEG5(E2BEG[5]),
    .E2BEG6(E2BEG[6]),
    .E2BEG7(E2BEG[7]),
    .E2BEGb0(E2BEGb[0]),
    .E2BEGb1(E2BEGb[1]),
    .E2BEGb2(E2BEGb[2]),
    .E2BEGb3(E2BEGb[3]),
    .E2BEGb4(E2BEGb[4]),
    .E2BEGb5(E2BEGb[5]),
    .E2BEGb6(E2BEGb[6]),
    .E2BEGb7(E2BEGb[7]),
    .A_CLK(A_CLK),
    .A_IN(A_IN),
    .A_EN(A_EN),
    .ConfigBits(ConfigBits[68-1:3]),
    .ConfigBits_N(ConfigBits_N[68-1:3])
);

endmodule
// Models for the embedded FPGA fabric
module config_latch (input D, E, output reg Q, QN);
    always @(*)
    begin
        if (E == 1'b1) begin
            Q = D;
            QN = ~D;
        end
    end
endmodule

module my_buf (A, X);
    input A;
    output X;
    assign X = A;
endmodule

module clk_buf(input A, output X);
assign X = A;
endmodule

module bus_keeper(inout X);
`ifdef PDK_ihp_sg13cmos5l
    (* keep *)
    sg13cmos5l_sighold sighold (
        .SH (X)
    );
`elsif PDK_ihp_sg13g2
    (* keep *)
    sg13g2_sighold sighold (
        .SH (X)
    );
`endif
endmodule

module cus_mux41 (A0, A1, A2, A3, S0, S0N, S1, S1N, X);
    input A0;
    input A1;
    input A2;
    input A3;
    input S0;
    input S0N;
    input S1;
    input S1N;
    output X;

    wire B0 = S0 ? A1 : A0;
    wire B1 = S0 ? A3 : A2;
    assign X = S1 ? B1 : B0;
endmodule

module cus_mux21 (A0, A1, S, X);
    input A0;
    input A1;
    input S;
    output X;

    assign X = S ? A1 : A0;
endmodule

module cus_mux81 (A0, A1, A2, A3, A4, A5, A6, A7, S0, S0N, S1, S1N, S2, S2N, X);
    input A0;
    input A1;
    input A2;
    input A3;
    input A4;
    input A5;
    input A6;
    input A7;
    input S0;
    input S0N;
    input S1;
    input S1N;
    input S2;
    input S2N;
    output X;

    wire cus_mux41_out0;
    wire cus_mux41_out1;

    cus_mux41 cus_mux41_inst0(
    .A0 (A0),
    .A1 (A1),
    .A2 (A2),
    .A3 (A3),
    .S0 (S0),
    .S0N(S0N),
    .S1 (S1),
    .S1N(S1N),
    .X  (cus_mux41_out0)
    );

    cus_mux41 cus_mux41_inst1(
    .A0 (A4),
    .A1 (A5),
    .A2 (A6),
    .A3 (A7),
    .S0 (S0),
    .S0N(S0N),
    .S1 (S1),
    .S1N(S1N),
    .X  (cus_mux41_out1)
    );

    cus_mux21 cus_mux21_inst(
    .A0(cus_mux41_out0),
    .A1(cus_mux41_out1),
    .S (S2),
    .X (X)
    );
endmodule

module cus_mux161 (A0, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, S0, S0N, S1, S1N, S2, S2N, S3, S3N, X);
    input A0;
    input A1;
    input A2;
    input A3;
    input A4;
    input A5;
    input A6;
    input A7;
    input A8;
    input A9;
    input A10;
    input A11;
    input A12;
    input A13;
    input A14;
    input A15;
    input S0;
    input S0N;
    input S1;
    input S1N;
    input S2;
    input S2N;
    input S3;
    input S3N;
    output X;

    wire cus_mux41_out0;
    wire cus_mux41_out1;
    wire cus_mux41_out2;
    wire cus_mux41_out3;

    cus_mux41 cus_mux41_inst0(
    .A0 (A0),
    .A1 (A1),
    .A2 (A2),
    .A3 (A3),
    .S0 (S0),
    .S0N(S0N),
    .S1 (S1),
    .S1N(S1N),
    .X  (cus_mux41_out0)
    );

    cus_mux41 cus_mux41_inst1(
    .A0 (A4),
    .A1 (A5),
    .A2 (A6),
    .A3 (A7),
    .S0 (S0),
    .S0N(S0N),
    .S1 (S1),
    .S1N(S1N),
    .X  (cus_mux41_out1)
    );

    cus_mux41 cus_mux41_inst2(
    .A0 (A8),
    .A1 (A9),
    .A2 (A10),
    .A3 (A11),
    .S0 (S0),
    .S0N(S0N),
    .S1 (S1),
    .S1N(S1N),
    .X  (cus_mux41_out2)
    );

    cus_mux41 cus_mux41_inst3(
    .A0 (A12),
    .A1 (A13),
    .A2 (A14),
    .A3 (A15),
    .S0 (S0),
    .S0N(S0N),
    .S1 (S1),
    .S1N(S1N),
    .X  (cus_mux41_out3)
    );

    cus_mux41 cus_mux41_inst4(
    .A0 (cus_mux41_out0),
    .A1 (cus_mux41_out1),
    .A2 (cus_mux41_out2),
    .A3 (cus_mux41_out3),
    .S0 (S2),
    .S0N(S2N),
    .S1 (S3),
    .S1N(S3N),
    .X  (X)
    );
endmodule

//module clk_buf(input A, output X);
//assign X = A;
//endmodule

// (* blackbox *)
// blacbox prevents logic loops, but OpenROAD
// doesn't find the instance later on...
//module break_comb_loop(input A, output X);
//assign X = A;
//endmodule

module tiny_fabric_5x5
    #(
        parameter MaxFramesPerCol=20,
        parameter FrameBitsPerRow=32
    )
    (
        input  Tile_X0Y1_A_OUT_top, //EXTERNAL
        output  Tile_X0Y1_A_IN_top, //EXTERNAL
        output  Tile_X0Y1_A_EN_top, //EXTERNAL
        input  Tile_X0Y1_B_OUT_top, //EXTERNAL
        output  Tile_X0Y1_B_IN_top, //EXTERNAL
        output  Tile_X0Y1_B_EN_top, //EXTERNAL
        input  Tile_X0Y1_C_OUT_top, //EXTERNAL
        output  Tile_X0Y1_C_IN_top, //EXTERNAL
        output  Tile_X0Y1_C_EN_top, //EXTERNAL
        input  Tile_X0Y1_D_OUT_top, //EXTERNAL
        output  Tile_X0Y1_D_IN_top, //EXTERNAL
        output  Tile_X0Y1_D_EN_top, //EXTERNAL
        input  Tile_X4Y1_A_OUT_top, //EXTERNAL
        output  Tile_X4Y1_A_IN_top, //EXTERNAL
        output  Tile_X4Y1_A_EN_top, //EXTERNAL
        input  Tile_X4Y1_B_OUT_top, //EXTERNAL
        output  Tile_X4Y1_B_IN_top, //EXTERNAL
        output  Tile_X4Y1_B_EN_top, //EXTERNAL
        input  Tile_X4Y1_C_OUT_top, //EXTERNAL
        output  Tile_X4Y1_C_IN_top, //EXTERNAL
        output  Tile_X4Y1_C_EN_top, //EXTERNAL
        input  Tile_X4Y1_D_OUT_top, //EXTERNAL
        output  Tile_X4Y1_D_IN_top, //EXTERNAL
        output  Tile_X4Y1_D_EN_top, //EXTERNAL
        input  Tile_X0Y2_A_OUT_top, //EXTERNAL
        output  Tile_X0Y2_A_IN_top, //EXTERNAL
        output  Tile_X0Y2_A_EN_top, //EXTERNAL
        input  Tile_X0Y2_B_OUT_top, //EXTERNAL
        output  Tile_X0Y2_B_IN_top, //EXTERNAL
        output  Tile_X0Y2_B_EN_top, //EXTERNAL
        input  Tile_X0Y3_A_OUT_top, //EXTERNAL
        output  Tile_X0Y3_A_IN_top, //EXTERNAL
        output  Tile_X0Y3_A_EN_top, //EXTERNAL
        input  Tile_X0Y3_B_OUT_top, //EXTERNAL
        output  Tile_X0Y3_B_IN_top, //EXTERNAL
        output  Tile_X0Y3_B_EN_top, //EXTERNAL
        input  Tile_X0Y3_C_OUT_top, //EXTERNAL
        output  Tile_X0Y3_C_IN_top, //EXTERNAL
        output  Tile_X0Y3_C_EN_top, //EXTERNAL
        input  Tile_X0Y3_D_OUT_top, //EXTERNAL
        output  Tile_X0Y3_D_IN_top, //EXTERNAL
        output  Tile_X0Y3_D_EN_top, //EXTERNAL
        input  Tile_X4Y3_A_OUT_top, //EXTERNAL
        output  Tile_X4Y3_A_IN_top, //EXTERNAL
        output  Tile_X4Y3_A_EN_top, //EXTERNAL
        input  Tile_X4Y3_B_OUT_top, //EXTERNAL
        output  Tile_X4Y3_B_IN_top, //EXTERNAL
        output  Tile_X4Y3_B_EN_top, //EXTERNAL
        input  Tile_X4Y3_C_OUT_top, //EXTERNAL
        output  Tile_X4Y3_C_IN_top, //EXTERNAL
        output  Tile_X4Y3_C_EN_top, //EXTERNAL
        input  Tile_X4Y3_D_OUT_top, //EXTERNAL
        output  Tile_X4Y3_D_IN_top, //EXTERNAL
        output  Tile_X4Y3_D_EN_top, //EXTERNAL
        input  Tile_X0Y4_SYS_RESET_RESET_top, //EXTERNAL
        input  Tile_X1Y4_A_OUT_top, //EXTERNAL
        output  Tile_X1Y4_A_IN_top, //EXTERNAL
        output  Tile_X1Y4_A_EN_top, //EXTERNAL
        input  Tile_X1Y4_B_OUT_top, //EXTERNAL
        output  Tile_X1Y4_B_IN_top, //EXTERNAL
        output  Tile_X1Y4_B_EN_top, //EXTERNAL
        input  Tile_X1Y4_C_OUT_top, //EXTERNAL
        output  Tile_X1Y4_C_IN_top, //EXTERNAL
        output  Tile_X1Y4_C_EN_top, //EXTERNAL
        input  Tile_X1Y4_D_OUT_top, //EXTERNAL
        output  Tile_X1Y4_D_IN_top, //EXTERNAL
        output  Tile_X1Y4_D_EN_top, //EXTERNAL
        input  Tile_X3Y4_A_OUT_top, //EXTERNAL
        output  Tile_X3Y4_A_IN_top, //EXTERNAL
        output  Tile_X3Y4_A_EN_top, //EXTERNAL
        input  Tile_X3Y4_B_OUT_top, //EXTERNAL
        output  Tile_X3Y4_B_IN_top, //EXTERNAL
        output  Tile_X3Y4_B_EN_top, //EXTERNAL
        input  Tile_X3Y4_C_OUT_top, //EXTERNAL
        output  Tile_X3Y4_C_IN_top, //EXTERNAL
        output  Tile_X3Y4_C_EN_top, //EXTERNAL
        input  Tile_X3Y4_D_OUT_top, //EXTERNAL
        output  Tile_X3Y4_D_IN_top, //EXTERNAL
        output  Tile_X3Y4_D_EN_top, //EXTERNAL
        input  [(FrameBitsPerRow*5)-1:0] FrameData, //CONFIG_PORT
        input  [(MaxFramesPerCol*5)-1:0] FrameStrobe //CONFIG_PORT
);

 //signal declarations

 //configuration signal declarations

wire[FrameBitsPerRow -1:0] Row_Y0_FrameData;
wire[FrameBitsPerRow -1:0] Row_Y1_FrameData;
wire[FrameBitsPerRow -1:0] Row_Y2_FrameData;
wire[FrameBitsPerRow -1:0] Row_Y3_FrameData;
wire[FrameBitsPerRow -1:0] Row_Y4_FrameData;
wire[MaxFramesPerCol - 1:0] Column_X0_FrameStrobe;
wire[MaxFramesPerCol - 1:0] Column_X1_FrameStrobe;
wire[MaxFramesPerCol - 1:0] Column_X2_FrameStrobe;
wire[MaxFramesPerCol - 1:0] Column_X3_FrameStrobe;
wire[MaxFramesPerCol - 1:0] Column_X4_FrameStrobe;
wire[FrameBitsPerRow - 1:0] Tile_X0Y0_FrameData_O;
wire[FrameBitsPerRow - 1:0] Tile_X1Y0_FrameData_O;
wire[FrameBitsPerRow - 1:0] Tile_X2Y0_FrameData_O;
wire[FrameBitsPerRow - 1:0] Tile_X3Y0_FrameData_O;
wire[FrameBitsPerRow - 1:0] Tile_X4Y0_FrameData_O;
wire[FrameBitsPerRow - 1:0] Tile_X0Y1_FrameData_O;
wire[FrameBitsPerRow - 1:0] Tile_X1Y1_FrameData_O;
wire[FrameBitsPerRow - 1:0] Tile_X2Y1_FrameData_O;
wire[FrameBitsPerRow - 1:0] Tile_X3Y1_FrameData_O;
wire[FrameBitsPerRow - 1:0] Tile_X4Y1_FrameData_O;
wire[FrameBitsPerRow - 1:0] Tile_X0Y2_FrameData_O;
wire[FrameBitsPerRow - 1:0] Tile_X1Y2_FrameData_O;
wire[FrameBitsPerRow - 1:0] Tile_X2Y2_FrameData_O;
wire[FrameBitsPerRow - 1:0] Tile_X3Y2_FrameData_O;
wire[FrameBitsPerRow - 1:0] Tile_X4Y2_FrameData_O;
wire[FrameBitsPerRow - 1:0] Tile_X0Y3_FrameData_O;
wire[FrameBitsPerRow - 1:0] Tile_X1Y3_FrameData_O;
wire[FrameBitsPerRow - 1:0] Tile_X2Y3_FrameData_O;
wire[FrameBitsPerRow - 1:0] Tile_X3Y3_FrameData_O;
wire[FrameBitsPerRow - 1:0] Tile_X4Y3_FrameData_O;
wire[FrameBitsPerRow - 1:0] Tile_X0Y4_FrameData_O;
wire[FrameBitsPerRow - 1:0] Tile_X1Y4_FrameData_O;
wire[FrameBitsPerRow - 1:0] Tile_X2Y4_FrameData_O;
wire[FrameBitsPerRow - 1:0] Tile_X3Y4_FrameData_O;
wire[FrameBitsPerRow - 1:0] Tile_X4Y4_FrameData_O;
wire[MaxFramesPerCol - 1:0] Tile_X0Y0_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X1Y0_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X2Y0_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X3Y0_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X4Y0_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X0Y1_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X1Y1_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X2Y1_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X3Y1_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X4Y1_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X0Y2_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X1Y2_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X2Y2_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X3Y2_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X4Y2_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X0Y3_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X1Y3_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X2Y3_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X3Y3_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X4Y3_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X0Y4_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X1Y4_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X2Y4_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X3Y4_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X4Y4_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X0Y5_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X1Y5_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X2Y5_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X3Y5_FrameStrobe_O;
wire[MaxFramesPerCol - 1:0] Tile_X4Y5_FrameStrobe_O;
 //tile-to-tile signal declarations
wire[3:0] Tile_X0Y0_S_GBUF_FEED_BEG;
wire[7:0] Tile_X1Y0_S1BEG;
wire[7:0] Tile_X1Y0_S2BEG;
wire[7:0] Tile_X1Y0_S2BEGb;
wire[7:0] Tile_X2Y0_S1BEG;
wire[7:0] Tile_X2Y0_S2BEG;
wire[7:0] Tile_X2Y0_S2BEGb;
wire[7:0] Tile_X3Y0_S1BEG;
wire[7:0] Tile_X3Y0_S2BEG;
wire[7:0] Tile_X3Y0_S2BEGb;
wire[3:0] Tile_X0Y1_S_GBUF_FEED_BEG;
wire[3:0] Tile_X0Y1_N_GBUF_BEG;
wire[7:0] Tile_X0Y1_E1BEG;
wire[7:0] Tile_X0Y1_E2BEG;
wire[7:0] Tile_X0Y1_E2BEGb;
wire[3:0] Tile_X1Y1_N_GBUF_BEG;
wire[7:0] Tile_X1Y1_N1BEG;
wire[7:0] Tile_X1Y1_N2BEG;
wire[7:0] Tile_X1Y1_N2BEGb;
wire[7:0] Tile_X1Y1_E1BEG;
wire[7:0] Tile_X1Y1_E2BEG;
wire[7:0] Tile_X1Y1_E2BEGb;
wire[7:0] Tile_X1Y1_S1BEG;
wire[7:0] Tile_X1Y1_S2BEG;
wire[7:0] Tile_X1Y1_S2BEGb;
wire[7:0] Tile_X1Y1_W1BEG;
wire[7:0] Tile_X1Y1_W2BEG;
wire[7:0] Tile_X1Y1_W2BEGb;
wire[0:0] Tile_X1Y1_CO;
wire[3:0] Tile_X2Y1_N_GBUF_BEG;
wire[7:0] Tile_X2Y1_N1BEG;
wire[7:0] Tile_X2Y1_N2BEG;
wire[7:0] Tile_X2Y1_N2BEGb;
wire[7:0] Tile_X2Y1_E1BEG;
wire[7:0] Tile_X2Y1_E2BEG;
wire[7:0] Tile_X2Y1_E2BEGb;
wire[7:0] Tile_X2Y1_S1BEG;
wire[7:0] Tile_X2Y1_S2BEG;
wire[7:0] Tile_X2Y1_S2BEGb;
wire[7:0] Tile_X2Y1_W1BEG;
wire[7:0] Tile_X2Y1_W2BEG;
wire[7:0] Tile_X2Y1_W2BEGb;
wire[0:0] Tile_X2Y1_CO;
wire[3:0] Tile_X3Y1_N_GBUF_BEG;
wire[7:0] Tile_X3Y1_N1BEG;
wire[7:0] Tile_X3Y1_N2BEG;
wire[7:0] Tile_X3Y1_N2BEGb;
wire[7:0] Tile_X3Y1_E1BEG;
wire[7:0] Tile_X3Y1_E2BEG;
wire[7:0] Tile_X3Y1_E2BEGb;
wire[7:0] Tile_X3Y1_S1BEG;
wire[7:0] Tile_X3Y1_S2BEG;
wire[7:0] Tile_X3Y1_S2BEGb;
wire[7:0] Tile_X3Y1_W1BEG;
wire[7:0] Tile_X3Y1_W2BEG;
wire[7:0] Tile_X3Y1_W2BEGb;
wire[0:0] Tile_X3Y1_CO;
wire[3:0] Tile_X4Y1_N_GBUF_BEG;
wire[7:0] Tile_X4Y1_W1BEG;
wire[7:0] Tile_X4Y1_W2BEG;
wire[7:0] Tile_X4Y1_W2BEGb;
wire[3:0] Tile_X0Y2_S_GBUF_FEED_BEG;
wire[3:0] Tile_X0Y2_N_GBUF_BEG;
wire[7:0] Tile_X0Y2_E1BEG;
wire[7:0] Tile_X0Y2_E2BEG;
wire[7:0] Tile_X0Y2_E2BEGb;
wire[3:0] Tile_X1Y2_N_GBUF_BEG;
wire[7:0] Tile_X1Y2_N1BEG;
wire[7:0] Tile_X1Y2_N2BEG;
wire[7:0] Tile_X1Y2_N2BEGb;
wire[7:0] Tile_X1Y2_E1BEG;
wire[7:0] Tile_X1Y2_E2BEG;
wire[7:0] Tile_X1Y2_E2BEGb;
wire[7:0] Tile_X1Y2_S1BEG;
wire[7:0] Tile_X1Y2_S2BEG;
wire[7:0] Tile_X1Y2_S2BEGb;
wire[7:0] Tile_X1Y2_W1BEG;
wire[7:0] Tile_X1Y2_W2BEG;
wire[7:0] Tile_X1Y2_W2BEGb;
wire[0:0] Tile_X1Y2_CO;
wire[3:0] Tile_X2Y2_N_GBUF_BEG;
wire[7:0] Tile_X2Y2_N1BEG;
wire[7:0] Tile_X2Y2_N2BEG;
wire[7:0] Tile_X2Y2_N2BEGb;
wire[7:0] Tile_X2Y2_E1BEG;
wire[7:0] Tile_X2Y2_E2BEG;
wire[7:0] Tile_X2Y2_E2BEGb;
wire[7:0] Tile_X2Y2_S1BEG;
wire[7:0] Tile_X2Y2_S2BEG;
wire[7:0] Tile_X2Y2_S2BEGb;
wire[7:0] Tile_X2Y2_W1BEG;
wire[7:0] Tile_X2Y2_W2BEG;
wire[7:0] Tile_X2Y2_W2BEGb;
wire[0:0] Tile_X2Y2_CO;
wire[3:0] Tile_X3Y2_N_GBUF_BEG;
wire[7:0] Tile_X3Y2_N1BEG;
wire[7:0] Tile_X3Y2_N2BEG;
wire[7:0] Tile_X3Y2_N2BEGb;
wire[7:0] Tile_X3Y2_E1BEG;
wire[7:0] Tile_X3Y2_E2BEG;
wire[7:0] Tile_X3Y2_E2BEGb;
wire[7:0] Tile_X3Y2_S1BEG;
wire[7:0] Tile_X3Y2_S2BEG;
wire[7:0] Tile_X3Y2_S2BEGb;
wire[7:0] Tile_X3Y2_W1BEG;
wire[7:0] Tile_X3Y2_W2BEG;
wire[7:0] Tile_X3Y2_W2BEGb;
wire[0:0] Tile_X3Y2_CO;
wire[3:0] Tile_X4Y2_N_GBUF_BEG;
wire[7:0] Tile_X4Y2_W1BEG;
wire[7:0] Tile_X4Y2_W2BEG;
wire[7:0] Tile_X4Y2_W2BEGb;
wire[3:0] Tile_X0Y3_S_GBUF_FEED_BEG;
wire[3:0] Tile_X0Y3_N_GBUF_BEG;
wire[7:0] Tile_X0Y3_E1BEG;
wire[7:0] Tile_X0Y3_E2BEG;
wire[7:0] Tile_X0Y3_E2BEGb;
wire[3:0] Tile_X1Y3_N_GBUF_BEG;
wire[7:0] Tile_X1Y3_N1BEG;
wire[7:0] Tile_X1Y3_N2BEG;
wire[7:0] Tile_X1Y3_N2BEGb;
wire[7:0] Tile_X1Y3_E1BEG;
wire[7:0] Tile_X1Y3_E2BEG;
wire[7:0] Tile_X1Y3_E2BEGb;
wire[7:0] Tile_X1Y3_S1BEG;
wire[7:0] Tile_X1Y3_S2BEG;
wire[7:0] Tile_X1Y3_S2BEGb;
wire[7:0] Tile_X1Y3_W1BEG;
wire[7:0] Tile_X1Y3_W2BEG;
wire[7:0] Tile_X1Y3_W2BEGb;
wire[0:0] Tile_X1Y3_CO;
wire[3:0] Tile_X2Y3_N_GBUF_BEG;
wire[7:0] Tile_X2Y3_N1BEG;
wire[7:0] Tile_X2Y3_N2BEG;
wire[7:0] Tile_X2Y3_N2BEGb;
wire[7:0] Tile_X2Y3_E1BEG;
wire[7:0] Tile_X2Y3_E2BEG;
wire[7:0] Tile_X2Y3_E2BEGb;
wire[7:0] Tile_X2Y3_S1BEG;
wire[7:0] Tile_X2Y3_S2BEG;
wire[7:0] Tile_X2Y3_S2BEGb;
wire[7:0] Tile_X2Y3_W1BEG;
wire[7:0] Tile_X2Y3_W2BEG;
wire[7:0] Tile_X2Y3_W2BEGb;
wire[0:0] Tile_X2Y3_CO;
wire[3:0] Tile_X3Y3_N_GBUF_BEG;
wire[7:0] Tile_X3Y3_N1BEG;
wire[7:0] Tile_X3Y3_N2BEG;
wire[7:0] Tile_X3Y3_N2BEGb;
wire[7:0] Tile_X3Y3_E1BEG;
wire[7:0] Tile_X3Y3_E2BEG;
wire[7:0] Tile_X3Y3_E2BEGb;
wire[7:0] Tile_X3Y3_S1BEG;
wire[7:0] Tile_X3Y3_S2BEG;
wire[7:0] Tile_X3Y3_S2BEGb;
wire[7:0] Tile_X3Y3_W1BEG;
wire[7:0] Tile_X3Y3_W2BEG;
wire[7:0] Tile_X3Y3_W2BEGb;
wire[0:0] Tile_X3Y3_CO;
wire[3:0] Tile_X4Y3_N_GBUF_BEG;
wire[7:0] Tile_X4Y3_W1BEG;
wire[7:0] Tile_X4Y3_W2BEG;
wire[7:0] Tile_X4Y3_W2BEGb;
wire[3:0] Tile_X0Y4_N_GBUF_BEG;
wire[3:0] Tile_X0Y4_E_GBUF_BEG;
wire[3:0] Tile_X1Y4_W_GBUF_FEED_BEG;
wire[3:0] Tile_X1Y4_N_GBUF_BEG;
wire[3:0] Tile_X1Y4_E_GBUF_BEG;
wire[7:0] Tile_X1Y4_N1BEG;
wire[7:0] Tile_X1Y4_N2BEG;
wire[7:0] Tile_X1Y4_N2BEGb;
wire[0:0] Tile_X1Y4_Co;
wire[3:0] Tile_X2Y4_W_GBUF_FEED_BEG;
wire[3:0] Tile_X2Y4_N_GBUF_BEG;
wire[3:0] Tile_X2Y4_E_GBUF_BEG;
wire[7:0] Tile_X2Y4_N1BEG;
wire[7:0] Tile_X2Y4_N2BEG;
wire[7:0] Tile_X2Y4_N2BEGb;
wire[0:0] Tile_X2Y4_Co;
wire[3:0] Tile_X3Y4_W_GBUF_FEED_BEG;
wire[3:0] Tile_X3Y4_N_GBUF_BEG;
wire[3:0] Tile_X3Y4_E_GBUF_BEG;
wire[7:0] Tile_X3Y4_N1BEG;
wire[7:0] Tile_X3Y4_N2BEG;
wire[7:0] Tile_X3Y4_N2BEGb;
wire[0:0] Tile_X3Y4_Co;
wire[3:0] Tile_X4Y4_W_GBUF_FEED_BEG;
wire[3:0] Tile_X4Y4_N_GBUF_BEG;

assign Row_Y0_FrameData = FrameData[FrameBitsPerRow*(0+1)-1:FrameBitsPerRow*0];
assign Row_Y1_FrameData = FrameData[FrameBitsPerRow*(1+1)-1:FrameBitsPerRow*1];
assign Row_Y2_FrameData = FrameData[FrameBitsPerRow*(2+1)-1:FrameBitsPerRow*2];
assign Row_Y3_FrameData = FrameData[FrameBitsPerRow*(3+1)-1:FrameBitsPerRow*3];
assign Row_Y4_FrameData = FrameData[FrameBitsPerRow*(4+1)-1:FrameBitsPerRow*4];
assign Column_X0_FrameStrobe = FrameStrobe[MaxFramesPerCol*(0+1)-1:MaxFramesPerCol*0];
assign Column_X1_FrameStrobe = FrameStrobe[MaxFramesPerCol*(1+1)-1:MaxFramesPerCol*1];
assign Column_X2_FrameStrobe = FrameStrobe[MaxFramesPerCol*(2+1)-1:MaxFramesPerCol*2];
assign Column_X3_FrameStrobe = FrameStrobe[MaxFramesPerCol*(3+1)-1:MaxFramesPerCol*3];
assign Column_X4_FrameStrobe = FrameStrobe[MaxFramesPerCol*(4+1)-1:MaxFramesPerCol*4];

 //tile IO port will get directly connected to top-level tile module
 (* keep *)
(* keep *) NW_term
`ifdef EMULATION
    #(
    .Emulate_Bitstream(`Tile_X0Y0_Emulate_Bitstream)
    )
`endif
    Tile_X0Y0_NW_term
    (
    .N_GBUF_END(Tile_X0Y1_N_GBUF_BEG),
    .S_GBUF_FEED_BEG(Tile_X0Y0_S_GBUF_FEED_BEG),
    .FrameData(Row_Y0_FrameData),
    .FrameData_O(Tile_X0Y0_FrameData_O),
    .FrameStrobe(Tile_X0Y1_FrameStrobe_O),
    .FrameStrobe_O(Tile_X0Y0_FrameStrobe_O)
);


 //tile IO port will get directly connected to top-level tile module
 (* keep *)
(* keep *) N_term
`ifdef EMULATION
    #(
    .Emulate_Bitstream(`Tile_X1Y0_Emulate_Bitstream)
    )
`endif
    Tile_X1Y0_N_term
    (
    .N_GBUF_END(Tile_X1Y1_N_GBUF_BEG),
    .N1END(Tile_X1Y1_N1BEG),
    .N2MID(Tile_X1Y1_N2BEG),
    .N2END(Tile_X1Y1_N2BEGb),
    .Ci(Tile_X1Y1_CO),
    .S1BEG(Tile_X1Y0_S1BEG),
    .S2BEG(Tile_X1Y0_S2BEG),
    .S2BEGb(Tile_X1Y0_S2BEGb),
    .FrameData(Tile_X0Y0_FrameData_O),
    .FrameData_O(Tile_X1Y0_FrameData_O),
    .FrameStrobe(Tile_X1Y1_FrameStrobe_O),
    .FrameStrobe_O(Tile_X1Y0_FrameStrobe_O)
);


 //tile IO port will get directly connected to top-level tile module
 (* keep *)
(* keep *) N_term
`ifdef EMULATION
    #(
    .Emulate_Bitstream(`Tile_X2Y0_Emulate_Bitstream)
    )
`endif
    Tile_X2Y0_N_term
    (
    .N_GBUF_END(Tile_X2Y1_N_GBUF_BEG),
    .N1END(Tile_X2Y1_N1BEG),
    .N2MID(Tile_X2Y1_N2BEG),
    .N2END(Tile_X2Y1_N2BEGb),
    .Ci(Tile_X2Y1_CO),
    .S1BEG(Tile_X2Y0_S1BEG),
    .S2BEG(Tile_X2Y0_S2BEG),
    .S2BEGb(Tile_X2Y0_S2BEGb),
    .FrameData(Tile_X1Y0_FrameData_O),
    .FrameData_O(Tile_X2Y0_FrameData_O),
    .FrameStrobe(Tile_X2Y1_FrameStrobe_O),
    .FrameStrobe_O(Tile_X2Y0_FrameStrobe_O)
);


 //tile IO port will get directly connected to top-level tile module
 (* keep *)
(* keep *) N_term
`ifdef EMULATION
    #(
    .Emulate_Bitstream(`Tile_X3Y0_Emulate_Bitstream)
    )
`endif
    Tile_X3Y0_N_term
    (
    .N_GBUF_END(Tile_X3Y1_N_GBUF_BEG),
    .N1END(Tile_X3Y1_N1BEG),
    .N2MID(Tile_X3Y1_N2BEG),
    .N2END(Tile_X3Y1_N2BEGb),
    .Ci(Tile_X3Y1_CO),
    .S1BEG(Tile_X3Y0_S1BEG),
    .S2BEG(Tile_X3Y0_S2BEG),
    .S2BEGb(Tile_X3Y0_S2BEGb),
    .FrameData(Tile_X2Y0_FrameData_O),
    .FrameData_O(Tile_X3Y0_FrameData_O),
    .FrameStrobe(Tile_X3Y1_FrameStrobe_O),
    .FrameStrobe_O(Tile_X3Y0_FrameStrobe_O)
);


 //tile IO port will get directly connected to top-level tile module
 (* keep *)
(* keep *) NE_term
`ifdef EMULATION
    #(
    .Emulate_Bitstream(`Tile_X4Y0_Emulate_Bitstream)
    )
`endif
    Tile_X4Y0_NE_term
    (
    .N_GBUF_END(Tile_X4Y1_N_GBUF_BEG),
    .FrameData(Tile_X3Y0_FrameData_O),
    .FrameData_O(Tile_X4Y0_FrameData_O),
    .FrameStrobe(Tile_X4Y1_FrameStrobe_O),
    .FrameStrobe_O(Tile_X4Y0_FrameStrobe_O)
);


 //tile IO port will get directly connected to top-level tile module
 (* keep *)
(* keep *) W_IO4
`ifdef EMULATION
    #(
    .Emulate_Bitstream(`Tile_X0Y1_Emulate_Bitstream)
    )
`endif
    Tile_X0Y1_W_IO4
    (
    .N_GBUF_END(Tile_X0Y2_N_GBUF_BEG),
    .S_GBUF_FEED_END(Tile_X0Y0_S_GBUF_FEED_BEG),
    .W1END(Tile_X1Y1_W1BEG),
    .W2MID(Tile_X1Y1_W2BEG),
    .W2END(Tile_X1Y1_W2BEGb),
    .S_GBUF_FEED_BEG(Tile_X0Y1_S_GBUF_FEED_BEG),
    .N_GBUF_BEG(Tile_X0Y1_N_GBUF_BEG),
    .E1BEG(Tile_X0Y1_E1BEG),
    .E2BEG(Tile_X0Y1_E2BEG),
    .E2BEGb(Tile_X0Y1_E2BEGb),
    .A_OUT_top(Tile_X0Y1_A_OUT_top),
    .A_IN_top(Tile_X0Y1_A_IN_top),
    .A_EN_top(Tile_X0Y1_A_EN_top),
    .B_OUT_top(Tile_X0Y1_B_OUT_top),
    .B_IN_top(Tile_X0Y1_B_IN_top),
    .B_EN_top(Tile_X0Y1_B_EN_top),
    .C_OUT_top(Tile_X0Y1_C_OUT_top),
    .C_IN_top(Tile_X0Y1_C_IN_top),
    .C_EN_top(Tile_X0Y1_C_EN_top),
    .D_OUT_top(Tile_X0Y1_D_OUT_top),
    .D_IN_top(Tile_X0Y1_D_IN_top),
    .D_EN_top(Tile_X0Y1_D_EN_top),
    .FrameData(Row_Y1_FrameData),
    .FrameData_O(Tile_X0Y1_FrameData_O),
    .FrameStrobe(Tile_X0Y2_FrameStrobe_O),
    .FrameStrobe_O(Tile_X0Y1_FrameStrobe_O)
);


 //tile IO port will get directly connected to top-level tile module
 (* keep *)
(* keep *) LUT4x8_ha
`ifdef EMULATION
    #(
    .Emulate_Bitstream(`Tile_X1Y1_Emulate_Bitstream)
    )
`endif
    Tile_X1Y1_LUT4x8_ha
    (
    .N_GBUF_END(Tile_X1Y2_N_GBUF_BEG),
    .N1END(Tile_X1Y2_N1BEG),
    .N2MID(Tile_X1Y2_N2BEG),
    .N2END(Tile_X1Y2_N2BEGb),
    .CI(Tile_X1Y2_CO),
    .E1END(Tile_X0Y1_E1BEG),
    .E2MID(Tile_X0Y1_E2BEG),
    .E2END(Tile_X0Y1_E2BEGb),
    .S1END(Tile_X1Y0_S1BEG),
    .S2MID(Tile_X1Y0_S2BEG),
    .S2END(Tile_X1Y0_S2BEGb),
    .W1END(Tile_X2Y1_W1BEG),
    .W2MID(Tile_X2Y1_W2BEG),
    .W2END(Tile_X2Y1_W2BEGb),
    .N_GBUF_BEG(Tile_X1Y1_N_GBUF_BEG),
    .N1BEG(Tile_X1Y1_N1BEG),
    .N2BEG(Tile_X1Y1_N2BEG),
    .N2BEGb(Tile_X1Y1_N2BEGb),
    .E1BEG(Tile_X1Y1_E1BEG),
    .E2BEG(Tile_X1Y1_E2BEG),
    .E2BEGb(Tile_X1Y1_E2BEGb),
    .S1BEG(Tile_X1Y1_S1BEG),
    .S2BEG(Tile_X1Y1_S2BEG),
    .S2BEGb(Tile_X1Y1_S2BEGb),
    .W1BEG(Tile_X1Y1_W1BEG),
    .W2BEG(Tile_X1Y1_W2BEG),
    .W2BEGb(Tile_X1Y1_W2BEGb),
    .CO(Tile_X1Y1_CO),
    .FrameData(Tile_X0Y1_FrameData_O),
    .FrameData_O(Tile_X1Y1_FrameData_O),
    .FrameStrobe(Tile_X1Y2_FrameStrobe_O),
    .FrameStrobe_O(Tile_X1Y1_FrameStrobe_O)
);


 //tile IO port will get directly connected to top-level tile module
 (* keep *)
(* keep *) LUT4x8_ha
`ifdef EMULATION
    #(
    .Emulate_Bitstream(`Tile_X2Y1_Emulate_Bitstream)
    )
`endif
    Tile_X2Y1_LUT4x8_ha
    (
    .N_GBUF_END(Tile_X2Y2_N_GBUF_BEG),
    .N1END(Tile_X2Y2_N1BEG),
    .N2MID(Tile_X2Y2_N2BEG),
    .N2END(Tile_X2Y2_N2BEGb),
    .CI(Tile_X2Y2_CO),
    .E1END(Tile_X1Y1_E1BEG),
    .E2MID(Tile_X1Y1_E2BEG),
    .E2END(Tile_X1Y1_E2BEGb),
    .S1END(Tile_X2Y0_S1BEG),
    .S2MID(Tile_X2Y0_S2BEG),
    .S2END(Tile_X2Y0_S2BEGb),
    .W1END(Tile_X3Y1_W1BEG),
    .W2MID(Tile_X3Y1_W2BEG),
    .W2END(Tile_X3Y1_W2BEGb),
    .N_GBUF_BEG(Tile_X2Y1_N_GBUF_BEG),
    .N1BEG(Tile_X2Y1_N1BEG),
    .N2BEG(Tile_X2Y1_N2BEG),
    .N2BEGb(Tile_X2Y1_N2BEGb),
    .E1BEG(Tile_X2Y1_E1BEG),
    .E2BEG(Tile_X2Y1_E2BEG),
    .E2BEGb(Tile_X2Y1_E2BEGb),
    .S1BEG(Tile_X2Y1_S1BEG),
    .S2BEG(Tile_X2Y1_S2BEG),
    .S2BEGb(Tile_X2Y1_S2BEGb),
    .W1BEG(Tile_X2Y1_W1BEG),
    .W2BEG(Tile_X2Y1_W2BEG),
    .W2BEGb(Tile_X2Y1_W2BEGb),
    .CO(Tile_X2Y1_CO),
    .FrameData(Tile_X1Y1_FrameData_O),
    .FrameData_O(Tile_X2Y1_FrameData_O),
    .FrameStrobe(Tile_X2Y2_FrameStrobe_O),
    .FrameStrobe_O(Tile_X2Y1_FrameStrobe_O)
);


 //tile IO port will get directly connected to top-level tile module
 (* keep *)
(* keep *) LUT4x8_ha
`ifdef EMULATION
    #(
    .Emulate_Bitstream(`Tile_X3Y1_Emulate_Bitstream)
    )
`endif
    Tile_X3Y1_LUT4x8_ha
    (
    .N_GBUF_END(Tile_X3Y2_N_GBUF_BEG),
    .N1END(Tile_X3Y2_N1BEG),
    .N2MID(Tile_X3Y2_N2BEG),
    .N2END(Tile_X3Y2_N2BEGb),
    .CI(Tile_X3Y2_CO),
    .E1END(Tile_X2Y1_E1BEG),
    .E2MID(Tile_X2Y1_E2BEG),
    .E2END(Tile_X2Y1_E2BEGb),
    .S1END(Tile_X3Y0_S1BEG),
    .S2MID(Tile_X3Y0_S2BEG),
    .S2END(Tile_X3Y0_S2BEGb),
    .W1END(Tile_X4Y1_W1BEG),
    .W2MID(Tile_X4Y1_W2BEG),
    .W2END(Tile_X4Y1_W2BEGb),
    .N_GBUF_BEG(Tile_X3Y1_N_GBUF_BEG),
    .N1BEG(Tile_X3Y1_N1BEG),
    .N2BEG(Tile_X3Y1_N2BEG),
    .N2BEGb(Tile_X3Y1_N2BEGb),
    .E1BEG(Tile_X3Y1_E1BEG),
    .E2BEG(Tile_X3Y1_E2BEG),
    .E2BEGb(Tile_X3Y1_E2BEGb),
    .S1BEG(Tile_X3Y1_S1BEG),
    .S2BEG(Tile_X3Y1_S2BEG),
    .S2BEGb(Tile_X3Y1_S2BEGb),
    .W1BEG(Tile_X3Y1_W1BEG),
    .W2BEG(Tile_X3Y1_W2BEG),
    .W2BEGb(Tile_X3Y1_W2BEGb),
    .CO(Tile_X3Y1_CO),
    .FrameData(Tile_X2Y1_FrameData_O),
    .FrameData_O(Tile_X3Y1_FrameData_O),
    .FrameStrobe(Tile_X3Y2_FrameStrobe_O),
    .FrameStrobe_O(Tile_X3Y1_FrameStrobe_O)
);


 //tile IO port will get directly connected to top-level tile module
 (* keep *)
(* keep *) E_IO4
`ifdef EMULATION
    #(
    .Emulate_Bitstream(`Tile_X4Y1_Emulate_Bitstream)
    )
`endif
    Tile_X4Y1_E_IO4
    (
    .N_GBUF_END(Tile_X4Y2_N_GBUF_BEG),
    .E1END(Tile_X3Y1_E1BEG),
    .E2MID(Tile_X3Y1_E2BEG),
    .E2END(Tile_X3Y1_E2BEGb),
    .N_GBUF_BEG(Tile_X4Y1_N_GBUF_BEG),
    .W1BEG(Tile_X4Y1_W1BEG),
    .W2BEG(Tile_X4Y1_W2BEG),
    .W2BEGb(Tile_X4Y1_W2BEGb),
    .A_OUT_top(Tile_X4Y1_A_OUT_top),
    .A_IN_top(Tile_X4Y1_A_IN_top),
    .A_EN_top(Tile_X4Y1_A_EN_top),
    .B_OUT_top(Tile_X4Y1_B_OUT_top),
    .B_IN_top(Tile_X4Y1_B_IN_top),
    .B_EN_top(Tile_X4Y1_B_EN_top),
    .C_OUT_top(Tile_X4Y1_C_OUT_top),
    .C_IN_top(Tile_X4Y1_C_IN_top),
    .C_EN_top(Tile_X4Y1_C_EN_top),
    .D_OUT_top(Tile_X4Y1_D_OUT_top),
    .D_IN_top(Tile_X4Y1_D_IN_top),
    .D_EN_top(Tile_X4Y1_D_EN_top),
    .FrameData(Tile_X3Y1_FrameData_O),
    .FrameData_O(Tile_X4Y1_FrameData_O),
    .FrameStrobe(Tile_X4Y2_FrameStrobe_O),
    .FrameStrobe_O(Tile_X4Y1_FrameStrobe_O)
);


 //tile IO port will get directly connected to top-level tile module
 (* keep *)
(* keep *) W_IO2
`ifdef EMULATION
    #(
    .Emulate_Bitstream(`Tile_X0Y2_Emulate_Bitstream)
    )
`endif
    Tile_X0Y2_W_IO2
    (
    .N_GBUF_END(Tile_X0Y3_N_GBUF_BEG),
    .S_GBUF_FEED_END(Tile_X0Y1_S_GBUF_FEED_BEG),
    .W1END(Tile_X1Y2_W1BEG),
    .W2MID(Tile_X1Y2_W2BEG),
    .W2END(Tile_X1Y2_W2BEGb),
    .S_GBUF_FEED_BEG(Tile_X0Y2_S_GBUF_FEED_BEG),
    .N_GBUF_BEG(Tile_X0Y2_N_GBUF_BEG),
    .E1BEG(Tile_X0Y2_E1BEG),
    .E2BEG(Tile_X0Y2_E2BEG),
    .E2BEGb(Tile_X0Y2_E2BEGb),
    .A_OUT_top(Tile_X0Y2_A_OUT_top),
    .A_IN_top(Tile_X0Y2_A_IN_top),
    .A_EN_top(Tile_X0Y2_A_EN_top),
    .B_OUT_top(Tile_X0Y2_B_OUT_top),
    .B_IN_top(Tile_X0Y2_B_IN_top),
    .B_EN_top(Tile_X0Y2_B_EN_top),
    .FrameData(Row_Y2_FrameData),
    .FrameData_O(Tile_X0Y2_FrameData_O),
    .FrameStrobe(Tile_X0Y3_FrameStrobe_O),
    .FrameStrobe_O(Tile_X0Y2_FrameStrobe_O)
);


 //tile IO port will get directly connected to top-level tile module
 (* keep *)
(* keep *) LUT4x8_ha
`ifdef EMULATION
    #(
    .Emulate_Bitstream(`Tile_X1Y2_Emulate_Bitstream)
    )
`endif
    Tile_X1Y2_LUT4x8_ha
    (
    .N_GBUF_END(Tile_X1Y3_N_GBUF_BEG),
    .N1END(Tile_X1Y3_N1BEG),
    .N2MID(Tile_X1Y3_N2BEG),
    .N2END(Tile_X1Y3_N2BEGb),
    .CI(Tile_X1Y3_CO),
    .E1END(Tile_X0Y2_E1BEG),
    .E2MID(Tile_X0Y2_E2BEG),
    .E2END(Tile_X0Y2_E2BEGb),
    .S1END(Tile_X1Y1_S1BEG),
    .S2MID(Tile_X1Y1_S2BEG),
    .S2END(Tile_X1Y1_S2BEGb),
    .W1END(Tile_X2Y2_W1BEG),
    .W2MID(Tile_X2Y2_W2BEG),
    .W2END(Tile_X2Y2_W2BEGb),
    .N_GBUF_BEG(Tile_X1Y2_N_GBUF_BEG),
    .N1BEG(Tile_X1Y2_N1BEG),
    .N2BEG(Tile_X1Y2_N2BEG),
    .N2BEGb(Tile_X1Y2_N2BEGb),
    .E1BEG(Tile_X1Y2_E1BEG),
    .E2BEG(Tile_X1Y2_E2BEG),
    .E2BEGb(Tile_X1Y2_E2BEGb),
    .S1BEG(Tile_X1Y2_S1BEG),
    .S2BEG(Tile_X1Y2_S2BEG),
    .S2BEGb(Tile_X1Y2_S2BEGb),
    .W1BEG(Tile_X1Y2_W1BEG),
    .W2BEG(Tile_X1Y2_W2BEG),
    .W2BEGb(Tile_X1Y2_W2BEGb),
    .CO(Tile_X1Y2_CO),
    .FrameData(Tile_X0Y2_FrameData_O),
    .FrameData_O(Tile_X1Y2_FrameData_O),
    .FrameStrobe(Tile_X1Y3_FrameStrobe_O),
    .FrameStrobe_O(Tile_X1Y2_FrameStrobe_O)
);


 //tile IO port will get directly connected to top-level tile module
 (* keep *)
(* keep *) LUT4x8_ha
`ifdef EMULATION
    #(
    .Emulate_Bitstream(`Tile_X2Y2_Emulate_Bitstream)
    )
`endif
    Tile_X2Y2_LUT4x8_ha
    (
    .N_GBUF_END(Tile_X2Y3_N_GBUF_BEG),
    .N1END(Tile_X2Y3_N1BEG),
    .N2MID(Tile_X2Y3_N2BEG),
    .N2END(Tile_X2Y3_N2BEGb),
    .CI(Tile_X2Y3_CO),
    .E1END(Tile_X1Y2_E1BEG),
    .E2MID(Tile_X1Y2_E2BEG),
    .E2END(Tile_X1Y2_E2BEGb),
    .S1END(Tile_X2Y1_S1BEG),
    .S2MID(Tile_X2Y1_S2BEG),
    .S2END(Tile_X2Y1_S2BEGb),
    .W1END(Tile_X3Y2_W1BEG),
    .W2MID(Tile_X3Y2_W2BEG),
    .W2END(Tile_X3Y2_W2BEGb),
    .N_GBUF_BEG(Tile_X2Y2_N_GBUF_BEG),
    .N1BEG(Tile_X2Y2_N1BEG),
    .N2BEG(Tile_X2Y2_N2BEG),
    .N2BEGb(Tile_X2Y2_N2BEGb),
    .E1BEG(Tile_X2Y2_E1BEG),
    .E2BEG(Tile_X2Y2_E2BEG),
    .E2BEGb(Tile_X2Y2_E2BEGb),
    .S1BEG(Tile_X2Y2_S1BEG),
    .S2BEG(Tile_X2Y2_S2BEG),
    .S2BEGb(Tile_X2Y2_S2BEGb),
    .W1BEG(Tile_X2Y2_W1BEG),
    .W2BEG(Tile_X2Y2_W2BEG),
    .W2BEGb(Tile_X2Y2_W2BEGb),
    .CO(Tile_X2Y2_CO),
    .FrameData(Tile_X1Y2_FrameData_O),
    .FrameData_O(Tile_X2Y2_FrameData_O),
    .FrameStrobe(Tile_X2Y3_FrameStrobe_O),
    .FrameStrobe_O(Tile_X2Y2_FrameStrobe_O)
);


 //tile IO port will get directly connected to top-level tile module
 (* keep *)
(* keep *) LUT4x8_ha
`ifdef EMULATION
    #(
    .Emulate_Bitstream(`Tile_X3Y2_Emulate_Bitstream)
    )
`endif
    Tile_X3Y2_LUT4x8_ha
    (
    .N_GBUF_END(Tile_X3Y3_N_GBUF_BEG),
    .N1END(Tile_X3Y3_N1BEG),
    .N2MID(Tile_X3Y3_N2BEG),
    .N2END(Tile_X3Y3_N2BEGb),
    .CI(Tile_X3Y3_CO),
    .E1END(Tile_X2Y2_E1BEG),
    .E2MID(Tile_X2Y2_E2BEG),
    .E2END(Tile_X2Y2_E2BEGb),
    .S1END(Tile_X3Y1_S1BEG),
    .S2MID(Tile_X3Y1_S2BEG),
    .S2END(Tile_X3Y1_S2BEGb),
    .W1END(Tile_X4Y2_W1BEG),
    .W2MID(Tile_X4Y2_W2BEG),
    .W2END(Tile_X4Y2_W2BEGb),
    .N_GBUF_BEG(Tile_X3Y2_N_GBUF_BEG),
    .N1BEG(Tile_X3Y2_N1BEG),
    .N2BEG(Tile_X3Y2_N2BEG),
    .N2BEGb(Tile_X3Y2_N2BEGb),
    .E1BEG(Tile_X3Y2_E1BEG),
    .E2BEG(Tile_X3Y2_E2BEG),
    .E2BEGb(Tile_X3Y2_E2BEGb),
    .S1BEG(Tile_X3Y2_S1BEG),
    .S2BEG(Tile_X3Y2_S2BEG),
    .S2BEGb(Tile_X3Y2_S2BEGb),
    .W1BEG(Tile_X3Y2_W1BEG),
    .W2BEG(Tile_X3Y2_W2BEG),
    .W2BEGb(Tile_X3Y2_W2BEGb),
    .CO(Tile_X3Y2_CO),
    .FrameData(Tile_X2Y2_FrameData_O),
    .FrameData_O(Tile_X3Y2_FrameData_O),
    .FrameStrobe(Tile_X3Y3_FrameStrobe_O),
    .FrameStrobe_O(Tile_X3Y2_FrameStrobe_O)
);


 //tile IO port will get directly connected to top-level tile module
 (* keep *)
(* keep *) E_term
`ifdef EMULATION
    #(
    .Emulate_Bitstream(`Tile_X4Y2_Emulate_Bitstream)
    )
`endif
    Tile_X4Y2_E_term
    (
    .N_GBUF_END(Tile_X4Y3_N_GBUF_BEG),
    .E1END(Tile_X3Y2_E1BEG),
    .E2MID(Tile_X3Y2_E2BEG),
    .E2END(Tile_X3Y2_E2BEGb),
    .N_GBUF_BEG(Tile_X4Y2_N_GBUF_BEG),
    .W1BEG(Tile_X4Y2_W1BEG),
    .W2BEG(Tile_X4Y2_W2BEG),
    .W2BEGb(Tile_X4Y2_W2BEGb),
    .FrameData(Tile_X3Y2_FrameData_O),
    .FrameData_O(Tile_X4Y2_FrameData_O),
    .FrameStrobe(Tile_X4Y3_FrameStrobe_O),
    .FrameStrobe_O(Tile_X4Y2_FrameStrobe_O)
);


 //tile IO port will get directly connected to top-level tile module
 (* keep *)
(* keep *) W_IO4
`ifdef EMULATION
    #(
    .Emulate_Bitstream(`Tile_X0Y3_Emulate_Bitstream)
    )
`endif
    Tile_X0Y3_W_IO4
    (
    .N_GBUF_END(Tile_X0Y4_N_GBUF_BEG),
    .S_GBUF_FEED_END(Tile_X0Y2_S_GBUF_FEED_BEG),
    .W1END(Tile_X1Y3_W1BEG),
    .W2MID(Tile_X1Y3_W2BEG),
    .W2END(Tile_X1Y3_W2BEGb),
    .S_GBUF_FEED_BEG(Tile_X0Y3_S_GBUF_FEED_BEG),
    .N_GBUF_BEG(Tile_X0Y3_N_GBUF_BEG),
    .E1BEG(Tile_X0Y3_E1BEG),
    .E2BEG(Tile_X0Y3_E2BEG),
    .E2BEGb(Tile_X0Y3_E2BEGb),
    .A_OUT_top(Tile_X0Y3_A_OUT_top),
    .A_IN_top(Tile_X0Y3_A_IN_top),
    .A_EN_top(Tile_X0Y3_A_EN_top),
    .B_OUT_top(Tile_X0Y3_B_OUT_top),
    .B_IN_top(Tile_X0Y3_B_IN_top),
    .B_EN_top(Tile_X0Y3_B_EN_top),
    .C_OUT_top(Tile_X0Y3_C_OUT_top),
    .C_IN_top(Tile_X0Y3_C_IN_top),
    .C_EN_top(Tile_X0Y3_C_EN_top),
    .D_OUT_top(Tile_X0Y3_D_OUT_top),
    .D_IN_top(Tile_X0Y3_D_IN_top),
    .D_EN_top(Tile_X0Y3_D_EN_top),
    .FrameData(Row_Y3_FrameData),
    .FrameData_O(Tile_X0Y3_FrameData_O),
    .FrameStrobe(Tile_X0Y4_FrameStrobe_O),
    .FrameStrobe_O(Tile_X0Y3_FrameStrobe_O)
);


 //tile IO port will get directly connected to top-level tile module
 (* keep *)
(* keep *) LUT4x8_ha
`ifdef EMULATION
    #(
    .Emulate_Bitstream(`Tile_X1Y3_Emulate_Bitstream)
    )
`endif
    Tile_X1Y3_LUT4x8_ha
    (
    .N_GBUF_END(Tile_X1Y4_N_GBUF_BEG),
    .N1END(Tile_X1Y4_N1BEG),
    .N2MID(Tile_X1Y4_N2BEG),
    .N2END(Tile_X1Y4_N2BEGb),
    .CI(Tile_X1Y4_Co),
    .E1END(Tile_X0Y3_E1BEG),
    .E2MID(Tile_X0Y3_E2BEG),
    .E2END(Tile_X0Y3_E2BEGb),
    .S1END(Tile_X1Y2_S1BEG),
    .S2MID(Tile_X1Y2_S2BEG),
    .S2END(Tile_X1Y2_S2BEGb),
    .W1END(Tile_X2Y3_W1BEG),
    .W2MID(Tile_X2Y3_W2BEG),
    .W2END(Tile_X2Y3_W2BEGb),
    .N_GBUF_BEG(Tile_X1Y3_N_GBUF_BEG),
    .N1BEG(Tile_X1Y3_N1BEG),
    .N2BEG(Tile_X1Y3_N2BEG),
    .N2BEGb(Tile_X1Y3_N2BEGb),
    .E1BEG(Tile_X1Y3_E1BEG),
    .E2BEG(Tile_X1Y3_E2BEG),
    .E2BEGb(Tile_X1Y3_E2BEGb),
    .S1BEG(Tile_X1Y3_S1BEG),
    .S2BEG(Tile_X1Y3_S2BEG),
    .S2BEGb(Tile_X1Y3_S2BEGb),
    .W1BEG(Tile_X1Y3_W1BEG),
    .W2BEG(Tile_X1Y3_W2BEG),
    .W2BEGb(Tile_X1Y3_W2BEGb),
    .CO(Tile_X1Y3_CO),
    .FrameData(Tile_X0Y3_FrameData_O),
    .FrameData_O(Tile_X1Y3_FrameData_O),
    .FrameStrobe(Tile_X1Y4_FrameStrobe_O),
    .FrameStrobe_O(Tile_X1Y3_FrameStrobe_O)
);


 //tile IO port will get directly connected to top-level tile module
 (* keep *)
(* keep *) LUT4x8_ha
`ifdef EMULATION
    #(
    .Emulate_Bitstream(`Tile_X2Y3_Emulate_Bitstream)
    )
`endif
    Tile_X2Y3_LUT4x8_ha
    (
    .N_GBUF_END(Tile_X2Y4_N_GBUF_BEG),
    .N1END(Tile_X2Y4_N1BEG),
    .N2MID(Tile_X2Y4_N2BEG),
    .N2END(Tile_X2Y4_N2BEGb),
    .CI(Tile_X2Y4_Co),
    .E1END(Tile_X1Y3_E1BEG),
    .E2MID(Tile_X1Y3_E2BEG),
    .E2END(Tile_X1Y3_E2BEGb),
    .S1END(Tile_X2Y2_S1BEG),
    .S2MID(Tile_X2Y2_S2BEG),
    .S2END(Tile_X2Y2_S2BEGb),
    .W1END(Tile_X3Y3_W1BEG),
    .W2MID(Tile_X3Y3_W2BEG),
    .W2END(Tile_X3Y3_W2BEGb),
    .N_GBUF_BEG(Tile_X2Y3_N_GBUF_BEG),
    .N1BEG(Tile_X2Y3_N1BEG),
    .N2BEG(Tile_X2Y3_N2BEG),
    .N2BEGb(Tile_X2Y3_N2BEGb),
    .E1BEG(Tile_X2Y3_E1BEG),
    .E2BEG(Tile_X2Y3_E2BEG),
    .E2BEGb(Tile_X2Y3_E2BEGb),
    .S1BEG(Tile_X2Y3_S1BEG),
    .S2BEG(Tile_X2Y3_S2BEG),
    .S2BEGb(Tile_X2Y3_S2BEGb),
    .W1BEG(Tile_X2Y3_W1BEG),
    .W2BEG(Tile_X2Y3_W2BEG),
    .W2BEGb(Tile_X2Y3_W2BEGb),
    .CO(Tile_X2Y3_CO),
    .FrameData(Tile_X1Y3_FrameData_O),
    .FrameData_O(Tile_X2Y3_FrameData_O),
    .FrameStrobe(Tile_X2Y4_FrameStrobe_O),
    .FrameStrobe_O(Tile_X2Y3_FrameStrobe_O)
);


 //tile IO port will get directly connected to top-level tile module
 (* keep *)
(* keep *) LUT4x8_ha
`ifdef EMULATION
    #(
    .Emulate_Bitstream(`Tile_X3Y3_Emulate_Bitstream)
    )
`endif
    Tile_X3Y3_LUT4x8_ha
    (
    .N_GBUF_END(Tile_X3Y4_N_GBUF_BEG),
    .N1END(Tile_X3Y4_N1BEG),
    .N2MID(Tile_X3Y4_N2BEG),
    .N2END(Tile_X3Y4_N2BEGb),
    .CI(Tile_X3Y4_Co),
    .E1END(Tile_X2Y3_E1BEG),
    .E2MID(Tile_X2Y3_E2BEG),
    .E2END(Tile_X2Y3_E2BEGb),
    .S1END(Tile_X3Y2_S1BEG),
    .S2MID(Tile_X3Y2_S2BEG),
    .S2END(Tile_X3Y2_S2BEGb),
    .W1END(Tile_X4Y3_W1BEG),
    .W2MID(Tile_X4Y3_W2BEG),
    .W2END(Tile_X4Y3_W2BEGb),
    .N_GBUF_BEG(Tile_X3Y3_N_GBUF_BEG),
    .N1BEG(Tile_X3Y3_N1BEG),
    .N2BEG(Tile_X3Y3_N2BEG),
    .N2BEGb(Tile_X3Y3_N2BEGb),
    .E1BEG(Tile_X3Y3_E1BEG),
    .E2BEG(Tile_X3Y3_E2BEG),
    .E2BEGb(Tile_X3Y3_E2BEGb),
    .S1BEG(Tile_X3Y3_S1BEG),
    .S2BEG(Tile_X3Y3_S2BEG),
    .S2BEGb(Tile_X3Y3_S2BEGb),
    .W1BEG(Tile_X3Y3_W1BEG),
    .W2BEG(Tile_X3Y3_W2BEG),
    .W2BEGb(Tile_X3Y3_W2BEGb),
    .CO(Tile_X3Y3_CO),
    .FrameData(Tile_X2Y3_FrameData_O),
    .FrameData_O(Tile_X3Y3_FrameData_O),
    .FrameStrobe(Tile_X3Y4_FrameStrobe_O),
    .FrameStrobe_O(Tile_X3Y3_FrameStrobe_O)
);


 //tile IO port will get directly connected to top-level tile module
 (* keep *)
(* keep *) E_IO4
`ifdef EMULATION
    #(
    .Emulate_Bitstream(`Tile_X4Y3_Emulate_Bitstream)
    )
`endif
    Tile_X4Y3_E_IO4
    (
    .N_GBUF_END(Tile_X4Y4_N_GBUF_BEG),
    .E1END(Tile_X3Y3_E1BEG),
    .E2MID(Tile_X3Y3_E2BEG),
    .E2END(Tile_X3Y3_E2BEGb),
    .N_GBUF_BEG(Tile_X4Y3_N_GBUF_BEG),
    .W1BEG(Tile_X4Y3_W1BEG),
    .W2BEG(Tile_X4Y3_W2BEG),
    .W2BEGb(Tile_X4Y3_W2BEGb),
    .A_OUT_top(Tile_X4Y3_A_OUT_top),
    .A_IN_top(Tile_X4Y3_A_IN_top),
    .A_EN_top(Tile_X4Y3_A_EN_top),
    .B_OUT_top(Tile_X4Y3_B_OUT_top),
    .B_IN_top(Tile_X4Y3_B_IN_top),
    .B_EN_top(Tile_X4Y3_B_EN_top),
    .C_OUT_top(Tile_X4Y3_C_OUT_top),
    .C_IN_top(Tile_X4Y3_C_IN_top),
    .C_EN_top(Tile_X4Y3_C_EN_top),
    .D_OUT_top(Tile_X4Y3_D_OUT_top),
    .D_IN_top(Tile_X4Y3_D_IN_top),
    .D_EN_top(Tile_X4Y3_D_EN_top),
    .FrameData(Tile_X3Y3_FrameData_O),
    .FrameData_O(Tile_X4Y3_FrameData_O),
    .FrameStrobe(Tile_X4Y4_FrameStrobe_O),
    .FrameStrobe_O(Tile_X4Y3_FrameStrobe_O)
);


 //tile IO port will get directly connected to top-level tile module
 (* keep *)
(* keep *) SW_term
`ifdef EMULATION
    #(
    .Emulate_Bitstream(`Tile_X0Y4_Emulate_Bitstream)
    )
`endif
    Tile_X0Y4_SW_term
    (
    .S_GBUF_FEED_END(Tile_X0Y3_S_GBUF_FEED_BEG),
    .W_GBUF_FEED_END(Tile_X1Y4_W_GBUF_FEED_BEG),
    .N_GBUF_BEG(Tile_X0Y4_N_GBUF_BEG),
    .E_GBUF_BEG(Tile_X0Y4_E_GBUF_BEG),
    .SYS_RESET_RESET_top(Tile_X0Y4_SYS_RESET_RESET_top),
    .FrameData(Row_Y4_FrameData),
    .FrameData_O(Tile_X0Y4_FrameData_O),
    .FrameStrobe(Column_X0_FrameStrobe),
    .FrameStrobe_O(Tile_X0Y4_FrameStrobe_O)
);


 //tile IO port will get directly connected to top-level tile module
 (* keep *)
(* keep *) S_IO4
`ifdef EMULATION
    #(
    .Emulate_Bitstream(`Tile_X1Y4_Emulate_Bitstream)
    )
`endif
    Tile_X1Y4_S_IO4
    (
    .E_GBUF_END(Tile_X0Y4_E_GBUF_BEG),
    .S1END(Tile_X1Y3_S1BEG),
    .S2MID(Tile_X1Y3_S2BEG),
    .S2END(Tile_X1Y3_S2BEGb),
    .W_GBUF_FEED_END(Tile_X2Y4_W_GBUF_FEED_BEG),
    .W_GBUF_FEED_BEG(Tile_X1Y4_W_GBUF_FEED_BEG),
    .N_GBUF_BEG(Tile_X1Y4_N_GBUF_BEG),
    .E_GBUF_BEG(Tile_X1Y4_E_GBUF_BEG),
    .N1BEG(Tile_X1Y4_N1BEG),
    .N2BEG(Tile_X1Y4_N2BEG),
    .N2BEGb(Tile_X1Y4_N2BEGb),
    .Co(Tile_X1Y4_Co),
    .A_OUT_top(Tile_X1Y4_A_OUT_top),
    .A_IN_top(Tile_X1Y4_A_IN_top),
    .A_EN_top(Tile_X1Y4_A_EN_top),
    .B_OUT_top(Tile_X1Y4_B_OUT_top),
    .B_IN_top(Tile_X1Y4_B_IN_top),
    .B_EN_top(Tile_X1Y4_B_EN_top),
    .C_OUT_top(Tile_X1Y4_C_OUT_top),
    .C_IN_top(Tile_X1Y4_C_IN_top),
    .C_EN_top(Tile_X1Y4_C_EN_top),
    .D_OUT_top(Tile_X1Y4_D_OUT_top),
    .D_IN_top(Tile_X1Y4_D_IN_top),
    .D_EN_top(Tile_X1Y4_D_EN_top),
    .FrameData(Tile_X0Y4_FrameData_O),
    .FrameData_O(Tile_X1Y4_FrameData_O),
    .FrameStrobe(Column_X1_FrameStrobe),
    .FrameStrobe_O(Tile_X1Y4_FrameStrobe_O)
);


 //tile IO port will get directly connected to top-level tile module
 (* keep *)
(* keep *) S_term
`ifdef EMULATION
    #(
    .Emulate_Bitstream(`Tile_X2Y4_Emulate_Bitstream)
    )
`endif
    Tile_X2Y4_S_term
    (
    .E_GBUF_END(Tile_X1Y4_E_GBUF_BEG),
    .S1END(Tile_X2Y3_S1BEG),
    .S2MID(Tile_X2Y3_S2BEG),
    .S2END(Tile_X2Y3_S2BEGb),
    .W_GBUF_FEED_END(Tile_X3Y4_W_GBUF_FEED_BEG),
    .W_GBUF_FEED_BEG(Tile_X2Y4_W_GBUF_FEED_BEG),
    .N_GBUF_BEG(Tile_X2Y4_N_GBUF_BEG),
    .E_GBUF_BEG(Tile_X2Y4_E_GBUF_BEG),
    .N1BEG(Tile_X2Y4_N1BEG),
    .N2BEG(Tile_X2Y4_N2BEG),
    .N2BEGb(Tile_X2Y4_N2BEGb),
    .Co(Tile_X2Y4_Co),
    .FrameData(Tile_X1Y4_FrameData_O),
    .FrameData_O(Tile_X2Y4_FrameData_O),
    .FrameStrobe(Column_X2_FrameStrobe),
    .FrameStrobe_O(Tile_X2Y4_FrameStrobe_O)
);


 //tile IO port will get directly connected to top-level tile module
 (* keep *)
(* keep *) S_IO4
`ifdef EMULATION
    #(
    .Emulate_Bitstream(`Tile_X3Y4_Emulate_Bitstream)
    )
`endif
    Tile_X3Y4_S_IO4
    (
    .E_GBUF_END(Tile_X2Y4_E_GBUF_BEG),
    .S1END(Tile_X3Y3_S1BEG),
    .S2MID(Tile_X3Y3_S2BEG),
    .S2END(Tile_X3Y3_S2BEGb),
    .W_GBUF_FEED_END(Tile_X4Y4_W_GBUF_FEED_BEG),
    .W_GBUF_FEED_BEG(Tile_X3Y4_W_GBUF_FEED_BEG),
    .N_GBUF_BEG(Tile_X3Y4_N_GBUF_BEG),
    .E_GBUF_BEG(Tile_X3Y4_E_GBUF_BEG),
    .N1BEG(Tile_X3Y4_N1BEG),
    .N2BEG(Tile_X3Y4_N2BEG),
    .N2BEGb(Tile_X3Y4_N2BEGb),
    .Co(Tile_X3Y4_Co),
    .A_OUT_top(Tile_X3Y4_A_OUT_top),
    .A_IN_top(Tile_X3Y4_A_IN_top),
    .A_EN_top(Tile_X3Y4_A_EN_top),
    .B_OUT_top(Tile_X3Y4_B_OUT_top),
    .B_IN_top(Tile_X3Y4_B_IN_top),
    .B_EN_top(Tile_X3Y4_B_EN_top),
    .C_OUT_top(Tile_X3Y4_C_OUT_top),
    .C_IN_top(Tile_X3Y4_C_IN_top),
    .C_EN_top(Tile_X3Y4_C_EN_top),
    .D_OUT_top(Tile_X3Y4_D_OUT_top),
    .D_IN_top(Tile_X3Y4_D_IN_top),
    .D_EN_top(Tile_X3Y4_D_EN_top),
    .FrameData(Tile_X2Y4_FrameData_O),
    .FrameData_O(Tile_X3Y4_FrameData_O),
    .FrameStrobe(Column_X3_FrameStrobe),
    .FrameStrobe_O(Tile_X3Y4_FrameStrobe_O)
);


 //tile IO port will get directly connected to top-level tile module
 (* keep *)
(* keep *) SE_term
`ifdef EMULATION
    #(
    .Emulate_Bitstream(`Tile_X4Y4_Emulate_Bitstream)
    )
`endif
    Tile_X4Y4_SE_term
    (
    .E_GBUF_END(Tile_X3Y4_E_GBUF_BEG),
    .W_GBUF_FEED_BEG(Tile_X4Y4_W_GBUF_FEED_BEG),
    .N_GBUF_BEG(Tile_X4Y4_N_GBUF_BEG),
    .FrameData(Tile_X3Y4_FrameData_O),
    .FrameData_O(Tile_X4Y4_FrameData_O),
    .FrameStrobe(Column_X4_FrameStrobe),
    .FrameStrobe_O(Tile_X4Y4_FrameStrobe_O)
);

endmodule
