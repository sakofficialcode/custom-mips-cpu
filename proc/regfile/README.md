# Regfile
## Name
Siddharth Kini

## Description of Design
The Register file instantiates 32 Register modules, each of which have 32 D Flip-Flops.

`<<` Left Shifters were used to decode the write enable signal and the RegA and RegB output registers as necessary.

Tri-State Buffers were utilized in the output ports for RegA and RegB data to ensure only one register's output signal was wired to a specific output port on the module at a time. 

Wiring was done programmatically using genvars and generate statements.

## Bugs
None to my knowledge :-)