# RV32IMF / OoO project -- ModelSim / Questa simulation
# Put this file in sim/. Run: make -C sim ... (from the project root).
# This Makefile compiles HDL only; software/ISA tests are added later.

SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
.NOTPARALLEL:

# Optional shorthand: make ACTION TB_NAME TESTNAME
# Example: make run tb_alu alu
# Ordinary variable assignments and make build run still work.
ACTION_GOALS := all all_wave build run gui wave clean help
MAIN_GOAL := $(firstword $(MAKECMDGOALS))
SECOND_GOAL := $(word 2,$(MAKECMDGOALS))
POSITIONAL_ARGS :=
ifneq ($(filter all all_wave build run gui wave,$(MAIN_GOAL)),)
ifneq ($(SECOND_GOAL),)
ifeq ($(filter $(ACTION_GOALS),$(SECOND_GOAL)),)
ifneq ($(word 4,$(MAKECMDGOALS)),)
$(error Use: make ACTION TB_NAME [TESTNAME])
endif
POSITIONAL_ARGS := $(wordlist 2,3,$(MAKECMDGOALS))
TB_NAME ?= $(word 1,$(POSITIONAL_ARGS))
ifneq ($(word 2,$(POSITIONAL_ARGS)),)
ifneq ($(filter $(ACTION_GOALS),$(word 2,$(POSITIONAL_ARGS))),)
$(error TESTNAME must not equal an action name)
endif
TESTNAME ?= $(word 2,$(POSITIONAL_ARGS))
endif
endif
endif
endif

TB_NAME   ?= test_bench
TESTNAME  ?= $(TB_NAME)
FILELIST  ?= compile.f
RADIX     ?= hexadecimal
PLUSARGS  ?=

VLIB      ?= vlib
VMAP      ?= vmap
VLOG      ?= vlog
VSIM      ?= vsim
VLOG_FLAGS ?= -sv
VSIM_FLAGS ?= -voptargs=+acc

OUT_DIR := out/$(TESTNAME)
WAVEFILE := $(OUT_DIR)/wave.wlf

.PHONY: all all_wave build run gui wave clean help

# make normally treats these arguments as targets; consume them as no-ops.
ifneq ($(POSITIONAL_ARGS),)
.PHONY: $(sort $(POSITIONAL_ARGS))
$(sort $(POSITIONAL_ARGS)):
	@:
endif

all: build run

# build and run are independent. all runs them in order (.NOTPARALLEL).
build:
	@test -f "$(FILELIST)" || { echo "Missing file list: $(FILELIST)"; exit 1; }
	@mkdir -p "$(OUT_DIR)"
	@if [ ! -d work ]; then $(VLIB) work; fi
	@if [ ! -f modelsim.ini ]; then $(VMAP) -c; fi
	$(VMAP) work work
	$(VLOG) $(VLOG_FLAGS) -work work -f "$(FILELIST)" 2>&1 | tee "$(OUT_DIR)/compile.log"

# Testbench convention:
#   success -> $display("PASS"); $finish;
#   failure/timeout -> $fatal(1, "reason");
# Printing FAIL alone does NOT make the simulator or make return an error.
# -onfinish exit exits normally on $finish; errors/breaks return nonzero.
# If run -all returns without $finish, treat the run as incomplete.
run:
	@test -d work || { echo "No work library: run make build first."; exit 1; }
	@mkdir -p "$(OUT_DIR)"
	$(VSIM) -c -onfinish exit $(VSIM_FLAGS) \
		-l "$(OUT_DIR)/simulation.log" -wlf "$(WAVEFILE)" \
		work.$(TB_NAME) $(PLUSARGS) \
		-do 'onerror {quit -f -code 1}; onbreak {quit -f -code 1}; log -r /*; run -all; puts "ERROR: test ended without finish"; quit -f -code 1'

# Live debug: load the compiled design without rebuilding.
gui:
	@test -d work || { echo "No work library: run make build first."; exit 1; }
	@mkdir -p "$(OUT_DIR)"
	$(VSIM) -gui -onfinish stop $(VSIM_FLAGS) \
		-l "$(OUT_DIR)/gui.log" -wlf "$(OUT_DIR)/gui.wlf" \
		work.$(TB_NAME) $(PLUSARGS) \
		-do "log -r /*; add wave -r /$(TB_NAME)/*; radix $(RADIX)"

# Read the saved waveform without rebuilding or running again.
wave:
	@test -f "$(WAVEFILE)" || { echo "No waveform: run this test first."; exit 1; }
	$(VSIM) -i -view "$(WAVEFILE)" \
		-do "view wave; add wave -r /*; radix $(RADIX); wave zoom full"
		
all_wave: all
	$(MAKE) wave TB_NAME="$(TB_NAME)" TESTNAME="$(TESTNAME)"

# Keep source files, file lists, and modelsim.ini settings.
clean:
	rm -rf -- work out vsim.dbg
	rm -f -- transcript

help:
	@echo 'Run these commands inside sim/, or use make -C sim from the root:'
	@echo '  make                  Compile HDL and run the selected testbench'
	@echo '  make build            Compile HDL only'
	@echo '  make run              Run compiled HDL without rebuilding'
	@echo '  make gui              Open compiled HDL for live debug (no rebuild)'
	@echo '  make wave             Open saved waveform interactively (no rebuild)'
	@echo '  make all_wave         Compile, run, then open the saved waveform'
	@echo '  make clean            Remove generated libraries and results'
	@echo '  make build TB_NAME=tb_alu TESTNAME=alu'
	@echo '  make run TB_NAME=tb_alu TESTNAME=alu'
	@echo 'Shorthand (one action per command):'
	@echo '  make build tb_alu alu'
	@echo '  make run tb_alu alu'
	@echo '  make wave tb_alu alu'
	@echo '  make all_wave tb_alu alu'
	@echo '  make TB_NAME=tb_rob FILELIST=rob.f TESTNAME=rob'
	@echo '  make TB_NAME=tb_cpu PLUSARGS="+firmware=../sw/smoke.hex"'
	@echo 'Names/file lists in the examples must exist; the TB must read plusargs.'
