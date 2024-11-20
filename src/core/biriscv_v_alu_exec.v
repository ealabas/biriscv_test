//-----------------------------------------------------------------
//                         biRISC-V CPU
//                            V0.8.1
//                     Ultra-Embedded.com
//                     Copyright 2019-2020
//
//                   admin@ultra-embedded.com
//
//                     License: Apache 2.0
//-----------------------------------------------------------------
// Copyright 2020 Ultra-Embedded.com
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//-----------------------------------------------------------------

module biriscv_v_alu_exec#(
    parameter VLEN = 128;
)
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           opcode_valid_i
    ,input  [ 31:0]  opcode_opcode_i
    ,input  [ 31:0]  opcode_pc_i
    ,input           opcode_invalid_i
    ,input  [  4:0]  opcode_rd_idx_i
    ,input  [  4:0]  opcode_vd_idx_i
    ,input  [  4:0]  opcode_ra_idx_i
    ,input  [  4:0]  opcode_rb_idx_i
    ,input  [  4:0]  opcode_va_idx_i
    ,input  [  4:0]  opcode_vb_idx_i
    ,input  [ 31:0]  opcode_ra_operand_i
    ,input  [ 31:0]  opcode_rb_operand_i
    ,input  [ VLEN - 1:0]  opcode_va_operand_i
    ,input  [ VLEN - 1:0]  opcode_vb_operand_i
    ,input  [ VLEN - 1:0]  opcode_vmask_operand_i
    ,input           hold_i

    // Outputs
    ,output [ 31:0]  writeback_value_o
);



//-----------------------------------------------------------------
// Includes
//-----------------------------------------------------------------
`include "biriscv_defs.v"

//-------------------------------------------------------------
// Opcode decode
//-------------------------------------------------------------
reg [VLEN - 1:0]  imm4_r;
reg               vm_r;

always @ *
begin
    imm4_r   = {{(VLEN - 5){opcode_opcode_i[19]}}, opcode_opcode_i[19:15]};
    vm_r     = opcode_opcode_i[25];
end
reg  [VLEN - 1:0]  result_r;

wire v_alu_inst_w    = ((opcode_opcode_i & `INST_VADD_VV_MASK) == `INST_VADD_VV)|| 
                      ((opcode_opcode_i & `INST_VADD_VX_MASK) == `INST_VADD_VX)|| 
                      ((opcode_opcode_i & `INST_VADD_VI_MASK) == `INST_VADD_VI)||
                      ((opcode_opcode_i & `INST_VSUB_VV_MASK) == `INST_VSUB_VV)||
                      ((opcode_opcode_i & `INST_VSUB_VX_MASK) == `INST_VSUB_VX)||
                      ((opcode_opcode_i & `INST_VRSUB_VX_MASK) == `INST_VRSUB_VX)||
                      ((opcode_opcode_i & `INST_VRSUB_VI_MASK) == `INST_VRSUB_VI)||
                      ((opcode_opcode_i & `INST_VMINU_VV_MASK) == `INST_VMINU_VV)||
                      ((opcode_opcode_i & `INST_VMINU_VX_MASK) == `INST_VMINU_VX)||
                      ((opcode_opcode_i & `INST_VMAXU_VV_MASK) == `INST_VMAXU_VV)||
                      ((opcode_opcode_i & `INST_VMAXU_VX_MASK) == `INST_VMAXU_VX);

always @ *
begin
    if ((opcode_opcode_i & `INST_VADD_VV_MASK) == `INST_VADD_VV) // vadd.vv
    begin
        if (vm_r == 1'b1) begin
            for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                result_r[(i+1)*ELEN-1 -: ELEN] = opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN] + opcode_vb_operand_i[(i+1)*ELEN-1 -: ELEN];
            end
        end
        else begin
            for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                result_r[(i+1)*ELEN-1 -: ELEN] = opcode_vmask_operand_i[i * ELEN] ? opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN] + opcode_vb_operand_i[(i+1)*ELEN-1 -: ELEN] : {ELEN{1'b0}};
            end
        end        
    end
end


// Pipeline flops for multiplier
always @(posedge clk_i or posedge rst_i)
if (rst_i)
begin
    operand_a_e1_q <= 33'b0;
    operand_b_e1_q <= 33'b0;
    mulhi_sel_e1_q <= 1'b0;
end
else if (hold_i)
    ;
else if (opcode_valid_i && mult_inst_w)
begin
    operand_a_e1_q <= operand_a_r;
    operand_b_e1_q <= operand_b_r;
    mulhi_sel_e1_q <= ~((opcode_opcode_i & `INST_MUL_MASK) == `INST_MUL);
end
else
begin
    operand_a_e1_q <= 33'b0;
    operand_b_e1_q <= 33'b0;
    mulhi_sel_e1_q <= 1'b0;
end

assign mult_result_w = {{ 32 {operand_a_e1_q[32]}}, operand_a_e1_q}*{{ 32 {operand_b_e1_q[32]}}, operand_b_e1_q};

always @ *
begin
    result_r = mulhi_sel_e1_q ? mult_result_w[63:32] : mult_result_w[31:0];
end

always @(posedge clk_i or posedge rst_i)
if (rst_i)
    result_e2_q <= 32'b0;
else if (~hold_i)
    result_e2_q <= result_r;

always @(posedge clk_i or posedge rst_i)
if (rst_i)
    result_e3_q <= 32'b0;
else if (~hold_i)
    result_e3_q <= result_e2_q;

assign writeback_value_o  = (MULT_STAGES == 3) ? result_e3_q : result_e2_q;


endmodule
