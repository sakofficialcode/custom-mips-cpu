module ServoController(
    input        clk, 		    // System Clock Input 100 Mhz
    input[9:0]   switches,	    // Position control switches
    output       servoSignal    // Signal to the servo
    );	
        
    wire[9:0] duty_cycle;
    
    ////////////////////
	// Your Code Here //
	////////////////////
    wire pos;
    assign pos = switches[0];
    assign duty_cycle = pos ? 10'd51 : 10'd102;

    PWMSerializer #(.PERIOD_WIDTH_NS(20000000), .SYS_FREQ_MHZ(100)) ServoSerializer(clk,1'b0,duty_cycle,servoSignal);
    
endmodule