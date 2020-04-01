function param = my_fit_SEIQRDP(Confirmed, Recovered, Deaths, Npop, E0, I0, time, guess)


guess_v = [guess.alpha,  guess.beta, 1/guess.LT, 1/guess.QT, guess.lambda,...
    guess.kappa];

% disp(tableRecovered(indR,1:2));
% 
% indR = indR(1);

% If the number of confirmed Confirmed cases is small, it is difficult to know whether
% the quarantine has been rigorously applied or not. In addition, this
% suggests that the number of infectious is much larger than the number of
% confirmed cases
% 
% minNum= 50;
% Recovered(Confirmed<=minNum)=[];
% Deaths(Confirmed<=minNum)=[];
% time(Confirmed<=minNum)= [];
% Confirmed(Confirmed<=minNum)=[];

% Parameter estimation with the lsqcurvefit function
[alpha1,beta1,gamma1,delta1,lambda1,kappa1] = ...
    fit_SEIQRDP(Confirmed-Recovered-Deaths,Recovered,Deaths,Npop,E0,I0,time,guess_v);

%     fit_SEIQRDP(Confirmed,Recovered,Deaths,Npop,E0,I0,time,guess_v);

%     fit_SEIQRDP(Confirmed-Recovered-Deaths,Recovered,Deaths,Npop,E0,I0,time,guess_v);

param.alpha = alpha1;
param.beta = beta1;
param.gamma = gamma1;
param.delta = delta1;
param.lambda = lambda1;
param.kappa = kappa1;

end