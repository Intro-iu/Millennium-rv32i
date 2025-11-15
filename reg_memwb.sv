module reg_memrb(
    input         rst_i,
    input         clk_i,
    input  [31:0] wD_i,

    output [31:0] reg_wD_i
);
    logic [31:0] reg_wD;

    always @ (posedge clk_i or negedge rst_i) begin
        if (~rst_i) begin
            reg_wD <= '0;
        end else begin
            reg_wD <= wD_i;
        end
    end

    assign reg_wD_i = reg_wD;

endmodule