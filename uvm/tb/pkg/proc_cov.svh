class proc_cov extends uvm_subscriber #(exec_item);
    `uvm_component_utils(proc_cov)

    exec_item t;

    covergroup cg_insn;
        type_option.merge_instances = 1;
        cp_op: coverpoint t.op;
        cp_exc: coverpoint t.exception iff (t.exception != 0){
            bins add  = {1};
            bins addi = {2};
            bins sub  = {3};
            bins mul  = {4};
            bins div  = {5};
        }
        cp_dist_rs: coverpoint t.dist_rs iff (t.op != SETX){
            bins d1   = {1};
            bins d2   = {2};
            bins d3   = {3};
            bins none = {4};
        }
        cp_dist_rt: coverpoint t.dist_rt iff (!(t.op inside {SETX, BEX, ADDI, SLL, SRA, SW, LW})){
            bins d1   = {1};
            bins d2   = {2};
            bins d3   = {3};
            bins none = {4};
        }
        
        op_x_dist_rs: cross cp_op, cp_dist_rs {
            ignore_bins excl = binsof(cp_op) intersect {SETX};
        }
        cp_prod_lw: coverpoint t.prod_lw iff (t.dist_rs == 1 && t.op != SETX){
            bins lw = {1};
            bins not_lw = {0};
        }

        cp_bex: coverpoint t.bex_taken iff (t.op == BEX){
            bins taken = {1};
            bins not_taken = {0};
        }

        bex_x_dist_rs: cross cp_bex, cp_dist_rs;

        cp_a: coverpoint t.a iff (t.op inside {ADD, SUB, MUL, DIV, AND, OR, SLL, SRA}){
            bins INT_MIN = {32'h80000000};
            bins neg_one = {32'hFFFFFFFF};
            bins zero    = {32'h0};
            bins one     = {32'h1};
            bins INT_MAX = {32'h7FFFFFFF};
        }
        cp_b: coverpoint t.b iff (t.op inside {ADD, SUB, MUL, DIV, AND, OR}){
            bins INT_MIN = {32'h80000000};
            bins neg_one = {32'hFFFFFFFF};
            bins zero    = {32'h0};
            bins one     = {32'h1};
            bins INT_MAX = {32'h7FFFFFFF};
        }
        op_x_a_x_b: cross cp_op, cp_a, cp_b {
            ignore_bins excl = binsof(cp_op) intersect {AND, OR, SETX, BEX, ADDI, SLL, SRA, SW, LW};
        }
        

    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_insn = new();
    endfunction

    function void write(exec_item t);
        this.t = t;
        cg_insn.sample();
    endfunction


endclass
