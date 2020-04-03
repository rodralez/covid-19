
clear
close all
clc

ITERATIVE = 'ON'

% L = 7;
% Q = 25;
% M = L * Q;
%
% guess.LT = 1; % latent time in days, incubation period, gamma^(-1)
% guess.QT = 2; % quarantine time in days, infectious period, delta^(-1)
%
% opti_m = zeros(M, 3);
%
% z = 1;
%
% for i = 1:Q
%
%     guess.QT = i; % quarantine time in days
%
%     for j = 1:L
%
%         guess.LT = j; % latent time in days
%
%         seir_adjust
%
%         opti_m ( z , :) =  [infec_err, i, j];
%
%         z = z + 1;
%
%         close all
%     end
% end

test = 1:0.05:2;
M = length(test);

data_m = zeros(M, 2);

for i = 1:M
    
    ADJ = test(i)
    
    seir_adjust
    
    data_m ( i , :) =  [ADJ, infec_err];
    
end

[ MIN_DATA , idx ] = min ( data_m(:,2) )

figure, plot(data_m(:,1) , data_m(:,2), '-o')
grid on

save data_m data_m


