# Beyond Bits End-to-End Pipeline Submission (SOI 2026)

## Prerequisites
* Python 3.x (Dependencies listed in `requirements.txt`)
* HDL Simulator (e.g., Icarus Verilog / ModelSim)
* LTSpice XVII or higher

## How to Run the Pipeline:
1. Install Python dependencies: `pip install -r requirements.txt`
2. Open `Python/beyondbits.ipynb` and execute Step 1 to generate `bits.txt`.
3. Run `RTL/tb_compressor.v` in your HDL simulator to generate `compressed.txt`.
4. Execute the PWL block in the Jupyter notebook to write out `signal.pwl`.
5. Open `LTSpice/Draft1.asc`, run the simulation, and export `V(ch_out)` as `demod_output.txt` (File > Export data as text).
6. Run the final cell block in the notebook to verify successful data recovery.
