// 
// Module: tb
// Notes:
// - Top level simulation testbench with Futaba S.Bus parameters
//

`timescale 1ns/1ns
`define WAVES_FILE "waves-rx.vcd"

module tb;
localparam DATA_BITS		= 8;
localparam PARITY_BIT	= 1;
localparam STOP_BITS		= 2;
localparam PAYLOAD_BITS = DATA_BITS+PARITY_BIT+STOP_BITS; // 11 bits packet length

reg        clk          ; // Top level system clock input.
reg        resetn       ;
reg        uart_rxd     ; // UART Recieve pin.
reg        uart_rx_en   ; // Recieve enable
wire       uart_rx_break; // Did we get a BREAK message?
wire       uart_rx_valid; // Valid data recieved and available.
wire       uart_rx_pe;		// Parity error
//wire       parity;			// Parity bit
wire       uart_rx_fe;		// Frame error
wire [PAYLOAD_BITS-1:0] uart_rx_data ; // The recieved data.

//
// Bit rate of the UART line we are testing.
localparam BIT_RATE = 100000;						// 100KHz
localparam BIT_P    = (1000000000/BIT_RATE);	// 10000ns

//
// Period and frequency of the system clock.
localparam CLK_HZ   = 50000000;					// 50MHz
localparam CLK_P    = 1000000000/ CLK_HZ;		// 20ns

//
// Make the clock tick.
always begin #(CLK_P/2) assign clk = ~clk; end


//
// Sends a single byte down the UART line.
task send_byte;
    input [PAYLOAD_BITS-1:0] to_send;
    integer i;
    begin
        //$display("Sending byte: %d at time %d", to_send, $time);

        #BIT_P;												// Line not active or Stop bits
		  uart_rxd = 1'b0;									// Start bit
        for(i=0; i < PAYLOAD_BITS; i = i+1) begin
            #BIT_P;  uart_rxd = to_send[i];			// Data bits with parity bit

            //$display("    Bit: %d at time %d", i, $time);
        end
        #BIT_P;
		  uart_rxd = 1'b1;									// High bit level for
        #1000;													// stop bits or line inactive
    end
endtask

//
// Checks that the output of the UART is the value we expect.
integer passes = 0;
integer fails  = 0;
task check_byte;
    input [PAYLOAD_BITS-1:0] expected_value;
    begin
        if(uart_rx_data == expected_value) begin
            passes = passes + 1;
            $display("%d/%d/%d [PASS] Expected %b and got %b", 
                     passes,fails,passes+fails,
                     expected_value, uart_rx_data);
        end else begin
            fails  = fails  + 1;
            $display("%d/%d/%d [FAIL] Expected %b and got %b", 
                     passes,fails,passes+fails,
                     expected_value, uart_rx_data);
        end
    end
endtask

//
// Run the test sequence.
reg [PAYLOAD_BITS-1:0] to_send; reg [PAYLOAD_BITS-1:0] to_send_0; reg to_send_1;
initial begin
    resetn  = 1'b0;
    clk     = 1'b0;
    uart_rxd = 1'b1;
	 
    #40 resetn = 1'b1;
    
    $dumpfile(`WAVES_FILE);
    $dumpvars(0,tb);

    uart_rx_en = 1'b1;

    #1000;
    repeat(2) begin
        to_send_0 = $random; // 32-bit signed integer
		  to_send_1 = ^(to_send_0[PAYLOAD_BITS-STOP_BITS-PARITY_BIT-1:0]);
		  to_send = {{STOP_BITS{1'b1}},{PARITY_BIT{to_send_1}},{to_send_0[PAYLOAD_BITS-STOP_BITS-PARITY_BIT-1:0]}};
        send_byte(to_send); check_byte(to_send);
	 end
	 #150000
	 uart_rxd = 1'b0; // Line active glitch start level
	 #BIT_P;
	 uart_rxd = 1'b1; // Line not active
    #1000;
    repeat(1) begin
        to_send_0 = $random; // 32-bit signed integer
		  to_send_1 = ^(to_send_0[PAYLOAD_BITS-STOP_BITS-PARITY_BIT-1:0]);
		  to_send = {{STOP_BITS{1'b1}},{PARITY_BIT{to_send_1}},{to_send_0[PAYLOAD_BITS-STOP_BITS-PARITY_BIT-1:0]}};
        send_byte(to_send); check_byte(to_send);
	 end	
    #150000
    repeat(4) begin
        to_send_0 = $random; // 32-bit signed integer
		  to_send_1 = ^(to_send_0[PAYLOAD_BITS-STOP_BITS-PARITY_BIT-1:0]);
		  to_send = {{STOP_BITS{1'b1}},{PARITY_BIT{to_send_1}},{to_send_0[PAYLOAD_BITS-STOP_BITS-PARITY_BIT-1:0]}};
        send_byte(to_send); check_byte(to_send);
	 end		  
    #150000
	 
    $display("BIT RATE      : %db/s", BIT_RATE );
    $display("CLK PERIOD    : %dns" , CLK_P    );
    //$display("CYCLES/BIT    : %d"   , i_uart_rx.CYCLES_PER_BIT);
    //$display("SAMPLE PERIOD : %d", CLK_P *i_uart_rx.CYCLES_PER_BIT);
    $display("BIT PERIOD    : %dns" , BIT_P    );

    $display("Test Results:");
    $display("    PASSES: %d", passes);
    $display("    FAILS : %d", fails);

    $display("Finish simulation at time %d", $time);
    $finish();
end


//
// Instance of the DUT
uart_rx /*#(
.BIT_RATE(BIT_RATE),
.CLK_HZ  (CLK_HZ)
)*/ i_uart_rx(
.clk          (clk          ), // Top level system clock input.
.resetn       (resetn       ), // Asynchronous active low reset.
.uart_rxd     (uart_rxd     ), // UART Recieve pin.
.uart_rx_en   (uart_rx_en   ), // Recieve enable
.uart_rx_break(uart_rx_break), // Did we get a BREAK message?
.uart_rx_valid(uart_rx_valid), // Valid data recieved and available.
.uart_rx_data (uart_rx_data ), // The recieved data.
.uart_rx_pe (uart_rx_pe),		// Parity error
//.parity(parity),					// Parity bit
.uart_rx_fe (uart_rx_fe)		// Frame error
);

endmodule