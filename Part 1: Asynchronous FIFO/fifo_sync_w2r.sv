// Our synchronizer for the write pointer wptr entering into the read clock domain
// This is done to avoid metastability issues when moving from write clock domain to read clock domain
// Synchronization is achieved by using 2FFs. FF1 might go metastable but FF2 gurantees a true value hence 2FFs are used 
`timescale 1ns / 1ps

module fifo_sync_w2r #(
    parameter ADDRSIZE = 4 // Our 4-bit address
)(
    output logic [ADDRSIZE:0] rq2_wptr, // write pointer after it has been synchronized
    input  logic [ADDRSIZE:0] wptr, // original write pointer
    input  logic rclk, // read clock 
    input  logic rrst_n // active low reset in read domain
);

    logic [ADDRSIZE:0] rq1_wptr; // Internal FF1

    always_ff @(posedge rclk, negedge rrst_n) begin
        if (!rrst_n) begin // If reset
            {rq2_wptr, rq1_wptr} <= '0; // Clear both FFs to 0  
        end
        else begin // Else normal operation
            {rq2_wptr, rq1_wptr} <= {rq1_wptr, wptr}; // Ripple through the FF stages for stable output. wptr --> rq1_wptr --> rq2_wptr
        end
    end

endmodule
