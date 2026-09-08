module add_8(A, B, Cin, S, P, G);
    input [7:0] A, B;
    input Cin;
    output [7:0] S;
    output P, G;

    wire [7:0] cins;

    assign cins[0] = Cin;

    // Sums
    genvar i;
    generate
        for( i = 0; i < 8; i = i +1) begin : sums_loop
            xor sum(S[i], A[i], B[i], cins[i]);
        end
    endgenerate

    // Carryout
    wire p0, p1, p2, p3, p4, p5, p6, p7;
    wire g0, g1, g2, g3, g4, g5, g6, g7;


    // 0
    wire a00;
    or (p0, A[0], B[0]);
    and (g0, A[0], B[0]);
    and (a00, cins[0], p0);
    or (cins[1], g0, a00);
    
    // 1
    wire a10, a11;
    or (p1, A[1], B[1]);
    and (g1, A[1], B[1]);
    and (a10, g0, p1);
    and (a11, p1, p0, cins[0]);
    or (cins[2], g1, a10, a11);

    // 2
    wire a20, a21, a22;
    or (p2, A[2], B[2]);
    and (g2, A[2], B[2]);
    and (a20, p2, g1);
    and (a21, p2, p1, g0);
    and (a22, p2, p1, p0, cins[0]);
    or (cins[3], g2, a20, a21, a22);

    // 3
    wire a30, a31, a32, a33;
    or (p3, A[3], B[3]);
    and (g3, A[3], B[3]);
    and (a30, p3, g2);
    and (a31, p3, p2, g1);
    and (a32, p3, p2, p1, g0);
    and (a33, p3, p2, p1, p0, cins[0]);
    or (cins[4], g3, a30, a31, a32, a33);

    // 4
    wire a40, a41, a42, a43, a44;
    or (p4, A[4], B[4]);
    and (g4, A[4], B[4]);
    and (a40, p4, g3);
    and (a41, p4, p3, g2);
    and (a42, p4, p3, p2, g1);
    and (a43, p4, p3, p2, p1, g0);
    and (a44, p4, p3, p2, p1, p0, cins[0]);
    or (cins[5], g4, a40, a41, a42, a43, a44);

    // 5
    wire a50, a51, a52, a53, a54, a55;
    or (p5, A[5], B[5]);
    and (g5, A[5], B[5]);
    and (a50, p5, g4);
    and (a51, p5, p4, g3);
    and (a52, p5, p4, p3, g2);
    and (a53, p5, p4, p3, p2, g1);
    and (a54, p5, p4, p3, p2, p1, g0);
    and (a55, p5, p4, p3, p2, p1, p0, cins[0]);
    or (cins[6], g5, a50, a51, a52, a53, a54, a55);

    // 6
    wire a60, a61, a62, a63, a64, a65, a66;
    or (p6, A[6], B[6]);
    and (g6, A[6], B[6]);
    and (a60, p6, g5);
    and (a61, p6, p5, g4);
    and (a62, p6, p5, p4, g3);
    and (a63, p6, p5, p4, p3, g2);
    and (a64, p6, p5, p4, p3, p2, g1);
    and (a65, p6, p5, p4, p3, p2, p1, g0);
    and (a66, p6, p5, p4, p3, p2, p1, p0, cins[0]);
    or (cins[7], g6, a60, a61, a62, a63, a64, a65, a66);

    // 7
    wire a70, a71, a72, a73, a74, a75, a76, a77;
    or (p7, A[7], B[7]);
    and (g7, A[7], B[7]);
    and (a70, p7, g6);
    and (a71, p7, p6, g5);
    and (a72, p7, p6, p5, g4);
    and (a73, p7, p6, p5, p4, g3);
    and (a74, p7, p6, p5, p4, p3, g2);
    and (a75, p7, p6, p5, p4, p3, p2, g1);
    and (a76, p7, p6, p5, p4, p3, p2, p1, g0);

    // P G
    and (P, p7, p6, p5, p4, p3, p2, p1, p0);
    or (G, g7, a70, a71, a72, a73, a74, a75, a76);



endmodule