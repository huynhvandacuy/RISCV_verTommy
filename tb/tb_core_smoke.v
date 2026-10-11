`timescale 1ns/1ps

// Checks the renamed 5-stage core, including WB->ID and MEM/WB->EX forwarding.
module tb_core_smoke;
    reg clk;
    reg rst_n;
    reg finished;
    integer checks;
    integer commit_index;
    integer image_fd;
    integer index;
    reg [4:0] expected_rd [0:8];
    reg [31:0] expected_data [0:8];

    top dut (
        .clk_i  (clk),
        .rst_ni (rst_n)
    );

    // Testbench-only overrides; no change to top or instr_mem required.
    // Paths are relative to sim/, where the Makefile runs the simulator.
    defparam dut.u_instr_mem.IMEM_WORDS = 64;
    defparam dut.u_instr_mem.IMEM_HEX_FILE = "../sw/smoke/core_smoke.hex";

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Inspect WB BEFORE the nonblocking register write at this clock edge.
    always @(posedge clk) begin
        if (rst_n && dut.reg_write_en_wb && dut.rd_addr_wb != 5'd0) begin
            if (commit_index >= 9)
                $fatal(1, "FAIL: unexpected extra write x%0d=%h",
                       dut.rd_addr_wb, dut.write_data_wb);
            if (dut.rd_addr_wb !== expected_rd[commit_index] ||
                dut.write_data_wb !== expected_data[commit_index])
                $fatal(1,
                    "FAIL: WB #%0d got x%0d=%h; expected x%0d=%h",
                    commit_index, dut.rd_addr_wb, dut.write_data_wb,
                    expected_rd[commit_index], expected_data[commit_index]);
            $display("PASS: WB #%0d x%0d=%0d", commit_index,
                     dut.rd_addr_wb, dut.write_data_wb);
            checks = checks + 1;
            commit_index = commit_index + 1;
            if (commit_index == 9)
                finished <= 1'b1;
        end
    end

    task check_register;
        input [4:0] addr;
        input [31:0] value;
        begin
            if (dut.u_regfile.regs_q[addr] !== value)
                $fatal(1, "FAIL: final x%0d=%h expected=%h",
                       addr, dut.u_regfile.regs_q[addr], value);
            checks = checks + 1;
        end
    endtask

    initial begin
        rst_n = 1'b1;
        finished = 1'b0;
        checks = 0;
        commit_index = 0;
        expected_rd[0] = 5'd1; expected_data[0] = 32'd6;
        expected_rd[1] = 5'd3; expected_data[1] = 32'd6;  // WB -> ID
        expected_rd[2] = 5'd4; expected_data[2] = 32'd6;
        expected_rd[3] = 5'd5; expected_data[3] = 32'd12; // MEM -> EX, both sources
        expected_rd[4] = 5'd6; expected_data[4] = 32'd6;  // WB -> EX
        expected_rd[5] = 5'd7; expected_data[5] = 32'd1;
        expected_rd[6] = 5'd7; expected_data[6] = 32'd3;  // read-modify-write
        expected_rd[7] = 5'd8; expected_data[7] = 32'd6;  // MEM priority over WB
        expected_rd[8] = 5'd9; expected_data[8] = 32'd1;  // end marker

        image_fd = $fopen("../sw/smoke/core_smoke.hex", "r");
        if (image_fd == 0)
            $fatal(1, "Missing ../sw/smoke/core_smoke.hex; run from sim/");
        $fclose(image_fd);

        #2;
        rst_n = 1'b0;
        repeat (3) @(negedge clk);
        #1;
        rst_n = 1'b1;

        wait (finished);
        @(negedge clk);
        #1; // Final register write is now settled.
        check_register(5'd0, 32'd0);
        check_register(5'd1, 32'd6);
        check_register(5'd3, 32'd6);
        check_register(5'd4, 32'd6);
        check_register(5'd5, 32'd12);
        check_register(5'd6, 32'd6);
        check_register(5'd7, 32'd3);
        check_register(5'd8, 32'd6);
        check_register(5'd9, 32'd1);
        // Unused destination registers must remain unchanged.
        check_register(5'd2, 32'd0);
        for (index = 10; index < 32; index = index + 1)
            check_register(index, 32'd0);
        $display("PASS: tb_core_smoke, %0d checks, WB/ID and forwarding", checks);
        $finish;
    end

    initial begin
        #5000;
        $fatal(1, "TIMEOUT: tb_core_smoke, only %0d/9 writes observed", commit_index);
    end
endmodule
