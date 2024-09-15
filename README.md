# Asynchronous FIFO Module

## Overview

This module contains an implementation of an asynchronous FIFO (First-In-First-Out) buffer in Verilog. The FIFO buffer is essential in digital systems where data needs to be transferred asynchronously between two different clock domains. This module supports configurable data and address widths and handles synchronization between read and write operations across distinct clock domains.

![WhatsApp Image 2024-09-15 at 14 04 06_ffd07019](https://github.com/user-attachments/assets/2957cabe-70fe-4003-8f23-a908665b8cb2)

## Features

- **Data Width (DSIZE)**: Parameterizable width of the data being stored (default: 8 bits).
- **Address Width (ASIZE)**: Parameterizable width for address lines, which determines the FIFO depth (default: 4 bits, giving a depth of 16).
- **Write and Read Operations**: Independent clocks for write and read operations.
- **Full and Empty Flags**: Output flags to indicate whether the FIFO is full or empty.
- **Gray Code Pointers**: Uses Gray code to prevent glitches during pointer updates.

## Components

### 1. **Inputs and Outputs**

- **Inputs:**
  - `w_enable`: Write enable signal.
  - `w_clk`: Write clock signal.
  - `w_rst`: Write reset signal (active low).
  - `r_enable`: Read enable signal.
  - `r_clk`: Read clock signal.
  - `r_rst`: Read reset signal (active low).
  - `w_data`: Data to be written into the FIFO.

- **Outputs:**
  - `r_data`: Data read from the FIFO.
  - `full`: FIFO full flag.
  - `empty`: FIFO empty flag.

### 2. **Internal Signals**

- **Pointers:**
  - `wptr`, `rptr`: Gray code pointers for write and read operations.
  - `w_bin`, `r_bin`: Binary pointers for write and read operations.

- **Synchronization Signals:**
  - `rptr_sync2`, `rptr_sync2`: Write domain synchronized read pointers.
  - `wptr_sync2`, `wptr_sync1`: Read domain synchronized write pointers.

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
   - **Full Flag (`full`)**: Generated when the FIFO is at maximum capacity, based on the write pointer and read pointer values.
   - **Empty Flag (`empty`)**: Generated when the FIFO is empty, based on the read pointer and the synchronized write pointer values.

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
    .w_enable(write_enable),
    .w_clk(write_clock),
    .w_rst(write_reset),
    .r_enable(read_enable),
    .r_clk(read_clock),
    .r_rst(read_reset),
    .w_data(write_data),
    .r_data(read_data),
    .full(fifo_full),
    .empty(fifo_empty)
);
```
