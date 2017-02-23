%% LPC Encoder
% Generate LPC10 parameters and store them in parameters.mat
tic 
% Parameters
framelength = 180;
hamwin = hamming(framelength);
zcr_thresh = 0.05;
% 
% recorder = audiorecorder(8000,16,1);
% recordblocking(recorder,5);
% speech = getaudiodata(recorder);

[speech, Fs] = audioread('OSR_us_000_0010_8k.wav');
speech = speech(1:40000); % Extract first 5 seconds of file;

% Speech Normalization
speech = speech/max(abs(speech));

amp = max(abs(speech));

% Initial PCM
quantizer = dsp.UniformEncoder('PeakValue',amp,'NumBits',12,'OutputDataType','Signed integer');
speech = step(quantizer,speech);
decoder = dsp.UniformDecoder('PeakValue',amp,'NumBits',12);
speech = step(decoder,speech);

% Initial HPF
speech = filter([1 -0.9375],1,speech);

% Calculating number of windows
numwindows = ceil(length(speech)/framelength);

% Zero padding
speech = [speech; zeros(abs(length(speech)-numwindows*framelength),1)];

% Initialize parameters to be transmitted
period = zeros(numwindows,1);
voiced = zeros(numwindows,1);
gain = zeros(numwindows,1);
coeff = zeros(numwindows,10);

% Process Window by window
for win = 1:numwindows
    frame = speech((win-1)*framelength + 1:win*framelength);
    frame = frame.*hamwin;
    
    % LPC Coefficients
    autocorr = xcorr(frame,10);
    autocorr = autocorr(11:end);
    [k, a] = levDurbin(autocorr);
    k(1:2) = log10((1-k(1:2))./(1+k(1:2))); % Convert to LAR
    coeff(win,:) = k;
    
    % Zero Crossing Rate
    % Voiced/unvoiced detection through ZCR
    signmat = sign(frame);
    zcr = mean(abs(diff(signmat)/2));
    if zcr > zcr_thresh, voiced(win) = 0;
    else voiced(win) = 1; end
    
    % Pitch Detection
    residual = filter([1; -a],1,frame);
    if voiced(win)
        % Impulse train generation
        residual = residual.*hamming(length(residual));
        period(win) = pitch_detector(residual);
        
        % Set period within range of valid values
        if period(win) < 20
            period(win) = 0;
            voiced(win) = 0;
        end
        
        % Gain Calculation
        if (period(win) == 0)
            gain(win) = sqrt(mean(residual.^2));
        else
            error = residual.^2;
            error = error(1:floor(framelength/period)*period);
            gaintemp = sum(error)/(floor(framelength/period)*period);
            gain(win) = sqrt(period(win)*gaintemp);
        end
    else
        period(win) = 0;
        gain(win) = sqrt(mean(residual.^2));
    end
end
% Median filtering of pitch periods
period = medfilt1(period,5);
% Maximum gain calculation for quantization
maxgain = max(gain);

%% Quantization
% Quantize LPC10 parameters 
% Gain Quantization to 5 bits
% 
gain_quant = dsp.UniformEncoder('PeakValue',maxgain,'NumBits', 5,'OutputDataType','Unsigned integer');
gain = step(gain_quant,gain);

% Period Quantization to 6 bits
period(period < 42 & period < 78) = double(2*uint8(period(period < 42 & period < 78)/2));

% LPC Coefficient Quantization
lar_coeff = coeff(:,1:2);
lar_quant = dsp.UniformEncoder('PeakValue', 2, 'NumBits', 5,'OutputDataType','Signed integer');
lar_coeff = step(lar_quant, lar_coeff);

par5_coeff = coeff(:,3:4);
coeff5 = dsp.UniformEncoder('NumBits', 5,'OutputDataType','Signed integer');
par5_coeff = step(coeff5, par5_coeff);

par4_coeff = coeff(:,5:8);
coeff4 = dsp.UniformEncoder('NumBits', 4,'OutputDataType','Signed integer');
par4_coeff = step(coeff4, par4_coeff);

par3_coeff = coeff(:,9);
coeff3 = dsp.UniformEncoder('NumBits', 3,'OutputDataType','Signed integer');
par3_coeff = step(coeff3, par3_coeff);

par2_coeff = coeff(:,10);
coeff2 = dsp.UniformEncoder('NumBits', 2,'OutputDataType','Signed integer');
par2_coeff = step(coeff2, par2_coeff);

coeff = [lar_coeff par5_coeff par4_coeff par3_coeff par2_coeff];

parameters = [int8(gain) period coeff];
save('parameters','parameters');
toc

Total_Bits = size(coeff,1)*53



