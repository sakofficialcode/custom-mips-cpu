interface imem_if (input logic clk, input logic rst);
    logic [31:0] address;
    logic [31:0] q;

    clocking cb @(posedge clk);
        input address;
        input q;
    endclocking
endinterface
