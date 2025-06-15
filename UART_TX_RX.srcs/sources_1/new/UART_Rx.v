module UART_Rx(
    input clk,
    input reset,
    input rx,
    input baud_tick, 
    output reg [7:0] data_out,
    output reg rx_done,
    output reg rx_busy,
    output reg frame_error
);
    
    parameter IDLE  = 3'b000;
    parameter START = 3'b001;
    parameter DATA  = 3'b010;
    parameter STOP  = 3'b011;
    
    reg [2:0] current_state, next_state;
    reg [2:0] bit_counter;
    reg [7:0] rx_shift_reg;
    reg [3:0] sample_tick_counter;
    
    always @(posedge clk or posedge reset) begin 
        if (reset) begin 
            current_state <= IDLE;
            rx_done <= 0;
            rx_busy <= 0;
            bit_counter <= 0;
            frame_error <= 0;
            sample_tick_counter <= 0;
            rx_shift_reg <= 0;
            data_out <= 0;
        end else begin
            current_state <= next_state;
            
            case (current_state)
                IDLE: begin 
                    rx_done <= 0;
                    frame_error <= 0;
                    if (!rx) begin
                        rx_busy <= 1;
                        sample_tick_counter <= 0;
                        bit_counter <= 0;
                        rx_shift_reg <= 0;
                    end
                end
                
                START: begin 
                    if (baud_tick) begin 
                        sample_tick_counter <= sample_tick_counter + 1;
                        if (sample_tick_counter == 4'h8) begin  // Sample at middle
                            if (rx) begin
                                frame_error <= 1;
                                rx_busy <= 0;
                            end
                        end
                    end
                end
                
                DATA: begin 
                    if (baud_tick) begin 
                        sample_tick_counter <= sample_tick_counter + 1;
                        if (sample_tick_counter == 4'h8) begin  // Sample at middle
                            rx_shift_reg <= {rx_shift_reg[6:0], rx};  // LSB first
                        end
                        if (sample_tick_counter == 4'hF) begin
                            sample_tick_counter <= 0;
                            bit_counter <= bit_counter + 1;
                        end
                    end
                end
                
                STOP: begin
                    if (baud_tick) begin
                        sample_tick_counter <= sample_tick_counter + 1;
                        if (sample_tick_counter == 4'h8) begin  // Sample at middle
                            data_out <= rx_shift_reg;
                            rx_done <= (rx == 1);
                            frame_error <= (rx != 1);
                            rx_busy <= 0;
                        end
                    end
                end
            endcase
        end
    end

    always @(*) begin 
        next_state = current_state;
        case (current_state)
            IDLE:
                if (!rx)
                    next_state = START;

            START:
                if (baud_tick && sample_tick_counter == 4'hF)
                    next_state = DATA;

            DATA:
                if (bit_counter == 3'd7 && baud_tick && sample_tick_counter == 4'hF)
                    next_state = STOP;

            STOP:
                if (baud_tick && sample_tick_counter == 4'hF)
                    next_state = IDLE;

            default:
                next_state = IDLE;
        endcase
    end
endmodule