# FIFO


## Part 1: Asynchronous FIFO Design

This part of the project implements and verifies a parameterized asynchronous FIFO in SystemVerilog. Asynchronous means the write and read sides use independent clocks. The default configuration stores 8-bit words with a logical depth of 16 entries, but both width and depth are parameters that we can change without touching the internals. The design follows the standard, proven approach of using Gray-code pointers so only one bit changes per increment, two-flip-flop synchronizers when a pointer crosses into the other clock domain, and Moore-style status flags indicating full, empty, and the 1/4th and 3/4th thresholds that are registered in their local domains. Because the flags depend on a pointer that has crossed a clock boundary and then been registered, their changes lag real pushes and pops by a few cycles of the observing clock. That small, predictable latency is expected and is exactly what keeps the FIFO robust against metastability and mis-sampling.


All the files used in this design are available at https://github.com/brett3182/FIFO/tree/main/Part%201%3A%20Asynchronous%20FIFO 

The files have been commented well enough to understand whats happening.

A brief explanation of all the design files is summarized below:

**<ins> fifo_top.sv:</ins>** The top module wires up write side, read side, the two synchronizers, and the memory. Exposes the FIFO ports and flags.

**<ins>fifo_write.sv:</ins>** It contains the write clock domain logic -  increments the write pointer, makes the write address, and raises the full and almost_full flags based on the synced read pointer.

**<ins>fifo_read.sv:</ins>** It contains the read clock domain logic - increments the read pointer, makes the read address, and raises empty and almost_empty flags based on the synced write pointer.

**<ins>fifo_sync_r2w.sv:</ins>** Two flip-flop synchronizer to bring the read Gray pointer safely into the write clock domain.

**<ins>fifo_sync_w2r.sv:</ins>** Two flip-flop synchronizer to bring the write Gray pointer safely into the read clock domain.

**<ins>fifo_memory.sv:</ins>** It is the storage array whcih does synchronous writes on wclk, simple async read via raddr.


### Design Verification using SystemVerilog Testbench

**<ins>1) Write then Read (tb_fifo_write_then_read.sv):</ins>** This part is basically "Fill it, then drain it". It is testing that the FIFO correctly fills from empty to full under a faster write clock, asserts walmost_full near 3/4th depth and wfull at capacity, then drains back to empty in order with ralmost_empty and rempty asserting at the tail.

**Output:** *The design was compiled and simulated using Synopsys VCS and Synopsys Verdi*


![image alt](https://github.com/brett3182/FIFO/blob/main/images/1.png?raw=true)


In this 'write until full then read until empty testbench', the FIFO starts empty where can we see that the rempty and almost empty flags are set to logic 1. The writer pushes an incrementing pattern from 0 until F on every positive edge of write clock until the FIFO reaches its full capacity afterwhich wfull is asserted and our test switches to read. Now, the FIFO pops out everything on the positive edge of read clock until the FIFO is empty again. Notice how rempty and ralmost_empty stay high through the early writes and only drop after several items have been pushed. This is the expected because of the 2 flip flop latency in the read domain. The write pointer must synchronize across, costing ~2–3 rclk cycles. Likewise, after reads begin, wfull doesn’t clear immediately, it deasserts a few wclk cycles later once the read pointer has synchronized into the write domain. Because the write clock is faster than the read clock, these CDC latencies show up as “several items” on waves, but all flags and data ordering behave exactly as designed.


***Simulation log*** 

```
wfull=0
rempty=1
[0] FIFO is empty. Start of simulation
WRITE: addr=0 data=0
WRITE: addr=1 data=1
WRITE: addr=2 data=2
WRITE: addr=3 data=3
WRITE: addr=4 data=4
rempty=0
WRITE: addr=5 data=5
WRITE: addr=6 data=6
WRITE: addr=7 data=7
WRITE: addr=8 data=8
WRITE: addr=9 data=9
WRITE: addr=10 data=a
WRITE: addr=11 data=b
WRITE: addr=12 data=c
WRITE: addr=13 data=d
WRITE: addr=14 data=e
WRITE: addr=15 data=f
wfull=1
[175000] FIFO is full
READ:  addr=1 data=1
READ:  addr=2 data=2
wfull=0
READ:  addr=3 data=3
READ:  addr=4 data=4
READ:  addr=5 data=5
READ:  addr=6 data=6
READ:  addr=7 data=7
READ:  addr=8 data=8
READ:  addr=9 data=9
READ:  addr=10 data=a
READ:  addr=11 data=b
READ:  addr=12 data=c
READ:  addr=13 data=d
READ:  addr=14 data=e
READ:  addr=15 data=f
rempty=1

[413000] FIFO is empty again. Test complete
READ:  addr=0 data=0
```


**<ins>2) Simultaneous read and write operation (tb_simultaneous_write_read.sv):</ins>** This testbenches tests the design for reads and writes at the same time. Overall, it tests that with both sides active under independent clocks, the FIFO still preserves order, wraps cleanly in the address space, and raises the “almost” and “full/empty” flags at the right times.

**Output:** *The design was compiled and simulated using Synopsys VCS and Synopsys Verdi*


