`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.11.2024 21:16:36
// Design Name: 
// Module Name: biriscv_v_regfile
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

module biriscv_v_regfile
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter SUPPORT_REGFILE_XILINX = 0,
     parameter SUPPORT_DUAL_ISSUE = 1,
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
    ,input  [  4:0]  rd1_i
    ,input  [ VLEN - 1:0]  rd0_value_i
    ,input  [ VLEN - 1:0]  rd1_value_i
    ,input  [  4:0]  ra0_i
    ,input  [  4:0]  rb0_i
    ,input  [  4:0]  ra1_i
    ,input  [  4:0]  rb1_i

    // Outputs
    ,output [ VLEN - 1:0]  ra0_value_o
    ,output [ VLEN - 1:0]  rb0_value_o
    ,output [ VLEN - 1:0]  ra1_value_o
    ,output [ VLEN - 1:0]  rb1_value_o
);

//-----------------------------------------------------------------
// Xilinx specific register file (dual issue)
//-----------------------------------------------------------------
generate
if (SUPPORT_REGFILE_XILINX && SUPPORT_DUAL_ISSUE)
begin: REGFILE_XILINX
    wire [VLEN - 1:0] ra0_value_w[1:0];
    wire [VLEN - 1:0] rb0_value_w[1:0];
    wire [VLEN - 1:0] ra1_value_w[1:0];
    wire [VLEN - 1:0] rb1_value_w[1:0];

    biriscv_v_xilinx_2r1w#(
        .VLEN(VLEN)
    )
    u_a_0
    (
        // Inputs
         .clk_i(clk_i)
        ,.rst_i(rst_i)
        ,.rd0_i(rd0_i)
        ,.rd0_value_i(rd0_value_i)
        ,.ra_i(ra0_i)
        ,.rb_i(rb0_i)

        // Outputs
        ,.ra_value_o(ra0_value_w[0])
        ,.rb_value_o(rb0_value_w[0])
    );

    biriscv_v_xilinx_2r1w#(
        .VLEN(VLEN)
    )
    u_a_1
    (
        // Inputs
         .clk_i(clk_i)
        ,.rst_i(rst_i)
        ,.rd0_i(rd1_i)
        ,.rd0_value_i(rd1_value_i)
        ,.ra_i(ra0_i)
        ,.rb_i(rb0_i)

        // Outputs
        ,.ra_value_o(ra0_value_w[1])
        ,.rb_value_o(rb0_value_w[1])
    );

    biriscv_v_xilinx_2r1w#(
        .VLEN(VLEN)
    )
    u_b_0
    (
        // Inputs
         .clk_i(clk_i)
        ,.rst_i(rst_i)
        ,.rd0_i(rd0_i)
        ,.rd0_value_i(rd0_value_i)
        ,.ra_i(ra1_i)
        ,.rb_i(rb1_i)

        // Outputs
        ,.ra_value_o(ra1_value_w[0])
        ,.rb_value_o(rb1_value_w[0])
    );

    biriscv_v_xilinx_2r1w#(
        .VLEN(VLEN)
    )
    u_b_1
    (
        // Inputs
         .clk_i(clk_i)
        ,.rst_i(rst_i)
        ,.rd0_i(rd1_i)
        ,.rd0_value_i(rd1_value_i)
        ,.ra_i(ra1_i)
        ,.rb_i(rb1_i)

        // Outputs
        ,.ra_value_o(ra1_value_w[1])
        ,.rb_value_o(rb1_value_w[1])
    );

    // Track latest register write 
    reg [31:0] reg_src_q;
    reg [31:0] reg_src_r;

    always @ *
    begin
        reg_src_r = reg_src_q;

        reg_src_r[rd0_i] = 1'b0;
        reg_src_r[rd1_i] = 1'b1;

        // Ignore register 0
        reg_src_r[0] = 1'b0;
    end 

    always @ (posedge clk_i or posedge rst_i)
    if (rst_i)
        reg_src_q <= 32'b0;
    else
        reg_src_q <= reg_src_r;


    assign ra0_value_o = reg_src_q[ra0_i] ? ra0_value_w[1] : ra0_value_w[0];
    assign rb0_value_o = reg_src_q[rb0_i] ? rb0_value_w[1] : rb0_value_w[0];
    assign ra1_value_o = reg_src_q[ra1_i] ? ra1_value_w[1] : ra1_value_w[0];
    assign rb1_value_o = reg_src_q[rb1_i] ? rb1_value_w[1] : rb1_value_w[0];
end
//-----------------------------------------------------------------
// Xilinx specific register file (single issue)
//-----------------------------------------------------------------
else if (SUPPORT_REGFILE_XILINX && !SUPPORT_DUAL_ISSUE)
begin: REGFILE_XILINX_SINGLE

    biriscv_v_xilinx_2r1w#(
        .VLEN(VLEN)
    )
    u_reg
    (
        // Inputs
         .clk_i(clk_i)
        ,.rst_i(rst_i)
        ,.rd0_i(rd0_i)
        ,.rd0_value_i(rd0_value_i)
        ,.ra_i(ra0_i)
        ,.rb_i(rb0_i)

        // Outputs
        ,.ra_value_o(ra0_value_o)
        ,.rb_value_o(rb0_value_o)
    );

    assign ra1_value_o = 32'b0;
    assign rb1_value_o = 32'b0;
end
//-----------------------------------------------------------------
// Flop based register file
//-----------------------------------------------------------------
else
begin: REGFILE
    reg [VLEN-1:0] reg_v0_q;
    reg [VLEN-1:0] reg_v1_q;
    reg [VLEN-1:0] reg_v2_q;
    reg [VLEN-1:0] reg_v3_q;
    reg [VLEN-1:0] reg_v4_q;
    reg [VLEN-1:0] reg_v5_q;
    reg [VLEN-1:0] reg_v6_q;
    reg [VLEN-1:0] reg_v7_q;
    reg [VLEN-1:0] reg_v8_q;
    reg [VLEN-1:0] reg_v9_q;
    reg [VLEN-1:0] reg_v10_q;
    reg [VLEN-1:0] reg_v11_q;
    reg [VLEN-1:0] reg_v12_q;
    reg [VLEN-1:0] reg_v13_q;
    reg [VLEN-1:0] reg_v14_q;
    reg [VLEN-1:0] reg_v15_q;
    reg [VLEN-1:0] reg_v16_q;
    reg [VLEN-1:0] reg_v17_q;
    reg [VLEN-1:0] reg_v18_q;
    reg [VLEN-1:0] reg_v19_q;
    reg [VLEN-1:0] reg_v20_q;
    reg [VLEN-1:0] reg_v21_q;
    reg [VLEN-1:0] reg_v22_q;
    reg [VLEN-1:0] reg_v23_q;
    reg [VLEN-1:0] reg_v24_q;
    reg [VLEN-1:0] reg_v25_q;
    reg [VLEN-1:0] reg_v26_q;
    reg [VLEN-1:0] reg_v27_q;
    reg [VLEN-1:0] reg_v28_q;
    reg [VLEN-1:0] reg_v29_q;
    reg [VLEN-1:0] reg_v30_q;
    reg [VLEN-1:0] reg_v31_q;


    // Simulation-friendly names
    wire [VLEN-1:0] x0_v0_w   = reg_v0_q;
    wire [VLEN-1:0] x1_v1_w   = reg_v1_q;
    wire [VLEN-1:0] x2_v2_w   = reg_v2_q;
    wire [VLEN-1:0] x3_v3_w   = reg_v3_q;
    wire [VLEN-1:0] x4_v4_w   = reg_v4_q;
    wire [VLEN-1:0] x5_v5_w   = reg_v5_q;
    wire [VLEN-1:0] x6_v6_w   = reg_v6_q;
    wire [VLEN-1:0] x7_v7_w   = reg_v7_q;
    wire [VLEN-1:0] x8_v8_w   = reg_v8_q;
    wire [VLEN-1:0] x9_v9_w   = reg_v9_q;
    wire [VLEN-1:0] x10_v10_w = reg_v10_q;
    wire [VLEN-1:0] x11_v11_w = reg_v11_q;
    wire [VLEN-1:0] x12_v12_w = reg_v12_q;
    wire [VLEN-1:0] x13_v13_w = reg_v13_q;
    wire [VLEN-1:0] x14_v14_w = reg_v14_q;
    wire [VLEN-1:0] x15_v15_w = reg_v15_q;
    wire [VLEN-1:0] x16_v16_w = reg_v16_q;
    wire [VLEN-1:0] x17_v17_w = reg_v17_q;
    wire [VLEN-1:0] x18_v18_w = reg_v18_q;
    wire [VLEN-1:0] x19_v19_w = reg_v19_q;
    wire [VLEN-1:0] x20_v20_w = reg_v20_q;
    wire [VLEN-1:0] x21_v21_w = reg_v21_q;
    wire [VLEN-1:0] x22_v22_w = reg_v22_q;
    wire [VLEN-1:0] x23_v23_w = reg_v23_q;
    wire [VLEN-1:0] x24_v24_w = reg_v24_q;
    wire [VLEN-1:0] x25_v25_w = reg_v25_q;
    wire [VLEN-1:0] x26_v26_w = reg_v26_q;
    wire [VLEN-1:0] x27_v27_w = reg_v27_q;
    wire [VLEN-1:0] x28_v28_w = reg_v28_q;
    wire [VLEN-1:0] x29_v29_w = reg_v29_q;
    wire [VLEN-1:0] x30_v30_w = reg_v30_q;
    wire [VLEN-1:0] x31_v31_w = reg_v31_q;


    //-----------------------------------------------------------------
    // Flop based register File (for simulation)
    //-----------------------------------------------------------------

    // Synchronous register write back
    always @ (posedge clk_i )
    if (rst_i)
    begin
        reg_v0_q       <= {VLEN{1'b0}};
        reg_v1_q       <= {VLEN{1'b0}};
        reg_v2_q       <= {VLEN{1'b0}};
        reg_v3_q       <= {VLEN{1'b0}};
        reg_v4_q       <= {VLEN{1'b0}};
        reg_v5_q       <= {VLEN{1'b0}};
        reg_v6_q       <= {VLEN{1'b0}};
        reg_v7_q       <= {VLEN{1'b0}};
        reg_v8_q       <= {VLEN{1'b0}};
        reg_v9_q       <= {VLEN{1'b0}};
        reg_v10_q      <= {VLEN{1'b0}};
        reg_v11_q      <= {VLEN{1'b0}};
        reg_v12_q      <= {VLEN{1'b0}};
        reg_v13_q      <= {VLEN{1'b0}};
        reg_v14_q      <= {VLEN{1'b0}};
        reg_v15_q      <= {VLEN{1'b0}};
        reg_v16_q      <= {VLEN{1'b0}};
        reg_v17_q      <= {VLEN{1'b0}};
        reg_v18_q      <= {VLEN{1'b0}};
        reg_v19_q      <= {VLEN{1'b0}};
        reg_v20_q      <= {VLEN{1'b0}};
        reg_v21_q      <= {VLEN{1'b0}};
        reg_v22_q      <= {VLEN{1'b0}};
        reg_v23_q      <= {VLEN{1'b0}};
        reg_v24_q      <= {VLEN{1'b0}};
        reg_v25_q      <= {VLEN{1'b0}};
        reg_v26_q      <= {VLEN{1'b0}};
        reg_v27_q      <= {VLEN{1'b0}};
        reg_v28_q      <= {VLEN{1'b0}};
        reg_v29_q      <= {VLEN{1'b0}};
        reg_v30_q      <= {VLEN{1'b0}};
        reg_v31_q      <= {VLEN{1'b0}};

    end
    else
    begin
        if      (rd0_i == 5'd0)  reg_v0_q  <= rd0_value_i;
        else if (rd1_i == 5'd0)  reg_v0_q  <= rd1_value_i;
        if      (rd0_i == 5'd1)  reg_v1_q  <= rd0_value_i;
        else if (rd1_i == 5'd1)  reg_v1_q  <= rd1_value_i;
        if      (rd0_i == 5'd2)  reg_v2_q  <= rd0_value_i;
        else if (rd1_i == 5'd2)  reg_v2_q  <= rd1_value_i;
        if      (rd0_i == 5'd3)  reg_v3_q  <= rd0_value_i;
        else if (rd1_i == 5'd3)  reg_v3_q  <= rd1_value_i;
        if      (rd0_i == 5'd4)  reg_v4_q  <= rd0_value_i;
        else if (rd1_i == 5'd4)  reg_v4_q  <= rd1_value_i;
        if      (rd0_i == 5'd5)  reg_v5_q  <= rd0_value_i;
        else if (rd1_i == 5'd5)  reg_v5_q  <= rd1_value_i;
        if      (rd0_i == 5'd6)  reg_v6_q  <= rd0_value_i;
        else if (rd1_i == 5'd6)  reg_v6_q  <= rd1_value_i;
        if      (rd0_i == 5'd7)  reg_v7_q  <= rd0_value_i;
        else if (rd1_i == 5'd7)  reg_v7_q  <= rd1_value_i;
        if      (rd0_i == 5'd8)  reg_v8_q  <= rd0_value_i;
        else if (rd1_i == 5'd8)  reg_v8_q  <= rd1_value_i;
        if      (rd0_i == 5'd9)  reg_v9_q  <= rd0_value_i;
        else if (rd1_i == 5'd9)  reg_v9_q  <= rd1_value_i;
        if      (rd0_i == 5'd10) reg_v10_q <= rd0_value_i;
        else if (rd1_i == 5'd10) reg_v10_q <= rd1_value_i;
        if      (rd0_i == 5'd11) reg_v11_q <= rd0_value_i;
        else if (rd1_i == 5'd11) reg_v11_q <= rd1_value_i;
        if      (rd0_i == 5'd12) reg_v12_q <= rd0_value_i;
        else if (rd1_i == 5'd12) reg_v12_q <= rd1_value_i;
        if      (rd0_i == 5'd13) reg_v13_q <= rd0_value_i;
        else if (rd1_i == 5'd13) reg_v13_q <= rd1_value_i;
        if      (rd0_i == 5'd14) reg_v14_q <= rd0_value_i;
        else if (rd1_i == 5'd14) reg_v14_q <= rd1_value_i;
        if      (rd0_i == 5'd15) reg_v15_q <= rd0_value_i;
        else if (rd1_i == 5'd15) reg_v15_q <= rd1_value_i;
        if      (rd0_i == 5'd16) reg_v16_q <= rd0_value_i;
        else if (rd1_i == 5'd16) reg_v16_q <= rd1_value_i;
        if      (rd0_i == 5'd17) reg_v17_q <= rd0_value_i;
        else if (rd1_i == 5'd17) reg_v17_q <= rd1_value_i;
        if      (rd0_i == 5'd18) reg_v18_q <= rd0_value_i;
        else if (rd1_i == 5'd18) reg_v18_q <= rd1_value_i;
        if      (rd0_i == 5'd19) reg_v19_q <= rd0_value_i;
        else if (rd1_i == 5'd19) reg_v19_q <= rd1_value_i;
        if      (rd0_i == 5'd20) reg_v20_q <= rd0_value_i;
        else if (rd1_i == 5'd20) reg_v20_q <= rd1_value_i;
        if      (rd0_i == 5'd21) reg_v21_q <= rd0_value_i;
        else if (rd1_i == 5'd21) reg_v21_q <= rd1_value_i;
        if      (rd0_i == 5'd22) reg_v22_q <= rd0_value_i;
        else if (rd1_i == 5'd22) reg_v22_q <= rd1_value_i;
        if      (rd0_i == 5'd23) reg_v23_q <= rd0_value_i;
        else if (rd1_i == 5'd23) reg_v23_q <= rd1_value_i;
        if      (rd0_i == 5'd24) reg_v24_q <= rd0_value_i;
        else if (rd1_i == 5'd24) reg_v24_q <= rd1_value_i;
        if      (rd0_i == 5'd25) reg_v25_q <= rd0_value_i;
        else if (rd1_i == 5'd25) reg_v25_q <= rd1_value_i;
        if      (rd0_i == 5'd26) reg_v26_q <= rd0_value_i;
        else if (rd1_i == 5'd26) reg_v26_q <= rd1_value_i;
        if      (rd0_i == 5'd27) reg_v27_q <= rd0_value_i;
        else if (rd1_i == 5'd27) reg_v27_q <= rd1_value_i;
        if      (rd0_i == 5'd28) reg_v28_q <= rd0_value_i;
        else if (rd1_i == 5'd28) reg_v28_q <= rd1_value_i;
        if      (rd0_i == 5'd29) reg_v29_q <= rd0_value_i;
        else if (rd1_i == 5'd29) reg_v29_q <= rd1_value_i;
        if      (rd0_i == 5'd30) reg_v30_q <= rd0_value_i;
        else if (rd1_i == 5'd30) reg_v30_q <= rd1_value_i;
        if      (rd0_i == 5'd31) reg_v31_q <= rd0_value_i;
        else if (rd1_i == 5'd31) reg_v31_q <= rd1_value_i;
    end

    //-----------------------------------------------------------------
    // Asynchronous read
    //-----------------------------------------------------------------
    reg [VLEN-1:0] ra0_value_r;
    reg [VLEN-1:0] rb0_value_r;
    always @ *
    begin
        case (ra0_i)
        5'd0: ra0_value_r = reg_v0_q;
        5'd1: ra0_value_r = reg_v1_q;
        5'd2: ra0_value_r = reg_v2_q;
        5'd3: ra0_value_r = reg_v3_q;
        5'd4: ra0_value_r = reg_v4_q;
        5'd5: ra0_value_r = reg_v5_q;
        5'd6: ra0_value_r = reg_v6_q;
        5'd7: ra0_value_r = reg_v7_q;
        5'd8: ra0_value_r = reg_v8_q;
        5'd9: ra0_value_r = reg_v9_q;
        5'd10: ra0_value_r = reg_v10_q;
        5'd11: ra0_value_r = reg_v11_q;
        5'd12: ra0_value_r = reg_v12_q;
        5'd13: ra0_value_r = reg_v13_q;
        5'd14: ra0_value_r = reg_v14_q;
        5'd15: ra0_value_r = reg_v15_q;
        5'd16: ra0_value_r = reg_v16_q;
        5'd17: ra0_value_r = reg_v17_q;
        5'd18: ra0_value_r = reg_v18_q;
        5'd19: ra0_value_r = reg_v19_q;
        5'd20: ra0_value_r = reg_v20_q;
        5'd21: ra0_value_r = reg_v21_q;
        5'd22: ra0_value_r = reg_v22_q;
        5'd23: ra0_value_r = reg_v23_q;
        5'd24: ra0_value_r = reg_v24_q;
        5'd25: ra0_value_r = reg_v25_q;
        5'd26: ra0_value_r = reg_v26_q;
        5'd27: ra0_value_r = reg_v27_q;
        5'd28: ra0_value_r = reg_v28_q;
        5'd29: ra0_value_r = reg_v29_q;
        5'd30: ra0_value_r = reg_v30_q;
        5'd31: ra0_value_r = reg_v31_q;
        default : ra0_value_r = {VLEN{1'b0}};
        endcase

        case (rb0_i)
        5'd0: rb0_value_r = reg_v0_q;
        5'd1: rb0_value_r = reg_v1_q;
        5'd2: rb0_value_r = reg_v2_q;
        5'd3: rb0_value_r = reg_v3_q;
        5'd4: rb0_value_r = reg_v4_q;
        5'd5: rb0_value_r = reg_v5_q;
        5'd6: rb0_value_r = reg_v6_q;
        5'd7: rb0_value_r = reg_v7_q;
        5'd8: rb0_value_r = reg_v8_q;
        5'd9: rb0_value_r = reg_v9_q;
        5'd10: rb0_value_r = reg_v10_q;
        5'd11: rb0_value_r = reg_v11_q;
        5'd12: rb0_value_r = reg_v12_q;
        5'd13: rb0_value_r = reg_v13_q;
        5'd14: rb0_value_r = reg_v14_q;
        5'd15: rb0_value_r = reg_v15_q;
        5'd16: rb0_value_r = reg_v16_q;
        5'd17: rb0_value_r = reg_v17_q;
        5'd18: rb0_value_r = reg_v18_q;
        5'd19: rb0_value_r = reg_v19_q;
        5'd20: rb0_value_r = reg_v20_q;
        5'd21: rb0_value_r = reg_v21_q;
        5'd22: rb0_value_r = reg_v22_q;
        5'd23: rb0_value_r = reg_v23_q;
        5'd24: rb0_value_r = reg_v24_q;
        5'd25: rb0_value_r = reg_v25_q;
        5'd26: rb0_value_r = reg_v26_q;
        5'd27: rb0_value_r = reg_v27_q;
        5'd28: rb0_value_r = reg_v28_q;
        5'd29: rb0_value_r = reg_v29_q;
        5'd30: rb0_value_r = reg_v30_q;
        5'd31: rb0_value_r = reg_v31_q;
        default : rb0_value_r = {VLEN{1'b0}};
        endcase
    end

    assign ra0_value_o = ra0_value_r;
    assign rb0_value_o = rb0_value_r;


    reg [VLEN-1:0] ra1_value_r;
    reg [VLEN-1:0] rb1_value_r;
    always @ *
    begin
        case (ra1_i)
        5'd0: ra1_value_r = reg_v0_q;
        5'd1: ra1_value_r = reg_v1_q;
        5'd2: ra1_value_r = reg_v2_q;
        5'd3: ra1_value_r = reg_v3_q;
        5'd4: ra1_value_r = reg_v4_q;
        5'd5: ra1_value_r = reg_v5_q;
        5'd6: ra1_value_r = reg_v6_q;
        5'd7: ra1_value_r = reg_v7_q;
        5'd8: ra1_value_r = reg_v8_q;
        5'd9: ra1_value_r = reg_v9_q;
        5'd10: ra1_value_r = reg_v10_q;
        5'd11: ra1_value_r = reg_v11_q;
        5'd12: ra1_value_r = reg_v12_q;
        5'd13: ra1_value_r = reg_v13_q;
        5'd14: ra1_value_r = reg_v14_q;
        5'd15: ra1_value_r = reg_v15_q;
        5'd16: ra1_value_r = reg_v16_q;
        5'd17: ra1_value_r = reg_v17_q;
        5'd18: ra1_value_r = reg_v18_q;
        5'd19: ra1_value_r = reg_v19_q;
        5'd20: ra1_value_r = reg_v20_q;
        5'd21: ra1_value_r = reg_v21_q;
        5'd22: ra1_value_r = reg_v22_q;
        5'd23: ra1_value_r = reg_v23_q;
        5'd24: ra1_value_r = reg_v24_q;
        5'd25: ra1_value_r = reg_v25_q;
        5'd26: ra1_value_r = reg_v26_q;
        5'd27: ra1_value_r = reg_v27_q;
        5'd28: ra1_value_r = reg_v28_q;
        5'd29: ra1_value_r = reg_v29_q;
        5'd30: ra1_value_r = reg_v30_q;
        5'd31: ra1_value_r = reg_v31_q;
        default : ra1_value_r = {VLEN{1'b0}};
        endcase

        case (rb1_i)
        5'd0: rb1_value_r = reg_v0_q;
        5'd1: rb1_value_r = reg_v1_q;
        5'd2: rb1_value_r = reg_v2_q;
        5'd3: rb1_value_r = reg_v3_q;
        5'd4: rb1_value_r = reg_v4_q;
        5'd5: rb1_value_r = reg_v5_q;
        5'd6: rb1_value_r = reg_v6_q;
        5'd7: rb1_value_r = reg_v7_q;
        5'd8: rb1_value_r = reg_v8_q;
        5'd9: rb1_value_r = reg_v9_q;
        5'd10: rb1_value_r = reg_v10_q;
        5'd11: rb1_value_r = reg_v11_q;
        5'd12: rb1_value_r = reg_v12_q;
        5'd13: rb1_value_r = reg_v13_q;
        5'd14: rb1_value_r = reg_v14_q;
        5'd15: rb1_value_r = reg_v15_q;
        5'd16: rb1_value_r = reg_v16_q;
        5'd17: rb1_value_r = reg_v17_q;
        5'd18: rb1_value_r = reg_v18_q;
        5'd19: rb1_value_r = reg_v19_q;
        5'd20: rb1_value_r = reg_v20_q;
        5'd21: rb1_value_r = reg_v21_q;
        5'd22: rb1_value_r = reg_v22_q;
        5'd23: rb1_value_r = reg_v23_q;
        5'd24: rb1_value_r = reg_v24_q;
        5'd25: rb1_value_r = reg_v25_q;
        5'd26: rb1_value_r = reg_v26_q;
        5'd27: rb1_value_r = reg_v27_q;
        5'd28: rb1_value_r = reg_v28_q;
        5'd29: rb1_value_r = reg_v29_q;
        5'd30: rb1_value_r = reg_v30_q;
        5'd31: rb1_value_r = reg_v31_q;
        default : rb1_value_r = {VLEN{1'b0}};
        endcase
    end

    assign ra1_value_o = ra1_value_r;
    assign rb1_value_o = rb1_value_r;

    //-------------------------------------------------------------
    // get_register: Read register file
    //-------------------------------------------------------------
    `ifdef verilator
    function [VLEN-1:0] get_register; /*verilator public*/
        input [4:0] r;
    begin
        case (r)
        5'd0: get_register = reg_v0_q;
        5'd1: get_register = reg_v1_q;
        5'd2: get_register = reg_v2_q;
        5'd3: get_register = reg_v3_q;
        5'd4: get_register = reg_v4_q;
        5'd5: get_register = reg_v5_q;
        5'd6: get_register = reg_v6_q;
        5'd7: get_register = reg_v7_q;
        5'd8: get_register = reg_v8_q;
        5'd9: get_register = reg_v9_q;
        5'd10: get_register = reg_v10_q;
        5'd11: get_register = reg_v11_q;
        5'd12: get_register = reg_v12_q;
        5'd13: get_register = reg_v13_q;
        5'd14: get_register = reg_v14_q;
        5'd15: get_register = reg_v15_q;
        5'd16: get_register = reg_v16_q;
        5'd17: get_register = reg_v17_q;
        5'd18: get_register = reg_v18_q;
        5'd19: get_register = reg_v19_q;
        5'd20: get_register = reg_v20_q;
        5'd21: get_register = reg_v21_q;
        5'd22: get_register = reg_v22_q;
        5'd23: get_register = reg_v23_q;
        5'd24: get_register = reg_v24_q;
        5'd25: get_register = reg_v25_q;
        5'd26: get_register = reg_v26_q;
        5'd27: get_register = reg_v27_q;
        5'd28: get_register = reg_v28_q;
        5'd29: get_register = reg_v29_q;
        5'd30: get_register = reg_v30_q;
        5'd31: get_register = reg_v31_q;
        default : get_register = {VLEN{1'b0}};
        endcase
    end
    endfunction
    //-------------------------------------------------------------
    // set_register: Write register file
    //-------------------------------------------------------------
    function set_register; /*verilator public*/
        input [4:0] r;
        input [VLEN-1:0] value;
    begin
        //case (r)
        //5'd1:  reg_r1_q  <= value;
        //5'd2:  reg_r2_q  <= value;
        //5'd3:  reg_r3_q  <= value;
        //5'd4:  reg_r4_q  <= value;
        //5'd5:  reg_r5_q  <= value;
        //5'd6:  reg_r6_q  <= value;
        //5'd7:  reg_r7_q  <= value;
        //5'd8:  reg_r8_q  <= value;
        //5'd9:  reg_r9_q  <= value;
        //5'd10: reg_r10_q <= value;
        //5'd11: reg_r11_q <= value;
        //5'd12: reg_r12_q <= value;
        //5'd13: reg_r13_q <= value;
        //5'd14: reg_r14_q <= value;
        //5'd15: reg_r15_q <= value;
        //5'd16: reg_r16_q <= value;
        //5'd17: reg_r17_q <= value;
        //5'd18: reg_r18_q <= value;
        //5'd19: reg_r19_q <= value;
        //5'd20: reg_r20_q <= value;
        //5'd21: reg_r21_q <= value;
        //5'd22: reg_r22_q <= value;
        //5'd23: reg_r23_q <= value;
        //5'd24: reg_r24_q <= value;
        //5'd25: reg_r25_q <= value;
        //5'd26: reg_r26_q <= value;
        //5'd27: reg_r27_q <= value;
        //5'd28: reg_r28_q <= value;
        //5'd29: reg_r29_q <= value;
        //5'd30: reg_r30_q <= value;
        //5'd31: reg_r31_q <= value;
        //default :
        //    ;
        //endcase
    end
    endfunction
    `endif

end
endgenerate

endmodule

