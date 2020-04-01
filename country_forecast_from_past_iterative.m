
clear
close all
clc

L = 15;
Q = 25;
M = L * Q;

qt = 1:Q;

opti_m = zeros(M, 3);

z = 1;

for i = 1:15
    
    guess.LT = i; % latent time in days
    
    for j = 1:25    

        guess.QT = j; % quarantine time in days
        
        country_forecast_from_past
        
        opti_m ( z , :) =  [infec_err, i, j];
        
        z = z + 1;
        
        close all
    end
end



