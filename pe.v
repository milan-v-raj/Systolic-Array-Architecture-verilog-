// pe.v
`timescale 1ns / 1ps

// This module defines a single Processing Element (PE).
// It's parameterized to handle different data and accumulator bit widths.
module pe #(
    parameter DATA_WIDTH = 8,  // Bit width of a single input number
    parameter ACC_WIDTH = 32   // Bit width of the accumulator to prevent overflow
) (
    // ========= I/O Ports =========
    input wire                  clk,       // System clock signal
    input wire                  rst,       // System reset signal
    input wire [DATA_WIDTH-1:0] a_in,      // Input 'A' value from the PE above
    input wire [DATA_WIDTH-1:0] b_in,      // Input 'B' value from the PE to the left

    output wire [DATA_WIDTH-1:0] a_out,     // Output 'A' value to the PE below
    output wire [DATA_WIDTH-1:0] b_out,     // Output 'B' value to the PE to the right
    output wire [ACC_WIDTH-1:0]  p_sum_out  // Output of the internal accumulator register
);

    // ========= Internal Registers =========
    // These registers hold the values for one clock cycle before passing them on.
    // This pipelined data flow is what makes the array "systolic".
    reg [DATA_WIDTH-1:0] a_reg;       // Register for the 'A' value
    reg [DATA_WIDTH-1:0] b_reg;       // Register for the 'B' value
    
    // This register holds the running sum of the products.
    reg [ACC_WIDTH-1:0]  p_sum_reg;   // The accumulator register

    // ========= Core Logic Block =========
    // This block describes what the PE does on every rising edge of the clock.
    always @(posedge clk) begin
        // If the reset signal is active, clear all internal state.
        if (rst) begin
            a_reg     <= 0;
            b_reg     <= 0;
            p_sum_reg <= 0;
        end else begin
            // --- Systolic Data Flow ---
            // On each cycle, capture the current inputs into the internal registers.
            // These registered values will be passed out to the next PEs.
            a_reg <= a_in;
            b_reg <= b_in;

            // --- Multiply-Accumulate (MAC) Operation ---
            // This is the computational heart of the PE.
            // It multiplies the current inputs (a_in * b_in) and adds the
            // result to the value already in the accumulator register.
            p_sum_reg <= p_sum_reg + (a_in * b_in);
        end
    end

    // ========= Continuous Output Assignments =========
    // These lines connect the internal registers to the output ports.
    // This ensures the outputs are the registered (one-cycle delayed) values.
    assign a_out = a_reg;       // Pass the registered 'A' value to the PE below.
    assign b_out = b_reg;       // Pass the registered 'B' value to the PE to the right.
    assign p_sum_out = p_sum_reg; // Expose the current value of the accumulator.

endmodule