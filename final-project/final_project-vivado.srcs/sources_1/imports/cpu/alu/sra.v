module sra(in, shift_amt, res);

    input  [31:0] in;
    input  [4:0]  shift_amt;
    output [31:0] res;

    wire [31:0] r1,r2,r3,r4,r5;

    assign r1 = shift_amt[0] ? {in[31],in[31:1]} : in;
    assign r2 = shift_amt[1] ? {{2{in[31]}},r1[31:2]} : r1;
    assign r3 = shift_amt[2] ? {{4{in[31]}},r2[31:4]} : r2;
    assign r4 = shift_amt[3] ? {{8{in[31]}},r3[31:8]} : r3;
    assign r5 = shift_amt[4] ? {{16{in[31]}},r4[31:16]} : r4;

    assign res = r5;
    
endmodule