interface dmem_if (input logic clk, input logic rst);
    logic [31:0] address;
    logic wren;
    logic [31:0] data;
    logic [31:0] q = 0;

    clocking cb @(posedge clk);
        input address;
        input wren;
        input data;
        input q;
    endclocking

    clocking drv_cb @(posedge clk);
        input address;
        input wren;
        input data;
        output q;
    endclocking

endinterface
