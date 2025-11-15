// Annotate this macro before synthesis
// `define RUN_TRACE
// `define SIMULATION_MODE

// TODO: 在此处定义你的宏
// 

// ALU操作码
`define ALU_ADD  4'b0000
`define ALU_SUB  4'b0001
`define ALU_AND  4'b0010
`define ALU_OR   4'b0011
`define ALU_XOR  4'b0100
`define ALU_SLL  4'b0101
`define ALU_SRL  4'b0110
`define ALU_SRA  4'b0111
`define ALU_SLT  4'b1000
`define ALU_SLTU 4'b1001

`define ALUB_EXT 1'b0
`define ALUB_REG 1'b1

`define NPC_PC4 2'b00
`define NPC_BR 2'b01
`define NPC_JALR 2'b10
`define NPC_JAL 2'b11

`define EXT_I_0 3'b110
`define EXT_I_1 3'b111
`define EXT_S   3'b001
`define EXT_B   3'b010
`define EXT_U   3'b011
`define EXT_J   3'b100

`define DRAM_R   1'b0
`define DRAM_W   1'b1

`define WB_ALU   3'b000
`define WB_ALU0  3'b001
`define WB_RAM   3'b010
`define WB_PC4   3'b100
`define WB_EXT   3'b101
`define WB_PCEXT 3'b110

// 外设I/O接口电路的端口地址
`define PERI_ADDR_DIG 32'h0000_0008
`define PERI_ADDR_LED 32'hFFFF_F060
`define PERI_ADDR_SW 32'hFFFF_F070
`define PERI_ADDR_BTN 32'hFFFF_F078
