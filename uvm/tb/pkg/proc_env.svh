class proc_env extends uvm_env;
    `uvm_component_utils(proc_env)

    wb_monitor monitor;
    imem_agent imem_ag;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = wb_monitor::type_id::create("monitor", this);
        imem_ag = imem_agent::type_id::create("imem_ag", this);
    endfunction
endclass
