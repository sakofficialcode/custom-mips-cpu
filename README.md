# custom-mips-cpu

A 32-bit, 5-stage pipelined MIPS-style processor written in structural Verilog. Built a self-playing guitar controlled by the processor.

| Directory | Contents |
| :--- | :--- |
| [`proc/`](proc/) | The processor, organized by checkpoint (ALU, regfile, multdiv, full CPU) |
| [`final-project/`](final-project/) | The self-playing guitar: Vivado project, player program, songs, and VGA assets |

## Processor

The processor is written primarily in structural Verilog, apart from clocked registers.

- Hazard handling: MX, WX, and WM bypassing, load-use stalls, `bex` taken from the decode stage, and a stall while a multiply or divide is running
- ALU: carry-lookahead adder and barrel shifter
- Multiply/divide: modified Booth multiplication (16 cycles) and non-restoring division (32 cycles)
- Register file: 32 registers of 32 D flip-flops, with tri-state buffers on the read ports, wired up with `genvar`/`generate`
- Testbenches: each module is checked against a CSV of expected outputs, and mismatches are written to a diff file

### In progress

I'm still working on the processor. These are the three things I'm adding right now.

#### UVM testbench

Right now the ALU, regfile, and multdiv are each tested against a fixed CSV of expected outputs, and there's no full-processor testbench in this repo. I'm replacing that setup with a UVM testbench that can test the whole processor, not just one module at a time. This also means moving from Icarus Verilog to a simulator that supports SystemVerilog and UVM.

#### Instruction and data caches

Instruction memory (`ROM.v`) and data memory (`RAM.v`) are currently plain 4096-word arrays with no memory hierarchy. I'm adding a separate cache in front of each one. The pipeline will also need to stall on a cache miss, the same way it already stalls during a multiply or divide.

#### Branch prediction

`bne` and `blt` are resolved in the execute stage, and the processor always assumes a branch won't be taken. When a branch or jump is taken, the two instructions already in fetch and decode get flushed. Branch prediction will guess the outcome earlier so that fewer instructions get thrown away.

### Simulation

```bash
cd proc/alu && iverilog -o ALU -c FileList.txt && ./ALU +test=add
cd ../regfile && iverilog -o regfile -c FileList.txt && ./regfile +test=basic
cd ../multdiv && iverilog -o multdiv -c FileList.txt && ./multdiv +test=multbasic
```

Each test writes a `*_diff.csv` file. If it's empty, all the test vectors passed.

The full-processor testbench (`Wrapper_tb.v`, referenced in `proc/FileList.txt`) isn't included in this repo, so the complete CPU can't be simulated from here yet.

### Instruction set

This isn't the standard MIPS instruction set. Opcodes are 5 bits instead of 6, R-type instructions choose their operation with a 5-bit ALU opcode instead of a 6-bit funct field, and jump targets are 27 bits. `setx` and `bex` don't exist in MIPS, and in MIPS `blt` is only an assembler pseudo-instruction. All R-type instructions use opcode `00000`.

| R-type | ALU op | | I / J-type | Opcode |
| :--- | :--- | :-- | :--- | :--- |
| `add` | `00000` | | `j` | `00001` |
| `sub` | `00001` | | `bne` | `00010` |
| `and` | `00010` | | `jal` | `00011` |
| `or` | `00011` | | `jr` | `00100` |
| `sll` | `00100` | | `addi` | `00101` |
| `sra` | `00101` | | `blt` | `00110` |
| `mul` | `00110` | | `sw` | `00111` |
| `div` | `00111` | | `lw` | `01000` |
| | | | `setx` | `10101` |
| | | | `bex` | `10110` |

When `add`, `addi`, `sub`, `mul`, or `div` hits an exception, it writes a status code to `$r30` (`$rstatus`): 1 for `add`, 2 for `addi`, 3 for `sub`, 4 for `mul`, and 5 for `div`.

More detail is in the design docs for the [processor](proc/README.md), [ALU](proc/alu/README.md), [multdiv](proc/multdiv/README.md), and [regfile](proc/regfile/README.md).

## Self-playing guitar

The processor runs a bare-metal assembly program that reads a song out of data memory and moves nine servos mounted on an acoustic guitar. Four of the servos pluck strings and the other five press frets. The VGA output shows a screen for choosing which album to play.

### Hardware

- Board: Nexys A7-100T (`xc7a100tcsg324-1`). A PLL divides the 100 MHz board clock down to 25 MHz, which clocks both the processor and the VGA output.
- Servos: the pluck servos (`servos[0:3]`) connect to Pmod JC and the fret servos (`servos[4:8]`) connect to Pmod JD.
- Video: 640x480 with 12-bit color, using a palettized framebuffer.
- Buttons: BTNU resets, BTNL and BTNR change the selected album, and BTNC starts playback.

### Building

```bash
cd final-project
python songs/songtomem.py
python assembly/assembler-python-version/assemble.py assembly/guitar.s -o assembly/guitar.mem
vivado final_project-vivado.xpr
```

