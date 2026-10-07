module regfile (
    input         clk,
    input         rst_n,
    input         write_en,
    input  [ 4:0] rs1,
    input  [ 4:0] rs2,
    input  [ 4:0] rd,
    input  [31:0] write_data,
    output [31:0] rdata1,
    output [31:0] rdata2,
    output [31:0] debug_x0,  output [31:0] debug_x1,  output [31:0] debug_x2,  output [31:0] debug_x3,
    output [31:0] debug_x4,  output [31:0] debug_x5,  output [31:0] debug_x6,  output [31:0] debug_x7,
    output [31:0] debug_x8,  output [31:0] debug_x9,  output [31:0] debug_x10, output [31:0] debug_x11,
    output [31:0] debug_x12, output [31:0] debug_x13, output [31:0] debug_x14, output [31:0] debug_x15,
    output [31:0] debug_x16, output [31:0] debug_x17, output [31:0] debug_x18, output [31:0] debug_x19,
    output [31:0] debug_x20, output [31:0] debug_x21, output [31:0] debug_x22, output [31:0] debug_x23,
    output [31:0] debug_x24, output [31:0] debug_x25, output [31:0] debug_x26, output [31:0] debug_x27,
    output [31:0] debug_x28, output [31:0] debug_x29, output [31:0] debug_x30, output [31:0] debug_x31
);
    reg [31:0] regs [0:31];
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i = 0; i < 32; i = i + 1)
                regs[i] <= 32'b0;
        end else if(write_en && (rd != 5'd0)) begin
            regs[rd] <= write_data;
        end
    end

    assign rdata1 = (rs1 == 5'd0) ? 32'b0 : regs[rs1];
    assign rdata2 = (rs2 == 5'd0) ? 32'b0 : regs[rs2];

    assign debug_x0  = regs[0];  assign debug_x1  = regs[1];  assign debug_x2  = regs[2];  assign debug_x3  = regs[3];
    assign debug_x4  = regs[4];  assign debug_x5  = regs[5];  assign debug_x6  = regs[6];  assign debug_x7  = regs[7];
    assign debug_x8  = regs[8];  assign debug_x9  = regs[9];  assign debug_x10 = regs[10]; assign debug_x11 = regs[11];
    assign debug_x12 = regs[12]; assign debug_x13 = regs[13]; assign debug_x14 = regs[14]; assign debug_x15 = regs[15];
    assign debug_x16 = regs[16]; assign debug_x17 = regs[17]; assign debug_x18 = regs[18]; assign debug_x19 = regs[19];
    assign debug_x20 = regs[20]; assign debug_x21 = regs[21]; assign debug_x22 = regs[22]; assign debug_x23 = regs[23];
    assign debug_x24 = regs[24]; assign debug_x25 = regs[25]; assign debug_x26 = regs[26]; assign debug_x27 = regs[27];
    assign debug_x28 = regs[28]; assign debug_x29 = regs[29]; assign debug_x30 = regs[30]; assign debug_x31 = regs[31];
endmodule
