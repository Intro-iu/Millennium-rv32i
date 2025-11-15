//Copyright (C)2014-2025 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11.03 (64-bit) 
//Created Time: 2025-08-28 22:46:49
create_clock -name fpga_clk -period 20 -waveform {0 10} [get_ports {fpga_clk}]