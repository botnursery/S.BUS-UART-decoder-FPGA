// 
// Module: uart_rx 
// Notes:
// - UART reciever module.
//

module uart_rx(
input  wire       clk          , // Top level system clock input.
input  wire       resetn       , // Asynchronous active low reset.
input  wire       uart_rxd     , // UART Recieve pin.
input  wire       uart_rx_en   , // Recieve enable.
output wire       uart_rx_break, // Did we get a BREAK message?
output wire       uart_rx_valid, // Valid data recieved and available.
output wire       uart_rx_fe,		// Frame error
//output wire       parity,		// Parity bit calculated
output reg			uart_rx_pe,		// Check if even parity bit matches.
output reg  [PAYLOAD_BITS-1:0] uart_rx_data // The recieved data.
);

// --------------------------------------------------------------------------- 
// External parameters.
// 

//
// Input bit rate of the UART line.
parameter   BIT_RATE        = 100_000; // bits / sec
localparam  BIT_P           = 1_000_000_000 * 1/BIT_RATE; // nanoseconds

//
// Clock frequency in hertz.
parameter   CLK_HZ          =    50_000_000;
localparam  CLK_P           = 1_000_000_000 * 1/CLK_HZ; // nanoseconds

//
// Number of data bits recieved per UART packet.
// The presence of parity bit: 1 - present, 0 - not.
// Number of stop bits indicating the end of a packet 1 or 2.
localparam INVERTED  = 0;
localparam DATA_BITS = 8;
localparam PARITY_BIT = 1;
localparam STOP_BITS  = 2;
parameter PAYLOAD_BITS = DATA_BITS+PARITY_BIT+STOP_BITS;

// -------------------------------------------------------------------------- 
// Internal parameters.
// 

//
// Number of clock cycles per uart bit.
localparam       CYCLES_PER_BIT     = BIT_P / CLK_P;

//
// Size of the registers which store sample counts and bit durations.
localparam       COUNT_REG_LEN      = 1+$clog2(CYCLES_PER_BIT);

// -------------------------------------------------------------------------- 
// Internal registers.
// 

//
// Internally latched value of the uart_rxd line. Helps break long timing
// paths from input pins into the logic.
reg rxd_reg;
reg rxd_reg_0;
// If need inverted input
wire uart_rxd_inv;
assign uart_rxd_inv = (INVERTED) ? ~uart_rxd : uart_rxd;

//
// Storage for the recieved serial data.
reg [PAYLOAD_BITS-1:0] recieved_data;

//
// Counter for the number of cycles over a packet bit.
reg [COUNT_REG_LEN-1:0] cycle_counter;

//
// Counter for the number of recieved bits of the packet.
reg [3:0] bit_counter;

//
// Sample of the UART input line whenever we are in the middle of a bit frame.
reg bit_sample;

//
// Current and next states of the internal FSM.
reg [2:0] fsm_state;
reg [2:0] n_fsm_state;

localparam FSM_IDLE = 0;
localparam FSM_START= 1;
localparam FSM_RECV = 2;
localparam FSM_STOP = 3;

// --------------------------------------------------------------------------- 
// Output assignment
// 

assign uart_rx_break = uart_rx_valid && ~|recieved_data;
assign uart_rx_valid = fsm_state == FSM_STOP && n_fsm_state == FSM_IDLE;

