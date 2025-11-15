`timescale 1ns / 1ps

`include "defines.vh"

`define STATE_0 8'b00000001
`define STATE_1 8'b00000010
`define STATE_2 8'b00000100
`define STATE_3 8'b00001000
`define STATE_4 8'b00010000
`define STATE_5 8'b00100000
`define STATE_6 8'b01000000
`define STATE_7 8'b10000000

module Digit (
    input  wire        rst_i,
    input  wire        clk_i,
    input  wire        we_i,
    input  wire [31:0] wdata_i,
    output wire [ 7:0] dig_en_o,
    output wire [ 7:0] led_seg_o
);
    reg [31:0] data;
    reg [7:0] current_state;
    wire [7:0] next_state;
    wire [3:0] digit;
    reg [15:0] scan_counter;
    wire scan_clk;

    assign scan_clk = (scan_counter == 16'd50000);

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            scan_counter <= 16'd0;
        end else begin
            if (scan_counter == 16'd50000) begin
                scan_counter <= 16'd0;
            end else begin
                scan_counter <= scan_counter + 1;
            end
        end
    end

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            data <= 32'hABCD;
        end else if (we_i) begin
            data <= wdata_i;
        end
    end

    assign next_state = (current_state == `STATE_0) ? `STATE_1 :
                        (current_state == `STATE_1) ? `STATE_2 :
                        (current_state == `STATE_2) ? `STATE_3 :
                        (current_state == `STATE_3) ? `STATE_4 :
                        (current_state == `STATE_4) ? `STATE_5 :
                        (current_state == `STATE_5) ? `STATE_6 :
                        (current_state == `STATE_6) ? `STATE_7 :
                        `STATE_0;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            current_state <= `STATE_0;
        end else if (scan_clk) begin
            current_state <= next_state;
        end
    end

    // 低电平有效
    assign dig_en_o = ~current_state;

    assign digit = (current_state == `STATE_0) ? data[3:0] :
                   (current_state == `STATE_1) ? data[7:4] :
                   (current_state == `STATE_2) ? data[11:8] :
                   (current_state == `STATE_3) ? data[15:12] :
                   (current_state == `STATE_4) ? data[19:16] :
                   (current_state == `STATE_5) ? data[23:20] :
                   (current_state == `STATE_6) ? data[27:24] :
                   (current_state == `STATE_7) ? data[31:28] : 4'b0000;

    // 低电平有效
    assign led_seg_o = (digit == 4'h0) ? 8'b00000011:
                       (digit == 4'h1) ? 8'b10011111:
                       (digit == 4'h2) ? 8'b00100101:
                       (digit == 4'h3) ? 8'b00001101:
                       (digit == 4'h4) ? 8'b10011001:
                       (digit == 4'h5) ? 8'b01001001:
                       (digit == 4'h6) ? 8'b01000001:
                       (digit == 4'h7) ? 8'b00011111:
                       (digit == 4'h8) ? 8'b00000001:
                       (digit == 4'h9) ? 8'b00001001:
                       (digit == 4'hA) ? 8'b00010001:
                       (digit == 4'hB) ? 8'b11000001:
                       (digit == 4'hC) ? 8'b01100011:
                       (digit == 4'hD) ? 8'b10000101:
                       (digit == 4'hE) ? 8'b01100001:
                       (digit == 4'hF) ? 8'b01110001:
                                8'b00000000;
endmodule
