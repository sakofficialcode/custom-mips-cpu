/**
 * READ THIS DESCRIPTION!
 *
 * This is your processor module that will contain the bulk of your code submission. You are to implement
 * a 5-stage pipelined processor in this module, accounting for hazards and implementing bypasses as
 * necessary.
 *
 * Ultimately, your processor will be tested by a master skeleton, so the
 * testbench can see which controls signal you active when. Therefore, there needs to be a way to
 * "inject" imem, dmem, and regfile interfaces from some external controller module. The skeleton
 * file, Wrapper.v, acts as a small wrapper around your processor for this purpose. Refer to Wrapper.v
 * for more details.
 *
 * As a result, this module will NOT contain the RegFile nor the memory modules. Study the inputs 
 * very carefully - the RegFile-related I/Os are merely signals to be sent to the RegFile instantiated
 * in your Wrapper module. This is the same for your memory elements. 
 *
 *
 */
module processor(
    // Control signals
    clock,                          // I: The master clock
    reset,                          // I: A reset signal

    // Imem
    address_imem,                   // O: The address of the data to get from imem
    q_imem,                         // I: The data from imem

    // Dmem
    address_dmem,                   // O: The address of the data to get or put from/to dmem
    data,                           // O: The data to write to dmem
    wren,                           // O: Write enable for dmem
    q_dmem,                         // I: The data from dmem

    // Regfile
    ctrl_writeEnable,               // O: Write enable for RegFile
    ctrl_writeReg,                  // O: Register to write to in RegFile
    ctrl_readRegA,                  // O: Register to read from port A of RegFile
    ctrl_readRegB,                  // O: Register to read from port B of RegFile
    data_writeReg,                  // O: Data to write to for RegFile
    data_readRegA,                  // I: Data from port A of RegFile
    data_readRegB                   // I: Data from port B of RegFile
	 
	);

	// Control signals
	input clock, reset;
	
	// Imem
    output [31:0] address_imem;
	input [31:0] q_imem;

	// Dmem
	output [31:0] address_dmem, data;
	output wren;
	input [31:0] q_dmem;

	// Regfile
	output ctrl_writeEnable;
	output [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
	output [31:0] data_writeReg;
	input [31:0] data_readRegA, data_readRegB;

	/* YOUR CODE STARTS HERE */
	
    // FETCH

    wire [31:0] fdpc_out;
    wire [31:0] pcIncremented;

    alu pcIncrement(.data_operandA(fdpc_out), .data_operandB(32'b1), .ctrl_ALUopcode(5'b0), .ctrl_shiftamt(5'b0), .data_result(pcIncremented), .isNotEqual(), .isLessThan(), .overflow());

    
    register #(.WIDTH(32)) FD_PC (.clock(clock), .reset(reset), .enable(1'b1), .in(pcIncremented), .out(fdpc_out));

    assign address_imem = fdpc_out;

    wire [31:0] fdinsn_out;
    register #(.WIDTH(32)) FD_INSN (.clock(~clock), .reset(reset), .enable(1'b1), .in(q_imem), .out(fdinsn_out));

    // DECODE

    // Decode
    assign ctrl_readRegA = fdinsn_out[21:17];
    assign ctrl_readRegB = fdinsn_out[16:12];

    // Latch
    wire [31:0] dxa_out;
    register #(.WIDTH(32)) DX_A (.clock(~clock), .reset(reset), .enable(1'b1), .in(data_readRegA), .out(dxa_out));

    wire [31:0] dxb_out;
    register #(.WIDTH(32)) DX_B (.clock(~clock), .reset(reset), .enable(1'b1), .in(data_readRegB), .out(dxb_out));

    wire [31:0] dxinsn_out;
    register #(.WIDTH(32)) DX_INSN (.clock(~clock), .reset(reset), .enable(1'b1), .in(fdinsn_out), .out(dxinsn_out));

    // EXECUTE

    wire isI;
    assign isI = ~|(5'b00101 ^ dxinsn_out[31:27]);

    wire [31:0] aluOut;
    wire [31:0] immediate;
    assign immediate = {{15{dxinsn_out[16]}}, dxinsn_out[16:0]};

    alu ALU(.data_operandA(dxa_out), .data_operandB(isI ? immediate : dxb_out), .ctrl_ALUopcode(isI ? 5'b0 : dxinsn_out[6:2]), .ctrl_shiftamt(dxinsn_out[11:7]), .data_result(aluOut), .isNotEqual(), .isLessThan(), .overflow());

    wire [31:0] xmo_out;
    register #(.WIDTH(32)) XM_O (.clock(~clock), .reset(reset), .enable(1'b1), .in(aluOut), .out(xmo_out));

    wire [31:0] xmb_out;
    register #(.WIDTH(32)) XM_B (.clock(~clock), .reset(reset), .enable(1'b1), .in(dxb_out), .out(xmb_out));

    wire [31:0] xminsn_out;
    register #(.WIDTH(32)) XM_INSN (.clock(~clock), .reset(reset), .enable(1'b1), .in(dxinsn_out), .out(xminsn_out));

    // MEMORY

    // placeholder
    wire [31:0] memory_out;
    assign memory_out = xmb_out;

    wire [31:0] mwo_out;
    register #(.WIDTH(32)) MW_O (.clock(~clock), .reset(reset), .enable(1'b1), .in(xmo_out), .out(mwo_out));

    wire [31:0] mwd_out;
    register #(.WIDTH(32)) MW_D (.clock(~clock), .reset(reset), .enable(1'b1), .in(memory_out), .out(mwd_out));

    wire [31:0] mwinsn_out;
    register #(.WIDTH(32)) MW_INSN (.clock(~clock), .reset(reset), .enable(1'b1), .in(xminsn_out), .out(mwinsn_out));

    // WRITEBACK
    assign ctrl_writeReg = mwinsn_out[26:22];

    assign data_writeReg = mwo_out;

    assign ctrl_writeEnable = 1'b1;



	/* END CODE */

endmodule
