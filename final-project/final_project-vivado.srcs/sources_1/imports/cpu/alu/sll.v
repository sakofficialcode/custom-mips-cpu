module sll(in, shift_amt, res);

    input [31:0] in;
    input [4:0] shift_amt;
    output [31:0] res;

    wire [31:0] s1,s2,s3,s4,s5;

    assign s1 = shift_amt[0] ? {in[30:0],1'b0} : in;
    assign s2 = shift_amt[1] ? {s1[29:0],2'b00} : s1;
    assign s3 = shift_amt[2] ? {s2[27:0],4'b0000} : s2;
    assign s4 = shift_amt[3] ? {s3[23:0],8'b00000000} : s3;
    assign s5 = shift_amt[4] ? {s4[15:0],16'b0000000000000000} : s4;

    assign res = s5;
    
endmodule