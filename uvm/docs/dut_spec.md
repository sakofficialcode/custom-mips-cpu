# Processor DUT Spec for the UVM Testbench

Everything here was read from the RTL at commit `7e1fccb` ("Completed full CPU") unless marked
**simulated**. The port list and the architectural semantics shouldn't change when you rework the
processor for timing; internal signal names, stall timing and latency may. Anything the ISS models
is proven only once Phase E's 41-program validation passes.

Contents: [Ports](#ports) · [Clocking](#clocking-at-the-ports) · [Reset](#reset-and-power-up) ·
[Encoding](#instruction-encoding) · [Semantics](#architectural-semantics) ·
[Exceptions](#exceptions) · [Multdiv](#multdiv) · [Pipeline behavior](#pipeline-behavior) ·
[Memories](#memories) · [Regfile](#regfile) · [Programs](#program-and-expectation-files)

---

## Ports

`module processor` in [proc/processor.v](../../proc/processor.v). There is no regfile or
memory inside it; the testbench provides all three.

| Port | Dir | Width | Meaning |
|---|---|---|---|
| `clock` | in | 1 | |
| `reset` | in | 1 | active high, asynchronous |
| `address_imem` | out | 32 | PC of the instruction being fetched |
| `q_imem` | in | 32 | instruction word at that address |
| `address_dmem` | out | 32 | ALU result of the instruction in Memory (`$rs + N` for lw/sw) |
| `data` | out | 32 | value to store (sw) |
| `wren` | out | 1 | 1 exactly when the Memory-stage instruction is `sw` |
| `q_dmem` | in | 32 | data read from dmem |
| `ctrl_writeEnable` | out | 1 | regfile write enable (Writeback stage) |
| `ctrl_writeReg` | out | 5 | register to write |
| `data_writeReg` | out | 32 | value to write |
| `ctrl_readRegA` | out | 5 | register read on port A (Decode stage) |
| `ctrl_readRegB` | out | 5 | register read on port B |
| `data_readRegA` | in | 32 | |
| `data_readRegB` | in | 32 | |

---

## Clocking at the ports

Every pipeline register is `register` (posedge flops) clocked by **`~clock`**, so the pipeline
advances on the **falling edge**. The regfile, ROM, RAM and multdiv use the **rising edge**.

**Every output is a function of falling-edge registers only**: there is no combinational path from
any input to any output. So outputs change only just after a falling edge and are stable through
the following rising edge. The processor captures its inputs at the falling edge.

| Interface | Processor drives (after falling edge) | Consumer acts (rising edge) | Processor captures (next falling edge) |
|---|---|---|---|
| imem | `address_imem` | ROM registers `q_imem <= mem[addr]` | `q_imem` into the Fetch/Decode latch |
| dmem | `address_dmem`, `data`, `wren` | RAM writes, or registers `q_dmem` | `q_dmem` into the Memory/Writeback latch |
| regfile write | `ctrl_writeEnable`, `ctrl_writeReg`, `data_writeReg` | regfile commits | — |
| regfile read | `ctrl_readRegA/B` | (combinational read) | `data_readRegA/B` into the Decode/Execute latch |

What this means for your interfaces:

- **Monitors should sample at the rising edge**, the same edge the real consumer uses.
  `Wrapper_tb.v` samples register writes this way. That point is also the most robust to your
  timing rework, since it's the contract the memories rely on.
- **Responders get half a cycle.** An imem/dmem responder sees the address at the rising edge and
  its data must be stable before the next falling edge.
- **Regfile writes are visible to reads in the same cycle.** A value committed at the rising edge
  is on `data_readRegA/B` before the Decode latch captures at the falling edge. That's why there
  is no Writeback→Decode bypass in the RTL.

## Reset and power-up

- `reset` is an async clear into every pipeline register (`dffe_ref`: `always @(posedge clk or posedge clr)`).
- `dffe_ref` also has `initial q = 1'b0`, so in simulation every flop starts at 0 **even with
  no reset**. Don't treat "passes without reset" as evidence that reset works.
- **multdiv ignores `reset`.** Its counter clears only on a `ctrl_MULT`/`ctrl_DIV` pulse, and the
  busy flop clears on `data_resultRDY`. A reset in the middle of a multdiv doesn't abort it
  cleanly. Avoid mid-test reset until you've decided what the ISS should predict.
- The regfile clears on `ctrl_reset`; wire it to `reset` as the wrappers do.
- `Wrapper_tb.v` holds reset for only 1 ns at t=0, before any edge. That's fine for an async
  clear, but hold it across at least one full clock in your reset phase.

---

## Instruction encoding

Opcode table: [assembler-python-version/instructions.csv](../../assembler-python-version/instructions.csv).
Register aliases (`$sp`, `$ra`, …): `registers.csv` beside it.

| Type | [31:27] | [26:22] | [21:17] | [16:12] | [11:7] | [6:2] | [1:0] |
|---|---|---|---|---|---|---|---|
| R | `00000` | rd | rs | rt | shamt | ALUop | `00` |
| I | opcode | rd | rs | imm[16:0] ⟶ | | | |
| JI | opcode | target[26:0] ⟶ | | | | | |
| JII | opcode | rd | zero ⟶ | | | | |

| Opcode | Instr | Type | | ALUop | Instr |
|---|---|---|---|---|---|
| `00000` | R-type | R | | `00000` | add |
| `00001` | j | JI | | `00001` | sub |
| `00010` | bne | I | | `00010` | and |
| `00011` | jal | JI | | `00011` | or |
| `00100` | jr | JII | | `00100` | sll |
| `00101` | addi | I | | `00101` | sra |
| `00110` | blt | I | | `00110` | mul |
| `00111` | sw | I | | `00111` | div |
| `01000` | lw | I | | | |
| `10101` | setx | JI | | | |
| `10110` | bex | JI | | | |

The all-zeros word is `add $0, $0, $0`: the RTL's bubble/nop.

---

## Architectural semantics

This is what the ISS should model. `PC` is **word-addressed**: sequential execution is `PC + 1`.
`N` is `imm[16:0]` **sign-extended**. `T` is `target[26:0]` **zero-extended**. All values are 32-bit
two's complement.

| Instruction | Effect |
|---|---|
| `add $rd, $rs, $rt` | `$rd = $rs + $rt` — exception on signed overflow |
| `sub $rd, $rs, $rt` | `$rd = $rs - $rt` — exception on signed overflow |
| `and` / `or $rd, $rs, $rt` | bitwise; never an exception |
| `sll $rd, $rs, shamt` | `$rd = $rs << shamt` (rt field ignored) |
| `sra $rd, $rs, shamt` | `$rd = $rs >>> shamt` (arithmetic) |
| `mul $rd, $rs, $rt` | `$rd = $rs * $rt` (low 32 bits) — exception if the signed product doesn't fit in 32 bits |
| `div $rd, $rs, $rt` | `$rd = $rs / $rt`, signed, truncating toward zero — exception if `$rt == 0` |
| `addi $rd, $rs, N` | `$rd = $rs + N` — exception on signed overflow |
| `sw $rd, N($rs)` | `MEM[$rs + N] = $rd` |
| `lw $rd, N($rs)` | `$rd = MEM[$rs + N]` |
| `j T` | `PC = T` |
| `jal T` | `$r31 = PC + 1; PC = T` |
| `jr $rd` | `PC = $rd` |
| `bne $rd, $rs, N` | `if ($rd != $rs) PC = PC + 1 + N` |
| `blt $rd, $rs, N` | `if ($rd < $rs) PC = PC + 1 + N` — signed compare |
| `setx T` | `$r30 = T` |
| `bex T` | `if ($r30 != 0) PC = T` |

- **Operand order for branches is `$rd` then `$rs`.** `blt $1, $2, N` branches when `$1 < $2`.
  The ALU's `isLessThan` is `sign(A - B) XOR overflow`, which is a correct signed compare.
- **`$r0`** always reads 0 and ignores writes. `$r30` is `$rstatus`; `$r31` is `$ra`.
- **Branch offsets.** The assembler computes `N = label - line - 1` (masked to 17 bits), which
  matches the `PC + 1 + N` rule.
- **Not pinned here:** `INT_MIN / -1`. multdiv.v has no divide-overflow check (only divisor == 0),
  so there's no exception and the true quotient +2³¹ doesn't fit. Pin its value by simulation
  before deciding what the ISS predicts.

## Exceptions

An exception **replaces** the instruction's write: `$rd` is not written, and `$r30` gets the code.

| Cause | `$r30` |
|---|---|
| `add` overflow | 1 |
| `addi` overflow | 2 |
| `sub` overflow | 3 |
| `mul` overflow | 4 |
| `div` by zero | 5 |

In the RTL, Writeback drives `ctrl_writeReg = 30` and `data_writeReg = code`
([processor.v:179](../../proc/processor.v#L179), [:229-231](../../proc/processor.v#L229)).

---

## Multdiv

[proc/multdiv/multdiv.v](../../proc/multdiv/multdiv.v)

- **Latency:** `data_resultRDY` asserts when the internal counter reaches **17 for mul** and
  **33 for div**, counted from the one-cycle `ctrl_MULT`/`ctrl_DIV` pulse
  ([multdiv.v:95](../../proc/multdiv/multdiv.v#L95)).
- **Operand B is read live for the whole operation.** Operand A is registered at the start
  (`AReg`). `data_operandB` feeds the exception checks, the divide-by-zero test and the result
  sign directly on every cycle. (`BReg` exists but latches `data_operandA` and is never read.)
  The processor therefore has to hold its operand-B bypass value stable across the whole stall.
  A good coverage target: operand B's bypass source changing *during* a multdiv stall.
- While busy, the processor holds the instruction in Execute (`stall_multdiv`) and sends
  bubbles into Memory.

## Pipeline behavior

The ISS doesn't model these, but coverage and assertions will care about them.

- **Bypassing.** Execute's operands take Memory→Execute and Writeback→Execute bypasses, never
  from `$r0`. The Memory stage forwards Writeback data into `data` for `sw`. Writeback→Decode is
  covered by the regfile's same-cycle read (see Clocking).
- **Load-use stall** ([processor.v:181](../../proc/processor.v#L181)). Triggers when `lw` is in
  Execute and its `$rd` (non-zero) matches Decode's `ctrl_readRegA`, or `ctrl_readRegB` when Decode
  isn't a `sw`. **This produces spurious stalls:** `ctrl_readRegB` for I-types is `insn[16:12]`
  (immediate bits), and `ctrl_readRegA` for `j`/`jal`/`setx` is `insn[21:17]` (target bits).
  Those stalls are harmless to correctness, but stall-cause coverage will count them.
- **Branches and jumps** (`bne`, `blt`, `j`, `jal`, `jr`) resolve in Execute and squash 2
  instructions. **`bex`** resolves in Decode and squashes 1.
- **Bubbles show up as writes to `$r0`.** A nop is `add $0,$0,$0`, so Writeback asserts
  `ctrl_writeEnable = 1` with `ctrl_writeReg = 0` on every bubble. Your writeback monitor has to
  filter `ctrl_writeReg == 0`, as `Wrapper_tb.v` does, or it reports writes that never happened.

---

## Memories

**ROM** ([proc/ROM.v](../../proc/ROM.v)) — what your imem responder replaces.
- 4096 words, 12-bit address. The wrappers connect `address_imem[11:0]`, so the PC wraps modulo 4096.
- Registered read: `always @(posedge clk) dataOut <= MemoryArray[addr]`.
- Loaded with **`$readmemb`** (binary text, not hex) at time 0.

**RAM** ([proc/RAM.v](../../proc/RAM.v)) — what your dmem responder replaces.
- 4096 words, 12-bit address (`address_dmem[11:0]`, so addresses alias modulo 4096). Zero-initialized.
- **No read during write.** On a write cycle `dataOut` isn't updated and holds its previous value:
  ```verilog
  always @(posedge clk) if (wEn) MemoryArray[addr] <= dataIn; else dataOut <= MemoryArray[addr];
  ```
  This can't affect architectural state, because the only instruction in Memory on a write cycle
  is `sw`, and `sw` ignores `q_dmem`. It matters only if a monitor or assertion inspects `q_dmem`
  during a write. Model it in your responder anyway, so waveforms match the Wrapper.
- `Wrapper.v` has no memory-mapped I/O. The old `Wrapper_timing.v` put switches at 4096 and LEDs
  at 4097, which alias onto RAM addresses 0 and 1 through the 12-bit truncation.

## Regfile

[proc/regfile/regfile.v](../../proc/regfile/regfile.v)

- 32 registers; register 0's enable is tied to 0.
- **Read ports are tri-state per register**: `assign data_readRegA = RegA[j] ? registerOuts[j] : 32'bz`.
  With a valid 5-bit select exactly one driver is active. An `x` select (e.g. before reset
  settles) gives `x`/`z` on the read bus, so check for that explicitly instead of letting it
  reach a scoreboard compare.
- Writes commit on the rising edge when `ctrl_writeEnable` is set.

---

## Program and expectation files

| Path | Contents |
|---|---|
| `test_files/assembly_files/*.s` | 52 directed programs; `active_final.txt` lists the 41-test regression |
| `test_files/mem_files/*.mem` | assembled images: 4096 lines of 32-char binary; gitignored, regenerated |
| `test_files/verification_files/*_exp.txt` | `num cycles:<n>` then `r<N>=<signed decimal>` lines |
| `test_files/output_files/*_actual.txt` | `Cycle %3d: Wrote %0d into register %0d` trace from `Wrapper_tb.v` |

The Makefile passes all three directories to every test as absolute paths with a trailing `/`
(`+MEM_DIR=`, `+VERIF_DIR=`, `+ASM_DIR=`).

To assemble a program by hand:
`python3 assembler-python-version/assemble.py -o out.mem prog.s`. The autotester does this
automatically through `helper_scripts/asm_compiler.py`. `num cycles` in the `_exp.txt` files is
the directed testbench's run length, not an architectural property. A scoreboard comparing the
order of writes shouldn't depend on it.
