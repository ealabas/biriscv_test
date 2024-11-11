`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.11.2024 21:21:03
// Design Name: 
// Module Name: biriscv_v_xilinx_2r1w
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module biriscv_v_xilinx_2r1w
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter VLEN = 128
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input  [  4:0]  rd0_i
    ,input  [ VLEN - 1:0]  rd0_value_i
    ,input  [  4:0]  ra_i
    ,input  [  4:0]  rb_i

    // Outputs
    ,output [ VLEN - 1:0]  ra_value_o
    ,output [ VLEN - 1:0]  rb_value_o
);


//-----------------------------------------------------------------
// Registers / Wires
//-----------------------------------------------------------------
wire [VLEN - 1:0]     reg_rs1_w;
wire [VLEN - 1:0]     reg_rs2_w;
wire [VLEN - 1:0]     rs1_0_15_w;
wire [VLEN - 1:0]     rs1_16_31_w;
wire [VLEN - 1:0]     rs2_0_15_w;
wire [VLEN - 1:0]     rs2_16_31_w;
wire            write_enable_w;
wire            write_banka_w;
wire            write_bankb_w;

//-----------------------------------------------------------------
// Register File (using RAM16X1D )
//-----------------------------------------------------------------
genvar i;

// Registers 0 - 15
generate
for (i=0;i<VLEN;i=i+1)
begin : reg_loop1
    RAM16X1D reg_bit1a(.WCLK(clk_i), .WE(write_banka_w), .A0(rd0_i[0]), .A1(rd0_i[1]), .A2(rd0_i[2]), .A3(rd0_i[3]), .D(rd0_value_i[i]), 
    .DPRA0(ra_i[0]), .DPRA1(ra_i[1]), .DPRA2(ra_i[2]), .DPRA3(ra_i[3]), .DPO(rs1_0_15_w[i]), .SPO(/* open */));
    RAM16X1D reg_bit2a(.WCLK(clk_i), .WE(write_banka_w), .A0(rd0_i[0]), .A1(rd0_i[1]), .A2(rd0_i[2]), .A3(rd0_i[3]), .D(rd0_value_i[i]), 
    .DPRA0(rb_i[0]), .DPRA1(rb_i[1]), .DPRA2(rb_i[2]), .DPRA3(rb_i[3]), .DPO(rs2_0_15_w[i]), .SPO(/* open */));
end
endgenerate

// Registers 16 - 31
generate
for (i=0;i<VLEN;i=i+1)
begin : reg_loop2
    RAM16X1D reg_bit1b(.WCLK(clk_i), .WE(write_bankb_w), .A0(rd0_i[0]), .A1(rd0_i[1]), .A2(rd0_i[2]), .A3(rd0_i[3]), .D(rd0_value_i[i]), 
    .DPRA0(ra_i[0]), .DPRA1(ra_i[1]), .DPRA2(ra_i[2]), .DPRA3(ra_i[3]), .DPO(rs1_16_31_w[i]), .SPO(/* open */));
    RAM16X1D reg_bit2b(.WCLK(clk_i), .WE(write_bankb_w), .A0(rd0_i[0]), .A1(rd0_i[1]), .A2(rd0_i[2]), .A3(rd0_i[3]), .D(rd0_value_i[i]), 
    .DPRA0(rb_i[0]), .DPRA1(rb_i[1]), .DPRA2(rb_i[2]), .DPRA3(rb_i[3]), .DPO(rs2_16_31_w[i]), .SPO(/* open */));
end
endgenerate

//-----------------------------------------------------------------
// Combinatorial Assignments
//-----------------------------------------------------------------
assign reg_rs1_w       = (ra_i[4] == 1'b0) ? rs1_0_15_w : rs1_16_31_w;
assign reg_rs2_w       = (rb_i[4] == 1'b0) ? rs2_0_15_w : rs2_16_31_w;

assign write_enable_w = (rd0_i != 5'b00000);

assign write_banka_w  = (write_enable_w & (~rd0_i[4])); 
assign write_bankb_w  = (write_enable_w & rd0_i[4]); 
 
reg [VLEN - 1:0] ra_value_r; 
reg [VLEN - 1:0] rb_value_r; 
 
// Register read ports
always @ *
begin
    if (ra_i == 5'b00000)
        ra_value_r = {VLEN{1'b0}};
    else
        ra_value_r = reg_rs1_w;

    if (rb_i == 5'b00000)
        rb_value_r = {VLEN{1'b0}};
    else
        rb_value_r = reg_rs2_w;
end

assign ra_value_o = ra_value_r;
assign rb_value_o = rb_value_r;

endmodule

//-------------------------------------------------------------
// RAM16X1D: Verilator target RAM16X1D model
//-------------------------------------------------------------
`ifdef verilator
module RAM16X1D (DPO, SPO, A0, A1, A2, A3, D, DPRA0, DPRA1, DPRA2, DPRA3, WCLK, WE);

    parameter INIT = 16'h0000;

    output DPO, SPO;

    input  A0, A1, A2, A3, D, DPRA0, DPRA1, DPRA2, DPRA3, WCLK, WE;

    reg  [15:0] mem;
    wire [3:0] adr;

    assign adr = {A3, A2, A1, A0};
    assign SPO = mem[adr];
    assign DPO = mem[{DPRA3, DPRA2, DPRA1, DPRA0}];

    initial 
        mem = INIT;

    always @(posedge WCLK) 
        if (WE == 1'b1)
            mem[adr] <= D;

endmodule
`endif

