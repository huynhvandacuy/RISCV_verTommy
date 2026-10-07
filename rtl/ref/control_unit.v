module control_unit (
    input  wire [6:0] opcode_i,
    output reg        reg_write_en_o,
    output reg        mem_read_en_o,
    output reg        wb_sel_mem_o,
    output reg        MemtoReg,
    output reg        alu_src_b_imm_o,
    output reg        branch_en_o,
    output reg        Jal,
    output reg        jalr_en_o,
    output reg        UsePcSrcA,
    output reg        UseZeroSrcA,
    output reg [1:0]  ALUOp
);

    localparam R_TYPE  = 7'b0110011;
    localparam I_TYPE  = 7'b0010011;
    localparam LOAD    = 7'b0000011;
    localparam STORE   = 7'b0100011;
    localparam branch_en_o  = 7'b1100011;
    localparam LUI     = 7'b0110111;
    localparam AUIPC   = 7'b0010111;
    localparam JAL     = 7'b1101111;
    localparam jalr_en_o    = 7'b1100111;

    always @(*) begin
        reg_write_en_o    = 1'b0;
        mem_read_en_o     = 1'b0;
        wb_sel_mem_o    = 1'b0;
        MemtoReg    = 1'b0;
        alu_src_b_imm_o      = 1'b0;
        branch_en_o      = 1'b0;
        Jal         = 1'b0;
        jalr_en_o        = 1'b0;
        UsePcSrcA   = 1'b0;
        UseZeroSrcA = 1'b0;
        ALUOp       = 2'b00;

        case (opcode_i)
            R_TYPE: begin
                reg_write_en_o = 1'b1;
                ALUOp    = 2'b10;
            end
            I_TYPE: begin
                reg_write_en_o = 1'b1;
                alu_src_b_imm_o   = 1'b1;
                ALUOp    = 2'b11;
            end
            LOAD: begin
                reg_write_en_o = 1'b1; alu_src_b_imm_o = 1'b1; mem_read_en_o = 1'b1; MemtoReg = 1'b1;
                ALUOp    = 2'b00;
            end
            STORE: begin
                alu_src_b_imm_o   = 1'b1; wb_sel_mem_o = 1'b1;
                ALUOp    = 2'b00;
            end
            branch_en_o: begin
                branch_en_o   = 1'b1;
                ALUOp    = 2'b01;
            end
            LUI: begin
                reg_write_en_o    = 1'b1;
                alu_src_b_imm_o      = 1'b1;
                UseZeroSrcA = 1'b1;
                ALUOp       = 2'b00;
            end
            AUIPC: begin
                reg_write_en_o  = 1'b1;
                alu_src_b_imm_o    = 1'b1;
                UsePcSrcA = 1'b1;
                ALUOp     = 2'b00;
            end
            JAL: begin
                reg_write_en_o = 1'b1;
                Jal      = 1'b1;
            end
            jalr_en_o: begin
                reg_write_en_o = 1'b1;
                alu_src_b_imm_o   = 1'b1;
                jalr_en_o     = 1'b1;
            end
            default: ;
        endcase
    end
endmodule