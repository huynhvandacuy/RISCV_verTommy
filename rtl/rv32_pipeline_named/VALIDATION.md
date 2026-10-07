# Validation

- All 16 active modules compiled with Icarus Verilog in SystemVerilog mode.
- Strict compile with `default_nettype none`: passed, no implicit nets.
- Updated `tb_alu`: 12 directed checks passed, with a watchdog.
- Original uploaded version and renamed version simulated side by side for
  300 cycles with identical instruction memory. PC, pipeline signals, WB,
  Mul/Div state/results, all 32 integer registers and 64 data memory words
  matched on each sampled cycle.
- Standalone modules were also checked for reversible identifier changes
  before redundant WB aliases and unused top declarations were removed.
- `rtl/ref/` files were copied unchanged and excluded from the active file list.

This demonstrates sampled behavior preservation, not formal equivalence or
full RISC-V ISA compliance. It preserves known input-version defects. ModelSim
was not available in this environment.
