
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
    input wire [0:7] data;
    input wire trig;

    //----declaring the outputs
    output wire requestToSend;
    output wire completeData; 
    output reg [31:0] triggerMeasurements
    output wire ready;

    //---- declaring the internal registers

    reg [0:31] timer;
    reg [0:31] trigVal
    //need to make a ring buffer somehow not sure if this is the correct order
    reg [0:31] ringBuf [0:8];
    

    //making local params for readability of the states
    local params IDLE = 3'b000; 
    local params RUNNING = 3'b001;
    local params TRIGGERED = 3'b010;
    local params SENDBUFFER = 3'b011;
    local params RESET = 3'b100;
    
    //setting the current state into the IDLE
    //This is essentially sudo code at the moment -> will clean up after the idea makes sence
    reg [0:3] currentState = RESET;

    always@(posedge clk)
    case (currentState)
        RESET: begin
            //resets all the values
            currentState <= IDLE;
            head <= 32'h0;
            tao; <= 32'h0;
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
    endcase 
endmodule;