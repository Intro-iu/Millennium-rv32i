// module seg(
//     input  rst_i,
//     input  clk_i,
//     input  we_i,
//     input  logic [31:0] wdata_i,
//     output logic [7:0]  led_seg_o
// );
//     logic [31:0] data;
//     wire [3:0] digit;

//     always @(posedge clk_i or negedge rst_i) begin
//         if (!rst_i) begin
//             data <= 32'hAAAA;
//         end else if (we_i) begin
//             data <= wdata_i;
//         end
//     end
    
//     assign digit = data[3:0];
//     always_comb begin
//         case(digit)
//             4'h0: led_seg_o = 8'b00000011;
//             4'h1: led_seg_o = 8'b10011111;
//             4'h2: led_seg_o = 8'b00100101;
//             4'h3: led_seg_o = 8'b00001101;
//             4'h4: led_seg_o = 8'b10011001;
//             4'h5: led_seg_o = 8'b01001001;
//             4'h6: led_seg_o = 8'b01000001;
//             4'h7: led_seg_o = 8'b00011111;
//             4'h8: led_seg_o = 8'b00000001;
//             4'h9: led_seg_o = 8'b00001001;
//             4'hA: led_seg_o = 8'b00010001;
//             4'hB: led_seg_o = 8'b11000001;
//             4'hC: led_seg_o = 8'b01100011;
//             4'hD: led_seg_o = 8'b10000101;
//             4'hE: led_seg_o = 8'b01100001;
//             4'hF: led_seg_o = 8'b01110001;
//             default: led_seg_o = 8'b00000000;
//         endcase
//     end


// endmodule

module dig (
    input              rst_i,
    input              clk_i,
    input              we_i,
    input logic [31:0] wdata_i,
    
    output [7: 0] addr_dig_o,
    output [7: 0] data_dig_o,
    output logic dio_o,
    output logic sclk_o,
    output logic rclk_o
);
    logic [2: 0] addr_curr, addr_next;
    wire [3: 0] digit;
    logic [31: 0] data;
    logic [15:0] scan_counter;
    bit [7:0] dig_code [15:0] = '{
        8'b01110001, 8'b01100001, 8'b10000101, 8'b01100011, 
        8'b11000001, 8'b00010001, 8'b00001001, 8'b00000001, 
        8'b00011111, 8'b01000001, 8'b01001001, 8'b10011001, 
        8'b00001101, 8'b00100101, 8'b10011111, 8'b00000011
    };

    wire scan_clk;
    wire [15: 0] data_seq;
    assign data_seq[ 7: 0] = data_dig_o;
    assign data_seq[15: 8] = addr_dig_o;
    assign scan_clk = (scan_counter >= 16'd32);

    always_ff @(posedge clk_i or negedge rst_i) begin
        if (!rst_i) begin
            rclk_o <= '1;
            scan_counter <= '0;
        end else begin
            rclk_o <= '0;
            if (scan_counter == 16'd16) begin
                rclk_o <= '1;
            end
            if (scan_counter == 16'd32) begin
                scan_counter <= 16'd0;
            end else begin
                if (scan_counter <= 4'hF) begin
                    dio_o <= data_seq[scan_counter];
                end
                if (we_i) scan_counter <= 16'd0;
                else scan_counter <= scan_counter + 1;
            end
        end
    end
  
    assign addr_next = addr_curr + 1;

    always_ff @(posedge clk_i or negedge rst_i) begin
        if (!rst_i) begin
            data <= '0;
        end else if (we_i) begin
            data <= wdata_i;
        end
    end

    always_ff @(posedge clk_i or negedge rst_i) begin
        if (!rst_i) begin
            addr_curr <= '0;
        end else if (scan_clk) begin
            addr_curr <= addr_next;
        end
    end

    assign digit =  (addr_curr == 0) ? data[ 3: 0] :
                    (addr_curr == 1) ? data[ 7: 4] :
                    (addr_curr == 2) ? data[11: 8] :
                    (addr_curr == 3) ? data[15:12] :
                    (addr_curr == 4) ? data[19:16] :
                    (addr_curr == 5) ? data[23:20] :
                    (addr_curr == 6) ? data[27:24] :
                    (addr_curr == 7) ? data[31:28] : 
                    '0;

    assign sclk_o = clk_i & ~rclk_o;
    assign addr_dig_o = ~(8'b00000001 << addr_curr);
    assign data_dig_o = dig_code[digit];
endmodule