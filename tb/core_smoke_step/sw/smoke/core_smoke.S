# Documentation for the pre-encoded word-per-line core_smoke.hex.
# This step does not require a compiler or linker.
# Reset PC: 0x80000000. Every instruction is 4 bytes (RV32I).

    addi x1, x0, 6
    nop
    nop
    addi x3, x1, 0       # WB -> ID: x3 = 6
    nop
    nop
    nop
    addi x4, x0, 6
    add  x5, x4, x4      # MEM -> EX: x5 = 12
    add  x6, x4, x0      # WB -> EX: x6 = 6
    addi x7, x0, 1
    addi x7, x7, 2       # x7 = 3
    add  x8, x7, x7      # newer MEM value wins over WB: x8 = 6
    addi x9, x0, 1       # end marker checked by the testbench
    # Remaining instruction-memory words contain NOPs.
