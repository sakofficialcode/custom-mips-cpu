class proc_env extends uvm_env;
    `uvm_component_utils(proc_env)

    wb_monitor   wb_m;
    dmem_monitor dmem_m;
    imem_agent   imem_ag;
    dmem_agent   dmem_ag;
    wb_printer   wb_p;
    mem_printer  mem_p;


    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        wb_m    = wb_monitor::type_id::create("wb_m", this);
        dmem_m  = dmem_monitor::type_id::create("dmem_m", this);
        imem_ag = imem_agent::type_id::create("imem_ag", this);
        dmem_ag = dmem_agent::type_id::create("dmem_ag", this);
        wb_p    = wb_printer::type_id::create("wb_p", this);
        mem_p   = mem_printer::type_id::create("mem_p", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        wb_m.ap.connect(wb_p.analysis_export);
        dmem_m.ap.connect(mem_p.analysis_export);
    endfunction
endclass
