`timescale 1ps/1ps

module async_fifo #(
    parameter DSIZE = 8,  // Data width
    parameter ASIZE = 4   // Address width, determines FIFO depth (2^ASIZE)
) (
    //INPUT
    input w_enable,                   // Write request
    input w_clk,                   // Write clock
    input w_rst,                 // Write reset (active low, resets at 0)
    input r_enable,                   // Read request
    input r_clk,                   // Read clock
    input r_rst,                 // Read reset (active low, resets at 0)
    input [DSIZE-1:0] w_data,      // Data to write
    
    //OUTPUT
    output [DSIZE-1:0] r_data,     // Data to read
    output reg full,             // FIFO full flag
    output reg empty             // FIFO empty flag
);

// Internal pointer and synchronization signals
//    size of pointers = ASIZE + 1, MSB indicates overflow
reg [ASIZE:0] wq2_rptr, wq1_rptr, rptr;   // Write domain synchronized read pointer and read pointer
reg [ASIZE:0] rq2_wptr, rq1_wptr, wptr;   // Read domain synchronized write pointer and write pointer
reg [ASIZE:0] r_bin, w_bin;                 // Binary read and write pointers

// Next state signals
wire [ASIZE:0] rptr_nxt, wptr_nxt;        // Next state of Gray code read/write pointers
wire [ASIZE-1:0] r_addr, w_addr;            // Memory addresses
wire [ASIZE:0] rbin_nxt, wbin_nxt;        // Next binary read and write pointers

// FIFO status flags
wire rempty_val, wfull_val;

// FIFO memory size (2^ASIZE depth)
localparam DEPTH = (1 << ASIZE);
reg [DSIZE-1:0] mem [0:DEPTH-1];          // FIFO memory



// Synchronize read pointer into write clock domain
always @(posedge w_clk or negedge w_rst) begin
    if (!w_rst) begin
        wq2_rptr <= 0;
        wq1_rptr <= 0;
    end else begin
        wq2_rptr <= wq1_rptr;
        wq1_rptr <= rptr;  // Sync read pointer into write clock domain
    end
end



// Synchronize write pointer into read clock domain
always @(posedge r_clk or negedge r_rst) begin
    if (!r_rst) begin
        rq2_wptr <= 0;
        rq1_wptr <= 0;
    end else begin
        rq2_wptr <= rq1_wptr;
        rq1_wptr <= wptr;  // Sync write pointer into read clock domain
    end
end




// FIFO Empty Flag: Check if read pointer equals synchronized write pointer
assign rempty_val = (rptr_nxt == rq2_wptr);  // FIFO is empty when pointers match
always @(posedge r_clk or negedge r_rst) begin
    if (!r_rst)
        empty <= 1'b0;  // Reset empty flag
    else
        empty <= rempty_val;  // Update empty flag
end



// FIFO Full Flag: Check if write pointer is just one slot behind synchronized read pointer
assign wfull_val = (wq2_rptr == {~wptr[ASIZE:ASIZE-1], wptr[ASIZE-2:0]});  // Full when write pointer wraps
always @(posedge w_clk or negedge w_rst) begin
    if (!w_rst)
        full <= 1'b0;  // Reset full flag
    else
        full <= wfull_val;  // Update full flag
end



// Read Pointer and Address Generation
assign rbin_nxt = r_bin + (r_enable & ~empty);  // Increment read binary pointer if not empty and read requested
always @(posedge r_clk or negedge r_rst) begin
    if (!r_rst)
        r_bin <= 0;  // Reset read binary pointer
    else
        r_bin <= rbin_nxt;  // Update read binary pointer
end
assign r_addr = r_bin[ASIZE-1:0];  // Use lower bits of read binary pointer as memory address



// Read binary pointer -----> Gray code
assign rptr_nxt = rbin_nxt ^ (rbin_nxt >> 1);
always @(posedge r_clk or negedge r_rst) begin
    if (!r_rst)
        rptr <= 0;  
    else
        rptr <= rptr_nxt;  
end




// Write Pointer and Address Generation
assign wbin_nxt = w_bin + (w_enable & ~full);  // Increment write binary pointer if not full and write requested
always @(posedge w_clk or negedge w_rst) begin
    if (!w_rst)
        w_bin <= 0;  
    else
        w_bin <= wbin_nxt;  
end
assign w_addr = w_bin[ASIZE-1:0];  // Use lower bits of write binary pointer as memory address



// Write binary pointer -----> Gray code
assign wptr_nxt = wbin_nxt ^ (wbin_nxt >> 1);
always @(posedge w_clk or negedge w_rst) begin
    if (!w_rst)
        wptr <= 0;  
    else
        wptr <= wptr_nxt;  
end



// FIFO Memory Operations
always @(posedge w_clk) begin
    if (w_enable & ~full)
        mem[w_addr] <= w_data;  // Write data into FIFO memory if not full
end

assign r_data = mem[r_addr];  // Read data from FIFO memory

endmodule
