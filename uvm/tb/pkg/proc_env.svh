class proc_env extends uvm_env;
    `uvm_component_utils(proc_env)

    wb_monitor monitor;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = wb_monitor::type_id::create("monitor", this);
    endfunction
endclass
