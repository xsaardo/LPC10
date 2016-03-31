%% Quantization
% Quantize LPC10 parameters 
tic
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

