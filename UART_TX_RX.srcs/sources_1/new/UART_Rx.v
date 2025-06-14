module UART_Rx(
    input clk,   //internal clock 
    input reset, //active high reset
    input rx,    //serial input from the tx
    input baud_tick, 
    output reg [7:0] data_out,
    output reg rx_done,
    output reg rx_busy
    );
    
    parameter IDLE = 3'b000;    //wait for the rx faling edge
    parameter START= 3'b001;    //confirm the valid start bit (0)
    parameter DATA = 3'b010;    //receive 8 bit data
    parameter STOP = 3'b011;    //confirm ending of receiving by receiving bit 1
    parameter WAIT = 3'b100;    //go back to IDLE state 
    
    reg [2:0] current_state,next_state,bit_counter;
    reg [7:0] rx_shift_reg;         //hold receiving data
    reg [3:0] sample_tick_counter;  //4-bit counter to divide the baud_tick:
    
    //seqauential logics
    
    always @(posedge clk or posedge reset) begin 
        if(reset) begin 
            current_state <= IDLE;
            rx_done <=0;
            rx_busy <=0;
            bit_counter <=0;
            sample_tick_counter <=0;
            rx_shift_reg <=0;
        end
        
        else begin
            current_state <= next_state;
            case(current_state)
                IDLE: begin 
                    rx_done<=0;
                    if(!rx) begin
                      rx_busy <=0;
                      bit_counter <=0;
                      sample_tick_counter <=0;
                      rx_shift_reg <=0;
                    end
                end
                START: begin 
                    
                end 
               
            endcase
        end
    end
    
   
    //next state logics are implemented in a combinational logic block
    always @(*) begin 
        next_state = current_state;
        case(current_state)
            
            IDLE: begin 
                if(!rx) next_state = START;
            end
            
            START: begin 
                if(baud_tick) begin 
                    if(sample_tick_counter==1) next_state = DATA;
                end
            end
            
            DATA : begin 
                if(baud_tick) begin 
                    if(bit_counter==8) next_state = STOP;
                end
            end
            
            STOP: begin 
                if(baud_tick) next_state = WAIT;
            end
            
            WAIT: next_state = IDLE;
           
            default: next_state = IDLE;    
        endcase
    end

endmodule
