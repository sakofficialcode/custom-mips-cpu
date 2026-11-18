class imem_model;

    bit [31:0] mem [0:4095];

    function void load(string path);
        $readmemb(path, mem);
    endfunction

    function void load_image(prog_image image);
        mem = image.words;
    endfunction

    function bit [31:0] read(bit [31:0] addr);
        return mem[addr[11:0]];
    endfunction

endclass