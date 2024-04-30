`include "tsc.v"
`timescale 10ns / 1ns

module TSC_tb();
parameter CLK_PERIOD = 10; // Clock period in ns

// Declare inputs as regs and outputs as wires
//From ADC
reg rdy;
reg [7:0] dat;
//To ADC
wire req;
wire rst;

//External inputs
reg clk;
reg start;
reg reset;
reg SBF;
//External Outputs
wire [31:0] CD;
wire TRD;
wire SD;


// Signals

// Instantiate ADC module
tsc tsc_init (
    .rdy(rdy),
    .dat(dat),
    .req(req),
    .rst(rst),
    .clk(clk),
    .start(start),
    .reset(reset),
    .SBF(SBF),
    .CD(CD),
    .TRD(TRD),
    .SD(SD)
);

// Initialize all variables
initial begin 
  $display("Started");
  $dumpfile("Test2.vcd");
  $dumpvars(0,TSC_tb);
  	
  //set intial values of thingies
  rdy = 0;
  dat = 8'h00;
  
  clk = 0;
  start = 0;
  reset =0;
  SBF =0;

  //checking the operation of the states
  #10 reset =1; //reseting
  #10 reset = 0;
  #10 start = 1;
  #10 start = 0;  //go into RUNNING mode (001)
  #20 dat = 8'h00;//go to triggered mode for 16 clocks then back to idle
  #10 dat = 8'hD6; 
  #160 // should go into idle now
  #10 SBF =1; // go to send buf mode
  $display("Finished");
  #160 $finish;
 
end

// Clock generator
always begin
  #1 clk = ~clk; // Toggle clock every 5 ticks
end

// Connect DUT to test bench
    
endmodule