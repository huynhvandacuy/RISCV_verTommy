#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RTL_DIR="$SCRIPT_DIR/../rtl"
TB_DIR="$SCRIPT_DIR/../tb"

find "$RTL_DIR" -maxdepth 1 -type f \( -name "*.v" -o -name "*.sv" \) \
    | sort > "$SCRIPT_DIR/rtl.f"

find "$TB_DIR" -maxdepth 1 -type f \( -name "*.v" -o -name "*.sv" \) \
    | sort > "$SCRIPT_DIR/tb.f"

echo "Generated rtl.f"
echo "Generated tb.f"