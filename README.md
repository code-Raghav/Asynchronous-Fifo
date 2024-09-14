# Asynchronous FIFO Module

## Overview

This repository contains an implementation of an asynchronous FIFO (First-In-First-Out) buffer in Verilog. The FIFO buffer is a crucial component in digital systems where data needs to be transferred between two clock domains asynchronously. This module supports different data and address widths and handles synchronization between read and write operations across different clocks.

## Features

- **Data Width (DSIZE)**: Parameterizable width of the data being stored (default: 8 bits).
- **Address Width (ASIZE)**: Parameterizable width for address lines, which determines the FIFO depth (default: 4 bits, giving a depth of 16).
- **Write and Read Operations**: Independent clocks for write and read operations.
- **Full and Empty Flags**: Output flags to indicate whether the FIFO is full or empty.
- **Gray Code Pointers**: Uses Gray code to prevent glitches during pointer updates.

## Components

### 1. **Inputs and Outputs**

- **Inputs:**
  - `wreq`: Write request signal.
  - `wclk`: Write clock signal.
  - `wrst_n`: Write reset signal (active low).
  - `rreq`: Read request signal.
  - `rclk`: Read clock signal.
  - `rrst_n`: Read reset signal (active low).
  - `wdata`: Data to be written into the FIFO.

- **Outputs:**
  - `rdata`: Data read from the FIFO.
  - `wfull`: FIFO full flag.
  - `rempty`: FIFO empty flag.

### 2. **Internal Signals**

- **Pointers:**
  - `wptr`, `rptr`: Gray code pointers for write and read operations.
  - `wbin`, `rbin`: Binary pointers for write and read operations.

- **Synchronization Signals:**
  - `wq2_rptr`, `wq1_rptr`: Write domain synchronized read pointers.
  - `rq2_wptr`, `rq1_wptr`: Read domain synchronized write pointers.

- **Flags:**
  - `wfull_val`, `rempty_val`: Internal signals to compute FIFO full and empty statuses.

### 3. **FIFO Memory**

- A memory array with a depth of \(2^{ASIZE}\) and width equal to `DSIZE`.

## How It Works

1. **Pointer Synchronization:**
   - Read and write pointers are synchronized across clock domains using dual flip-flop synchronizers to avoid metastability.

2. **Pointer Generation:**
   - **Binary to Gray Code Conversion**: Write and read binary pointers are converted to Gray code to minimize errors when crossing clock domains.

3. **Flag Management:**
   - **Full Flag (`wfull`)**: Generated when the FIFO is at maximum capacity, based on the write pointer and read pointer values.
   - **Empty Flag (`rempty`)**: Generated when the FIFO is empty, based on the read pointer and the synchronized write pointer values.

4. **Memory Operations:**
   - Data is written into the FIFO memory on the rising edge of the write clock if the FIFO is not full.
   - Data is read from the FIFO memory on the rising edge of the read clock if the FIFO is not empty.

## Example Usage

To integrate this FIFO into a project, instantiate the module with appropriate parameters for data width and address width. Connect the module to your design’s read and write interfaces, ensuring proper clock and reset signals.

```verilog
async_fifo #(
    .DSIZE(8),
    .ASIZE(4)
) my_fifo (
    .wreq(write_request),
    .wclk(write_clock),
    .wrst_n(write_reset_n),
    .rreq(read_request),
    .rclk(read_clock),
    .rrst_n(read_reset_n),
    .wdata(write_data),
    .rdata(read_data),
    .wfull(fifo_full),
    .rempty(fifo_empty)
);
```
