clear; clc; close all;

% Define constants of the filters project
Fs = 24000;               % sample frequency 
N = 141;                  % number of filter taps (coefficients)
M = N-1;                  % filter order
fc1 = 650;                % LPF / BPF crossover frequency (Hz)
fc2 = 3000;               % BPF / HPF crossover frequency (Hz)
Q = 12;                   % number of scaling bits
Nfft = 2048;              % FFT length (number of frequency points)

% Design normalized (wFcx) cutoff frequencies
wFc1 = fc1 / (Fs / 2);
wFc2 = fc2 / (Fs / 2);

% Design low-pass and band-pass and high-pass FIR filters using noscale
lowPassCoefficients = fir1(M, wFc1, 'low', 'noscale');
bandPassCoefficients = fir1(M, [wFc1 wFc2], 'bandpass', 'noscale');
highPassCoefficients = fir1(M, wFc2, 'high', 'noscale');

sumCoefficients = lowPassCoefficients + bandPassCoefficients + highPassCoefficients;

% Graphic verification 
[H_sum, f] = freqz(sumCoefficients, 1, Nfft, Fs);
[H_low, ~] = freqz(lowPassCoefficients, 1, Nfft, Fs);
[H_band, ~] = freqz(bandPassCoefficients, 1, Nfft, Fs);
[H_high, ~] = freqz(highPassCoefficients, 1, Nfft, Fs);

figure;
plot(f, 20 * log10(abs(H_high) + eps));
hold on;
plot(f, 20 * log10(abs(H_band) + eps));
plot(f, 20 * log10(abs(H_low) + eps));
plot(f, 20 * log10(abs(H_sum) + eps));
title('Ideal Floating-Point Filters')
legend('High-pass', 'Band-pass', 'Low-pass', 'Sum');
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
ylim([-80 5]);
grid on;

% Quantize coefficients to signed Q-format integers
lowPassQuant = round(lowPassCoefficients * 2^Q);
bandPassQuant = round(bandPassCoefficients * 2^Q);
highPassQuant = round(highPassCoefficients * 2^Q);
sumQuant = lowPassQuant + bandPassQuant + highPassQuant;

% Graphic verification
[HqSum, fq] = freqz(sumQuant / 2^Q, 1, Nfft, Fs);
[HqLow, ~] = freqz(lowPassQuant / 2^Q, 1, Nfft, Fs);
[HqBand, ~] = freqz(bandPassQuant / 2^Q, 1, Nfft, Fs);
[HqHigh, ~] = freqz(highPassQuant / 2^Q, 1, Nfft, Fs);


figure;
plot(fq, 20 * log10(abs(HqHigh) + eps));
hold on;
plot(fq, 20 * log10(abs(HqBand) + eps));
plot(fq, 20 * log10(abs(HqLow) + eps));
plot(fq, 20 * log10(abs(HqSum) + eps));
legend('High-pass', 'Band-pass', 'Low-pass', 'Sum');
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
title(sprintf('Quantized Filters (Q = %d)',Q));
ylim([-80 5]); grid on;


% Command window output
fprintf('LPF: min = %d, max = %d\n', ...
    min(lowPassQuant), max(lowPassQuant));
fprintf('BPF: min = %d, max = %d\n', ...
    min(bandPassQuant), max(bandPassQuant));
fprintf('HPF: min = %d, max = %d\n', ...
    min(highPassQuant), max(highPassQuant));

% Export data to VHDL (package)
packageFile = fopen(fullfile('..','fpga','rtl','eq_coeffs_pkg.vhd'), 'w');
assert(packageFile ~=-1, 'Cannot open output VHDL file');
fprintf(packageFile, 'library ieee;\nuse ieee.std_logic_1164.all;\nuse ieee.numeric_std.all;\n\n');
fprintf(packageFile, 'package eq_coeffs_pkg is\n');
fprintf(packageFile, '  constant FILTER_TAPS : integer := %d;\n', N);
fprintf(packageFile, '  type coeffs_array is array (0 to FILTER_TAPS-1) of integer;\n');
fprintf(packageFile, '  constant EQ_SCALE_BITS : integer := %d;\n', Q);

write_vhdl_array(packageFile,'COEF_LPF',lowPassQuant);
write_vhdl_array(packageFile,'COEF_BPF',bandPassQuant);
write_vhdl_array(packageFile,'COEF_HPF',highPassQuant);

fprintf(packageFile, 'end package eq_coeffs_pkg;\n');
fclose(packageFile);
disp('VHDL coefficient package exported successfully.');

% Function write_vhdl_array
function write_vhdl_array(fileId, arrayName, coefficients)
fprintf(fileId, '  constant %s : coeffs_array := (\n', arrayName);
for index = 1:numel(coefficients)
    fprintf(fileId, '%6d', coefficients(index));
    if index < numel(coefficients)
        fprintf(fileId, ',');
        if mod(index,10) == 0 
            fprintf(fileId, '\n');
        end
    end

end
fprintf(fileId, '\n  ); \n\n' );
end