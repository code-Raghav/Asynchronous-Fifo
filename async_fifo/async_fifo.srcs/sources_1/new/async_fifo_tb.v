//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.09.2024 17:29:27
// Design Name: 
// Module Name: async_fifo_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// TB to verify async_fifo

`timescale 1ps/1ps

module async_fifo #(
    parameter DSIZE = 8,  // Data width
    parameter ASIZE = 4   // Address width, determines FIFO depth (2^ASIZE)
) (
    input wreq,                   // Write request
    input wclk,                   // Write clock
    input wrst_n,                 // Write reset (active low)
    input rreq,                   // Read request
    input rclk,                   // Read clock
    input rrst_n,                 // Read reset (active low)
    input [DSIZE-1:0] wdata,      // Data to write
    output [DSIZE-1:0] rdata,     // Data to read
    output reg wfull,             // FIFO full flag
    output reg rempty             // FIFO empty flag
);

// Internal pointer and synchronization signals
reg [ASIZE:0] wq2_rptr, wq1_rptr, rptr;   // Write domain synchronized read pointer and read pointer
reg [ASIZE:0] rq2_wptr, rq1_wptr, wptr;   // Read domain synchronized write pointer and write pointer
reg [ASIZE:0] rbin, wbin;                 // Binary read and write pointers

// Next state signals
wire [ASIZE:0] rptr_nxt, wptr_nxt;        // Next state of Gray code read/write pointers
wire [ASIZE-1:0] raddr, waddr;            // Memory addresses
wire [ASIZE:0] rbin_nxt, wbin_nxt;        // Next binary read and write pointers

// FIFO status flags
wire rempty_val, wfull_val;

// FIFO memory size (2^ASIZE depth)
localparam DEPTH = (1 << ASIZE);
reg [DSIZE-1:0] mem [0:DEPTH-1];          // FIFO memory

//-----------------------------------------------------------------------------
// Synchronize read pointer into write clock domain
//-----------------------------------------------------------------------------
always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
        wq2_rptr <= 0;
        wq1_rptr <= 0;
    end else begin
        wq2_rptr <= wq1_rptr;
        wq1_rptr <= rptr;  // Sync read pointer into write clock domain
    end
end

//-----------------------------------------------------------------------------
// Synchronize write pointer into read clock domain
//-----------------------------------------------------------------------------
always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
        rq2_wptr <= 0;
        rq1_wptr <= 0;
    end else begin
        rq2_wptr <= rq1_wptr;
        rq1_wptr <= wptr;  // Sync write pointer into read clock domain
    end
end

//-----------------------------------------------------------------------------
// FIFO Empty Flag: Check if read pointer equals synchronized write pointer
//-----------------------------------------------------------------------------
assign rempty_val = (rptr_nxt == rq2_wptr);  // FIFO is empty when pointers match

always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n)
        rempty <= 1'b0;  // Reset empty flag
    else
        rempty <= rempty_val;  // Update empty flag
end

//-----------------------------------------------------------------------------
// FIFO Full Flag: Check if write pointer is just one slot behind synchronized read pointer
//-----------------------------------------------------------------------------
assign wfull_val = (wq2_rptr == {~wptr[ASIZE:ASIZE-1], wptr[ASIZE-2:0]});  // Full when write pointer wraps

always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n)
        wfull <= 1'b0;  // Reset full flag
    else
        wfull <= wfull_val;  // Update full flag
end

//-----------------------------------------------------------------------------
// Read Pointer and Address Generation
//-----------------------------------------------------------------------------
assign rbin_nxt = rbin + (rreq & ~rempty);  // Increment read binary pointer if not empty and read requested

always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n)
        rbin <= 0;  // Reset read binary pointer
    else
        rbin <= rbin_nxt;  // Update read binary pointer
end

assign raddr = rbin[ASIZE-1:0];  // Use lower bits of read binary pointer as memory address

// Convert read binary pointer to Gray code
assign rptr_nxt = rbin_nxt ^ (rbin_nxt >> 1);

always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n)
        rptr <= 0;  // Reset read Gray pointer
    else
        rptr <= rptr_nxt;  // Update read Gray pointer
end

//-----------------------------------------------------------------------------
// Write Pointer and Address Generation
//-----------------------------------------------------------------------------
assign wbin_nxt = wbin + (wreq & ~wfull);  // Increment write binary pointer if not full and write requested

always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n)
        wbin <= 0;  // Reset write binary pointer
    else
        wbin <= wbin_nxt;  // Update write binary pointer
end

assign waddr = wbin[ASIZE-1:0];  // Use lower bits of write binary pointer as memory address

// Convert write binary pointer to Gray code
assign wptr_nxt = wbin_nxt ^ (wbin_nxt >> 1);

always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n)
        wptr <= 0;  // Reset write Gray pointer
    else
        wptr <= wptr_nxt;  // Update write Gray pointer
end

//-----------------------------------------------------------------------------
// FIFO Memory Operations
//-----------------------------------------------------------------------------
always @(posedge wclk) begin
    if (wreq & ~wfull)
        mem[waddr] <= wdata;  // Write data into FIFO memory if not full
end

assign rdata = mem[raddr];  // Read data from FIFO memory

endmodule


endmodule
