`timescale 1ns/1ps

module tb_riscv_add;
    localparam [31:0] STATUS_ADDR = 32'h00003ffc;

    reg clk = 0;
    reg rst_n = 1;
    integer fd;
    integer cycles = 0;

    top dut (
        .clk_i  (clk),
        .rst_ni (rst_n)
    );

    defparam dut.u_instr_mem.IMEM_WORDS = 4096;
    defparam dut.u_instr_mem.IMEM_HEX_FILE =
        "../sw/riscv_tests/out/rv32ui-add.hex";

    always #5 clk = ~clk;

    initial begin
        fd = $fopen(
            "../sw/riscv_tests/out/rv32ui-add.hex", "r"
        );

        if (fd == 0)
            $fatal(1, "Missing hex: run build_add.sh first");

        $fclose(fd);

        #2;
        rst_n = 0;
        repeat (3) @(negedge clk);
        #1;
        rst_n = 1;
    end

    // Observe the status store at the memory write edge.
    always @(posedge clk) begin
        if (rst_n) begin
            cycles = cycles + 1;

            if (dut.mem_write_en_mem &&
                dut.exec_result_mem === STATUS_ADDR) begin

                if (dut.funct3_mem !== 3'b010)
                    $fatal(1, "FAIL: status must use SW");

                if (dut.rs2_data_mem === 32'd1) begin
                    $display(
                        "PASS: tb_riscv_add, rv32ui-add, %0d cycles",
                        cycles
                    );
                    $finish;
                end else begin
                    if (^dut.rs2_data_mem === 1'bx ||
                        dut.rs2_data_mem < 32'd2)
                        $fatal(1, "FAIL: invalid status=%h",
                               dut.rs2_data_mem);

                    $fatal(
                        1,
                        "FAIL: rv32ui-add test number=%0d",
                        dut.rs2_data_mem - 32'd2
                    );
                end
            end
        end
    end

    initial begin
        #1000000;
        $fatal(1, "TIMEOUT: rv32ui-add, PC=%h, TESTNUM=%h",
               dut.pc_if, dut.debug_x3);
    end
endmodule