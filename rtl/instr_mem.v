module i_mem#(
    parameter IMEM_WORDS = 4096,          // 16KB, 4096 words (1 word = 4 byte)
    parameter IMEM_BASE  = 32'h8000_0000, // Base address
    parameter IMEM_HEX   = "../test-cache/rv32ui-p-add"
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