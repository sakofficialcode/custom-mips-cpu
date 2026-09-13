# Vivado xsim flow for the processor UVM testbench. Usage and the xsim quirks this file works
# around are in README.md.
#
#   make smoke                                  verify the toolchain itself
#   make rtl                                    compile + elaborate the RTL alone
#   make sim TEST=t [SEED=n|random] [VERBOSITY=UVM_HIGH] [PLUSARGS="+A=1 +B"] [WAVES=1]
#   make regress TESTS="t1 t2" [SEEDS="1 2 3"]
#   make cov                                    report over every coverage database so far
#   make view TEST=t SEED=n                     open a WAVES=1 run in the xsim GUI
#   make clean
#
# RTL_DIR and TEST_FILES are relative to this directory. RTL_DIR can point at any processor
# directory, e.g. a known-good worktree:
#   make sim TEST=t RTL_DIR=../../proc-golden/main/proc

RTL_DIR    ?= ../proc
TEST_FILES ?= ../test_files
TB_F      ?= tb.f
TB_DIR    ?= tb
TOP       ?= tb_top
TEST      ?=
SEED      ?= 1
VERBOSITY ?= UVM_MEDIUM
PLUSARGS  ?=
WAVES     ?= 0
TESTS     ?= $(TEST)
SEEDS     ?= 1 2 3 4 5

ifeq ($(SEED),random)
override SEED := $(shell od -An -N4 -tu4 /dev/urandom | tr -d ' ')
endif

BUILD     := $(CURDIR)/build
SCRIPTS   := $(CURDIR)/scripts
RTL_ABS   := $(abspath $(RTL_DIR))
TESTS_ABS := $(abspath $(TEST_FILES))
SNAP      := $(TOP)_snap

# RAM.v and ROM.v carry `timescale; processor.v, regfile.v and the precompiled UVM package do
# not, and xsim refuses to elaborate that mix. Force 1ns/1ps everywhere (matches Wrapper_tb.v).
TIMESCALE := --timescale 1ns/1ps --override_timeunit --override_timeprecision

# -H: RTL_DIR is normally a symlink (../proc -> main/proc), and plain find doesn't descend into
# a symlinked starting directory - it would silently track nothing and never recompile.
RTL_SRCS := $(shell find -H $(RTL_ABS) -name '*.v' 2>/dev/null)
TB_SRCS  := $(shell find -H $(abspath $(TB_DIR)) \( -name '*.sv' -o -name '*.svh' \) 2>/dev/null)
INCDIRS  := $(shell find -H $(abspath $(TB_DIR)) -type d 2>/dev/null)

# tb.f entries are relative to this directory but the tools run inside build/.
TB_ABS_CMD = awk -v base=$(CURDIR) '{ sub(/[[:space:]]*\/\/.*$$/, ""); gsub(/^[[:space:]]+|[[:space:]]+$$/, "") } \
                 NF { print ($$0 ~ /^\// ? $$0 : base "/" $$0) }' $(TB_F)
TB_LISTED := $(shell $(TB_ABS_CMD) 2>/dev/null)

# Absolute paths every test can read with $value$plusargs, so no TB code depends on the
# simulator's working directory. Each ends in '/'.
REPO_ARGS := --testplusarg MEM_DIR=$(TESTS_ABS)/mem_files/ \
             --testplusarg VERIF_DIR=$(TESTS_ABS)/verification_files/ \
             --testplusarg ASM_DIR=$(TESTS_ABS)/assembly_files/
USER_ARGS := $(foreach p,$(PLUSARGS),--testplusarg $(patsubst +%,%,$(p)))

LOG := $(BUILD)/logs/$(TEST)_$(SEED).log
WDB := $(BUILD)/waves/$(TEST)_$(SEED).wdb
ifeq ($(WAVES),1)
RUN_MODE := --wdb $(WDB) -t $(SCRIPTS)/waves.tcl
else
RUN_MODE := -R
endif

