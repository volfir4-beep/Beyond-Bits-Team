# Results Summary -- quick reference for reviewers

Full detail and discussion is in `Documentation/Beyond_Bits_Technical_Report.pdf`.
This file just indexes where the raw evidence for each claim lives.

## End-to-end run (input: "hello world")

| Stage | File | Result |
|---|---|---|
| Source text -> bits | `PYTHON/bits.txt` | 88 bits |
| RLE compression | `PYTHON/compressed.txt` | 225 bits (45 runs) -- CR = 88/225 = 0.39x (see report S3.2 for why) |
| Pad + Hamming(7,4) encode | `PYTHON/ecc_encode_input.txt`, `PYTHON/encoded_clean.txt` | 228 -> 399 bits (57 codewords) |
| PWL waveform | `PYTHON/signal.pwl`, `LTSpice/signal.pwl` | 399 us burst |
| LTSpice ASK modulation + noise (NOISE_AMP=0.3) + demod | `LTSpice/Modulator_with_demod_FIXED.asc`, `.raw`, `.log`, `.net` | see waveform |
| Exported demod waveform | `PYTHON/demod_output.txt` | analog trace |
| Thresholded back to bits | `PYTHON/demod_bits.txt` | 399 bits, 0 errors vs `encoded_clean.txt` |
| RTL Hamming(7,4) decode | `PYTHON/ecc_decode_report.txt`, `PYTHON/decoded_bits.txt` | 0/57 codewords needed correction this run |
| Trim padding + RTL decompression | `PYTHON/final_compressed_recovered.txt`, `PYTHON/final_recovered_bits.txt` | 88 bits |
| Final text | (notebook Step 9 printout) | `'hello world' == 'hello world'` -> **Pipeline Integrity Verified: True** |

## ECC correction proof (deliberate fault injection)

File: `Results/ecc_fault_injection_demo_report.txt` (produced by `RTL/tb_ecc_correction_demo.v`)

A bit was deliberately flipped in codeword #28 of 57. The Hamming(7,4) decoder detected
the error at bit position 3 and corrected it, recovering the exact original 4-bit nibble
(`0101`). This is the evidence that the ECC *works*, independent of the fact that the
real channel run above happened to introduce zero natural errors.

## BER / SNR (computed from `PYTHON/demod_output.txt` + `PYTHON/demod_bits.txt`)

- Logic-1 cluster: mean 0.366 V, sigma 0.056 V
- Logic-0 cluster: mean 0.007 V, sigma 0.009 V
- Adaptive threshold used: 0.241 V
- Estimated SNR: ~14.9 dB
- BER this run: 0 / 399 bits

Full derivation and discussion: `Documentation/Beyond_Bits_Technical_Report.pdf`, Section 6.
