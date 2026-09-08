# ALU
## Name
Siddharth Kini
## Description of Design
The program has 6 main operations:

AND / OR - Utilized a generate loop to create 32 and / or gates for each of the input bits

SLL / SRA - Utilized a barrel shifter to shift by 1, 2, 4, 8, or 16 bits depending on the shift amount. Utilized several MUX_2 modules.

ADD / SUBTRACT - Utilized a carry lookahead adder based on the design discussed in class. Add was implemented as standard and subtract was implemented by flipping bits of B and adding 1 to the carryout.

The following outputs were calculated as such:

isNotEqual - Check if any of the bits in the subtract result were 1, in which case the two are not equal.

overflow - If the sign of the two input numbers match and differ from the sign of the result that means that the operation overflowed

isLessThan - If the result of subtraction is negative, then A < B, but this isn't true if the result overflowed.





## Bugs

None to my knowledge :-)
