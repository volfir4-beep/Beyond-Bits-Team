// hamming74_dec.v
// Hamming(7,4) decoder: takes a (possibly corrupted) 7-bit codeword,
// computes a 3-bit "syndrome" from the parity checks, and if a single
// bit was flipped, the syndrome directly gives its position (1-7) so
// it can be corrected before the original 4 data bits are extracted.
module hamming74_dec (
    input  [6:0] code_in,
    output reg [3:0] data_out,
    output reg        error_detected,
    output reg        error_corrected,
    output reg [2:0]  error_position   // 0 = no error, 1-7 = corrected bit position
);
    reg [6:0] fixed;
    reg s1, s2, s3;
    reg [2:0] syndrome;

    always @(*) begin
        fixed = code_in;

        // Recompute each parity check; a mismatch (1) means that
        // group of bits doesn't add up anymore.
        s1 = code_in[6] ^ code_in[4] ^ code_in[2] ^ code_in[0]; // p1,d1,d2,d4 -> positions 1,3,5,7
        s2 = code_in[5] ^ code_in[4] ^ code_in[1] ^ code_in[0]; // p2,d1,d3,d4 -> positions 2,3,6,7
        s3 = code_in[3] ^ code_in[2] ^ code_in[1] ^ code_in[0]; // p3,d2,d3,d4 -> positions 4,5,6,7

        syndrome = {s3, s2, s1};   // value 0-7 = which position (if any) is wrong
        error_position = syndrome;

        if (syndrome != 3'b000) begin
            error_detected  = 1'b1;
            error_corrected = 1'b1;
            fixed[7 - syndrome] = ~code_in[7 - syndrome];  // flip the faulty bit back
        end else begin
            error_detected  = 1'b0;
            error_corrected = 1'b0;
        end

        // Extract the 4 data bits (positions 3,5,6,7 = code indices 4,2,1,0) from the fixed codeword
        data_out = {fixed[4], fixed[2], fixed[1], fixed[0]};
    end
endmodule
