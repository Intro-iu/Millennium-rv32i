`timescale 1ns / 1ps

`include "defines.svh"

module idecode (
    input clk_i,

    input  [31:0] inst_i,

    input  [ 2:0] sext_op_i,

    input         wE_i,
    input  [31:0] alu_i,
    input         alu_i0,
    input  [31:0] dram_i,
    input  [31:0] pc_i,
    input  [ 2:0] rf_sel_i,
    input  [ 1:0] bit_addr_i,

    output logic [31:0] rD_o1,
    output logic [31:0] rD_o2,
    output logic [31:0] dD_o,
    output logic [31:0] ext_o,
    output logic [31:0] wD_o
);
    logic [31:0] dram_ex, pc_ext;
    logic [ 4:0] rR1, rR2, wR;
    assign rR1 = inst_i[19:15];
    assign rR2 = inst_i[24:20];
    assign wR  = inst_i[11: 7];

    always_comb begin
        // Default assignments to prevent latches
        dD_o    = '0;
        dram_ex = '0;

        case (inst_i[14:12])
            3'b000: begin
                dram_ex = bit_addr_i == 2'b00 ? {{24{dram_i[ 7]}}, dram_i[ 7: 0]} :
                          bit_addr_i == 2'b01 ? {{24{dram_i[15]}}, dram_i[15: 8]} :
                          bit_addr_i == 2'b10 ? {{24{dram_i[23]}}, dram_i[23:16]} :
                          bit_addr_i == 2'b11 ? {{24{dram_i[31]}}, dram_i[31:24]} :
                          '0;
                dD_o    = bit_addr_i == 2'b00 ? {dram_i[31: 8],  rD_o2[ 7:0]} :
                          bit_addr_i == 2'b01 ? {dram_i[31:16],  rD_o2[ 7:0], dram_i[ 7:0]} :
                          bit_addr_i == 2'b10 ? {dram_i[31:24],  rD_o2[ 7:0], dram_i[15:0]} :
                          bit_addr_i == 2'b11 ? { rD_o2[ 7: 0], dram_i[23:0]} :
                          '0;
            end
            3'b001: begin
                dram_ex = bit_addr_i == 2'b00 ? {{24{dram_i[15]}}, dram_i[15: 0]} :
                          bit_addr_i == 2'b10 ? {{24{dram_i[31]}}, dram_i[31:16]} :
                          '0;
                dD_o    = bit_addr_i == 2'b00 ? {dram_i[31:16],  rD_o2[15:0]} :
                          bit_addr_i == 2'b10 ? { rD_o2[15: 0], dram_i[15:0]} :
                          '0;
            end
            3'b100: begin
                dram_ex = bit_addr_i == 2'b00 ? dram_i[ 7: 0] :
                          bit_addr_i == 2'b01 ? dram_i[15: 8] :
                          bit_addr_i == 2'b10 ? dram_i[23:16] :
                          bit_addr_i == 2'b11 ? dram_i[31:24] :
                          '0;
            end
            3'b101: begin
                dram_ex = bit_addr_i == 2'b00 ? dram_i[15: 0] :
                          bit_addr_i == 2'b10 ? dram_i[31:16] :
                          '0;
            end
            default: begin
                dram_ex = dram_i[31:0];
                dD_o    =  rD_o2[31:0];
            end
        endcase
    end

    RF_W_SEL idecode_rf_w_sel (
        .alu_i(alu_i),
        .alu_i0(alu_i0),
        .dram_ext_i(dram_ex),
        .pc_i(pc_i),
        .ext_i(ext_o),
        .rf_sel_i(rf_sel_i),
        .wD_o(wD_o)
    );

    RF idecode_rf (
        .clk_i(clk_i),
        .rR_i1(rR1),
        .rR_i2(rR2),
        .wE_i(wE_i),
        .wR_i(wR),
        .wD_i(wD_o),
        .rD_o1(rD_o1),
        .rD_o2(rD_o2)
    );


    SEXT idecode_sext (
        .inst_i(inst_i),
        .op_i(sext_op_i),
        .ext_o(ext_o)
    );

endmodule

module RF_W_SEL (
    input  [31:0] alu_i,
    input         alu_i0,
    input  [31:0] dram_ext_i,
    input  [31:0] pc_i,
    input  [31:0] ext_i,
    input  [ 2:0] rf_sel_i,

    output [31:0] wD_o
);
    assign wD_o = rf_sel_i == `WB_ALU   ? alu_i :
                  rf_sel_i == `WB_ALU0  ? alu_i0 :
                  rf_sel_i == `WB_RAM   ? dram_ext_i :
                  rf_sel_i == `WB_PC4   ? pc_i + 32'd4 :
                  rf_sel_i == `WB_EXT   ? ext_i :
                  rf_sel_i == `WB_PCEXT ? pc_i + ext_i :
                  '0;
endmodule

module RF (
    input clk_i,

    input  [ 4:0] rR_i1,
    input  [ 4:0] rR_i2,

    input wE_i,
    input  [ 4:0] wR_i,
    input  [31:0] wD_i,

    output [31:0] rD_o1,
    output [31:0] rD_o2
);
    logic [31:0] reg_file[31:0];

    assign rD_o1 = rR_i1 == '0 ? '0 : reg_file[rR_i1];
    assign rD_o2 = rR_i2 == '0 ? '0 : reg_file[rR_i2];

    always @(posedge clk_i) begin
        if (wE_i) begin
            case (wR_i)
                5'b00000: reg_file[wR_i] <= '0;
                default:  reg_file[wR_i] <= wD_i;
            endcase
        end
    end
    
endmodule

module SEXT (
    input  [31:0] inst_i,
    input  [ 2:0] op_i,

    output [31:0] ext_o
);
    assign ext_o = op_i == `EXT_I_0 ? inst_i[24:20] :
                   op_i == `EXT_I_1 ? {{20{inst_i[31]}}, inst_i[31:20]}  :
                   op_i == `EXT_S ? {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]} :
                   op_i == `EXT_B ? {{20{inst_i[31]}}, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0} :
                   op_i == `EXT_U ? {inst_i[31:12], 12'b0} :
                   op_i == `EXT_J ? {{12{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0} :
                   32'd4;
endmodule