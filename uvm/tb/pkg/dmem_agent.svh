class dmem_agent extends uvm_agent;
    `uvm_component_utils(dmem_agent)

    dmem_driver driver;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        driver = dmem_driver::type_id::create("driver", this);

    endfunction;

endclass