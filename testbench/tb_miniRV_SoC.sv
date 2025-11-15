`timescale 1ns / 1ps
//
// Testbench for miniRV_SoC
//

module tb_miniRV_SoC;

    // Clock period for 30MHz
    localparam CLK_PERIOD = 33.33;

    // DUT Inputs
    reg fpga_rst_n;
    reg fpga_clk;

    // DUT Outputs
    wire dig_dio, dig_sclk, dig_rclk;

    // Instantiate the Unit Under Test (UUT)
    // The signals to be monitored (inst_addr, Bus_wdata, wdata_to_dig) are internal to the uut.
    // In Vivado's waveform viewer, you can add them by navigating the hierarchy.
    miniRV_SoC uut (
        .fpga_rst_n(fpga_rst_n),
        .fpga_clk(fpga_clk),
        .dig_dio(dig_dio),
        .dig_sclk(dig_sclk),
        .dig_rclk(dig_rclk)
    );

    // Clock generation process
    initial begin
        fpga_clk = 0;
        forever #(CLK_PERIOD / 2) fpga_clk = ~fpga_clk;
    end

    // Stimulus process
    initial begin
        // Initialize Inputs
        fpga_rst_n = 1'b0; // Assert reset (active low)

        // Wait for global reset
        repeat(5) @(posedge fpga_clk);

        // De-assert reset
        fpga_rst_n = 1'b1;

        // Wait for some time to observe the behavior
        repeat(20000) @(posedge fpga_clk);

        // Stop the simulation
        $display("Simulation Finished");
        $finish;
    end

endmodule
