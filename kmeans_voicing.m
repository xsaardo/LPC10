% Initialize centroids
mean1 = 0.5;
mean2 = 0.05;
zcr_label = zeros(length(zcr),1);

for j = 1:100
    for i = 1:length(zcr_label)
        diff1 = abs(zcr(i) - mean1);
        diff2 = abs(zcr(i) - mean2);
        if diff1 > diff2
            zcr_label(i) = 1;
        else
            zcr_label(i) = 0;
        end
        mean1 = mean(zcr(zcr_label == 0));
        mean2 = mean(zcr(zcr_label == 1));
    end
end
