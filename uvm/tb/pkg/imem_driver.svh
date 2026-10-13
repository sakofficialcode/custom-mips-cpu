class imem_driver extends uvm_driver;
    `uvm_component_utils(imem_driver)

    virtual imem_if vif;
    imem_model model;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        string prog, mem_dir;
        
        super.build_phase(phase);

        if (!uvm_config_db#(virtual imem_if)::get(this, "", "imem_vif", vif))
            `uvm_fatal("MEM", "No VIF found")

        

        
        model = new();
        if ($value$plusargs("PROG=%s", prog) && $value$plusargs("MEM_DIR=%s", mem_dir)) begin
            model.load({mem_dir, prog, ".mem"});
        end else begin
            `uvm_fatal("MEM", "No prog or memory found")
        end
        

    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            @(vif.drv_cb);
            vif.drv_cb.q <= model.read(vif.drv_cb.address);
        end
    endtask
endclass