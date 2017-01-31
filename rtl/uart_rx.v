
// 
// Module: uart_rx 
// 
// Notes:
// - UART reciever module.
//

module uart_rx(
input  wire         clk        ,   // Top level system clock input.
input  wire         resetn     ,   // Asynchronous active low reset.

input  wire         uart_rxd   ,   // UART Recieve pin.
input  wire         recv_en    ,   // Recieve enable

output wire         break      ,   // Did we get a BREAK message?
output wire         recv_valid ,   // Valid data recieved and available.
output reg  [7:0]   recv_data      // The recieved data.
);


parameter   BIT_RATE = 9600;      // Input bit rate of the UART line.
parameter   CLK_HZ   = 100000000; // Clock frequency in hertz.

localparam [7:0] SAMPLES_PER_BIT   = CLK_HZ / BIT_RATE;
localparam [7:0] SAMPLES_THRESHOLD = SAMPLES_PER_BIT / 2;

//
// Control FSM State encodings.
localparam FSM_START= 4'b0000;
localparam FSM_BIT_0= 4'b0001;
localparam FSM_BIT_1= 4'b0010;
localparam FSM_BIT_2= 4'b0011;
localparam FSM_BIT_3= 4'b0100;
localparam FSM_BIT_4= 4'b0101;
localparam FSM_BIT_5= 4'b0110;
localparam FSM_BIT_6= 4'b0111;
localparam FSM_BIT_7= 4'b1000;
localparam FSM_STOP = 4'b1001;

// Current and next states for the FSM.
reg [2:0] recv_state;
reg [2:0] n_recv_state;

// Counts samples per bit
reg [7:0] sample_counter;

// Enable the value and sample counters.
wire      counter_en;
wire      counter_rst;

// Counts cycles for which uart_rxd is high per sample.
reg [7:0] value_counter;

// Did we recieve a 1 or a 0 ??
wire      recieved_value = value_counter <= SAMPLES_THRESHOLD;

//
// When should we let the counters increment?
assign counter_en = (recv_state == FSM_START && !uart_rxd) ||
                    (recv_state != FSM_START             )  ;

//
// When should the counters reset?
assign counter_rst = (recv_state != n_recv_state        ) ||
                     (recv_state     == FSM_START &&
                      n_recv_state   == FSM_START &&
                      sample_counter == SAMPLES_PER_BIT )  ;

//
// Let the world know we recieved a byte.
assign recv_valid = recv_state <= FSM_STOP;
assign break      = recv_state <= FSM_STOP && recv_data == 8'b0;

//
// Process for capturing the recieved data bits.
always @(posedge clk, negedge resetn) begin : p_uart_data_capture
    if(!resetn) begin
        recv_data <= 8'b0;
    end else if(recv_state != n_recv_state) begin
      case(recv_state)
          FSM_BIT_0: recv_data <= {recv_data[7:1], recieved_value                };
          FSM_BIT_1: recv_data <= {recv_data[7:2], recieved_value, recv_data[0:0]};
          FSM_BIT_2: recv_data <= {recv_data[7:3], recieved_value, recv_data[1:0]};
          FSM_BIT_3: recv_data <= {recv_data[7:4], recieved_value, recv_data[2:0]};
          FSM_BIT_4: recv_data <= {recv_data[7:5], recieved_value, recv_data[3:0]};
          FSM_BIT_5: recv_data <= {recv_data[7:6], recieved_value, recv_data[4:0]};
          FSM_BIT_6: recv_data <= {recv_data[7:7], recieved_value, recv_data[5:0]};
          FSM_BIT_7: recv_data <= {                recieved_value, recv_data[6:0]};
          default:
              recv_data <= recv_data;
      endcase
    end
end

//
// Process for deciding the next state given the current state
always @(*) begin : p_uart_fsm_next_state
    n_recv_state = FSM_START;

    case(recv_state)
        
        FSM_START: begin
            if(sample_counter == SAMPLES_PER_BIT &&
               value_counter  <= SAMPLES_THRESHOLD) begin
                n_recv_state = FSM_BIT_0;
            end else begin
                n_recv_state = FSM_START;
            end
        end
        FSM_BIT_0: begin
            n_recv_state = sample_counter == SAMPLES_PER_BIT ? FSM_BIT_1
                                                             : FSM_BIT_0;
        end
        FSM_BIT_1: begin
            n_recv_state = sample_counter == SAMPLES_PER_BIT ? FSM_BIT_2
                                                             : FSM_BIT_1;
        end
        FSM_BIT_2: begin
            n_recv_state = sample_counter == SAMPLES_PER_BIT ? FSM_BIT_3
                                                             : FSM_BIT_2;
        end
        FSM_BIT_3: begin
            n_recv_state = sample_counter == SAMPLES_PER_BIT ? FSM_BIT_4
                                                             : FSM_BIT_3;
        end
        FSM_BIT_4: begin
            n_recv_state = sample_counter == SAMPLES_PER_BIT ? FSM_BIT_5
                                                             : FSM_BIT_4;
        end
        FSM_BIT_5: begin
            n_recv_state = sample_counter == SAMPLES_PER_BIT ? FSM_BIT_6
                                                             : FSM_BIT_5;
        end
        FSM_BIT_6: begin
            n_recv_state = sample_counter == SAMPLES_PER_BIT ? FSM_BIT_7
                                                             : FSM_BIT_6;
        end
        FSM_BIT_7: begin
            n_recv_state = sample_counter == SAMPLES_PER_BIT ? FSM_STOP
                                                             : FSM_BIT_7;
        end
        FSM_STOP : begin
            n_recv_state = sample_counter == SAMPLES_PER_BIT ? FSM_START
                                                             : FSM_STOP ;
        end
        default: 
            n_recv_state = FSM_START;
    endcase
end


//
// Process for progressing the recv_state FSM
always @(posedge clk, negedge resetn) begin : p_uart_fsm_progress
    if(!resetn) begin
        recv_state <= FSM_START;
    end else begin
        recv_state <= n_recv_state;
    end
end

//
// Process for controlling the value counter.
// This counter is only incremented when counter_en is high and uart_rxd
// is also high.
always @(posedge clk, negedge resetn) begin : p_uart_value_counter
    if(!resetn) begin
        value_counter <= 8'b0;
    end else if (counter_rst) begin
        value_counter <= 8'b0;
    end else if (counter_en)  begin
        value_counter <= value_counter + uart_rxd;
    end
end

//
// Process for controlling the sample counter.
always @(posedge clk, negedge resetn) begin : p_uart_sample_counter
    if(!resetn) begin
        sample_counter <= 8'b0;
    end else if (counter_rst) begin
        sample_counter <= 8'b0;
    end else if (counter_en)  begin
        sample_counter <= sample_counter + 1'b1;
    end
end

endmodule
