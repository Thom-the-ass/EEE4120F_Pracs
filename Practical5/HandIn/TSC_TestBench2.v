`include "tsc.v"
`timescale 1ns / 1ps

module tSC_TestBench2();
integer i;
parameter CLK_PERIOD = 10; // Clock period in ns

// Declare inputs as regs and outputs as wires
//From ADC
reg rdy;
reg [7:0] dat;
//To ADC
wire req;

//External inputs
reg clk;
reg start;
reg reset;
reg SBF;
//External Outputs
wire CD;
wire TRD;
wire SD;


//ADC DATA
reg [0:7] adc_data [0:15];

    

// Instantiate ADC module
tsc tsc_init (
    .rdy(rdy),
    .dat(dat),
    .req(req),
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
  $dumpfile("Test3.vcd");
  $dumpvars(0,tSC_TestBench2);
  	
  //set intial values of thingies
  rdy = 0;
  dat = 8'h00;
  i = 0;
  clk = 0;
  start = 0;
  reset =0;
  SBF =0;
  dat = 0;
// adc dataValues
  adc_data[ 0] = 8'h00;
adc_data[ 1] = 8'h0A;
adc_data[ 2] = 8'h99;
adc_data[ 3] = 8'h9B;
adc_data[ 4] = 8'h93;
adc_data[ 5] = 8'hD5; // this should trigger it 
adc_data[ 6] = 8'h97;
adc_data[ 7] = 8'h90;
adc_data[ 8] = 8'h9F;
adc_data[ 9] = 8'hD7;
adc_data[10] = 8'h8D;
adc_data[11] = 8'h9C;
adc_data[12] = 8'h85;
adc_data[13] = 8'h8A;
adc_data[14] = 8'h91;
adc_data[15] = 8'h8C;

  //checking the operation of the states
  #10 reset =1; //reseting
  #10 reset = 0;
  #10 start = 1;
  #10 start = 0;  //go into RECORD mode (001)
  #1 rdy = 1; // ADC pulsing the ready line
  #1 rdy = 0;
  //sending a bunch of data to (as if it was the ADC)
  while(req ==1) begin
    #10 dat = adc_data[i%16];
    i<= i+1;
  end
  
  #10 SBF =1; // go to send buf mode
  $display("Finished");
  #1200 $finish;
  
end

// Clock generator
always begin
  #2 clk = ~clk; // Toggle clock every 5 ticks
end

// Connect DUT to test bench
    
endmodule