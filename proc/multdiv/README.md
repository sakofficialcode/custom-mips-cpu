# MultDiv
## Name
Siddharth Kini
## Description of Design
Implemented 6 bit (64 cycle) counter with T flip-flops.
Utilizes counter to ensure data ready after 16/32 clock cycles of processing for multiplication and division operations respectively.

### Multiplication
Implements a modified booth's algorithm: \
`000` / `111` - No sum
`001` / `010` - Add Multplicand (`data_operandA`) \
`011` - Add Multiplicand * 2 (`data_operandA << 1`) \
`110` / `101` - Subtract Multiplicand (`data_operandA`) \
`100` - Subtract Multiplicand * 2 (`data_operandA << 1`)

- No sum option was implemented via a mux that checks for those two options. 
- The register file was edited from the previous checkpoint to allow for varying length inputs through a parameter. It was used to hold the upper (`32` bits), lower (`32` bits), and helper bit of the booth register.
- Upon each clock cycle, one of the above actions was taken through the ALU along with an arithmetic right shift of `2` bits. The result was stored in the booth register.

### Division

First check for negative divisor / dividend, and change both to positive if necessary.

Uses the non-restore division algorithm:
1) A sign bit: `0` - Shift left, subtract divisor from accumulator / `1` - Shift left, add divisor to accumulator
2) A sign bit: `0` - Set LSB to `1` / `1` - Set LSB to `0`

Continue for 32 bits (Length of dividend) \
A sign bit: `0` - Pass / `1` - Add divisor to accumulator

Correct the sign of the quotient by checking if either divisor or dividend, but not both, are negative and negating the result if one is.

## Bugs
None to my knowledge :-)