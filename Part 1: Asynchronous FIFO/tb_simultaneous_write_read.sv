`timescale 1ns / 1ps

module tb_fifo_simult_read_write;

  // Parameters
  parameter DATASIZE = 8; // 8-bit data
  parameter ADDRSIZE = 4; // 4-bit address 
  localparam DEPTH = (1 << ADDRSIZE); // Depth of FIFO is 16

  // Clock and reset signals
  logic wclk, rclk; // Write and read clocks
  logic wrst_n, rrst_n; // Write and read resets

  // FIFO interface signals
  logic [DATASIZE-1:0] wdata; // Write data
  logic                winc; // Write enable
  logic                wfull, walmost_full; // Full and almost full flags

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


  // Writing on positive edge of write clock
  always_ff @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin // If reset
      wdata <= 0; // Clear write data to 0
    end else if (winc) begin // Else
      wdata <= wdata + 1; // Increment by 1 on every posedge
    end
  end


  // 100 MHz write clock
  initial begin
    wclk = 0;
    forever #5 wclk = ~wclk;
  end

  // 67 MHz read clock
  // Hence write is faster than read
  initial begin
    rclk = 0;
    forever #7.5 rclk = ~rclk;
  end

  // Simulation. Reset everything. Deassert reset after 20ns
  initial begin
    wrst_n = 0;
    rrst_n = 0;
    winc   = 0;
    rinc   = 0;
    #20;
    wrst_n = 1;
    rrst_n = 1;
  end

  
  initial begin
    // Wait until the almost empty flag pulses after reset
    @(posedge ralmost_empty);
    $display("[%0t] FIFO is almost empty at start.", $time);

    // Wait until the FIFO becomes fully empty
    wait (rempty == 1);
    $display("[%0t] FIFO is empty at start.", $time);

    // Enable both write and read simultaneously
    winc = 1;
    rinc = 1;

    // Wait for almost full flag to appear
    @(posedge walmost_full);
    $display("[%0t] FIFO is almost full.", $time);

    // Wait for full
    @(posedge wfull);
    $display("[%0t] FIFO is full.", $time);

    // Once full, stop writing but keep reading
    winc = 0;

    // Wait till FIFO empties again
    wait (rempty == 1);
    $display("[%0t] FIFO is empty.", $time);

    // End test
    #10;
    $display("[%0t] Test complete (empty → almost_full → full → almost_empty → empty).", $time);
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
