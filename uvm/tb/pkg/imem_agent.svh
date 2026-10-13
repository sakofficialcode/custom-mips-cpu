class imem_agent extends uvm_agent;
    `uvm_component_utils(imem_agent)

    imem_driver driver;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        driver = imem_driver::type_id::create("driver", this);
    endfunction

endclass