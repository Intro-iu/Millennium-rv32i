`timescale 1ns / 1ps

`include "defines.svh"

// Top-level ifetch module
module ifetch (
    input         rst_i,
    input         clk_i,

    // 来自ID/EX的控制
    input         redir_id_i,        // JAL
    input  [31:0] id_target_i,       // IF/ID.PC + imm

    input         redir_ex_i,        // JALR / 分支成立
    input  [31:0] ex_target_i,       // 由EX算好的最终目标

    input         stall_if_i,        // ICache miss
    input         stall_id_i,        // 数据冒险导致ID停

    // 取指存储器接口
    output [31:0] pc_o,
    input  [31:0] inst_i,

    output        ifid_flush_o,
    // IF/ID 输出
    output [31:0] ifid_pc_o,
    output [31:0] ifid_inst_o
);

    wire [31:0] pc, npc, pc4;

    NPC u_npc (
        .pc_i       (pc),
        .id_target_i(id_target_i),
        .ex_target_i(ex_target_i),
        .redir_id_i (redir_id_i),
        .redir_ex_i (redir_ex_i),
        .npc_o      (npc),
        .pc4_o      (pc4)
    );

    PC u_pc (
        .rst_i(rst_i),
        .clk_i(clk_i),
        .en_i(!stall_if_i),
        .d_i(npc),
        .pc_o(pc)
    );
    assign pc_o = pc;

    // IF/ID（flush 由“谁决定跳转”而来）
    wire flush_ifid = redir_id_i | redir_ex_i;

    reg_ifid u_ifid (
        .rst_i   (rst_i),
        .clk_i   (clk_i),
        .en_i    (!stall_id_i),
        .flush_i (flush_ifid),
        .pc_i    (pc),
        .inst_i  (inst_i),

        .ifid_flush_o (ifid_flush_o),
        .ifid_pc_o    (ifid_pc_o),
        .ifid_inst_o  (ifid_inst_o)
    );

endmodule

// PC Register module
module PC (
    input  rst_i,           // 建议用同步复位更干净
    input  clk_i,
    input  en_i,            // = !stall_if
    input  [31:0] d_i,
    output logic [31:0] pc_o
);
    always @(posedge clk_i or negedge rst_i) begin
        if (!rst_i)     pc_o <= 32'h0000_0000; // RESET_PC
        else if (en_i) pc_o <= d_i;
    end
endmodule


module NPC (
    input  [31:0] pc_i,          // 全局PC当前值（给顺序pc+4用）
    input  [31:0] id_target_i,   // 来自ID级（如JAL): IF/ID.PC + imm
    input  [31:0] ex_target_i,   // 来自EX级（如JALR/BEQ真）: 由EX算出
    input         redir_id_i,    // 本拍由ID决定重定向（JAL）
    input         redir_ex_i,    // 本拍由EX决定重定向（分支成立/JALR）
    output [31:0] npc_o,
    output [31:0] pc4_o
);
    assign pc4_o = pc_i + 32'd4;

    // 优先级：EX > ID > 顺序
    assign npc_o = redir_ex_i ? ex_target_i :
                   redir_id_i ? id_target_i :
                   pc4_o;
endmodule

module reg_ifid(
    input         rst_i,
    input         clk_i,
    input         en_i,        // = !stall_id
    input         flush_i,     // flush 时注入NOP
    input  [31:0] pc_i,
    input  [31:0] inst_i,

    output logic        ifid_flush_o,
    output logic [31:0] ifid_pc_o,
    output logic [31:0] ifid_inst_o
);
    localparam logic [31:0] NOP = 32'h0000_0013; // ADDI x0,x0,0

    always @(posedge clk_i or negedge rst_i) begin
        if (!rst_i) begin
            ifid_flush_o <= '1;
            ifid_pc_o    <= '0;
            ifid_inst_o  <= NOP;          // 复位成 NOP
        end else if (flush_i) begin
            ifid_flush_o <= '1;
            ifid_pc_o    <= '0;           // 清零快照
            ifid_inst_o  <= NOP;          // NOP
        end else if (en_i) begin
            ifid_flush_o <= '0;
            ifid_pc_o    <= pc_i;         // 本拍PC快照
            ifid_inst_o  <= inst_i;       // 本拍取到的指令
        end
        // stall: 什么都不做，保持上拍
    end
endmodule