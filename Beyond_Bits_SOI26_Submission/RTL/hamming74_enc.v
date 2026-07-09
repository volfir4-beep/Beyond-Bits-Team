// hamming74_enc.v
// Hamming(7,4) encoder: takes 4 data bits, outputs a 7-bit codeword
// with 3 parity bits added so a single-bit error can be corrected at
// the receiver. This is the RTL-based error-correction coding required
// for SOI'26 Pipeline Enhancement #3.
//
// Bit layout of the 7-bit codeword (standard Hamming positions 1-7):
//   position: 1  2  3  4  5  6  7
//   content:  p1 p2 d1 p3 d2 d3 d4
//   code_out index: 6  5  4  3  2  1  0
module hamming74_enc (
    input  [3:0] data_in,   // {d1, d2, d3, d4}, d1 = MSB
    output [6:0] code_out
);
    wire d1 = data_in[3];
    wire d2 = data_in[2];
    wire d3 = data_in[1];
    wire d4 = data_in[0];

    // Each parity bit covers a fixed set of data bits (standard Hamming rule)
    wire p1 = d1 ^ d2 ^ d4;   // covers positions 1,3,5,7
    wire p2 = d1 ^ d3 ^ d4;   // covers positions 2,3,6,7
    wire p3 = d2 ^ d3 ^ d4;   // covers positions 4,5,6,7

    assign code_out = {p1, p2, d1, p3, d2, d3, d4};
endmodule
