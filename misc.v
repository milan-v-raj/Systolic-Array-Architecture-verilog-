`timescale 1ns / 1ps

module tb_tiled_matmul;

    localparam MATRIX_DIM = 16;

    localparam DATA_WIDTH = 8;
    localparam ACC_WIDTH = 32;
    localparam MATRIX_SIZE = MATRIX_DIM * MATRIX_DIM;

    reg clk, rst, start;
    wire done;

    reg [ACC_WIDTH-1:0] expected_c_mem [0:MATRIX_SIZE-1];

    tiled_matmul_engine #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .MATRIX_DIM(MATRIX_DIM)
    ) u_dut (
        .clk(clk), .rst(rst), .start(start), .done(done)
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

    initial begin
        string row_str;
        integer error_count;
        
        $display("INFO: %dx%d Testbench started.", MATRIX_DIM, MATRIX_DIM);
        
        $display("INFO: Initializing memories...");
        $readmemh("matrix_a.mem", u_dut.mem_a);
        $readmemh("matrix_b.mem", u_dut.mem_b);
        $readmemh("expected_c.mem", expected_c_mem);
        $display("INFO: Memory initialization complete.");
        
        rst = 1; start = 0; error_count = 0; #20; rst = 0;
        
        start = 1; @(posedge clk); start = 0;
        $display("INFO: Start signal pulsed. Hardware is running...");
        
        wait (done);
        $display("INFO: Done signal received at time %t.", $time);

        $display("\n--- Verilog DUT Result Matrix ---");
        for (int i = 0; i < MATRIX_DIM; i = i + 1) begin
            row_str = "";
            for (int j = 0; j < MATRIX_DIM; j = j + 1) begin
                row_str = $sformatf("%s %8h", row_str, u_dut.mem_c_acc[i*MATRIX_DIM + j]);
            end
            $display(row_str);
        end

        $display("\n--- PyTorch Expected Matrix ---");
        for (int i = 0; i < MATRIX_DIM; i = i + 1) begin
            row_str = "";
            for (int j = 0; j < MATRIX_DIM; j = j + 1) begin
                row_str = $sformatf("%s %8h", row_str, expected_c_mem[i*MATRIX_DIM + j]);
            end
            $display(row_str);
        end
        $display("\n");
        
        $display("INFO: Verifying all %d matrix elements...", MATRIX_SIZE);
        for (int i = 0; i < MATRIX_SIZE; i = i + 1) begin
            if (u_dut.mem_c_acc[i] !== expected_c_mem[i]) begin
                if (error_count < 10) $display("ERROR at index %d! Expected: %h, Got: %h", 
                                             i, expected_c_mem[i], u_dut.mem_c_acc[i]);
                error_count = error_count + 1;
            end
        end

        if (error_count == 0) $display("\n✅ ✅ ✅ SUCCESS! All %d matrix elements match the PyTorch result.", MATRIX_SIZE);
        else $display("\n❌ ❌ ❌ FAILURE! Found %0d mismatches.", error_count);

        $finish;
    end
endmodule