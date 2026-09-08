module register(
    clock, out, in, enable, reset
);

    input clock, enable, reset;
    input [31:0] in;
    output [31:0] out;

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin: dff_loop
            dffe_ref dff(out[i], in[i], clock, enable, reset);
        end
    endgenerate

endmodule