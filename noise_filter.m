function flt_signal = noise_filter(signal)

% Butterworth Highpass filter designed using FDESIGN.HIGHPASS.
% Coeficients of the filter derived from fdatool
% All frequency values are in Hz.

%Fs = 16000;  % Sampling Frequency

%Fstop = 300;         % Stopband Frequency
%Fpass = 4000;        % Passband Frequency
% Astop = 40;          % Stopband Attenuation (dB)
% Apass = 3;           % Passband Ripple (dB)
% match = 'stopband';  % Band to match exactly

% flt_signal=filter([1 -2 1],[1 -0.59790 0.23549],signal);
flt_signal=filter([1 -0.95], [1 0],signal);