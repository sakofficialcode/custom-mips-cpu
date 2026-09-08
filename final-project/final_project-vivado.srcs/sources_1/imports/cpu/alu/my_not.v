module my_not(in, res);

    input  [31:0] in;
    output [31:0] res;

    genvar i;
    generate
        for(i=0;i<32;i=i+1)
            not not_bit(res[i],in[i]);
    endgenerate
    
endmodule
