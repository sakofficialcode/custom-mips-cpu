interface imem_if (input logic clk, input logic rst);
    logic [31:0] address;
    logic [31:0] q = 0;

    clocking cb @(posedge clk);
        input address;
        input q;
    endclocking

    clocking drv_cb @(posedge clk);
        input address;
        output q;
    endclocking

endinterface
