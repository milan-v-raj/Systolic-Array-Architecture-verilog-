import torch
import time

# Set matrix dimension
DIM = 32

# Generate random matrices
torch.manual_seed(42)
A = torch.randint(0, 100, (DIM, DIM), dtype=torch.int64)
B = torch.randint(0, 100, (DIM, DIM), dtype=torch.int64)

# Warm-up (important if you’re using GPU, but harmless on CPU)
_ = torch.matmul(A, B)

# Measure time
start_time = time.time()
C = torch.matmul(A, B)  # Matrix multiplication
end_time = time.time()

# Print results
print("Matrix A:\n", A)
print("\nMatrix B:\n", B)
print("\nResult C = A x B:\n", C)
print(f"\nTime taken: {(end_time - start_time) * 1e6:.2f} microseconds")
