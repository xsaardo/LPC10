function [k, a] = levDurbin(R)
% Return PARCOR coefficients k and LPC coefficients a for input
% autocorrelation sequence R

    E = R(1);
    k = zeros(10,1);
    a = zeros(10,1);
    k(1) = R(2)/E;
    a(1) = k(1);
    E = (1-k(1)^2)*E;
    
    for i = 2:10
        k(i) = (R(i+1) - a(1:i-1)'*flipud(R(2:i)))/E;
        a = a - k(i)*circshift(flipud(a),i-1,1);
        a(i) = k(i);
        E = (1-k(i)^2)*E;
    end
    
end