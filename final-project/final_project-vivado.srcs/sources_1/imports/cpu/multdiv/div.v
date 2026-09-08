module div(
    input clk, 
    input [31:0] A, 
    input [31:0] B, 
    input ctrl_DIV,
    input interrupt,
    output [31:0] result,
    output ready,
    output exception
);

    wire [31:0] counter, counterd;
    wire [31:0] M, Md;
    wire [31:0] R, Rd;
    wire [31:0] Q, Qd;

    wire en_run;
    wire counter_zero;
    
    assign counter_zero = ~(|counter);
    assign en_run = ~counter_zero;
    
    assign counterd = ctrl_DIV ? 32'hFFFFFFFF : {1'b0, counter[31:1]};

    wire [31:0] newR, newQ;

    wire Aneg, Bneg;
    dffe_ref Aneg_reg (.q(Aneg), .d(ctrl_DIV ? A[31] : Aneg),  .clk(clk), .en(en_run | ctrl_DIV), .clr(1'b0));
    dffe_ref Bneg_reg (.q(Bneg), .d(ctrl_DIV ? B[31] : Bneg),    .clk(clk), .en(en_run | ctrl_DIV), .clr(1'b0));

    wire interrupt_val;
    dffe_ref interrupt_reg (.q(interrupt_val), .d(ctrl_DIV ? 1'b0 : (interrupt_val | interrupt)),  .clk(clk), .en(en_run | ctrl_DIV), .clr(1'b0));

    wire [31:0] Aminus, Bminus;
    negate negateA(A,Aminus);
    negate negateB(B,Bminus);
    
    assign Md = ctrl_DIV ? (B[31] ? Bminus : B) : M;
    assign Rd = ctrl_DIV ? 32'd0 : newR;
    assign Qd = ctrl_DIV ? (A[31] ? Aminus : A) : newQ;

    register M_reg (.q(M), .d(Md),  .clk(clk), .en(en_run | ctrl_DIV), .clr(1'b0));
    register R_reg (.q(R),   .d(Rd),    .clk(clk), .en(en_run | ctrl_DIV), .clr(1'b0));
    register Q_reg (.q(Q),   .d(Qd),    .clk(clk), .en(en_run | ctrl_DIV), .clr(1'b0));
    register cnt_reg (.q(counter), .d(counterd), .clk(clk), .en(en_run | ctrl_DIV), .clr(1'b0));

    div_datapath dp (.clk(clk), .M(M), .A(R), .Q(Q), .newA(newR), .newQ(newQ), .overflow());

    wire [31:0] Resminus;
    negate negateRes(Q,Resminus);
    
    assign result = (Aneg ^ Bneg) ? Resminus : Q;
    wire was_running;
    dffe_ref running_reg (.q(was_running), .d(en_run), .clk(clk), .en(1'b1), .clr(1'b0));
    assign ready = was_running & counter_zero & !interrupt_val;

    assign exception = !(|M);

endmodule

module div_datapath(
    input clk, 
    input [31:0] M,
    input [31:0] A,
    input [31:0] Q,
    output [31:0] newA,
    output [31:0] newQ,
    output overflow
);

    cla cla_add (.in1(A[31] ? M : ~M), .in2({A[30:0],Q[31]}), .c_in(A[31] ? 1'b0 : 1'b1), .sum(newA), .overflow());
    assign newQ = {Q[30:0],!newA[31]};

    assign overflow = 1'b0;

endmodule

module negate(input [31:0] A, output [31:0] negA);
    cla cla_add (.in1(~A), .in2(32'b0), .c_in(1'b1), .sum(negA),.overflow());
endmodule