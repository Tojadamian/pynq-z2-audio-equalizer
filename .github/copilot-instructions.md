# Project Instructions — PYNQ-Z2 3-Band FIR Audio Equalizer

## 1. Strict Working Rules for AI Agents
- **Learning-First Policy:** This is a hands-on FPGA learning repository. **DO NOT** create, modify, or auto-implement VHDL RTL files (`fpga/rtl/*.vhd`), testbenches (`fpga/sim/*.vhd`), constraints (`fpga/constraints/*.xdc`), or MATLAB scripts (`matlab/*.m`) unless the user explicitly asks for a specific edit to those files.
- **Git Restriction:** **NEVER** run `git add`, `git commit`, `git push`, `git reset`, or any other Git state-changing commands. The user manages all Git operations manually.
- **Documentation Honesty:** When creating or updating `README.md` or files in `docs/`, always inspect the actual files currently present in the workspace first. **NEVER** invent Vivado utilization/timing numbers, and clearly distinguish between **implemented** modules and **planned** modules.

## 2. Project Overview & Hardware Target
- **Goal:** Real-time 3-band digital audio equalizer (LPF, BPF, HPF) built from scratch in VHDL.
- **Board:** TUL PYNQ-Z2 (`xc7z020clg400-1`, Zynq-7000).
- **Audio Peripherals:** Digilent PmodMIC (TI ADCS7476 12-bit SPI ADC), Digilent PmodDA2 (TI DAC121S101 12-bit SPI DAC), Digilent PmodAMP2 (headphone amplifier via PmodBB).
- **Toolchain:**
  - DSP design & VHDL package generation: MATLAB (`fir1`, `freqz`)
  - Local VHDL linting & simulation (macOS): VS Code + TerosHDL + `nvc` + VaporView
  - Synthesis, implementation & bitstream: AMD Vivado 2023.2

## 3. Architecture & Technical Specification (Source of Truth)
- **Clocking Strategy:** Single **125 MHz** clock domain (`clk`, pin `H16`) using 1-cycle clock enable strobes (`en_24kHz` for audio sampling, ~2.083 MHz SPI timing, ~2 Hz LED blink). No logic-divided secondary clocks.
- **Reset Convention:** Synchronous **active-high** `reset` (`BTN0`, pin `D19`). Default equalizer band state after reset: all bands ON (`"111"`).
- **DSP Filter Parameters:**
  - Sampling rate: `Fs = 24000 Hz` (Nyquist = `12000 Hz`)
  - Crossover frequencies: `fc1 = 650 Hz` (LPF/BPF), `fc2 = 3000 Hz` (BPF/HPF)
  - Bands: LPF (`0–650 Hz`), BPF (`650–3000 Hz`), HPF (`3000–12000 Hz`)
  - Filter design: 3 parallel linear-phase FIR filters, Hamming window with `'noscale'` so `LPF + BPF + HPF` sums flat to `0 dB`
  - Length / Order: `N = 141` taps (`M = 140`), identical group delay (`70` samples) across all 3 bands
  - Coefficient quantization: `Q = 12` fractional scaling bits (`2^12 = 4096`), integer range `[-921, +3072]`
- **Fixed-Point Data Path Widths:**
  - `DATA_WIDTH = 12` (12-bit unsigned offset-binary at ADC/DAC with mid-scale silence `0x800`; converted to 12-bit signed two's complement via MSB inversion inside DSP)
  - `COEF_WIDTH = 13` (signed U2)
  - `PROD_WIDTH = 25` (`12 + 13`)
  - `SUM_WIDTH = 33` (`25 + ceil(log2(141)) = 25 + 8` guard bits, zero overflow)
- **FIR Architecture:** Modular, parameterized **Systolic Array** (`mac_cell.vhd` with `z^-2` data pipeline and `z^-1` sum pipeline + `fir_filter.vhd` instantiated via `for ... generate` with generic `COEFFS` from `eq_coeffs_pkg.vhd`).
- **Planned Board Controls (PYNQ-Z2):**
  - `SW0`: Audio master ON/OFF (muted to mid-scale `0x800` when OFF)
  - `SW1`: Mode select (`0` = Bypass, `1` = 3-Band Equalizer)
  - `BTN0`: Synchronous active-high reset (resets bands to `"111"`)
  - `BTN1` / `BTN2` / `BTN3`: Debounced toggle buttons for LPF / BPF / HPF
  - `LD0`: Audio status (OFF when muted, solid ON in Bypass, blinking ~2 Hz in Equalizer mode)
  - `LD1` / `LD2` / `LD3`: Active band indicators for LPF / BPF / HPF (OFF in Bypass or Mute)

## 4. Repository Structure & Roadmap
- `matlab/` — MATLAB filter design & automated VHDL coefficient package export
- `fpga/rtl/` — Synthesizable VHDL source files
- `fpga/sim/` — VHDL simulation testbenches
- `fpga/constraints/` — PYNQ-Z2 `.xdc` pin & timing constraints
- `docs/` — Frequency response plots, block diagrams, and simulation captures

### Implementation Status
- [x] Stage 1: Architecture, hardware UI spec, repo layout & `.gitignore`
- [x] Stage 2: MATLAB 3-band FIR design (`design_eq_filters.m`) & auto-generated `eq_coeffs_pkg.vhd`
- [x] Stage 3: Parameterized Systolic Array FIR (`mac_cell.vhd`, `fir_filter.vhd`), verified with `nvc`
- [ ] Stage 4: 3-band equalizer core (`audio_equalizer.vhd`: 3× FIR, mixing, scaling, saturation) & simulation
- [ ] Stage 5: Single-domain 125 MHz peripherals (`timing_gen`, `btn_controller`, SPI ADC/DAC controllers)
- [ ] Stage 6: Top-level integration (`top_audio_eq.vhd`), PYNQ-Z2 `.xdc`, Vivado build & hardware verification
