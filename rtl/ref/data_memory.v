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
