class exec_item extends uvm_sequence_item;
    `uvm_object_utils(exec_item)


    op_e        op;
    bit  [ 4:0] rd,        rs,      rt;
    bit  [31:0] a,         b,       result;
    bit  [31:0] exception;
    bit         bex_taken;
    int         dist_rs,   dist_rt;
    bit         prod_lw;

    function new(string name = "exec_item");
        super.new(name);
    endfunction

    function string convert2string();
        case (op)
            BEX:     return $sformatf("%s r%0d a=%0d taken=%0d dist_rs=%0d", op.name(),rs, $signed(a), bex_taken, dist_rs);
            default: return $sformatf("%s r%0d, r%0d, r%0d a=%0d b=%0d result=%0d exception=%0d dist_rs=%0d dist_rt=%0d lw=%0d", op.name(),rd, rs, rt, $signed(a), $signed(b), $signed(result), exception, dist_rs, dist_rt, prod_lw);
        endcase

    endfunction



endclass
