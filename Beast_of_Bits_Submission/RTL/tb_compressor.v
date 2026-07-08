`timescale 1ns/1ps

module tb_compressor;
    reg clk = 0;
    reg rst = 1;
    reg data_in = 0;
    reg data_valid = 0;
    
    wire [3:0] run_count;
    wire run_bit;
    wire out_valid;

    // Instantiate compressor
    rle_compressor uut (
        .clk(clk), 
        .rst(rst),
        .data_in(data_in), 
        .data_valid(data_valid),
        .run_count(run_count), 
        .run_bit(run_bit),
        .out_valid(out_valid)
    );

    // 100 MHz clock generation (Period = 10ns)
    always #5 clk = ~clk;   

    integer fd_in, fd_out, bit_val;
    integer i; // Declaring integer for index instead of reg [3:0]

    initial begin
        // Open input/output files (Must be inside the ModelSim folder)
        fd_in  = $fopen("bits.txt",        "r");
        fd_out = $fopen("compressed.txt",  "w");

        if (fd_in == 0) begin
            $display("ERROR: bits.txt could not be found!");
            $finish;
        end

        #20 rst = 0; // Release active-high reset

        // Feed bits from file one per clock cycle
        while (!$feof(fd_in)) begin
            if ($fscanf(fd_in, "%1d\n", bit_val) == 1) begin
                @(posedge clk);
                data_in    = bit_val;
                data_valid = 1;
                
                @(negedge clk);
                // Capture completed runs immediately if flagged by hardware
                if (out_valid) begin
                    $fwrite(fd_out, "%0d\n", run_bit);
                    for (i = 3; i >= 0; i = i - 1) begin
                        $fwrite(fd_out, "%0d\n", run_count[i]);
                    end
                end
            end
        end

        // File stream finished: dropping data input validation
        @(posedge clk);
        data_valid = 0;

        // Give the hardware one cycle to register the data_valid drop and flush
        @(negedge clk);
        if (out_valid) begin
            $fwrite(fd_out, "%0d\n", run_bit);
            for (i = 3; i >= 0; i = i - 1) begin
                $fwrite(fd_out, "%0d\n", run_count[i]);
            end
        end

        repeat(5) @(posedge clk);

        $fclose(fd_in);
        $fclose(fd_out);
        $display("SUCCESS: Compression done. Check compressed.txt");
        $finish;
    end
endmodule
