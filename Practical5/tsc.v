//still to do:
// implement the head and tail buffer correctly



module tsc ( 
                //clk, 
                //start, 
                //reset, 
                //sendBuf, 
                //data,
                //trig,
                //requestToSend,
                //completeData,
                //triggerMeasurements,
                //ready

    // -----declaring the ADC comms         
    input wire rdy,      // Ready signal from ADC
    input wire [7:0] dat, // Data input from the ADC array   
    output wire req,      // Request signal to ADC
    output wire rst,      // Reset signal for ADC

    // -----declaring the ext device comms
    input wire clk,
    input wire start,
    input wire reset,
    input wire SBF,
    output reg [31:0] CD, 
    output reg TRD,
    output reg SD //serial data output


);
    //---- declaring the internal registers

    reg [0:31] timer;
    reg [0:7] trigVal =8'hD5; // hardcoded value for trigger -> see prac 5
   
    reg [0:31] trigTM; //this will store the time when triggered
    //need to make a ring buffer somehow not sure if this is the correct order
    reg [0:31] ringBuf [0:8];
    reg [0:4]  head;
    reg [0:4] tail;

    //making local params for readability of the states
    localparam  RESET = 3'b100,
                IDLE = 3'b000,
                RECORD = 3'b001,
                TRIGGERED = 3'b010,
                SENDBUFFER = 3'b011;
                
    
    //setting the current state into the IDLE
    reg [0:5] currentState = RESET;


    //startup conditions
    initial
        begin
           currentState <= RESET; 
        end


    //Reset on clock, not sure if we need this but need to transition states using this always@() style
    always@(posedge reset) begin
        currentState <= RESET;
        //resets all the values
        currentState <= IDLE;
        head <= 5'h0;
        tail <= 5'h0;
        TRD <= 1'b0;
        CD <= 1'b0;
    end

    always@(posedge start) begin
        currentState <= RECORD;
    end

    always@(posedge SBF) begin
        currentState <= SENDBUFFER;
    end

    always@(posedge clk) begin
        case (currentState)
            IDLE: begin
                //Read ADC value here and compare to threshhold
              /*  if(start) //go to running mode
                    currentState <= RUNNING;
                end
                if(reset) //go to reset mode
                    currentState <= RESET;
                end
                if(sendBuf) //go to sendBuffer mode
                    currentState <= SENDBUFFER;
                end*/
            end
            RECORD: begin
                timer <= timer +1; // increment the clock
                ringBuf[tail] <= dat; // store the data in the ring buffer 
                tail <= (tail+1)%32; //increment the tail   
                if(tail >= head) begin // if it has gone around the loop shift 
                    head <= (head +1) % 32;
                end    
                if(dat > trigVal) begin //now need to shift into a new state if the trigger value is high enough
                    trigTM <= timer;
                    currentState <= TRIGGERED;
                end
                currentState <= IDLE;    
            end
            TRIGGERED: begin
                //needs to store the next 16 values from adc
                if((trigTM - timer)> 16) begin
                    ringBuf[tail] <= dat;
                    tail <= tail+ 1'b1;
                    timer <= timer +1;//increment the timer
                end
                else begin
                    currentState <= IDLE;
                    TRD = 1'b1;
                    SD <= 1'b0; //start condition
                    CD <= 1'b0; // not complete
                end
            end
            SENDBUFFER: begin
            //needs to send ring buff out via SD Lin
                if(tail!=head) begin
                    SD <= 1'b0; //start bit
                    SD <= ringBuf[tail];
                    if(tail ==0) begin// this will allow the buffer to loop around and not go negative
                        tail <=32;
                    end
                    tail <= tail -1;
                end
                CD <= 1'b0; //data sent through 
            end    

        endcase 
    end
endmodule;