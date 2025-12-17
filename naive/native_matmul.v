`timescale 1ns / 1ps

module naive_matmul #(
    parameter MATRIX_DIM = 32,
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH = 32
)(
    input wire clk,
    input wire rst,
    input wire start,
    output reg done
);

    localparam MATRIX_SIZE = MATRIX_DIM * MATRIX_DIM;

    // Internal memories for the matrices
    reg [DATA_WIDTH-1:0] mem_a [0:MATRIX_SIZE-1];
    reg [DATA_WIDTH-1:0] mem_b [0:MATRIX_SIZE-1];
    reg [ACC_WIDTH-1:0]  mem_c [0:MATRIX_SIZE-1];

    // State machine and loop counters
    localparam S_IDLE = 0, S_COMPUTE = 1, S_DONE = 2;
    reg [1:0] state;
    integer i, j, k; // Use integers for large loops in simulation

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            done <= 0;
            i <= 0; j <= 0; k <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    done <= 0;
                    if (start) begin
                        i <= 0; j <= 0; k <= 0;
                        state <= S_COMPUTE;
                    end
                end
                
                S_COMPUTE: begin
                    // This is the O(N^3) operation.
                    // On each clock cycle, we do ONE multiply-accumulate.
                    mem_c[i*MATRIX_DIM + j] <= mem_c[i*MATRIX_DIM + j] + (mem_a[i*MATRIX_DIM + k] * mem_b[k*MATRIX_DIM + j]);

                    // Update loop counters
                    if (k < MATRIX_DIM - 1) begin
                        k <= k + 1;
                    end else begin
                        k <= 0;
                        if (j < MATRIX_DIM - 1) begin
                            j <= j + 1;
                        end else begin
                            j <= 0;
                            if (i < MATRIX_DIM - 1) begin
                                i <= i + 1;
                            end else begin
                                // All loops are finished
                                state <= S_DONE;
                            end
                        end
                    end
                end

                S_DONE: begin
                    done <= 1;
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule