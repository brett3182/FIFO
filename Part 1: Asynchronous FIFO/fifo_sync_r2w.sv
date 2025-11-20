// Our synchronizer for the read pointer rptr entering into the write clock domain
// This is done to avoid metastability issues when moving from read clock domain to write clock domain
// Synchronization is achieved by using 2FFs. FF1 might go metastable but FF2 gurantees a true value hence 2FFs are used 
`timescale 1ns / 1ps
module fifo_sync_r2w #(
    parameter ADDRSIZE = 4 // 4-bits to represent 0 - 15 address of the FIFO
)(
    output logic [ADDRSIZE:0] wq2_rptr, // read pointer after it has been synchronized
    input  logic [ADDRSIZE:0] rptr, // original read pointer serving as input
    input  logic wclk, wrst_n // wclk is the write clock and wrst_n is the active low reset
);

    logic [ADDRSIZE:0] wq1_rptr; // Flip flop 1 of the 2FF synchronizer

    always_ff @(posedge wclk, negedge wrst_n) begin
        if (!wrst_n) begin // If reset
            {wq2_rptr, wq1_rptr} <= '0; // Both FFS become 0  
        end
        else begin // Else in normal operation
            {wq2_rptr, wq1_rptr} <= {wq1_rptr, rptr}; // Shift through the 2 FFs rptr --> wq1_rptr --> wq2_rptr. Total 2 cycles for stability.
        end
    end

endmodule
