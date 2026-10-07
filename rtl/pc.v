module pc (
    input             clk_i,
    input             rst_ni,
    input      [31:0] pc_next_i,
    input             pc_write_en_i,
    output reg [31:0] pc_o
);

    parameter RESET_ADDR = 32'h8000_0000;

    always @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni)
            pc_o <= RESET_ADDR;
        else if (pc_write_en_i)
            pc_o <= pc_next_i;
    end
endmodule
