`timescale 1ns / 1ps

module tb_naive_matmul;

    localparam MATRIX_DIM = 32; // Must match Python script
    parameter CLK_PERIOD = 10;

    reg clk, rst, start;
    wire done;

    // Instantiate the Naive DUT
    naive_matmul #(.MATRIX_DIM(MATRIX_DIM)) dut (
        .clk(clk), .rst(rst), .start(start), .done(done)
    );

    initial begin clk = 0; forever #(CLK_PERIOD/2) clk = ~clk; end

    initial begin
        time start_time, end_time;
        longint total_cycles;

        $display("--- Naive O(N^3) Simulation for N=%0d ---", MATRIX_DIM);
        
        // Load memories from files
        $display("INFO: Initializing memories...");
        $readmemh("matrix_a_naive.mem", dut.mem_a);
        $readmemh("matrix_b_naive.mem", dut.mem_b);
        $display("INFO: Memory initialization complete.");
        
        rst = 1; start = 0; #20; rst = 0;
        
        start = 1;
        @(posedge clk);
        start = 0;
        
        $display("INFO: Start signal pulsed. Hardware is running... (This will take a very long time)");
        start_time = $time;
        
        wait (done);
        end_time = $time;
        
        total_cycles = (end_time - start_time) / CLK_PERIOD;
        
        $display("\n" + "="*50);
        $display("---           SIMULATION COMPLETE          ---");
        $display("="*50);
        $display("Matrix Size (N): %0d", MATRIX_DIM);
        $display("Total Clock Cycles: %0d", total_cycles);
        $display("Total Simulated Time: %0t ns", (end_time - start_time)/1000);
        $display("="*50);

        $finish;
    end
endmodule