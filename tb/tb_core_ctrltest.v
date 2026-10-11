`timescale 1ns/1ps
module tb_core_ctrltest;
    localparam WCOUNT=41, CCOUNT=22, SCOUNT=2;
    reg clk=0, rst_n=1, finished=0;
    integer wi=0, ci=0, si=0, stalls=0, checks=0, fd, i;
    reg [4:0] erd[0:WCOUNT-1];
    reg [31:0] edata[0:WCOUNT-1], epc[0:CCOUNT-1], etarget[0:CCOUNT-1];
    reg etaken[0:CCOUNT-1];
    reg [31:0] eaddr[0:SCOUNT-1], estore[0:SCOUNT-1], final_regs[0:31];
    reg [31:0] target_saved;
    top dut(.clk_i(clk),.rst_ni(rst_n));
    defparam dut.u_instr_mem.IMEM_WORDS=256;
    defparam dut.u_instr_mem.IMEM_HEX_FILE="../sw/ctrltest/core_ctrltest.hex";
    always #5 clk=~clk;
    always @(posedge clk) if(rst_n) begin
        if(dut.reg_write_en_wb && dut.rd_addr_wb!=0) begin
            if(wi>=WCOUNT) $fatal(1,"FAIL: extra WB");
            if(dut.rd_addr_wb !== erd[wi] || dut.write_data_wb !== edata[wi])
                $fatal(1,"FAIL: WB #%0d x%0d=%h expected x%0d=%h",wi,dut.rd_addr_wb,dut.write_data_wb,erd[wi],edata[wi]);
            $display("PASS: WB #%0d x%0d=%h",wi,dut.rd_addr_wb,dut.write_data_wb);
            wi=wi+1; checks=checks+1;
            if(wi==WCOUNT) finished<=1;
        end
        if(dut.mem_write_en_mem) begin
            if(si>=SCOUNT) $fatal(1,"FAIL: extra/wrong-path store addr=%h",dut.exec_result_mem);
            if(dut.exec_result_mem !== eaddr[si] || dut.rs2_data_mem !== estore[si] || dut.funct3_mem !== 3'b010)
                $fatal(1,"FAIL: store #%0d addr=%h data=%h expected addr=%h data=%h",si,dut.exec_result_mem,dut.rs2_data_mem,eaddr[si],estore[si]);
            si=si+1; checks=checks+1;
        end
        if(dut.load_use_hazard) stalls=stalls+1;
    end
    always @(posedge clk) if(rst_n && (dut.branch_en_ex || dut.jal_en_ex || dut.jalr_en_ex)) begin
        if(ci>=CCOUNT) $fatal(1,"FAIL: extra control instruction");
        if(dut.pc_ex !== epc[ci] || dut.ctrl_flush_ex !== etaken[ci])
            $fatal(1,"FAIL: control #%0d PC=%h taken=%b expected PC=%h taken=%b",ci,dut.pc_ex,dut.ctrl_flush_ex,epc[ci],etaken[ci]);
        target_saved=etarget[ci];
        if(etaken[ci]) begin
            if(dut.pc_stall !== 1'b0 || dut.pc_next !== target_saved || dut.ifid_flush !== 1'b1 || dut.idex_flush !== 1'b1)
                $fatal(1,"FAIL: redirect target/flush control at PC=%h",dut.pc_ex);
        end
        $display("PASS: control #%0d PC=%h taken=%b",ci,dut.pc_ex,dut.ctrl_flush_ex);
        checks=checks+1;
        if(etaken[ci]) begin
            #1;
            if(dut.pc_if !== target_saved || dut.reg_write_en_ex !== 1'b0 || dut.mem_write_en_ex !== 1'b0 || dut.mem_read_en_ex !== 1'b0 || dut.branch_en_ex !== 1'b0 || dut.jal_en_ex !== 1'b0 || dut.jalr_en_ex !== 1'b0)
                $fatal(1,"FAIL: PC redirect or ID/EX flush state");
            checks=checks+1;
        end
        ci=ci+1;
    end
    initial begin
        erd[0]=5'd1; edata[0]=32'h00000001;
        erd[1]=5'd2; edata[1]=32'hffffffff;
        erd[2]=5'd3; edata[2]=32'h00000001;
        erd[3]=5'd11; edata[3]=32'h00000001;
        erd[4]=5'd10; edata[4]=32'h00000001;
        erd[5]=5'd11; edata[5]=32'h00000002;
        erd[6]=5'd11; edata[6]=32'h00000003;
        erd[7]=5'd10; edata[7]=32'h00000002;
        erd[8]=5'd11; edata[8]=32'h00000004;
        erd[9]=5'd11; edata[9]=32'h00000005;
        erd[10]=5'd10; edata[10]=32'h00000003;
        erd[11]=5'd11; edata[11]=32'h00000006;
        erd[12]=5'd11; edata[12]=32'h00000007;
        erd[13]=5'd10; edata[13]=32'h00000004;
        erd[14]=5'd11; edata[14]=32'h00000008;
        erd[15]=5'd11; edata[15]=32'h00000009;
        erd[16]=5'd10; edata[16]=32'h00000005;
        erd[17]=5'd11; edata[17]=32'h0000000a;
        erd[18]=5'd11; edata[18]=32'h0000000b;
        erd[19]=5'd10; edata[19]=32'h00000006;
        erd[20]=5'd11; edata[20]=32'h0000000c;
        erd[21]=5'd4; edata[21]=32'h00000007;
        erd[22]=5'd5; edata[22]=32'h00000007;
        erd[23]=5'd6; edata[23]=32'h00000003;
        erd[24]=5'd6; edata[24]=32'h00000002;
        erd[25]=5'd6; edata[25]=32'h00000001;
        erd[26]=5'd6; edata[26]=32'h00000000;
        erd[27]=5'd12; edata[27]=32'h80000100;
        erd[28]=5'd13; edata[28]=32'h80000100;
        erd[29]=5'd14; edata[29]=32'h80000118;
        erd[30]=5'd14; edata[30]=32'h8000012d;
        erd[31]=5'd15; edata[31]=32'h80000124;
        erd[32]=5'd16; edata[32]=32'h80000124;
        erd[33]=5'd17; edata[33]=32'h80000130;
        erd[34]=5'd17; edata[34]=32'h8000014d;
        erd[35]=5'd18; edata[35]=32'h8000014d;
        erd[36]=5'd19; edata[36]=32'h80000144;
        erd[37]=5'd20; edata[37]=32'h80000144;
        erd[38]=5'd21; edata[38]=32'h80000150;
        erd[39]=5'd21; edata[39]=32'h80000160;
        erd[40]=5'd31; edata[40]=32'h00000001;
        epc[0]=32'h8000000c; etaken[0]=1'b1; etarget[0]=32'h80000018;
        epc[1]=32'h8000001c; etaken[1]=1'b0; etarget[1]=32'h80000028;
        epc[2]=32'h8000002c; etaken[2]=1'b1; etarget[2]=32'h80000038;
        epc[3]=32'h8000003c; etaken[3]=1'b0; etarget[3]=32'h80000048;
        epc[4]=32'h8000004c; etaken[4]=1'b1; etarget[4]=32'h80000058;
        epc[5]=32'h8000005c; etaken[5]=1'b0; etarget[5]=32'h80000068;
        epc[6]=32'h8000006c; etaken[6]=1'b1; etarget[6]=32'h80000078;
        epc[7]=32'h8000007c; etaken[7]=1'b0; etarget[7]=32'h80000088;
        epc[8]=32'h8000008c; etaken[8]=1'b1; etarget[8]=32'h80000098;
        epc[9]=32'h8000009c; etaken[9]=1'b0; etarget[9]=32'h800000a8;
        epc[10]=32'h800000ac; etaken[10]=1'b1; etarget[10]=32'h800000b8;
        epc[11]=32'h800000bc; etaken[11]=1'b0; etarget[11]=32'h800000c8;
        epc[12]=32'h800000d0; etaken[12]=1'b1; etarget[12]=32'h800000dc;
        epc[13]=32'h800000e4; etaken[13]=1'b1; etarget[13]=32'h800000f0;
        epc[14]=32'h800000f8; etaken[14]=1'b1; etarget[14]=32'h800000f4;
        epc[15]=32'h800000f8; etaken[15]=1'b1; etarget[15]=32'h800000f4;
        epc[16]=32'h800000f8; etaken[16]=1'b0; etarget[16]=32'h800000f4;
        epc[17]=32'h800000fc; etaken[17]=1'b1; etarget[17]=32'h80000108;
        epc[18]=32'h8000010c; etaken[18]=1'b1; etarget[18]=32'h80000118;
        epc[19]=32'h80000120; etaken[19]=1'b1; etarget[19]=32'h8000012c;
        epc[20]=32'h80000140; etaken[20]=1'b1; etarget[20]=32'h8000014c;
        epc[21]=32'h80000158; etaken[21]=1'b1; etarget[21]=32'h80000164;
        eaddr[0]=32'h00000004; estore[0]=32'h00000007;
        eaddr[1]=32'h00000008; estore[1]=32'h8000014d;
        for(i=0;i<32;i=i+1) final_regs[i]=0;
        for(i=0;i<WCOUNT;i=i+1) final_regs[erd[i]]=edata[i];
        fd=$fopen("../sw/ctrltest/core_ctrltest.hex","r");
        if(fd==0) $fatal(1,"Missing core_ctrltest.hex; run from sim/");
        $fclose(fd);
        #2; rst_n=0; repeat(3) @(negedge clk); #1; rst_n=1;
        wait(finished); repeat(4) @(negedge clk); #1;
        if(ci!=CCOUNT || si!=SCOUNT) $fatal(1,"FAIL: missing control/store events %0d/%0d %0d/%0d",ci,CCOUNT,si,SCOUNT);
        if(stalls<2) $fatal(1,"FAIL: expected load->branch and load->JALR stalls, got %0d",stalls);
        for(i=0;i<32;i=i+1) begin
            if(dut.u_regfile.regs_q[i] !== final_regs[i]) $fatal(1,"FAIL: final x%0d=%h expected=%h",i,dut.u_regfile.regs_q[i],final_regs[i]);
            checks=checks+1;
        end
        if(dut.u_data_memory.mem[0] !== 32'h0 || dut.u_data_memory.mem[1] !== estore[0] || dut.u_data_memory.mem[2] !== estore[1])
            $fatal(1,"FAIL: final memory / wrong-path side effect");
        checks=checks+3;
        $display("PASS: tb_core_ctrltest, %0d checks, %0d WB, %0d control events, %0d stores, %0d load-use stalls",checks,wi,ci,si,stalls);
        $finish;
    end
    initial begin
        #20000; $fatal(1,"TIMEOUT: WB=%0d/%0d control=%0d/%0d",wi,WCOUNT,ci,CCOUNT);
    end
endmodule
