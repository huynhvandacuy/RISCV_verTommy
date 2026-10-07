`timescale 1ns/1ps

module tb_alu;
    reg  [31:0] a, b;
    reg         op_sub;
    wire [31:0] result;

    alu dut (
        .a(a),
        .b(b),
        .op_sub(op_sub),
        .result(result)
    );

    initial begin
        a      = 32'd5;
        b      = 32'd7;
        op_sub = 1'b0;

        #1;

        if (result !== 32'd12)
            $fatal(1, "FAIL: result=%0d, expected=12", result);

        $display("PASS: ADD %0d + %0d = %0d", a, b, result);
        $finish;
    end

    initial begin
        #1000;
        $fatal(1, "TIMEOUT");
    end
endmodule