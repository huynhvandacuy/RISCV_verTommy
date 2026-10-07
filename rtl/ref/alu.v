module alu (
    input      [31:0] src_a_i,
    input      [31:0] src_b_i,
    input      [ 4:0] alu_op_i,
    output reg [31:0] result_o,
    output            zero_o
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
        case (alu_op_i)
            ALU_ADD : result_o = src_a_i + src_b_i;
            ALU_SUB : result_o = src_a_i - src_b_i;
            ALU_SLL : result_o = src_a_i << src_b_i[4:0];
            ALU_SLT : result_o = ($signed(src_a_i) < $signed(src_b_i)) ? 32'd1 : 32'd0;
            ALU_SLTU: result_o = (src_a_i < src_b_i) ? 32'd1 : 32'd0;
            ALU_XOR : result_o = src_a_i ^ src_b_i;
            ALU_SRL : result_o = src_a_i >> src_b_i[4:0];
            ALU_SRA : result_o = $signed(src_a_i) >>> src_b_i[4:0];
            ALU_OR  : result_o = src_a_i | src_b_i;
            ALU_AND : result_o = src_a_i & src_b_i;
            default: result_o = 32'b0;
        endcase
    end

    assign zero_o = (result_o == 32'b0);
endmodule