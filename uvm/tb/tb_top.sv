module  tb_top;
    import uvm_pkg::*;
    import proc_pkg::*;
    `include "uvm_macros.svh"



    logic clock = 0;
    always #10 clock = ~clock;
    
    logic rst = 1;

    initial begin
        @(negedge clock);
        #1 rst = 0;
    end

    imem_if imem(clock, rst);
    dmem_if dmem(clock, rst);
    reg_if regIF(clock, rst);

    initial begin
        string mem_dir, prog;
        if (!$value$plusargs("MEM_DIR=%s", mem_dir)) $fatal(1, "+MEM_DIR required");
        if (!$value$plusargs("PROG=%s", prog)) $fatal(1, "+PROG required");
        $readmemb({mem_dir, prog, ".mem"}, InstMem.MemoryArray);
    end

    initial begin
        uvm_config_db#(virtual reg_if)::set(null, "*", "reg_vif", regIF);
        run_test();
    end





    



    processor CPU(
        .clock(clock),
        .reset(rst),
        
        .address_imem(imem.address),
        .q_imem(imem.q),

        .ctrl_writeEnable(regIF.ctrl_we),
        .ctrl_writeReg(regIF.ctrl_writeReg),
        .ctrl_readRegA(regIF.ctrl_readRegA),
        .ctrl_readRegB(regIF.ctrl_readRegB),
        .data_readRegA(regIF.data_readRegA),
        .data_readRegB(regIF.data_readRegB),
        .data_writeReg(regIF.data_writeReg),

        .wren(dmem.wren),
        .address_dmem(dmem.address),
        .data(dmem.data),
        .q_dmem(dmem.q)
    );

    ROM InstMem(
        .clk(clock),
        .addr(imem.address[11:0]),
        .dataOut(imem.q)
    );

    RAM ProcMem(
        .clk(clock),
        .wEn(dmem.wren),
        .addr(dmem.address[11:0]),
        .dataIn(dmem.data),
        .dataOut(dmem.q)
    );

    regfile RegFile(
        .clock(clock),
        .ctrl_reset(rst),
        .ctrl_writeEnable(regIF.ctrl_we),
        .ctrl_writeReg(regIF.ctrl_writeReg),
        .ctrl_readRegA(regIF.ctrl_readRegA),
        .ctrl_readRegB(regIF.ctrl_readRegB),
        .data_readRegA(regIF.data_readRegA),
        .data_readRegB(regIF.data_readRegB),
        .data_writeReg(regIF.data_writeReg)
    );

endmodule