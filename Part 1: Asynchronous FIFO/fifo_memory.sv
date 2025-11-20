`timescale 1ns / 1ps

module fifo_memory #(
    parameter DATASIZE = 8,  // Read and write data size is of 8-bits
    parameter ADDRSIZE = 4   // 4-bit address. Hence 2^4 = 16 locations in memory. Hence depth is 16
)(
    output logic [DATASIZE-1:0] rdata, // Read data
    input  logic [DATASIZE-1:0] wdata, // Write data
    input  logic [ADDRSIZE-1:0] waddr, raddr, // Read and write addresses. 'Where to read or write'
    input  logic wclken, // write clock enable. Gates our write clock
    input  logic wfull, // 1 means FIFO is full, 0 means we can write
    input  logic wclk // Write clock
);

    
    localparam DEPTH = 1 << ADDRSIZE; // 1 left shifted by addrsize which is 4 --> 10000 = 16 which is the depth of FIFO
    logic [DATASIZE-1:0] mem [DEPTH];  // 16 memory locations in FIFO and each location is 8-bit.

    always_ff @(posedge wclk) begin
        if (wclken && !wfull) begin // If write clock is enabled and FIFO is not full then
            mem[waddr] <= wdata; // Write data into the location given by write address
        end
    end
    assign rdata = mem[raddr]; // Logic to read data from read address

endmodule
