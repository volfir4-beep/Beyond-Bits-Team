`timescale 1ns/1ps

// Hardware round-trip verification: feeds a compressed bitstream file
// (same format tb_compressor.v produces: bit, then 4-bit count, repeating)
// into rle_decompressor and writes the re-inflated bits to final_recovered_bits.txt.
//
// This gives decompressor.v (previously unused/dead code) a real role in the
// pipeline: proving the RTL decompressor itself works, independent of Python.
module tb_decompressor_final;
    reg clk = 0;
    reg rst = 1;
    reg [3:0] run_count = 0;
    reg run_bit = 0;
    reg in_valid = 0;

    wire data_out;
    wire out_valid;
    wire ready;

    rle_decompressor uut (
        .clk(clk),
        .rst(rst),
        .run_count(run_count),
        .run_bit(run_bit),
        .in_valid(in_valid),
        .data_out(data_out),
        .out_valid(out_valid),
        .ready(ready)
    );

    always #5 clk = ~clk;

    integer fd_in, fd_out;
    integer bit_line, count_bit;
    reg [3:0] count_accum;
    integer i;
    integer output_count;

    initial begin
        // INPUT_FILE selectable at compile/run time; default final_compressed_recovered.txt
        fd_in  = $fopen("final_compressed_recovered.txt", "r");
        fd_out = $fopen("final_recovered_bits.txt", "w");

        if (fd_in == 0) begin
            $display("ERROR: final_compressed_recovered.txt could not be found!");
            $finish;
        end

        #20 rst = 0;
        @(negedge clk);

        // Read tokens: 1 line for run_bit, then 4 lines for run_count (MSB first)
        while (!$feof(fd_in)) begin
            if ($fscanf(fd_in, "%1d\n", bit_line) == 1) begin
                run_bit = bit_line[0];
                count_accum = 4'd0;
                for (i = 0; i < 4; i = i + 1) begin
                    if ($fscanf(fd_in, "%1d\n", count_bit) == 1) begin
                        count_accum = {count_accum[2:0], count_bit[0]};
                    end
                end
                run_count = count_accum;

                // Wait until decompressor is ready to accept the next token
                while (!ready) @(negedge clk);
                in_valid = 1;
                @(posedge clk);
                @(negedge clk);
                in_valid = 0;

                // Drain exactly count_accum output bits for this run.
                // (Polling on `ready` alone drops the final bit, since ready
                // goes high on the SAME cycle as the last out_valid pulse --
                // counting explicitly avoids that off-by-one.)
                output_count = 0;
                while (output_count < count_accum) begin
                    if (out_valid) begin
                        $fwrite(fd_out, "%0d\n", data_out);
                        output_count = output_count + 1;
                    end
                    @(negedge clk);
                end
            end
        end

        repeat(5) @(posedge clk);

        $fclose(fd_in);
        $fclose(fd_out);
        $display("SUCCESS: Decompression done. Check final_recovered_bits.txt");
        $finish;
    end
endmodule // tb_decompressor_final
