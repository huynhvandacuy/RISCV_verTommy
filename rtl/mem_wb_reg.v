module mem_wb_reg(
    input             clk_i,
    input             rst_ni,

    input             reg_write_en_i,
    input             wb_sel_mem_i,
    input      [31:0] load_data_i,
    input      [31:0] exec_result_i,
    input      [ 4:0] rd_addr_i,

    output reg        reg_write_en_o,
    output reg        wb_sel_mem_o,
    output reg [31:0] load_data_o,
    output reg [31:0] exec_result_o,
    output reg [ 4:0] rd_addr_o
);
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            reg_write_en_o   <= 1'b0;
            wb_sel_mem_o  <= 1'b0;
            load_data_o    <= 32'b0;
            exec_result_o  <= 32'b0;
            rd_addr_o          <= 5'b0;
        end else begin
            reg_write_en_o   <= reg_write_en_i;
            wb_sel_mem_o  <= wb_sel_mem_i;
            load_data_o    <= load_data_i;
            exec_result_o  <= exec_result_i;
            rd_addr_o          <= rd_addr_i;
        end
    end
endmodule
