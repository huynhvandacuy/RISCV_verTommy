module ID_EX(
    input             clk,
    input             rst_n,
    input             flush,
    input             stall,

    // From ID
    input      [31:0] pc_in,
    input      [31:0] rdata1_in,
    input      [31:0] rdata2_in,
    input      [31:0] imm_in,
    input      [ 4:0] rs1_in,
    input      [ 4:0] rs2_in,
    input      [ 4:0] rd_in,
    input      [ 2:0] funct3_in,
    input      [ 6:0] funct7_in,

    // Control
    input             aluSrc_in,
    input             mem_to_reg_in,
    input             reg_write_in,
    input             mem_read_in,
    input             mem_write_in,
    input             branch_in,
    input             jal_in,
    input             jalr_in,
    input             use_pc_srcA_in,
    input             use_zero_srcA_in,
    input      [ 1:0] aluOp_in,

    // Out
    output reg [31:0] pc_out,
    output reg [31:0] rdata1_out,
    output reg [31:0] rdata2_out,
    output reg [31:0] imm_out,
    output reg [ 4:0] rs1_out,
    output reg [ 4:0] rs2_out,
    output reg [ 4:0] rd_out,
    output reg [ 2:0] funct3_out,
    output reg [ 6:0] funct7_out,

    output reg        aluSrc_out,
    output reg        mem_to_reg_out,
    output reg        reg_write_out,
    output reg        mem_read_out,
    output reg        mem_write_out,
    output reg        branch_out,
    output reg        jal_out,
    output reg        jalr_out,
    output reg        use_pc_srcA_out,
    output reg        use_zero_srcA_out,
    output reg [ 1:0] aluOp_out
);
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n || flush) begin
            pc_out            <= 32'h0;
            rdata1_out        <= 32'b0;
            rdata2_out        <= 32'b0;
            imm_out           <= 32'b0;
            rs1_out           <= 5'b0;
            rs2_out           <= 5'b0;
            rd_out            <= 5'b0;
            funct3_out        <= 3'b0;
            funct7_out        <= 7'b0;

            aluSrc_out        <= 1'b0;
            mem_to_reg_out    <= 1'b0;
            reg_write_out     <= 1'b0;
            mem_read_out      <= 1'b0;
            mem_write_out     <= 1'b0;
            branch_out        <= 1'b0;
            jal_out           <= 1'b0;
            jalr_out          <= 1'b0;
            use_pc_srcA_out   <= 1'b0;
            use_zero_srcA_out <= 1'b0;
            aluOp_out         <= 2'b0;
        end else if(!stall) begin
            pc_out            <= pc_in;
            rdata1_out        <= rdata1_in;
            rdata2_out        <= rdata2_in;
            imm_out           <= imm_in;
            rs1_out           <= rs1_in;
            rs2_out           <= rs2_in;
            rd_out            <= rd_in;
            funct3_out        <= funct3_in;
            funct7_out        <= funct7_in;

            aluSrc_out        <= aluSrc_in;
            mem_to_reg_out    <= mem_to_reg_in;
            reg_write_out     <= reg_write_in;
            mem_read_out      <= mem_read_in;
            mem_write_out     <= mem_write_in;
            branch_out        <= branch_in;
            jal_out           <= jal_in;
            jalr_out          <= jalr_in;
            use_pc_srcA_out   <= use_pc_srcA_in;
            use_zero_srcA_out <= use_zero_srcA_in;
            aluOp_out         <= aluOp_in;
        end
    end
endmodule