![image alt](https://github.com/brett3182/FIFO/blob/main/images/2.png?raw=true)


In this testbench we write and read simultaneously. We started empty where we can see both empty flags high, then enabled read and write together with independent clocks where write (100MHz) is faster than read (66.7 MHz). As data flowed, the addresses wrapped naturally ....14, 15, 0, 1..... and the read stream preserved order. The FIFO occupancy climbed despite concurrent pops, so walmost_full asserted first and later wfull went high; after hitting full we stopped writes, kept reading, and the FIFO drained back to empty, with ralmost_empty and then rempty asserting at the end. Because the write side and read side use different clocks, each side only sees the other side’s pointer after it passes through the two-flip-flop synchronizer. That adds a few local cycles of delay. Also, our flags are Moore style, so they only update on a clock edge, which adds another beat of delay. Put together, this is why we see walmost_full first, then wfull, and why wfull drops a few write clocks after reads start. The extra “READ” line right when rempty goes high is just a print timing thing, $strobe prints at the end of the same timestep the FIFO becomes empty, so it logs the last valid pop and then we see rempty=1. Overall, the lag and that final print are expected and correct.



***Simulation log*** 
```
*Verdi* : Create FSDB file 'novas.fsdb'
*Verdi* : Begin traversing the scopes, layer (0).
*Verdi* : End of traversing.
wfull=0
rempty=1
[0] FIFO is almost empty at start.
[0] FIFO is empty at start.
WRITE: addr=0 data=0
WRITE: addr=1 data=1
WRITE: addr=2 data=2
WRITE: addr=3 data=3
WRITE: addr=4 data=4
rempty=0
WRITE: addr=5 data=5
READ:  addr=1 data=1
WRITE: addr=6 data=6
WRITE: addr=7 data=7
READ:  addr=2 data=2
WRITE: addr=8 data=8
READ:  addr=3 data=3
WRITE: addr=9 data=9
WRITE: addr=10 data=a
READ:  addr=4 data=4
WRITE: addr=11 data=b
READ:  addr=5 data=5
WRITE: addr=12 data=c
WRITE: addr=13 data=d
READ:  addr=6 data=6
WRITE: addr=14 data=e
READ:  addr=7 data=7
WRITE: addr=15 data=f
WRITE: addr=0 data=10
READ:  addr=8 data=8
WRITE: addr=1 data=11
READ:  addr=9 data=9
WRITE: addr=2 data=12
WRITE: addr=3 data=13
READ:  addr=10 data=a
WRITE: addr=4 data=14
READ:  addr=11 data=b
WRITE: addr=5 data=15
[235000] FIFO is almost full.
WRITE: addr=6 data=16
READ:  addr=12 data=c
WRITE: addr=7 data=17
READ:  addr=13 data=d
WRITE: addr=8 data=18
WRITE: addr=9 data=19
READ:  addr=14 data=e
WRITE: addr=10 data=1a
READ:  addr=15 data=f
WRITE: addr=11 data=1b
WRITE: addr=12 data=1c
READ:  addr=0 data=10
WRITE: addr=13 data=1d
READ:  addr=1 data=11
WRITE: addr=14 data=1e
wfull=1
[325000] FIFO is full.
wfull=0
READ:  addr=2 data=12
READ:  addr=3 data=13
READ:  addr=4 data=14
READ:  addr=5 data=15
READ:  addr=6 data=16
READ:  addr=7 data=17
READ:  addr=8 data=18
READ:  addr=9 data=19
READ:  addr=10 data=1a
READ:  addr=11 data=1b
READ:  addr=12 data=1c
READ:  addr=13 data=1d
READ:  addr=14 data=1e
rempty=1
[533000] FIFO is empty.
READ:  addr=15 data=f
[543000] Test complete (empty → almost_full → full → almost_empty → empty).
$finish called from file "../Part1/tb_simultaneous_write_read.sv", line 109.
$finish at simulation time               542500
           V C S   S i m u l a t i o n   R e p o r t 
Time: 542500 ps
CPU Time:      0.220 seconds;       Data structure size:   0.0Mb
```


### Synthesis

Synthesis was run in Synopsys Design Compiler (dc_shell) using a short Tcl script to read the RTL, elaborate the top, set clock constraints, and produce timing, area, and power reports. Two independent clocks were constrained to aggressive targets of 1.6 GHz for the write domain and 0.8 GHz for the read domain to stress timing and reveal headroom. The domains were treated as asynchronous so only paths within each domain were optimized, consistent with the FIFO architecture. Under these targets the design compiled cleanly, with the expected trade-off of tighter timing driving larger cells and higher area.


**Power report:**

![image alt](https://github.com/brett3182/FIFO/blob/main/images/3.png?raw=true)


**Area report:** 

![image alt](https://github.com/brett3182/FIFO/blob/main/images/4.png?raw=true)

**Timing report:**

![image alt](https://github.com/brett3182/FIFO/blob/main/images/5.png?raw=true)

**Cell report:** *Design synthesized using different standard cells from the standard cell library of a 45nm PDK*

![image alt](https://github.com/brett3182/FIFO/blob/main/images/6.png?raw=true)
