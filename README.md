# FIFO


## Part 1: Asynchronous FIFO Design

This part of the project implements and verifies a parameterized asynchronous FIFO in SystemVerilog. Asynchronous means the write and read sides use independent clocks. The default configuration stores 8-bit words with a logical depth of 16 entries, but both width and depth are parameters that we can change without touching the internals. The design follows the standard, proven approach of using Gray-code pointers so only one bit changes per increment, two-flip-flop synchronizers when a pointer crosses into the other clock domain, and Moore-style status flags indicating full, empty, and the 1/4th and 3/4th thresholds that are registered in their local domains. Because the flags depend on a pointer that has crossed a clock boundary and then been registered, their changes lag real pushes and pops by a few cycles of the observing clock. That small, predictable latency is expected and is exactly what keeps the FIFO robust against metastability and mis-sampling.


All the files used in this design are available at https://github.com/brett3182/FIFO/tree/main/Part%201%3A%20Asynchronous%20FIFO 

A brief explanation of all the design files is summarized below:

**fifo_top.sv:** The top module wires up write side, read side, the two synchronizers, and the memory. Exposes the FIFO ports and flags.
**fifo_write.sv:** It contains the write clock domain logic -  increments the write pointer, makes the write address, and raises the full and almost_full flags based on the synced read pointer.
**fifo_read.sv:** It contains the read clock domain logic - increments the read pointer, makes the read address, and raises empty and almost_empty flags based on the synced write pointer.
**fifo_sync_r2w.sv:** Two flip-flop synchronizer to bring the read Gray pointer safely into the write clock domain.
**fifo_sync_w2r.sv:** Two flip-flop synchronizer to bring the write Gray pointer safely into the read clock domain.
**fifo_memory.sv:** It is the storage array whcih does synchronous writes on wclk, simple async read via raddr.


First simulation:

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

Second simulation:
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
