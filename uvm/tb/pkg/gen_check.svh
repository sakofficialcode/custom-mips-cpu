// Throwaway check for F1: randomize insn_item and print each encoding with its assembly.
class gen_check_test extends uvm_test;
    `uvm_component_utils(gen_check_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        insn_item it;
        phase.raise_objection(this);
        it = insn_item::type_id::create("it");
        repeat (20) begin
            if (!it.randomize())
                `uvm_fatal("GEN", "randomize failed")
            $display("GEN %032b  %s", it.encode(), it.convert2string());
        end
        phase.drop_objection(this);
    endtask
endclass
