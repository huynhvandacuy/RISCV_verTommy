module if_id_reg (
    input             clk,
    input             rst_n,
    input      [31:0] ins,
    input      [31:0] pc_in,
    input             flush,
    input             write_en,
    output reg [31:0] ins_out,
    output reg [31:0] pc_out
);
    localparam NOP = 32'h0000_0013; // addi x0,x0,0

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ins_out <= NOP;
            pc_out  <= 32'h0000_0000;
        end else if(flush) begin
            ins_out <= NOP;
            pc_out  <= 32'h0000_0000;
        end else if(write_en) begin
            ins_out <= ins;
            pc_out  <= pc_in;
        end
    end
endmodule
