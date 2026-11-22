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

    function void gen_body_insn(insn_item insn);
        int d;
        bit corner;
        op_e op_sel;
        bit history_sel;
        bit [4:0] target_rs;

        if(!std::randomize(op_sel) with {op_sel dist {[ADD:DIV] :/ 8, SW := 1, LW := 1};})
            `uvm_fatal("GEN", "Couldn't generate op selection")
        if (!std::randomize(d) with {d dist {0 := 1, 1 := 3, 2 := 2, 3 := 2};})
            `uvm_fatal("GEN", "Couldn't generate distance")
        if (!std::randomize(corner) with {corner dist {0 := 4, 1 := 1};})
            `uvm_fatal("GEN", "Couldn't generate corner")
        insn.c_corner.constraint_mode(corner);
        history_sel = !(corner || (op_sel inside {SW, LW})) && d > 0 && d <= history.size();
        target_rs = history_sel ? history[d-1] : 5'b0;
        if (!insn.randomize() with {!(rd inside {[1:4], 28, 29, 31}); history_sel -> rs == target_rs; !corner -> op == op_sel;})
            `uvm_fatal("GEN", "Couldn't generate body")
        emit(insn.encode(), insn.convert2string());
        if (!(insn.op inside {SW}))
            rem(insn.rd);
        
        insn.c_corner.constraint_mode(0);

    endfunction

    function void gen_bex_setx(insn_item insn);
        int fill, post, skip;
        bit [26:0]  bex_target;

        if (!std::randomize(fill) with {fill dist {0 := 1, [1:3] :/ 2};})
            `uvm_fatal("GEN", "Couldn't generate fill")
        if (!std::randomize(post) with {post dist {[1:7] :/ 7};})
            `uvm_fatal("GEN", "Couldn't generate post")
        
        
        if (!insn.randomize() with {op == SETX; target dist {0 := 3, [1:27'h7FFFFFF] :/ 1};})
            `uvm_fatal("GEN", "Couldn't generate bex/setx")
        emit(insn.encode(), insn.convert2string());
        rem(30);
        repeat (fill) begin
            gen_body_insn(insn);
        end

        if (!std::randomize(skip) with {skip inside {[1:post]};})
            `uvm_fatal("GEN", "Couldn't generate skip")
        
        bex_target = pc + 1 + skip;

        if (!insn.randomize() with {op == BEX; target == bex_target;})
            `uvm_fatal("GEN", "Couldn't generate bex/setx")
        emit(insn.encode(), insn.convert2string());
        repeat (post) begin
            gen_body_insn(insn);
        end
    endfunction


    function prog_image build_prog();
        insn_item insn;
        

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

        if(!insn.randomize() with {op == ADDI; rd == 5'd28; rs == 0; imm == 17'd256;})
            `uvm_fatal("GEN", "Couldn't generate mem reg instruction")
        emit(insn.encode(), insn.convert2string());        
        if(!insn.randomize() with {op == ADDI; rd == 5'd29; rs == 0; imm == 17'd288;})
            `uvm_fatal("GEN", "Couldn't generate mem reg instruction")
        emit(insn.encode(), insn.convert2string());

        for (int l = 0; l < 64; l++) begin
            if(!insn.randomize() with {op == SW; rd inside {[5:27]}; rs == 5'd28; imm == l;})
                `uvm_fatal("GEN", "Couldn't generate fill instruction")
            emit(insn.encode(), insn.convert2string());
        end


        for (int i = 0; i < n_body; i++) begin
            randcase
                9: gen_body_insn(insn);
                1: gen_bex_setx(insn);
            endcase
        end
        



        emit({5'b00001, 27'(pc)}, "j halt");

        return img;
    endfunction
endclass
