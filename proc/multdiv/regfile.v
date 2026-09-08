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

	wire [31:0] WE, RegA, RegB;
	wire [31:0] registerOuts [31:0];

	assign WE = ctrl_writeEnable << ctrl_writeReg;

	register reg_zero(.clock(clock), .out(registerOuts[0]), .in(data_writeReg), .enable(1'b0), .reset(ctrl_reset));
	
	genvar i;
	generate
		for (i = 1; i < 32; i = i + 1) begin: register_loop
			register regs(.clock(clock), .out(registerOuts[i]), .in(data_writeReg), .enable(WE[i]), .reset(ctrl_reset));
		end
	endgenerate

	assign RegA = 32'b1 << ctrl_readRegA;
	assign RegB = 32'b1 << ctrl_readRegB;

	genvar j;
	generate
		for (j = 0; j < 32; j = j + 1) begin: out_loop
			assign data_readRegA = RegA[j] ? registerOuts[j] : 32'bz;
			assign data_readRegB = RegB[j] ? registerOuts[j] : 32'bz;
		end
	endgenerate

endmodule