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
    wire [31:0] mult_result;
    wire mult_ready, mult_execption;
    
    mult multiplier (
        .clk(clock),
        .A(data_operandA),
        .B(data_operandB),
        .interrupt(ctrl_DIV),
        .ctrl_MULT(ctrl_MULT),
        .result(mult_result),
        .ready(mult_ready),
        .exception(mult_execption)
    );

    wire [31:0] div_result;
    wire div_ready, div_execption;
    
    div divider (
        .clk(clock),
        .A(data_operandA),
        .B(data_operandB),
        .interrupt(ctrl_MULT),
        .ctrl_DIV(ctrl_DIV),
        .result(div_result),
        .ready(div_ready),
        .exception(div_execption)
    );
    
    assign data_result = mult_ready ? mult_result : div_result;
    assign data_resultRDY = mult_ready | div_ready;
    assign data_exception = mult_ready ? mult_execption : div_execption;

endmodule