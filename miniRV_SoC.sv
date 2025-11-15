`timescale 1ns / 1ps

`include "defines.svh"

module miniRV_SoC (
    
`ifdef RUN_TRACE
    input wire fpga_rst,
`else
    input wire fpga_rst_n,  // Low active
`endif
    input wire fpga_clk,

    input  wire [23:0] sw,
    input  wire [ 4:0] button,
    output wire        dig_dio,
    output wire        dig_sclk,
    output wire        dig_rclk


`ifdef RUN_TRACE
    ,
    // Debug Interface
    output wire         debug_wb_have_inst, // 当前时钟周期是否有指令写回 (对单周期CPU，可在复位后恒置1)
    output wire [31:0]  debug_wb_pc,        // 当前写回的指令的PC (若wb_have_inst=0，此项可为任意值)
    output              debug_wb_ena,       // 指令写回时，寄存器堆的写使能 (若wb_have_inst=0，此项可为任意值)
    output wire [ 4:0]  debug_wb_reg,       // 指令写回时，写入的寄存器号 (若wb_ena或wb_have_inst=0，此项可为任意值)
    output wire [31:0]  debug_wb_value      // 指令写回时，写入寄存器的值 (若wb_ena或wb_have_inst=0，此项可为任意值)
`endif
);
    wire pll_lock;
    wire pll_clk;
    wire cpu_clk;

    // Interface between CPU and IROM
`ifdef RUN_TRACE
    wire fpga_rst_n;
    assign fpga_rst_n = ~fpga_rst;
    wire [15:0] inst_addr;
`else
    wire [13:0] inst_addr;
`endif
    /* verilator lint_off UNOPTFLAT */
    wire [31:0] inst;
    /* verilator lint_on UNOPTFLAT */

    // Interface between CPU and Bridge
    wire [31:0] Bus_rdata;
    wire [31:0] Bus_addr;
    wire        Bus_we;
    wire [31:0] Bus_wdata;

    // Interface between bridge and DRAM
    // wire         rst_bridge2dram;
    wire        clk_bridge2dram;
    wire [31:0] addr_bridge2dram;
    wire [31:0] rdata_dram2bridge;
    wire        we_bridge2dram;
    wire [31:0] wdata_bridge2dram;

    // Interface between bridge and peripherals
    // TODO: 在此定义总线桥与外设I/O接口电路模块的连接信号
    //
    wire rst_to_dig, clk_to_dig, we_to_dig;
    wire [31:0] addr_to_dig, wdata_to_dig;

    wire rst_to_led, clk_to_led, we_to_led; 
    wire [31:0] wdata_to_led;


`ifdef RUN_TRACE
    // Trace调试时，直接使用外部输入时钟
    assign cpu_clk = fpga_clk;
`else
`ifdef SIMULATION_MODE
    assign cpu_clk = fpga_clk;
`else
    // 下板时，使用PLL分频后的时钟
    assign cpu_clk = pll_clk & pll_lock;
    cpuclk Clkgen (
        // .resetn     (!fpga_rst),
        .clkin (fpga_clk),
        .clkout(pll_clk),
        .lock  (pll_lock)
    );
`endif
`endif

    myCPU Core_cpu (
        .cpu_rst(fpga_rst_n),
        .cpu_clk(cpu_clk),

        // Interface to IROM
        .inst_addr(inst_addr),
        .inst     (inst),

        // Interface to Bridge
        .Bus_addr (Bus_addr),
        .Bus_rdata(Bus_rdata),
        .Bus_we   (Bus_we),
        .Bus_wdata(Bus_wdata)

`ifdef RUN_TRACE
        ,
        // Debug Interface
        .debug_wb_have_inst(debug_wb_have_inst),
        .debug_wb_pc       (debug_wb_pc),
        .debug_wb_ena      (debug_wb_ena),
        .debug_wb_reg      (debug_wb_reg),
        .debug_wb_value    (debug_wb_value)
`endif
    );

    IROM Mem_IROM (
        `ifdef SIMULATION_MODE
        .a   (inst_addr),
        .spo (inst)
        `else
        .ad  (inst_addr),
        .dout(inst)
        `endif
    );

    DRAM Mem_DRAM (
        `ifdef SIMULATION_MODE
        .clk(clk_bridge2dram),
        .a  (addr_bridge2dram[15:2]),
        .spo(rdata_dram2bridge),
        .we (we_bridge2dram),
        .d  (wdata_bridge2dram)
        `else
        .clk(clk_bridge2dram),
        .ad  (addr_bridge2dram[15:2]),
        .dout(rdata_dram2bridge),
        .wre (we_bridge2dram),
        .di(wdata_bridge2dram)
        `endif
    );

    Bridge Bridge (
        // Interface to CPU
        .rst_from_cpu  (fpga_rst_n),
        .clk_from_cpu  (cpu_clk),
        .addr_from_cpu (Bus_addr),
        .we_from_cpu   (Bus_we),
        .wdata_from_cpu(Bus_wdata),
        .rdata_to_cpu  (Bus_rdata),

        // Interface to DRAM
        // .rst_to_dram    (rst_bridge2dram),
        .clk_to_dram    (clk_bridge2dram),
        .addr_to_dram   (addr_bridge2dram),
        .rdata_from_dram(rdata_dram2bridge),
        .we_to_dram     (we_bridge2dram),
        .wdata_to_dram  (wdata_bridge2dram),

        // Interface to 7-seg digital LEDs
        .rst_to_dig  (rst_to_dig),
        .clk_to_dig  (clk_to_dig),
        .addr_to_dig (addr_to_dig),
        .we_to_dig   (we_to_dig),
        .wdata_to_dig(wdata_to_dig),

        // Interface to LEDs
        .rst_to_led  (rst_to_led),
        .clk_to_led  (clk_to_led),
        .addr_to_led (  /* TODO */),
        .we_to_led   (we_to_led),
        .wdata_to_led(wdata_to_led),

        // Interface to switches
        .rst_to_sw    (  /* TODO */),
        .clk_to_sw    (  /* TODO */),
        .addr_to_sw   (  /* TODO */),
        .rdata_from_sw(  /* TODO */),

        // Interface to buttons
        .rst_to_btn    (  /* TODO */),
        .clk_to_btn    (  /* TODO */),
        .addr_to_btn   (  /* TODO */),
        .rdata_from_btn(  /* TODO */)
    );

    // TODO: 在此实例化你的外设I/O接口电路模块
    //
    
    dig led_dig (
        .rst_i(fpga_rst_n),
        .clk_i(clk_to_dig),
        .we_i(we_to_dig),
        .wdata_i(wdata_to_dig),
        
        .addr_dig_o(),
        .data_dig_o(),
        .dio_o(dig_dio),
        .sclk_o(dig_sclk),
        .rclk_o(dig_rclk)
    );

endmodule
