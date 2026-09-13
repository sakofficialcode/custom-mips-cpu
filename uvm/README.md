# UVM Testbench (Vivado xsim)

A UVM flow for `proc/processor.v`, running in parallel with the Icarus autotester and
independent of it. The infrastructure is here. **Everything under `tb/` is yours to write.**

The flow expects `proc/` and `test_files/` next to `uvm/`. In this repo, `proc` is a symlink to
`main/proc`. The folder is otherwise self-contained, so you can copy `uvm/` anywhere as long as
those two directories sit beside it, or you point `RTL_DIR=` / `TEST_FILES=` at them.

- [docs/dut_spec.md](docs/dut_spec.md) — the processor's exact behavior at its ports: clock edges,
  ISA semantics, exception codes, multdiv latency, memory quirks. Read the Clocking section before
  writing an interface.

## Quick start

```sh
cd uvm
make smoke        # verify the toolchain: UVM, solver, coverage, failure detection (~40 s)
make rtl          # verify the RTL compiles and elaborates under xsim
```

Then write your first files under `tb/`, list them in [tb.f](tb.f), and run:

```sh
make sim TEST=my_first_test
```

`tb/` doesn't exist yet. Create whatever layout you like under it; the Makefile finds `.sv`/`.svh`
files there for rebuild tracking and puts every subdirectory on the `` `include `` path. The top
module must be `tb_top`, or pass `TOP=`.

## Commands

| Command | Does |
|---|---|
| `make sim TEST=t` | compile if needed, elaborate, run, print PASS/FAIL |
| `  SEED=42` / `SEED=random` | solver seed. `random` picks one and puts it in the log name so the run is reproducible |
| `  VERBOSITY=UVM_HIGH` | UVM verbosity (default `UVM_MEDIUM`) |
| `  PLUSARGS="+PROG=alu_bypass +N=5"` | extra plusargs for `$value$plusargs` |
| `  WAVES=1` | record all HDL signals to `build/waves/<test>_<seed>.wdb` |
| `make regress TESTS="a b" SEEDS="1 2 3"` | elaborate once, run every combination, summary + nonzero exit on any failure |
| `make cov` | merge every coverage database from past runs into text + HTML reports |
| `make view TEST=t SEED=n` | open a `WAVES=1` run in the xsim GUI (untested under WSL) |
| `make elab` / `make clean` | |

Logs go to `build/logs/<test>_<seed>.log`. Everything under `build/` is disposable and gitignored.

Every test also receives `+MEM_DIR=`, `+VERIF_DIR=` and `+ASM_DIR=`: absolute paths to
`test_files/` subdirectories, each ending in `/`. Use them instead of relative paths; the simulator
runs inside `build/`.

## How a run passes

xsim's exit code is useless, so `make` decides with [scripts/check_log.sh](scripts/check_log.sh).
A run passes only if it reaches the UVM report summary with `UVM_ERROR : 0`, `UVM_FATAL : 0`, and
no simulator `Error:`/`Fatal:` lines. The last condition covers SVA and `$error` failures, which
UVM doesn't count. Consequences:

- Ending a test by calling `$finish` yourself is a **failure** (no summary). End tests by dropping
  objections.
- An assertion failure fails the test even when the scoreboard is happy.

## Working on the RTL in parallel

- **New RTL files need no testbench change.** `build/rtl.f` is regenerated from `RTL_DIR` on
  every run (skipping `*_tb.v` and `Wrapper*.v`), and the RTL recompiles only when files change.
- **Duplicate module files.** The submodules carry their own copies of `alu`, `mux_*`, `dffe_ref`,
  etc. Identical copies are resolved automatically. Copies that *differ* stop the build until
  [rtl_overrides.txt](rtl_overrides.txt) names one. Right now `register.v` has differing copies,
  and only `multdiv/register.v` has the `WIDTH` parameter the processor needs. Every build
  prints a note while an override is choosing between differing copies.
- **When a test fails, check whether the TB or the RTL is at fault** by rerunning against a
  known-good design:
  ```sh
  git worktree add ../proc-golden 7e1fccb        # from the repo root, once
  make sim TEST=t SEED=n RTL_DIR=../../proc-golden/main/proc
  ```
  `RTL_DIR` is relative to `uvm/`. Switching it recompiles only the RTL. The worktree has no
  `proc` symlink (it isn't committed), hence `main/proc`.
- Keep internal probes (hierarchical references into `dut.*`) in one file. Your timing rework
  renames exactly those signals.

## xsim gotchas

Items 1–6 were reproduced on this install (Vivado 2024.2) while setting up the flow. Items 7–8 are
general knowledge and weren't tested here.

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
6. `processor.v` uses wires before declaring them, which strict Verilog rejects. The RTL compiles
   with `--relax`, and only the RTL does; your SystemVerilog compiles strict. If you move those
   declarations up during your RTL rework, `--relax` can be dropped.
7. **UVM class members can't be recorded in waveforms**, only module/interface signals. To see
   transaction data in the waveform, put it on an interface.
8. **A `uvm_config_db` get with a mismatched type parameter just returns 0.** That's standard UVM,
   not xsim-specific, but it's the most common silent failure. Always check the return value and
   `` `uvm_fatal `` when it's 0.

## Layout

```
uvm/
├── Makefile
├── tb.f                   your source list (compile order matters)
├── rtl_overrides.txt      which copy wins for differing duplicate RTL files
├── docs/dut_spec.md
├── scripts/               gen_rtl_f.py, check_log.sh, waves.tcl
├── smoke/smoke_top.sv     toolchain self-test only, not a pattern to copy
└── tb/                    yours
```
