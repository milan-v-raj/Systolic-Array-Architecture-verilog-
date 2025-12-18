# Systolic-Array-Architecture-verilog-
# High-Performance Systolic Array Matrix Multiplication Accelerator

This project focuses on the design, implementation, and verification of a hardware accelerator for matrix multiplication based on a **Systolic Array** architecture. It compares this hardware-first approach against naive sequential hardware and optimized software baselines like PyTorch.

##  Project Overview

Modern neural networks rely heavily on matrix multiplication, but direct implementations on parallel hardware often hit the "Memory Wall," where compute units are starved for data from slow off-chip memory. The Systolic Array solves this by optimizing data orchestration, ensuring hardware remains efficient through deep pipelining, local communication, and massive data reuse.

### Key Performance Benchmarks (32x32 Matrix)

Based on synthesis for a Xilinx Artix-7 FPGA (xc7a35tcpg236-1):

Metric,Naive Hardware (O(N3)),PyTorch (CPU),Custom Systolic Array
Complexity,O(N3) ,N/A,O(N) 
Latency,~170 µs ,~161 µs ,6.2 µs 
Max Frequency,193 MHz ,N/A,310 MHz 
Power,~0.073 W ,~80 W (Est.) ,0.073 W 
Efficiency,Low,~0.005 GOPS/W ,145 GOPS/W 
---

##  Architecture

The design utilizes a grid of **Processing Elements (PEs)**. Each PE is a Multiply-Accumulate (MAC) unit that performs C = C + (A \times B) while simultaneously passing data to its immediate neighbors.

### Tiled Matrix Multiplication

To overcome physical FPGA resource limits, the project implements **Tiling (Block Multiplication)**. Large matrices are divided into smaller 8\times8 blocks, allowing the hardware to process matrices of any size (e.g., 16x16 or 32x32) by combining block-level results.

---

##  Project Structure

* 
`pe.v`: Verilog implementation of a single MAC Processing Element.


* 
`systolic_array_8x8.v`: The 8\times8 core compute grid.


* 
`matmul_controller.v`: The "brain" of the engine, managing loop counters and memory addresses for tiling.


* 
`tiled_matmul_engine.v`: The top-level body that orchestrates data flow between memories and the systolic core.


* 
`tb_tiled_matmul.v`: Testbench for verifying tiled multiplication results against PyTorch.



---

##  How to Run

### 1. Data Generation (Python)

Use the provided Python script to generate matrix data in a "block-major" format and create the necessary skewed stimulus vectors for the systolic timing.

```bash
# Example for generating 16x16 matrices
python generate_test_data.py 

```

### 2. Simulation (Icarus Verilog)

To verify the design functionality and compare results with PyTorch golden references:

```bash
# Compile the design
iverilog -o sim_tiled -g2012 pe.v systolic_array_8x8.v matmul_controller.v tiled_matmul_engine.v tb_tiled_matmul.v

# Run the simulation
vvp sim_tiled

```

### 3. Hardware Implementation (Vivado)

1. Open **Vivado** and create a new project targeting the `xc7a35tcpg236-1` part.


2. Add all `.v` source files.
3. Add timing constraints (Target: 10ns / 100MHz clock).


4. Run **Synthesis** and **Implementation**.


5. Check **Report Power** and **Report Timing Summary** for performance metrics.

