# Beyond Bits — SOI 2026 (Electronics Club, IIT Dharwad)

An end-to-end mixed-signal communication pipeline: text -> RTL RLE compression ->
RTL Hamming(7,4) error-correction encoding -> LTSpice ASK modulation over a
noisy channel -> LTSpice envelope-detector demodulation -> RTL Hamming decoding
(detects + corrects channel-noise bit flips) -> RTL decompression -> recovered text.

**Pipeline Enhancement implemented: #3 — channel noise + RTL-based error
detection/correction (Hamming(7,4)).**

**Status: fully run end-to-end. Verified output:**
```
Expected Input:  'hello world'
Recovered Text:  'hello world'
Pipeline Integrity Verified: True
```
All raw run artifacts (not just the print statement) are included under `PYTHON/`,
`LTSpice/`, and `Results/` as evidence — see `Results/RESULTS_SUMMARY.md` for an
indexed summary of which file backs which claim.

## Folder structure

```
Documentation/   Beyond_Bits_Technical_Report.pdf   (full write-up: architecture,
                 compression analysis, ECC design + fault-injection proof, BER/SNR)
LTSpice/         Modulator_with_demod_FIXED.asc      modulator + noise + demodulator
                 .raw / .log / .net                  actual LTSpice simulation output
                 signal.pwl                           the PWL waveform that was fed in
PYTHON/          beyondbits_final.ipynb              drives the whole pipeline
                 bits.txt ... final_recovered_bits.txt  every intermediate file from
                                                       the verified run (see table below)
RTL/             all Verilog source + testbenches (see below)
Results/         RESULTS_SUMMARY.md                  index: claim -> evidence file
                 ecc_fault_injection_demo_report.txt  deliberate bit-flip -> correction proof
```

## RTL files

| File | Role |
|---|---|
| `rle_compressor.v` | Run-length compresses the input bitstream |
| `decompressor.v` | Re-inflates a run-length compressed bitstream |
| `hamming74_enc.v` | Encodes 4 data bits -> 7-bit Hamming codeword |
| `hamming74_dec.v` | Decodes a 7-bit codeword, corrects a single-bit error if present |
| `tb_compressor_fixed.v` | Testbench for `rle_compressor.v` (bits.txt -> compressed.txt) |
| `tb_ecc_encode.v` | Testbench: pads + Hamming-encodes compressed.txt -> encoded_clean.txt |
| `tb_ecc_decode.v` | Testbench: Hamming-decodes the channel-recovered bits, corrects errors, logs a report |
| `tb_decompressor_final.v` | Testbench: final decompression stage (post-ECC-decode -> original bits) |
| `tb_decompressor_standalone_demo.v` | Optional: proves the decompressor works in isolation, RTL-only, no channel |
| `tb_ecc_correction_demo.v` | Deliberately injects one bit error and proves Hamming correction — evidence in `Results/ecc_fault_injection_demo_report.txt` |

## PYTHON/ intermediate files (evidence of the verified run)

| File | Produced by | Contents |
|---|---|---|
| `bits.txt` | notebook Step 1 | 88-bit binary of "hello world" |
| `compressed.txt` | RTL compressor | 225 bits (45 RLE runs) |
| `ecc_encode_input.txt`, `ecc_pad.txt` | notebook Step 3 | padded-to-228-bits input + pad count |
| `encoded_clean.txt` | RTL Hamming encoder | 399 bits (57 codewords) — this is what was modulated |
| `signal.pwl` | notebook Step 4 | PWL waveform fed into LTSpice |
| `demod_output.txt` | **LTSpice** (exported) | analog demodulated waveform, 399 us |
| `demod_bits.txt` | notebook Step 6 | 399 bits thresholded back from the analog waveform |
| `ecc_decode_report.txt`, `decoded_bits.txt` | RTL Hamming decoder | 57/57 codewords, 0 corrections needed this run |
| `final_compressed_recovered.txt`, `final_recovered_bits.txt` | notebook Step 8 + RTL decompressor | 225 -> 88 bits |
| `tx_bit_count.txt` | notebook Step 4 | 399 (actual transmitted bit count) |

## How to reproduce it

### 1. Install prerequisites
- **Python 3** with `numpy` (`pip install numpy`)
- **Icarus Verilog** (`iverilog` + `vvp`) — Ubuntu/WSL: `sudo apt install iverilog`; Windows: https://bleyer.org/icarus/ (add to PATH); or use ModelSim/Vivado manually instead for the RTL steps
- **LTSpice** — free, from https://www.analog.com/en/resources/design-tools-and-calculators/ltspice-simulator.html

### 2. Run the notebook
Open `PYTHON/beyondbits_final.ipynb` and run cells top to bottom, in order, in one sitting.
- Cells 1–4 run automatically (they call `iverilog`/`vvp` for you) and produce `signal.pwl` and copy this into the `LTSpice` Folder.
- **Cell 5 is a manual pause**: open `LTSpice/Modulator_with_demod_FIXED.asc`, run the simulation,
  export `V(DEMOD_OUT)` as `demod_output.txt` in the same folder as the notebook, then continue.
- Cells 6–9 finish automatically and print `Pipeline Integrity Verified: True` if everything worked.

### 3. Reproducing the ECC fault-injection proof (optional, already included as evidence)

- Open the `PYTHON` Folder in Terminal and paste the following Commands.

```
iverilog -o ecc_demo RTL/hamming74_enc.v RTL/hamming74_dec.v RTL/tb_ecc_correction_demo.v
vvp ecc_demo
```
This regenerates `ecc_report.txt` (reproduced here as `Results/ecc_fault_injection_demo_report.txt`),
showing a deliberately flipped bit being detected and corrected.

## Known limitation, reported honestly (see report Section 3.2)

RLE compression **expands** the "hello world" demo input (88 -> 225 bits, CR = 0.39x)
because that string has almost no repeated bit-runs — RLE's fixed 5-bit-per-run
overhead only pays off on redundant data. This is explained in the report rather
than hidden; a good, quick strengthening step (not required) is to re-run the
notebook once more with a more repetitive `TEXT_INPUT` (e.g. a string with long
repeated-character runs) to also show a case where CR > 1.

<!-- ## What was fixed since the original submission
- Testbench race condition (inputs now driven on `negedge`, not racing the DUT's `posedge`)
- `decompressor.v` was unused — now has two real testbenches (standalone RTL proof + final pipeline stage)
- Notebook: undefined `V_HIGH`, `generate_pwl()` never called, mismatched bit timing (50us vs 1us), final check hardcoded `'HELLO WORLD'` instead of comparing to the real input, and decompression was skipped before the final text conversion — all fixed
- Missing demodulator circuit (`Draft1.asc` was referenced but absent) — rebuilt as an envelope detector (1N4148 diode + 1k/470pF RC filter) in `Modulator_with_demod_FIXED.asc`
- Hardcoded Windows file path — now relative
- Added Hamming(7,4) RTL error-correction coding (Pipeline Enhancement #3), with a
  demonstrated single-bit-error injection and correction, verified end-to-end
- **Technical Report rewritten**: added the missing Hamming(7,4) ECC section, the
  mandatory BER/SNR analysis section, corrected the input-text mismatch
  ("HELLO WORLD" -> "hello world"), and replaced unsupported claims ("highly
  effective... excellent optimization coefficients") with the actual measured
  compression ratio and an honest discussion of when RLE helps vs. hurts
- Full pipeline run end-to-end with real LTSpice simulation; every intermediate
  file included as evidence instead of only a screenshot/printout -->
