typedef enum {ADD, SUB, AND, OR, SLL, SRA, ADDI, MUL, DIV} op_e;

class insn_item extends uvm_sequence_item;
    `uvm_object_utils(insn_item)

    rand op_e       op;
    rand bit [4:0]  rd, rs, rt, shamt;
    rand bit [16:0] imm;

    function new(string name = "insn_item");
        super.new(name);
    endfunction

    constraint c_shift{
        solve op before rt, shamt;
        if (op inside {SLL, SRA}) rt == 5'b0;
        else shamt == 5'b0;
    }
    constraint c_rd{
        rd dist {0 := 1, [1:31] :/ 31};
    }

    constraint c_corner{
        op inside {ADD, SUB, MUL, DIV};
        rs inside {[0:4]};
        rt inside {[0:4]};
    }

    function bit [31:0] encode();
        bit [4:0] aluop;
        case (op)
            ADD:  aluop = 5'b00000;
            SUB:  aluop = 5'b00001;
            AND:  aluop = 5'b00010;
            OR:   aluop = 5'b00011;
            SLL:  aluop = 5'b00100;
            SRA:  aluop = 5'b00101;
            ADDI: return {5'b00101, rd, rs, imm};
            MUL:  aluop = 5'b00110;
            DIV:  aluop = 5'b00111;
            default: `uvm_fatal("ENC", $sformatf("encode() has no case for %s", op.name()))
        endcase
        return {5'b00000, rd, rs, rt, shamt, aluop, 2'b00};
    endfunction

    function string convert2string();
        case (op)
            SLL, SRA: return $sformatf("%s r%0d, r%0d, %0d", op.name(), rd, rs, shamt);
            ADDI:     return $sformatf("%s r%0d, r%0d, %0d", op.name(), rd, rs, $signed(imm));
            default:  return $sformatf("%s r%0d, r%0d, r%0d", op.name(), rd, rs, rt);
        endcase
    endfunction
endclass
