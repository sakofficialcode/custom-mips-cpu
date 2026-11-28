`include "uvm_macros.svh"

module proc_sva(
    input logic clock, reset,
    input logic [31:0] dxinsn_out,
    input logic [31:0] x_exception,
    input logic x_isALU, x_isADDI,
    input logic [4:0] aluOp,
    input logic stall, stall_lw,
    input logic [31:0] fdpc_out, fdinsn_out,
    input logic ctrl_MULT, ctrl_DIV, multdiv_ready,
    input logic w_isException, ctrl_writeEnable,
    input logic [4:0] ctrl_writeReg, 
    input logic wren, 
    input logic [31:0] address_dmem, data,data_writeReg,
    input logic [31:0] address_imem
);

import uvm_pkg::*;


localparam logic [4:0]  ADD = 5'b00000,
                        SUB = 5'b00001,
                        MUL = 5'b00110,
                        DIV = 5'b00111;



nop_no_exception: assert property (@(posedge clock) disable iff (reset) (~|dxinsn_out |-> ~|x_exception))
    else `uvm_error("PROC_ASSERT", $sformatf("NOP instruction should not cause exception, dxinsn_out=%h, x_exception=%h", dxinsn_out, x_exception));

exc_is_arith: assert property (@(posedge clock) disable iff (reset) x_exception |-> (x_isALU && aluOp inside {ADD, SUB, MUL, DIV}) || x_isADDI) 
    else `uvm_error("PROC_ASSERT", $sformatf("Exception should only be caused by arithmetic instructions, dxinsn_out=%h, x_exception=%h", dxinsn_out, x_exception));

stall_stable_pc: assert property (@(negedge clock) disable iff (reset) stall |=> $stable(fdpc_out) && $stable(fdinsn_out))
    else `uvm_error("PROC_ASSERT", $sformatf("Stall should hold fdpc_out and fdinsn_out stable, fdpc_out=%h, fdinsn_out=%h", fdpc_out, fdinsn_out));

lw_stall_one_cycle: assert property (@(negedge clock) disable iff (reset) stall_lw |=> !stall_lw)
    else `uvm_error("PROC_ASSERT", "Load stall should only last one cycle");

multdiv_onehot: assert property (@(posedge clock) disable iff (reset) ~(ctrl_MULT && ctrl_DIV))
    else `uvm_error("PROC_ASSERT", "Only one of MULT / DIV can be high at once");

mult_latency: assert property (@(posedge clock) disable iff (reset) ctrl_MULT |-> ##[1:17] $rose(multdiv_ready))
    else `uvm_error("PROC_ASSERT", "MULT should take 1-17 cycles to complete");

div_latency: assert property (@(posedge clock) disable iff (reset) ctrl_DIV |-> ##[1:33] $rose(multdiv_ready))
    else `uvm_error("PROC_ASSERT", "DIV should take 1-33 cycles to complete");

exc_writes_status: assert property (@(posedge clock) disable iff (reset) w_isException |-> ctrl_writeEnable && ctrl_writeReg == 5'd30)
    else `uvm_error("PROC_ASSERT", "Exception should write to status register");

writeback_safe: assert property (@(posedge clock) disable iff (reset) ctrl_writeEnable |-> !$isunknown(data_writeReg) && !$isunknown(ctrl_writeReg))
    else `uvm_error("PROC_ASSERT", "Write should not write unknown values to register file");

memory_safe: assert property (@(posedge clock) disable iff (reset) wren |-> !$isunknown(address_dmem) && !$isunknown(data)) 
    else `uvm_error("PROC_ASSERT", "Memory should not write unknown values to memory");

fetch_safe: assert property (@(posedge clock) disable iff (reset) !$isunknown(address_imem))
    else `uvm_error("PROC_ASSERT", "Fetch should not fetch unknown values from memory");


endmodule
