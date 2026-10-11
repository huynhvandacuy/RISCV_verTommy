#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.."

src="reference/riscv-tests"
out="sw/riscv_tests/out"
prefix="${RISCV_PREFIX:-riscv64-unknown-elf-}"

mkdir -p "$out"

"${prefix}gcc" \
    -march=rv32i -mabi=ilp32 \
    -nostdlib -nostartfiles \
    -mno-relax \
    -I sw/riscv_tests/env \
    -I "$src/isa/macros/scalar" \
    -T sw/riscv_tests/link.ld \
    -Wl,--no-relax \
    "$src/isa/rv32ui/add.S" \
    -o "$out/rv32ui-add.elf"

"${prefix}objcopy" \
    -O binary -j .text \
    "$out/rv32ui-add.elf" \
    "$out/rv32ui-add.bin"

"${prefix}objdump" \
    -d -M no-aliases,numeric \
    "$out/rv32ui-add.elf" \
    > "$out/rv32ui-add.asm"

python3 - <<'PY'
from pathlib import Path

out = Path("sw/riscv_tests/out")
data = (out / "rv32ui-add.bin").read_bytes()
capacity = 4096

if not data or len(data) % 4:
    raise SystemExit("Invalid instruction image size")

words = [
    int.from_bytes(data[i:i+4], "little")
    for i in range(0, len(data), 4)
]

if len(words) > capacity:
    raise SystemExit("Image exceeds instruction memory capacity")

count = len(words)
words.extend([0x00000013] * (capacity - count))

(out / "rv32ui-add.hex").write_text(
    "".join(f"{word:08x}\n" for word in words)
)
print(f"Built rv32ui-add: {count} instruction words")
PY