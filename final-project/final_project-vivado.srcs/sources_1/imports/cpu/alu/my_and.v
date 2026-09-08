module my_and(in1, in2, res);

    input  [31:0] in1;
    input  [31:0] in2;
    output [31:0] res;

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1)
            and and_bit(res[i], in1[i], in2[i]);
    endgenerate

endmodule