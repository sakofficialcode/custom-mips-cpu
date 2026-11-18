class proc_base_test extends uvm_test;
    `uvm_component_utils(proc_base_test)

    proc_env env;
    virtual reg_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = proc_env::type_id::create("env", this);
        if(!uvm_config_db#(virtual reg_if)::get(this, "", "reg_vif", vif))
            `uvm_fatal("TEST", "failed to get clock")
        
    endfunction

    task run_phase(uvm_phase phase);
        
        int cycles = 0;
        int TIMEOUT = 20000;

        phase.raise_objection(this);
        
        wait (vif.rst === 1'b0);

        while (!env.sb.done() && cycles < TIMEOUT) begin
            @(vif.cb);
            cycles++;
        end
        if (!env.sb.done())
            `uvm_error("TEST", $sformatf("Test timed out after %0d cycles", TIMEOUT))
        
        repeat (50) @(vif.cb);

        phase.drop_objection(this);
    endtask
endclass
