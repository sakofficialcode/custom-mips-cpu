class dmem_monitor extends uvm_monitor;
    `uvm_component_utils(dmem_monitor)

    virtual dmem_if vif;
    uvm_analysis_port #(mem_item) ap;

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual dmem_if)::get(this, "", "dmem_vif", vif))
            `uvm_fatal("NOVIF", "Failed to get vif")
        ap = new("ap", this);
    endfunction

    task run_phase(uvm_phase phase);
        int cycle = 0;
        mem_item item;

        wait(vif.rst === 1'b1);
        wait(vif.rst === 1'b0);

        forever begin
            @(vif.cb);
            if (vif.cb.wren === 1'b1) begin
                item = mem_item::type_id::create("item");
                item.addr = vif.cb.address;
                item.data = vif.cb.data;
                item.cycle = cycle;
                ap.write(item);

            end
            cycle++;
        end
    endtask

endclass