# Echo a tool command and run it with output going only to its log; on failure print the
# errors and the log path.
quiet = echo '$(1)' && $(1) > /dev/null 2>&1 || { grep -E '^(ERROR|CRITICAL)' $(2) || tail -20 $(2); echo "full log: $(BUILD)/$(2)"; exit 1; }

.PHONY: smoke rtl elab sim regress cov view clean need-test FORCE

$(BUILD) $(BUILD)/logs $(BUILD)/waves:
	@mkdir -p $@

# ---- RTL ------------------------------------------------------------------------------------
# Both files are regenerated on every run but only rewritten when their contents change, so a
# recompile happens exactly when RTL files appear/disappear or RTL_DIR changes.
$(BUILD)/rtl.f: FORCE | $(BUILD)
	@python3 $(SCRIPTS)/gen_rtl_f.py $(RTL_ABS) rtl_overrides.txt $@.tmp
	@cmp -s $@.tmp $@ && rm -f $@.tmp || mv $@.tmp $@

$(BUILD)/rtl_dir.txt: FORCE | $(BUILD)
	@echo '$(RTL_ABS)' | cmp -s - $@ || echo '$(RTL_ABS)' > $@

# --relax only here: processor.v uses wires before declaring them, which strict Verilog rejects.
$(BUILD)/.rtl.stamp: $(BUILD)/rtl.f $(BUILD)/rtl_dir.txt $(RTL_SRCS)
	@cd $(BUILD) && rm -rf xsim.dir/rtl && $(call quiet,xvlog --relax --work rtl -f rtl.f --log xvlog_rtl.log,xvlog_rtl.log)
	@touch $@

rtl: $(BUILD)/.rtl.stamp
	@cd $(BUILD) && $(call quiet,xelab -L rtl $(TIMESCALE) -s rtl_snap rtl.processor rtl.regfile --log xelab_rtl.log,xelab_rtl.log)
	@echo "rtl: processor and regfile elaborate cleanly"

# ---- Testbench ------------------------------------------------------------------------------
# Same only-rewrite-on-change scheme as rtl.f, so switching TB_F also triggers a recompile.
$(BUILD)/tb.abs.f: FORCE | $(BUILD)
	@$(TB_ABS_CMD) > $@.tmp
	@cmp -s $@.tmp $@ && rm -f $@.tmp || mv $@.tmp $@

$(BUILD)/.tb.stamp: $(BUILD)/tb.abs.f $(TB_SRCS) $(TB_LISTED)
	@test -s $< || { echo "$(TB_F) lists no sources yet: add your .sv files to it (see README.md)"; exit 1; }
	@cd $(BUILD) && rm -rf xsim.dir/work && $(call quiet,xvlog -sv -L uvm $(addprefix -i ,$(INCDIRS)) -f tb.abs.f --log xvlog_tb.log,xvlog_tb.log)
	@touch $@

$(BUILD)/.elab.$(TOP).stamp: $(BUILD)/.rtl.stamp $(BUILD)/.tb.stamp
	@cd $(BUILD) && $(call quiet,xelab -L rtl -L uvm --debug typical $(TIMESCALE) -s $(SNAP) work.$(TOP) --log xelab_$(TOP).log,xelab_$(TOP).log)
	@touch $@

elab: $(BUILD)/.elab.$(TOP).stamp

# ---- Running --------------------------------------------------------------------------------
need-test:
	@test -n "$(TEST)" || { echo "TEST is required, e.g. make sim TEST=my_test"; exit 1; }

sim: need-test $(BUILD)/.elab.$(TOP).stamp | $(BUILD)/logs $(BUILD)/waves
	@echo "xsim $(SNAP) test=$(TEST) seed=$(SEED) log=$(LOG)"
	@cd $(BUILD) && xsim $(SNAP) $(RUN_MODE) --sv_seed $(SEED) \
	    --testplusarg UVM_TESTNAME=$(TEST) --testplusarg UVM_VERBOSITY=$(VERBOSITY) $(REPO_ARGS) $(USER_ARGS) \
	    --cov_db_dir cov --cov_db_name $(TEST)_$(SEED) --log $(LOG) $(if $(QUIET),> /dev/null 2>&1)
	@$(SCRIPTS)/check_log.sh $(LOG) "$(TEST) seed=$(SEED)"

