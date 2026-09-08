module cla_8b(sum, overflow, P, G, in1, in2, c_in);
    input [7:0] in1;
    input [7:0] in2;
    input c_in;
    output [7:0] sum;
    output overflow, P, G;

    wire [7:0] g;
    wire [7:0] p;
    wire [7:0] c;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin
            and and_bit(g[i], in1[i], in2[i]);
            or or_bit(p[i], in1[i], in2[i]);
        end
    endgenerate

    wire c0_term1;
    and and_c0(c0_term1, p[0], c_in);
    or or_c0(c[0], g[0], c0_term1);

    wire c1_term1, c1_term2;
    and and_c1_1(c1_term1, p[1], g[0]);
    and and_c1_2(c1_term2, p[1], p[0], c_in);
    or or_c1(c[1], g[1], c1_term1, c1_term2);

    wire c2_term1, c2_term2, c2_term3;
    and and_c2_1(c2_term1, p[2], g[1]);
    and and_c2_2(c2_term2, p[2], p[1], g[0]);
    and and_c2_3(c2_term3, p[2], p[1], p[0], c_in);
    or or_c2(c[2], g[2], c2_term1, c2_term2, c2_term3);

    wire c3_term1, c3_term2, c3_term3, c3_term4;
    and and_c3_1(c3_term1, p[3], g[2]);
    and and_c3_2(c3_term2, p[3], p[2], g[1]);
    and and_c3_3(c3_term3, p[3], p[2], p[1], g[0]);
    and and_c3_4(c3_term4, p[3], p[2], p[1], p[0], c_in);
    or or_c3(c[3], g[3], c3_term1, c3_term2, c3_term3, c3_term4);

    wire c4_term1, c4_term2, c4_term3, c4_term4, c4_term5;
    and and_c4_1(c4_term1, p[4], g[3]);
    and and_c4_2(c4_term2, p[4], p[3], g[2]);
    and and_c4_3(c4_term3, p[4], p[3], p[2], g[1]);
    and and_c4_4(c4_term4, p[4], p[3], p[2], p[1], g[0]);
    and and_c4_5(c4_term5, p[4], p[3], p[2], p[1], p[0], c_in);
    or or_c4(c[4], g[4], c4_term1, c4_term2, c4_term3, c4_term4, c4_term5);

    wire c5_term1, c5_term2, c5_term3, c5_term4, c5_term5, c5_term6;
    and and_c5_1(c5_term1, p[5], g[4]);
    and and_c5_2(c5_term2, p[5], p[4], g[3]);
    and and_c5_3(c5_term3, p[5], p[4], p[3], g[2]);
    and and_c5_4(c5_term4, p[5], p[4], p[3], p[2], g[1]);
    and and_c5_5(c5_term5, p[5], p[4], p[3], p[2], p[1], g[0]);
    and and_c5_6(c5_term6, p[5], p[4], p[3], p[2], p[1], p[0], c_in);
    or or_c5(c[5], g[5], c5_term1, c5_term2, c5_term3, c5_term4, c5_term5, c5_term6);

    wire c6_term1, c6_term2, c6_term3, c6_term4, c6_term5, c6_term6, c6_term7;
    and and_c6_1(c6_term1, p[6], g[5]);
    and and_c6_2(c6_term2, p[6], p[5], g[4]);
    and and_c6_3(c6_term3, p[6], p[5], p[4], g[3]);
    and and_c6_4(c6_term4, p[6], p[5], p[4], p[3], g[2]);
    and and_c6_5(c6_term5, p[6], p[5], p[4], p[3], p[2], g[1]);
    and and_c6_6(c6_term6, p[6], p[5], p[4], p[3], p[2], p[1], g[0]);
    and and_c6_7(c6_term7, p[6], p[5], p[4], p[3], p[2], p[1], p[0], c_in);
    or or_c6(c[6], g[6], c6_term1, c6_term2, c6_term3, c6_term4, c6_term5, c6_term6, c6_term7);

    wire c7_term1, c7_term2, c7_term3, c7_term4, c7_term5, c7_term6, c7_term7, c7_term8;
    and and_c7_1(c7_term1, p[7], g[6]);
    and and_c7_2(c7_term2, p[7], p[6], g[5]);
    and and_c7_3(c7_term3, p[7], p[6], p[5], g[4]);
    and and_c7_4(c7_term4, p[7], p[6], p[5], p[4], g[3]);
    and and_c7_5(c7_term5, p[7], p[6], p[5], p[4], p[3], g[2]);
    and and_c7_6(c7_term6, p[7], p[6], p[5], p[4], p[3], p[2], g[1]);
    and and_c7_7(c7_term7, p[7], p[6], p[5], p[4], p[3], p[2], p[1], g[0]);
    and and_c7_8(c7_term8, p[7], p[6], p[5], p[4], p[3], p[2], p[1], p[0], c_in);
    or or_c7(c[7], g[7], c7_term1, c7_term2, c7_term3, c7_term4, c7_term5, c7_term6, c7_term7, c7_term8);

    xor xor_sum0(sum[0], in1[0], in2[0], c_in);
    xor xor_sum1(sum[1], in1[1], in2[1], c[0]);
    xor xor_sum2(sum[2], in1[2], in2[2], c[1]);
    xor xor_sum3(sum[3], in1[3], in2[3], c[2]);
    xor xor_sum4(sum[4], in1[4], in2[4], c[3]);
    xor xor_sum5(sum[5], in1[5], in2[5], c[4]);
    xor xor_sum6(sum[6], in1[6], in2[6], c[5]);
    xor xor_sum7(sum[7], in1[7], in2[7], c[6]);

    xor ovf(overflow, c[6], c[7]);

    and and_P(P, p[7], p[6], p[5], p[4], p[3], p[2], p[1], p[0]);

    wire G_term1, G_term2, G_term3, G_term4, G_term5, G_term6, G_term7;
    and and_G_1(G_term1, p[7], g[6]);
    and and_G_2(G_term2, p[7], p[6], g[5]);
    and and_G_3(G_term3, p[7], p[6], p[5], g[4]);
    and and_G_4(G_term4, p[7], p[6], p[5], p[4], g[3]);
    and and_G_5(G_term5, p[7], p[6], p[5], p[4], p[3], g[2]);
    and and_G_6(G_term6, p[7], p[6], p[5], p[4], p[3], p[2], g[1]);
    and and_G_7(G_term7, p[7], p[6], p[5], p[4], p[3], p[2], p[1], g[0]);
    or or_G(G, g[7], G_term1, G_term2, G_term3, G_term4, G_term5, G_term6, G_term7);

endmodule