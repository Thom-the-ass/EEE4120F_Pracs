`include "tsc.v"
`timescale 1ns /1 ns

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

  $dumpfile("tsc_tb_firstTest.vcd");
  $dumpvars(0,TSC_tb);
  $display ("time\t clk reset enable counter");	

  #10 clk = 0;
  #20 clk = 1;

end

// Clock generator
always begin
  #CLK_PERIOD clk = ~clk; // Toggle clock every 5 ticks
end

// Connect DUT to test bench
    
endmodule