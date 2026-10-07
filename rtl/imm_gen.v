module immediate_data_extractor(
    input  [31:0] ins,
    output [31:0] imm_i,
    output [31:0] imm_s,
    output [31:0] imm_b,
    output [31:0] imm_u,
    output [31:0] imm_j
  );
    assign imm_i = {{20{ins[31]}}, ins[31:20]};
    assign imm_s = {{20{ins[31]}}, ins[31:25], ins[11:7]};
    assign imm_b = {{19{ins[31]}}, ins[31], ins[7], ins[30:25], ins[11:8],1'b0};
    assign imm_u = {ins[31:12], 12'b0};
    assign imm_j = {{12{ins[31]}}, ins[19:12], ins[20], ins[30:21], 1'b0};
  endmodule