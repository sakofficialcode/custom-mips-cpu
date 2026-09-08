module multdiv(
	data_operandA, data_operandB, 
	ctrl_MULT, ctrl_DIV, 
	clock, 
	data_result, data_exception, data_resultRDY);

    input [31:0] data_operandA, data_operandB;
    input ctrl_MULT, ctrl_DIV, clock;

    output [31:0] data_result;
    output data_exception, data_resultRDY;

    // add your code here

    // Store data inputs

    wire [31:0] stable_A, stable_B;
    register #(.WIDTH(32)) AReg(.clock(clock), .in(data_operandA), .out(stable_A), .enable(ctrl_DIV | ctrl_MULT), .reset());
    register #(.WIDTH(32)) BReg(.clock(clock), .in(data_operandA), .out(stable_B), .enable(ctrl_DIV | ctrl_MULT), .reset());

    
    // Store Operation
    wire multOp, divOp;

    dffe_ref multDff(.q(multOp), .d(1'b1), .clk(clock), .en(ctrl_MULT), .clr(ctrl_DIV));
    dffe_ref divDff(.q(divOp), .d(1'b1), .clk(clock), .en(ctrl_DIV), .clr(ctrl_MULT));

    
    // Counter
    wire [5:0] counter;

    tff c0(.t(1'b1), .clock(clock), .reset(ctrl_MULT | ctrl_DIV), .q(counter[0]));
    tff c1(.t(counter[0]), .clock(clock), .reset(ctrl_MULT | ctrl_DIV), .q(counter[1]));
    tff c2(.t(counter[0] & counter[1]), .clock(clock), .reset(ctrl_MULT | ctrl_DIV), .q(counter[2]));
    tff c3(.t(counter[0] & counter[1] & counter[2]), .clock(clock), .reset(ctrl_MULT | ctrl_DIV), .q(counter[3]));
    tff c4(.t(counter[0] & counter[1] & counter[2] & counter[3]), .clock(clock), .reset(ctrl_MULT | ctrl_DIV), .q(counter[4]));
    tff c5(.t(counter[0] & counter[1] & counter[2] & counter[3] & counter[4]), .clock(clock), .reset(ctrl_MULT | ctrl_DIV), .q(counter[5]));

    // MULT
    wire [64:0] boothReg_d, boothReg_q;

    register #(.WIDTH(65)) boothReg(.clock(clock), .in(boothReg_d), .out(boothReg_q), .enable(1'b1), .reset(ctrl_MULT));

    wire [2:0] boothCode;
    assign boothCode = boothReg_q[2:0];

    wire [31:0] aluOut;

    alu boothALU(.data_operandA(boothReg_q[64:33]), .data_operandB(stable_A << ~(^boothCode[1:0])), .ctrl_ALUopcode({4'b0, boothCode[2]}), .ctrl_shiftamt(5'b0), .data_result(aluOut), .isNotEqual(), .isLessThan(), .overflow());

    wire signed [64:0] beforeArr, afterArr;
    assign beforeArr = (~(|boothCode) | &boothCode) ? boothReg_q : {aluOut, boothReg_q[32:0]};
    assign afterArr = beforeArr >>> 2;

    assign boothReg_d = ~(|counter) ? {32'b0, data_operandB[31:0], 1'b0} : afterArr;

    wire mult_exception;
    assign mult_exception = ~((~(|boothReg_q[64:33]) & ~boothReg_q[32]) | ((&boothReg_q[64:33]) & boothReg_q[32])) | (stable_A[31] & ~(|stable_A[30:0]) & data_operandB[31]) | (data_operandB[31] & ~(|data_operandB[30:0]) & stable_A[31]);

    // DIV
    wire [31:0] negA, negB;
    wire [31:0] accA, accB;
    assign accA = stable_A[31] ? negA : stable_A;
    assign accB = data_operandB[31] ? negB : data_operandB;
    alu negAAlu(.data_operandA(~stable_A), .data_operandB(32'b1), .ctrl_ALUopcode(5'b0), .ctrl_shiftamt(5'b0), .data_result(negA), .isNotEqual(), .isLessThan(), .overflow());
    alu negBAlu(.data_operandA(~data_operandB), .data_operandB(32'b1), .ctrl_ALUopcode(5'b0), .ctrl_shiftamt(5'b0), .data_result(negB), .isNotEqual(), .isLessThan(), .overflow());

    wire [63:0] divReg_d, divReg_q;
    
    register #(.WIDTH(64)) divReg(.clock(clock), .in(divReg_d), .out(divReg_q), .enable(1'b1), .reset(ctrl_DIV));

    wire [31:0] divAluOut;

    wire correction;
    assign correction = divReg_q[31] & (counter[5] & counter[0] & ~counter[4] & ~counter[3] & ~counter[2] & ~counter[1]);

    alu divALU(.data_operandA(correction ? divReg_q[63:32] : divReg_q[62:31]), .data_operandB(accB), .ctrl_ALUopcode({4'b0, ~divReg_q[63]}), .ctrl_shiftamt(5'b0), .data_result(divAluOut), .isNotEqual(), .isLessThan(), .overflow());

    wire [63:0] ls;
    assign ls = {divAluOut, divReg_q[30:0], ~divAluOut[31]};

    wire [63:0] corrected;
    assign corrected = {divAluOut, divReg_q[31:0]};

    assign divReg_d = ~(|counter) ? {32'b0, accA[31:0]} : correction ? corrected : ls;
    //assign divReg_d = ctrl_DIV ? {32'b0, accA[31:0]} : correction ? corrected : ls;

    wire divException;
    assign divException = ~|data_operandB;

    wire [31:0] divOut, negDivOut;
    assign divOut = correction ? corrected : divReg_q[31:0];
    alu negOut (.data_operandA(~divOut), .data_operandB(32'b1), .ctrl_ALUopcode(5'b0), .ctrl_shiftamt(5'b0), .data_result(negDivOut), .isNotEqual(), .isLessThan(), .overflow());

    assign data_resultRDY = multOp ? (counter[4] & counter[0] & ~counter[3] & ~counter[2] & ~counter[1]) :  counter[5] & counter[0] & ~counter[4] & ~counter[3] & ~counter[2] & ~counter[1];
    assign data_result = multOp ? boothReg_q[32:1] : divException ? 32'b0 : (stable_A[31] ^ data_operandB[31]) ? negDivOut : divOut;
    assign data_exception = multOp ? mult_exception : divException;

endmodule