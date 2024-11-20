`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.11.2024 23:50:00
// Design Name: 
// Module Name: biriscv_v_alu
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


module biriscv_v_alu 
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter VLEN    = 128,
     parameter ELEN    = 32
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input  [  3:0]        alu_op_i
    ,input  [ VLEN - 1:0]  alu_a_i
    ,input  [ VLEN - 1:0]  alu_b_i
    ,input  [ VLEN - 1:0]  alu_mask_i
    ,input                 alu_vm

    // Outputs
    ,output [ VLEN - 1:0]  alu_p_o
);

//-----------------------------------------------------------------
// Includes
//-----------------------------------------------------------------
`include "biriscv_defs.v"

//-----------------------------------------------------------------
// Registers
//-----------------------------------------------------------------
reg [ VLEN - 1:0]      result_r;


integer i;


//-----------------------------------------------------------------
// ALU
//-----------------------------------------------------------------
always @ (alu_op_i or alu_a_i or alu_b_i or alu_vm or alu_mask_i)
begin
    case (alu_op_i)
       //----------------------------------------------
       // Arithmetic
       //----------------------------------------------

       //----------------------------------------------
       // VADD
       //----------------------------------------------
       `ALU_VADDVV : 
        begin
                if (alu_vm == 1'b1) begin
                    for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                        result_r[(i+1)*ELEN-1 -: ELEN] = alu_a_i[(i+1)*ELEN-1 -: ELEN] + alu_b_i[(i+1)*ELEN-1 -: ELEN];
                    end
                end
                else begin
                    for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                        result_r[(i+1)*ELEN-1 -: ELEN] = alu_mask_i[i * ELEN] ? alu_a_i[(i+1)*ELEN-1 -: ELEN] + alu_b_i[(i+1)*ELEN-1 -: ELEN] : {ELEN{1'b0}};
                    end
                end
        end

       `ALU_VADDVXI  : 
        begin
                if (alu_vm == 1'b1) begin
                    for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                        result_r[(i+1)*ELEN-1 -: ELEN] = alu_a_i[(i+1)*ELEN-1 -: ELEN] + alu_b_i[ELEN - 1 : 0];
                    end
                end
                else begin
                    for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                        result_r[(i+1)*ELEN-1 -: ELEN] = alu_mask_i[i * ELEN] ? alu_a_i[(i+1)*ELEN-1 -: ELEN] + alu_b_i[ELEN - 1 : 0] : {ELEN{1'b0}};
                    end
                end
        end

       //----------------------------------------------
       // VSUB
       //----------------------------------------------
       `ALU_VSUBVV : 
        begin
                if (alu_vm == 1'b1) begin
                    for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                        result_r[(i+1)*ELEN-1 -: ELEN] = alu_a_i[(i+1)*ELEN-1 -: ELEN] - alu_b_i[(i+1)*ELEN-1 -: ELEN];
                    end
                end
                else begin
                    for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                        result_r[(i+1)*ELEN-1 -: ELEN] = alu_mask_i[i * ELEN] ? alu_a_i[(i+1)*ELEN-1 -: ELEN] - alu_b_i[(i+1)*ELEN-1 -: ELEN] : {ELEN{1'b0}};
                    end
                end
        end

       `ALU_VSUBVX : 
        begin
                if (alu_vm == 1'b1) begin
                    for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                        result_r[(i+1)*ELEN-1 -: ELEN] = alu_a_i[(i+1)*ELEN-1 -: ELEN] - alu_b_i[ELEN - 1 : 0];
                    end
                end
                else begin
                    for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                        result_r[(i+1)*ELEN-1 -: ELEN] = alu_mask_i[i * ELEN] ? alu_a_i[(i+1)*ELEN-1 -: ELEN] - alu_b_i[ELEN - 1 : 0] : {ELEN{1'b0}};
                    end
                end
        end

       //----------------------------------------------
       // VRSUB
       //----------------------------------------------
       `ALU_VRSUBVXI : 
        begin
                if (alu_vm == 1'b1) begin
                    for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                        result_r[(i+1)*ELEN-1 -: ELEN] = alu_b_i[ELEN - 1 : 0] - alu_a_i[(i+1)*ELEN-1 -: ELEN];
                    end
                end
                else begin
                    for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                        result_r[(i+1)*ELEN-1 -: ELEN] = alu_mask_i[i * ELEN] ? alu_b_i[ELEN - 1 : 0] - alu_a_i[(i+1)*ELEN-1 -: ELEN] : {ELEN{1'b0}};
                    end
                end
        end

       //----------------------------------------------
       // VMINU
       //----------------------------------------------
       `ALU_VMINUVV: 
        begin
            if (alu_vm == 1'b1) begin
                for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                    result_r[(i+1)*ELEN-1 -: ELEN] = ((alu_a_i[(i+1)*ELEN-1 -: ELEN] < alu_b_i[(i+1)*ELEN-1 -: ELEN]) 
                                                    ? alu_a_i[(i+1)*ELEN-1 -: ELEN]
                                                    : alu_b_i[(i+1)*ELEN-1 -: ELEN]);
                end
            end
            else begin
                for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                    result_r[(i+1)*ELEN-1 -: ELEN] = alu_mask_i[i * ELEN] 
                                                    ? ((alu_a_i[(i+1)*ELEN-1 -: ELEN] < alu_b_i[(i+1)*ELEN-1 -: ELEN]) 
                                                        ? alu_a_i[(i+1)*ELEN-1 -: ELEN] 
                                                        : alu_b_i[(i+1)*ELEN-1 -: ELEN])
                                                        : {ELEN{1'b0}};
                end
            end
        end

       `ALU_VMINUVX: 
        begin
            if (alu_vm == 1'b1) begin
                for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                    result_r[(i+1)*ELEN-1 -: ELEN] = ((alu_a_i[(i+1)*ELEN-1 -: ELEN] < alu_b_i[ELEN - 1 : 0])
                                                    ? alu_a_i[(i+1)*ELEN-1 -: ELEN]
                                                    : alu_b_i[ELEN - 1 : 0]);
                end
            end
            else begin
                for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                    result_r[(i+1)*ELEN-1 -: ELEN] = alu_mask_i[i * ELEN] 
                                                    ? ((alu_a_i[(i+1)*ELEN-1 -: ELEN] < alu_b_i[ELEN - 1 : 0]) 
                                                        ? alu_a_i[(i+1)*ELEN-1 -: ELEN] 
                                                        : alu_b_i[ELEN - 1 : 0])
                                                        : {ELEN{1'b0}};
                end
            end
        end

       //----------------------------------------------
       // VMAXU
       //----------------------------------------------
       `ALU_VMAXUVV: 
        begin
            if (alu_vm == 1'b1) begin
                for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                    result_r[(i+1)*ELEN-1 -: ELEN] = ((alu_a_i[(i+1)*ELEN-1 -: ELEN] > alu_b_i[(i+1)*ELEN-1 -: ELEN]) 
                                                    ? alu_a_i[(i+1)*ELEN-1 -: ELEN]
                                                    : alu_b_i[(i+1)*ELEN-1 -: ELEN]);
                end
            end
            else begin
                for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                    result_r[(i+1)*ELEN-1 -: ELEN] = alu_mask_i[i * ELEN] 
                                                    ? ((alu_a_i[(i+1)*ELEN-1 -: ELEN] > alu_b_i[(i+1)*ELEN-1 -: ELEN]) 
                                                        ? alu_a_i[(i+1)*ELEN-1 -: ELEN] 
                                                        : alu_b_i[(i+1)*ELEN-1 -: ELEN])
                                                        : {ELEN{1'b0}};
                end
            end
        end

       `ALU_VMINUVX: 
        begin
            if (alu_vm == 1'b1) begin
                for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                    result_r[(i+1)*ELEN-1 -: ELEN] = ((alu_a_i[(i+1)*ELEN-1 -: ELEN] > alu_b_i[ELEN - 1 : 0]) 
                                                        ? alu_a_i[(i+1)*ELEN-1 -: ELEN]
                                                        : alu_b_i[ELEN - 1 : 0]);
                end
            end
            else begin
                for (i = 0; i < VLEN / ELEN; i = i + 1) begin
                    result_r[(i+1)*ELEN-1 -: ELEN] = alu_mask_i[i * ELEN] 
                                                    ? ((alu_a_i[(i+1)*ELEN-1 -: ELEN] > alu_b_i[ELEN - 1 : 0]) 
                                                        ? alu_a_i[(i+1)*ELEN-1 -: ELEN] 
                                                        : alu_b_i[ELEN - 1 : 0])
                                                        : {ELEN{1'b0}};
                end
            end
        end


       //----------------------------------------------
       // Logical
       //----------------------------------------------       


       //----------------------------------------------
       // Comparision
       //----------------------------------------------
       default: result_r = 0;  
    endcase
end

assign alu_p_o    = result_r;

endmodule
