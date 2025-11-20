// This code first writes until FIFO is full, then reads until it is empty
`timescale 1ns / 1ps

module tb_fifo_write_then_read;

  // Our defined parameters
  parameter DATASIZE = 8; // 8-bits of data
  parameter ADDRSIZE = 4; // 4-bits to represent address
  localparam DEPTH = (1 << ADDRSIZE); // Depth of FIFO is 16

  // Clock and reset signals
  logic wclk, rclk; // Write and read clocks
  logic wrst_n, rrst_n; // Write and read resets

  // FIFO interface signals
  // Write signals
  logic [DATASIZE-1:0] wdata; // Write data
  logic                winc; // Write enable
  logic                wfull, walmost_full; // Full and almost full flags

  // Read signals
  logic [DATASIZE-1:0] rdata; // Read data
  logic                rinc; // Read enable
  logic                rempty, ralmost_empty; // Empty and almost empty flags

  // FIFO instantiation
  fifo_top #(
    .DATASIZE(DATASIZE),
    .ADDRSIZE(ADDRSIZE)
  ) uut (
    .rdata         (rdata),
    .wfull         (wfull),
    .rempty        (rempty),
    .walmost_full  (walmost_full),
    .ralmost_empty (ralmost_empty),
    .wdata         (wdata),
    .winc          (winc),
    .wclk          (wclk),
    .wrst_n        (wrst_n),
    .rinc          (rinc),
    .rclk          (rclk),
    .rrst_n        (rrst_n)
  );
  
  
  // write data on positive edge of write clock
  always_ff @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin // If reset
      wdata <= 0; // Clear write data to 0
    end else if (winc) begin // Else if write is enabled
      wdata <= wdata + 1; // Write data = wdata + 1
    end
  end

  // 100 MHz write clock
  initial begin
    wclk = 0;
    forever #5 wclk = ~wclk;
  end

  // 67 MHz read clock
  initial begin
    rclk = 0;
    forever #7.5 rclk = ~rclk;
  end

  // Reset initially. After 20ns deassert reset for both read and write
  initial begin
    wrst_n = 0;
    rrst_n = 0;
    winc   = 0;
    rinc   = 0;
    #20;
    wrst_n = 1;
    rrst_n = 1;
  end

  // This part writes until FIFO is full, then pops until it is empty
  initial begin
    // Wait until FIFO is empty after reset
    wait (rempty == 1);
    $display("[%0t] FIFO is empty. Start of simulation", $time);

    // Start writing
    winc = 1;
    rinc = 0;

    // writing till FIFO asserts full
    @(posedge wfull);
    $display("[%0t] FIFO is full", $time);

    // Stop writing and begin reading
    winc = 0;
    rinc = 1;

    // Keep reading till FIFO is empty again
    wait (rempty == 1);
    $display("[%0t] FIFO is empty again. Test complete", $time);
    #10;
    $finish;
  end

// Some monitors

// Write monitor
always_ff @(posedge wclk) begin
  if (wrst_n && winc && !wfull)
    $display("WRITE: addr=%0d data=%0h", uut.waddr, wdata); // waddr is an internal signal
end

// Read monitor
always_ff @(posedge rclk) begin
  if (rrst_n && rinc && !rempty)
    $strobe("READ:  addr=%0d data=%0h", uut.raddr, rdata); // raddr is an internal signal
end

// Flags
always @(posedge wfull)  $display("wfull=1");
always @(negedge wfull)  $display("wfull=0");
always @(posedge rempty) $display("rempty=1");
always @(negedge rempty) $display("rempty=0");


  // Dump FSDB to view waveforms
  initial begin
    $fsdbDumpvars();
  end

endmodule
