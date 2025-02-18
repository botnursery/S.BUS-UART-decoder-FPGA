// 
// Module: sbus_puzzle
// Notes:
// - SBUS decoder.
//

module sbus_puzzle (
   input wire clk,						// Top level system clock input.
   input wire resetn,					// Asynchronous active low reset.
   input wire uart_rx_valid,			// Valid data recieved and available.
   input wire uart_rx_fe,				// Frame error
   input wire uart_rx_pe,				// Check if even parity bit matches.
   input wire [7:0] uart_rx_data,	// The recieved data byte.
	output reg [SHIFT_REG_LEN-1:0] sbus_frame, // 25 bytes SBUS frame output.
   output reg sbus_frame_valid		// True if SBUS frame of packet received and valid.
);

// --------------------------------------------------------------------------- 
// Internal parameters.

   // Define the length of the shift register 25 byte
   localparam SHIFT_REG_LEN = 200;

// Internal registers.
   // Shift register
   reg [SHIFT_REG_LEN-1:0] sbus_reg;
	 
// --------------------------------------------------------------------------- 
// Receive and check sbus packet
   
   // Initialize the shift register and control signals
   always @(posedge clk or negedge resetn) begin
      if (!resetn) begin
         sbus_reg <= {SHIFT_REG_LEN{1'b1}};
      end else if (uart_rx_valid) begin
         // Shift the register and load new data
         sbus_reg <= {uart_rx_data, sbus_reg[SHIFT_REG_LEN-1:8]};
		end
	end
	
	// Initialize the out sbus packet frame register and valid signal
   always @(posedge clk or negedge resetn) begin
      if (!resetn) begin
         sbus_frame <= {SHIFT_REG_LEN{1'b1}};
         sbus_frame_valid <= 1'b1; // True - no sbus packet ready
      // Check if the shift register is full and frame valid
      end else if
			((sbus_reg[7:0]==8'b11110000) 
			&& (sbus_reg[SHIFT_REG_LEN-1:SHIFT_REG_LEN-8]==8'b0))
		begin
				sbus_frame <= sbus_reg;
            sbus_frame_valid <= 1'b0;
		end else begin
            sbus_frame_valid <= 1'b1;
		end
   end

endmodule
