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

    wire [31:0] nop;
    assign nop = 32'b0;

    wire stall, stall_lw, stall_multdiv;
    //assign stall = 1'b0;

	
    // FETCH

    wire [31:0] fdpc_out;
    wire [31:0] pcIncremented;

    wire branch;
    wire [31:0] branch_address;

    assign branch = (x_isBNE & x_isNE) | (x_isBLT & x_isLT);
    assign branch_address = x_Branch;

    alu pcIncrement(.data_operandA( fdpc_out), .data_operandB(32'b1), .ctrl_ALUopcode(5'b0), .ctrl_shiftamt(5'b0), .data_result(pcIncremented), .isNotEqual(), .isLessThan(), .overflow());

    wire [31:0] nextPC;
    wire BEXTaken, x_isJ, x_isJAL, x_isJR;
    assign BEXTaken = d_isBEX & ((|(32'b0^data_readRegA)) | ~|(5'b10101^dxinsn_out[31:27]) | (~|(5'b11110^m_rd) & x_bypass_m_we) | (~|(5'b11110^m_rd) & ctrl_writeEnable));
    assign nextPC = BEXTaken ? {{5'b0}, fdinsn_out[26:0]} : (x_isJ | x_isJAL) ? {{5'b0}, dxinsn_out[26:0]} : x_isJR ? x_a_bypass : branch ? branch_address : pcIncremented;

    register #(.WIDTH(32)) FD_PC (.clock(~clock), .reset(reset), .enable(~stall), .in(nextPC), .out(fdpc_out));

    assign address_imem = fdpc_out;

    wire [31:0] fdinsn_out;
    register #(.WIDTH(32)) FD_INSN (.clock(~clock), .reset(reset), .enable(~stall), .in((BEXTaken | x_isJ | x_isJAL | x_isJR | branch) ? nop : q_imem), .out(fdinsn_out));

    // DECODE

    wire d_isSW, d_isBEX, d_isJR, d_isBNE, d_isBLT, d_flush;
    assign d_isSW = ~|(5'b00111^fdinsn_out[31:27]);
    assign d_isBEX = ~|(5'b10110^fdinsn_out[31:27]);
    assign d_isJR = ~|(5'b00100^fdinsn_out[31:27]);
    assign d_isBNE = ~|(5'b00010^fdinsn_out[31:27]);
    assign d_isBLT = ~|(5'b00110^fdinsn_out[31:27]);


    // Decode   
    assign ctrl_readRegA = d_isBEX ? 5'b11110 : (d_isJR | d_isBNE | d_isBLT) ? fdinsn_out[26:22] : fdinsn_out[21:17];
    assign ctrl_readRegB = d_isSW ? fdinsn_out[26:22] : (d_isBNE | d_isBLT) ? fdinsn_out[21:17] : fdinsn_out[16:12];

    // Latch
    wire [31:0] dxa_out;
    register #(.WIDTH(32)) DX_A (.clock(~clock), .reset(reset), .enable(~stall), .in(data_readRegA), .out(dxa_out));

    wire [31:0] dxb_out;
    register #(.WIDTH(32)) DX_B (.clock(~clock), .reset(reset), .enable(~stall), .in(data_readRegB), .out(dxb_out));

    wire [31:0] dxinsn_out;
    register #(.WIDTH(32)) DX_INSN (.clock(~clock), .reset(reset), .enable(~stall_multdiv), .in((x_isJ | x_isJAL | x_isJR | branch | stall_lw) ? nop : fdinsn_out), .out(dxinsn_out));

    wire [31:0] dxpc_out;
    register #(.WIDTH(32)) DX_PC (.clock(~clock), .reset(reset), .enable(~stall), .in(fdpc_out), .out(dxpc_out));

    // EXECUTE

    wire x_isI, x_isBNE, x_isBLT, x_isALU, x_isMult, x_isDiv, x_isLW, x_isSW;
    assign x_isI = ~|(5'b00101 ^ dxinsn_out[31:27]) | ~|(5'b01000 ^ dxinsn_out[31:27]) | ~|(5'b00111 ^ dxinsn_out[31:27]);
    assign x_isJ = ~|(5'b00001^dxinsn_out[31:27]);
    assign x_isJAL = ~|(5'b00011^dxinsn_out[31:27]);
    assign x_isJR = ~|(5'b00100^dxinsn_out[31:27]);
    assign x_isBNE = ~|(5'b00010^dxinsn_out[31:27]);
    assign x_isBLT = ~|(5'b00110^dxinsn_out[31:27]);
    assign x_isALU = ~|(5'b00000^dxinsn_out[31:27]);
    assign x_isMult = x_isALU & ~|(5'b00110^dxinsn_out[6:2]);
    assign x_isDiv = x_isALU & ~|(5'b00111^dxinsn_out[6:2]);
    assign x_isLW = ~|(5'b01000^dxinsn_out[31:27]);
    assign x_isSW = ~|(5'b00111^dxinsn_out[31:27]);

    wire [4:0] aluOp;
    assign aluOp = dxinsn_out[6:2];

    wire [31:0] aluOut, x_Branch;
    wire x_isNE, x_isLT, x_overflow;
    wire [31:0] immediate;
    assign immediate = {{15{dxinsn_out[16]}}, dxinsn_out[16:0]};

    wire [31:0] x_a_bypass, x_b_bypass;
    wire x_bypass_m_we;
    
    wire [4:0] x_rs1, m_rd;
    assign x_rs1 = (x_isBNE | x_isBLT | x_isJR) ? dxinsn_out[26:22] : dxinsn_out[21:17];
    assign m_rd = (m_isSETX | |xmexception_out) ? 5'b11110 : m_isJAL ? 5'b11111 : xminsn_out[26:22];
    assign x_bypass_m_we = ~|(5'b00000^xminsn_out[31:27]) | ~|(5'b00101^xminsn_out[31:27]) | m_isJAL | m_isSETX | m_isLW | |(xmexception_out);
    assign x_a_bypass = ((~|(x_rs1^m_rd) & x_bypass_m_we) & |x_rs1) ? (|(xmexception_out) ? xmexception_out : xmo_out): ((~|(x_rs1^ctrl_writeReg) & ctrl_writeEnable) & |x_rs1) ? data_writeReg : dxa_out;

    wire [4:0] x_rs2;
    assign x_rs2 = (x_isBNE | x_isBLT) ? dxinsn_out[21:17] : x_isSW ? dxinsn_out[26:22] : dxinsn_out[16:12];
    assign x_b_bypass = ((~|(x_rs2^m_rd) & x_bypass_m_we) & |x_rs2) ? (|(xmexception_out) ? xmexception_out : xmo_out) : ((~|(x_rs2^ctrl_writeReg) & ctrl_writeEnable) & |x_rs2) ? data_writeReg : dxb_out;

    alu ALU(.data_operandA(x_isJAL ? dxpc_out : x_a_bypass), .data_operandB(x_isI ? immediate : x_isJAL ? 32'b0 : x_b_bypass), .ctrl_ALUopcode((x_isI | x_isJAL) ? 5'b0 : aluOp), .ctrl_shiftamt(dxinsn_out[11:7]), .data_result(aluOut), .isNotEqual(x_isNE), .isLessThan(x_isLT), .overflow(x_overflow));

    alu XBRANCH(.data_operandA(dxpc_out), .data_operandB(immediate), .ctrl_ALUopcode(5'b0), .ctrl_shiftamt(5'b0), .data_result(x_Branch), .isNotEqual(), .isLessThan(), .overflow());

    wire [31:0] multdiv_out;
    wire multdiv_busy, multdiv_ready, multdiv_exception;

    dffe_ref multdivDff(.q(multdiv_busy), .d(1'b1), .clk(clock), .en((x_isMult | x_isDiv) & ~multdiv_busy), .clr(multdiv_ready));

    assign stall_multdiv = ((x_isMult | x_isDiv) | multdiv_busy) & ~multdiv_ready;

    wire ctrl_MULT, ctrl_DIV;
    assign ctrl_MULT = x_isMult & ~multdiv_busy & ~multdiv_ready;
    assign ctrl_DIV = x_isDiv & ~multdiv_busy & ~multdiv_ready;

    multdiv MULTDIV(.data_operandA(x_a_bypass), .data_operandB(x_b_bypass), .ctrl_MULT(ctrl_MULT), .ctrl_DIV(ctrl_DIV), .clock(clock), .data_result(multdiv_out), .data_exception(multdiv_exception), .data_resultRDY(multdiv_ready));

    wire [31:0] x_exception;
    assign x_exception = x_overflow ? x_isI ? 32'h00000002 : ~|(5'b0^aluOp) ? 32'h00000001 : ~|(5'b00001^aluOp) ? 32'h00000003 :  32'b0 : (multdiv_exception & multdiv_ready) ? ~|(5'b00110^aluOp) ? 32'h00000004 : ~|(5'b00111^aluOp) ? 32'h00000005 : 32'b0  : 32'b0;

    assign stall_lw = x_isLW & (~|(ctrl_readRegA^dxinsn_out[26:22]) | (~|(ctrl_readRegB^dxinsn_out[26:22]) & ~d_isSW)) & |(dxinsn_out[26:22]);

    assign stall = stall_multdiv | stall_lw;

    // Latch
    wire [31:0] xmo_out;
    register #(.WIDTH(32)) XM_O (.clock(~clock), .reset(reset), .enable(1'b1), .in((multdiv_ready & (x_isMult | x_isDiv | multdiv_busy)) ? multdiv_out : aluOut), .out(xmo_out));

    wire [31:0] xmb_out;
    register #(.WIDTH(32)) XM_B (.clock(~clock), .reset(reset), .enable(1'b1), .in(x_b_bypass), .out(xmb_out));

    wire [31:0] xminsn_out;
    register #(.WIDTH(32)) XM_INSN (.clock(~clock), .reset(reset), .enable(1'b1), .in(stall_multdiv ? nop : dxinsn_out), .out(xminsn_out));

    wire [31:0] xmexception_out;
    register #(.WIDTH(32)) XM_EXCEPTION (.clock(~clock), .reset(reset), .enable(1'b1), .in(x_exception), .out(xmexception_out));

    // MEMORY

    assign address_dmem = xmo_out;
    assign data = ((~|(xminsn_out[26:22]^ctrl_writeReg) & m_isSW & ctrl_writeEnable) & |ctrl_writeReg) ? data_writeReg: xmb_out;
    assign wren = ~|(5'b00111^xminsn_out[31:27]);

    wire m_isJAL, m_isSETX, m_isLW, m_isSW;
    assign m_isJAL = ~|(5'b00011^xminsn_out[31:27]);
    assign m_isSETX = ~|(5'b10101^xminsn_out[31:27]);
    assign m_isLW = ~|(5'b01000^xminsn_out[31:27]);
    assign m_isSW = ~|(5'b00111^xminsn_out[31:27]);

    wire [31:0] mwo_out;
    register #(.WIDTH(32)) MW_O (.clock(~clock), .reset(reset), .enable(1'b1), .in(xmo_out), .out(mwo_out));

    wire [31:0] mwd_out;
    register #(.WIDTH(32)) MW_D (.clock(~clock), .reset(reset), .enable(1'b1), .in(q_dmem), .out(mwd_out));

    wire [31:0] mwinsn_out;
    register #(.WIDTH(32)) MW_INSN (.clock(~clock), .reset(reset), .enable(1'b1), .in(xminsn_out), .out(mwinsn_out));

    wire [31:0] mwexception_out;
    register #(.WIDTH(32)) MW_EXCEPTION (.clock(~clock), .reset(reset), .enable(1'b1), .in(xmexception_out), .out(mwexception_out));

    // WRITEBACK
    wire w_isJAL, w_isSETX, w_isLW, w_isException;
    assign w_isJAL = ~|(5'b00011^mwinsn_out[31:27]);
    assign w_isSETX = ~|(5'b10101^mwinsn_out[31:27]);
    assign w_isLW = ~|(5'b01000^mwinsn_out[31:27]);
    assign w_isException = |(mwexception_out);

    assign ctrl_writeReg = (w_isSETX | w_isException) ? 5'b11110 : w_isJAL ? 5'b11111 : mwinsn_out[26:22];

    assign data_writeReg = w_isException ? mwexception_out : w_isSETX ? {{5'b0},mwinsn_out[26:0]} : w_isLW ? mwd_out : mwo_out;
    //assign data_writeReg = w_isSETX ? 32'b1 : mwo_out;

    assign ctrl_writeEnable = ~|(5'b00000^mwinsn_out[31:27]) | ~|(5'b00101^mwinsn_out[31:27]) | w_isJAL | w_isSETX | w_isLW | w_isException;



	/* END CODE */

endmodule
