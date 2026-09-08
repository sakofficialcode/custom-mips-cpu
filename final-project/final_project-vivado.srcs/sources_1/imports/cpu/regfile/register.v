module register (output [31:0] q, input [31:0] d, input clk, input en, input clr);
	genvar b;
	generate
		for (b = 0; b < 32; b = b + 1) begin : bits
			dffe_ref dff (q[b], d[b], clk, en, clr);
		end
	endgenerate
endmodule
