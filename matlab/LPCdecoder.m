% Perform synthesis of original speech signal
% reconstruct = synthesized speech file
tic

%% Load quantized parameters
load parameters.mat

coeff = parameters(:,3:end);
gain = parameters(:,1);
period = parameters(:,2);

speechlength = length(speech);
% Synthesize speech from LPC10 paramters

reconstruct = zeros(speechlength,1);
framelength = 180;
numwindows = ceil(speechlength/framelength);

%% Converting quantized parameters to floating point values
% Decode Gain
gain = double(gain - min(gain));

% Decode PARCOR Coefficients
decodelar = dsp.UniformDecoder('PeakValue',2,'NumBits',5);
lar_coeff = step(decodelar, coeff(:,1:2));

decode5 = dsp.UniformDecoder('NumBits',5);
par5_coeff = step(decode5, coeff(:,3:4));

decode4 = dsp.UniformDecoder('NumBits',4);
par4_coeff = step(decode4, coeff(:,5:8));

decode3 = dsp.UniformDecoder('NumBits',3);
par3_coeff = step(decode3, coeff(:,9));

decode2 = dsp.UniformDecoder('NumBits',2);
par2_coeff = step(decode2, coeff(:,10));

coeff = [lar_coeff par5_coeff par4_coeff par3_coeff par2_coeff];

%% Window by window reconstruction

for j = 1:numwindows
    k = coeff(j,:);
    
    % LAR to PARCOR
    k(1:2) = (1 - 10.^k(1:2))./(1 + 10.^k(1:2));
    
    % PARCOR to LPC Coefficients
    a = zeros(10,1);
    for i = 1:10
        a(i) = k(i);
        a(1:i-1) = a(1:i-1) - k(i)*circshift(flipud(a(1:i-1)),i-1,1);
    end
    
    % Excitation Generation and Synthesis
    if period(j) > 0
        impulse = zeros(period(j),1);
        
        % Retain continuity between framess
        if period(j-1) ~= 0 && j > 1 && period(j)-lastpulse > 0
            impulse(period(j)-lastpulse) = 1;
            excitation = repmat(impulse,100,1);
            excitation = excitation(1:framelength);
            lastpulse = find(excitation == 1);
            lastpulse = 180-lastpulse(end);
        else
            impulse(1) = 1;
            excitation = repmat(impulse,100,1);
            excitation = excitation(1:framelength);
            lastpulse = find(excitation == 1);
            lastpulse = 180-lastpulse(end);
        end
        
        excitation = repmat(impulse,100,1);
        excitation = excitation(1:framelength); % impulse train excitation
        
        synth = gain(j)*filter(1,[1; -a], excitation);
    else
        excitation = randn(framelength,1); % white noise excitation
        synth = gain(j)*filter(1,[1; -a], excitation);
    end
    reconstruct((j-1)*framelength+1:j*framelength) = synth;
end

% Post Filter
reconstruct = filter(1,[1 -0.9375],reconstruct);
toc
