module cla(in1, in2, c_in, sum, overflow);

    input [31:0] in1;
    input [31:0] in2;
    input c_in;
    output [31:0] sum;
    output overflow;

    wire [3:0] P, G, ovf;
    wire [4:0] c;

    assign c[0] = c_in;

    cla_8b block0(sum[7:0], ovf[0], P[0], G[0], in1[7:0], in2[7:0], c[0]);
    cla_8b block1(sum[15:8], ovf[1], P[1], G[1], in1[15:8], in2[15:8], c[1]);
    cla_8b block2(sum[23:16], ovf[2], P[2], G[2], in1[23:16], in2[23:16], c[2]);
    cla_8b block3(sum[31:24], overflow, P[3], G[3], in1[31:24], in2[31:24], c[3]);
    
    wire c1_term;
    and and_c1(c1_term, P[0], c[0]);
    or or_c1(c[1], G[0], c1_term);

    wire c2_term1, c2_term2;
    and and_c2_1(c2_term1, P[1], G[0]);
    and and_c2_2(c2_term2, P[1], P[0], c[0]);
    or or_c2(c[2], G[1], c2_term1, c2_term2);

    wire c3_term1, c3_term2, c3_term3;
    and and_c3_1(c3_term1, P[2], G[1]);
    and and_c3_2(c3_term2, P[2], P[1], G[0]);
    and and_c3_3(c3_term3, P[2], P[1], P[0], c[0]);
    or or_c3(c[3], G[2], c3_term1, c3_term2, c3_term3);

    wire c4_term1, c4_term2, c4_term3, c4_term4;
    and and_c4_1(c4_term1, P[3], G[2]);
    and and_c4_2(c4_term2, P[3], P[2], G[1]);
    and and_c4_3(c4_term3, P[3], P[2], P[1], G[0]);
    and and_c4_4(c4_term4, P[3], P[2], P[1], P[0], c[0]);
    or or_c4(c[4], G[3], c4_term1, c4_term2, c4_term3, c4_term4);

endmodule