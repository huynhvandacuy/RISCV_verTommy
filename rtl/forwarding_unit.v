module forwarding_unit(
    input      [4:0] rs1_addr_ex_i,
    input      [4:0] rs2_addr_ex_i,
    input      [4:0] rd_addr_mem_i,
    input      [4:0] rd_addr_wb_i,
    input            reg_write_en_mem_i,
    input            reg_write_en_wb_i,
    output reg [1:0] forward_a_sel_o,
    output reg [1:0] forward_b_sel_o
);
    always @(*) begin
        forward_a_sel_o = 2'b00;
        forward_b_sel_o = 2'b00;

        // MEM -> EX forwarding (priority cao hơn)
        if(reg_write_en_mem_i && (rd_addr_mem_i != 5'd0) && (rd_addr_mem_i == rs1_addr_ex_i)) begin
            forward_a_sel_o = 2'b10;
        end else if(reg_write_en_wb_i && (rd_addr_wb_i != 5'd0) && (rd_addr_wb_i == rs1_addr_ex_i)) begin
            forward_a_sel_o = 2'b01;
        end

        if (reg_write_en_mem_i && (rd_addr_mem_i != 5'd0) && (rd_addr_mem_i == rs2_addr_ex_i)) begin
            forward_b_sel_o = 2'b10;
        end else if (reg_write_en_wb_i && (rd_addr_wb_i != 5'd0) && (rd_addr_wb_i == rs2_addr_ex_i)) begin
            forward_b_sel_o = 2'b01;
        end
    end
endmodule
