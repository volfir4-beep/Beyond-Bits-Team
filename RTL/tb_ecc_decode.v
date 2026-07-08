`timescale 1ns/1ps

// Real-pipeline DECODE stage: reads the bits recovered from the LTSpice
// channel (demod_bits.txt, produced by thresholding V(DEMOD_OUT)), runs
// each 7-bit codeword through the Hamming decoder to detect/correct any
// single-bit errors introduced by channel noise, and writes the recovered
// 4-bit-per-codeword data to decoded_bits.txt. Any corrections made are
// logged to ecc_decode_report.txt.
module tb_ecc_decode;
    reg  [6:0] dec_in;
    wire [3:0] dec_data;
    wire       dec_err_detected, dec_err_corrected;
    wire [2:0] dec_err_pos;
    hamming74_dec DEC (
        .code_in(dec_in),
        .data_out(dec_data),
        .error_detected(dec_err_detected),
        .error_corrected(dec_err_corrected),
        .error_position(dec_err_pos)
    );

    integer fd_in, fd_out, fd_log;
    integer bit_val;
    reg [7999:0] all_bits;
    integer total_bits, n_codewords, i, j;
    reg [6:0] codeword;
    integer error_count;

    initial begin
        fd_in = $fopen("demod_bits.txt", "r");
        if (fd_in == 0) begin
            $display("ERROR: demod_bits.txt not found!");
            $finish;
        end

        total_bits = 0;
        while (!$feof(fd_in)) begin
            if ($fscanf(fd_in, "%1d\n", bit_val) == 1) begin
                all_bits[total_bits] = bit_val[0];
                total_bits = total_bits + 1;
            end
        end
        $fclose(fd_in);

        if (total_bits % 7 != 0) begin
            $display("WARNING: input length (%0d) is not a multiple of 7 -- truncating extra bits", total_bits);
        end
        n_codewords = total_bits / 7;

        fd_out = $fopen("decoded_bits.txt", "w");
        fd_log = $fopen("ecc_decode_report.txt", "w");
        $fwrite(fd_log, "ECC Decode Report -- Hamming(7,4)\n");
        $fwrite(fd_log, "==================================\n");
        $fwrite(fd_log, "Total codewords received: %0d\n\n", n_codewords);

        error_count = 0;
        for (i = 0; i < n_codewords; i = i + 1) begin
            codeword = {all_bits[i*7], all_bits[i*7+1], all_bits[i*7+2], all_bits[i*7+3],
                        all_bits[i*7+4], all_bits[i*7+5], all_bits[i*7+6]};
            dec_in = codeword;
            #1;
            for (j = 3; j >= 0; j = j - 1) $fwrite(fd_out, "%0d\n", dec_data[j]);

            if (dec_err_detected) begin
                error_count = error_count + 1;
                $fwrite(fd_log, "Codeword #%0d: error at bit position %0d -- CORRECTED\n", i, dec_err_pos);
            end
        end
        $fclose(fd_out);

        $fwrite(fd_log, "\nTotal errors detected and corrected: %0d / %0d codewords\n", error_count, n_codewords);
        $fclose(fd_log);

        $display("SUCCESS: Decoded %0d codewords. %0d error(s) corrected. See ecc_decode_report.txt",
                   n_codewords, error_count);
        $finish;
    end
endmodule
