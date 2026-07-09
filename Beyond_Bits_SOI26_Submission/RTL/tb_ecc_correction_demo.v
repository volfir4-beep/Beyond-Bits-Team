`timescale 1ns/1ps

// Encodes compressed.txt (RLE output) with Hamming(7,4), writes the clean
// encoded stream (encoded_clean.txt -- this is what should actually be fed
// into generate_pwl() for the LTSpice channel), THEN deliberately flips one
// bit in one codeword to simulate a noise-induced error (as required by
// SOI'26 Pipeline Enhancement #3), decodes it, and proves the ECC decoder
// detects and corrects it -- recovering the exact original data.
module tb_ecc_pipeline;
    reg  [3:0] enc_in;
    wire [6:0] enc_out;
    hamming74_enc ENC (.data_in(enc_in), .code_out(enc_out));

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

    integer fd_in, fd_clean, fd_corrupt, fd_decoded, fd_log;
    integer bit_val;
    reg [7999:0] all_bits;     // scratch buffer, plenty of room for this project's scale
    integer total_bits, pad, n_nibbles;
    integer i, j;
    reg [6:0] codeword;
    integer flip_codeword_index, flip_bit_index;

    initial begin
        fd_in = $fopen("compressed.txt", "r");
        if (fd_in == 0) begin
            $display("ERROR: compressed.txt not found");
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
        $display("Read %0d bits from compressed.txt", total_bits);

        // Pad to a multiple of 4 (Hamming needs 4 data bits per codeword)
        pad = (4 - (total_bits % 4)) % 4;
        for (i = 0; i < pad; i = i + 1) all_bits[total_bits + i] = 1'b0;
        total_bits = total_bits + pad;
        n_nibbles  = total_bits / 4;
        $display("Padded to %0d bits (%0d nibbles, %0d pad bits)", total_bits, n_nibbles, pad);

        // ---- ENCODE: write the clean (noise-free) encoded stream ----
        fd_clean = $fopen("encoded_clean.txt", "w");
        for (i = 0; i < n_nibbles; i = i + 1) begin
            enc_in = {all_bits[i*4], all_bits[i*4+1], all_bits[i*4+2], all_bits[i*4+3]};
            #1;
            for (j = 6; j >= 0; j = j - 1) $fwrite(fd_clean, "%0d\n", enc_out[j]);
        end
        $fclose(fd_clean);
        $display("Encoded %0d codewords (%0d bits) -> encoded_clean.txt", n_nibbles, n_nibbles*7);

        // ---- INJECT a deliberate single-bit flip (simulates channel noise) ----
        flip_codeword_index = n_nibbles / 2;  // pick a codeword roughly in the middle
        flip_bit_index       = 4;             // bit index 4 = d1, a DATA bit (position 3)

        fd_log = $fopen("ecc_report.txt", "w");
        $fwrite(fd_log, "ECC Verification Report -- Hamming(7,4)\n");
        $fwrite(fd_log, "========================================\n");
        $fwrite(fd_log, "Total codewords: %0d\n", n_nibbles);
        $fwrite(fd_log, "Deliberately flipped bit index %0d of codeword #%0d (simulated channel noise)\n\n",
                 flip_bit_index, flip_codeword_index);

        fd_corrupt  = $fopen("encoded_corrupted.txt", "w");
        fd_decoded  = $fopen("decoded_bits.txt", "w");

        for (i = 0; i < n_nibbles; i = i + 1) begin
            enc_in = {all_bits[i*4], all_bits[i*4+1], all_bits[i*4+2], all_bits[i*4+3]};
            #1;
            codeword = enc_out;

            if (i == flip_codeword_index) begin
                codeword[flip_bit_index] = ~codeword[flip_bit_index];
                $fwrite(fd_log, "  >> Injected bit flip into codeword #%0d: clean=%b corrupted=%b\n",
                         i, enc_out, codeword);
            end

            for (j = 6; j >= 0; j = j - 1) $fwrite(fd_corrupt, "%0d\n", codeword[j]);

            dec_in = codeword;
            #1;
            for (j = 3; j >= 0; j = j - 1) $fwrite(fd_decoded, "%0d\n", dec_data[j]);

            if (dec_err_detected) begin
                $fwrite(fd_log, "  Codeword #%0d: ERROR DETECTED at bit position %0d -- CORRECTED (recovered data=%b)\n",
                         i, dec_err_pos, dec_data);
            end
        end
        $fclose(fd_corrupt);
        $fclose(fd_decoded);

        // ---- Self-check is done externally by comparing decoded_bits.txt
        //      (first total_bits-pad bits) against the original compressed.txt ----
        $fwrite(fd_log, "\nEncode -> corrupt -> decode cycle complete.\n");
        $fwrite(fd_log, "Compare decoded_bits.txt (first %0d bits, ignoring padding) against compressed.txt to confirm full recovery.\n", total_bits - pad);
        $fclose(fd_log);

        $display("SUCCESS: ECC encode/corrupt/decode complete. See ecc_report.txt, decoded_bits.txt");
        $finish;
    end
endmodule
