module id_ex_reg(
    input             clk_i,
    input             rst_ni,
    input             flush_i,
    input             stall_i,

    // From ID
    input      [31:0] pc_i,
    input      [31:0] rs1_data_i,
    input      [31:0] rs2_data_i,
    input      [31:0] imm_i,
    input      [ 4:0] rs1_addr_i,
    input      [ 4:0] rs2_addr_i,
    input      [ 4:0] rd_addr_i,
    input      [ 2:0] funct3_i,
    input      [ 6:0] funct7_i,

    // Control
    input             alu_src_b_imm_i,
    input             wb_sel_mem_i,
    input             reg_write_en_i,
    input             mem_read_en_i,
    input             mem_write_en_i,
    input             branch_en_i,
    input             jal_en_i,
    input             jalr_en_i,
    input             alu_src_a_pc_i,
    input             alu_src_a_zero_i,
    input      [ 1:0] alu_class_i,

    // Out
    output reg [31:0] pc_o,
    output reg [31:0] rs1_data_o,
    output reg [31:0] rs2_data_o,
    output reg [31:0] imm_o,
    output reg [ 4:0] rs1_addr_o,
    output reg [ 4:0] rs2_addr_o,
    output reg [ 4:0] rd_addr_o,
    output reg [ 2:0] funct3_o,
    output reg [ 6:0] funct7_o,

    output reg        alu_src_b_imm_o,
    output reg        wb_sel_mem_o,
    output reg        reg_write_en_o,
    output reg        mem_read_en_o,
    output reg        mem_write_en_o,
    output reg        branch_en_o,
    output reg        jal_en_o,
    output reg        jalr_en_o,
    output reg        alu_src_a_pc_o,
    output reg        alu_src_a_zero_o,
    output reg [ 1:0] alu_class_o
);
    always @(posedge clk_i or negedge rst_ni) begin
        if(!rst_ni || flush_i) begin
            pc_o            <= 32'h0;
            rs1_data_o        <= 32'b0;
            rs2_data_o        <= 32'b0;
            imm_o           <= 32'b0;
            rs1_addr_o           <= 5'b0;
            rs2_addr_o           <= 5'b0;
            rd_addr_o            <= 5'b0;
            funct3_o        <= 3'b0;
            funct7_o        <= 7'b0;

            alu_src_b_imm_o        <= 1'b0;
            wb_sel_mem_o    <= 1'b0;
            reg_write_en_o     <= 1'b0;
            mem_read_en_o      <= 1'b0;
            mem_write_en_o     <= 1'b0;
            branch_en_o        <= 1'b0;
            jal_en_o           <= 1'b0;
            jalr_en_o          <= 1'b0;
            alu_src_a_pc_o   <= 1'b0;
            alu_src_a_zero_o <= 1'b0;
            alu_class_o         <= 2'b0;
        end else if(!stall_i) begin
            pc_o            <= pc_i;
            rs1_data_o        <= rs1_data_i;
            rs2_data_o        <= rs2_data_i;
            imm_o           <= imm_i;
            rs1_addr_o           <= rs1_addr_i;
            rs2_addr_o           <= rs2_addr_i;
            rd_addr_o            <= rd_addr_i;
            funct3_o        <= funct3_i;
            funct7_o        <= funct7_i;

            alu_src_b_imm_o        <= alu_src_b_imm_i;
            wb_sel_mem_o    <= wb_sel_mem_i;
            reg_write_en_o     <= reg_write_en_i;
            mem_read_en_o      <= mem_read_en_i;
            mem_write_en_o     <= mem_write_en_i;
            branch_en_o        <= branch_en_i;
            jal_en_o           <= jal_en_i;
            jalr_en_o          <= jalr_en_i;
            alu_src_a_pc_o   <= alu_src_a_pc_i;
            alu_src_a_zero_o <= alu_src_a_zero_i;
            alu_class_o         <= alu_class_i;
        end
    end
endmodule
