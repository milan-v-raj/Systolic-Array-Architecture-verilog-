import torch
import numpy as np

N = 8  # Matrix dimension is 8x8

# Matrices A and B
A_torch = torch.randint(0, 16, (N, N), dtype=torch.int64)
B_torch = torch.randint(0, 16, (N, N), dtype=torch.int64)
C_torch = torch.matmul(A_torch, B_torch)

# Skew the input matrices for the systolic array 
# Total simulation cycles required for inputs: 3*N - 1 = 23
total_cycles = 3 * N - 1

skewed_A = np.zeros((total_cycles, N), dtype=int)
skewed_B = np.zeros((total_cycles, N), dtype=int)

# This is the logic that creates the "conveyor belt" data
# It correctly spaces the data with zeros for the systolic array's timing
A_np = A_torch.numpy()
B_np = B_torch.numpy()

for t in range(total_cycles):
    for i in range(N):
        # Skew logic for B (fed to top input)
        b_row = t - i
        if 0 <= b_row < N:
            skewed_A[t][i] = B_np[b_row][i]

        # Skew logic for A (fed to left input)
        a_col = t - i
        if 0 <= a_col < N:
            skewed_B[t][i] = A_np[i][a_col]

#Helper to save matrix to a Verilog-friendly hex file
def save_to_mem(matrix, filename):
    with open(filename, 'w') as f:
        for row in matrix:
            # Each row in the file corresponds to one clock cycle
            f.write(' '.join([f'{val:02x}' for val in row]) + '\n')

def save_result_to_mem(matrix, filename):
    flat_list = matrix.flatten().tolist()
    with open(filename, 'w') as f:
        f.write(' '.join([f'{val:08x}' for val in flat_list]) + '\n')

# Save the skewed data
save_to_mem(skewed_A, "skewed_a.mem")
save_to_mem(skewed_B, "skewed_b.mem")
save_result_to_mem(C_torch, "expected_c.mem")

print(f"Successfully generated skewed data files for an {N}x{N} multiplication.")