always @(posedge clk) begin
    if(!resetn) begin
        uart_rx_data  <= {PAYLOAD_BITS{1'b0}};
    end else if (fsm_state == FSM_STOP) begin
        uart_rx_data  <= recieved_data;
    end
end

// --------------------------------------------------------------------------- 
// FSM next state selection.
// 

wire next_bit     = cycle_counter == CYCLES_PER_BIT ||
                        fsm_state       == FSM_STOP && 
                        cycle_counter   == CYCLES_PER_BIT/2;
wire payload_done = bit_counter   == PAYLOAD_BITS  ;

//
// Handle picking the next state.
always @(*) begin : p_n_fsm_state
    case(fsm_state)
        FSM_IDLE : n_fsm_state = rxd_reg      ? FSM_IDLE : FSM_START;
        FSM_START: n_fsm_state = next_bit     ? FSM_RECV : FSM_START;
        FSM_RECV : n_fsm_state = payload_done ? FSM_STOP : FSM_RECV ;
        FSM_STOP : n_fsm_state = next_bit     ? FSM_IDLE : FSM_STOP ;
        default  : n_fsm_state = FSM_IDLE;
    endcase
end

// --------------------------------------------------------------------------- 
// Internal register setting and re-setting.
// 

//
// Handle updates to the recieved data register.
integer i = 0;
always @(posedge clk) begin : p_recieved_data
    if(!resetn) begin
        recieved_data <= {PAYLOAD_BITS{1'b0}};
    end else if(fsm_state == FSM_IDLE             ) begin
        recieved_data <= {PAYLOAD_BITS{1'b0}};
    end else if(fsm_state == FSM_RECV && next_bit ) begin
        recieved_data[PAYLOAD_BITS-1] <= bit_sample;
        for ( i = PAYLOAD_BITS-2; i >= 0; i = i - 1) begin
            recieved_data[i] <= recieved_data[i+1];
        end
    end
end

//
// Increments the bit counter when recieving.
always @(posedge clk) begin : p_bit_counter
    if(!resetn) begin
        bit_counter <= 4'b0;
    end else if(fsm_state != FSM_RECV) begin
        bit_counter <= {COUNT_REG_LEN{1'b0}};
    end else if(fsm_state == FSM_RECV && next_bit) begin
        bit_counter <= bit_counter + 1'b1;
    end
end

//
// Sample the recieved bit when in the middle of a bit frame.
always @(posedge clk) begin : p_bit_sample
    if(!resetn) begin
        bit_sample <= 1'b0;
    end else if (cycle_counter == CYCLES_PER_BIT/2) begin
        bit_sample <= rxd_reg;
    end
end


//
// Increments the cycle counter when recieving.
always @(posedge clk) begin : p_cycle_counter
    if(!resetn) begin
        cycle_counter <= {COUNT_REG_LEN{1'b0}};
    end else if(next_bit) begin
        cycle_counter <= {COUNT_REG_LEN{1'b0}};
    end else if(fsm_state == FSM_START || 
                fsm_state == FSM_RECV  || 
                fsm_state == FSM_STOP   ) begin
        cycle_counter <= cycle_counter + 1'b1;
    end
end


//
// Progresses the next FSM state.
always @(posedge clk) begin : p_fsm_state
    if(!resetn) begin
        fsm_state <= FSM_IDLE;
    end else begin
        fsm_state <= n_fsm_state;
    end
end


//
// Responsible for updating the internal value of the rxd_reg.
always @(posedge clk) begin : p_rxd_reg
    if(!resetn) begin
        rxd_reg     <= 1'b1;
        rxd_reg_0   <= 1'b1;
    end else if(uart_rx_en) begin
        rxd_reg     <= rxd_reg_0;
        rxd_reg_0   <= uart_rxd_inv;
    end
end

// --------------------------------------------------------------------------- 
// Checking integrity
//

// Calculate parity by XORing all bits of uart_rx_data except the parity and stop bits
wire parity;
assign parity = ^(uart_rx_data[PAYLOAD_BITS-STOP_BITS-PARITY_BIT-1:0]);
// Always block to even check parity
always @(uart_rx_data) begin
    if (parity == uart_rx_data[PAYLOAD_BITS-STOP_BITS-1])
        uart_rx_pe <= 1'b0; // Parity matches - 0 
    else 
        uart_rx_pe <= PARITY_BIT ? 1'b1 : 1'b0; // Parity error - 1
end

// Stop bits check: error flag - 1
assign uart_rx_fe = STOP_BITS-1 ? ~&uart_rx_data[PAYLOAD_BITS-1:PAYLOAD_BITS-2] : ~uart_rx_data[PAYLOAD_BITS-1];

endmodule
