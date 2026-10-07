module instr_mem#(
    parameter IMEM_WORDS = 4096,          // 16KB, 4096 words (1 word = 4 byte)
    parameter IMEM_BASE  = 32'h8000_0000, // Base address
    parameter IMEM_HEX_FILE   = "../test-cache/rv32ui-p-add"
  )(
    input  [31:0]  addr_i,
    output [31:0]  instr_o
  );
    reg [31:0] mem [0:IMEM_WORDS-1];
  
    initial begin
      $readmemh(IMEM_HEX_FILE, mem);
    end
  
    wire [31:0] addr_offset = addr_i - IMEM_BASE;
    wire [31:0] word_index = addr_offset[31:2];  // word index
    wire        in_range = (addr_i >= IMEM_BASE) && (word_index < IMEM_WORDS);
  
    assign instr_o = in_range ? mem[word_index[$clog2(IMEM_WORDS)-1:0]] : 32'h0000_0013;
  endmodule