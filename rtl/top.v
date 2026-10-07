module top(
    input clk,
    input rst_n
);

    // ============================================================
    // IF Stage
    // ============================================================
    wire [31:0] pc_if;
    wire [31:0] pc_next;
    wire [31:0] pc_plus4_if;
    wire        pc_stall;

    pc PC0(
        .clk     (clk),
        .rst_n   (rst_n),
        .pc_next (pc_next),
        .pc_write(~pc_stall),   // pc_write active high = không stall
        .pc_out  (pc_if)
    );

    assign pc_plus4_if = pc_if + 32'd4;

    wire [31:0] ins_if;

    i_mem IMEM(
        .ins_addr(pc_if),
        .ins     (ins_if)
    );

    // ============================================================
    // IF/ID Pipeline Register
    // ============================================================
    wire        ifid_write_en;
    wire        ifid_flush;
    wire [31:0] ins_id;
    wire [31:0] pc_id;

    IF_ID IF_ID0(
        .clk     (clk),
        .rst_n   (rst_n),
        .ins     (ins_if),
        .pc_in   (pc_if),
        .flush   (ifid_flush),
        .write_en(ifid_write_en),
        .ins_out (ins_id),
        .pc_out  (pc_id)
    );

    // ============================================================
    // ID Stage
    // ============================================================
    wire [6:0] opcode_id;
    wire [4:0] rd_id;
    wire [4:0] rs1_id;
    wire [4:0] rs2_id;
    wire [2:0] funct3_id;
    wire [6:0] funct7_id;

    ins_parser PARSE_ID(
        .ins   (ins_id),
        .opcode(opcode_id),
        .rd    (rd_id),
        .funct3(funct3_id),
        .rs1   (rs1_id),
        .rs2   (rs2_id),
        .funct7(funct7_id)
    );

    wire [31:0] imm_i_id, imm_s_id, imm_b_id, imm_u_id, imm_j_id;

    immediate_data_extractor IMM_ID(
        .ins  (ins_id),
        .imm_i(imm_i_id),
        .imm_s(imm_s_id),
        .imm_b(imm_b_id),
        .imm_u(imm_u_id),
        .imm_j(imm_j_id)
    );

    // Control
    wire       aluSrc_id, mem_to_reg_id, reg_write_id, mem_read_id, mem_write_id, branch_id;
    wire       jal_id, jalr_id, use_pc_srcA_id, use_zero_srcA_id;
    wire [1:0] aluOp_id;

    control_unit CTRL_ID(
        .opcode     (opcode_id),
        .RegWrite   (reg_write_id),
        .MemRead    (mem_read_id),
        .MemWrite   (mem_write_id),
        .MemtoReg   (mem_to_reg_id),
        .ALUSrc     (aluSrc_id),
        .Branch     (branch_id),
        .Jal        (jal_id),
        .Jalr       (jalr_id),
        .UsePcSrcA  (use_pc_srcA_id),
        .UseZeroSrcA(use_zero_srcA_id),
        .ALUOp      (aluOp_id)
    );

    // Choose immediate based on opcode
    reg [31:0] imm_sel_id;
    always @(*) begin
        case (opcode_id)
            7'b0000011, // LOAD
            7'b0010011, // OP-IMM
            7'b1100111: // JALR
                imm_sel_id = imm_i_id;
            7'b0100011: // STORE
                imm_sel_id = imm_s_id;
            7'b1100011: // BRANCH
                imm_sel_id = imm_b_id;
            7'b0110111, // LUI
            7'b0010111: // AUIPC
                imm_sel_id = imm_u_id;
            7'b1101111: // JAL
                imm_sel_id = imm_j_id;
            default:    imm_sel_id = 32'b0;
        endcase
    end

    // Register File
    wire        wb_reg_write;
    wire [ 4:0] wb_rd;
    wire [31:0] wb_wdata;
    wire [31:0] rdata1_id, rdata2_id;

    wire [31:0] debug_x0,  debug_x1,  debug_x2,  debug_x3;
    wire [31:0] debug_x4,  debug_x5,  debug_x6,  debug_x7;
    wire [31:0] debug_x8,  debug_x9,  debug_x10, debug_x11;
    wire [31:0] debug_x12, debug_x13, debug_x14, debug_x15;
    wire [31:0] debug_x16, debug_x17, debug_x18, debug_x19;
    wire [31:0] debug_x20, debug_x21, debug_x22, debug_x23;
    wire [31:0] debug_x24, debug_x25, debug_x26, debug_x27;
    wire [31:0] debug_x28, debug_x29, debug_x30, debug_x31;

    reg_file RF0(
        .clk       (clk),
        .rst_n     (rst_n),
        .write_en  (wb_reg_write),
        .rs1       (rs1_id),
        .rs2       (rs2_id),
        .rd        (wb_rd),
        .write_data(wb_wdata),
        .rdata1    (rdata1_id),
        .rdata2    (rdata2_id),
        .debug_x0  (debug_x0),  .debug_x1  (debug_x1),  .debug_x2  (debug_x2),  .debug_x3  (debug_x3),
        .debug_x4  (debug_x4),  .debug_x5  (debug_x5),  .debug_x6  (debug_x6),  .debug_x7  (debug_x7),
        .debug_x8  (debug_x8),  .debug_x9  (debug_x9),  .debug_x10 (debug_x10), .debug_x11 (debug_x11),
        .debug_x12 (debug_x12), .debug_x13 (debug_x13), .debug_x14 (debug_x14), .debug_x15 (debug_x15),
        .debug_x16 (debug_x16), .debug_x17 (debug_x17), .debug_x18 (debug_x18), .debug_x19 (debug_x19),
        .debug_x20 (debug_x20), .debug_x21 (debug_x21), .debug_x22 (debug_x22), .debug_x23 (debug_x23),
        .debug_x24 (debug_x24), .debug_x25 (debug_x25), .debug_x26 (debug_x26), .debug_x27 (debug_x27),
        .debug_x28 (debug_x28), .debug_x29 (debug_x29), .debug_x30 (debug_x30), .debug_x31 (debug_x31)
    );

    // ============================================================
    // ID/EX Pipeline Register
    // ============================================================
    wire        idex_flush;
    wire        idex_stall;
    wire [31:0] pc_ex, rdata1_ex, rdata2_ex, imm_ex;
    wire [ 4:0] rs1_ex, rs2_ex, rd_ex;
    wire [ 2:0] funct3_ex;
    wire [ 6:0] funct7_ex;
    wire        aluSrc_ex, mem_to_reg_ex, reg_write_ex, mem_read_ex, mem_write_ex, branch_ex;
    wire        jal_ex, jalr_ex, use_pc_srcA_ex, use_zero_srcA_ex;
    wire [ 1:0] aluOp_ex;

    ID_EX ID_EX0(
        .clk              (clk),
        .rst_n            (rst_n),
        .flush            (idex_flush),
        .stall            (idex_stall),

        .pc_in            (pc_id),
        .rdata1_in        (rdata1_id),
        .rdata2_in        (rdata2_id),
        .imm_in           (imm_sel_id),
        .rs1_in           (rs1_id),
        .rs2_in           (rs2_id),
        .rd_in            (rd_id),
        .funct3_in        (funct3_id),
        .funct7_in        (funct7_id),

        .aluSrc_in        (aluSrc_id),
        .mem_to_reg_in    (mem_to_reg_id),
        .reg_write_in     (reg_write_id),
        .mem_read_in      (mem_read_id),
        .mem_write_in     (mem_write_id),
        .branch_in        (branch_id),
        .jal_in           (jal_id),
        .jalr_in          (jalr_id),
        .use_pc_srcA_in   (use_pc_srcA_id),
        .use_zero_srcA_in (use_zero_srcA_id),
        .aluOp_in         (aluOp_id),

        .pc_out           (pc_ex),
        .rdata1_out       (rdata1_ex),
        .rdata2_out       (rdata2_ex),
        .imm_out          (imm_ex),
        .rs1_out          (rs1_ex),
        .rs2_out          (rs2_ex),
        .rd_out           (rd_ex),
        .funct3_out       (funct3_ex),
        .funct7_out       (funct7_ex),

        .aluSrc_out       (aluSrc_ex),
        .mem_to_reg_out   (mem_to_reg_ex),
        .reg_write_out    (reg_write_ex),
        .mem_read_out     (mem_read_ex),
        .mem_write_out    (mem_write_ex),
        .branch_out       (branch_ex),
        .jal_out          (jal_ex),
        .jalr_out         (jalr_ex),
        .use_pc_srcA_out  (use_pc_srcA_ex),
        .use_zero_srcA_out(use_zero_srcA_ex),
        .aluOp_out        (aluOp_ex)
    );

    // EX/MEM wires (declare trước để dùng trong forwarding)
    wire [31:0] alu_result_mem;
    wire [31:0] rdata2_mem;
    wire        mem_read_mem, mem_write_mem, mem_to_reg_mem, reg_write_mem;
    wire [2:0]  funct3_mem;

    // ============================================================
    // EX Stage
    // ============================================================

    // Forwarding Unit
    wire [1:0] fwdA, fwdB;
    wire [4:0] mem_rd;
    wire [4:0] wb_rd_int;
    wire       mem_reg_write;
    wire       wb_reg_write_int;

    forwarding_unit FWD0(
        .EX_rs1      (rs1_ex),
        .EX_rs2      (rs2_ex),
        .MEM_rd      (mem_rd),
        .WB_rd       (wb_rd_int),
        .MEM_regWrite(reg_write_mem),
        .WB_regWrite (wb_reg_write_int),
        .ForwardA    (fwdA),
        .ForwardB    (fwdB)
    );

    // WB data for forwarding
    wire [31:0] wb_data_int;

    wire [31:0] rdata1_fwd = (fwdA==2'b10) ? alu_result_mem :
                             (fwdA==2'b01) ? wb_data_int    :
                                             rdata1_ex;

    wire [31:0] rdata2_fwd = (fwdB==2'b10) ? alu_result_mem :
                             (fwdB==2'b01) ? wb_data_int    :
                                             rdata2_ex;

    // SrcA/SrcB for ALU
    reg [31:0] srcA_ex_v;
    reg [31:0] srcB_ex_v;

    always @(*) begin
        if (jal_ex || jalr_ex) begin
            srcA_ex_v = pc_ex;
            srcB_ex_v = 32'd4;
        end else begin
            if (use_pc_srcA_ex) begin
                srcA_ex_v = pc_ex;
            end else if (use_zero_srcA_ex) begin
                srcA_ex_v = 32'd0;
            end else begin
                srcA_ex_v = rdata1_fwd;
            end
            srcB_ex_v = (aluSrc_ex) ? imm_ex : rdata2_fwd;
        end
    end

    // ALU Control + ALU
    wire [ 4:0] alu_ctrl_ex;
    wire [31:0] alu_result_ex;
    wire        zero_flag_unused;
    wire        is_m_op_ex;

    alu_control ALUCTRL0(
        .alu_op   (aluOp_ex),
        .funct3   (funct3_ex),
        .funct7_7 (funct7_ex[0]),
        .funct7_5 (funct7_ex[5]),
        .alu_ctrl (alu_ctrl_ex),
        .is_m_op  (is_m_op_ex)
    );

    alu ALU0(
        .src_a     (srcA_ex_v),
        .src_b     (srcB_ex_v),
        .alu_ctrl  (alu_ctrl_ex),
        .alu_result(alu_result_ex),
        .zero_flag (zero_flag_unused)
    );

    // Comparator for branches
    reg take_branch_ex;
    always @(*) begin
        case (funct3_ex)
            3'b000: take_branch_ex = (rdata1_fwd == rdata2_fwd);                     // BEQ
            3'b001: take_branch_ex = (rdata1_fwd != rdata2_fwd);                     // BNE
            3'b100: take_branch_ex = ($signed(rdata1_fwd) <  $signed(rdata2_fwd));   // BLT
            3'b101: take_branch_ex = ($signed(rdata1_fwd) >= $signed(rdata2_fwd));   // BGE
            3'b110: take_branch_ex = (rdata1_fwd <  rdata2_fwd);                     // BLTU
            3'b111: take_branch_ex = (rdata1_fwd >= rdata2_fwd);                     // BGEU
            default: take_branch_ex = 1'b0;
        endcase
    end

    // Branch/Jump targets
    wire [31:0] branch_target_ex = pc_ex + imm_ex;
    wire [31:0] jal_target_ex    = pc_ex + imm_ex;
    wire [31:0] jalr_target_ex   = (rdata1_fwd + imm_ex) & ~32'h1;

    // M-extension co-processor
    wire        m_hold_ex;
    wire        m_done_ex;
    wire        m_wr_ex;
    wire [31:0] m_result_ex;

    mul_div_unit MEXT0(
        .clk     (clk),
        .rst_n   (rst_n),
        .start   (is_m_op_ex),
        .src_a   (rdata1_fwd),
        .src_b   (rdata2_fwd),
        .funct3  (funct3_ex),
        .result  (m_result_ex),
        .busy    (m_hold_ex),
        .done    (m_done_ex)
    );

    // EX result: M-extension result or ALU result
    wire [31:0] ex_result_final = is_m_op_ex ? m_result_ex : alu_result_ex;

    // ============================================================
    // EX/MEM Pipeline Register
    // ============================================================
    EX_MEM EX_MEM0(
        .clk           (clk),
        .rst_n         (rst_n),
        .flush         (1'b0),

        .alu_result_in (ex_result_final),
        .rdata2_in     (rdata2_fwd),
        .rd_in         (rd_ex),
        .mem_read_in   (mem_read_ex),
        .mem_write_in  (mem_write_ex),
        .mem_to_reg_in (mem_to_reg_ex),
        .reg_write_in  (reg_write_ex),
        .funct3_in     (funct3_ex),

        .alu_result_out(alu_result_mem),
        .rdata2_out    (rdata2_mem),
        .rd_out        (mem_rd),
        .mem_read_out  (mem_read_mem),
        .mem_write_out (mem_write_mem),
        .mem_to_reg_out(mem_to_reg_mem),
        .reg_write_out (reg_write_mem),
        .funct3_out    (funct3_mem)
    );

    // ============================================================
    // MEM Stage
    // ============================================================
    wire [31:0] mem_data_mem;

    data_memory DMEM(
        .clk       (clk),
        .mem_read  (mem_read_mem),
        .mem_write (mem_write_mem),
        .addr      (alu_result_mem),
        .write_data(rdata2_mem),
        .funct3    (funct3_mem),
        .read_data (mem_data_mem)
    );

    // ============================================================
    // MEM/WB Pipeline Register
    // ============================================================
    wire [31:0] mem_data_wb, alu_result_wb;
    wire        mem_to_reg_wb, reg_write_wb;

    MEM_WB MEM_WB0(
        .clk           (clk),
        .rst_n         (rst_n),
        .reg_write_in  (reg_write_mem),
        .mem_to_reg_in (mem_to_reg_mem),
        .mem_data_in   (mem_data_mem),
        .alu_result_in (alu_result_mem),
        .rd_in         (mem_rd),

        .reg_write_out (reg_write_wb),
        .mem_to_reg_out(mem_to_reg_wb),
        .mem_data_out  (mem_data_wb),
        .alu_result_out(alu_result_wb),
        .rd_out        (wb_rd_int)
    );

    // ============================================================
    // WB Stage
    // ============================================================
    assign wb_reg_write_int = reg_write_wb;
    assign wb_rd            = wb_rd_int;

    wire [31:0] wb_data_sel = (mem_to_reg_wb) ? mem_data_wb : alu_result_wb;

    assign wb_wdata     = wb_data_sel;
    assign wb_reg_write = wb_reg_write_int;
    assign wb_data_int  = wb_data_sel;

    // ============================================================
    // Hazard Detection
    // ============================================================

    // Load-use: ID_EX đang load và IF/ID dùng rd đó -> stall 1 cycle
    wire load_use_hazard = (mem_read_ex && (rd_ex != 5'd0) &&
                         ((rd_ex == rs1_id) || (rd_ex == rs2_id)));

    // M-extension busy
    wire ex_m_busy = m_hold_ex;

    // Control flush (branch taken / JAL / JALR)
    wire ctrl_flush_ex = (branch_ex & take_branch_ex) | jal_ex | jalr_ex;

    assign pc_stall      = load_use_hazard | ex_m_busy;
    assign ifid_write_en = ~(load_use_hazard | ex_m_busy);
    assign ifid_flush    = ctrl_flush_ex;

    assign idex_stall    = ex_m_busy;
    assign idex_flush    = load_use_hazard | ctrl_flush_ex;

    // ============================================================
    // PC Next
    // ============================================================
    assign pc_next =  jalr_ex                      ? jalr_target_ex   :
                      jal_ex                       ? jal_target_ex    :
                      (branch_ex & take_branch_ex) ? branch_target_ex :
                                                     pc_plus4_if;

    // Trace
    always @(posedge clk) if (rst_n) $display("PC=%h INS=%h", pc_if, ins_if);

endmodule
