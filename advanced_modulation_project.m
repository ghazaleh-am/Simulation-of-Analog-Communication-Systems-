function advanced_modulation_project()
    % Project: Analog Modulation Analysis under AWGN
    % Author: [Your Name Here]
    % Description: AM/FM Modulation, Noise addition, Spectral Analysis, and Demodulation.
    
    clc; close all; clear;

    %% 1. System Parameters (تنظیمات سیستم)
    fs = 10000;             % نرخ نمونه‌برداری (Hz)
    T = 1;                  % مدت زمان سیگنال (ثانیه)
    t = 0:1/fs:T-1/fs;      % بردار زمان
    
    fc = 500;               % فرکانس حامل (Carrier)
    fm = 10;                % فرکانس پیام (Message)
    SNR_dB = 15;            % نسبت سیگنال به نویز (کم کنید تا نویز بیشتر شود)

    % ساخت سیگنال پیام (Message Signal)
    msg = cos(2*pi*fm*t);
    
    %% 2. Transmitter (فرستنده)
    
    % --- AM Modulation ---
    % m < 1 ensures no overmodulation
    m_idx = 0.8;            
    tx_am = (1 + m_idx * msg) .* cos(2*pi*fc*t);
    
    % --- FM Modulation ---
    % beta = df / fm
    beta_idx = 5;           
    tx_fm = cos(2*pi*fc*t + beta_idx * sin(2*pi*fm*t));

    %% 3. Channel (کانال نویزی)
    
    % افزودن نویز سفید گوسی (AWGN) به صورت دستی برای درک ریاضی
    % Signal Power calculation
    Ps_am = bandpower(tx_am);
    Ps_fm = bandpower(tx_fm);
    
    % Noise Power calculation based on SNR
    Pn_am = Ps_am / (10^(SNR_dB/10));
    Pn_fm = Ps_fm / (10^(SNR_dB/10));
    
    % Generate Noise
    noise_am = sqrt(Pn_am) * randn(size(tx_am));
    noise_fm = sqrt(Pn_fm) * randn(size(tx_fm));
    
    % Received Signals
    rx_am = tx_am + noise_am;
    rx_fm = tx_fm + noise_fm;

    %% 4. Receiver (گیرنده و دمدولاسیون)
    
    % --- AM Demodulation (Envelope Detector using Hilbert) ---
    demod_am = abs(hilbert(rx_am)); 
    demod_am = demod_am - mean(demod_am); % حذف DC Offset
    
    % --- FM Demodulation (Instantaneous Frequency) ---
    % استفاده از تبدیل هیلبرت برای استخراج فاز لحظه‌ای و مشتق‌گیری
    inst_phase = unwrap(angle(hilbert(rx_fm)));
    inst_freq = diff(inst_phase) * fs / (2*pi); 
    % تغییر سایز برای همخوانی ابعاد (مشتق یک نمونه کم می‌کند)
    demod_fm = [inst_freq, inst_freq(end)]; 
    demod_fm = demod_fm - mean(demod_fm); % حذف Carrier Offset
    
    % فیلتر پایین‌گذر برای حذف نویزهای فرکانس بالا در گیرنده
    demod_am = lowpass(demod_am, 50, fs);
    demod_fm = lowpass(demod_fm, 50, fs);

    %% 5. Visualization (داشبورد مهندسی)
    
    figure('Name', 'Advanced DSP Project: AM vs FM', 'Color', 'w', 'Position', [100, 100, 1200, 700]);
    
    % --- Row 1: Time Domain (Noisy) ---
    subplot(3,2,1);
    plot(t(1:500), rx_am(1:500), 'b'); title(['AM Signal + Noise (SNR=' num2str(SNR_dB) 'dB)']);
    grid on; ylabel('Amplitude'); axis tight;
    
    subplot(3,2,2);
    plot(t(1:500), rx_fm(1:500), 'r'); title(['FM Signal + Noise (SNR=' num2str(SNR_dB) 'dB)']);
    grid on; axis tight;

    % --- Row 2: Frequency Domain (Spectrum) ---
    subplot(3,2,3);
    plot_fft(tx_am, fs, 'b'); title('AM Spectrum (Bandwidth Analysis)');
    ylim([-100 0]); xlim([0 1000]);
    
    subplot(3,2,4);
    plot_fft(tx_fm, fs, 'r'); title('FM Spectrum (Carson''s Rule)');
    ylim([-100 0]); xlim([0 1000]);

    % --- Row 3: Demodulated Output (Result) ---
    subplot(3,2,5);
    plot(t, msg, 'k--', 'LineWidth', 1.5); hold on;
    plot(t, demod_am, 'b', 'LineWidth', 1);
    legend('Original', 'Recovered'); title('AM Demodulation Result');
    grid on; xlabel('Time (s)');
    
    subplot(3,2,6);
    plot(t, msg.*beta_idx*10, 'k--', 'LineWidth', 1.5); hold on; % Scale msg for visual match
    plot(t, demod_fm, 'r', 'LineWidth', 1);
    legend('Original', 'Recovered'); title('FM Demodulation Result');
    grid on; xlabel('Time (s)');
end

function plot_fft(sig, fs, color_code)
    % تابع کمکی برای رسم FFT استاندارد
    L = length(sig);
    Y = fft(sig);
    P2 = abs(Y/L);
    P1 = P2(1:L/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f = fs*(0:(L/2))/L;
    
    % تبدیل به dB
    P1_dB = 20*log10(P1 + eps); % eps برای جلوگیری از log(0)
    plot(f, P1_dB, color_code, 'LineWidth', 1.2);
    grid on; xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
end