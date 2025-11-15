`timescale 1ns / 1ps

`include "defines.svh"

module myCPU (
    input wire cpu_rst,
    input wire cpu_clk,

    // Interface to IROM
`ifdef RUN_TRACE
    output wire [15:0] inst_addr,
`else
    output wire [13:0] inst_addr,
`endif
    input  wire [31:0] inst,

    // Interface to Bridge
    output wire [31:0] Bus_addr,
    input  wire [31:0] Bus_rdata,
    output wire        Bus_we,
    output wire [31:0] Bus_wdata

`ifdef RUN_TRACE
    ,
    // Debug Interface
    output wire        debug_wb_have_inst,
    output wire [31:0] debug_wb_pc,
    output             debug_wb_ena,
    output wire [ 4:0] debug_wb_reg,
    output wire [31:0] debug_wb_value
`endif
);
    logic reg_wE, alub_sel, alu_rev, alu0;
    logic [ 1:0] bit_addr, npc_op;
    logic [ 2:0] sext_op, wb;
    logic [ 3:0] alu_op;
    logic [31:0] pc, rD1, rD2, dD, ext, wD, alu, pc4;
    assign inst_addr = pc[15:2];
    assign Bus_addr  = alu;
    assign bit_addr  = alu[1:0];
    assign Bus_wdata = dD;

    control CTRL (
        .opcode_i(ifid_inst[6:0]),
        .funct3_i(ifid_inst[14:12]),
        .funct7_i(ifid_inst[31:25]),
        .reg_wE_o(reg_wE),
        .npc_op_o(npc_op),
        .sext_op_o(sext_op),
        .alub_sel_o(alub_sel),
        .alu_op_o(alu_op),
        .alu_rev_o(alu_rev),
        .dram_we_o(Bus_we),
        .wb_o(wb)
    );

    logic [31:0] ifid_pc, ifid_inst;
    logic ifid_flush;

    wire        redir_id;     // ID 级决定的跳转 `JAL`
    wire [31:0] id_target;    // IF/ID.PC + imm
    
    wire        redir_ex;     // EX 级决定的跳转 `JALR` 或 `分支成立`
    wire [31:0] ex_target;    // JALR: alu&~1；分支成立: ifid_pc + ext

    assign redir_id  = (npc_op == `NPC_JAL);
    assign id_target = ifid_pc + ext;
    
    assign redir_ex  = (npc_op == `NPC_JALR) |
                       ((npc_op == `NPC_BR) && (alu_rev ^ alu0));
    
    assign ex_target = (npc_op == `NPC_JALR) ? (alu & ~32'h1)
                                             : (ifid_pc + ext); // 分支成立时
    
    // 如暂时没有stall机制，先常0
    wire stall_if  = 1'b0;
    wire stall_id  = 1'b0;
    
    ifetch IF (
        .rst_i        (cpu_rst),
        .clk_i        (cpu_clk),
    
        .redir_id_i   (redir_id),       // JAL
        .id_target_i  (id_target),      // ifid_pc + ext
    
        .redir_ex_i   (redir_ex),       // JALR / BR-true
        .ex_target_i  (ex_target),
    
        .stall_if_i   (stall_if),
        .stall_id_i   (stall_id),
    
        .pc_o         (pc),             // IROM 接口 
        .inst_i       (inst),
    
        .ifid_flush_o (ifid_flush),
        .ifid_pc_o    (ifid_pc),        // 给下级用
        .ifid_inst_o  (ifid_inst)
    );

    idecode ID (
        .clk_i(cpu_clk),
        .inst_i(ifid_inst),
        .sext_op_i(sext_op),
        .wE_i(reg_wE),
        .alu_i(alu),
        .alu_i0(alu0),
        .dram_i(Bus_rdata),
        .bit_addr_i(bit_addr),
        .pc_i(ifid_pc),
        .rf_sel_i(wb),
        .rD_o1(rD1),
        .rD_o2(rD2),
        .dD_o(dD),
        .ext_o(ext),
        .wD_o(wD)
    );

    execute EX (
        .deD_i1(rD1),
        .deD_i2(rD2),
        .ext_i(ext),
        .alub_sel_i(alub_sel),
        .alu_op_i(alu_op),
        .alu_o(alu),
        .alu_o0(alu0)
    );

    // reg_memrb regMEMWB (
    //     .rst_i(cpu_rst),
    //     .clk_i(cpu_clk),
    //     .wD_i(),
    
    //     .reg_wD_i()
    // );

    `ifdef RUN_TRACE
        assign debug_wb_have_inst = ~ifid_flush;
        assign debug_wb_pc        = ifid_pc;
        assign debug_wb_ena       = reg_wE;
        assign debug_wb_reg       = ifid_inst[11:7];
        assign debug_wb_value     = wD;
    `endif

endmodule
