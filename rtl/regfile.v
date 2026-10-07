module regfile(
    input         clk_i,
    input         rst_ni,
    input         write_en_i,
    input  [ 4:0] rs1_addr_i,
    input  [ 4:0] rs2_addr_i,
    input  [ 4:0] rd_addr_i,
    input  [31:0] write_data_i,
    output [31:0] rs1_data_o,
    output [31:0] rs2_data_o,
    output [31:0] debug_x0_o,  output [31:0] debug_x1_o,  output [31:0] debug_x2_o,  output [31:0] debug_x3_o,
    output [31:0] debug_x4_o,  output [31:0] debug_x5_o,  output [31:0] debug_x6_o,  output [31:0] debug_x7_o,
    output [31:0] debug_x8_o,  output [31:0] debug_x9_o,  output [31:0] debug_x10_o, output [31:0] debug_x11_o,
    output [31:0] debug_x12_o, output [31:0] debug_x13_o, output [31:0] debug_x14_o, output [31:0] debug_x15_o,
    output [31:0] debug_x16_o, output [31:0] debug_x17_o, output [31:0] debug_x18_o, output [31:0] debug_x19_o,
    output [31:0] debug_x20_o, output [31:0] debug_x21_o, output [31:0] debug_x22_o, output [31:0] debug_x23_o,
    output [31:0] debug_x24_o, output [31:0] debug_x25_o, output [31:0] debug_x26_o, output [31:0] debug_x27_o,
    output [31:0] debug_x28_o, output [31:0] debug_x29_o, output [31:0] debug_x30_o, output [31:0] debug_x31_o
);
    reg [31:0] regs_q [0:31];
    integer i;

    always @(posedge clk_i or negedge rst_ni) begin
        if(!rst_ni) begin
            for(i = 0; i < 32; i = i + 1)
                regs_q[i] <= 32'b0;
        end else if(write_en_i && (rd_addr_i != 5'd0)) begin
            regs_q[rd_addr_i] <= write_data_i;
        end
    end

    assign rs1_data_o =
        (rs1_addr_i == 5'd0) ? 32'd0 :
        (write_en_i && (rd_addr_i == rs1_addr_i))
            ? write_data_i
            : regs_q[rs1_addr_i];

    assign rs2_data_o =
        (rs2_addr_i == 5'd0) ? 32'd0 :
        (write_en_i && (rd_addr_i == rs2_addr_i))
            ? write_data_i
            : regs_q[rs2_addr_i];

    assign debug_x0_o  = regs_q[0];  assign debug_x1_o  = regs_q[1];  assign debug_x2_o  = regs_q[2];  assign debug_x3_o  = regs_q[3];
    assign debug_x4_o  = regs_q[4];  assign debug_x5_o  = regs_q[5];  assign debug_x6_o  = regs_q[6];  assign debug_x7_o  = regs_q[7];
    assign debug_x8_o  = regs_q[8];  assign debug_x9_o  = regs_q[9];  assign debug_x10_o = regs_q[10]; assign debug_x11_o = regs_q[11];
    assign debug_x12_o = regs_q[12]; assign debug_x13_o = regs_q[13]; assign debug_x14_o = regs_q[14]; assign debug_x15_o = regs_q[15];
    assign debug_x16_o = regs_q[16]; assign debug_x17_o = regs_q[17]; assign debug_x18_o = regs_q[18]; assign debug_x19_o = regs_q[19];
    assign debug_x20_o = regs_q[20]; assign debug_x21_o = regs_q[21]; assign debug_x22_o = regs_q[22]; assign debug_x23_o = regs_q[23];
    assign debug_x24_o = regs_q[24]; assign debug_x25_o = regs_q[25]; assign debug_x26_o = regs_q[26]; assign debug_x27_o = regs_q[27];
    assign debug_x28_o = regs_q[28]; assign debug_x29_o = regs_q[29]; assign debug_x30_o = regs_q[30]; assign debug_x31_o = regs_q[31];
endmodule
