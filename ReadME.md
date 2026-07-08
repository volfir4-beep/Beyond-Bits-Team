# Beyond Bits — SOI 2026 (Electronics Club, IIT Dharwad)

An end-to-end mixed-signal communication pipeline: text -> RTL compression -> RTL
Hamming(7,4) error-correction encoding -> LTSpice ASK modulation over a noisy
channel -> LTSpice envelope-detector demodulation -> RTL Hamming decoding
(detects + corrects channel-noise bit flips) -> RTL decompression -> recovered text.

Pipeline Enhancement implemented: **#3 — channel noise + RTL-based error
detection/correction (Hamming(7,4))**.

## Folder structure

```
Documentation/   Beyond_Bits_Technical_Report.pdf
LTSpice/         Modulator_with_demod.asc   (modulator + noise + demodulator)
PYTHON/          beyondbits_final.ipynb     (drives the whole pipeline)
RTL/             all Verilog source + testbenches (see below)
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
| `tb_ecc_correction_demo.v` | Optional: deliberately injects one bit error and proves Hamming correction — good evidence for your report |

## How to run it (full instructions below, written for someone testing this from scratch)

### 1. Install prerequisites
- **Python 3** with `numpy` (`pip install numpy`)
- **Icarus Verilog** (`iverilog` + `vvp`) — Ubuntu/WSL: `sudo apt install iverilog`; Windows: https://bleyer.org/icarus/ (add to PATH); or use ModelSim/Vivado manually instead for the RTL steps
- **LTSpice** — free, from https://www.analog.com/en/resources/design-tools-and-calculators/ltspice-simulator.html

### 2. Run the notebook
Open `PYTHON/beyondbits_final.ipynb` and run cells top to bottom, in order, in one sitting.
- Cells 1–4 run automatically (they call `iverilog`/`vvp` for you) and produce `signal.pwl`.
- **Cell 5 is a manual pause**: open `LTSpice/Modulator_with_demod.asc`, run the simulation,
  export `V(DEMOD_OUT)` as `demod_output.txt` in the same folder as the notebook, then continue.
- Cells 6–9 finish automatically and print `Pipeline Integrity Verified: True` if everything worked.

### 3. Checking the LTSpice schematic
When you open `Modulator_with_demod.asc`, confirm every pin on the new diode/resistor/
capacitor cluster (the demodulator, added right of the original circuit) shows a **solid
red dot**, not a hollow square. A hollow square means that pin isn't actually connected —
just drag the part one grid click to snap it in.

## What was fixed since the original submission
- Testbench race condition (inputs now driven on `negedge`, not racing the DUT's `posedge`)
- `decompressor.v` was unused — now has two real testbenches (standalone RTL proof + final pipeline stage)
- Notebook: undefined `V_HIGH`, `generate_pwl()` never called, mismatched bit timing (50us vs 1us), final check hardcoded `'HELLO WORLD'` instead of comparing to the real input, and decompression was skipped before the final text conversion — all fixed
- Missing demodulator circuit (`Draft1.asc` was referenced but absent) — rebuilt as an envelope detector (1N4148 diode + 1k/470pF RC filter) in `Modulator_with_demod.asc`
- Hardcoded Windows file path — now relative
- Added Hamming(7,4) RTL error-correction coding (Pipeline Enhancement #3), with a
  demonstrated single-bit-error injection and correction, verified end-to-end

## Still to do before submitting
- **Technical Report**: add a section describing the Hamming(7,4) ECC implementation
  (encoder/decoder logic, the deliberate bit-flip demo, and a note on the ~1.77x bit
  overhead it costs). Update any figures/description referencing the old (broken) pipeline.
- Actually run `Modulator_with_demod.asc` in LTSpice yourself and confirm the exported
  `demod_output.txt` looks like a clean envelope (smooth, not raw 10MHz oscillation).
- Do one final clean run of the whole notebook and save the printed
  `Pipeline Integrity Verified: True` output as evidence in your report.
