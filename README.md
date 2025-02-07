
# SBUS / UART Implementation

A very simple UART inverted and Futaba S.BUS implementation, written in Verilog.
Based on `ben-marshall/uart` repository.

---

This is a really simple implementation of a Universal Asynchronous Reciever
Transmitter (UART) modem.

And also it its inverted version with frame decoder known as Futaba S.BUS protocol.

Added a block of Start-bit detection, as well as a monitoring module.

It can be synthesised for use with FPGAs, and is
small enough to sit along side most existing projects as a peripheral.

It was adapted for Quartus Prime Lite Edition(23.1std),
it's free so should cost you nothing to setup and play with in your own simulations.

I have tested it with a Intel/Altera FPGA using the QMTech® CycloneIV Starter Kit board.
It runs happily using a 50MHz clock and so long as you buffer 
the input and output pins properly, should be able to run much faster.

This isn't the smallest or the fastest UART implementation around, but it
should be the easiest to integrated into a project.

## Tools

- [Quartus Prime Lite Edition](https://www.intel.com/content/www/us/en/software-kit/825278/intel-quartus-prime-lite-edition-design-software-version-23-1-1-for-windows.html)
- [Questa Intel Starter FPGA Edition](https://www.intel.com/content/www/us/en/software-kit/795215/questa-intel-fpgas-standard-edition-software-version-23-1.html)

Both for Windows.


## Simulation

To run the simple testbench, you can use the `tb.v`.
There was built the separate testbenches for the RX and TX modules `tb_rx.v` `tb_tx.v`.
Run their simulations, and output their wave files to `.\simulation\questa\waves-??.vcd`

## Implementation

When implemented on my development board using the constraints file in
`./constraints` and  default synthesis strategy, the following
utilisation numbers are reported:

Module  | Slice LUTs | Slice Registers | Slices | LUT as Logic | LUT FF Pairs
--------|------------|-----------------|--------|--------------|--------------
`uart_rx` | 51       | 47              | 26     | 51           | 29
`uart_tx` | 35       | 31              | 18     | 35           | 21

## Modules

### `impl_top`

The top level for the implementation (synthesis) of the simple echo test.

### `uart_rx`

The reciever module.

```verilog
module uart_rx(
input                   clk          , // Top level system clock input.
input                   resetn       , // Asynchronous active low reset.
input                   uart_rxd     , // UART Recieve pin.
input                   uart_rx_en   , // Recieve enable
output                  uart_rx_break, // Did we get a BREAK message?
output                  uart_rx_valid, // Valid data recieved/available.
output [PAYLOAD_BITS:0] uart_rx_data   // The recieved data.
);

parameter   BIT_RATE = 100000;      // Input bit rate of the UART line.
parameter   CLK_HZ   = 100000000; // Clock frequency in hertz.
parameter   PAYLOAD_BITS    = 8;  // Number of data bits per UART packet.
parameter   STOP_BITS       = 2;  // Stop bits per UART packet.
```

### `uart_tx`

The transmitter module.

```verilog
module uart_tx(
input                     clk         , // Top level system clock input.
input                     resetn      , // Asynchronous active low reset.
output                    uart_txd    , // UART transmit pin.
output                    uart_tx_busy, // Module busy sending previous item.
input                     uart_tx_en  , // Send the data on uart_tx_data
input  [PAYLOAD_BITS-1:0] uart_tx_data  // The data to be sent
);

parameter   BIT_RATE = 100000;      // Input bit rate of the UART line.
parameter   CLK_HZ   = 100000000; // Clock frequency in hertz.
parameter   PAYLOAD_BITS    = 8;  // Number of data bits per UART packet.
parameter   STOP_BITS       = 2;  // Stop bits per UART packet.
```
