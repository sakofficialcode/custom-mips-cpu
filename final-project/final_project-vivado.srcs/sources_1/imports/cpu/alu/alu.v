module alu(data_operandA, data_operandB, ctrl_ALUopcode, ctrl_shiftamt, data_result, isNotEqual, isLessThan, overflow);
        
    input [31:0] data_operandA, data_operandB;
    input [4:0] ctrl_ALUopcode, ctrl_shiftamt;

    output [31:0] data_result;
    output isNotEqual, isLessThan, overflow;

    // add your code here
    wire [31:0] add_res,sub_res,and_res,or_res,sll_res,sra_res;
    wire ov_add,ov_sub;

    wire [31:0] neg_B;
    genvar bi;
    generate
    for (bi = 0; bi < 32; bi = bi + 1) begin : GEN_NOT_B
        not not_b (neg_B[bi], data_operandB[bi]);
    end
    endgenerate

    cla add0(data_operandA,data_operandB,1'b0,add_res,ov_add);
    cla sub0(data_operandA,neg_B,1'b1,sub_res,ov_sub);
    my_and and0(data_operandA,data_operandB,and_res);
    my_or or0(data_operandA,data_operandB,or_res);
    sll sll0(data_operandA,ctrl_shiftamt,sll_res);
    sra sra0(data_operandA,ctrl_shiftamt,sra_res);

    mux_8 result_mux(
        data_result,
        ctrl_ALUopcode[2:0],
        add_res,
        sub_res,
        and_res,
        or_res,
        sll_res,
        sra_res, 
        add_res,
        32'b0
    );

    mux_8 #(1) overflow_mux(
        overflow,
        ctrl_ALUopcode[2:0],
        ov_add,
        ov_sub,
        1'b0,
        1'b0,
        1'b0,
        1'b0,
        1'b0,
        1'b0
    );
   
    wire [30:0] neq_chain;
    or neqor(neq_chain[0], sub_res[0], sub_res[1]);
    genvar i;
    generate
    for (i = 1; i < 31; i = i + 1) begin
        or or_stage(neq_chain[i], neq_chain[i-1], sub_res[i+1]);
    end
    endgenerate

    assign isNotEqual = neq_chain[30];

    xor xor_lt(isLessThan, sub_res[31], ov_sub);
    
endmodule