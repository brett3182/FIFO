// The FIFO write module
// This block computes wfull and walmost_full, advances the write pointer, and provides the RAM address 
// using only local state and the synchronized view of the read pointer wq2_rptr
`timescale 1ns / 1ps

module fifo_write #(
    parameter ADDRSIZE = 4, // Address size 4 bits to represent depth of 2 ^ 4 = 16
    parameter ALMOST_FULL_THRESHOLD = 12 // Almost full threshold is 3/4 * 16 = 12
)(
    output logic wfull, // No space in FIFO signal
    output logic walmost_full, // FIFO almost full
    output logic [ADDRSIZE-1:0] waddr, // Write address
    output logic [ADDRSIZE:0] wptr, // Write pointer. Indicates 'write at this location' 0 - 15
    input logic [ADDRSIZE:0] wq2_rptr, // read pointer after 2ff synchronization. Now it is synched wrt wclk
    input logic winc, wclk, wrst_n // winc is the write enable, wclk is the write domain clock, wrst_n is the active low reset for the write domain
);

    localparam DEPTH = 1 << ADDRSIZE; // Our FIFO depth should be 16. Here '1' is left shifted by addrsize which is 4 to get the representable depth of 16
                                      // 1 < 4 ---> 10000 = 16 ---> 2 ^ 4
    logic [ADDRSIZE:0] wbin; // Write pointer in binary with wrap bit. 'where the write will go'
    logic [ADDRSIZE:0] wbinnext; // This represents where the write pointer would be next if we accept a write
    logic [ADDRSIZE:0] wgraynext; // The same next write pointer but in gray
    logic wfull_val; // If we do a write next, will FIFO be full? This signal is there to avoid combinational loop if used wfull 
    logic walmost_full_val; // if we do a write next, will the FIFO be 3/4th full? Signal present to avoid comb loop if used walmost_full
    logic [ADDRSIZE:0] rbin_sync; // wq2_rptr pointer is in gray code. The gray is converted to binary. This signal represents that binary read pointer
    logic [ADDRSIZE:0] fill_level; // How many items are there in the FIFO right now

    // Gray to binary converstion for w2q_rptr. The w2q_rptr is the read pointer in gray which gets converted into binary rbin_sync
    generate
        genvar i;
        assign rbin_sync[ADDRSIZE] = wq2_rptr[ADDRSIZE];  // MSB stays the same since it is the wrap bit counting whether we have finished a loop
        for(i = ADDRSIZE-1; i >= 0; i--) begin : GRAY2BIN
            assign rbin_sync[i] = rbin_sync[i+1] ^ wq2_rptr[i];  // Logic to convert gray to binary. XOR logic. eg. b[3] = b[4] ^ G[3]
        end
    endgenerate

    // Fill level calculation. How many items are there in the FIFO?
    assign fill_level = wbin - rbin_sync; // wbin is the write pointer stating how many write so far, 
                                          // rbin_sync read pointer in binary stating how many reads. eg: 1_0011 (19) - 0_1101 (13) = 6. FIFO has 6 elements.

    // Pointer update logic
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin  // If reset
            {wbin, wptr} <= '0; // Clear both binary and gray write pointers to 0
        end
        else begin  // Else
            {wbin, wptr} <= {wbinnext, wgraynext};  // Next location for the pointers
        end
    end

    assign waddr = wbin[ADDRSIZE-1:0]; // Write address is the lower LSB bits of write binary. wbin is [4:0] of which w[4] is wrap bit. The other are waddr
    assign wbinnext = wbin + (winc & ~wfull); // If write is enabled and FIFO is not full, next write binary address is current + 1
    assign wgraynext = (wbinnext >> 1) ^ wbinnext; // Converting the next write address in binary to gray

    // Full detection logic using Cummings logic
    // Full happens when the next write pointer would be at the same index as the read pointer but on the next lap
    assign wfull_val = (wgraynext == {~wq2_rptr[ADDRSIZE:ADDRSIZE-1], wq2_rptr[ADDRSIZE-2:0]});
    assign walmost_full_val = (fill_level >= ALMOST_FULL_THRESHOLD); // Almost full if fill level >= 12

    // Assigning the full and almost full write flags.
    // This is done to avoid the combinational loop wbinnext -> wgraynext -> wfull_val -> (back into) wbinnext
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wfull <= 1'b0;
            walmost_full <= 1'b0;
        end
        else begin
            wfull <= wfull_val;
            walmost_full <= walmost_full_val;
        end
    end

endmodule
