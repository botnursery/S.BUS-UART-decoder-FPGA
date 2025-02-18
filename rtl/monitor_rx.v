// 
// Module: monitor_rx
//
// Notes:
// - UART monitor module.
//

module monitor_rx (
input  wire       clk        , // Top level system clock input.
input  wire       sw_0       , // Asynchronous active low reset.
input  wire [PAYLOAD_BITS-1:0] uart_rx_data,// The data to be monitored
input  wire       uart_rx_break, // Did we get a BREAK message?
input  wire       uart_rx_valid, // Valid data recieved and available.
input  wire       uart_tx_busy,	// Module busy sending previous item.
output wire [7:0] led				// Monitor data frame output.
);

// --------------------------------------------------------------------------- 
// External parameters.
// 

//
// Number of data bits recieved per UART packet.
parameter   PAYLOAD_BITS    = 0;

//
// Number of stop bits indicating the end of a packet.
parameter   STOP_BITS       = 0;

// --------------------------------------------------------------------------- 
// Internal registers.
// 

reg  [PAYLOAD_BITS-1:0]  led_reg;
assign      led = led_reg;

// Latch output byte
always @(posedge clk) begin
    if(!sw_0) begin
        led_reg <= 8'hF0;
    end else if(uart_rx_valid) begin
        led_reg <= uart_rx_data[PAYLOAD_BITS-1:0];
    end
end

endmodule
