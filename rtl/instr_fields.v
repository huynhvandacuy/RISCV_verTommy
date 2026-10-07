module instr_fields (
    input  [31:0] instr_i,
    output [ 6:0] opcode_o,
    output [ 4:0] rd_addr_o,
    output [ 2:0] funct3_o,
    output [ 4:0] rs1_addr_o,
    output [ 4:0] rs2_addr_o,
    output [ 6:0] funct7_o
);
    assign opcode_o = instr_i[ 6: 0];
    assign rd_addr_o     = instr_i[11: 7];
    assign funct3_o = instr_i[14:12];
    assign rs1_addr_o    = instr_i[19:15];
    assign rs2_addr_o    = instr_i[24:20];
    assign funct7_o = instr_i[31:25];
endmodule
