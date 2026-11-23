# UVM Testbench (Synopsys VCS / Vivado xsim)

A UVM testbench for `proc/processor.v`. Results and the bugs it found are in the
[top-level README](../README.md#verification).

The flow expects `proc/` and `test_files/` next to `uvm/`, or point `RTL_DIR=` / `TEST_FILES=` at
them. `test_files/` (the 41 directed course programs) isn't in the repo; the random tests don't
need it.

- [docs/dut_spec.md](docs/dut_spec.md): the processor's exact behavior at its ports: clock edges,
  ISA semantics, exception codes, multdiv latency, memory quirks.

## Quick start

```sh
cd uvm
make sim TEST=rand_test SEED=1                              # one random program
make regress TESTS=rand_test SEEDS="$(seq -s ' ' 1 200)"    # many seeds
make cov                                                    # merged coverage report
```

`SIM` picks the simulator: `vcs` when `vcs` is on the PATH, `xsim` otherwise. Override with
`SIM=vcs` or `SIM=xsim`. Directed programs run with
`make sim TEST=proc_base_test PLUSARGS=+PROG=<name>`.

## Testbench

| File (`tb/pkg/`) | Role |
|---|---|
| `insn_item`, `prog_gen` | Instruction item with constraints and encoding; the program generator (prologue, random body with hazard and corner-value bias, `setx`/`bex` and memory-hazard streams, halt) |
| `rand_test` | Generates a program in `build_phase` and hands it to the env through `uvm_config_db` |
| `imem_*`, `dmem_*` | Responder agents that replace ROM and RAM |
| `wb_monitor`, `dmem_monitor` | Register-file write and store monitors |
| `proc_iss` | Instruction-set simulator; predicts every register write and store, and logs each executed instruction as an `exec_item` |
| `proc_scoreboard` | Compares DUT writes to the ISS in order; replays `exec_item`s to coverage |
| `proc_cov` | `uvm_subscriber` with the functional covergroup |

The top module is `tb_top`, or pass `TOP=`. The Makefile finds `.sv`/`.svh` files under `tb/`
for rebuild tracking and puts every subdirectory on the `` `include `` path.

## Commands

| Command | Does |
|---|---|
| `make sim TEST=t` | compile if needed, elaborate, run, print PASS/FAIL |
| `  SEED=42` / `SEED=random` | solver seed. `random` picks one and puts it in the log name so the run is reproducible |
| `  VERBOSITY=UVM_HIGH` | UVM verbosity (default `UVM_MEDIUM`) |
| `  PLUSARGS="+PROG=alu_bypass +N=5"` | extra plusargs for `$value$plusargs` |
| `  WAVES=1` | xsim only: record all HDL signals to `build/waves/<test>_<seed>.wdb` |
| `  SIM=vcs` / `SIM=xsim` | choose the simulator (default: `vcs` if on PATH) |
| `make regress TESTS="a b" SEEDS="1 2 3"` | elaborate once, run every combination, summary + nonzero exit on any failure |
| `make cov` | merge coverage from past runs into text + HTML reports (`urg` on VCS, `xcrg` on xsim) |
| `make cov-clean` | drop collected coverage but keep the build (on VCS, `simv.vdb` also holds the design database) |
| `make view TEST=t SEED=n` | xsim only: open a `WAVES=1` run in the xsim GUI (untested under WSL) |
| `make smoke` / `make rtl` | xsim only: toolchain self-test / RTL-only elaboration |
| `make elab` / `make clean` | |

On VCS, code coverage (line, condition, toggle, branch, FSM) is collected on `tb_top.CPU` and
`tb_top.RegFile` only, not the testbench.

Logs go to `build/logs/<test>_<seed>.log`. Everything under `build/` is disposable and gitignored.

Every test also receives `+MEM_DIR=`, `+VERIF_DIR=` and `+ASM_DIR=`: absolute paths to
`test_files/` subdirectories, each ending in `/`. Use them instead of relative paths; the simulator
runs inside `build/`.

## How a run passes

Simulator exit codes are unreliable (xsim exits 0 even on `UVM_FATAL`), so `make` decides with
[scripts/check_log.sh](scripts/check_log.sh). A run passes only if it reaches the UVM report
summary with `UVM_ERROR : 0`, `UVM_FATAL : 0`, and no simulator error lines (xsim's
`ERROR:`/`Fatal:`, VCS's `Error-[...]`). The last condition covers SVA and `$error` failures, which
UVM doesn't count. Consequences:

- Ending a test by calling `$finish` yourself is a **failure** (no summary). End tests by dropping
  objections.
- An assertion failure fails the test even when the scoreboard is happy.

## Working on the RTL in parallel

- **New RTL files need no testbench change.** `build/rtl.f` is regenerated from `RTL_DIR` on
  every run (skipping `*_tb.v` and `Wrapper*.v`), and the RTL recompiles only when files change.
- **Duplicate module files.** The submodules carry their own copies of `alu`, `mux_*`, `dffe_ref`,
  etc. Identical copies are resolved automatically. Copies that *differ* stop the build until
  [rtl_overrides.txt](rtl_overrides.txt) names one. Every build prints a note while an override
  is choosing between differing copies.
- **When a test fails, check whether the TB or the RTL is at fault** by rerunning against another
  version of the design:
  ```sh
  git worktree add ../proc-golden <commit>        # from the repo root, once
  make sim TEST=t SEED=n RTL_DIR=../../proc-golden/proc
  ```
  `RTL_DIR` is relative to `uvm/`. Switching it recompiles only the RTL.
- Keep internal probes (hierarchical references into `dut.*`) in one file. Your timing rework
  renames exactly those signals.

## xsim gotchas

Items 1–6 and 9 were reproduced on this install (Vivado 2024.2). Items 7–8 are general
knowledge and weren't tested here.

1. **No `` `timescale `` in your files.** `RAM.v`/`ROM.v` have one, while `processor.v`, the regfile
   and the precompiled UVM package don't. xsim refuses that mix ("has a timescale but at least one
   module in design doesn't"). The Makefile forces 1ns/1ps on everything at elaboration.
2. **Set `type_option.merge_instances = 1` in every covergroup.** With the default of 0, `make cov`
   *averages* instances instead of taking the union of their bins. Measured: two runs covering
   complementary bins through differently named instances merge to 50% with the default and 100%
   with the option set.
3. **Don't call `set_inst_name()` on a covergroup.** It crashes the xsim kernel (`FATAL_ERROR:
   Vivado Simulator kernel has discovered an exceptional condition`).
4. **`randc` wider than 8 bits silently becomes `rand`.** xsim warns once at elaboration (the UVM
   package itself triggers the same warning). Keep `randc` fields ≤ 8 bits, or you lose the
   cyclic guarantee without noticing.
5. `--sv_seed random` never prints the seed it chose; use `SEED=random` through `make`.
6. `processor.v` used to use wires before declaring them, which strict Verilog (and VCS) rejects.
   The declarations have been moved up, so the RTL compiles strict; the Makefile still passes
   `--relax` to the xsim RTL compile and it can be dropped.
7. **UVM class members can't be recorded in waveforms**, only module/interface signals. To see
   transaction data in the waveform, put it on an interface.
8. **A `uvm_config_db` get with a mismatched type parameter just returns 0.** That's standard UVM,
   not xsim-specific, but it's the most common silent failure. Always check the return value and
   `` `uvm_fatal `` when it's 0.
9. **The constraint solver mishandles some constraints.** Measured on this install: `solve before`
   and `dist` on an enum field were ignored under paired implications (write `if/else`); a `dist`
   on a wide field inside `randomize() with {}` was ignored; two complementary implications on
   the same field (`a -> x == 0; !a -> x != 0;`) failed or picked the wrong case; and about 1 in
   5000 `randomize()` calls failed on satisfiable constraints that index a queue. Decide such
   cases in procedural code and pass a single value or bit into `with {}`. The generator is
   written this way, so it is portable to VCS.

## Layout

```
uvm/
├── Makefile
├── tb.f                   your source list (compile order matters)
├── rtl_overrides.txt      which copy wins for differing duplicate RTL files
├── docs/dut_spec.md
├── scripts/               gen_rtl_f.py, check_log.sh, waves.tcl
├── smoke/smoke_top.sv     xsim toolchain self-test only, not a pattern to copy
└── tb/
    ├── tb_top.sv
    ├── if/                imem, dmem, regfile interfaces
    └── pkg/               proc_pkg and the classes listed under Testbench
```
