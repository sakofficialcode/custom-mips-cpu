// Flow smoke test - throwaway. Proves the xsim toolchain before any real TB code exists:
// UVM 1.2 elaborates, +UVM_TESTNAME reaches the factory, the constraint solver handles
// dist/solve-before, covergroups write a coverage database, and a UVM_ERROR is caught by
// the Makefile's pass/fail check. Not a pattern to copy; it deliberately skips agents/envs.
// No `timescale here: the Makefile applies 1ns/1ps to every module at elaboration.

package smoke_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    class smoke_item extends uvm_object;
        rand bit [4:0]  opcode;
        rand bit [4:0]  aluop;
        rand bit [16:0] imm;

        constraint c_legal {
            opcode inside {5'b00000, 5'b00101, 5'b00111, 5'b01000};
            (opcode != 5'b00000) -> aluop == 5'b00000;
            solve opcode before aluop;
        }
        constraint c_imm { imm dist {17'h00000 := 1, 17'h0FFFF := 1, [17'h00001:17'h0FFFE] :/ 8}; }

        `uvm_object_utils(smoke_item)
        function new(string name = "smoke_item"); super.new(name); endfunction
    endclass

    class smoke_test extends uvm_test;
        `uvm_component_utils(smoke_test)

        bit [4:0] cg_opcode;
        covergroup cg;
            cp_opcode: coverpoint cg_opcode {
                bins r_type = {5'b00000};
                bins addi   = {5'b00101};
                bins sw     = {5'b00111};
                bins lw     = {5'b01000};
            }
        endgroup

        function new(string name, uvm_component parent);
            super.new(name, parent);
            cg = new();
        endfunction

        task run_phase(uvm_phase phase);
            smoke_item item = smoke_item::type_id::create("item");
            phase.raise_objection(this);
            repeat (200) begin
                if (!item.randomize()) `uvm_fatal("SMOKE", "randomize() failed")
                if (item.opcode != 5'b00000 && item.aluop != 5'b00000)
                    `uvm_error("SMOKE", "constraint violated: I-type with nonzero aluop")
                cg_opcode = item.opcode;
                cg.sample();
                #10;
            end
            `uvm_info("SMOKE", $sformatf("opcode coverage: %0.1f%%", cg.get_coverage()), UVM_NONE)
            phase.drop_objection(this);
        endtask
    endclass

    // Run with +UVM_TESTNAME=smoke_fail_test to confirm failures are detected.
    class smoke_fail_test extends smoke_test;
        `uvm_component_utils(smoke_fail_test)
        function new(string name, uvm_component parent); super.new(name, parent); endfunction
        task run_phase(uvm_phase phase);
            `uvm_error("SMOKE", "intentional error")
        endtask
    endclass
endpackage

module smoke_top;
    import uvm_pkg::*;
    import smoke_pkg::*;
    initial run_test();
endmodule
