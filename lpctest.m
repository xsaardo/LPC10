%% LPC Encoder

% Parameters
framelength = 180;
hamwin = hamming(framelength);
zcr_thresh = 0.26;
% pav_thresh = 0.0026;

[speech, Fs] = audioread('OSR_us_000_0010_8k.wav');
speech = speech(1:40000);

% Speech Normalization
speech = speech/max(abs(speech));

% Initial PCM
quantizer = dsp.UniformEncoder('PeakValue',max(abs(speech)),'NumBits',12,'OutputDataType','Signed integer');
speech = double(step(quantizer,speech));

% Initial HPF
speech = filter([1 -0.9375],1,speech);

% Calculating number of windows
numwindows = ceil(length(speech)/framelength);

% Zero padding
speech = [speech; zeros(abs(length(speech)-numwindows*framelength),1)];

reconstruct = [];

% Process Window by window
for win = 1:numwindows
    frame = speech((win-1)*framelength + 1:win*framelength);
    frame = frame.*hamwin;
    
    %% LPC Coefficients
    autocorr = xcorr(frame,10);
    autocorr = autocorr(11:end);
    
    Rx = toeplitz(autocorr(1:end-1));
    r = autocorr(2:end);
    
    a = Rx\r;
    
    %% Zero Crossing Rate      
    % Voiced detection through ZCR
    signmat = sign(frame);
    zcr = mean(abs(diff(signmat)/2));
    if zcr > zcr_thresh, voiced = 0;
    else voiced = 1; end
    
    % Voiced detection through energy
%     pav = mean((frame.*hamwin).^2);
%     if pav > pav_thresh,  voiced = 1;
%     else voiced = 0; end
%     
    %% Pitch Detection
    residual = filter([1; -a],1,frame);
    if voiced
        % Impulse train generation
        residual = residual.*hamming(length(residual));
        period = pitch_detector(residual);
        while period < 20
            period = period*2;
        end
        impulse = zeros(period,1);
        impulse(1) = 1;
        excitation = repmat(impulse,100,1);
        excitation = excitation(1:framelength);
        
        % Gain Calculation
        error = residual.^2;
        error = error(1:floor(framelength/period)*period);
        gain = sum(error)/(floor(framelength/period)*period);
        gain = sqrt(period*gain);
%         pause;
    else 
        excitation = randn(framelength,1);
        gain = sqrt(mean(residual.^2));
    end
    
    %% Synthesis
    synth = filter(gain,[1; -a],excitation);
    reconstruct = [reconstruct; synth];
end