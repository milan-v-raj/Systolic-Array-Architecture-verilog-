`timescale 1ns / 1ps

module tiled_matmul_engine #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH = 32,
    parameter MATRIX_DIM = 32,
    parameter BLOCK_DIM = 8
)(
    input wire clk,
    input wire rst,
    input wire start,
    output wire done
);

    localparam NUM_BLOCKS = MATRIX_DIM / BLOCK_DIM;
    localparam BLOCK_SIZE = BLOCK_DIM * BLOCK_DIM;
    localparam MATRIX_SIZE = MATRIX_DIM * MATRIX_DIM;

    reg [DATA_WIDTH-1:0] mem_a [0:MATRIX_SIZE-1];
    reg [DATA_WIDTH-1:0] mem_b [0:MATRIX_SIZE-1];
    reg [ACC_WIDTH-1:0]  mem_c_acc [0:MATRIX_SIZE-1];

    wire [$clog2(MATRIX_SIZE)-1:0] mem_a_addr, mem_b_addr, mem_c_addr;
    wire mem_a_rd, mem_b_rd, mem_c_rd, mem_c_wr;
    wire init_c_block, systolic_start, systolic_rst;
    reg systolic_done;

    matmul_controller #(
        .NUM_BLOCKS(NUM_BLOCKS),
        .BLOCK_SIZE(BLOCK_SIZE),
        .ADDR_WIDTH($clog2(MATRIX_SIZE))
    ) u_controller (
        .clk(clk), .rst(rst), .start(start), .systolic_done(systolic_done), .done(done),
        .mem_a_addr_out(mem_a_addr), .mem_a_rd_out(mem_a_rd),
        .mem_b_addr_out(mem_b_addr), .mem_b_rd_out(mem_b_rd),
        .mem_c_addr_out(mem_c_addr), .mem_c_rd_out(mem_c_rd), .mem_c_wr_out(mem_c_wr),
        .init_c_block_out(init_c_block), .systolic_start_out(systolic_start),
        .systolic_rst_out(systolic_rst)
    );

    reg [BLOCK_DIM*DATA_WIDTH-1:0] systolic_a_in;
    reg [BLOCK_DIM*DATA_WIDTH-1:0] systolic_b_in;
    wire [BLOCK_SIZE*ACC_WIDTH-1:0]  systolic_c_out;

    systolic_array_8x8 u_systolic_core (
        .clk(clk), .rst(systolic_rst || rst),
        .a_in_top(systolic_a_in), .b_in_left(systolic_b_in), .c_out_matrix(systolic_c_out)
    );

    reg [DATA_WIDTH-1:0] block_a_buf [0:BLOCK_SIZE-1];
    reg [DATA_WIDTH-1:0] block_b_buf [0:BLOCK_SIZE-1];
    reg [ACC_WIDTH-1:0]  block_c_buf [0:BLOCK_SIZE-1];
    integer i, b_row, a_col;

    always @(posedge clk) begin
        if (mem_a_rd) for(i=0; i<BLOCK_SIZE; i=i+1) block_a_buf[i] <= mem_a[mem_a_addr + i];
        if (mem_b_rd) for(i=0; i<BLOCK_SIZE; i=i+1) block_b_buf[i] <= mem_b[mem_b_addr + i];
        if (mem_c_rd) for(i=0; i<BLOCK_SIZE; i=i+1) block_c_buf[i] <= mem_c_acc[mem_c_addr + i];
        if (init_c_block) for(i=0; i<BLOCK_SIZE; i=i+1) mem_c_acc[mem_c_addr + i] <= 0;
        if (mem_c_wr) begin
            for(i=0; i<BLOCK_SIZE; i=i+1) begin
                mem_c_acc[mem_c_addr + i] <= block_c_buf[i] + systolic_c_out[(i*ACC_WIDTH) +: ACC_WIDTH];
            end
        end
    end
    
    reg [4:0] stream_cycle_count;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            systolic_a_in <= 0; systolic_b_in <= 0; systolic_done <= 0; stream_cycle_count <= 0;
        end else begin
            if (systolic_start && !systolic_done) begin
                for (i = 0; i < BLOCK_DIM; i = i + 1) begin
                    b_row = stream_cycle_count - i; a_col = stream_cycle_count - i;
                    if (b_row >= 0 && b_row < BLOCK_DIM) systolic_a_in[i*DATA_WIDTH +: DATA_WIDTH] <= block_b_buf[b_row*BLOCK_DIM + i];
                    else systolic_a_in[i*DATA_WIDTH +: DATA_WIDTH] <= 0;
                    if (a_col >= 0 && a_col < BLOCK_DIM) systolic_b_in[i*DATA_WIDTH +: DATA_WIDTH] <= block_a_buf[i*BLOCK_DIM + a_col];
                    else systolic_b_in[i*DATA_WIDTH +: DATA_WIDTH] <= 0;
                end
                stream_cycle_count <= stream_cycle_count + 1;
            end

            if (stream_cycle_count == (3*BLOCK_DIM - 2)) begin
                systolic_done <= 1; stream_cycle_count <= 0;
            end

            if (systolic_rst) begin 
                systolic_done <= 0;
            end
        end
    end
endmodule