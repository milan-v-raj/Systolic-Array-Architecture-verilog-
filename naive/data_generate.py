import torch
import numpy as np

# --- Configuration ---
DIM = 32 # Or start with 32
FILENAME_A = "matrix_a_naive.mem"
FILENAME_B = "matrix_b_naive.mem"

# --- Generate Matrices ---
print(f"Generating {DIM}x{DIM} matrices...")
A_torch = torch.randint(0, 16, (DIM, DIM), dtype=torch.int64)
B_torch = torch.randint(0, 16, (DIM, DIM), dtype=torch.int64)

def save_to_mem(matrix, filename):
    print(f"Saving matrix to {filename}...")
    flat_list = matrix.flatten().tolist()
    with open(filename, 'w') as f:
        f.write(' '.join([f'{val:02x}' for val in flat_list]))
    print(f"Successfully saved {filename}")

save_to_mem(A_torch, FILENAME_A)
save_to_mem(B_torch, FILENAME_B)