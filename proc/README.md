# Processor
## Siddharth Kini (SAK101)

## Description of Design

5 stage pipeline:
 - Fetch: Set PC to instruction address in memory. Typically increments by 1 for a word, but can be set to specific addresses for branches and jumps.
 - Decode: Reads values from the register file based on the instruction.
 - Execute: Uses values and generates output from the ALU and/or MultDiv module to enact the expected behavior of an instruction.
 - Memory: Stores or Loads values from memory.
 - Writeback: Writes data into the register file.

## Bypassing
### x_a_bypass / x_b_bypass: MX and WX Bypasses
When the instruction in execute uses the same register as either the data in memory or writeback, AND those instructions are write-enable, as in they'll update the register value, they're bypassed into the appropriate line in the execute stage.
### data: WM Bypass
Similarly, when a register is about to be written to and then stored, that data is forwarded into the memory stage.
### BEX bypass
If at any point in the pipeline, the BEX register is written to, BEXTaken is driven high and the branch is taken straight from the decode stage.


## Stalling
### Load Use Stall
The processor stalls when a Load Word instruction is immediately followed by another instruction which uses the same register that the data is loaded into. By inserting a NOP into the pipeline at the DX latch, the processor now is able to forward the value from the LW to the following real instruction which is in the execute stage.

### MultDiv Stall
The processor stalls whenever a Multiplication or Division instruction is active. After the correct number of cycles for the specific instruction,  multdiv_ready is HIGH which ends the stall and latches the correct value from the MultDiv module.


## Optimizations
The current iteration does not include any optimizations, but the following are planned:
- Branch Prediction
- Pipelined Multicycle Operations

## Bugs
None to my knowledge