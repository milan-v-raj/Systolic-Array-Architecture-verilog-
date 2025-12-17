// tb_systolic_array.v (Corrected)
`timescale 1ns / 1ps

module tb_systolic_array;

    // --- Parameters ---
    parameter N = 8;
    parameter DATA_WIDTH = 8;
    parameter ACC_WIDTH = 32;
    parameter SIM_CYCLES = 3 * N - 1; // Time to feed all data

    // --- Testbench Registers and Wires ---
    reg clk;
    reg rst;
    reg [N*DATA_WIDTH-1:0] a_in_top;
    reg [N*DATA_WIDTH-1:0] b_in_left;
    wire [N*N*ACC_WIDTH-1:0] c_out_matrix;

    // --- Memories for test data ---
    reg [DATA_WIDTH-1:0] skewed_a_mem [0:SIM_CYCLES-1][0:N-1];
    reg [DATA_WIDTH-1:0] skewed_b_mem [0:SIM_CYCLES-1][0:N-1];
    reg [ACC_WIDTH-1:0] expected_c_mem [0:N*N-1];

    integer cycle, i, j;
    integer error_count = 0;

    // --- Instantiate the DUT (Device Under Test) ---
    systolic_array_8x8 #(
        .N(N),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .a_in_top(a_in_top),
        .b_in_left(b_in_left),
        .c_out_matrix(c_out_matrix)
    );

    // --- Clock Generation ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period -> 100MHz clock
    end

    // --- Test Sequence ---
    initial begin
        // --- Declare variables at the top of the block ---
        integer matrix_idx;
        logic [ACC_WIDTH-1:0] result;
        string row_str; // String to build each row for printing

        // 1. Load test data from files
        $readmemh("skewed_a.mem", skewed_a_mem);
        $readmemh("skewed_b.mem", skewed_b_mem);
        $readmemh("expected_c.mem", expected_c_mem);
        
        // 2. Reset the DUT
        rst = 1;
        a_in_top = 0;
        b_in_left = 0;
        #20;
        rst = 0;
        #5;

        // 3. Feed the skewed data into the array cycle-by-cycle
        $display("INFO: Starting data feed into systolic array...");
        for (cycle = 0; cycle < SIM_CYCLES; cycle = cycle + 1) begin
            @(posedge clk);
            for (i = 0; i < N; i = i + 1) begin
                a_in_top[i*DATA_WIDTH +: DATA_WIDTH] = skewed_a_mem[cycle][i];
                b_in_left[i*DATA_WIDTH +: DATA_WIDTH] = skewed_b_mem[cycle][i];
            end
        end
        
        // 4. Stop feeding data and wait
        @(posedge clk);
        a_in_top = 0;
        b_in_left = 0;
        #10;
        
        $display("INFO: Data feed complete. Displaying results...");

        // --- ADDED: Display matrix contents ---
        
        // Display the matrix calculated by your Verilog hardware
        $display("\n--- Verilog DUT Result Matrix (Got) ---");
        for (i = 0; i < N; i = i + 1) begin
            row_str = ""; // Clear the string for the new row
            for (j = 0; j < N; j = j + 1) begin
                // Use $sformatf to build the string for one row
                result = c_out_matrix[(i*N + j)*ACC_WIDTH +: ACC_WIDTH];
                row_str = $sformatf("%s %8h", row_str, result);
            end
            $display(row_str); // Display the completed row
        end

        // Display the expected matrix from PyTorch
        $display("\n--- PyTorch Golden Matrix (Expected) ---");
        for (i = 0; i < N; i = i + 1) begin
            row_str = "";
            for (j = 0; j < N; j = j + 1) begin
                row_str = $sformatf("%s %8h", row_str, expected_c_mem[i*N + j]);
            end
            $display(row_str);
        end
        $display("\n");
        // --- END of added section ---

        // 5. Verify the output matrix
        $display("INFO: Verifying all %d matrix elements...", N*N);
        error_count = 0;
        for (i = 0; i < N; i = i + 1) begin
            for (j = 0; j < N; j = j + 1) begin
                matrix_idx = i*N + j;
                result = c_out_matrix[matrix_idx*ACC_WIDTH +: ACC_WIDTH];
                
                if (result !== expected_c_mem[matrix_idx]) begin
                    // Only print the first 10 errors to avoid flooding the console
                    if (error_count < 10) begin
                        $display("ERROR: Mismatch at C[%0d][%0d]! Expected: %h, Got: %h",
                                 i, j, expected_c_mem[matrix_idx], result);
                    end
                    error_count = error_count + 1;
                end
            end
        end

        // 6. Report final status
        if (error_count == 0) begin
            $display("\n SUCCESS! All %0d matrix elements match the PyTorch result.", N*N);
        end else begin
            $display("\n FAILURE! Found %0d mismatches.", error_count);
        end

        $finish;
    end

endmodule