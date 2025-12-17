`timescale 1ns / 1ps

module matmul_controller #(
    parameter NUM_BLOCKS = 4,
    parameter BLOCK_SIZE = 64,
    parameter ADDR_WIDTH = 10 
)(
    input wire clk,
    input wire rst,
    input wire start,
    input wire systolic_done,
    output reg done,
    output reg [ADDR_WIDTH-1:0] mem_a_addr_out, mem_b_addr_out, mem_c_addr_out,
    output reg mem_a_rd_out, mem_b_rd_out, mem_c_rd_out, mem_c_wr_out,
    output reg init_c_block_out, systolic_start_out,
    output reg systolic_rst_out
);

    localparam IDLE = 0, INIT_C_BLOCK = 1, FETCH_A = 2, FETCH_B = 3, INIT_CORE = 4;
    localparam EXECUTE = 5, READ_C_OLD = 6, WRITE_C_NEW = 7, UPDATE_POINTERS = 8, DONE_STATE = 9;

    reg [3:0] state, next_state;
    localparam COUNTER_WIDTH = (NUM_BLOCKS > 1) ? $clog2(NUM_BLOCKS) : 1;
    reg [COUNTER_WIDTH-1:0] i_block, j_block, k_block;

    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            i_block <= 0; j_block <= 0; k_block <= 0;
        end else begin
            // State is always updated
            state <= next_state;

            // Counters are only updated when transitioning out of specific states
            case(state)
                IDLE: begin
                    if (start) {i_block, j_block, k_block} <= 0;
                end
                UPDATE_POINTERS: begin
                    if (k_block == NUM_BLOCKS - 1) begin
                        k_block <= 0;
                        if (j_block == NUM_BLOCKS - 1) begin
                            j_block <= 0;
                            i_block <= i_block + 1;
                        end else begin
                            j_block <= j_block + 1;
                        end
                    end else begin
                        k_block <= k_block + 1;
                    end
                end
            endcase
        end
    end

    // Combinational logic for FSM outputs and next state
    always @(*) begin
        // Default outputs
        done=0; mem_a_addr_out=0; mem_a_rd_out=0; mem_b_addr_out=0; mem_b_rd_out=0;
        mem_c_addr_out=0; mem_c_rd_out=0; mem_c_wr_out=0; init_c_block_out=0; 
        systolic_start_out=0; systolic_rst_out=0;
        next_state = state;

        case (state)
            IDLE: if (start) next_state = INIT_C_BLOCK;
            INIT_C_BLOCK: begin
                mem_c_addr_out = (i_block * NUM_BLOCKS + j_block) * BLOCK_SIZE;
                init_c_block_out = 1; next_state = FETCH_A;
            end
            FETCH_A: begin
                mem_a_addr_out = (i_block * NUM_BLOCKS + k_block) * BLOCK_SIZE;
                mem_a_rd_out = 1; next_state = FETCH_B;
            end
            FETCH_B: begin
                mem_b_addr_out = (k_block * NUM_BLOCKS + j_block) * BLOCK_SIZE;
                mem_b_rd_out = 1; next_state = INIT_CORE;
            end
            INIT_CORE: begin
                systolic_rst_out = 1;
                next_state = EXECUTE;
            end
            EXECUTE: begin
                systolic_start_out = 1;
                if (systolic_done) next_state = READ_C_OLD;
                else next_state = EXECUTE;
            end
            READ_C_OLD: begin
                mem_c_addr_out = (i_block * NUM_BLOCKS + j_block) * BLOCK_SIZE;
                mem_c_rd_out = 1; next_state = WRITE_C_NEW;
            end
            WRITE_C_NEW: begin
                mem_c_addr_out = (i_block * NUM_BLOCKS + j_block) * BLOCK_SIZE;
                mem_c_wr_out = 1; next_state = UPDATE_POINTERS;
            end
            UPDATE_POINTERS: begin
                if (i_block == NUM_BLOCKS-1 && j_block == NUM_BLOCKS-1 && k_block == NUM_BLOCKS-1)
                    next_state = DONE_STATE;
                else if (k_block == NUM_BLOCKS-1)
                    next_state = INIT_C_BLOCK;
                else
                    next_state = FETCH_A;
            end
            DONE_STATE: begin
                done = 1; 
                if (~start) next_state = IDLE;
            end
        endcase
    end
endmodule