module tff (
    t, clock, reset, q
);
    input t, clock, reset;
    output q;

    wire d;
    assign d = (t & ~q) | (~t & q);

    dffe_ref dff(.q(q), .d(d), .clk(clock), .en(1'b1), .clr(reset));
endmodule