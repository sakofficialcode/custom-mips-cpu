    /**
    * READ THIS DESCRIPTION!
    *
    * This is your processor module that will contain the bulk of your code submission. You are to implement
    * a 5-stage pipelined processor in this module, accounting for hazards and implementing bypasses as
    * necessary.
    *
    * Ultimately, your processor will be tested by a master skeleton, so the
    * testbench can see which controls signal you active when. Therefore, there needs to be a way to
    * "inject" imem, dmem, and regfile interfaces from some external controller module. The skeleton
    * file, Wrapper.v, acts as a small wrapper around your processor for this purpose. Refer to Wrapper.v
    * for more details.
    *
    * As a result, this module will NOT contain the RegFile nor the memory modules. Study the inputs 
    * very carefully - the RegFile-related I/Os are merely signals to be sent to the RegFile instantiated
    * in your Wrapper module. This is the same for your memory elements. 
    *
    *
    */
    module processor(
        // Control signals
        clock,                          // I: The master clock
        reset,                          // I: A reset signal

        // Imem
        address_imem,                   // O: The address of the data to get from imem
        q_imem,                         // I: The data from imem

        // Dmem
        address_dmem,                   // O: The address of the data to get or put from/to dmem
        data,                           // O: The data to write to dmem
        wren,                           // O: Write enable for dmem
        q_dmem,                         // I: The data from dmem

        // Regfile
        ctrl_writeEnable,               // O: Write enable for RegFile
        ctrl_writeReg,                  // O: Register to write to in RegFile
        ctrl_readRegA,                  // O: Register to read from port A of RegFile
        ctrl_readRegB,                  // O: Register to read from port B of RegFile
        data_writeReg,                  // O: Data to write to for RegFile
        data_readRegA,                  // I: Data from port A of RegFile
        data_readRegB                   // I: Data from port B of RegFile
        
        );

        // Control signals
        input clock, reset;
        
        // Imem
        output [31:0] address_imem;
        input [31:0] q_imem;

        // Dmem
        output [31:0] address_dmem, data;
        output wren;
        input [31:0] q_dmem;

        // Regfile
        output ctrl_writeEnable;
        output [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
        output [31:0] data_writeReg;
        input [31:0] data_readRegA, data_readRegB;

        /* YOUR CODE STARTS HERE */

        wire md_stall = (is_mult | is_div) & ~md_ready;
        wire stall = md_stall | load_use_stall;
        // ==================== FETCH ====================
        wire [31:0] PC, pc_plus1, PC_next;
        cla pcadder(.in1(PC),.in2(32'b1),.c_in(1'b0),.overflow(),.sum(pc_plus1));

        register PC_reg(.clk(~clock), .clr(reset), .en(~stall), .d(PC_next), .q(PC));
        assign address_imem = PC;

        assign PC_next = branch_taken ? branch_target :
                        is_jr        ? jr_target :
                        is_jump      ? {5'b0, insn_D[26:0]} :
                                        pc_plus1;

        wire [31:0] PC_D;
        register FD_PC(.clk(~clock), .clr(reset), .en(~stall), .q(PC_D), .d(pc_plus1));
        wire [31:0] insn_D;
        register FD_IR(.clk(~clock), .clr(reset), .en(~stall), .q(insn_D), .d(branch_taken | is_jump ? 32'b0 : q_imem));

        // ==================== DECODE ====================
        wire is_branch_D = (insn_D[31:27] == 5'b00010) | (insn_D[31:27] == 5'b00110);
        assign ctrl_readRegA = (insn_D[31:27] == 5'b10110) ? 5'd30 : (insn_D[31:27] == 5'b00100) ? insn_D[26:22] : is_branch_D ? insn_D[26:22] : insn_D[21:17];
        assign ctrl_readRegB = (insn_D[31:27] == 5'b00111) ? insn_D[26:22] : is_branch_D ? insn_D[21:17] : insn_D[16:12];

        wire is_j   = (insn_D[31:27] == 5'b00001);
        wire is_jr  = (insn_D[31:27] == 5'b00100);
        wire is_jal = (insn_D[31:27] == 5'b00011);
        wire is_jump = is_j | is_jr | is_jal;

        wire [31:0] PC_X;
        register DX_PC(.clk(~clock), .clr(reset), .en(~stall), .q(PC_X), .d(PC_D));
        wire [31:0] decodeA, decodeB;
        register DX_A(.clk(~clock), .clr(reset), .en(~stall), .q(decodeA), .d(data_readRegA));
        register DX_B(.clk(~clock), .clr(reset), .en(~stall), .q(decodeB), .d(data_readRegB));
        wire [31:0] insn_X;
        register DX_IR(.clk(~clock), .clr(reset), .en(~stall | load_use_stall), .q(insn_X), .d(branch_taken ? 32'b0 : load_use_stall ? 32'b0 : insn_D));

        // ==================== E(X)ECUTE ====================
        wire [4:0] opcodeX = insn_X[31:27];
        wire [31:0] immedX = {{15{insn_X[16]}}, insn_X[16:0]};
        wire i_type = ((opcodeX == 5'b00101 || opcodeX == 5'b00111 || opcodeX == 5'b01000));

        wire is_add  = (opcodeX == 5'b00000) && (insn_X[6:2] == 5'b00000);
        wire is_sub  = (opcodeX == 5'b00000) && (insn_X[6:2] == 5'b00001);
        wire is_addi = (opcodeX == 5'b00101);
        wire is_mult = (opcodeX == 5'b00000) && (insn_X[6:2] == 5'b00110);
        wire is_div  = (opcodeX == 5'b00000) && (insn_X[6:2] == 5'b00111);

        wire [31:0] alu_out;
        wire ne, lt, alu_overflow;
        wire [4:0] alu_opcode = (i_type ? 5'b00000 : insn_X[6:2]);

        wire [31:0] opA = mx_bypass_A ? m_bypass_val : wx_bypass_A ? data_writeReg : decodeA;
        wire [31:0] opB = i_type ? immedX : mx_bypass_lw_B ? q_dmem : mx_bypass_B ? m_bypass_val : wx_bypass_B ? data_writeReg : decodeB;
        alu ALU(.data_operandA(opA), .data_operandB(opB), .ctrl_ALUopcode(alu_opcode), .ctrl_shiftamt(insn_X[11:7]), .data_result(alu_out), .isNotEqual(ne), .isLessThan(lt), .overflow(alu_overflow));

        wire [31:0] md_out;
        wire md_overflow;
        wire md_ready, md_running;
        dffe_ref md_run_reg(.q(md_running), .d(stall), .clk(~clock), .en(1'b1), .clr(reset));
        multdiv md(.data_operandA(opA),.data_operandB(opB),.ctrl_MULT(is_mult && !md_running),.ctrl_DIV(is_div && !md_running),.clock(clock),.data_result(md_out),.data_resultRDY(md_ready),.data_exception(md_overflow));

        wire is_bne = (opcodeX == 5'b00010);
        wire is_blt = (opcodeX == 5'b00110);
        wire is_bex = (opcodeX == 5'b10110);

        wire [31:0] branch_plus_immed;
        cla bradder(.in1(PC_X), .in2(immedX), .c_in(1'b0), .overflow(), .sum(branch_plus_immed));

        wire [31:0] branch_target = is_bex ? {5'b0, insn_X[26:0]} : branch_plus_immed;

        wire branch_taken = (is_bne & ne) | (is_blt & lt) | (is_bex & opA != 32'b0);

        wire [31:0] exception_code = (alu_overflow && is_add)  ? 32'd1 :
                                    (alu_overflow && is_addi) ? 32'd2 :
                                    (alu_overflow && is_sub)  ? 32'd3 :
                                    (md_overflow  && is_mult) ? 32'd4 :
                                    (md_overflow  && is_div)  ? 32'd5 :
                                                                32'd0;

        wire [31:0] PC_M;
        register XMJ_PC(.clk(~clock), .clr(reset), .en(~md_stall), .q(PC_M), .d(PC_X));
        wire [31:0] exception_M;
        register XM_EX(.clk(~clock), .clr(reset), .en(~md_stall), .q(exception_M), .d(exception_code));
        wire [31:0] executeOut;
        register XM_O(.clk(~clock), .clr(reset), .en(~md_stall), .q(executeOut), .d((is_mult | is_div) ? md_out : alu_out));
        wire [31:0] executeB;
        register XM_B(.clk(~clock), .clr(reset), .en(~md_stall), .q(executeB), .d(wx_bypass_B ? data_writeReg : decodeB));
        wire [31:0] insn_M;
        register XM_IR(.clk(~clock), .clr(reset), .en(~md_stall), .q(insn_M), .d(insn_X));

        // ==================== MEMORY ====================
        wire [4:0] opcodeM = insn_M[31:27];
        assign address_dmem = executeOut;
        assign data = wm_bypass ? data_writeReg : executeB;
        assign wren = (opcodeM == 5'b00111);

        wire [31:0] PC_W;
        register MW_PC(.clk(~clock), .clr(reset), .en(~md_stall), .q(PC_W), .d(PC_M));
        wire [31:0] exception_W;
        register MW_EX(.clk(~clock), .clr(reset), .en(~md_stall), .q(exception_W), .d(exception_M));
        wire [31:0] memoryOut;
        wire [31:0] mwo_d = (opcodeM == 5'b01000) ? q_dmem : executeOut;
        register MW_O(.clk(~clock), .clr(reset), .en(~md_stall), .q(memoryOut), .d(mwo_d));
        wire [31:0] insn_W;
        register MW_IR(.clk(~clock), .clr(reset), .en(~md_stall), .q(insn_W), .d(insn_M));

        // ==================== WRITEBACK ====================
        wire [4:0] opcodeW = insn_W[31:27];
        wire is_jal_W = (opcodeW == 5'b00011);
        wire is_setx_W = (opcodeW == 5'b10101);

        assign ctrl_writeReg = (exception_W || is_setx_W) ? 5'd30 : is_jal_W ? 5'd31 : insn_W[26:22];
        assign data_writeReg = exception_W ? exception_W : is_setx_W ? {5'b0, insn_W[26:0]} : is_jal_W ? PC_W : memoryOut;
        wire rwe = (opcodeW == 5'b00000 || opcodeW == 5'b00101 || opcodeW == 5'b01000 || is_jal_W || is_setx_W || exception_W);
        assign ctrl_writeEnable = rwe;

        // By-pass detection

        //MX
        wire m_writes_reg = (opcodeM == 5'b00000 || opcodeM == 5'b00101 || opcodeM == 5'b01000 || opcodeM == 5'b10101 || opcodeM == 5'b00011 || (exception_M != 32'b0));

        wire [4:0] m_rd = (exception_M != 32'b0 || opcodeM == 5'b10101) ? 5'd30 : opcodeM == 5'b00011 ? 5'd31 : insn_M[26:22];
        wire [4:0] x_rs = (opcodeX == 5'b10110) ? 5'd30 : ((opcodeX == 5'b00010) || (opcodeX == 5'b00110)) ? insn_X[26:22] : insn_X[21:17];
        wire [4:0] x_rt = opcodeX == 5'b00111 ? insn_X[26:22] : ((opcodeX == 5'b00010) | (opcodeX == 5'b00110))  ? insn_X[21:17] : insn_X[16:12];

        wire m_is_lw = (opcodeM == 5'b01000);
        wire mx_bypass_A = m_writes_reg && !m_is_lw && (m_rd == x_rs) && (m_rd != 0);
        wire mx_bypass_B = m_writes_reg && !m_is_lw && (m_rd == x_rt) && (m_rd != 0);
        wire mx_bypass_lw_B = m_is_lw && (m_rd == x_rt) && (m_rd != 0);

        // WX
        wire wx_bypass_A = rwe && (ctrl_writeReg != 5'd0) && (ctrl_writeReg == x_rs) && !mx_bypass_A;
        wire wx_bypass_B = rwe && (ctrl_writeReg != 5'd0) && (ctrl_writeReg == x_rt) && !mx_bypass_B;

        // WM
        wire wm_bypass = rwe && (ctrl_writeReg != 5'd0) && (opcodeM == 5'b00111) && (ctrl_writeReg == insn_M[26:22]);

        wire [31:0] m_bypass_val = (exception_M != 32'b0) ? exception_M : (opcodeM == 5'b10101)   ? {5'b0, insn_M[26:0]} : (opcodeM == 5'b00011) ? PC_M : executeOut;

        // JR bypass
        wire x_is_jal  = (opcodeX == 5'b00011);
        wire x_is_setx = (opcodeX == 5'b10101);
        wire x_exception = (exception_code != 32'b0);

        wire x_writes_reg = (opcodeX == 5'b00000 || opcodeX == 5'b00101 || x_is_jal || x_is_setx || x_exception);

        wire [4:0] x_rd = (x_exception | x_is_setx) ? 5'd30 : x_is_jal ? 5'd31 : insn_X[26:22];

        wire [31:0] x_value = x_exception ? exception_code :
                            x_is_setx   ? {5'b0, insn_X[26:0]} :
                            x_is_jal    ? PC_X :
                                            alu_out;

        wire [4:0] jr_src = insn_D[26:22];

        wire jr_x_bypass = x_writes_reg && !is_lw_X && (x_rd != 5'd0) && (x_rd == jr_src);
        wire jr_mx_bypass = m_writes_reg && !m_is_lw && (m_rd != 5'd0) && (m_rd == jr_src) && !jr_x_bypass;
        wire jr_lw_mx_bypass = m_is_lw && (m_rd != 5'd0) && (m_rd == jr_src) && !jr_x_bypass;
        wire jr_wx_bypass = rwe && (ctrl_writeReg != 5'd0) && (ctrl_writeReg == jr_src) && !jr_x_bypass && !jr_mx_bypass && !jr_lw_mx_bypass;

        wire [31:0] jr_target = jr_x_bypass    ? x_value :
                                jr_mx_bypass   ? m_bypass_val :
                                jr_lw_mx_bypass ? q_dmem :
                                jr_wx_bypass   ? data_writeReg :
                                                data_readRegA;

        //load-use stall
        wire is_lw_X = (opcodeX == 5'b01000);
        wire [4:0] d_rs = (insn_D[31:27] == 5'b10110) ? 5'd30 : (insn_D[31:27] == 5'b00100) ? insn_D[26:22] : is_branch_D ? insn_D[26:22] : insn_D[21:17];
        wire [4:0] d_rt = (insn_D[31:27] == 5'b00111) ? insn_D[26:22] : is_branch_D ? insn_D[21:17] : insn_D[16:12];

        wire load_use_stall = is_lw_X && (insn_X[26:22] != 5'd0) && ((insn_X[26:22] == d_rs) || (insn_X[26:22] == d_rt));
        
        /* END CODE */

    endmodule
