module regfile (
	clock,
	ctrl_writeEnable, ctrl_reset, ctrl_writeReg,
	ctrl_readRegA, ctrl_readRegB, data_writeReg,
	data_readRegA, data_readRegB
);

	input clock, ctrl_writeEnable, ctrl_reset;
	input [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
	input [31:0] data_writeReg;

	output [31:0] data_readRegA, data_readRegB;

	// add your code here
	wire [31:0] writeSel;
	wire [31:0] readSelA;
	wire [31:0] readSelB;
	wire [31:0] reg_q [31:0];
	assign writeSel = ctrl_writeEnable ? (32'b1 << ctrl_writeReg) : 32'b0;
	assign readSelA = (32'b1 << ctrl_readRegA);
	assign readSelB = (32'b1 << ctrl_readRegB);

	assign reg_q[0] = 32'b0;

	genvar i;
	generate
		for (i = 1; i < 32; i = i + 1) begin
			register r(reg_q[i], data_writeReg, clock, writeSel[i], ctrl_reset);
		end
	endgenerate

	generate
		for (i = 0; i < 32; i = i + 1) begin
			assign data_readRegA = readSelA[i] ? reg_q[i] : 32'bz;
			assign data_readRegB = readSelB[i] ? reg_q[i] : 32'bz;
		end
	endgenerate
endmodule
