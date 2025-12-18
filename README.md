# Systolic-Array-Architecture-verilog-
# High-Performance Systolic Array Matrix Multiplication Accelerator

This project focuses on the design, implementation, and verification of a hardware accelerator for matrix multiplication based on a **Systolic Array** architecture. It compares this hardware-first approach against naive sequential hardware and optimized software baselines like PyTorch.

##  Project Overview

Modern neural networks rely heavily on matrix multiplication, but direct implementations on parallel hardware often hit the "Memory Wall," where compute units are starved for data from slow off-chip memory. The Systolic Array solves this by optimizing data orchestration, ensuring hardware remains efficient through deep pipelining, local communication, and massive data reuse.

### Key Performance Benchmarks (32x32 Matrix)

Based on synthesis for a Xilinx Artix-7 FPGA (xc7a35tcpg236-1):

<img width="797" height="446" alt="image" src="https://github.com/user-attachments/assets/eda12988-9e65-4a80-9763-36a345eb4c94" />


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
**
Vivado Results  **
<img width="1628" height="881" alt="image" src="https://github.com/user-attachments/assets/3249ea25-1f18-470e-88c7-d8864bda2cfd" />

# Project Analysis: Systolic Array Matrix Multiplication

This section details the performance and efficiency metrics for the Systolic Array accelerator, based on Vivado synthesis and implementation results.

---

##  Performance Calculation

The final execution time is determined by the total clock cycles required for the operation divided by the maximum achievable clock frequency.

### 1. Maximum Frequency (f_{max})

* 
**Target Clock Period:** 10\text{ ns} (100\text{ MHz}).


* 
**Worst Negative Slack (WNS):** +6.773\text{ ns}.


* 
**Actual Minimum Period:** \text{Target Period} - \text{WNS} = 10\text{ ns} - 6.773\text{ ns} = 3.227\text{ ns}.


* 
**Maximum Frequency (f_{max}):** 1 / 3.227\text{ ns} \approx \mathbf{310\text{ MHz}}.



### 2. Total Clock Cycles (32x32 Matrix)

For a 32 \times 32 matrix (comprising a 4 \times 4 grid of 8 \times 8 blocks), the cycle breakdown is as follows:

* 
**Total Block Operations:** 4 \times 4 \times 4 = 64 block operations.


* 
**Cycles per Block:** \approx 30\text{ cycles}.


* 
*Breakdown:* `fetch_a` (1), `fetch_b` (1), `reset_systolic` (1), `execute` (23), `read_c` (1), `write_c` (1), `update_pointers` (1).




* 
**Total Cycles:** 64\text{ blocks} \times 30\text{ cycles/block} = \mathbf{1,920\text{ cycles}}.



### 3. Execution Time

* 
**Formula:** 1,920\text{ cycles} / 310,000,000\text{ cycles/second} \approx 0.00000619\text{ seconds}.


* 
**Result:** **6.19\text{ microseconds (\textmu s)}**.



---

##  Throughput and Efficiency

### Throughput

* 
**Total Operations:** 2 \times 32 \times 32 \times 32 = 65,536\text{ operations}.


* 
**Calculation:** 65,536\text{ ops} / 0.0000062\text{ s} \approx \mathbf{10.6\text{ GOPS}}.



### Power and Efficiency

* 
**Total On-Chip Power:** **0.073\text{ W}** (73\text{ mW}).


* 
**Power Efficiency:** 10.6\text{ GOPS} / 0.073\text{ W} = \mathbf{145\text{ GOPS/Watt}}.



---

##  Resource Utilization

The implementation on the Artix-7 FPGA is highly optimized:

* 
**Logic Usage:** Uses only **1\%** of the FPGA's logic (LUTs and FFs).

