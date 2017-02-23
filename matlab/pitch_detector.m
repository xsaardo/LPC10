function [pitch] = pitch_detector(signal)

[autocorr,lags] = xcorr(signal);
ind = find(lags == 0);
autocorr = autocorr(ind:end);
[max, loc] = findpeaks(autocorr);
[~,order] = sort(max,'descend');
loc = loc(order);
pitch = loc(1);

end