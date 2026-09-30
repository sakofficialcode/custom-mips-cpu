class wb_monitor extends uvm_monitor;
    `uvm_component_utils(wb_monitor)

    virtual reg_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual reg_if)::get(this, "", "reg_vif", vif))
            `uvm_fatal("NOVIF", "Failed to get vif")
    endfunction

    task run_phase(uvm_phase phase);
        int cycle = 0;

        wait(vif.rst === 1'b1);
        wait(vif.rst === 1'b0);

        forever begin
            @(vif.cb);
            if (vif.cb.ctrl_we && vif.cb.ctrl_writeReg != 5'b0) begin
                $display("TRACE Cycle %3d: Wrote %0d into register %0d", cycle, $signed(vif.cb.data_writeReg), vif.cb.ctrl_writeReg);
            end
            cycle++;
        end
    endtask

endclass