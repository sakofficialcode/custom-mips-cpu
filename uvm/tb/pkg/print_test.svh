class wb_printer extends uvm_subscriber #(wb_item);
    `uvm_component_utils(wb_printer)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void write(wb_item t);
        $display("wb_sub %s", t.convert2string());
    endfunction


endclass

class mem_printer extends uvm_subscriber #(mem_item);
    `uvm_component_utils(mem_printer)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void write(mem_item t);
        $display("mem_sub %s", t.convert2string());
    endfunction
endclass
