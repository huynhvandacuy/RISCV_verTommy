module data_memory#(
    parameter DMEM_WORDS = 4096 // 16KB
)(
    input             clk_i,
    input             read_en_i,
    input             write_en_i,
    input      [31:0] addr_i,
    input      [31:0] write_data_i,
    input      [ 2:0] funct3_i, // SB/SH/SW, LB/LH/LBU/LHU/LW
    output reg [31:0] read_data_o
);
    reg [31:0] mem [0:DMEM_WORDS-1];
    integer i;

    initial begin
      for (i = 0; i < DMEM_WORDS; i = i + 1)
        mem[i] = 32'b0;
    end

    wire [$clog2(DMEM_WORDS)-1:0] word_index    = addr_i[31:2];
    wire                   [ 1:0] byte_offset = addr_i[1:0];
    wire                   [31:0] read_word   = mem[word_index];

    always @(posedge clk_i) begin
      if (write_en_i) begin
        case (funct3_i)
          3'b000: begin // SB
            case (byte_offset)
              2'b00: mem[word_index] <= {read_word[31: 8], write_data_i[7:0]};
              2'b01: mem[word_index] <= {read_word[31:16], write_data_i[7:0], read_word[ 7:0]};
              2'b10: mem[word_index] <= {read_word[31:24], write_data_i[7:0], read_word[15:0]};
              2'b11: mem[word_index] <= {write_data_i[7:0], read_word[23:0]};
            endcase
          end
          3'b001: begin // SH
            if (byte_offset[1]==1'b0) begin
              mem[word_index] <= {read_word[31:16], write_data_i[15:0]};
            end else begin
              mem[word_index] <= {write_data_i[15:0], read_word[15:0]};
            end
          end
          3'b010: begin // SW
            mem[word_index] <= write_data_i;
          end
          default: ;
        endcase
      end
    end

    always @(*) begin
      if (!read_en_i) begin
        read_data_o = 32'b0;
      end else begin
        case (funct3_i)
          3'b000: begin // LB
            case (byte_offset)
              2'b00: read_data_o = {{24{read_word[ 7]}},  read_word[ 7: 0]};
              2'b01: read_data_o = {{24{read_word[15]}},  read_word[15: 8]};
              2'b10: read_data_o = {{24{read_word[23]}},  read_word[23:16]};
              2'b11: read_data_o = {{24{read_word[31]}},  read_word[31:24]};
            endcase
          end
          3'b001: begin // LH
            if (byte_offset[1]==1'b0) begin
              read_data_o = {{16{read_word[15]}}, read_word[15:0]};
            end else begin
              read_data_o = {{16{read_word[31]}}, read_word[31:16]};
            end
          end
          3'b010: begin // LW
            read_data_o = read_word;
          end
          3'b100: begin // LBU
            case (byte_offset)
              2'b00: read_data_o = {24'b0, read_word[ 7: 0]};
              2'b01: read_data_o = {24'b0, read_word[15: 8]};
              2'b10: read_data_o = {24'b0, read_word[23:16]};
              2'b11: read_data_o = {24'b0, read_word[31:24]};
            endcase
          end
          3'b101: begin // LHU
            if (byte_offset[1]==1'b0) begin
              read_data_o = {16'b0, read_word[15: 0]};
            end else begin
              read_data_o = {16'b0, read_word[31:16]};
            end
          end
          default: read_data_o = 32'b0;
        endcase
      end
    end
endmodule
