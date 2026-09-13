module register #(parameter WIDTH = 32)(
    clock, out, in, enable, reset
);

    input clock, enable, reset;
    input [WIDTH - 1:0] in;
    output [WIDTH - 1:0] out;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: dff_loop
            dffe_ref dff(out[i], in[i], clock, enable, reset);
        end
    endgenerate

endmodule