# Elaborates once, then runs every TESTS x SEEDS combination. A run that produces no verdict
# at all (e.g. xsim failed to launch) counts as a failure.
regress: $(BUILD)/.elab.$(TOP).stamp | $(BUILD)/logs
	@test -n "$(TESTS)" || { echo 'TESTS is required, e.g. make regress TESTS="t1 t2" SEEDS="1 2 3"'; exit 1; }
	@summary=$(BUILD)/logs/regress_summary.txt; : > $$summary; \
	for t in $(TESTS); do for s in $(SEEDS); do \
	    $(MAKE) --no-print-directory sim QUIET=1 TEST=$$t SEED=$$s 2>&1 | grep -E '^(PASS|FAIL) ' | tee -a $$summary; \
	done; done; \
	total=$$(( $(words $(TESTS)) * $(words $(SEEDS)) )); pass=$$(grep -c '^PASS' $$summary); \
	echo "regress: $$pass/$$total passed  ($$summary)"; test $$pass -eq $$total

cov:
	@test -d $(BUILD)/cov/xsim.covdb || { echo "no coverage databases yet: run some tests first"; exit 1; }
	@cd $(BUILD) && rm -rf cov_report && $(call quiet,xcrg -cov_db_dir cov -report_format all -report_dir cov_report -log xcrg.log,xcrg.log)
	@echo "text: $(BUILD)/cov_report/functionalCoverageReport/xcrg_func_cov_report.txt"
	@echo "html: $(BUILD)/cov_report/functionalCoverageReport/dashboard.html"

view: need-test
	@test -f $(WDB) || { echo "no waveform at $(WDB): rerun with WAVES=1"; exit 1; }
	cd $(BUILD) && xsim --gui $(WDB)

# ---- Toolchain self-test --------------------------------------------------------------------
# Kept in its own library so it never collides with the real testbench.
smoke_run = cd $(BUILD) && xsim smoke_snap -R --sv_seed 1 --testplusarg UVM_TESTNAME=$(1) \
            --cov_db_dir smoke_cov --cov_db_name $(1) --log logs/smoke_$(1).log > /dev/null 2>&1

smoke: | $(BUILD)/logs
	@cd $(BUILD) && rm -rf xsim.dir/smoke smoke_cov smoke_cov_report && \
	    $(call quiet,xvlog -sv -L uvm --work smoke $(CURDIR)/smoke/smoke_top.sv --log xvlog_smoke.log,xvlog_smoke.log)
	@cd $(BUILD) && $(call quiet,xelab -L uvm $(TIMESCALE) -s smoke_snap smoke.smoke_top --log xelab_smoke.log,xelab_smoke.log)
	@$(call smoke_run,smoke_test); \
	    $(SCRIPTS)/check_log.sh $(BUILD)/logs/smoke_smoke_test.log "UVM runs, constraints solve, covergroup samples"
	@for t in smoke_fail_test no_such_test; do \
	    $(call smoke_run,$$t); \
	    if $(SCRIPTS)/check_log.sh $(BUILD)/logs/smoke_$$t.log x > /dev/null; then \
	        echo "FAIL check_log.sh passed $$t, which must fail"; exit 1; \
	    else echo "PASS check_log.sh fails $$t"; fi; \
	done
	@cd $(BUILD) && xcrg -cov_db_dir smoke_cov -cov_db_name smoke_test -report_format text -report_dir smoke_cov_report -nolog > /dev/null 2>&1; \
	    grep -qE 'Coverage Score +:, 100' smoke_cov_report/functionalCoverageReport/xcrg_func_cov_report.txt \
	    && echo "PASS xcrg reports functional coverage" || { echo "FAIL xcrg report missing or not 100%"; exit 1; }
	@echo "smoke: toolchain OK"

clean:
	rm -rf $(BUILD)
