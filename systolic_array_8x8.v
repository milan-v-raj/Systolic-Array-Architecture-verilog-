// systolic_array_8x8.v
`timescale 1ns / 1ps

// This module defines a complete NxN systolic array. It's parameterized,
// but for our purposes, it's an 8x8 grid of Processing Elements (PEs).
module systolic_array_8x8 #(
    parameter N = 8,                // Dimension of the matrix (e.g., 8 for 8x8)
    parameter DATA_WIDTH = 8,       // Bit width for input matrix elements
    parameter ACC_WIDTH = 32        // Bit width for the accumulator in each PE
) (
    // ========= I/O Ports =========
    input wire clk,                  // System clock
    input wire rst,                  // System reset

    // The inputs are flattened vectors representing the data streams that will be
    // fed into the edges of the array, one "slice" per clock cycle.
    input wire [N*DATA_WIDTH-1:0] a_in_top,    // Data for Matrix A, fed to the top edge
    input wire [N*DATA_WIDTH-1:0] b_in_left,   // Data for Matrix B, fed to the left edge

    // The output is the entire resulting C matrix, flattened into a single wide vector.
    output wire [N*N*ACC_WIDTH-1:0] c_out_matrix
);

    // ========= Internal Wiring =========
    // We need 2D arrays of wires to interconnect all the PEs in the grid.

    // 'b_wires' carry data for Matrix B horizontally across the rows of PEs.
    // It's sized [N-1:0][N:0] to have N rows and N+1 columns of wires
    // (1 input column + N inter-PE columns).
    wire [DATA_WIDTH-1:0] b_wires [N-1:0][N:0];
    
    // 'a_wires' carry data for Matrix A vertically down the columns of PEs.
    // It's sized [N:0][N-1:0] to have N+1 rows and N columns of wires
    // (1 input row + N inter-PE rows).
    wire [DATA_WIDTH-1:0] a_wires [N:0][N-1:0];

    // ========= Input Connection Generation =========
    // This 'generate' block creates the connections from the top-level input ports
    // to the wires that feed the very first row and column of PEs.
    genvar i, j; // Special variables for use inside generate blocks
    generate
        for (i = 0; i < N; i = i + 1) begin : input_assign
            // Connect the i-th chunk of the 'a_in_top' vector to the i-th wire
            // at the top edge (row 0) of the 'a_wires' grid.
            assign a_wires[0][i] = a_in_top[i*DATA_WIDTH +: DATA_WIDTH];
            
            // Connect the i-th chunk of the 'b_in_left' vector to the i-th wire
            // at the left edge (column 0) of the 'b_wires' grid.
            assign b_wires[i][0] = b_in_left[i*DATA_WIDTH +: DATA_WIDTH];
        end
    endgenerate

    // ========= PE Grid Generation =========
    // This is the core of the design. These nested 'generate for' loops
    // create and connect the 2D grid of 64 (8x8) Processing Elements.
    // This is much more scalable than manually instantiating 64 modules.
    generate
        // Loop to generate each row of PEs
        for (i = 0; i < N; i = i + 1) begin : row_gen
            // Loop to generate each PE within a row
            for (j = 0; j < N; j = j + 1) begin : col_gen
                
                // Instantiate one Processing Element module
                pe #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACC_WIDTH(ACC_WIDTH)
                ) u_pe (
                    .clk(clk),
                    .rst(rst),
                    
                    // --- Data Inputs ---
                    // The vertical input 'a_in' connects to the wire from the PE above it.
                    .a_in(a_wires[i][j]),
                    // The horizontal input 'b_in' connects to the wire from the PE to its left.
                    .b_in(b_wires[i][j]),
                    
                    // --- Data Outputs (to neighbors) ---
                    // The vertical output 'a_out' connects to the wire for the PE below it.
                    .a_out(a_wires[i+1][j]),
                    // The horizontal output 'b_out' connects to the wire for the PE to its right.
                    .b_out(b_wires[i][j+1]),

                    // --- Result Output ---
                    // The PE's final accumulated sum is connected to its corresponding
                    // slice of the main output vector, c_out_matrix.
                    .p_sum_out(c_out_matrix[ (i*N + j)*ACC_WIDTH +: ACC_WIDTH ])
                );
            end
        end
    endgenerate

endmodule