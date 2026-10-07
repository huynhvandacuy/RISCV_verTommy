module top(
    input clk_i,
    input rst_ni
);

    // ============================================================
    // IF Stage
    // ============================================================
    wire [31:0] pc_if;
    wire [31:0] pc_next;
    wire [31:0] pc_plus4_if;
    wire        pc_stall;

    pc u_pc (
        .clk_i         (clk_i),
        .rst_ni        (rst_ni),
        .pc_next_i     (pc_next),
        .pc_write_en_i (~pc_stall),
        .pc_o          (pc_if)
    );

    assign pc_plus4_if = pc_if + 32'd4;

    wire [31:0] instr_if;

    instr_mem u_instr_mem (
        .addr_i  (pc_if),
        .instr_o (instr_if)
    );

    // ============================================================
    // IF/ID Pipeline Register
    // ============================================================
    wire        ifid_write_en;
    wire        ifid_flush;
    wire [31:0] instr_id;
    wire [31:0] pc_id;

    if_id_reg u_if_id_reg (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .instr_i    (instr_if),
        .pc_i       (pc_if),
        .flush_i    (ifid_flush),
        .write_en_i (ifid_write_en),
        .instr_o    (instr_id),
        .pc_o       (pc_id)
    );

    // ============================================================
    // ID Stage
    // ============================================================
    wire [6:0] opcode_id;
    wire [4:0] rd_addr_id;
    wire [4:0] rs1_addr_id;
    wire [4:0] rs2_addr_id;
    wire [2:0] funct3_id;
    wire [6:0] funct7_id;

    instr_fields u_instr_fields (
        .instr_i    (instr_id),
        .opcode_o   (opcode_id),
        .rd_addr_o  (rd_addr_id),
        .funct3_o   (funct3_id),
        .rs1_addr_o (rs1_addr_id),
        .rs2_addr_o (rs2_addr_id),
        .funct7_o   (funct7_id)
    );

    wire [31:0] imm_i_id, imm_s_id, imm_b_id, imm_u_id, imm_j_id;

    imm_gen u_imm_gen (
        .instr_i (instr_id),
        .imm_i_o (imm_i_id),
        .imm_s_o (imm_s_id),
        .imm_b_o (imm_b_id),
        .imm_u_o (imm_u_id),
        .imm_j_o (imm_j_id)
    );

    // Control
    wire       alu_src_b_imm_id, wb_sel_mem_id, reg_write_en_id, mem_read_en_id, mem_write_en_id, branch_en_id;
    wire       jal_en_id, jalr_en_id, alu_src_a_pc_id, alu_src_a_zero_id;
    wire [1:0] alu_class_id;

    control_unit u_control (
        .opcode_i         (opcode_id),
        .reg_write_en_o   (reg_write_en_id),
        .mem_read_en_o    (mem_read_en_id),
        .mem_write_en_o   (mem_write_en_id),
        .wb_sel_mem_o     (wb_sel_mem_id),
        .alu_src_b_imm_o  (alu_src_b_imm_id),
        .branch_en_o      (branch_en_id),
        .jal_en_o         (jal_en_id),
        .jalr_en_o        (jalr_en_id),
        .alu_src_a_pc_o   (alu_src_a_pc_id),
        .alu_src_a_zero_o (alu_src_a_zero_id),
        .alu_class_o      (alu_class_id)
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
    wire        reg_write_en_wb;
    wire [ 4:0] rd_addr_wb;
    wire [31:0] write_data_wb;
    wire [31:0] rs1_data_id, rs2_data_id;

    wire [31:0] debug_x0,  debug_x1,  debug_x2,  debug_x3;
    wire [31:0] debug_x4,  debug_x5,  debug_x6,  debug_x7;
    wire [31:0] debug_x8,  debug_x9,  debug_x10, debug_x11;
    wire [31:0] debug_x12, debug_x13, debug_x14, debug_x15;
    wire [31:0] debug_x16, debug_x17, debug_x18, debug_x19;
    wire [31:0] debug_x20, debug_x21, debug_x22, debug_x23;
    wire [31:0] debug_x24, debug_x25, debug_x26, debug_x27;
    wire [31:0] debug_x28, debug_x29, debug_x30, debug_x31;

    regfile u_regfile (
        .clk_i        (clk_i),
        .rst_ni       (rst_ni),
        .write_en_i   (reg_write_en_wb),
        .rs1_addr_i   (rs1_addr_id),
        .rs2_addr_i   (rs2_addr_id),
        .rd_addr_i    (rd_addr_wb),
        .write_data_i (write_data_wb),
        .rs1_data_o   (rs1_data_id),
        .rs2_data_o   (rs2_data_id),
        .debug_x0_o   (debug_x0),
        .debug_x1_o   (debug_x1),
        .debug_x2_o   (debug_x2),
        .debug_x3_o   (debug_x3),
        .debug_x4_o   (debug_x4),
        .debug_x5_o   (debug_x5),
        .debug_x6_o   (debug_x6),
        .debug_x7_o   (debug_x7),
        .debug_x8_o   (debug_x8),
        .debug_x9_o   (debug_x9),
        .debug_x10_o  (debug_x10),
        .debug_x11_o  (debug_x11),
        .debug_x12_o  (debug_x12),
        .debug_x13_o  (debug_x13),
        .debug_x14_o  (debug_x14),
        .debug_x15_o  (debug_x15),
        .debug_x16_o  (debug_x16),
        .debug_x17_o  (debug_x17),
        .debug_x18_o  (debug_x18),
        .debug_x19_o  (debug_x19),
        .debug_x20_o  (debug_x20),
        .debug_x21_o  (debug_x21),
        .debug_x22_o  (debug_x22),
        .debug_x23_o  (debug_x23),
        .debug_x24_o  (debug_x24),
        .debug_x25_o  (debug_x25),
        .debug_x26_o  (debug_x26),
        .debug_x27_o  (debug_x27),
        .debug_x28_o  (debug_x28),
        .debug_x29_o  (debug_x29),
        .debug_x30_o  (debug_x30),
        .debug_x31_o  (debug_x31)
    );

    // ============================================================
    // ID/EX Pipeline Register
    // ============================================================
    wire        idex_flush;
    wire        idex_stall;
    wire [31:0] pc_ex, rs1_data_ex, rs2_data_ex, imm_ex;
    wire [ 4:0] rs1_addr_ex, rs2_addr_ex, rd_addr_ex;
    wire [ 2:0] funct3_ex;
    wire [ 6:0] funct7_ex;
    wire        alu_src_b_imm_ex, wb_sel_mem_ex, reg_write_en_ex, mem_read_en_ex, mem_write_en_ex, branch_en_ex;
    wire        jal_en_ex, jalr_en_ex, alu_src_a_pc_ex, alu_src_a_zero_ex;
    wire [ 1:0] alu_class_ex;

    id_ex_reg u_id_ex_reg (
        .clk_i            (clk_i),
        .rst_ni           (rst_ni),
        .flush_i          (idex_flush),
        .stall_i          (idex_stall),
        .pc_i             (pc_id),
        .rs1_data_i       (rs1_data_id),
        .rs2_data_i       (rs2_data_id),
        .imm_i            (imm_sel_id),
        .rs1_addr_i       (rs1_addr_id),
        .rs2_addr_i       (rs2_addr_id),
        .rd_addr_i        (rd_addr_id),
        .funct3_i         (funct3_id),
        .funct7_i         (funct7_id),
        .alu_src_b_imm_i  (alu_src_b_imm_id),
        .wb_sel_mem_i     (wb_sel_mem_id),
        .reg_write_en_i   (reg_write_en_id),
        .mem_read_en_i    (mem_read_en_id),
        .mem_write_en_i   (mem_write_en_id),
        .branch_en_i      (branch_en_id),
        .jal_en_i         (jal_en_id),
        .jalr_en_i        (jalr_en_id),
        .alu_src_a_pc_i   (alu_src_a_pc_id),
        .alu_src_a_zero_i (alu_src_a_zero_id),
        .alu_class_i      (alu_class_id),
        .pc_o             (pc_ex),
        .rs1_data_o       (rs1_data_ex),
        .rs2_data_o       (rs2_data_ex),
        .imm_o            (imm_ex),
        .rs1_addr_o       (rs1_addr_ex),
        .rs2_addr_o       (rs2_addr_ex),
        .rd_addr_o        (rd_addr_ex),
        .funct3_o         (funct3_ex),
        .funct7_o         (funct7_ex),
        .alu_src_b_imm_o  (alu_src_b_imm_ex),
        .wb_sel_mem_o     (wb_sel_mem_ex),
        .reg_write_en_o   (reg_write_en_ex),
        .mem_read_en_o    (mem_read_en_ex),
        .mem_write_en_o   (mem_write_en_ex),
        .branch_en_o      (branch_en_ex),
        .jal_en_o         (jal_en_ex),
        .jalr_en_o        (jalr_en_ex),
        .alu_src_a_pc_o   (alu_src_a_pc_ex),
        .alu_src_a_zero_o (alu_src_a_zero_ex),
        .alu_class_o      (alu_class_ex)
    );

    // EX/MEM wires (declare trước để dùng trong forwarding)
    wire [31:0] exec_result_mem;
    wire [31:0] rs2_data_mem;
    wire        mem_read_en_mem, mem_write_en_mem, wb_sel_mem_mem, reg_write_en_mem;
    wire [2:0]  funct3_mem;

    // ============================================================
    // EX Stage
    // ============================================================

    // Forwarding Unit
    wire [1:0] forward_a_sel_ex, forward_b_sel_ex;
    wire [4:0] rd_addr_mem;

    forwarding_unit u_forwarding (
        .rs1_addr_ex_i      (rs1_addr_ex),
        .rs2_addr_ex_i      (rs2_addr_ex),
        .rd_addr_mem_i      (rd_addr_mem),
        .rd_addr_wb_i       (rd_addr_wb),
        .reg_write_en_mem_i (reg_write_en_mem),
        .reg_write_en_wb_i  (reg_write_en_wb),
        .forward_a_sel_o    (forward_a_sel_ex),
        .forward_b_sel_o    (forward_b_sel_ex)
    );

    // WB data for forwarding

    wire [31:0] rs1_data_forward_ex = (forward_a_sel_ex==2'b10) ? exec_result_mem :
                             (forward_a_sel_ex==2'b01) ? write_data_wb    :
                                             rs1_data_ex;

    wire [31:0] rs2_data_forward_ex = (forward_b_sel_ex==2'b10) ? exec_result_mem :
                             (forward_b_sel_ex==2'b01) ? write_data_wb    :
                                             rs2_data_ex;

    // SrcA/SrcB for ALU
    reg [31:0] alu_src_a_ex;
    reg [31:0] alu_src_b_ex;

    always @(*) begin
        if (jal_en_ex || jalr_en_ex) begin
            alu_src_a_ex = pc_ex;
            alu_src_b_ex = 32'd4;
        end else begin
            if (alu_src_a_pc_ex) begin
                alu_src_a_ex = pc_ex;
            end else if (alu_src_a_zero_ex) begin
                alu_src_a_ex = 32'd0;
            end else begin
                alu_src_a_ex = rs1_data_forward_ex;
            end
            alu_src_b_ex = (alu_src_b_imm_ex) ? imm_ex : rs2_data_forward_ex;
        end
    end

    // ALU Control + ALU
    wire [ 4:0] alu_op_ex;
    wire [31:0] alu_result_ex;
    wire        zero_flag_unused;
    wire        is_m_op_ex;

    alu_control u_alu_control (
        .alu_class_i   (alu_class_ex),
        .funct3_i      (funct3_ex),
        .funct7_bit0_i (funct7_ex[0]),
        .funct7_bit5_i (funct7_ex[5]),
        .alu_op_o      (alu_op_ex),
        .is_m_op_o     (is_m_op_ex)
    );

    alu u_alu (
        .src_a_i  (alu_src_a_ex),
        .src_b_i  (alu_src_b_ex),
        .alu_op_i (alu_op_ex),
        .result_o (alu_result_ex),
        .zero_o   (zero_flag_unused)
    );

    // Comparator for branches
    reg take_branch_ex;
    always @(*) begin
        case (funct3_ex)
            3'b000: take_branch_ex = (rs1_data_forward_ex == rs2_data_forward_ex);                     // BEQ
            3'b001: take_branch_ex = (rs1_data_forward_ex != rs2_data_forward_ex);                     // BNE
            3'b100: take_branch_ex = ($signed(rs1_data_forward_ex) <  $signed(rs2_data_forward_ex));   // BLT
            3'b101: take_branch_ex = ($signed(rs1_data_forward_ex) >= $signed(rs2_data_forward_ex));   // BGE
            3'b110: take_branch_ex = (rs1_data_forward_ex <  rs2_data_forward_ex);                     // BLTU
            3'b111: take_branch_ex = (rs1_data_forward_ex >= rs2_data_forward_ex);                     // BGEU
            default: take_branch_ex = 1'b0;
        endcase
    end

    // Branch/Jump targets
    wire [31:0] branch_target_ex = pc_ex + imm_ex;
    wire [31:0] jal_target_ex    = pc_ex + imm_ex;
    wire [31:0] jalr_target_ex   = (rs1_data_forward_ex + imm_ex) & ~32'h1;

    // M-extension co-processor
    wire        mul_div_busy_ex;
    wire        mul_div_done_ex;
    wire [31:0] mul_div_result_ex;

    mul_div_unit u_mul_div (
        .clk_i    (clk_i),
        .rst_ni   (rst_ni),
        .start_i  (is_m_op_ex),
        .src_a_i  (rs1_data_forward_ex),
        .src_b_i  (rs2_data_forward_ex),
        .funct3_i (funct3_ex),
        .result_o (mul_div_result_ex),
        .busy_o   (mul_div_busy_ex),
        .done_o   (mul_div_done_ex)
    );

    // EX result: M-extension result or ALU result
    wire [31:0] exec_result_ex = is_m_op_ex ? mul_div_result_ex : alu_result_ex;

    // ============================================================
    // EX/MEM Pipeline Register
    // ============================================================
    ex_mem_reg u_ex_mem_reg (
        .clk_i          (clk_i),
        .rst_ni         (rst_ni),
        .flush_i        (1'b0),
        .exec_result_i  (exec_result_ex),
        .store_data_i   (rs2_data_forward_ex),
        .rd_addr_i      (rd_addr_ex),
        .mem_read_en_i  (mem_read_en_ex),
        .mem_write_en_i (mem_write_en_ex),
        .wb_sel_mem_i   (wb_sel_mem_ex),
        .reg_write_en_i (reg_write_en_ex),
        .funct3_i       (funct3_ex),
        .exec_result_o  (exec_result_mem),
        .store_data_o   (rs2_data_mem),
        .rd_addr_o      (rd_addr_mem),
        .mem_read_en_o  (mem_read_en_mem),
        .mem_write_en_o (mem_write_en_mem),
        .wb_sel_mem_o   (wb_sel_mem_mem),
        .reg_write_en_o (reg_write_en_mem),
        .funct3_o       (funct3_mem)
    );

    // ============================================================
    // MEM Stage
    // ============================================================
    wire [31:0] load_data_mem;

    data_memory u_data_memory (
        .clk_i        (clk_i),
        .read_en_i    (mem_read_en_mem),
        .write_en_i   (mem_write_en_mem),
        .addr_i       (exec_result_mem),
        .write_data_i (rs2_data_mem),
        .funct3_i     (funct3_mem),
        .read_data_o  (load_data_mem)
    );

    // ============================================================
    // MEM/WB Pipeline Register
    // ============================================================
    wire [31:0] load_data_wb, exec_result_wb;
    wire        wb_sel_mem_wb;

    mem_wb_reg u_mem_wb_reg (
        .clk_i          (clk_i),
        .rst_ni         (rst_ni),
        .reg_write_en_i (reg_write_en_mem),
        .wb_sel_mem_i   (wb_sel_mem_mem),
        .load_data_i    (load_data_mem),
        .exec_result_i  (exec_result_mem),
        .rd_addr_i      (rd_addr_mem),
        .reg_write_en_o (reg_write_en_wb),
        .wb_sel_mem_o   (wb_sel_mem_wb),
        .load_data_o    (load_data_wb),
        .exec_result_o  (exec_result_wb),
        .rd_addr_o      (rd_addr_wb)
    );

    // ============================================================
    // WB Stage
    // ============================================================

    assign write_data_wb = (wb_sel_mem_wb) ? load_data_wb : exec_result_wb;


    // ============================================================
    // Hazard Detection
    // ============================================================

    // Load-use: ID_EX đang load và IF/ID dùng rd đó -> stall 1 cycle
    wire load_use_hazard = (mem_read_en_ex && (rd_addr_ex != 5'd0) &&
                         ((rd_addr_ex == rs1_addr_id) || (rd_addr_ex == rs2_addr_id)));

    // M-extension busy
    wire ex_m_busy = mul_div_busy_ex;

    // Control flush (branch taken / JAL / JALR)
    wire ctrl_flush_ex = (branch_en_ex & take_branch_ex) | jal_en_ex | jalr_en_ex;

    assign pc_stall      = load_use_hazard | ex_m_busy;
    assign ifid_write_en = ~(load_use_hazard | ex_m_busy);
    assign ifid_flush    = ctrl_flush_ex;

    assign idex_stall    = ex_m_busy;
    assign idex_flush    = load_use_hazard | ctrl_flush_ex;

    // ============================================================
    // PC Next
    // ============================================================
    assign pc_next =  jalr_en_ex                      ? jalr_target_ex   :
                      jal_en_ex                       ? jal_target_ex    :
                      (branch_en_ex & take_branch_ex) ? branch_target_ex :
                                                     pc_plus4_if;

    // Trace
    always @(posedge clk_i) if (rst_ni) $display("PC=%h INS=%h", pc_if, instr_if);

endmodule
