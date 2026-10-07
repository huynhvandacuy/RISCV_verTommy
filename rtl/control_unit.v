module control_unit (
    input  wire [6:0] opcode,
    output reg        RegWrite,
    output reg        MemRead,
    output reg        MemWrite,
    output reg        MemtoReg,
    output reg        ALUSrc,
    output reg        Branch,
    output reg        Jal,
    output reg        Jalr,
    output reg        UsePcSrcA,
    output reg        UseZeroSrcA,
    output reg [1:0]  ALUOp
);

    localparam R_TYPE  = 7'b0110011;
    localparam I_TYPE  = 7'b0010011;
    localparam LOAD    = 7'b0000011;
    localparam STORE   = 7'b0100011;
    localparam BRANCH  = 7'b1100011;
    localparam LUI     = 7'b0110111;
    localparam AUIPC   = 7'b0010111;
    localparam JAL     = 7'b1101111;
    localparam JALR    = 7'b1100111;

    always @(*) begin
        RegWrite    = 1'b0;
        MemRead     = 1'b0;
        MemWrite    = 1'b0;
        MemtoReg    = 1'b0;
        ALUSrc      = 1'b0;
        Branch      = 1'b0;
        Jal         = 1'b0;
        Jalr        = 1'b0;
        UsePcSrcA   = 1'b0;
        UseZeroSrcA = 1'b0;
        ALUOp       = 2'b00;

        case (opcode)
            R_TYPE: begin
                RegWrite = 1'b1;
                ALUOp    = 2'b10;
            end
            I_TYPE: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
                ALUOp    = 2'b11;
            end
            LOAD: begin
                RegWrite = 1'b1; ALUSrc = 1'b1; MemRead = 1'b1; MemtoReg = 1'b1;
                ALUOp    = 2'b00;
            end
            STORE: begin
                ALUSrc   = 1'b1; MemWrite = 1'b1;
                ALUOp    = 2'b00;
            end
            BRANCH: begin
                Branch   = 1'b1;
                ALUOp    = 2'b01;
            end
            LUI: begin
                RegWrite    = 1'b1;
                ALUSrc      = 1'b1;
                UseZeroSrcA = 1'b1;
                ALUOp       = 2'b00;
            end
            AUIPC: begin
                RegWrite  = 1'b1;
                ALUSrc    = 1'b1;
                UsePcSrcA = 1'b1;
                ALUOp     = 2'b00;
            end
            JAL: begin
                RegWrite = 1'b1;
                Jal      = 1'b1;
            end
            JALR: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
                Jalr     = 1'b1;
            end
            default: ;
        endcase
    end
endmodule