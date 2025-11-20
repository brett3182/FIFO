// FIFO read module
// this block runs on rclk, advances the read pointer when rinc && !rempty, supplies the RAM address, 
// and asserts rempty  and ralmost_empty based on the synchronized view of the writer’s position.

`timescale 1ns / 1ps

module fifo_read #(
    parameter ADDRSIZE = 4, // Number of bits to represent the address 0 - 15 of FIFO
    parameter ALMOST_EMPTY_THRESHOLD = 4  // Almost empty threshold. 1/4 * 16 = 4
)(
    output logic rempty, // Nothing to read flag
    output logic ralmost_empty,  // FIFO almost empty flag
    output logic [ADDRSIZE-1:0] raddr, // The read address
    output logic [ADDRSIZE:0] rptr, // The read pointer with wrap bit in gray
    input logic [ADDRSIZE:0] rq2_wptr,  // The write pointer after 2ff synchronization into the read domain
    input logic rinc, rclk, rrst_n // read enable, read clk and active low reset for read domain
);

    localparam DEPTH = 1 << ADDRSIZE; // Depth calculated by left shifting 1 by addrsize. 1 <<4 --> 10000 = 16. FIFO depth is 16
    
    logic [ADDRSIZE:0] rbin; // Current read pointer in binary
    logic [ADDRSIZE:0] rbinnext; // Where the read pointer would be next
    logic [ADDRSIZE:0] rgraynext; // The next read pointer in gray
    logic rempty_val; // FIFO is empty indication flag
    logic [ADDRSIZE:0] wbin_sync;  // Write pointer in binary. rq2_wptr is in gray, we convert it to binary
    logic [ADDRSIZE:0] fill_level; // How many elements are there in the FIFO
    logic ralmost_empty_val; // Almost empty flag indication

    // Gray to binary conversion for write pointer rq2_wptr
    generate
        genvar i;
        assign wbin_sync[ADDRSIZE] = rq2_wptr[ADDRSIZE]; // Keep MSB the same
        for(i = ADDRSIZE-1; i >= 0; i--) begin : GRAY2BIN
            assign wbin_sync[i] = wbin_sync[i+1] ^ rq2_wptr[i]; // XOR ripple logic to convert gray to binary
        end
    endgenerate

    // Fill level calculation for the FIFO. We come to know how many elements are there in the FIFO
    assign fill_level = wbin_sync - rbin;

    // Almost empty condition flag 
    assign ralmost_empty_val = (fill_level <= ALMOST_EMPTY_THRESHOLD); // Theshold is 4. 1/4th of FIFO depth

    // Read pointer update logic
    always_ff @(posedge rclk, negedge rrst_n) begin
        if (!rrst_n) begin // If reset
            {rbin, rptr} <= '0; // Then set the pointers to 0
        end
        else begin // Else
            {rbin, rptr} <= {rbinnext, rgraynext}; // Set them to the next pointer
        end
    end

    assign raddr = rbin[ADDRSIZE-1:0]; // The read address is the lower LSB bits of the read pointer. The MSB is just the wrap bit
    assign rbinnext = rbin + (rinc & ~rempty); // If read is enabled and FIFO is not empty then the next read address is current + 1
    assign rgraynext = (rbinnext >> 1) ^ rbinnext; // Logic to convert next read pointer address to gray

    // Empty detection
    assign rempty_val = (rgraynext == rq2_wptr); // rq2_wptr tells where the writer is. If it is equal to where the reader is then FIFO is empty

    // Empty and almost empty assignment to avoid combinational loops
    always_ff @(posedge rclk, negedge rrst_n) begin
        if (!rrst_n) begin // If reset
            rempty <= 1'b1; // Empty is set to '1' because FIFO is empty on reset
            ralmost_empty <= 1'b1;  // Running low is also true
        end
        else begin // Else
            rempty <= rempty_val; // Assigning empty flag
            ralmost_empty <= ralmost_empty_val; // Assigning almost empty flag
        end
    end

endmodule
