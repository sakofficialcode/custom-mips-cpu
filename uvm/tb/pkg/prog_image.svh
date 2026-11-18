class prog_image extends uvm_object;
    `uvm_object_utils(prog_image)
    bit [31:0] words [4096];
    function new(string name = "prog_image");
        super.new(name);
    endfunction
endclass