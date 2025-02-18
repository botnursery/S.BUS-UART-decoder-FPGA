// 
// Module: tb
// Notes:
// - Top level simulation testbench.
//

`timescale 1ns/1ns

module tb;
localparam DATA_BITS		= 8;
localparam PARITY_BIT	= 1;
localparam STOP_BITS		= 2;
localparam PAYLOAD_BITS = DATA_BITS+PARITY_BIT+STOP_BITS;
 
reg  clk        ;   // Top level system clock input.
reg  resetn     ;	  // Asynchronous active low reset.
wire [3:0] sw   ;   // Slide switches.
wire [7:0] led  ;   // Green Leds
reg  uart_rxd   ;   // UART Recieve pin.
wire uart_txd	 ;	  // UART transmit pin.
wire uart_rx_break; // Did we get a BREAK message?
wire uart_rx_valid; // Valid data recieved and available.
wire uart_tx_busy;  // Module busy sending previous item.
wire [PAYLOAD_BITS-1:0] uart_rx_data;// The recieved data.
wire [200-1:0] sbus_frame;// 25 bytes SBUS frame output.
wire sbus_frame_valid;	// SBUS frame of packet received and valid.
//
// Bit rate of the UART line we are testing.
localparam BIT_RATE = 100000;
localparam BIT_P    = (1000000000/BIT_RATE);

//
// Period and frequency of the system clock.
localparam CLK_HZ   = 50000000;
localparam CLK_P    = 1000000000/ CLK_HZ;

assign sw    = {2'b0, 1'b1, resetn};

//
// Make the clock tick.
always begin #(CLK_P/2) assign clk    = ~clk; end

//
// Sends a single byte down the UART line.
task send_byte;
    input [PAYLOAD_BITS-1:0] to_send;
    integer i;
    begin
        $display("Sending byte: %d, %b at time %d", to_send,to_send, $time);
        #BIT_P;  uart_rxd = 1'b0;
        for(i=0; i < PAYLOAD_BITS; i = i+1) begin
            #BIT_P;  uart_rxd = to_send[i];
            //$display("    Bit: %d at time %d", i, $time);
        end
        #BIT_P;  uart_rxd = 1'b1;
        #1000;
    end
endtask

//
// Writes a register via the UART
task write_register;
    input [7:0] register;
    input [7:0] value   ;
    begin
        $display("Write register %d with %h", register, value);
        send_byte(register);
        send_byte(value);
    end
endtask

//
// Reads a register via the UART
task read_register;
    input [7:0] register;
    begin
        $display("Read register: %d", register);
        send_byte(register);
    end
endtask

//
// Run the test sequence.
reg [PAYLOAD_BITS-1:0] to_send; reg [PAYLOAD_BITS-1:0] to_send_0; reg to_send_1; time moment;
initial begin
    resetn  = 1'b0;
    clk     = 1'b0;
    uart_rxd = 1'b1;
    #40 resetn = 1'b1;
    
    $dumpfile("waves-sys.vcd");     
    $dumpvars(0,tb);
	 
	 send_byte(11'b11011110000);	// hF0 start byte
    repeat(22) begin					// 22 data bytes
        to_send_0 = $random(moment);// 32-bit signed integer
		  to_send_1 = ^(to_send_0[PAYLOAD_BITS-STOP_BITS-PARITY_BIT-1:0]);
		  to_send = {{STOP_BITS{1'b1}},{PARITY_BIT{to_send_1}},{to_send_0[PAYLOAD_BITS-STOP_BITS-PARITY_BIT-1:0]}};
        send_byte(to_send);
	 end
	 send_byte(11'b11011000000);	// hC0 flags byte
	 send_byte(11'b11000000000);	// h00 stop byte
	
   // send_byte(11'b11001000001);	// h41 ok 11'b11001000001
   // send_byte(11'b01100110001);	// h31 stop-error 11'b01100110001
   /*
    send_byte("B");	// h42
    send_byte("2");	// h32
    
    send_byte("C");	// h43
    send_byte("3");	// h33
    
    send_byte("D");	// h44
    send_byte("4");	// h34
   */
   // send_byte(11'b11101111110);	// ~ h7e parity-error 11'b11101111110 // 0 h30
	/*
    send_byte("a");	// h61
    send_byte("b");	// h62
    send_byte("c");	// h63
    send_byte("d");	// h64
    
    send_byte(0);		// h00
    send_byte(0);		// h00
	*/
    $display("Finish simulation at time %d", $time);
	 #150000
    $finish();
end

//
// Instance the top level implementation module.
impl_top /*#(
.BIT_RATE(BIT_RATE),
.CLK_HZ  (CLK_HZ  )
)*/ i_dut (
.clk      (clk     ),   // Top level system clock input.
.sw_0     (sw[0]   ),   // Slide switches.
.led      (led     ),   // Green Leds
.uart_rxd (uart_rxd),   // UART Recieve pin.
//.uart_rx_en   (uart_rx_en   ), // Recieve enable
.uart_rx_break(uart_rx_break), // Did we get a BREAK message?
.uart_rx_valid(uart_rx_valid), // Valid data recieved and available.
.uart_rx_fe(uart_rx_fe),		// Frame error
.uart_rx_pe(uart_rx_pe),		// Check if even parity bit matches.
.uart_rx_data (uart_rx_data),	// The recieved data.
.uart_tx_busy(uart_tx_busy),	// Module busy sending previous item.
.uart_txd (uart_txd),			// UART transmit pin.
.sbus_frame(sbus_frame),		// SBUS frame output.
.sbus_frame_valid(sbus_frame_valid)	// True if SBUS frame of packet received and valid.
);

endmodule
