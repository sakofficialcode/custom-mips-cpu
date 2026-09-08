module alu(data_operandA, data_operandB, ctrl_ALUopcode, ctrl_shiftamt, data_result, isNotEqual, isLessThan, overflow);
        
    input [31:0] data_operandA, data_operandB;
    input [4:0] ctrl_ALUopcode, ctrl_shiftamt;

    output [31:0] data_result;
    output isNotEqual, isLessThan, overflow;

    wire [2:0] sel;
    wire [31:0] and_result, or_result, sll_result, sra_result, add_result, subtract_result;

    assign sel = ctrl_ALUopcode[2:0];

    // add your code here

    // AND
    genvar i;
    generate
        for (i = 0; i < 32; i = i+1) begin : and_loop
            and a(and_result[i], data_operandA[i], data_operandB[i]);
        end
    endgenerate


    // OR
    genvar j;
    generate
        for (j = 0; j < 32; j = j+1) begin : or_loop
            or o(or_result[j], data_operandA[j], data_operandB[j]);
        end
    endgenerate

    // Left Logical Shifter
    wire [31:0] lw1, lw2, lw3, lw4;
    
    mux_2 #(.WIDTH(32)) lm1(lw1, ctrl_shiftamt[0], data_operandA, {data_operandA[30:0], 1'b0});
    mux_2 #(.WIDTH(32)) lm2(lw2, ctrl_shiftamt[1], lw1, {lw1[29:0], {2{1'b0}}});
    mux_2 #(.WIDTH(32)) lm3(lw3, ctrl_shiftamt[2], lw2, {lw2[27:0], {4{1'b0}}});
    mux_2 #(.WIDTH(32)) lm4(lw4, ctrl_shiftamt[3], lw3, {lw3[23:0], {8{1'b0}}});
    mux_2 #(.WIDTH(32)) lm5(sll_result, ctrl_shiftamt[4], lw4, {lw4[15:0], {16{1'b0}}});
    
    // Right Arithmetic Shifter
    wire [31:0] rw1, rw2, rw3, rw4;

    mux_2 #(.WIDTH(32)) rm1(rw1, ctrl_shiftamt[0], data_operandA, {{1{data_operandA[31]}}, data_operandA[31:1]});
    mux_2 #(.WIDTH(32)) rm2(rw2, ctrl_shiftamt[1], rw1, {{2{rw1[31]}}, rw1[31:2]});
    mux_2 #(.WIDTH(32)) rm3(rw3, ctrl_shiftamt[2], rw2, {{4{rw2[31]}}, rw2[31:4]});
    mux_2 #(.WIDTH(32)) rm4(rw4, ctrl_shiftamt[3], rw3, {{8{rw3[31]}}, rw3[31:8]});
    mux_2 #(.WIDTH(32)) rm5(sra_result, ctrl_shiftamt[4], rw4, {{16{rw4[31]}}, rw4[31:16]});

    // ADDER
    wire AP0, AP1, AP2, AP3;
    wire AG0, AG1, AG2, AG3;

    wire Ac8, Ac16, Ac24, Ac32;

    assign Ac8 = AG0;

    wire Ac160;
    and (Ac160, AP1, Ac8);
    or (Ac16, AG1, Ac160);

    wire Ac240, Ac241;
    and (Ac240, AP2, AG1);
    and (Ac241, AP2, AP1, AG0);
    or (Ac24, AG2, Ac240, Ac241);
    
    add_8 a0(data_operandA[7:0], data_operandB[7:0], 1'b0, add_result[7:0], AP0, AG0);
    add_8 a1(data_operandA[15:8], data_operandB[15:8], Ac8, add_result[15:8], AP1, AG1);
    add_8 a2(data_operandA[23:16], data_operandB[23:16], Ac16, add_result[23:16], AP2, AG2);
    add_8 a3(data_operandA[31:24], data_operandB[31:24], Ac24, add_result[31:24], AP3, AG3);

    // Subtractor

    wire [31:0] B_not;

    genvar k;
    generate
        for (k = 0; k < 32; k = k+1) begin : not_b_loop
            not (B_not[k], data_operandB[k]);
        end
    endgenerate

    wire SP0, SP1, SP2, SP3;
    wire SG0, SG1, SG2, SG3;

    wire Sc8, Sc16, Sc24, Sc32;

    wire Sc80;
    and (Sc80, SP0, 1'b1);
    or (Sc8, SG0, Sc80);

    wire Sc160, Sc161;
    and (Sc160, SP1, SG0);
    and (Sc161, SP1, SP0, 1'b1);
    or (Sc16, SG1, Sc160, Sc161);

    wire Sc240, Sc241, Sc242;
    and (Sc240, SP2, SG1);
    and (Sc241, SP2, SP1, SG0);
    and (Sc242, SP2, SP1, SP0, 1'b1);
    or (Sc24, SG2, Sc240, Sc241, Sc242);
    
    add_8 s0(data_operandA[7:0], B_not[7:0], 1'b1, subtract_result[7:0], SP0, SG0);
    add_8 s1(data_operandA[15:8], B_not[15:8], Sc8, subtract_result[15:8], SP1, SG1);
    add_8 s2(data_operandA[23:16], B_not[23:16], Sc16, subtract_result[23:16], SP2, SG2);
    add_8 s3(data_operandA[31:24], B_not[31:24], Sc24, subtract_result[31:24], SP3, SG3);

    mux_8 #(.WIDTH(32)) res_mux(data_result, sel, add_result, subtract_result, and_result, or_result, sll_result, sra_result, 32'b0, 32'b0);

    
    or (isNotEqual, subtract_result[0], subtract_result[1], subtract_result[2], subtract_result[3], subtract_result[4], subtract_result[5], subtract_result[6], subtract_result[7], subtract_result[8], subtract_result[9], subtract_result[10], subtract_result[11], subtract_result[12], subtract_result[13], subtract_result[14], subtract_result[15], subtract_result[16], subtract_result[17], subtract_result[18], subtract_result[19], subtract_result[20], subtract_result[21], subtract_result[22], subtract_result[23], subtract_result[24], subtract_result[25], subtract_result[26], subtract_result[27], subtract_result[28], subtract_result[29], subtract_result[30], subtract_result[31]);

    wire accB_sign, same_sign, diff_sign;

    assign accB_sign = ctrl_ALUopcode[0] ? B_not[31] : data_operandB[31];
    
    xnor (same_sign, data_operandA[31], accB_sign);
    xor (diff_sign, data_operandA[31], data_result[31]);
    and (overflow, same_sign, diff_sign);

    
    wire diff_sign_less_than;
    xor (diff_sign_less_than, subtract_result[31], overflow);
    assign isLessThan = diff_sign_less_than ? 1'b1 : 1'b0; 






    



endmodule