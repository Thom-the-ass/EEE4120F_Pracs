/* Thomas and Charlie's TSC module
*  4/30/2024
*/



module tsc ( 
          
    // -----declaring the ADC comms         
    input wire rdy,      // Ready signal from ADC
    input wire [7:0] dat, // Data input from the ADC array   
    
    output reg req,      // Request signal to ADC

    // -----declaring the ext device comms
    input wire clk,
    input wire start,
    input wire reset,
    input wire SBF,
    
    output reg CD, 
    output reg TRD,
    output reg SD //serial data output
    //test


);
    //---- declaring the internal registers

    reg [31:0] timer;
    reg [0:7] trigVal =8'hD5; // hardcoded value for trigger -> see prac 5
   
    reg [31:0] trigTM; //this will store the time when triggered
    reg [0:7] ringBuf [0:31];// ring buffer of 32 bytes
    reg [0:4]  head; // head and tail for FIFO
    reg [0:4] tail;

    reg [0:3] index; // this is the index to send out 1 bit at a time from SD
    reg dataAvaliable; // this will be triggered if that data is available to read from ADC
    
    //making local params for readability of the states
    localparam  RESET = 3'b100,
                IDLE = 3'b000,
                RECORD = 3'b001,
                TRIGGERED = 3'b010,
                SENDBUFFER = 3'b011;
                
    
    //setting the current state into the IDLE
    reg [3:0] currentState = IDLE;

    //startup conditions
    initial
        begin
           currentState <= RESET;
           timer <= 32'h00; 
           index <= 0;
           SD <= 0;
           req <= 0;
           
        end


    //Reset on clock, not sure if we need this but need to transition states using this always@() style
    always@(posedge reset) begin
        currentState <= RESET;
        //resets all the values
        currentState <= IDLE;
        head <= 5'h0;
        tail <= 5'h1;
        TRD <= 1'b0;
        CD <= 1'b0;
        req <= 0;
        dataAvaliable = 0;
    end
    always@(posedge rdy)begin
        dataAvaliable = 1'b1; // you are allowed to read from ADC
    end

    always@(posedge start) begin //edge trigger state shifter
        currentState <= RECORD;
    end

    always@(posedge SBF) begin //edge trigger state shifter
        currentState <= SENDBUFFER;
    end

    always@(posedge clk) begin
        case (currentState)
            IDLE: begin
                req <=0; // do nothing except tell the ADC you want nothing
            end
            RECORD: begin
                req <= 1'b1; // ask for adc to send data
                if(dataAvaliable) begin // wait for data to become available from ADC (should be super fast)
                    timer <= timer +1; // increment the clock
                    tail <= (tail+1)%32;// increment the tail
                    ringBuf[tail] <= dat; // store the data in the ring buffer    
                    if(head === tail) begin // if it has gone around the loop shift (don't let the tail get eaten by the head)
                        head <= (head +1) % 32;
                    end    
                    if(dat > trigVal) begin //now need to shift into a new state if the trigger value is high enough
                        trigTM <= timer;
                        currentState <= TRIGGERED; // move the triggered
                    end   
                end
            end
            TRIGGERED: begin
                //needs to store the next 16 values from adc
                if(dataAvaliable == 1) begin
                    timer <= timer +1;//increment the timer
                    if((timer - trigTM)< 16) begin // if it hasn't yet stored 16 more data bits store one more
                        ringBuf[tail] <= dat;
                        tail <= tail+ 1;   
                    end
                    else begin
                        currentState <= IDLE;
                        TRD = 1'b1; // output that you have been triggered
                        SD <= 1'b0; //start condition
                        CD <= 1'b0; // not complete
                    end
                    if(head == tail) begin // if it has gone around the loop shift 
                            head <= (head +1) % 32;
                    end
                end
            end
            SENDBUFFER: begin //also see the posedge clk to get a full understand how the data is sent out
            //needs to send ring buff out via SD Lin               
                if(tail!=head) begin // if havn't sent out whole buffer keep sending
                    if(index < 8) begin // if havent completed a byte yet keep trying
                        SD <= ringBuf[tail][index]; 
                        //sendsout a bit from the ring buf
                        index <= index +1;
                    end    
                    else begin //once sent out a byte -> go to the next item
                        SD <=1; // sets SD to zero at the start of every byte
                        index <= 0; //resetting to the starts of a vyte
                        if(tail ==0) begin// this will allow the buffer to loop around and not go negative
                            tail <=32;
                        end
                        tail <= tail -1; // decrementing the tail
                    end
                end
                else begin
                    CD <= 1'b1; //data sent through
                    currentState <= IDLE;
                end
            end    

        endcase 
    end
    always@(negedge clk) begin
        if(currentState == SENDBUFFER) begin
            SD <= 0;
            //sends a low at the start of every bit
        end
    end
endmodule;