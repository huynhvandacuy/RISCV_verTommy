`timescale 1ns/1ps

// Register file contract:
// - asynchronous active-low reset clears all registers;
// - synchronous writes on the rising clock edge;
// - x0 always reads zero and ignores writes;
// - combinational reads bypass an enabled write to the same address.
module tb_regfile;
    reg clk;
    reg rst_n;
    reg write_en;
    reg [4:0] rs1_addr;
    reg [4:0] rs2_addr;
    reg [4:0] rd_addr;
    reg [31:0] write_data;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    wire [31:0] debug_x0;
    wire [31:0] debug_x5;

    integer checks;
    integer index;
    reg [31:0] expected [0:31];

    regfile dut (
        .clk_i        (clk),
        .rst_ni       (rst_n),
        .write_en_i   (write_en),
        .rs1_addr_i   (rs1_addr),
        .rs2_addr_i   (rs2_addr),
        .rd_addr_i    (rd_addr),
        .write_data_i (write_data),
        .rs1_data_o   (rs1_data),
        .rs2_data_o   (rs2_data),
        .debug_x0_o   (debug_x0),
        .debug_x5_o   (debug_x5)
        // Other debug outputs are intentionally left unconnected.
    );

    initial clk = 1'b0;
    always #5 clk = ~clk; // 10 ns clock period

    task expect_reads;
        input [31:0] expected_rs1;
        input [31:0] expected_rs2;
        input [8*80-1:0] label;
        begin
            if (rs1_data !== expected_rs1 || rs2_data !== expected_rs2)
                $fatal(1,
                    "FAIL [%0s] rs1=x%0d got=%h expected=%h; rs2=x%0d got=%h expected=%h",
                    label, rs1_addr, rs1_data, expected_rs1,
                    rs2_addr, rs2_data, expected_rs2);
            checks = checks + 1;
        end
    endtask

    task read_pair;
        input [4:0] addr1;
        input [4:0] addr2;
        input [31:0] expected_rs1;
        input [31:0] expected_rs2;
        input [8*80-1:0] label;
        begin
            @(negedge clk);
            #1;
            write_en = 1'b0;
            rs1_addr = addr1;
            rs2_addr = addr2;
            #1;
            expect_reads(expected_rs1, expected_rs2, label);
        end
    endtask

    task write_reg;
        input [4:0] addr;
        input [31:0] data;
        begin
            @(negedge clk);
            #1;
            write_en = 1'b1;
            rd_addr = addr;
            write_data = data;
            @(posedge clk);
            #1; // Wait until nonblocking writes have settled.
            if (addr != 5'd0)
                expected[addr] = data;
            @(negedge clk);
            #1;
            write_en = 1'b0;
        end
    endtask

    task bypass_check;
        input [4:0] dest;
        input [31:0] data;
        input [4:0] addr1;
        input [4:0] addr2;
        input [31:0] expected_rs1;
        input [31:0] expected_rs2;
        input [8*80-1:0] label;
        begin
            @(negedge clk);
            #1;
            rd_addr = dest;
            write_data = data;
            rs1_addr = addr1;
            rs2_addr = addr2;
            write_en = 1'b1;
            #1;
            // Crucial: check BEFORE the next rising edge.
            expect_reads(expected_rs1, expected_rs2, label);
            if (dest == 5'd5 && debug_x5 !== expected[5])
                $fatal(1, "FAIL: x5 storage changed before rising edge");
            @(posedge clk);
            #1;
            if (dest != 5'd0)
                expected[dest] = data;
            expect_reads(expected_rs1, expected_rs2, "after write edge");
            @(negedge clk);
            #1;
            write_en = 1'b0;
            #1;
            expect_reads(expected_rs1, expected_rs2, "stored data after bypass disabled");
        end
    endtask

    initial begin
        checks = 0;
        rst_n = 1'b1;
        write_en = 1'b0;
        rs1_addr = 5'd1;
        rs2_addr = 5'd31;
        rd_addr = 5'd0;
        write_data = 32'd0;
        for (index = 0; index < 32; index = index + 1)
            expected[index] = 32'd0;

        // Assert reset between clock edges: asynchronous behavior.
        #2;
        rst_n = 1'b0;
        #1;
        expect_reads(32'd0, 32'd0, "initial asynchronous reset");
        repeat (2) @(negedge clk);
        #1;
        rst_n = 1'b1;

        for (index = 0; index < 32; index = index + 1)
            read_pair(index, 31-index, 32'd0, 32'd0, "all registers reset");

        // Distinct data makes address/port wiring errors visible.
        for (index = 1; index < 32; index = index + 1)
            write_reg(index, 32'h1020_0000 + index);
        for (index = 0; index < 32; index = index + 1)
            read_pair(index, 31-index, expected[index], expected[31-index],
                      "independent read ports, x0 through x31");

        write_reg(5'd0, 32'hffff_ffff);
        read_pair(5'd0, 5'd5, 32'd0, expected[5], "x0 ignores writes");
        if (debug_x0 !== 32'd0)
            $fatal(1, "FAIL: x0 storage is not zero");

        // Disabled write must neither bypass nor modify storage.
        @(negedge clk);
        #1;
        write_en = 1'b0;
        rd_addr = 5'd5;
        write_data = 32'hbad0_0005;
        rs1_addr = 5'd5;
        rs2_addr = 5'd5;
        #1;
        expect_reads(expected[5], expected[5], "disabled write does not bypass");
        @(posedge clk);
        #1;
        expect_reads(expected[5], expected[5], "disabled write does not store");

        bypass_check(5'd5, 32'hdead_beef, 5'd5, 5'd6,
                     32'hdead_beef, expected[6], "bypass to rs1 only");
        bypass_check(5'd6, 32'h1234_5678, 5'd5, 5'd6,
                     expected[5], 32'h1234_5678, "bypass to rs2 only");
        bypass_check(5'd7, 32'h8000_0000, 5'd7, 5'd7,
                     32'h8000_0000, 32'h8000_0000, "bypass to both read ports");
        bypass_check(5'd0, 32'hffff_ffff, 5'd0, 5'd0,
                     32'd0, 32'd0, "x0 has priority over bypass");

        write_reg(5'd31, 32'hffff_ffff);
        read_pair(5'd31, 5'd31, 32'hffff_ffff, 32'hffff_ffff, "overwrite x31");

        // Reset populated registers, away from the active clock edge.
        @(negedge clk);
        #2;
        rs1_addr = 5'd5;
        rs2_addr = 5'd31;
        rst_n = 1'b0;
        #1;
        expect_reads(32'd0, 32'd0, "asynchronous reset clears populated registers");
        @(negedge clk);
        #1;
        rst_n = 1'b1;
        for (index = 0; index < 32; index = index + 1)
            read_pair(index, 31-index, 32'd0, 32'd0, "all registers cleared again");

        $display("PASS: tb_regfile, %0d checks", checks);
        $finish;
    end

    initial begin
        #10000;
        $fatal(1, "TIMEOUT: tb_regfile exceeded 10000 ns");
    end
endmodule
