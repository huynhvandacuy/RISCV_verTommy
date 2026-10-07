module alu_control (
    input  wire [1:0] alu_class_i,
    input  wire [2:0] funct3_i,
    input  wire       funct7_bit0_i,
    input  wire       funct7_bit5_i,
    output reg  [4:0] alu_op_o,
    output wire       is_m_op_o
);

    localparam OP_ADD  = 5'b00000;
    localparam OP_SUB  = 5'b00001;
    localparam OP_SLL  = 5'b00010;
    localparam OP_SLT  = 5'b00011;
    localparam OP_SLTU = 5'b00100;
    localparam OP_XOR  = 5'b00101;
    localparam OP_SRL  = 5'b00110;
    localparam OP_SRA  = 5'b00111;
    localparam OP_OR   = 5'b01000;
    localparam OP_AND  = 5'b01001;

    localparam OP_MUL    = 5'b10000;
    localparam OP_MULH   = 5'b10001;
    localparam OP_MULHSU = 5'b10010;
    localparam OP_MULHU  = 5'b10011;
    localparam OP_DIV    = 5'b10100;
    localparam OP_DIVU   = 5'b10101;
    localparam OP_REM    = 5'b10110;
    localparam OP_REMU   = 5'b10111;

    assign is_m_op_o = (alu_class_i == 2'b10) && funct7_bit0_i;

    always @(*) begin
        case (alu_class_i)
            2'b00: alu_op_o = OP_ADD;
            2'b01: alu_op_o = OP_SUB;

            2'b10: begin
                if (funct7_bit0_i) begin
                    case (funct3_i)
                        3'b000: alu_op_o = OP_MUL;
                        3'b001: alu_op_o = OP_MULH;
                        3'b010: alu_op_o = OP_MULHSU;
                        3'b011: alu_op_o = OP_MULHU;
                        3'b100: alu_op_o = OP_DIV;
                        3'b101: alu_op_o = OP_DIVU;
                        3'b110: alu_op_o = OP_REM;
                        3'b111: alu_op_o = OP_REMU;
                        default: alu_op_o = OP_ADD;
                    endcase
                end else begin
                    case (funct3_i)
                        3'b000: alu_op_o = (funct7_bit5_i) ? OP_SUB : OP_ADD;
                        3'b001: alu_op_o = OP_SLL;
                        3'b010: alu_op_o = OP_SLT;
                        3'b011: alu_op_o = OP_SLTU;
                        3'b100: alu_op_o = OP_XOR;
                        3'b101: alu_op_o = (funct7_bit5_i) ? OP_SRA : OP_SRL;
                        3'b110: alu_op_o = OP_OR;
                        3'b111: alu_op_o = OP_AND;
                        default: alu_op_o = OP_ADD;
                    endcase
                end
            end

            2'b11: begin
                case (funct3_i)
                    3'b000: alu_op_o = OP_ADD;
                    3'b010: alu_op_o = OP_SLT;
                    3'b011: alu_op_o = OP_SLTU;
                    3'b100: alu_op_o = OP_XOR;
                    3'b110: alu_op_o = OP_OR;
                    3'b111: alu_op_o = OP_AND;
                    3'b001: alu_op_o = OP_SLL;
                    3'b101: alu_op_o = (funct7_bit5_i) ? OP_SRA : OP_SRL;
                    default: alu_op_o = OP_ADD;
                endcase
            end
            default: alu_op_o = OP_ADD;
        endcase
    end
endmodule