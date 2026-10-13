class dmem_driver extends uvm_driver;
    `uvm_component_utils(dmem_driver)

    virtual dmem_if vif;
    dmem_model model;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        model = new();
        if (!uvm_config_db#(virtual dmem_if)::get(this, "", "dmem_vif", vif))
            `uvm_fatal("DMEM", "No VIF found")
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            @(vif.drv_cb);
            
            if (vif.drv_cb.wren === 1'b1)
                model.write(vif.drv_cb.address, vif.drv_cb.data);
            else
                vif.drv_cb.q <= model.read(vif.drv_cb.address);

        end
    endtask
endclass