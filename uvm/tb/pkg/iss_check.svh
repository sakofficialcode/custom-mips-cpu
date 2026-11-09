class iss_check_test extends uvm_test;
    `uvm_component_utils(iss_check_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        proc_iss iss;
        string mem_dir, verif_dir, prog;
        int fd, num_cycles, r, v;
        phase.raise_objection(this);

        if (!$value$plusargs("MEM_DIR=%s", mem_dir))
            `uvm_fatal("ISS", "+MEM_DIR required")
        if (!$value$plusargs("VERIF_DIR=%s", verif_dir))
            `uvm_fatal("ISS", "+VERIF_DIR required")
        if (!$value$plusargs("PROG=%s", prog))
            `uvm_fatal("ISS", "+PROG required")
        
        iss = new();
        iss.load({mem_dir, prog, ".mem"});

        if (!iss.run())
            `uvm_error("ISS", $sformatf("%s stopped at maximum steps, on PC=%0d", prog, iss.pc))

        foreach (iss.reg_writes[i])
            $display("ISS %s", iss.reg_writes[i].convert2string());
        foreach(iss.mem_writes[i])
            $display("ISS_MEM %s", iss.mem_writes[i].convert2string());
        
        fd = $fopen({verif_dir, prog, "_exp.txt"}, "r");
        if (fd == 0)
            `uvm_fatal("ISS", "verification file not found")
        $fscanf(fd, "num cycles:%d", num_cycles);
        while ($fscanf(fd, " r%d=%d", r, v) == 2) begin
            if (iss.regs[r] != v)
                `uvm_error("ISS", $sformatf("%s: r%0d = %0d, expected %0d", prog, r, iss.regs[r], v))
        end
        $fclose(fd);



            

        phase.drop_objection(this);
    endtask
endclass
