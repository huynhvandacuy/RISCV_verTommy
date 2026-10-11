#!/usr/bin/env bash

set -euo pipefail

# Luôn chạy trong thư mục sim/, dù gọi script từ đâu.
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

tests=(
    "tb_core_smoke smoke"
    "tb_core_memtest memtest"
    "tb_core_ctrltest ctrltest"
    "tb_core_alutest alutest"
)

# Makefile compile toàn bộ file trong compile.f, chỉ cần build một lần.
make build tb_core_smoke smoke

for entry in "${tests[@]}"; do
    read -r tb name <<< "$entry"

    printf '\nRunning %s\n' "$tb"
    make run "$tb" "$name"
    logfile="../log/$name/simulation.log"

    # Ngoài exit code, phải có dòng PASS tổng kết của đúng test.
    if ! grep -Fq "PASS: $tb," "$logfile"; then
        printf 'FAIL: thiếu dòng PASS của %s\n' "$tb" >&2
        exit 1
    fi
done

printf '\nPASS: toàn bộ 4 test RV32I\n'