// -----------------------------
// RV32I/M 5-stage pipeline (IF-ID-EX-MEM-WB)
// + M-extension co-processor (multi-cycle) with valid/hold/done handshake
// (No "pcpi_*" names are used.)
// -----------------------------

// =============================
// Program Counter
// =============================
module program_counter(
    input              clk,
    input              rst_n,
    input       [31:0] PC_in,
    input              stall,
    output  reg [31:0] PC_out
  );
    always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        PC_out <= 32'h8000_0000;
      end else begin
        if(!stall) begin
          PC_out <= PC_in;
        end
      end
    end
  endmodule
  
  // =============================
  // Instruction Memory (simple ROM)
  // =============================
  module instruction_memory#(
    parameter IMEM_WORDS = 4096,          // 16KB, 4096 words (1 word = 4 byte)
    parameter IMEM_BASE  = 32'h8000_0000, // Base address
    parameter IMEM_HEX   = "../test_lenh/rv32ui-p-add.hex"
  )(
    input  [31:0]  ins_addr,
    output [31:0]  ins
  );
    reg [31:0] mem [0:IMEM_WORDS-1];
  
    initial begin
      $readmemh(IMEM_HEX, mem);
    end
  
    wire [31:0] addr_off = ins_addr - IMEM_BASE;
    wire [31:0] idx_full = addr_off[31:2];  // word index
    wire        in_range = (ins_addr >= IMEM_BASE) && (idx_full < IMEM_WORDS);
  
    assign ins = in_range ? mem[idx_full[$clog2(IMEM_WORDS)-1:0]] : 32'h0000_0013;
  endmodule
  
  // =============================
  // IF/ID pipeline reg
  // =============================
  module IF_ID(
    input             clk,
    input             rst_n,
    input      [31:0] ins,
    input      [31:0] pc_in,
    input             flush,
    input             write_en,
    output reg [31:0] ins_out,
    output reg [31:0] pc_out
  );
    localparam NOP = 32'h0000_0013; // addi x0,x0,0
  
    always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        ins_out <= NOP;
        pc_out  <= 32'h0000_0000;
      end else if(flush) begin
        ins_out <= NOP;
        pc_out  <= 32'h0000_0000;
      end else if(write_en) begin
        ins_out <= ins;
        pc_out  <= pc_in;
      end
    end
  endmodule
  
  // =============================
  // Instruction field parser
  // =============================
  module instruction_parser(
    input  [31:0] ins,
    output [ 6:0] opcode,
    output [ 4:0] rd,
    output [ 2:0] funct3,
    output [ 4:0] rs1,
    output [ 4:0] rs2,
    output [ 6:0] funct7
  );
    assign opcode = ins[ 6: 0];
    assign rd     = ins[11: 7];
    assign funct3 = ins[14:12];
    assign rs1    = ins[19:15];
    assign rs2    = ins[24:20];
    assign funct7 = ins[31:25];
  endmodule
  
  // =============================
  // Immediate extractor
  // =============================
  module immediate_data_extractor(
    input  [31:0] ins,
    output [31:0] imm_i,
    output [31:0] imm_s,
    output [31:0] imm_b,
    output [31:0] imm_u,
    output [31:0] imm_j
  );
    assign imm_i = {{20{ins[31]}}, ins[31:20]};
    assign imm_s = {{20{ins[31]}}, ins[31:25], ins[11:7]};
    assign imm_b = {{19{ins[31]}}, ins[31], ins[7], ins[30:25], ins[11:8],1'b0};
    assign imm_u = {ins[31:12], 12'b0};
    assign imm_j = {{11{ins[31]}}, ins[19:12], ins[20], ins[30:21], 1'b0};
  endmodule
  
  // =============================
  // Control Unit
  // =============================
  module control_unit(
    input      [6:0] opcode,
    output reg       aluSrc,
    output reg       mem_to_reg,
    output reg       reg_write,
    output reg       mem_read,
    output reg       mem_write,
    output reg       branch,
    output reg       jal,
    output reg       jalr,
    output reg       use_pc_srcA,   // AUIPC
    output reg       use_zero_srcA, // LUI
    output reg [1:0] aluOp
  );
    always @(*) begin
      aluSrc          = 0;
      mem_to_reg      = 0;
      reg_write       = 0;
      mem_read        = 0;
      mem_write       = 0;
      branch          = 0;
      jal             = 0;
      jalr            = 0;
      use_pc_srcA     = 0;
      use_zero_srcA   = 0;
      aluOp           = 2'b00;
  
      case(opcode)
        7'b0110111: begin // LUI
          aluSrc        = 1;
          reg_write     = 1;
          use_zero_srcA = 1;
          aluOp         = 2'b00;
        end
        7'b0010111: begin // AUIPC
          aluSrc        = 1;
          reg_write     = 1;
          use_pc_srcA   = 1;
          aluOp         = 2'b00;
        end
        7'b1101111: begin // JAL
          reg_write     = 1;
          jal           = 1;
        end
        7'b1100111: begin // JALR
          aluSrc        = 1;
          reg_write     = 1;
          jalr          = 1;
        end
        7'b1100011: begin // BRANCH
          branch        = 1;
          aluOp         = 2'b01;
        end
        7'b0000011: begin // LOAD
          aluSrc        = 1;
          mem_to_reg    = 1;
          reg_write     = 1;
          mem_read      = 1;
          aluOp         = 2'b00;
        end
        7'b0100011: begin // STORE
          aluSrc        = 1;
          mem_write     = 1;
          aluOp         = 2'b00;
        end
        7'b0010011: begin // OP-IMM
          aluSrc        = 1;
          reg_write     = 1;
          aluOp         = 2'b11;
        end
        7'b0110011: begin // OP
          reg_write     = 1;
          aluOp         = 2'b10;
        end
        default: ;
      endcase
    end
  endmodule
  
  // =============================
  // ALU control (keeps M encodings, ALU will ignore them)
  // =============================
  module alu_control(
    input      [1:0] aluOP,
    input      [2:0] funct3,
    input      [6:0] funct7,
    output reg [4:0] alu_ctrl
  );
    always @(*) begin
      case(aluOP)
        2'b00: alu_ctrl = 5'b00000;            // ADD
        2'b01: alu_ctrl = 5'b00001;            // SUB
        2'b10: begin                           // R-type
          if(funct7 == 7'b0000001) begin
            // M extension (ALU will ignore; co-processor will handle)
            case (funct3)
              3'b000: alu_ctrl = 5'b10000;     // MUL
              3'b001: alu_ctrl = 5'b10001;     // MULH
              3'b010: alu_ctrl = 5'b10010;     // MULHSU
              3'b011: alu_ctrl = 5'b10011;     // MULHU
              3'b100: alu_ctrl = 5'b10100;     // DIV
              3'b101: alu_ctrl = 5'b10101;     // DIVU
              3'b110: alu_ctrl = 5'b10110;     // REM
              3'b111: alu_ctrl = 5'b10111;     // REMU
            endcase
          end else begin
            // RV32I
            case ({funct7[5],funct3})
              4'b0000: alu_ctrl = 5'b00000;    // ADD
              4'b1000: alu_ctrl = 5'b00001;    // SUB
              4'b0001: alu_ctrl = 5'b00010;    // SLL
              4'b0010: alu_ctrl = 5'b00011;    // SLT
              4'b0011: alu_ctrl = 5'b00100;    // SLTU
              4'b0100: alu_ctrl = 5'b00101;    // XOR
              4'b0101: alu_ctrl = 5'b00110;    // SRL
              4'b1101: alu_ctrl = 5'b00111;    // SRA
              4'b0110: alu_ctrl = 5'b01000;    // OR
              4'b0111: alu_ctrl = 5'b01001;    // AND
              default: alu_ctrl = 5'b00000;
            endcase
          end
        end
        2'b11: begin                            // OP-IMM
          case (funct3)
            3'b000: alu_ctrl = 5'b00000;       // ADDI
            3'b010: alu_ctrl = 5'b00011;       // SLTI
            3'b011: alu_ctrl = 5'b00100;       // SLTIU
            3'b100: alu_ctrl = 5'b00101;       // XORI
            3'b110: alu_ctrl = 5'b01000;       // ORI
            3'b111: alu_ctrl = 5'b01001;       // ANDI
            3'b001: alu_ctrl = 5'b00010;       // SLLI
            3'b101: alu_ctrl = (funct7[5]) ? 5'b00111 : 5'b00110; // SRAI/SRLI
            default: alu_ctrl = 5'b00000;
          endcase
        end
        default: alu_ctrl = 5'b00000;
      endcase
    end
  endmodule
  
  // =============================
  // Register File
  // =============================
  module reg_file(
    input         clk,
    input         rst_n,
    input         write_en,
    input  [ 4:0] rs1,
    input  [ 4:0] rs2,
    input  [ 4:0] rd,
    input  [31:0] write_data,
    output [31:0] rdata1,
    output [31:0] rdata2
  );
    reg [31:0] regs [0:31];
    integer i;
  
    always @(negedge rst_n) begin
      if(!rst_n) begin
        for(i = 0; i < 32; i = i + 1)
          regs[i] <= 32'b0;
      end
    end
  
    assign rdata1 = (rs1 == 5'd0) ? 32'b0 : regs[rs1];
    assign rdata2 = (rs2 == 5'd0) ? 32'b0 : regs[rs2];
  
    always @(posedge clk) begin
      if(write_en && (rd != 5'd0)) begin
        regs[rd]  <= write_data;
      end
      regs[0] <= 32'b0;
    end
  endmodule
  
  // =============================
  // ID/EX pipeline reg
  // =============================
  module ID_EX(
    input             clk,
    input             rst_n,
    input             flush,
    input             stall,
  
    // From ID
    input      [31:0] pc_in,
    input      [31:0] rdata1_in,
    input      [31:0] rdata2_in,
    input      [31:0] imm_in,
    input      [ 4:0] rs1_in,
    input      [ 4:0] rs2_in,
    input      [ 4:0] rd_in,
    input      [ 2:0] funct3_in,
    input      [ 6:0] funct7_in,
  
    // Control
    input             aluSrc_in,
    input             mem_to_reg_in,
    input             reg_write_in,
    input             mem_read_in,
    input             mem_write_in,
    input             branch_in,
    input             jal_in,
    input             jalr_in,
    input             use_pc_srcA_in,
    input             use_zero_srcA_in,
    input      [ 1:0] aluOp_in,
  
    // Out
    output reg [31:0] pc_out,
    output reg [31:0] rdata1_out,
    output reg [31:0] rdata2_out,
    output reg [31:0] imm_out,
    output reg [ 4:0] rs1_out,
    output reg [ 4:0] rs2_out,
    output reg [ 4:0] rd_out,
    output reg [ 2:0] funct3_out,
    output reg [ 6:0] funct7_out,
  
    output reg        aluSrc_out,
    output reg        mem_to_reg_out,
    output reg        reg_write_out,
    output reg        mem_read_out,
    output reg        mem_write_out,
    output reg        branch_out,
    output reg        jal_out,
    output reg        jalr_out,
    output reg        use_pc_srcA_out,
    output reg        use_zero_srcA_out,
    output reg [ 1:0] aluOp_out
  );
    always @(posedge clk or negedge rst_n) begin
      if(!rst_n || flush) begin
        pc_out            <= 32'h0;
        rdata1_out        <= 32'b0;
        rdata2_out        <= 32'b0;
        imm_out           <= 32'b0;
        rs1_out           <= 5'b0;
        rs2_out           <= 5'b0;
        rd_out            <= 5'b0;
        funct3_out        <= 3'b0;
        funct7_out        <= 7'b0;
  
        aluSrc_out        <= 1'b0;
        mem_to_reg_out    <= 1'b0;
        reg_write_out     <= 1'b0;
        mem_read_out      <= 1'b0;
        mem_write_out     <= 1'b0;
        branch_out        <= 1'b0;
        jal_out           <= 1'b0;
        jalr_out          <= 1'b0;
        use_pc_srcA_out   <= 1'b0;
        use_zero_srcA_out <= 1'b0;
        aluOp_out         <= 2'b0;
      end else if(!stall) begin
        pc_out            <= pc_in;
        rdata1_out        <= rdata1_in;
        rdata2_out        <= rdata2_in;
        imm_out           <= imm_in;
        rs1_out           <= rs1_in;
        rs2_out           <= rs2_in;
        rd_out            <= rd_in;
        funct3_out        <= funct3_in;
        funct7_out        <= funct7_in;
  
        aluSrc_out        <= aluSrc_in;
        mem_to_reg_out    <= mem_to_reg_in;
        reg_write_out     <= reg_write_in;
        mem_read_out      <= mem_read_in;
        mem_write_out     <= mem_write_in;
        branch_out        <= branch_in;
        jal_out           <= jal_in;
        jalr_out          <= jalr_in;
        use_pc_srcA_out   <= use_pc_srcA_in;
        use_zero_srcA_out <= use_zero_srcA_in;
        aluOp_out         <= aluOp_in;
      end
    end
  endmodule
  
  // =============================
  // ALU (only RV32I ops; M ops handled by co-processor)
  // =============================
  module alu(
    input      [31:0] src_a,
    input      [31:0] src_b,
    input      [ 4:0] alu_ctrl,
    output reg [31:0] alu_result,
    output            zero_flag
  );
    always @(*) begin
      case (alu_ctrl)
        5'b00000: alu_result = src_a + src_b;                      // ADD/ADDI
        5'b00001: alu_result = src_a - src_b;                      // SUB
        5'b00010: alu_result = src_a << src_b[4:0];                // SLL/SLLI
        5'b00011: alu_result = ($signed(src_a) <  $signed(src_b)) ? 32'd1 : 32'd0; // SLT
        5'b00100: alu_result = ($unsigned(src_a) < $unsigned(src_b)) ? 32'd1 : 32'd0; // SLTU
        5'b00101: alu_result = src_a ^ src_b;                      // XOR/XORI
        5'b00110: alu_result = src_a >> src_b[4:0];                // SRL/SRLI
        5'b00111: alu_result = $signed(src_a) >>> src_b[4:0];      // SRA/SRAI
        5'b01000: alu_result = src_a | src_b;                      // OR/ORI
        5'b01001: alu_result = src_a & src_b;                      // AND/ANDI
        default:  alu_result = 32'b0;                              // ignore M codes here
      endcase
    end
  
    assign zero_flag = (alu_result == 32'b0);
  endmodule
  
  // =============================
  // Forwarding Unit
  // =============================
  module forwarding_unit(
    input      [4:0] EX_rs1,
    input      [4:0] EX_rs2,
    input      [4:0] MEM_rd,
    input      [4:0] WB_rd,
    input            MEM_regWrite,
    input            WB_regWrite,
    output reg [1:0] ForwardA,
    output reg [1:0] ForwardB
  );
    always @(*) begin
      ForwardA = 2'b00;
      ForwardB = 2'b00;
  
      if(MEM_regWrite && (MEM_rd != 5'd0) && (MEM_rd == EX_rs1)) begin
        ForwardA = 2'b10;
      end else if(WB_regWrite && (WB_rd != 5'd0) && (WB_rd == EX_rs1)) begin
        ForwardA = 2'b01;
      end
  
      if (MEM_regWrite && (MEM_rd != 5'd0) && (MEM_rd == EX_rs2)) begin
        ForwardB = 2'b10;
      end else if (WB_regWrite && (WB_rd != 5'd0) && (WB_rd == EX_rs2)) begin
        ForwardB = 2'b01;
      end
    end
  endmodule
  
  // =============================
  // EX/MEM pipeline reg
  // =============================
  module EX_MEM(
    input             clk,
    input             rst_n,
    input             flush,
  
    input      [31:0] alu_result_in,
    input      [31:0] rdata2_in,
    input      [ 4:0] rd_in,
    input             mem_read_in,
    input             mem_write_in,
    input             mem_to_reg_in,
    input             reg_write_in,
    input      [ 2:0] funct3_in,
  
    output reg [31:0] alu_result_out,
    output reg [31:0] rdata2_out,
    output reg [ 4:0] rd_out,
    output reg        mem_read_out,
    output reg        mem_write_out,
    output reg        mem_to_reg_out,
    output reg        reg_write_out,
    output reg [ 2:0] funct3_out
  );
    always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        alu_result_out <= 32'b0;
        rdata2_out     <= 32'b0;
        rd_out         <= 5'b0;
        mem_read_out   <= 1'b0;
        mem_write_out  <= 1'b0;
        mem_to_reg_out <= 1'b0;
        reg_write_out  <= 1'b0;
        funct3_out     <= 3'b000;
      end else if(flush) begin
        alu_result_out <= 32'b0;
        rdata2_out     <= 32'b0;
        rd_out         <= 5'b0;
        mem_read_out   <= 1'b0;
        mem_write_out  <= 1'b0;
        mem_to_reg_out <= 1'b0;
        reg_write_out  <= 1'b0;
        funct3_out     <= 3'b000;
      end else begin
        alu_result_out <= alu_result_in;
        rdata2_out     <= rdata2_in;
        rd_out         <= rd_in;
        mem_read_out   <= mem_read_in;
        mem_write_out  <= mem_write_in;
        mem_to_reg_out <= mem_to_reg_in;
        reg_write_out  <= reg_write_in;
        funct3_out     <= funct3_in;
      end
    end
  endmodule
  
  // =============================
  // Data Memory (byte/half/word with sign/zero extend)
  // =============================
  module data_memory#(
    parameter DMEM_WORDS = 4096 // 16KB
  )(
    input             clk,
    input             mem_read,
    input             mem_write,
    input      [31:0] addr,
    input      [31:0] write_data,
    input      [ 2:0] funct3, // SB/SH/SW, LB/LH/LBU/LHU/LW
    output reg [31:0] read_data
  );
    reg [31:0] mem [0:DMEM_WORDS-1];
    integer i;
  
    initial begin
      for (i = 0; i < DMEM_WORDS; i = i + 1)
        mem[i] = 32'b0;
    end
  
    wire [$clog2(DMEM_WORDS)-1:0] index    = addr[31:2];
    wire                   [ 1:0] byte_off = addr[1:0];
    wire                   [31:0] word_r   = mem[index];
  
    always @(posedge clk) begin
      if (mem_write) begin
        case (funct3)
          3'b000: begin // SB
            case (byte_off)
              2'b00: mem[index] <= {word_r[31: 8], write_data[7:0]};
              2'b01: mem[index] <= {word_r[31:16], write_data[7:0], word_r[ 7:0]};
              2'b10: mem[index] <= {word_r[31:24], write_data[7:0], word_r[15:0]};
              2'b11: mem[index] <= {write_data[7:0], word_r[23:0]};
            endcase
          end
          3'b001: begin // SH
            if (byte_off[1]==1'b0) begin
              mem[index] <= {word_r[31:16], write_data[15:0]};
            end else begin
              mem[index] <= {write_data[15:0], word_r[15:0]};
            end
          end
          3'b010: begin // SW
            mem[index] <= write_data;
          end
          default: ;
        endcase
      end
    end
  
    always @(*) begin
      if (!mem_read) begin
        read_data = 32'b0;
      end else begin
        case (funct3)
          3'b000: begin // LB
            case (byte_off)
              2'b00: read_data = {{24{word_r[ 7]}},  word_r[ 7: 0]};
              2'b01: read_data = {{24{word_r[15]}},  word_r[15: 8]};
              2'b10: read_data = {{24{word_r[23]}},  word_r[23:16]};
              2'b11: read_data = {{24{word_r[31]}},  word_r[31:24]};
            endcase
          end
          3'b001: begin // LH
            if (byte_off[1]==1'b0) begin
              read_data = {{16{word_r[15]}}, word_r[15:0]};
            end else begin
              read_data = {{16{word_r[31]}}, word_r[31:16]};
            end
          end
          3'b010: begin // LW
            read_data = word_r;
          end
          3'b100: begin // LBU
            case (byte_off)
              2'b00: read_data = {24'b0, word_r[ 7: 0]};
              2'b01: read_data = {24'b0, word_r[15: 8]};
              2'b10: read_data = {24'b0, word_r[23:16]};
              2'b11: read_data = {24'b0, word_r[31:24]};
            endcase
          end
          3'b101: begin // LHU
            if (byte_off[1]==1'b0) begin
              read_data = {16'b0, word_r[15: 0]};
            end else begin
              read_data = {16'b0, word_r[31:16]};
            end
          end
          default: read_data = 32'b0;
        endcase
      end
    end
  endmodule
  
  // =============================
  // MEM/WB pipeline reg
  // =============================
  module MEM_WB(
    input             clk,
    input             rst_n,
  
    input             reg_write_in,
    input             mem_to_reg_in,
    input      [31:0] mem_data_in,
    input      [31:0] alu_result_in,
    input      [ 4:0] rd_in,
  
    output reg        reg_write_out,
    output reg        mem_to_reg_out,
    output reg [31:0] mem_data_out,
    output reg [31:0] alu_result_out,
    output reg [ 4:0] rd_out
  );
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        reg_write_out   <= 1'b0;
        mem_to_reg_out  <= 1'b0;
        mem_data_out    <= 32'b0;
        alu_result_out  <= 32'b0;
        rd_out          <= 5'b0;
      end else begin
        reg_write_out   <= reg_write_in;
        mem_to_reg_out  <= mem_to_reg_in;
        mem_data_out    <= mem_data_in;
        alu_result_out  <= alu_result_in;
        rd_out          <= rd_in;
      end
    end
  endmodule
  
  // ============================================================
  // M-extension co-processor (mul/div/rem) - multi-cycle
  // Handshake: op_valid -> hold(busy) -> done+wr_en with result
  // ============================================================
  module mext_muldiv (
    input         clk,
    input         rst_n,
    input         op_valid,       // yêu cầu thực thi lệnh M ở EX
    input  [2:0]  f3,             // funct3
    input  [6:0]  f7,             // funct7 (0000001 với M-ext)
    input  [31:0] rs1_val,
    input  [31:0] rs2_val,
    output        hold,           // đang bận -> yêu cầu CPU stall
    output reg    done,           // kết quả sẵn sàng (1 xung)
    output reg    wr_en,          // cho phép ghi về RD (tùy dùng)
    output reg [31:0] result_out  // dữ liệu trả về
  );
    localparam F7_M = 7'b0000001;
  
    reg        busy;
    reg [5:0]  cycles_left;
  
    reg [2:0]  f3_q;
    reg [31:0] a_q, b_q;
    reg [31:0] result_calc;
  
    // helper cho DIV/REM (signed)
    function [31:0] div_signed_q(input [31:0] aa, input [31:0] bb);
      reg div_zero, ovf;
      begin
        div_zero = (bb == 32'b0);
        ovf      = (aa == 32'h8000_0000) && (bb == 32'hFFFF_FFFF);
        div_signed_q = div_zero ? 32'hFFFF_FFFF :
                       ovf      ? 32'h8000_0000 :
                       $signed(aa) / $signed(bb);
      end
    endfunction
  
    function [31:0] rem_signed_r(input [31:0] aa, input [31:0] bb);
      reg div_zero, ovf;
      begin
        div_zero = (bb == 32'b0);
        ovf      = (aa == 32'h8000_0000) && (bb == 32'hFFFF_FFFF);
        rem_signed_r = div_zero ? aa :
                       ovf      ? 32'h0000_0000 :
                       $signed(aa) % $signed(bb);
      end
    endfunction
  
    // 64-bit products
    wire [63:0]        mul_uu = $unsigned(a_q) * $unsigned(b_q);
    wire signed [63:0] mul_ss = $signed(a_q)   * $signed(b_q);
    wire signed [63:0] mul_su = $signed(a_q)   * $signed({1'b0, b_q});
  
    assign hold = busy;
  
    wire accept = op_valid && !busy && (f7 == F7_M);
  
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        busy        <= 1'b0;
        cycles_left <= 6'd0;
        done        <= 1'b0;
        wr_en       <= 1'b0;
        result_out  <= 32'b0;
        result_calc <= 32'b0;
        f3_q        <= 3'b000;
        a_q         <= 32'b0;
        b_q         <= 32'b0;
      end else begin
        // default mỗi nhịp
        done  <= 1'b0;
        wr_en <= 1'b0;
  
        if (accept) begin
          // latch toán hạng + funct3
          f3_q <= f3;
          a_q  <= rs1_val;
          b_q  <= rs2_val;
  
          // set độ trễ
          case (f3)
            3'b000,3'b001,3'b010,3'b011: cycles_left <= 6'd2;   // MUL*
            default:                     cycles_left <= 6'd32;  // DIV/REM*
          endcase
  
          busy <= 1'b1;
  
        end else if (busy) begin
          if (cycles_left != 0) begin
            cycles_left <= cycles_left - 1'b1;
  
            // tính kết quả trước khi kết thúc
            if (cycles_left == 6'd32-1 || cycles_left == 6'd2-1) begin
              case (f3_q)
                3'b000: result_calc <= mul_uu[31:0];                 // MUL
                3'b001: result_calc <= mul_ss[63:32];                // MULH
                3'b010: result_calc <= mul_su[63:32];                // MULHSU
                3'b011: result_calc <= mul_uu[63:32];                // MULHU
                3'b100: result_calc <= div_signed_q(a_q, b_q);       // DIV
                3'b101: result_calc <= (b_q==0) ? 32'hFFFF_FFFF
                                                : ($unsigned(a_q)/$unsigned(b_q)); // DIVU
                3'b110: result_calc <= rem_signed_r(a_q, b_q);       // REM
                3'b111: result_calc <= (b_q==0) ? a_q
                                                : ($unsigned(a_q)%$unsigned(b_q)); // REMU
                default: result_calc <= 32'b0;
              endcase
            end
  
          end else begin
            // nhịp cuối: xuất result và nhả busy
            busy       <= 1'b0;
            result_out <= result_calc;
            done       <= 1'b1;
            wr_en      <= 1'b1;
          end
        end
      end
    end
  endmodule
  
  
  // =============================
  // Top
  // =============================
  module top(
    input clk,
    input rst_n
  );
  
    // ---------- IF ----------
    wire [31:0] pc_if;
    wire [31:0] pc_next;
    wire [31:0] pc_plus4_if;
    wire        pc_stall;
  
    program_counter PC0(
      .clk   (clk),
      .rst_n (rst_n),
      .PC_in (pc_next),
      .stall (pc_stall),
      .PC_out(pc_if)
    );
  
    assign pc_plus4_if = pc_if + 32'd4;
  
    wire [31:0] ins_if;
  
    instruction_memory IMEM(
      .ins_addr(pc_if),
      .ins     (ins_if)
    );
  
    // IF/ID
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
  
    // ---------- ID ----------
    // Parse & imm
    wire [6:0] opcode_id;
    wire [4:0] rd_id;
    wire [4:0] rs1_id;
    wire [4:0] rs2_id;
    wire [2:0] funct3_id;
    wire [6:0] funct7_id;
  
    instruction_parser PARSE_ID(
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
      .opcode       (opcode_id),
      .aluSrc       (aluSrc_id),
      .mem_to_reg   (mem_to_reg_id),
      .reg_write    (reg_write_id),
      .mem_read     (mem_read_id),
      .mem_write    (mem_write_id),
      .branch       (branch_id),
      .jal          (jal_id),
      .jalr         (jalr_id),
      .use_pc_srcA  (use_pc_srcA_id),
      .use_zero_srcA(use_zero_srcA_id),
      .aluOp        (aluOp_id)
    );
  
    // Choose immediate
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
  
    // Regfile + WB
    wire        wb_reg_write;
    wire [ 4:0] wb_rd;
    wire [31:0] wb_wdata;
    wire [31:0] rdata1_id, rdata2_id;
  
    reg_file RF0(
      .clk       (clk),
      .rst_n     (rst_n),
      .write_en  (wb_reg_write),
      .rs1       (rs1_id),
      .rs2       (rs2_id),
      .rd        (wb_rd),
      .write_data(wb_wdata),
      .rdata1    (rdata1_id),
      .rdata2    (rdata2_id)
    );
  
    // ---------- ID/EX ----------
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
  
    // ---------- EX ----------
    // Forwarding
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
      .MEM_regWrite(mem_reg_write),
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
  
    // ALU control + ALU
    wire [ 4:0] alu_ctrl_ex;
    wire [31:0] alu_result_ex;
    wire        zero_flag_unused;
  
    alu_control ALUCTRL0(
      .aluOP   (aluOp_ex),
      .funct3  (funct3_ex),
      .funct7  (funct7_ex),
      .alu_ctrl(alu_ctrl_ex)
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
  
    // Targets
    wire [31:0] branch_target_ex = pc_ex + imm_ex;                 // BRANCH: imm_b
    wire [31:0] jal_target_ex    = pc_ex + imm_ex;                 // JAL   : imm_j
    wire [31:0] jalr_target_ex   = (rdata1_fwd + imm_ex) & ~32'h1; // JALR  : rs1 + imm_i
  
    // ---------- M-extension co-processor in EX ----------
    
    wire        is_m_op_ex = (aluOp_ex == 2'b10) && (funct7_ex == 7'b0000001);
  
    wire        m_hold_ex;
    wire        m_done_ex;
    wire        m_wr_ex;
    wire [31:0] m_result_ex;
  
    mext_muldiv MEXT0 (
      .clk       (clk),
      .rst_n     (rst_n),
      .op_valid  (is_m_op_ex),
      .f3        (funct3_ex),
      .f7        (funct7_ex),
      .rs1_val   (rdata1_fwd),
      .rs2_val   (rdata2_fwd),
      .hold      (m_hold_ex),
      .done      (m_done_ex),
      .wr_en     (m_wr_ex),
      .result_out(m_result_ex)
    );
  
    // EX result selection: prefer co-processor for M ops
    wire [31:0] ex_result_final = is_m_op_ex ? m_result_ex : alu_result_ex;
  
    // ---------- EX/MEM ----------
    wire [31:0] alu_result_mem;
    wire [31:0] rdata2_mem;
    wire        mem_read_mem, mem_write_mem, mem_to_reg_mem, reg_write_mem;
    wire [2:0]  funct3_mem;
  
    EX_MEM EX_MEM0(
      .clk           (clk),
      .rst_n         (rst_n),
      .flush         (1'b0),
  
      .alu_result_in (ex_result_final), // <--- use co-processor result when M op
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
      .reg_write_out (mem_reg_write),
      .funct3_out    (funct3_mem)
    );
  
    // ---------- MEM ----------
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
  
    // ---------- MEM/WB ----------
    wire [31:0] mem_data_wb, alu_result_wb;
    wire        mem_to_reg_wb, reg_write_wb;
  
    MEM_WB MEM_WB0(
      .clk           (clk),
      .rst_n         (rst_n),
      .reg_write_in  (mem_reg_write),
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
  
    // ---------- WB ----------
    assign wb_reg_write_int = reg_write_wb;
    assign wb_rd            = wb_rd_int;
  
    wire [31:0] wb_data_sel = (mem_to_reg_wb) ? mem_data_wb : alu_result_wb;
  
    assign wb_wdata     = wb_data_sel;
    assign wb_reg_write = wb_reg_write_int;
    assign wb_data_int  = wb_data_sel;
  
    // ---------- HAZARD ----------
    // Load-use: khi ID_EX đang load và IF/ID dùng rd đó → stall 1 chu kỳ
    wire load_use_hazard = (mem_read_ex && (rd_ex != 5'd0) &&
                         ((rd_ex == rs1_id) || (rd_ex == rs2_id)));
  
    // M-extension busy in EX: giữ EX đến khi done
    wire ex_m_busy = m_hold_ex;   // <<< chốt ở đây
  
    wire ctrl_flush_ex = (branch_ex & take_branch_ex) | jal_ex | jalr_ex;
  
    assign pc_stall      = load_use_hazard | ex_m_busy;
    assign ifid_write_en = ~(load_use_hazard | ex_m_busy);
    assign ifid_flush    = ctrl_flush_ex;
  
    assign idex_stall    = ex_m_busy;
    assign idex_flush    = load_use_hazard | ctrl_flush_ex;
  
    // ---------- PCNext ----------
    assign pc_next =  jalr_ex                      ? jalr_target_ex   :
                      jal_ex                       ? jal_target_ex    :
                      (branch_ex & take_branch_ex) ? branch_target_ex :
                                                     pc_plus4_if;
  
    // (tuỳ chọn) Trace
    always @(posedge clk) if (rst_n) $display("PC=%h INS=%h", pc_if, ins_if);
  
  endmodule
  