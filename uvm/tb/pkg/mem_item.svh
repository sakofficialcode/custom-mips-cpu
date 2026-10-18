class mem_item extends uvm_sequence_item;
    bit [31:0] addr;
    bit [31:0] data;
    int        cycle;

    `uvm_object_utils(mem_item)
    function new (string name = "mem_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("mem[%0h] <= %0d (cycle %0d)", addr, $signed(data), cycle);
    endfunction



endclass
