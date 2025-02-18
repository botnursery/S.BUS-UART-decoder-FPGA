// 
// Module: impl_top
// 
// Notes:
// - Top level module to be used in an implementation.
// - To be used in conjunction with the constraints/defaults.xdc file.
// - Ports can be (un)commented depending on whether they are being used.
// - The constraints file contains a complete list of the available ports
//   including the chipkit/Arduino pins.
//	- Sample the recieved bit when in the middle of a bit frame.

module impl_top (
input               clk     , // Top level system clock input.
input               sw_0    , // Slide switches.
//input               sw_1  ,		// Slide switches.
//input   wire        uart_rx_en,// Recieve enable
input   wire        uart_rxd, // UART Recieve pin.
output  wire        uart_txd, // UART transmit pin.
output  wire [7:0]  led,		// Monitor data frame output.
output  wire uart_rx_break,	// Did we get a BREAK message?
output  wire uart_rx_valid,	// Valid data recieved and available.
output  wire uart_tx_busy,		// Module busy sending previous item.
output  wire uart_rx_fe,		// Frame error
output  wire uart_rx_pe,		// Check if even parity bit matches.
output  wire [PAYLOAD_BITS-1:0] uart_rx_data, // The recieved data payload.
output  wire [SHIFT_REG_LEN-1:0] sbus_frame, // 25 bytes SBUS frame output.
output  wire sbus_frame_valid	// True if SBUS frame of packet received and valid.
);

// Clock frequency in hertz.
parameter CLK_HZ = 50000000;
parameter BIT_RATE =   100000;
parameter PAYLOAD_BITS = 11; // max 4 bits representing a number, includes parity if present and stops
parameter SHIFT_REG_LEN = 200; // 25 bytes SBUS frame output
parameter STOP_BITS = 0; 		// 1 or 2
// --------------------------------------------------------------------------- 
// Internal connections
//

wire [PAYLOAD_BITS-1:0]  uart_tx_data;
wire        uart_tx_en;

assign uart_tx_data = uart_rx_data;
assign uart_tx_en   = uart_rx_valid;

//
// UART RX
//
uart_rx #(
.BIT_RATE(BIT_RATE),
.PAYLOAD_BITS(PAYLOAD_BITS),
.CLK_HZ  (CLK_HZ  )
) i_uart_rx(
.clk          (clk          ), // Top level system clock input.
.resetn       (sw_0         ), // Asynchronous active low reset.
.uart_rxd     (uart_rxd     ), // UART Recieve pin.
.uart_rx_en   (1'b1         ), // Recieve enable
.uart_rx_break(uart_rx_break), // Did we get a BREAK message?
.uart_rx_valid(uart_rx_valid), // Valid data recieved and available.
.uart_rx_fe(uart_rx_fe),		// Frame error
.uart_rx_pe(uart_rx_pe),		// Check if even parity bit matches.
.uart_rx_data (uart_rx_data )  // The recieved data.
);

//
// UART Transmitter module.
//
uart_tx #(
.BIT_RATE(BIT_RATE),
.PAYLOAD_BITS(PAYLOAD_BITS),
.CLK_HZ  (CLK_HZ  )
) i_uart_tx(
.clk          (clk          ),
.resetn       (sw_0         ),
.uart_txd     (uart_txd     ),
.uart_tx_en   (uart_tx_en   ),
.uart_tx_busy (uart_tx_busy ),
.uart_tx_data (uart_tx_data ) 
);

//
// UART MONITOR
//
monitor_rx #(
.PAYLOAD_BITS(PAYLOAD_BITS),
.STOP_BITS(STOP_BITS)
) i_monitor_rx(
.clk			(clk          ), // Top level system clock input.
.sw_0			(sw_0         ), // Asynchronous active low reset.
//.display		(sw_1         ), // RX/SBUS data view.
.uart_rx_break(uart_rx_break), // Did we get a BREAK message?
.uart_rx_valid(uart_rx_valid), // Valid data recieved and available.
.uart_rx_data (uart_rx_data ), // The recieved data.
.uart_tx_busy (uart_tx_busy), // Module busy sending previous item.
.led (led)							// Monitor data frame output.
);

//
// SBUS DECODER
//
sbus_puzzle i_sbus_puzzle(
.clk				(clk          ), // Top level system clock input.
.resetn			(sw_0         ), // Asynchronous active low reset.
.uart_rx_valid(uart_rx_valid), // Valid data recieved and available.
.uart_rx_fe(uart_rx_fe),		// Frame error
.uart_rx_pe(uart_rx_pe),		// Check if even parity bit matches.
.uart_rx_data(uart_rx_data),	// The recieved data.
.sbus_frame(sbus_frame),				// SBUS frame output.
.sbus_frame_valid(sbus_frame_valid)	// True if SBUS frame of packet received and valid.
);

endmodule
