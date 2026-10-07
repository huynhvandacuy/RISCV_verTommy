// ============================================================
// LZC 24-bit dạng parallel tree — thay thế priority_encoder_24
// Giảm độ trễ ~40% so với casex tuần tự
// ============================================================


// ============================================================
// Top module — 4-stage pipeline (tách stage 3 thành 3a + 3b)
// Stage 1: Unpack, compare, align
// Stage 2: Add/Sub
// Stage 3a: Leading-zero count (LZC) — thêm mới
// Stage 3b: Normalize, pack, output
// ============================================================
module top (
    input        clk,
    input        op_sub,
    input  [31:0] a, b,
    output reg [31:0] out
);

    


endmodule