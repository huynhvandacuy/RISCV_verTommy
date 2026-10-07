module ex_mem_reg(
    input             clk_i,
    input             rst_ni,
    input             flush_i,

    input      [31:0] exec_result_i,
    input      [31:0] store_data_i,
    input      [ 4:0] rd_addr_i,
    input             mem_read_en_i,
    input             mem_write_en_i,
    input             wb_sel_mem_i,
    input             reg_write_en_i,
    input      [ 2:0] funct3_i,

    output reg [31:0] exec_result_o,
    output reg [31:0] store_data_o,
    output reg [ 4:0] rd_addr_o,
    output reg        mem_read_en_o,
    output reg        mem_write_en_o,
    output reg        wb_sel_mem_o,
    output reg        reg_write_en_o,
    output reg [ 2:0] funct3_o
);
    always @(posedge clk_i or negedge rst_ni) begin
        if(!rst_ni) begin
            exec_result_o <= 32'b0;
            store_data_o     <= 32'b0;
            rd_addr_o         <= 5'b0;
            mem_read_en_o   <= 1'b0;
            mem_write_en_o  <= 1'b0;
            wb_sel_mem_o <= 1'b0;
            reg_write_en_o  <= 1'b0;
            funct3_o     <= 3'b000;
        end else if(flush_i) begin
            exec_result_o <= 32'b0;
            store_data_o     <= 32'b0;
            rd_addr_o         <= 5'b0;
            mem_read_en_o   <= 1'b0;
            mem_write_en_o  <= 1'b0;
            wb_sel_mem_o <= 1'b0;
            reg_write_en_o  <= 1'b0;
            funct3_o     <= 3'b000;
        end else begin
            exec_result_o <= exec_result_i;
            store_data_o     <= store_data_i;
            rd_addr_o         <= rd_addr_i;
            mem_read_en_o   <= mem_read_en_i;
            mem_write_en_o  <= mem_write_en_i;
            wb_sel_mem_o <= wb_sel_mem_i;
            reg_write_en_o  <= reg_write_en_i;
            funct3_o     <= funct3_i;
        end
    end
endmodule
