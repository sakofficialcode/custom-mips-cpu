class prog_gen extends uvm_object;
    `uvm_object_utils(prog_gen)

    int unsigned n_body = 50;

    prog_image img;
    int unsigned pc;
    bit [4:0] history[$];

    function new(string name = "prog_gen");
        super.new(name);
    endfunction

    function void emit(bit [31:0] word, string asm);
        img.words[pc] = word;
        $display("PROG %4d  %08h  %s", pc, word, asm);
        pc++;
    endfunction

    function void rem(bit [4:0] rd);
        history.push_front(rd);
        if (history.size() > 3)
            history.pop_back();
    endfunction

    function prog_image build_prog();
        insn_item insn;
        int d;
        bit corner;

        img = prog_image::type_id::create("img");
        insn = insn_item::type_id::create("insn");
        pc  = 0;
        insn.c_corner.constraint_mode(0);


        for (int r = 1; r < 31; r++) begin
            if (r inside {28, 29}) continue;
            if (!insn.randomize() with {op == ADDI; rd == r; rs == 0;})
                `uvm_fatal("GEN", "Couldn't generate prologue")
            emit(insn.encode(), insn.convert2string());
        end

        if(!insn.randomize() with {op == ADDI; rd == 5'd1; rs == 0; imm == 17'h1FFFF;})
            `uvm_fatal("GEN", "Couldn't generate corner-case instruction")
        emit(insn.encode(), insn.convert2string());
        if(!insn.randomize() with {op == ADDI; rd == 5'd2; rs == 0; imm == 17'd1;})
            `uvm_fatal("GEN", "Couldn't generate corner-case instruction")
        emit(insn.encode(), insn.convert2string());
        if(!insn.randomize() with {op == SLL; rd == 5'd3; rs == 5'd2; shamt == 31;})
            `uvm_fatal("GEN", "Couldn't generate corner-case instruction")
        emit(insn.encode(), insn.convert2string());
        if(!insn.randomize() with {op == SUB; rd == 5'd4; rs == 5'd1; rt == 5'd3;})
            `uvm_fatal("GEN", "Couldn't generate corner-case instruction")
        emit(insn.encode(), insn.convert2string());

        for (int i = 0; i < n_body; i++) begin
            if (!std::randomize(d) with {d dist {0 := 1, 1 := 3, 2 := 2, 3 := 2};})
                `uvm_fatal("GEN", "Couldn't generate distance")
            if (!std::randomize(corner) with {d dist {0 := 4, 1 := 1};})
                `uvm_fatal("GEN", "Couldn't generate corner")
            insn.c_corner.constraint_mode(corner);
            if (!insn.randomize() with {!(rd inside {[1:4], 28, 29, 31}); !corner && d > 0 && d <= history.size() -> rs == history[d-1];})
                `uvm_fatal("GEN", "Couldn't generate body")
            emit(insn.encode(), insn.convert2string());
            rem(insn.rd);
        end
        



        emit({5'b00001, 27'(pc)}, "j halt");

        return img;
    endfunction
endclass
