`timescale 1ns/1ps

// Real-pipeline ENCODE stage: reads a bitstream that Python has already
// padded to a multiple of 4 (see notebook step "prepare_and_encode_ecc"),
// encodes every 4-bit group with Hamming(7,4), and writes the result to
// encoded_clean.txt -- this is what actually gets converted to signal.pwl
// and sent through the LTSpice channel.
module tb_ecc_encode;
    reg  [3:0] enc_in;
    wire [6:0] enc_out;
    hamming74_enc ENC (.data_in(enc_in), .code_out(enc_out));

    integer fd_in, fd_out;
    integer bit_val;
    reg [7999:0] all_bits;
    integer total_bits, n_nibbles, i, j;

    initial begin
        fd_in = $fopen("ecc_encode_input.txt", "r");
        if (fd_in == 0) begin
            $display("ERROR: ecc_encode_input.txt not found!");
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

        if (total_bits % 4 != 0) begin
            $display("ERROR: input length (%0d) is not a multiple of 4 -- pad it in Python first!", total_bits);
            $finish;
        end
        n_nibbles = total_bits / 4;

        fd_out = $fopen("encoded_clean.txt", "w");
        for (i = 0; i < n_nibbles; i = i + 1) begin
            enc_in = {all_bits[i*4], all_bits[i*4+1], all_bits[i*4+2], all_bits[i*4+3]};
            #1;
            for (j = 6; j >= 0; j = j - 1) $fwrite(fd_out, "%0d\n", enc_out[j]);
        end
        $fclose(fd_out);

        $display("SUCCESS: Encoded %0d nibbles (%0d bits) -> %0d codeword bits in encoded_clean.txt",
                   n_nibbles, total_bits, n_nibbles*7);
        $finish;
    end
endmodule
