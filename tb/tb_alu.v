`timescale 1ns/1ps
module tb_alu;
    reg [31:0] src_a;
    reg [31:0] src_b;
    reg [4:0] alu_op;
    wire [31:0] result;
    wire zero;
    integer checks;

    alu dut (
        .src_a_i  (src_a),
        .src_b_i  (src_b),
        .alu_op_i (alu_op),
        .result_o (result),
        .zero_o   (zero)
    );

    task check;
        input [4:0] op;
        input [31:0] a;
        input [31:0] b;
        input [31:0] expected;
        begin
            alu_op = op;
            src_a = a;
            src_b = b;
            #1;
            if (result !== expected || zero !== (expected == 32'd0))
                $fatal(1, "ALU FAIL op=%0d a=%h b=%h got=%h expected=%h zero=%b",
                       op, a, b, result, expected, zero);
            checks = checks + 1;
        end
    endtask

    initial begin
        checks = 0;
        check(5'd0, 32'd5, 32'd7, 32'd12);                 // ADD
        check(5'd0, 32'hffff_ffff, 32'd1, 32'd0);          // ADD wrap
        check(5'd1, 32'd0, 32'd1, 32'hffff_ffff);          // SUB
        check(5'd2, 32'd1, 32'd31, 32'h8000_0000);         // SLL
        check(5'd2, 32'd1, 32'd32, 32'd1);                // low 5 shift bits
        check(5'd3, 32'hffff_ffff, 32'd0, 32'd1);          // SLT signed
        check(5'd4, 32'hffff_ffff, 32'd0, 32'd0);          // SLTU unsigned
        check(5'd5, 32'hf0, 32'h55, 32'ha5);              // XOR
        check(5'd6, 32'h8000_0000, 32'd31, 32'd1);         // SRL
        check(5'd7, 32'h8000_0000, 32'd31, 32'hffff_ffff); // SRA
        check(5'd8, 32'ha0, 32'h0a, 32'haa);              // OR
        check(5'd9, 32'ha5, 32'hf0, 32'ha0);              // AND
        $display("PASS: tb_alu, %0d checks", checks);
        $finish;
    end

    initial begin
        #1000;
        $fatal(1, "TIMEOUT: tb_alu");
    end
endmodule
