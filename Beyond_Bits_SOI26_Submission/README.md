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

## Note on the included files

Every file in `PYTHON/`, `LTSpice/`, and `Results/` is the output of a run we
already completed — they are evidence of what the pipeline produced, not a blank
starting point. Please don't delete or edit these files directly, since they're
what our reported numbers in `Results/RESULTS_SUMMARY.md` and the technical
report are based on. If you'd like to run the pipeline yourself to confirm it
genuinely works rather than taking our word for it, we'd encourage you to copy
the folder to a separate location first and run it there — instructions below.

## How to reproduce it

### 1. Install prerequisites
- **Python 3** with `numpy` (`pip install numpy`)
- **Icarus Verilog** (`iverilog` + `vvp`) — Ubuntu/WSL: `sudo apt install iverilog`; Windows: https://bleyer.org/icarus/ (add to PATH); or use ModelSim/Vivado manually instead for the RTL steps
- **LTSpice** — free, from https://www.analog.com/en/resources/design-tools-and-calculators/ltspice-simulator.html

### 2. Run the notebook
Open `PYTHON/beyondbits_final.ipynb` and run the cells top to bottom, in order,
in one sitting.
- Cells 1–4 run automatically (they call `iverilog`/`vvp` for you) and produce
  `signal.pwl`, which you should copy into the `LTSpice/` folder.
- **Cell 5 is a manual pause**: open `LTSpice/Modulator_with_demod_FIXED.asc`,
  run the simulation, export `V(DEMOD_OUT)` as `demod_output.txt` in the same
  folder as the notebook, then continue.
- Cells 6–9 finish automatically and print `Pipeline Integrity Verified: True`
  if everything worked.

You're welcome to change `TEXT_INPUT` in Cell 1 to any string you like. Note that
this will naturally give different bit counts, compression ratios, and BER/SNR
numbers than the ones in `Results/RESULTS_SUMMARY.md`, since that file reports
figures for the specific input `'hello world'`. That's expected — the goal of
trying a different input is to confirm the pipeline genuinely compresses,
transmits, and reconstructs data correctly, not to reproduce our exact numbers.

### 3. Reproducing the ECC fault-injection proof (optional, already included as evidence)

Open the `PYTHON` folder in a terminal and run:

```
iverilog -o ecc_demo RTL/hamming74_enc.v RTL/hamming74_dec.v RTL/tb_ecc_correction_demo.v
vvp ecc_demo
```
This regenerates `ecc_report.txt` (reproduced here as
`Results/ecc_fault_injection_demo_report.txt`), showing a deliberately flipped bit
being detected and corrected.

## Known limitation, reported honestly (see report Section 3.2)

RLE compression **expands** the "hello world" demo input (88 -> 225 bits, CR = 0.39x)
because that string has almost no repeated bit-runs — RLE's fixed 5-bit-per-run
overhead only pays off on redundant data. We're explaining this in the report
rather than hiding it.

------------------------------------------------------------------------------------------

Thank you for reading.

Team Beast Of Bits,
Himank Jain
Parth Patel
Nagesh Pooniya

------------------------------------------------------------------------------------------
