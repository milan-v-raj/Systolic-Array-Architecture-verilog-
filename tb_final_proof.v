`timescale 1ns / 1ps // MODIFIED: Timescale is now in picoseconds

module tb_final_proof;

    parameter N = 8;
    parameter DATA_WIDTH = 8;
    parameter ACC_WIDTH = 32;
    // The clock period is now 500ps
    parameter CLK_PERIOD = 500; // MODIFIED: Period in ps

    reg clk, rst;
    logic [DATA_WIDTH-1:0] A [0:N-1][0:N-1];
    logic [DATA_WIDTH-1:0] B [0:N-1][0:N-1];
    logic [ACC_WIDTH-1:0]  C_golden [0:N-1][0:N-1];
    
    // --- Signals for the Systolic Array DUT ---
    reg [N*DATA_WIDTH-1:0] a_in_top;
    reg [N*DATA_WIDTH-1:0] b_in_left;
    wire [N*N*ACC_WIDTH-1:0] c_out_matrix;

    // --- Instantiate the Systolic Array ---
    systolic_array_8x8 #(.N(N)) dut (
        .clk(clk), .rst(rst),
        .a_in_top(a_in_top), .b_in_left(b_in_left),
        .c_out_matrix(c_out_matrix)
    );

    // --- Clock Generator ---
    initial begin
        clk = 0;
        // MODIFIED: #250 creates a 250ps half-period (500ps full period)
        forever #(CLK_PERIOD/2) clk = ~clk; 
    end

    // --- Main Proof Sequence ---
    initial begin
        time time_naive_start, time_naive_end;
        time time_systolic_start, time_systolic_end;
        longint cycles_naive, cycles_systolic;
        integer error_count;

        $display("--- Starting Head-to-Head Complexity Proof for N=%0d ---", N);

        // Procedurally generate input matrices
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) begin
                A[i][j] = i + j;
                B[i][j] = i - j;
                C_golden[i][j] = 0;
            end
        end

        // --- PART 1: NAIVE O(N^3) EXECUTION ---
        $display("\n1. Running Naive O(N^3) Multiplication...");
        // Wait for the first clock edge to align our timing capture
        @(posedge clk); 
        time_naive_start = $time;
        // This loop runs N*N*N times, with each iteration taking one clock cycle
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) begin
                for (int k = 0; k < N; k++) begin
                    C_golden[i][j] = C_golden[i][j] + (A[i][k] * B[k][j]);
                    @(posedge clk); // Each operation "costs" one clock cycle
                end
            end
        end
        time_naive_end = $time;
        cycles_naive = (time_naive_end - time_naive_start) / CLK_PERIOD;
        $display("   -> Naive method finished in %0d clock cycles.", cycles_naive);
        $display("      (Simulated time: %0t ns)", (time_naive_end - time_naive_start)/1000);

        // --- PART 2: SYSTOLIC O(N) EXECUTION ---
        $display("\n2. Running Parallel O(N) Systolic Array...");
        rst = 1; #20; rst = 0;
        
        // Wait for the first clock edge to align our timing capture
        @(posedge clk);
        time_systolic_start = $time;
        // This loop runs for 3*N-1 cycles to feed the array
        for (int cycle = 0; cycle < (3*N-1); cycle++) begin
            for (int i = 0; i < N; i++) begin
                // On-the-fly skewing logic...
                if ((cycle-i >= 0) && (cycle-i < N)) begin
                    a_in_top[i*DATA_WIDTH +: DATA_WIDTH] = B[cycle-i][i];
                    b_in_left[i*DATA_WIDTH +: DATA_WIDTH] = A[i][cycle-i];
                end else begin
                    a_in_top[i*DATA_WIDTH +: DATA_WIDTH] = 0;
                    b_in_left[i*DATA_WIDTH +: DATA_WIDTH] = 0;
                end
            end
            @(posedge clk); // This is where simulation time actually passes
        end
        time_systolic_end = $time;
        cycles_systolic = (time_systolic_end - time_systolic_start) / CLK_PERIOD;
        $display("   -> Systolic Array finished in %0d clock cycles.", cycles_systolic);
        $display("      (Simulated time: %0t ns)", (time_systolic_end - time_systolic_start)/1000);
        
        // --- PART 3: VERIFICATION AND CONCLUSION ---
        // (This part remains the same)
        error_count = 0;
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) begin
                logic [ACC_WIDTH-1:0] systolic_result = c_out_matrix[(i*N+j)*ACC_WIDTH +: ACC_WIDTH];
                if (systolic_result !== C_golden[i][j]) begin
                    error_count = error_count + 1;
                end
            end
        end
        
        $display("\n" + "="*50);
        $display("---           FINAL PROOF          ---");
        $display("="*50);
        $display("Verification Result: %s", (error_count == 0) ? "PASSED" : "FAILED");
        $display("Matrix Size (N): %0d", N);
        $display("Naive Sequential Time: %0d cycles (%0t ns)", cycles_naive, (time_naive_end - time_naive_start)/1000);
        $display("Systolic Parallel Time:  %0d cycles (%0t ns)", cycles_systolic, (time_systolic_end - time_systolic_start)/1000);
        $display("Performance Speedup: %.2fx", real'(cycles_naive) / real'(cycles_systolic));
        $display("="*50);

        $finish;
    end
endmodule