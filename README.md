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

The final execution time is calculated with this formula:  
Execution Time = Total Clock Cycles / Actual Maximum Clock Frequency 
 
Our target clock period was 10 ns (for a 100 MHz clock). 

The report shows a Worst Negative Slack (WNS) of +6.773 ns. 

A positive slack means our design is faster than the target. It finished its longest 
calculation 6.773 ns before the 10 ns deadline. 

Actual Minimum Period = (Target Period) - WNS = 10 ns - 6.773 ns = 3.227 ns. 

(fastest clock period our design can realistically support) 
Maximum Frequency (f_max) = 1 / 3.227 ns ≈ 310 MHz.  

 
 
This number comes from our controller's logic, which we know from the 
simulation. For a 32x32 matrix (which is a 4x4 grid of 8x8 blocks): 

• Total Block Operations: 4×4×4=64 block operations. 

• Cycles per Block: our FSM takes about 30 cycles per block (for fetches, 
core reset, execution, and accumulation). 

• Total Cycles: 64 blocks * 30 cycles/block = 1,920 cycles. 

To note : the 30 cycles comes from the following – fetch_a(1) , fetch_b(1), 
reset_systolic(1),execute (23 cycles), read_c(1), write_c(1), update_pointers(1) 
Now we plug these numbers into the formula: 
• Execution Time = 1,920 cycles / 310,000,000 cycles/second ≈ 0.00000619 
seconds. 

• that's 6.19 microseconds (µs). 

The Power report shows a Total On-Chip Power of 0.073 W (or 73 milliwatts). 
This is an exceptionally low number. A CPU running the same task might consume 
80W, and a GPU could be 150-300W. 

The Utilization report shows our entire accelerator uses only 1% of the FPGA's 
logic (LUTs and FFs). This means our design is incredibly compact and efficient. 
There is more to this!! 

Formula: Throughput = Total Operations / Execution Time 
Total Operations: For a 32x32 matrix, it's 2 * 32 * 32 * 32 = 65,536 operations. 

Execution Time: We previously calculated this from our report. 

• Max Frequency (f_max): 310 MHz 

• Total Clock Cycles: 1,920 cycles 

• Time = 1,920 / 310,000,000 = 6.2 µs (microseconds) 

Throughput Calculation: 
• 65,536 ops / 0.0000062 s ≈ 10,570,000,000 ops/sec ≈ 10.6 GOPS 

Efficiency = throughput / power = 10.6 GOPS/0.073 = 145 GOPS/Watt !!!!!! 

* 
**Logic Usage:** Uses only **1\%** of the FPGA's logic (LUTs and FFs).

