module alu(
    input      [31:0] src_a,
    input      [31:0] src_b,
    input      [ 4:0] alu_ctrl,
    output reg [31:0] alu_result,
    output            zero_flag
);
    localparam ALU_ADD = 5'b00000;
    localparam ALU_SUB = 5'b00001;
    localparam ALU_SLL = 5'b00010;
    localparam ALU_SLT = 5'b00011;
    localparam ALU_SLTU= 5'b00100;
    localparam ALU_XOR = 5'b00101;
    localparam ALU_SRL = 5'b00110;
    localparam ALU_SRA = 5'b00111;
    localparam ALU_OR  = 5'b01000;
    localparam ALU_AND = 5'b01001;

    always @(*) begin
        case (alu_ctrl)
            ALU_ADD : alu_result = src_a + src_b;
            ALU_SUB : alu_result = src_a - src_b;
            ALU_SLL : alu_result = src_a << src_b[4:0];
            ALU_SLT : alu_result = ($signed(src_a) < $signed(src_b)) ? 32'd1 : 32'd0;
            ALU_SLTU: alu_result = (src_a < src_b) ? 32'd1 : 32'd0;
            ALU_XOR : alu_result = src_a ^ src_b;
            ALU_SRL : alu_result = src_a >> src_b[4:0];
            ALU_SRA : alu_result = $signed(src_a) >>> src_b[4:0];
            ALU_OR  : alu_result = src_a | src_b;
            ALU_AND : alu_result = src_a & src_b;
            default: alu_result = 32'b0;
        endcase
    end

    assign zero_flag = (alu_result == 32'b0);
endmodule