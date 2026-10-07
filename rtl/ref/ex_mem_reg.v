module ex_mem_reg (
    input             clk,
    input             rst_n,
    input             flush,

    input      [31:0] alu_result_in,
    input      [31:0] rdata2_in,
    input      [ 4:0] rd_in,
    input             mem_read_in,
    input             mem_write_in,
    input             mem_to_reg_in,
    input             reg_write_in,
    input      [ 2:0] funct3_in,

    output reg [31:0] alu_result_out,
    output reg [31:0] rdata2_out,
    output reg [ 4:0] rd_out,
    output reg        mem_read_out,
    output reg        mem_write_out,
    output reg        mem_to_reg_out,
    output reg        reg_write_out,
    output reg [ 2:0] funct3_out
);
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            alu_result_out <= 32'b0;
            rdata2_out     <= 32'b0;
            rd_out         <= 5'b0;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;
            reg_write_out  <= 1'b0;
            funct3_out     <= 3'b000;
        end else if(flush) begin
            alu_result_out <= 32'b0;
            rdata2_out     <= 32'b0;
            rd_out         <= 5'b0;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;
            reg_write_out  <= 1'b0;
            funct3_out     <= 3'b000;
        end else begin
            alu_result_out <= alu_result_in;
            rdata2_out     <= rdata2_in;
            rd_out         <= rd_in;
            mem_read_out   <= mem_read_in;
            mem_write_out  <= mem_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            reg_write_out  <= reg_write_in;
            funct3_out     <= funct3_in;
        end
    end
endmodule
