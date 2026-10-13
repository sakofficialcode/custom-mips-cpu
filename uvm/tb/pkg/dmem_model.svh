class dmem_model;
    bit [31:0] mem [0:4095];

    function void write(bit [31:0] addr, bit [31:0] data);
        mem[addr[11:0]] = data;
    endfunction

    function bit [31:0] read(bit [31:0] addr);
        return mem[addr[11:0]];
    endfunction

endclass
