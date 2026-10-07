module pc (
    input             clk,
    input             rst_n,
    input      [31:0] pc_next,
    input             pc_write,
    output reg [31:0] pc_out
);

    parameter RESET_ADDR = 32'h8000_0000;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            pc_out <= RESET_ADDR;
        else if (pc_write)
            pc_out <= pc_next;
    end
endmodule
