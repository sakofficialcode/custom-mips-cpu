`timescale 1ns / 1ps
/**
 * 
 * READ THIS DESCRIPTION:
 *
 * This is the Wrapper module that will serve as the header file combining your processor, 
 * RegFile and Memory elements together.
 *
 * This file will be used to generate the bitstream to upload to the FPGA.
 * We have provided a sibling file, Wrapper_tb.v so that you can test your processor's functionality.
 * 
 * We will be using our own separate Wrapper_tb.v to test your code. You are allowed to make changes to the Wrapper files 
 * for your own individual testing, but we expect your final processor.v and memory modules to work with the 
 * provided Wrapper interface.
 * 
 * Refer to Lab 5 documents for detailed instructions on how to interface 
 * with the memory elements. Each imem and dmem modules will take 12-bit 
 * addresses and will allow for storing of 32-bit values at each address. 
 * Each memory module should receive a single clock. At which edges, is 
 * purely a design choice (and thereby up to you). 
 * 
 * You must change line 36 to add the memory file of the test you created using the assembler
 * For example, you would add sample inside of the quotes on line 38 after assembling sample.s
 *
 **/

module Wrapper (
    input clk_100mhz,
	input BTNC,
    input BTNU,
	input BTNL,
	input BTNR,
    input [15:0] SW,
    output reg [15:0] LED, output[8:0] servos,
	output hSync,
	output vSync,
	output[3:0] VGA_R,
	output[3:0] VGA_G,
	output[3:0] VGA_B
	);
    wire clock, reset;
    assign reset = BTNU; 
	wire rwe, mwe;
	wire[4:0] rd, rs1, rs2;
	wire[31:0] instAddr, instData,
		rData, regA, regB,
		memAddr, memDataIn, memDataOut, data;
	wire[31:0] ram_dataOut;
    reg [15:0] SW_Q, SW_M;

    reg [31:0] ms_counter  = 32'd0;
	reg [14:0] ms_prescale = 15'd0;
    always @(posedge clock) begin
        if (reset) begin
            ms_counter  <= 32'd0;
            ms_prescale <= 15'd0;
        end else if (ms_prescale >= 25000 - 1) begin
            ms_prescale <= 15'd0;
            ms_counter  <= ms_counter + 32'd1;
        end else begin
            ms_prescale <= ms_prescale + 15'd1;
        end
    end
    
    localparam n_servos  = 9;

    wire [1:0] selected;
    assign memDataOut = (memAddr == 32'd4096) ? ms_counter :
                        (memAddr == 32'd4097) ? {31'b0, BTNC}  :
                        (memAddr == 32'd4098) ? {30'b0, selected} :
                                                ram_dataOut;

    clk_wiz_0 pll (.clk_out1(clock),.reset(reset),.locked(),.clk_in1(clk_100mhz));

    reg [9:0] duty [0:n_servos-1];
    integer si;
    initial for (si = 0; si < n_servos; si = si + 1) duty[si] = 10'd0;

    wire [31:0] servo_off   = memAddr - 32'd4100;
    always @(posedge clock) begin
        if (mwe && (servo_off < n_servos*4) && (servo_off[1:0] == 2'b00))
            duty[servo_off[5:2]] <= memDataIn[9:0];
    end

    genvar gi;
    generate for (gi = 0; gi < n_servos; gi = gi + 1) begin : servo_gen
        PWMSerializer #(.PERIOD_WIDTH_NS(20000000), .SYS_FREQ_MHZ(25))
            S(clock, 1'b0, duty[gi], servos[gi]);
    end endgenerate

	// ADD YOUR MEMORY FILE HERE
	localparam INSTR_FILE = "guitar";
	
	// Main Processing Unit
	processor CPU(.clock(clock), .reset(reset), 
								
		// ROM
		.address_imem(instAddr), .q_imem(instData),
									
		// Regfile
		.ctrl_writeEnable(rwe),     .ctrl_writeReg(rd),
		.ctrl_readRegA(rs1),     .ctrl_readRegB(rs2), 
		.data_writeReg(rData), .data_readRegA(regA), .data_readRegB(regB),
									
		// RAM
		.wren(mwe), .address_dmem(memAddr), 
		.data(memDataIn), .q_dmem(memDataOut)); 
	
	// Instruction Memory (ROM)
	ROM #(.MEMFILE({INSTR_FILE, ".mem"}))
	InstMem(.clk(clock), 
		.addr(instAddr[11:0]), 
		.dataOut(instData));
	
	// Register File
	regfile RegisterFile(.clock(clock), 
		.ctrl_writeEnable(rwe), .ctrl_reset(reset), 
		.ctrl_writeReg(rd),
		.ctrl_readRegA(rs1), .ctrl_readRegB(rs2), 
		.data_writeReg(rData), .data_readRegA(regA), .data_readRegB(regB));
						
	// Processor Memory (RAM)
	wire ram_wEn = mwe & (memAddr[31:12] == 20'd0);
	RAM #(.MEMFILE("song.mem"))
	ProcMem(.clk(clock),
		.wEn(ram_wEn),
		.addr(memAddr[11:0]),
		.dataIn(memDataIn),
		.dataOut(ram_dataOut));
		
	VGAController vga(.clk(clock), .reset(reset), .hSync(hSync), .vSync(vSync), .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B), .BTNC(BTNC), .BTNL(BTNL), .BTNR(BTNR), .selected_out(selected));

endmodule
