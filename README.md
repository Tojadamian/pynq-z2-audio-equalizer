# PYNQ-Z2 3-Band FIR Audio Equalizer

A learning-focused FPGA audio equalizer project targeting the TUL PYNQ-Z2. The design is planned as a real-time, three-band low-pass, band-pass, and high-pass equalizer, implemented in VHDL with fixed-point FIR filters.

The repository currently contains the MATLAB coefficient-generation script and the VHDL coefficient package and systolic FIR datapath. The complete equalizer, audio peripherals, board-level integration, and hardware verification are still planned.

## Project Overview

The target system samples audio at 24 kHz, filters it through three parallel linear-phase FIR bands, and recombines the bands. The filter coefficients are designed in MATLAB and exported as a VHDL package. The current RTL provides a parameterized systolic FIR chain; it does not yet include the three-band equalizer core or audio I/O.

## Hardware Platform & Controls

| Item | Specification |
| --- | --- |
| FPGA board | TUL PYNQ-Z2 |
| FPGA device | AMD/Xilinx Zynq-7000, `xc7z020clg400-1` |
| Planned system clock | 125 MHz, single clock domain |
| Microphone / ADC | Digilent PmodMIC, TI ADCS7476 12-bit SPI ADC |
| DAC | Digilent PmodDA2, TI DAC121S101 12-bit SPI DAC |
| Headphone amplifier | Digilent PmodAMP2 via PmodBB |

The controls below describe the intended board interface. They are **planned**; no top-level design or board constraints currently implement them.

| Control | Planned function |
| --- | --- |
| `SW0` | Audio master enable; output is muted to mid-scale (`0x800`) when off |
| `SW1` | Mode select: bypass (`0`) or three-band equalizer (`1`) |
| `BTN0` | Synchronous active-high reset; reset band state is all on (`111`) |
| `BTN1` / `BTN2` / `BTN3` | Debounced LPF / BPF / HPF toggle buttons |
| `LD0` | Audio status: off when muted, solid in bypass, blinking in equalizer mode |
| `LD1` / `LD2` / `LD3` | LPF / BPF / HPF active indicators |

## DSP Filter Specifications

| Parameter | Value |
| --- | --- |
| Sampling rate (`Fs`) | 24,000 Hz |
| Nyquist frequency | 12,000 Hz |
| LPF / BPF crossover (`fc1`) | 650 Hz |
| BPF / HPF crossover (`fc2`) | 3,000 Hz |
| Bands | LPF: 0–650 Hz; BPF: 650–3,000 Hz; HPF: 3,000–12,000 Hz |
| FIR length | `N = 141` taps (`M = 140` order) |
| Window and scaling | Hamming window; MATLAB `fir1` with `'noscale'` |
| Coefficient quantization | `Q = 12` fractional bits; scale factor `2^12 = 4096` |
| Coefficient integer range | −921 to +3072 in the generated package |
| Data width | `DATA_WIDTH = 12` bits, signed within the FIR datapath |
| Coefficient width | `COEF_WIDTH = 13` bits, signed |
| Product width | `PROD_WIDTH = 25` bits (`12 + 13`) |
| Accumulator width | `SUM_WIDTH = 33` bits (`25 + 8` guard bits) |
| Group delay | 70 samples for each linear-phase filter |

The three filters are designed so their floating-point responses sum to approximately 0 dB. The MATLAB script also plots the floating-point and quantized responses for visual inspection.

## Systolic Array FIR Architecture

`fir_filter` builds a parameterized chain of 141 `mac_cell` instances using a VHDL `for ... generate` loop. Each cell multiplies its input sample by a coefficient, adds the product to the incoming sum, and passes delayed sample data to the next cell. The cell registers two data-delay stages and one sum stage, with synchronous active-high reset and clock enable. Coefficients are supplied through the `COEFFS` generic, defaulting to `COEF_LPF` from the generated `eq_coeffs_pkg` package.

The FIR output is a 33-bit signed accumulated result. Scaling, saturation, band mixing, and ADC/DAC offset-binary conversion belong to the planned equalizer integration and are not implemented in the current RTL.

## Repository Structure

```text
.
├── .github/
│   └── copilot-instructions.md
├── docs/                         # Present but currently empty
├── fpga/
│   └── rtl/
│       ├── eq_coeffs_pkg.vhd    # Generated coefficient package
│       ├── fir_filter.vhd       # Parameterized FIR chain
│       └── mac_cell.vhd         # FIR multiply-accumulate cell
├── matlab/
│   ├── design_eq_filters.m      # Filter design, plots, and VHDL export
│   └── design_eq_filters.asv    # MATLAB autosave file
└── README.md
```

## How to Run

### Generate the coefficient package with MATLAB

Run this from the repository root. The script requires MATLAB functions `fir1` and `freqz` (Signal Processing Toolbox) and writes the generated package to `fpga/rtl/eq_coeffs_pkg.vhd`.

```sh
matlab -batch "cd('matlab'); run('design_eq_filters.m')"
```

### Analyze the VHDL with NVC

Run from the repository root. Analyze the package before the modules that depend on it:

```sh
nvc --std=2008 -a \
  fpga/rtl/eq_coeffs_pkg.vhd \
  fpga/rtl/mac_cell.vhd \
  fpga/rtl/fir_filter.vhd
```

This compiles the currently present RTL; the repository does not yet contain a simulation testbench or a complete top-level design to run.

## Roadmap / Implementation Status

- [x] MATLAB design script for three 141-tap FIR bands and VHDL coefficient export.
- [x] Generated coefficient package with LPF, BPF, and HPF coefficient arrays.
- [x] Parameterized systolic FIR RTL (`mac_cell` and `fir_filter`); project notes record NVC verification.
- [ ] Three-band equalizer core: instantiate the three filters, mix enabled bands, scale, and saturate.
- [ ] Single-clock timing and peripheral controllers: sample-rate enable, button debounce, SPI ADC, and SPI DAC.
- [ ] Top-level board integration, PYNQ-Z2 constraints, and Vivado build.
- [ ] End-to-end simulation and hardware verification.