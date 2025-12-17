import torch
import numpy as np

# ===================================================================
#               CONFIGURATION: SET MATRIX DIMENSION HERE
# ===================================================================
DIM = 16 # <-- Set to your desired size (e.g., 32, 64, 128)
# ===================================================================

# --- Static Parameters ---
BLOCK_DIM = 8
DATA_WIDTH = 8
ACC_WIDTH = 32
FILENAME_A = "matrix_a.mem"
FILENAME_B = "matrix_b.mem"
FILENAME_C = "expected_c.mem"

# --- Generate Matrices ---
print(f"Generating {DIM}x{DIM} matrices...")
torch.manual_seed(42)
A_torch = torch.randint(0, 16, (DIM, DIM), dtype=torch.int64)
B_torch = torch.randint(0, 16, (DIM, DIM), dtype=torch.int64)

# --- Calculate Golden Result ---
print("Calculating golden result with PyTorch...")
C_torch = torch.matmul(A_torch, B_torch)
print("Calculation complete.")

# --- Function: Save in Block-Major format (for hardware) ---
def save_blocked_to_mem(matrix, filename, bits):
    print(f"Saving matrix to {filename} in block-major format...")
    
    num_blocks_dim = DIM // BLOCK_DIM
    matrix_np = matrix.numpy()
    
    # Rearrange the matrix from row-major to block-major
    blocked_list = []
    for i_block in range(num_blocks_dim):
        for j_block in range(num_blocks_dim):
            start_row = i_block * BLOCK_DIM
            start_col = j_block * BLOCK_DIM
            
            # Extract the 8x8 block
            block = matrix_np[start_row : start_row + BLOCK_DIM, 
                              start_col : start_col + BLOCK_DIM]
            
            # Flatten the block and add its elements to our list
            blocked_list.extend(block.flatten().tolist())

    hex_format = f'{{:0{bits//4}x}}'
    with open(filename, 'w') as f:
        f.write(' '.join([hex_format.format(val) for val in blocked_list]))
    print(f"Successfully saved {filename}")

# --- Function: Print actual + flattened matrix ---
def show_matrix_info(name, matrix):
    matrix_np = matrix.numpy()
    flattened = matrix_np.flatten().tolist()
    print(f"\n{name} (shape {matrix_np.shape}):\n")
    print(matrix_np)  # actual 2D matrix
    print(f"\n{name} Flattened Row-Major (length={len(flattened)}):\n")
    print(flattened[:], "...")  # show first 64 numbers for brevity
    return flattened

# --- Save all three matrices using the new function ---
save_blocked_to_mem(A_torch, FILENAME_A, bits=DATA_WIDTH)
save_blocked_to_mem(B_torch, FILENAME_B, bits=DATA_WIDTH)
save_blocked_to_mem(C_torch, FILENAME_C, bits=ACC_WIDTH)

# --- Display flattened & actual matrices ---
flat_A = show_matrix_info("Matrix A", A_torch)
flat_B = show_matrix_info("Matrix B", B_torch)
flat_C = show_matrix_info("Matrix C (Golden)", C_torch)
