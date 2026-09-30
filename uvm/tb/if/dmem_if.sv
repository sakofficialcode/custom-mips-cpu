interface dmem_if (input logic clk, input logic rst);
    logic [31:0] address;
    logic wren;
    logic [31:0] data;
    logic [31:0] q;

    clocking cb @(posedge clk);
        input address;
        input wren;
        input data;
        input q;
    endclocking

endinterface
