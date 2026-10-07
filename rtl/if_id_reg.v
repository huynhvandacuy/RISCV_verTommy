module if_id_reg(
    input             clk_i,
    input             rst_ni,
    input      [31:0] instr_i,
    input      [31:0] pc_i,
    input             flush_i,
    input             write_en_i,
    output reg [31:0] instr_o,
    output reg [31:0] pc_o
);
    localparam NOP = 32'h0000_0013; // addi x0,x0,0

    always @(posedge clk_i or negedge rst_ni) begin
        if(!rst_ni) begin
            instr_o <= NOP;
            pc_o  <= 32'h0000_0000;
        end else if(flush_i) begin
            instr_o <= NOP;
            pc_o  <= 32'h0000_0000;
        end else if(write_en_i) begin
            instr_o <= instr_i;
            pc_o  <= pc_i;
        end
    end
endmodule
