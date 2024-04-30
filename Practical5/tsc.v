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
    //need to make a ring buffer somehow not sure if this is the correct order
    reg [0:7] ringBuf [0:31];
    reg [0:4]  head;
    reg [0:4] tail;

    reg [0:3] index; // this is the index for outputting the variable
    reg dataAvaliable; // this will be triggered if that data is available to read
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
            /*
           ringBuf[ 0] = 8'h0;
           //creating an empty ringbuff
            ringBuf[ 1] = 8'h0;
            ringBuf[ 2] = 8'h0;
            ringBuf[ 3] = 8'h0;
            ringBuf[ 4] = 8'h0;
            ringBuf[ 5] = 8'h0;
            ringBuf[ 6] = 8'h0;
            ringBuf[ 7] = 8'h0;
            ringBuf[ 8] = 8'h0;
            ringBuf[ 9] = 8'h0;
            ringBuf[10] = 8'h0;
            ringBuf[11] = 8'h0;
            ringBuf[12] = 8'h0;
            ringBuf[13] = 8'h0;
            ringBuf[14] = 8'h0;
            ringBuf[15] = 8'h0;
            ringBuf[16] = 8'h0;
            ringBuf[17 ] =8'h0;
            ringBuf[18] =8'h0;
            ringBuf[19] = 8'h0;
            ringBuf[20] = 8'h0;
            ringBuf[21] = 8'h0;
            ringBuf[22] = 8'h0;
            ringBuf[23] = 8'h0;
            ringBuf[24] = 8'h0;
            ringBuf[25] =8'h0;
            ringBuf[26] = 8'h0;
            ringBuf[27] = 8'h0;
            ringBuf[28] = 8'h0;
            ringBuf[29] = 8'h0;
            ringBuf[30] = 8'h0;
            ringBuf[31] =8'h0;*/

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

    always@(posedge start) begin
        currentState <= RECORD;
    end

    always@(posedge SBF) begin
        currentState <= SENDBUFFER;
    end

    always@(posedge clk) begin
        case (currentState)
            IDLE: begin
                req <=0;
            end
            RECORD: begin
                req <= 1'b1; // ask for adc to send data
                if(dataAvaliable) begin
                    timer <= timer +1; // increment the clock
                    tail <= (tail+1)%32;
                    ringBuf[tail] <= dat; // store the data in the ring buffer    
                    if(head === tail) begin // if it has gone around the loop shift 
                        head <= (head +1) % 32;
                    end    
                    if(dat > trigVal) begin //now need to shift into a new state if the trigger value is high enough
                        trigTM <= timer;
                        currentState <= TRIGGERED;
                    end   
                end
                 //increment the tail
            end
            TRIGGERED: begin
                //needs to store the next 16 values from adc
                if(dataAvaliable == 1) begin
                    timer <= timer +1;//increment the timer
                    if((timer - trigTM)< 16) begin
                        ringBuf[tail] <= dat;
                        tail <= tail+ 1;   
                    end
                    else begin
                        currentState <= IDLE;
                        TRD = 1'b1;
                        SD <= 1'b0; //start condition
                        CD <= 1'b0; // not complete
                    end
                    if(head == tail) begin // if it has gone around the loop shift 
                            head <= (head +1) % 32;
                    end
                end
            end
            SENDBUFFER: begin
            //needs to send ring buff out via SD Lin               
                if(tail!=head) begin
                    if(index < 8) begin
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