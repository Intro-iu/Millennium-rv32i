`timescale 1ns / 1ps

`include "defines.svh"

module control (
    input  [6:0] opcode_i,
    input  [2:0] funct3_i,
    input  [6:0] funct7_i,


    output logic [2:0] npc_op_o,
    output logic       reg_wE_o,
    output logic [2:0] sext_op_o,
    output logic       alub_sel_o,
    output logic [3:0] alu_op_o,
    output logic       alu_rev_o,
    output logic       dram_we_o,
    output logic [2:0] wb_o
);

    always_comb begin
        {npc_op_o, reg_wE_o, sext_op_o, alub_sel_o, dram_we_o, wb_o, alu_rev_o} = '0;
        alu_op_o = '1;
        case (opcode_i)
            7'b0110011: begin
                npc_op_o = `NPC_PC4;
                reg_wE_o = '1;
                alub_sel_o = `ALUB_REG;
                alu_op_o = funct3_i == 3'b000 && funct7_i == 7'b0000000 ? `ALU_ADD  :
                           funct3_i == 3'b000 && funct7_i == 7'b0100000 ? `ALU_SUB  :
                           funct3_i == 3'b111 && funct7_i == 7'b0000000 ? `ALU_AND  :
                           funct3_i == 3'b110 && funct7_i == 7'b0000000 ? `ALU_OR   :
                           funct3_i == 3'b100 && funct7_i == 7'b0000000 ? `ALU_XOR  :
                           funct3_i == 3'b001 && funct7_i == 7'b0000000 ? `ALU_SLL  :
                           funct3_i == 3'b101 && funct7_i == 7'b0000000 ? `ALU_SRL  :
                           funct3_i == 3'b101 && funct7_i == 7'b0100000 ? `ALU_SRA  :
                           funct3_i == 3'b010 && funct7_i == 7'b0000000 ? `ALU_SLT  :
                           funct3_i == 3'b011 && funct7_i == 7'b0000000 ? `ALU_SLTU :
                           4'b1111;
                wb_o = funct3_i == 3'b010 || funct3_i == 3'b011 ? `WB_ALU0 : `WB_ALU;
            end 
            7'b0010011: begin
                npc_op_o = `NPC_PC4;
                reg_wE_o = '1;
                sext_op_o = funct3_i == 3'b001 && funct7_i == 7'b0000000 ? `EXT_I_0 :   // slli
                            funct3_i == 3'b101 && funct7_i == 7'b0000000 ? `EXT_I_0 :   // srli
                            funct3_i == 3'b101 && funct7_i == 7'b0100000 ? `EXT_I_0 :   // srai
                            `EXT_I_1;
                alub_sel_o = `ALUB_EXT;
                alu_op_o = funct3_i == 3'b000 ? `ALU_ADD :
                           funct3_i == 3'b111 ? `ALU_AND :
                           funct3_i == 3'b110 ? `ALU_OR  :
                           funct3_i == 3'b100 ? `ALU_XOR :
                           funct3_i == 3'b001 && funct7_i == 7'b0000000 ? `ALU_SLL :
                           funct3_i == 3'b101 && funct7_i == 7'b0000000 ? `ALU_SRL :
                           funct3_i == 3'b101 && funct7_i == 7'b0100000 ? `ALU_SRA :
                           funct3_i == 3'b010 ? `ALU_SLT :
                           funct3_i == 3'b011 ? `ALU_SLTU:
                           4'b1111;
                wb_o = funct3_i == 3'b010 || funct3_i == 3'b011 ? `WB_ALU0 : `WB_ALU;
            end
            7'b0000011: begin
                npc_op_o = `NPC_PC4;
                reg_wE_o = '1;
                sext_op_o = `EXT_I_1;
                alub_sel_o = `ALUB_EXT;
                alu_op_o = `ALU_ADD;
                wb_o = `WB_RAM;
            end
            7'b1100111: begin
                npc_op_o = `NPC_JALR;
                reg_wE_o = '1;
                sext_op_o = `EXT_I_1;
                alub_sel_o = `ALUB_EXT;
                alu_op_o = funct3_i == 3'b000 ? `ALU_ADD : 4'b1111;
                wb_o = `WB_PC4;
            end
            7'b0100011: begin
                npc_op_o = `NPC_PC4;
                reg_wE_o = '0;
                sext_op_o = `EXT_S;
                alub_sel_o = `ALUB_EXT;
                alu_op_o = `ALU_ADD;
                dram_we_o = `DRAM_W;
                wb_o = `WB_ALU;
            end
            7'b1100011: begin
                npc_op_o = `NPC_BR;
                reg_wE_o = '0;
                sext_op_o = `EXT_B;
                alub_sel_o = `ALUB_REG;
                alu_op_o  = funct3_i == 3'b000 ? `ALU_SUB :                     // beq
                            funct3_i == 3'b001 ? `ALU_SUB :                     // bne
                            funct3_i == 3'b100 ? `ALU_SLT :                     // blt
                            funct3_i == 3'b110 ? `ALU_SLTU:                     // bltu
                            funct3_i == 3'b101 ? `ALU_SLT :                     // bge
                            funct3_i == 3'b111 ? `ALU_SLTU:                     // bgeu
                            4'b1111;                                            // invalid

                alu_rev_o = funct3_i == 3'b000 ? '0 :                           // beq
                            funct3_i == 3'b001 ? '1 :                           // bne
                            funct3_i == 3'b100 ? '0 :                           // blt
                            funct3_i == 3'b110 ? '0 :                           // bltu
                            funct3_i == 3'b101 ? '1 :                           // bge
                            funct3_i == 3'b111 ? '1 :                           // bgeu
                            '0;
            end
            7'b0110111: begin
                npc_op_o = `NPC_PC4;
                reg_wE_o = '1;
                sext_op_o = `EXT_U;
                alub_sel_o = `ALUB_EXT;
                alu_op_o = `ALU_SLL;
                wb_o = `WB_EXT;
            end
            7'b0010111: begin
                npc_op_o = `NPC_PC4;
                reg_wE_o = '1;
                sext_op_o = `EXT_U;
                alub_sel_o = `ALUB_EXT;
                alu_op_o = `ALU_SLL;
                wb_o = `WB_PCEXT;
            end
            7'b1101111: begin
                npc_op_o = `NPC_JAL;
                reg_wE_o = '1;
                alub_sel_o = `ALUB_EXT;
                sext_op_o = `EXT_J;
                alu_op_o = `ALU_ADD;
                wb_o = `WB_PC4;
            end
        endcase
    end
    
endmodule