`songtomem.py` builds `songs/song.mem` from the song text files, `assemble.py` builds `guitar.mem` from the player program, and Vivado synthesizes the design and programs the board.

### Writing a song

Songs are stored in `songs/song0.txt` through `songs/song2.txt`. The first line sets the tempo, and every line after that is one event:

```
BPM 230
F 10110 4
P 0 0
P 3 8
```

| Line | Meaning |
| :--- | :--- |
| `BPM <n>` | Tempo in beats per minute. Has to be the first line |
| `P <string> <delta>` | Pluck a string (`0`-`3`) |
| `F <frets> <delta>` | Set all five fret servos at once, one digit per fret (`1` pressed, `0` released) |

`<delta>` is the number of ticks since the previous event, where one tick is a sixteenth note. In the example above, `F 10110 4` presses frets 0, 2, and 3 four ticks after the previous event, `P 0 0` plucks string 0 at the same time, and `P 3 8` plucks string 3 eight ticks later.

The song file can't contain comments, since each event line has to be exactly three fields.

`songtomem.py` converts the deltas into absolute times in milliseconds (`ms = ticks * 15000 / bpm`). The output starts with a table of the three songs' start addresses, followed by each song stored as one hex word per ASCII character and ended with a `0` word. `assemble.py` writes one 32-bit binary string per line, which is the format `ROM.v` reads with `$readmemb`.

### How it works

```
                +-----------+
 guitar.mem --> |    ROM    |
                +-----------+
                      |
                      v
                +-----------+  MMIO reads  +----------------+
                | processor | <----------- | 4096 ms timer  |
                +-----------+              | 4097 BTNC      |
                      |                    | 4098 album     |
                      | lw / sw            +----------------+
           +----------+-----------+
           |                      |
           v                      v
     +-----------+        +--------------+      +----------------+
     |    RAM    |        | servo duties |      | PWMSerializer  |
     | song.mem  |        | 4100 + 4*i   | ---> | x9, 20 ms      | ---> servos
     +-----------+        +--------------+      +----------------+

 BTNL/BTNR ---> VGAController ---> album select screen
                      |
                      +----------> selected album (MMIO 4098)
```

The player program ([`guitar.s`](final-project/assembly/guitar.s)) works like this:

1. Move all nine servos to their calibrated starting positions.
2. Wait for BTNC. When it's pressed, save the current millisecond count as the start time.
3. Read the selected album from MMIO `4098`, look up that song's start address in the offset table, and jump to it.
4. Read through the song one character at a time, parsing each `P` or `F` event.
5. For each event, loop in `wait_until` until the timer reaches the event's timestamp, then write the new servo duty cycles.
6. Stop when it reaches the `0` word at the end of the song.

### Memory map

| Address | R/W | Purpose |
| :--- | :---: | :--- |
| `0`-`2` | R | Song offset table (start of `song.mem`) |
| `3`-`3071` | R | Song data (rest of `song.mem`) |
| `3072`-`4095` | R/W | Scratch space for the player program |
| `4096` | R | Free-running millisecond counter |
| `4097` | R | BTNC state |
| `4098` | R | Selected album (`0`-`2`) from the VGA controller |
| `4100 + 4*i` | W | Duty cycle for servo `i` (`i` = 0-8), using the low 10 bits (`0`-`1023`) |

The odd-numbered fret servos are mounted facing the opposite direction, so their pressed and released angles are swapped. The pluck servos don't go back to a rest position after a note. Each pluck moves the servo to the other side of the string, so the picking direction alternates from note to note. The calibrated angles are set in `guitar.s`.

### Configuration

Settings are Verilog parameters or constants in the Python scripts:

| Parameter | File | Default | Purpose |
| :--- | :--- | :--- | :--- |
| `INSTR_FILE` | `Wrapper.v` | `"guitar"` | Instruction ROM image (`.mem` is appended) |
| `MEMFILE` | `Wrapper.v` (passed to `RAM`) | `"song.mem"` | Data memory contents |
| `MEMFILE` | `VGAController.v` | `"image.mem"` / `"colors.mem"` | Framebuffer and color palette |
| `n_servos` | `Wrapper.v` | `9` | Number of servo channels (4 pluck, 5 fret) |
| `PERIOD_WIDTH_NS` | `PWMSerializer.v` | `20000000` | Servo PWM period (20 ms) |
| `SYS_FREQ_MHZ` | `PWMSerializer.v` | `25` | Has to match the PLL output clock |
| `NUM_SONGS` | `songtomem.py` | `3` | Number of songs, which also sets the offset table size |

To regenerate the VGA framebuffer from an image (requires Pillow):

```bash
cd final-project/vga && python PicToMem.py slide.png
```

## Tools

Icarus Verilog for simulation, GTKWave for viewing waveforms, Vivado for synthesis, and Python 3 for the assembler and memory image scripts.

## Credits

- Siddharth Kini: processor and toolchain
- Vivek Chandy: self-playing guitar ([`final-project/`](final-project/))
