interface reg_if (input logic clk, input logic rst);
    logic ctrl_we;
    logic [4:0] ctrl_writeReg;
    logic [4:0] ctrl_readRegA;
    logic [4:0] ctrl_readRegB;
    logic [31:0] data_readRegA;
    logic [31:0] data_readRegB;
    logic [31:0] data_writeReg;

    clocking cb @(posedge clk);
        input ctrl_we;
        input ctrl_writeReg;
        input ctrl_readRegA;
        input ctrl_readRegB;
        input data_readRegA;
        input data_readRegB;
        input data_writeReg;
    endclocking

endinterface
