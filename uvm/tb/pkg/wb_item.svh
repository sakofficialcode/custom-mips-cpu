class wb_item extends uvm_sequence_item;
    bit [ 4:0] reg_idx;
    bit [31:0] data;
    int        cycle;

    `uvm_object_utils(wb_item)
    function new(string name = "wb_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("r%0d <= %0d (cycle %0d)", reg_idx, $signed(data), cycle);
    endfunction

endclass
