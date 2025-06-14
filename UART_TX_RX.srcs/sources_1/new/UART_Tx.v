module UART_Tx(
    input clk,         // clk signal
    input reset,       // synchronous reset active high reset
    input tx_start,    // starting signal 
    input baud_tick,   // tick at the boud rate frequency
    input [7:0] data_in, // data to besent
    output reg tx_done,    // output of the UART_Tx
    output reg tx_busy,     // becomes high when data is transmitting
    output reg tx
    );
    
    parameter IDLE = 3'b000;    //wait for the tx to start
    parameter START= 3'b001;    //send the start bit (0)
    parameter DATA = 3'b010;    //send 8 bit data(LSB first)
    parameter STOP = 3'b011;    //stop sending data with bit 1
    parameter CLEANUP = 3'b100; //prepare for next transmission
    
    reg [2:0] current_state,next_state,bit_counter;
    reg [7:0] tx_shift_reg;
    
    always @(posedge clk or posedge reset) begin 
        if(reset) begin
            current_state <= IDLE;  
            tx_busy <= 0; //no transmission
            tx_done <=0;
            tx <= 1;      //no transmission
            tx_shift_reg <=0;
            bit_counter <=0;
        end
        
        else begin 
            current_state <= next_state;
            case(current_state)
                IDLE: begin 
                   tx <= 1;                 //tx line is high no transmission happens
                   tx_done <=0;
                   if(tx_start) begin
                    tx_shift_reg <= data_in; //loading the data to the shift register
                    bit_counter <=0; 
                    tx_busy <= 1;            //transmission is going to start so its goingto be busy
                   end 
                   else begin 
                    tx_busy <=0;            //no transmisison
                   end
                end
                
                START: begin 
                    if(baud_tick) tx <= 0;  //starting bit 0                   
                end
                
                DATA: begin 
                    if(baud_tick) begin 
                        tx <= tx_shift_reg[0];    //transmitting the LSB
                        tx_shift_reg <= tx_shift_reg >> 1;  //right shifting the shift reg by 1
                        bit_counter <= bit_counter + 1;
                    end
                end
                
                STOP: begin
                    if(baud_tick) tx <= 1;   //transmitting stop bit
                end
                
                CLEANUP: begin
                    tx_done <= 1;    //finish transmission
                    tx_busy <= 0;       
                end
            endcase
        end
    end
    
    //next state logics are implemented in a combinational logic block
    always @(*) begin 
        next_state = current_state;
        case(current_state)
            
            IDLE: begin 
                if(tx_start) next_state = START;
            end
            
            START: begin 
                if(baud_tick) next_state = DATA;
            end
            
            DATA : begin 
                if(baud_tick) begin 
                    if(bit_counter==8) next_state = STOP;
                end
            end
            
            STOP: begin 
                if(baud_tick) next_state = CLEANUP;
            end
            
            CLEANUP: next_state = IDLE;
           
            default: next_state = IDLE;    
        endcase
    end

    
    
endmodule