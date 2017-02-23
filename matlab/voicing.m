% Generate ZCR for each frame

framelength = 180;
hamwin = hamming(framelength);
zcr_thresh = 0.26;

% Prepare speech
[speech, Fs] = audioread('OSR_us_000_0010_8k.wav');
speech = speech(1:40000);

speech = speech/max(abs(speech));

amp = max(abs(speech));
quantizer = dsp.UniformEncoder('PeakValue',amp,'NumBits',12,'OutputDataType','Signed integer');
speech = step(quantizer,speech);
decoder = dsp.UniformDecoder('PeakValue',amp,'NumBits',12);
speech = step(decoder,speech);

numwindows = ceil(length(speech)/framelength);
speech = filter([1 -0.9375],1,speech);

% Zero padding
speech = [speech; zeros(abs(length(speech)-numwindows*framelength),1)];

zcr = zeros(numwindows,1);
zcr_plot = zeros(length(speech),1);

for win = 1:numwindows
    frame = speech((win-1)*framelength + 1:win*framelength);
    frame = frame.*hamwin;
    signmat = sign(frame);
    
    zcr_plot((win-1)*framelength + 1:win*framelength) = mean(abs(diff(signmat)/2));
    zcr(win) = mean(abs(diff(signmat)/2));
end

zcr_plot(zcr_plot > zcr_thresh) = 1;
zcr_plot(zcr_plot <= zcr_thresh) = 0;


