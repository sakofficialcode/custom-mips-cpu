class proc_iss;
    bit      [31:0] regs      [  32];
    bit      [31:0] pc;
    bit      [31:0] imem      [4096];
    bit      [31:0] dmem      [4096];
    wb_item         reg_writes[   $];
    mem_item        mem_writes[   $];

    bit      [31:0] insn;

    function void load(string path);
        $readmemb(path, imem);
    endfunction

    function void load_image(prog_image image);
        imem = image.words;
    endfunction


    function void write_reg(bit [4:0] r, bit [31:0] d);
        wb_item item;

        if (r == 0) return;
        regs[r]      = d;
        item         = wb_item::type_id::create("item");
        item.reg_idx = r;
        item.data    = d;
        reg_writes.push_back(item);
    endfunction

    function void raise_exception(bit [31:0] code);
        write_reg(5'd30, code);
    endfunction



    function void step();
        bit [4:0] opcode, rd, rs, rt, shamt, aluop;
        bit [31:0] imm;
        bit [31:0] a, b, result;
        bit [32:0] wide;
        bit        w_inst;
        bit [ 4:0] dest;
        bit [31:0] exc;
        bit [31:0] addr;
        bit [31:0] next_pc;
        bit [63:0] prod;


        insn    = imem[pc[11:0]];
        opcode  = insn[31:27];
        rd      = insn[26:22];
        rs      = insn[21:17];
        rt      = insn[16:12];
        shamt   = insn[11:7];
        aluop   = insn[6:2];
        imm     = {{15{insn[16]}}, insn[16:0]};
        next_pc = pc + 1;

        w_inst  = 1'b0;
        dest    = 5'b0;
        exc     = 32'b0;

        case (opcode)
            5'b00000: begin
                case (aluop)
                    5'b00000: begin
                        a      = regs[rs];
                        b      = regs[rt];
                        result = a + b;
                        wide   = {a[31], a} + {b[31], b};
                        if (wide[32] ^ wide[31]) exc = 1;
                        w_inst = 1'b1;
                        dest   = rd;
                    end
                    5'b00001: begin
                        a      = regs[rs];
                        b      = regs[rt];
                        result = a - b;
                        wide   = {a[31], a} - {b[31], b};
                        if (wide[32] ^ wide[31]) exc = 3;
                        w_inst = 1'b1;
                        dest   = rd;
                    end
                    5'b00010: begin
                        a      = regs[rs];
                        b      = regs[rt];
                        result = a & b;
                        w_inst = 1'b1;
                        dest   = rd;
                    end
                    5'b00011: begin
                        a      = regs[rs];
                        b      = regs[rt];
                        result = a | b;
                        w_inst = 1'b1;
                        dest   = rd;
                    end
                    5'b00100: begin
                        a      = regs[rs];
                        result = a << shamt;
                        w_inst = 1'b1;
                        dest   = rd;
                    end
                    5'b00101: begin
                        a      = regs[rs];
                        result = $signed(a) >>> shamt;
                        w_inst = 1'b1;
                        dest   = rd;
                    end
                    5'b00110: begin

                        a      = regs[rs];
                        b      = regs[rt];


                        prod   = $signed({{32{a[31]}}, a}) * $signed({{32{b[31]}}, b});
                        result = prod[31:0];
                        if (prod != {{32{prod[31]}}, prod[31:0]}) exc = 4;
                        w_inst = 1'b1;
                        dest   = rd;
                    end
                    5'b00111: begin
                        a = regs[rs];
                        b = regs[rt];
                        if (b == 0) exc = 5;
                        if (a == 32'h80000000 && b == 32'hFFFFFFFF) begin
                            result = 32'h80000000;
                            w_inst = 1'b1;
                            dest   = rd;
                        end else begin
                            result = $signed(a) / $signed(b);
                            w_inst = 1'b1;
                            dest   = rd;
                        end
                    end
                    default;
                endcase
            end
            5'b00101: begin
                a      = regs[rs];
                result = a + imm;
                wide   = {a[31], a} + {imm[31], imm};
                if (wide[32] ^ wide[31]) exc = 2;
                w_inst = 1'b1;
                dest   = rd;
            end
            5'b00111: begin
                mem_item item;

                addr             = regs[rs] + imm;
                dmem[addr[11:0]] = regs[rd];
                item             = mem_item::type_id::create("item");
                item.addr        = addr;
                item.data        = regs[rd];
                mem_writes.push_back(item);
            end
            5'b01000: begin
                addr   = regs[rs] + imm;
                result = dmem[addr[11:0]];
                w_inst = 1;
                dest   = rd;

            end
            5'b00001: begin
                next_pc = {5'b0, insn[26:0]};
            end
            5'b00011: begin
                w_inst  = 1;
                dest    = 5'd31;
                result  = pc + 1;
                next_pc = {5'b0, insn[26:0]};
            end
            5'b00100: begin
                next_pc = regs[rd];
            end
            5'b00010: begin
                if (regs[rd] != regs[rs]) next_pc = pc + 1 + imm;
            end
            5'b00110: begin
                if ($signed(regs[rd]) < $signed(regs[rs])) next_pc = pc + 1 + imm;
            end
            5'b10110: begin
                if (regs[30] != 0) next_pc = {5'b0, insn[26:0]};
            end
            5'b10101: begin
                w_inst = 1;
                dest   = 5'd30;
                result = {5'b0, insn[26:0]};
            end




            default;

        endcase

        if (exc != 0) raise_exception(exc);
        else if (w_inst) write_reg(dest, result);

        pc = next_pc;
    endfunction

    function bit run(int max_steps = 100000);
        int nop_cnt = 0;
        int total = 0;
        int seen        [4096];
        bit [31:0] next;
        foreach (seen[i]) begin
            seen[i] = -1;
        end
        repeat (max_steps) begin
            next = imem[pc[11:0]];
            total = reg_writes.size() + mem_writes.size();
            if (seen[pc[11:0]] == total) return 1;
            else seen[pc[11:0]] = total;
            if (next == 32'b0) begin
                nop_cnt++;
                if (nop_cnt == 16) return 1;
            end else nop_cnt = 0;
            step();
        end
        return 0;
    endfunction

endclass
