`timescale 1ns/1ps
// Run from sim/. All accesses are aligned, within the 16 KiB data memory.
module tb_core_memtest;
    reg clk=0, rst_n=1, finished=0;
    integer wi=0, si=0, stalls=0, checks=0, fd, i;
    localparam WCOUNT=31, SCOUNT=13;
    reg [4:0] erd [0:WCOUNT-1];
    reg [31:0] edata [0:WCOUNT-1], eaddr [0:SCOUNT-1], estore [0:SCOUNT-1];
    reg [2:0] efunct [0:SCOUNT-1];
    reg [31:0] final_regs [0:31];
    reg [31:0] held_pc, held_instr, held_id_pc;
    
    top dut(.clk_i(clk), .rst_ni(rst_n));
    defparam dut.u_instr_mem.IMEM_WORDS=256;
    defparam dut.u_instr_mem.IMEM_HEX_FILE="../sw/memtest/core_memtest.hex";
    always #5 clk=~clk;
    always @(posedge clk) begin
        if (rst_n) begin
            if (dut.reg_write_en_wb && dut.rd_addr_wb != 0) begin
                if (wi>=WCOUNT) $fatal(1,"FAIL: extra WB");
                if (dut.rd_addr_wb !== erd[wi] || dut.write_data_wb !== edata[wi])
                    $fatal(1,"FAIL: WB #%0d x%0d=%h expected x%0d=%h",wi,dut.rd_addr_wb,dut.write_data_wb,erd[wi],edata[wi]);
                $display("PASS: WB #%0d x%0d=%h",wi,dut.rd_addr_wb,dut.write_data_wb);
                wi=wi+1; checks=checks+1;
                if(wi==WCOUNT) finished<=1;
            end
            if (dut.mem_write_en_mem) begin
                if(si>=SCOUNT) $fatal(1,"FAIL: extra store");
                if(dut.exec_result_mem !== eaddr[si] || dut.funct3_mem !== efunct[si] || dut.rs2_data_mem !== estore[si])
                    $fatal(1,"FAIL: store #%0d addr=%h data=%h funct3=%h expected addr=%h data=%h funct3=%h",si,dut.exec_result_mem,dut.rs2_data_mem,dut.funct3_mem,eaddr[si],estore[si],efunct[si]);
                si=si+1; checks=checks+1;
            end
        end
    end
    // Sample before the edge, then verify settled pipeline state after NBA.
    always @(posedge clk) begin
        if(rst_n && dut.load_use_hazard) begin
            stalls=stalls+1;
            held_pc=dut.pc_if; held_instr=dut.instr_id; held_id_pc=dut.pc_id;
            if(dut.pc_stall !== 1'b1 || dut.ifid_write_en !== 1'b0 || dut.idex_flush !== 1'b1)
                $fatal(1,"FAIL: load-use control");
            #1;
            if(dut.pc_if !== held_pc || dut.instr_id !== held_instr || dut.pc_id !== held_id_pc)
                $fatal(1,"FAIL: PC/IF-ID changed during load-use stall");
            if(dut.reg_write_en_ex !== 1'b0 || dut.mem_read_en_ex !== 1'b0 || dut.mem_write_en_ex !== 1'b0)
                $fatal(1,"FAIL: ID/EX did not inject bubble");
            checks=checks+1;
        end
    end
    task check_mem;
        input integer word_index;
        input [31:0] value;
        begin
            if(dut.u_data_memory.mem[word_index] !== value)
                $fatal(1,"FAIL: memory word %0d=%h expected=%h",word_index,dut.u_data_memory.mem[word_index],value);
            checks=checks+1;
        end
    endtask
    initial begin
        erd[0]=5'd1; edata[0]=32'h00000000;
        erd[1]=5'd2; edata[1]=32'h00000123;
        erd[2]=5'd3; edata[2]=32'h00000123;
        erd[3]=5'd4; edata[3]=32'h00000246;
        erd[4]=5'd5; edata[4]=32'h00000123;
        erd[5]=5'd6; edata[5]=32'h00000008;
        erd[6]=5'd7; edata[6]=32'h00000008;
        erd[7]=5'd8; edata[7]=32'h00000123;
        erd[8]=5'd9; edata[8]=32'hffffff80;
        erd[9]=5'd10; edata[9]=32'h80808080;
        erd[10]=5'd11; edata[10]=32'hffffff80;
        erd[11]=5'd12; edata[11]=32'h00000080;
        erd[12]=5'd11; edata[12]=32'hffffff80;
        erd[13]=5'd12; edata[13]=32'h00000080;
        erd[14]=5'd11; edata[14]=32'hffffff80;
        erd[15]=5'd12; edata[15]=32'h00000080;
        erd[16]=5'd11; edata[16]=32'hffffff80;
        erd[17]=5'd12; edata[17]=32'h00000080;
        erd[18]=5'd13; edata[18]=32'hffffffff;
        erd[19]=5'd14; edata[19]=32'h00000123;
        erd[20]=5'd15; edata[20]=32'hffffff23;
        erd[21]=5'd16; edata[21]=32'h0123ff23;
        erd[22]=5'd17; edata[22]=32'hffffff23;
        erd[23]=5'd18; edata[23]=32'h0000ff23;
        erd[24]=5'd19; edata[24]=32'h00000123;
        erd[25]=5'd20; edata[25]=32'h00000123;
        erd[26]=5'd21; edata[26]=32'hffffffff;
        erd[27]=5'd22; edata[27]=32'h0000ffff;
        erd[28]=5'd23; edata[28]=32'hffffffff;
        erd[29]=5'd24; edata[29]=32'h0000ffff;
        erd[30]=5'd31; edata[30]=32'h00000001;
        eaddr[0]=32'd0; efunct[0]=3'd2; estore[0]=32'h00000123;
        eaddr[1]=32'd4; efunct[1]=3'd2; estore[1]=32'h00000123;
        eaddr[2]=32'd12; efunct[2]=3'd2; estore[2]=32'h00000008;
        eaddr[3]=32'd8; efunct[3]=3'd2; estore[3]=32'h00000123;
        eaddr[4]=32'd16; efunct[4]=3'd0; estore[4]=32'hffffff80;
        eaddr[5]=32'd17; efunct[5]=3'd0; estore[5]=32'hffffff80;
        eaddr[6]=32'd18; efunct[6]=3'd0; estore[6]=32'hffffff80;
        eaddr[7]=32'd19; efunct[7]=3'd0; estore[7]=32'hffffff80;
        eaddr[8]=32'd20; efunct[8]=3'd2; estore[8]=32'hffffffff;
        eaddr[9]=32'd20; efunct[9]=3'd0; estore[9]=32'h00000123;
        eaddr[10]=32'd22; efunct[10]=3'd1; estore[10]=32'h00000123;
        eaddr[11]=32'd24; efunct[11]=3'd1; estore[11]=32'hffffffff;
        eaddr[12]=32'd26; efunct[12]=3'd1; estore[12]=32'hffffffff;
        for(i=0;i<32;i=i+1) final_regs[i]=0;
        for(i=0;i<WCOUNT;i=i+1) final_regs[erd[i]]=edata[i];
        fd=$fopen("../sw/memtest/core_memtest.hex","r");
        if(fd==0) $fatal(1,"Missing core_memtest.hex; run from sim/");
        $fclose(fd);
        #2; rst_n=0;
        repeat(3) @(negedge clk);
        #1; rst_n=1;
        wait(finished);
        repeat(4) @(negedge clk);
        #1;
        if(si!=SCOUNT) $fatal(1,"FAIL: missing stores %0d/%0d",si,SCOUNT);
        if(stalls<3) $fatal(1,"FAIL: expected at least 3 load-use stalls, got %0d",stalls);
        for(i=0;i<32;i=i+1) begin
            if(dut.u_regfile.regs_q[i] !== final_regs[i])
                $fatal(1,"FAIL: final x%0d=%h expected=%h",i,dut.u_regfile.regs_q[i],final_regs[i]);
            checks=checks+1;
        end
        check_mem(0,32'h123); check_mem(1,32'h123); check_mem(2,32'h123);
        check_mem(3,32'h8); check_mem(4,32'h80808080);
        check_mem(5,32'h0123ff23); check_mem(6,32'hffffffff);
        check_mem(7,32'h0);
        $display("PASS: tb_core_memtest, %0d checks, %0d WB, %0d stores, %0d load-use stalls",checks,wi,si,stalls);
        $finish;
    end
    initial begin
        #10000; $fatal(1,"TIMEOUT: tb_core_memtest WB=%0d/%0d stores=%0d/%0d",wi,WCOUNT,si,SCOUNT);
    end
endmodule
