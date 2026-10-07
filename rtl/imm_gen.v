module imm_gen(
    input  [31:0] instr_i,
    output [31:0] imm_i_o,
    output [31:0] imm_s_o,
    output [31:0] imm_b_o,
    output [31:0] imm_u_o,
    output [31:0] imm_j_o
  );
    assign imm_i_o = {{20{instr_i[31]}}, instr_i[31:20]};
    assign imm_s_o = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
    assign imm_b_o = {{19{instr_i[31]}}, instr_i[31], instr_i[7], instr_i[30:25], instr_i[11:8],1'b0};
    assign imm_u_o = {instr_i[31:12], 12'b0};
    assign imm_j_o = {{12{instr_i[31]}}, instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};
  endmodule