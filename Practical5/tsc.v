
module tsc ( 
clk, 
start, 
reset, 
sendBuf, 
data,
trig,
requestToSend,
completeData,
triggerMeasurements,
ready
);

    // -----declaring the inputs
    input wire clk;
    input wire start;
    input wire reset;
    input wire sendBuf;
    input wire [7:0] data;
    input wire trig;

    //----declaring the outputs
    output reg requestToSend;
    output reg completeData; 
    output reg [31:0] triggerMeasurements;
    output wire ready;
    output wire sd; //serial data output

    //---- declaring the internal registers

    reg [0:31] timer;
    reg [0:31] trigVal
    //need to make a ring buffer somehow not sure if this is the correct order
    reg [0:31] ringBuf [0:8];
    

    //making local params for readability of the states
    localparam  IDLE = 3'b000,
                RUNNING = 3'b001,
                TRIGGERED = 3'b010,
                SENDBUFFER = 3'b011,
                RESET = 3'b100;
    
    //setting the current state into the IDLE
    reg [0:3] currentState = RESET;


    //Reset on clock, not sure if we need this but need to transition states using this always@() style
    always@(posedge clk) begin
        case (currentState)
            RESET: begin
                //resets all the values
                currentState <= IDLE;
                head <= 32'h0;
                tail; <= 32'h0;
                triggerDetected <= 1'b0;
                completeData <= 1'b0;
            end
            IDLE: begin
                if(start) //go to running mode
                    currentState <= RUNNING;
                end
                if(reset) //go to reset mode
                    currentState <= RESET;
                end
                if(sendBuf) //go to sendBuffer mode
                    currentState <= SENDBUFFER;
                end
            end
            RUNNING: begin
                

                currentState <= IDLE
            end
            SENDBUFFER: begin

                currentState <= IDLE
            end
        endcase 
    end


endmodule;