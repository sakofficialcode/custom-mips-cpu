// Random-program test: generates a program and hands it to the imem driver and the scoreboard
// through config_db. Everything else (the env, ending when the scoreboard is satisfied) is
// inherited from proc_base_test.
class rand_test extends proc_base_test;
    `uvm_component_utils(rand_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        prog_gen   gen;
        prog_image img;
        gen = prog_gen::type_id::create("gen");
        void'($value$plusargs("N_BODY=%d", gen.n_body));
        img = gen.build_prog();
        // Set before the env is built; the driver and scoreboard get it in their build_phase.
        uvm_config_db#(prog_image)::set(this, "*", "prog", img);
        super.build_phase(phase);
    endfunction
endclass
