class proc_base_test extends uvm_test;
    `uvm_component_utils(proc_base_test)

    proc_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = proc_env::type_id::create("env", this);

    endfunction

    task run_phase(uvm_phase phase);
        
        string verif_dir, prog;
        int num_cycles = 255;
        int fd;
        if ($value$plusargs("VERIF_DIR=%s", verif_dir) && $value$plusargs("PROG=%s", prog)) begin
            fd = $fopen({verif_dir, prog, "_exp.txt"}, "r");
            if (fd) begin
                $fscanf(fd, "num cycles:%d", num_cycles);
                $fclose(fd);
            end
        end        

        phase.raise_objection(this);
        #(num_cycles * 20 + 11);
        phase.drop_objection(this);
    endtask
endclass
