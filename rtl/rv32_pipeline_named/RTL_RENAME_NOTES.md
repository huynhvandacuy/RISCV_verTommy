# RTL pipeline: consistent names

This bundle is based on the uploaded rtl.tar(1).gz. It changes names only,
except for removing unused wires and collapsing direct WB aliases.
The active top module remains `top`, so existing Makefile defaults can still
select it. File extensions remain `.v`. All active module names match files.
The original `rtl/ref/` files are unchanged and excluded from `sim/rtl.f`.

## Apply

Back up the current project first. Copy this bundle's `rtl/` files into your
project's `rtl/`. Copy `sim/rtl.f`, `sim/alu.f` and `tb/tb_alu.v` into their
matching directories. Keep your Makefile, compile.f and other testbenches.
No simulator results or compiled library are included.

From your existing project's sim directory:

```bash
make build tb_alu alu FILELIST=alu.f
make run tb_alu alu
make wave tb_alu alu
```

If you regenerate file lists automatically, exclude `rtl/ref/`.
Any other testbench using old module ports or hierarchical paths must be
updated too. For example, old `dut.RF0.regs` becomes
`dut.u_regfile.regs_q`, and `dut.IMEM.mem` becomes `dut.u_instr_mem.mem`.
The instruction memory parameter is now `IMEM_HEX_FILE`.

## Naming

- Inputs `_i`, outputs `_o`, active-low reset `rst_ni`.
- Local sequential state `_q`; combinational `reg` variables do not get `_q`.
- `alu_class` is the 2-bit instruction class; `alu_op` is the 5-bit operation.
- Register indices use `rs1_addr`, `rs2_addr`, `rd_addr`; values use `*_data`.
- Top-level stage signals end in `_if`, `_id`, `_ex`, `_mem`, `_wb`.
- Instance names start with `u_`.
- Existing operation encodings, reset values and timing behavior are retained.

## Scope and known issues

This is a naming cleanup, not a completed RV32IMF implementation. The M-unit
integration and WB-to-ID same-cycle read issue remain from the input version.
The standalone Mul/Div unit still requires stable inputs during execution.
No F extension, new handshake, traps or bypass logic are added.
The negative J immediate fix already present in the input is retained.

## Validation

See VALIDATION.md for checks performed using Icarus; ModelSim is not installed
in the verification environment.
