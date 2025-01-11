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
    parameter VLEN = 128
    ,parameter ELEN = 32
)
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           opcode_valid_i
    ,input  [ 31:0]  opcode_opcode_i
    ,input  [ 31:0]  opcode_pc_i
    ,input           opcode_invalid_i
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

    // EMO - v_alu_complete signal required 

    // Outputs
    ,output          writeback_valid_o
    ,output [ VLEN - 1:0]  writeback_value_o
);

integer i;


//-----------------------------------------------------------------
// Includes
//-----------------------------------------------------------------
`include "biriscv_defs.v"

//-------------------------------------------------------------
// Opcode decode
//-------------------------------------------------------------
reg [VLEN - 1:0]  imm4_r;
reg [VLEN - 1:0]  register_operand_r;
reg               vm_r;

always @ *
begin
    imm4_r   = {{(VLEN - 5){opcode_opcode_i[19]}}, opcode_opcode_i[19:15]};
    vm_r     = opcode_opcode_i[25];
    register_operand_r     = {{(VLEN - 32){opcode_ra_operand_i[31]}}, opcode_ra_operand_i};
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
    else if ((opcode_opcode_i & `INST_VADD_VX_MASK) == `INST_VADD_VX) // vadd.vx
    begin
        if (vm_r == 1'b1) begin
            for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                result_r[(i+1)*ELEN-1 -: ELEN] = opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN] + register_operand_r[ELEN - 1 : 0];
            end
        end
        else begin
            for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                result_r[(i+1)*ELEN-1 -: ELEN] = opcode_vmask_operand_i[i * ELEN] ? opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN] + register_operand_r[ELEN - 1 : 0] : {ELEN{1'b0}};
            end
        end
    end
    else if ((opcode_opcode_i & `INST_VADD_VI_MASK) == `INST_VADD_VI) // vadd.vi
    begin
        if (vm_r == 1'b1) begin
            for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                result_r[(i+1)*ELEN-1 -: ELEN] = opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN] + imm4_r[ELEN - 1 : 0];
            end
        end
        else begin
            for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                result_r[(i+1)*ELEN-1 -: ELEN] = opcode_vmask_operand_i[i * ELEN] ? opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN] + imm4_r[ELEN - 1 : 0] : {ELEN{1'b0}};
            end
        end
    end
    else if ((opcode_opcode_i & `INST_VSUB_VV_MASK) == `INST_VSUB_VV) // vsub.vv
    begin
        if (vm_r == 1'b1) begin
            for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                result_r[(i+1)*ELEN-1 -: ELEN] = opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN] - opcode_vb_operand_i[(i+1)*ELEN-1 -: ELEN];
            end
        end
        else begin
            for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                result_r[(i+1)*ELEN-1 -: ELEN] = opcode_vmask_operand_i[i * ELEN] ? opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN] - opcode_vb_operand_i[(i+1)*ELEN-1 -: ELEN] : {ELEN{1'b0}};
            end
        end
    end
    else if ((opcode_opcode_i & `INST_VSUB_VX_MASK) == `INST_VSUB_VX) // vsub.vx
    begin
        if (vm_r == 1'b1) begin
            for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                result_r[(i+1)*ELEN-1 -: ELEN] = opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN] - register_operand_r[ELEN - 1 : 0];
            end
        end
        else begin
            for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                result_r[(i+1)*ELEN-1 -: ELEN] = opcode_vmask_operand_i[i * ELEN] ? opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN] - register_operand_r[ELEN - 1 : 0] : {ELEN{1'b0}};
            end
        end
    end
    else if ((opcode_opcode_i & `INST_VRSUB_VX_MASK) == `INST_VRSUB_VX) // vrsub.vx
    begin
        if (vm_r == 1'b1) begin
            for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                result_r[(i+1)*ELEN-1 -: ELEN] = register_operand_r[ELEN - 1 : 0] - opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN];
            end
        end
        else begin
            for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                result_r[(i+1)*ELEN-1 -: ELEN] = opcode_vmask_operand_i[i * ELEN] ? register_operand_r[ELEN - 1 : 0] - opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN] : {ELEN{1'b0}};
            end
        end
    end
    else if ((opcode_opcode_i & `INST_VRSUB_VI_MASK) == `INST_VRSUB_VI) // vrsub.vi
    begin
        if (vm_r == 1'b1) begin
            for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                result_r[(i+1)*ELEN-1 -: ELEN] = imm4_r[ELEN - 1 : 0] - opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN];
            end
        end
        else begin
            for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                result_r[(i+1)*ELEN-1 -: ELEN] = opcode_vmask_operand_i[i * ELEN] ? imm4_r[ELEN - 1 : 0] - opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN] : {ELEN{1'b0}};
            end
        end
    end
    else if ((opcode_opcode_i & `INST_VMINU_VV_MASK) == `INST_VMINU_VV) // vminu_vv
    begin
        if (vm_r == 1'b1) begin
            for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                result_r[(i+1)*ELEN-1 -: ELEN] = ((opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN] < opcode_vb_operand_i[(i+1)*ELEN-1 -: ELEN]) 
                                                ? opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN]
                                                : opcode_vb_operand_i[(i+1)*ELEN-1 -: ELEN]);
            end
        end
        else begin
            for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                result_r[(i+1)*ELEN-1 -: ELEN] = opcode_vmask_operand_i[i * ELEN] 
                                                ? ((opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN] < opcode_vb_operand_i[(i+1)*ELEN-1 -: ELEN]) 
                                                    ? opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN] 
                                                    : opcode_vb_operand_i[(i+1)*ELEN-1 -: ELEN])
                                                    : {ELEN{1'b0}};
            end
        end
    end
    else if ((opcode_opcode_i & `INST_VMINU_VX_MASK) == `INST_VMINU_VX) // vminu_vx
    begin
        if (vm_r == 1'b1) begin
            for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                result_r[(i+1)*ELEN-1 -: ELEN] = ((opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN] < register_operand_r[ELEN - 1 : 0])
                                                ? opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN]
                                                : register_operand_r[ELEN - 1 : 0]);
            end
        end
        else begin
            for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                result_r[(i+1)*ELEN-1 -: ELEN] = opcode_vmask_operand_i[i * ELEN] 
                                                ? ((opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN] < register_operand_r[ELEN - 1 : 0]) 
                                                    ? opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN] 
                                                    : register_operand_r[ELEN - 1 : 0])
                                                    : {ELEN{1'b0}};
            end
        end
    end
    else if ((opcode_opcode_i & `INST_VMAXU_VV_MASK) == `INST_VMAXU_VV) // vmaxu_vv
    begin
        if (vm_r == 1'b1) begin
            for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                result_r[(i+1)*ELEN-1 -: ELEN] = ((opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN] > opcode_vb_operand_i[(i+1)*ELEN-1 -: ELEN]) 
                                                ? opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN]
                                                : opcode_vb_operand_i[(i+1)*ELEN-1 -: ELEN]);
            end
        end
        else begin
            for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                result_r[(i+1)*ELEN-1 -: ELEN] = opcode_vmask_operand_i[i * ELEN] 
                                                ? ((opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN] > opcode_vb_operand_i[(i+1)*ELEN-1 -: ELEN]) 
                                                    ? opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN] 
                                                    : opcode_vb_operand_i[(i+1)*ELEN-1 -: ELEN])
                                                    : {ELEN{1'b0}};
            end
        end
    end
    else if ((opcode_opcode_i & `INST_VMAXU_VX_MASK) == `INST_VMAXU_VX) // vmaxu_vx
    begin
        if (vm_r == 1'b1) begin
            for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                result_r[(i+1)*ELEN-1 -: ELEN] = ((opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN] > register_operand_r[(i+1)*ELEN-1 -: ELEN]) 
                                                ? opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN]
                                                : register_operand_r[(i+1)*ELEN-1 -: ELEN]);
            end
        end
        else begin
            for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                result_r[(i+1)*ELEN-1 -: ELEN] = opcode_vmask_operand_i[i * ELEN] 
                                                ? ((opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN] > register_operand_r[(i+1)*ELEN-1 -: ELEN]) 
                                                    ? opcode_va_operand_i[(i+1)*ELEN-1 -: ELEN] 
                                                    : register_operand_r[(i+1)*ELEN-1 -: ELEN])
                                                    : {ELEN{1'b0}};
            end
        end
    end         
end


assign writeback_valid_o  = 1'b1;
assign writeback_value_o  = result_r;


endmodule
