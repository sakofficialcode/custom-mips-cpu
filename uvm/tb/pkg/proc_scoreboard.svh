`uvm_analysis_imp_decl(_wb)
`uvm_analysis_imp_decl(_mem)

class proc_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(proc_scoreboard)

    uvm_analysis_imp_wb #(wb_item, proc_scoreboard) wb_imp;
    uvm_analysis_imp_mem #(mem_item, proc_scoreboard) mem_imp;
    uvm_analysis_port #(exec_item) exec_ap;
    prog_image img;
    proc_iss iss;
    int n_wb, n_mem, n_err;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        string prog, mem_dir;
        super.build_phase(phase);
        wb_imp = new("wb_imp", this);
        mem_imp = new("mem_imp", this);
        exec_ap = new("exec_ap", this);

        iss = new();
        if (uvm_config_db#(prog_image)::get(this, "", "prog", img)) begin
            iss.load_image(img);
        end else if ($value$plusargs("PROG=%s", prog) && $value$plusargs("MEM_DIR=%s", mem_dir)) begin
            iss.load({mem_dir, prog, ".mem"});
        end else begin
            `uvm_fatal("SB", "No prog or memory found")
        end

        
        if (!iss.run())
            `uvm_fatal("SB", "Sim timeout")
    endfunction

    function void write_wb(wb_item acc);
        wb_item exp;
        if (iss.reg_writes.size() == 0) begin
            `uvm_error("SB", {"unexpected reg write", acc.convert2string()})
            n_err++;
            return;
        end
        exp = iss.reg_writes.pop_front();
        if (acc.reg_idx != exp.reg_idx || acc.data != exp.data) begin
            `uvm_error("SB", $sformatf("cycle %0d: expected %s, actual %s", acc.cycle, exp.convert2string(), acc.convert2string()))
            n_err++;
        end
        n_wb++;
    endfunction

    function void write_mem(mem_item acc);
        mem_item exp;
        if (iss.mem_writes.size() == 0) begin
            `uvm_error("SB", {"unexpected mem write", acc.convert2string()})
            n_err++;
            return;
        end
        exp = iss.mem_writes.pop_front();
        if (acc.addr != exp.addr || acc.data != exp.data) begin
            `uvm_error("SB", $sformatf("cycle %0d: expected %s, actual %s", acc.cycle, exp.convert2string(), acc.convert2string()))
            n_err++;
        end
        n_mem++;
    endfunction

    function bit done();
        return iss.reg_writes.size() == 0 && iss.mem_writes.size() == 0;
    endfunction


    function void check_phase(uvm_phase phase);
        if (iss.reg_writes.size() != 0) begin
            `uvm_error("SB", $sformatf("%0d missing reg writes, top: %s", iss.reg_writes.size(), iss.reg_writes[0].convert2string()))
            n_err++;
        end
        if (iss.mem_writes.size() != 0) begin
            `uvm_error("SB", $sformatf("%0d missing mem writes, top: %s", iss.mem_writes.size(), iss.mem_writes[0].convert2string()))
            n_err++;
        end
        foreach (iss.exec_log[i]) begin
            exec_ap.write(iss.exec_log[i]);
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SB", $sformatf("%0d reg writes, %0d stores, %0d errors", n_wb, n_mem, n_err), UVM_LOW)
    endfunction
endclass
