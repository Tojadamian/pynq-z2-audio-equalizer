## ============================================================================
## TUL PYNQ-Z2 (xc7z020clg400-1) — 3-Band Audio Equalizer Constraints
## ============================================================================

## System Clock: 125 MHz (single clock domain)
set_property -dict { PACKAGE_PIN H16   IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }];

## Slide Switches (SW0 = Audio Enable, SW1 = Bypass / Equalizer)
set_property -dict { PACKAGE_PIN M20   IOSTANDARD LVCMOS33 } [get_ports { sw_audio }];
set_property -dict { PACKAGE_PIN M19   IOSTANDARD LVCMOS33 } [get_ports { sw_eq }];

## Push Buttons (BTN0 = Reset, BTN1..BTN3 = LPF / BPF / HPF Toggle)
set_property -dict { PACKAGE_PIN D19   IOSTANDARD LVCMOS33 } [get_ports { reset }];
set_property -dict { PACKAGE_PIN D20   IOSTANDARD LVCMOS33 } [get_ports { btn_lpf }];
set_property -dict { PACKAGE_PIN L20   IOSTANDARD LVCMOS33 } [get_ports { btn_bpf }];
set_property -dict { PACKAGE_PIN L19   IOSTANDARD LVCMOS33 } [get_ports { btn_hpf }];

## Onboard LEDs (LD0 = Status/Blink, LD1..LD3 = Active EQ Bands)
set_property -dict { PACKAGE_PIN R14   IOSTANDARD LVCMOS33 } [get_ports { led_audio }];
set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { led_lpf }];
set_property -dict { PACKAGE_PIN N16   IOSTANDARD LVCMOS33 } [get_ports { led_bpf }];
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { led_hpf }];

## PmodA (top row — Digilent PmodMIC / ADCS7476)
set_property -dict { PACKAGE_PIN Y18   IOSTANDARD LVCMOS33 } [get_ports { adc_cs }];
set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33 } [get_ports { spi_miso_adc }];
set_property -dict { PACKAGE_PIN Y17   IOSTANDARD LVCMOS33 } [get_ports { spi_sck_adc }];

## PmodB (top row — Digilent PmodDA2 / DAC121S101)
set_property -dict { PACKAGE_PIN W14   IOSTANDARD LVCMOS33 } [get_ports { dac_cs }];
set_property -dict { PACKAGE_PIN Y14   IOSTANDARD LVCMOS33 } [get_ports { spi_mosi_dac_A }];
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { spi_sck_dac }];
