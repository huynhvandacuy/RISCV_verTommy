module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire        op_sub,
    output wire [31:0] result
);
    assign result = op_sub ? (a - b) : (a + b);
endmodule