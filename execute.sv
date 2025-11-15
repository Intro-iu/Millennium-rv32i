`timescale 1ns / 1ps

`include "defines.svh"

module execute (
    input  [31:0] deD_i1,
    input  [31:0] deD_i2,
    input  [31:0] ext_i,
    input         alub_sel_i,
    input  [ 3:0] alu_op_i,
    
    output [31:0] alu_o,
    output        alu_o0
);
    logic [31:0] alu_b;
    assign alu_b = alub_sel_i == `ALUB_EXT ? ext_i : deD_i2;
    ALU execute_ALU (
        .A(deD_i1),
        .B(alu_b),
        .ALUOp(alu_op_i),
        .Result(alu_o),
        .Zero(alu_o0)
    );
    
endmodule

module ALU (
    input  logic [31:0] A,
    input  logic [31:0] B,
    input  logic [ 3:0] ALUOp,

    output logic [31:0] Result,       // 结果
    output logic        Zero,         // 为零
    output logic        Carry,        // 进位
    output logic        Overflow      // 溢出
);
    // ALU操作
    always_comb begin
        // 默认值
        Result   = '1;
        Carry    = '0;
        Overflow = '0;
        Zero     = '0;

        case (ALUOp)
            `ALU_ADD: begin // A + B
                {Carry, Result} = A + B;
                Overflow = A[31] == B[31] && A[31] != Result[31] ? '1 : '0;
            end
            `ALU_SUB: begin // A - B
                {Carry, Result} = A - B;
                Overflow = A[31] != B[31] && A[31] != Result[31] ? '1 : '0;
            end
            `ALU_AND:   Result = A & B;
            `ALU_OR:    Result = A | B;
            `ALU_XOR:   Result = A ^ B;
            `ALU_SLL:   Result = A << B[4:0];
            `ALU_SRL:   Result = A >> B[4:0];
            `ALU_SRA:   Result = $signed(A) >>> B[4:0];
            `ALU_SLT:   Result = ($signed(A) < $signed(B)) ? '0 : '1;
            `ALU_SLTU:  Result = (A < B) ? '0 : '1;
        endcase
        Zero = Result == 32'b0 ? '1 : '0;
    end
endmodule