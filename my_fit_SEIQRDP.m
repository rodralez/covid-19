function param = my_fit_SEIQRDP(Confirmed, Recovered, Deaths, Npop, E0, I0, time, varargin)
% [param,varargout] = 
% my_fit_SEIQRDP(Q,R,D,Npop,E0,I0,time,guess,varargin) estimates the 
% parameters used in the SEIQRDP function, used to model the time-evolution
% of an epidemic outbreak.
% Based on E. Cheynet's work [1].
%
% see also fit_SEIQRDP.m
%
% References:
% [1] https://www.mathworks.com/matlabcentral/fileexchange/74545-generalized-seir-epidemic-model-fitting-and-computation
%
% Version: 001
% Date:    2020/04/02
% Author:  Rodrigo Gonzalez <rodralez@frm.utn.edu.ar>
% URL:     https://github.com/rodralez/covid-19 
% 
% Input
% 
%   I: vector [1xN] of the target time-histories of the infectious cases
%   R: vector [1xN] of the target time-histories of the recovered cases
%   D: vector [1xN] of the target time-histories of the dead cases
%   Npop: scalar: Total population of the sample
%   E0: scalar [1x1]: Initial number of exposed cases
%   I0: scalar [1x1]: Initial number of infectious cases
%   time: vector [1xN] of time (datetime)
%   guess: first vector [1x6] guess for the fit
%   optionals
%       -tolFun: tolerance  option for optimset
%       -tolX: tolerance  option for optimset
%       -Display: Display option for optimset
%       -dt: time step for the fitting function
% 
% Output
% 
%   alpha: scalar [1x1]: fitted protection rate
%   beta: scalar [1x1]: fitted  infection rate
%   gamma: scalar [1x1]: fitted  Inverse of the average latent time
%   delta: scalar [1x1]: fitted  inverse of the average quarantine time
%   lambda: scalar [1x2]: fitted  cure rate
%   kappa: scalar [1x2]: fitted  mortality rate
%   optional:
%       - residual
%       - Jcobian
%       - The function @SEIQRDP_for_fitting

guess.LT = 5; % gamma^(-1), incubation period.
guess.QT = 5; % delta^(-1), infectious period.

% Definition of the first estimates for the parameters
guess.alpha = 1.0; % protection rate
guess.beta  = 1.0; % Infection rate

guess.lambda = [0.1, 0.05]; % recovery rate
guess.kappa  = [0.1, 0.05]; % death rate

guess_v = [guess.alpha,  guess.beta, 1/guess.LT, 1/guess.QT, guess.lambda,...
    guess.kappa];

% Parameter estimation with the lsqcurvefit function
if ~isempty(Recovered)
    
    [alpha1, beta1, gamma1, delta1, lambda1, kappa1, varargout] = ...
        fit_SEIQRDP(Confirmed-Recovered-Deaths,Recovered,Deaths,Npop,E0,I0,time,guess_v);
    
else
    
    [alpha1, beta1, gamma1, delta1, lambda1, kappa1, varargout] = ...
        fit_SEIQRDP(Confirmed-Deaths,Recovered,Deaths,Npop,E0,I0,time,guess_v);
end

% fit_SEIQRDP(Confirmed-Deaths,[],Deaths,Npop,E0,I0,time,guess,'Display','off');

param.alpha = alpha1;
param.beta = beta1;
param.gamma = gamma1;
param.delta = delta1;
param.lambda = lambda1;
param.kappa = kappa1;
param.varargout = varargout;
end