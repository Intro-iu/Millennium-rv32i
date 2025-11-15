`timescale 1ns/1ps

module tb_dig;
    // 信号声明
    logic clk;
    logic rst_n;
    logic we;
    logic [31:0] wdata;
    wire [2:0] addr_dig;
    wire [7:0] data_dig;
    
    wire dio, sclk, rclk;

    // DUT 实例化
    dig uut (
        .rst_i      (rst_n),
        .clk_i      (clk),
        .we_i       (we),
        .wdata_i    (wdata),
        .addr_dig_o (addr_dig),
        .data_dig_o (data_dig),
        .dio_o      (dio),
        .sclk_o     (sclk),
        .rclk_o     (rclk)
        
    );

    // 时钟产生
    initial clk = 0;
    always #10 clk = ~clk;  // 50MHz 时钟，周期 20ns

    // 仿真流程
    initial begin
        // 初始化
        rst_n = 0;
        we    = 0;
        wdata = 32'h0;

        // 释放复位
        #100;
        rst_n = 1;

        // 写入数据 1234_5678
        #50;
        we    = 1;
        wdata = 32'h1234_5678;
        #20;
        we    = 0;

        // 等待一段时间，观察数码管扫描输出
        #500000;

        // 再写入另一个数据
        #100;
        we    = 1;
        wdata = 32'hDEAD_BEEF;
        #20;
        we    = 0;

    end
endmodule
