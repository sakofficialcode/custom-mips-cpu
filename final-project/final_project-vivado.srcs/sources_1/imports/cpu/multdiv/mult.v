module mult(
    input clk, 
    input [31:0] A,
    input [31:0] B, 
    input ctrl_MULT,
    input interrupt,
    output [31:0] result,
    output ready,
    output exception
);

    wire [31:0] counter, counterd;
    wire [31:0] mult, multd;
    wire [31:0] hi, hid;
    wire [31:0] lo, lod;
    wire [31:0] a, b;
    wire q, qd;
    wire overflow_latched, overflow_d;

    wire en_run;
    wire counter_zero;
    
    assign counter_zero = ~(|counter);
    assign en_run = ~counter_zero;

    wire interrupt_val;
    dffe_ref interrupt_reg (.q(interrupt_val), .d(ctrl_MULT ? 1'b0 : (interrupt_val | interrupt)),  .clk(clk), .en(en_run | ctrl_MULT), .clr(1'b0));
    
    assign counterd = ctrl_MULT ? 32'hFFFFFFFF : {1'b0, counter[31:1]};

    wire [31:0] newhi, newlo;
    wire newq, dp_overflow;
    
    assign multd = ctrl_MULT ? A : mult;
    assign hid = ctrl_MULT ? 32'd0 : newhi;
    assign lod = ctrl_MULT ? B : newlo;
    assign qd = ctrl_MULT ? 1'b0 : newq;
    assign overflow_d = ctrl_MULT ? 1'b0 : (overflow_latched | dp_overflow);

    register A_reg     (.q(a), .d(ctrl_MULT ? A : a),  .clk(clk), .en(en_run | ctrl_MULT), .clr(1'b0));
    register B_reg     (.q(b), .d(ctrl_MULT ? B : b),  .clk(clk), .en(en_run | ctrl_MULT), .clr(1'b0));
    register mult_reg  (.q(mult), .d(multd),  .clk(clk), .en(en_run | ctrl_MULT), .clr(1'b0));
    register hi_reg    (.q(hi),   .d(hid),    .clk(clk), .en(en_run | ctrl_MULT), .clr(1'b0));
    register lo_reg    (.q(lo),   .d(lod),    .clk(clk), .en(en_run | ctrl_MULT), .clr(1'b0));
    register cnt_reg   (.q(counter), .d(counterd), .clk(clk), .en(en_run | ctrl_MULT), .clr(1'b0));
    dffe_ref overflow_reg (.q(overflow_latched), .d(overflow_d), .clk(clk), .en(en_run | ctrl_MULT), .clr(1'b0));

    dffe_ref qreg (.q(q), .d(qd), .clk(clk), .en(en_run | ctrl_MULT), .clr(1'b0));

    booth_datapath dp (.clk(clk), .mult(mult), .hi(hi), .lo(lo), .q(q), .newhi(newhi), .newlo(newlo), .newq(newq), .overflow(dp_overflow));
    
    assign result = lo;
    wire was_running;
    dffe_ref running_reg (.q(was_running), .d(en_run), .clk(clk), .en(1'b1), .clr(1'b0));
    assign ready = was_running & counter_zero & !interrupt_val;

    wire mismatch;
    assign mismatch = |(hi ^ {32{lo[31]}});
    wire special;
    assign special = (~|a[30:0]) & a[31] & (~|b[31:1]) & b[0];
    wire special2;
    assign special2 = (~|a[30:0]) & a[31] & &b;
    assign exception = ready & ((mismatch & ~special) | special2); //| ((~|a[30:0]) & a[31] & (|b[31:1] | ~b[0])));//(overflow_latched | dp_overflow) |

endmodule

module booth_datapath(
    input clk, 
    input [31:0] mult,
    input [31:0] hi,
    input [31:0] lo,
    input q,
    output [31:0] newhi,
    output [31:0] newlo,
    output newq,
    output overflow
);

    wire is_01, is_10;
    assign is_01 = ~lo[0] & q;
    assign is_10 = lo[0] & ~q;

    wire [31:0] add_in;
    assign add_in = is_01 ? mult : (is_10 ? ~mult : 32'b0);

    wire cin;
    assign cin = is_10;

    wire [31:0] hi_updated;
    cla cla_add (.in1(hi), .in2(add_in), .c_in(cin), .sum(hi_updated), .overflow(overflow));

    assign newhi = {hi_updated[31], hi_updated[31:1]};
    assign newlo = {hi_updated[0], lo[31:1]};
    assign newq = lo[0];

endmodule