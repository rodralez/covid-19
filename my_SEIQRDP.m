function [S,E,I,Q,R,D,P] = my_SEIQRDP(param,Npop,E0,I0,Q0,R0,D0,t)
% [S,E,I,Q,R,D,P] = SEIQRDP(param,Npop,E0,I0,R0,D0,t)
% simulate the time-histories of an epidemic outbreak using a generalized
% SEIR model.
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
%   param.alpha: scalar [1x1]: fitted protection rate
%   param.beta: scalar [1x1]: fitted  infection rate
%   param.gamma: scalar [1x1]: fitted  Inverse of the average latent time
%   param.delta: scalar [1x1]: fitted  inverse of the average quarantine time
%   param.lambda: scalar [1x1]: fitted  cure rate
%   param.kappa: scalar [1x1]: fitted  mortality rate
%   Npop: scalar: Total population of the sample
%   E0: scalar [1x1]: Initial number of exposed cases
%   I0: scalar [1x1]: Initial number of infectious cases
%   Q0: scalar [1x1]: Initial number of quarantined cases
%   R0: scalar [1x1]: Initial number of recovered cases
%   D0: scalar [1x1]: Initial number of dead cases
%   t: vector [1xN] of time (double; it cannot be a datetime)
%
% Output
%   S: vector [1xN] of the target time-histories of the susceptible cases
%   E: vector [1xN] of the target time-histories of the exposed cases
%   I: vector [1xN] of the target time-histories of the infectious cases
%   Q: vector [1xN] of the target time-histories of the quarantinedcases
%   R: vector [1xN] of the target time-histories of the recovered cases
%   D: vector [1xN] of the target time-histories of the dead cases
%   P: vector [1xN] of the target time-histories of the insusceptible cases

%%

alpha = param.alpha;
beta = param.beta;
gamma = param.gamma;
delta = param.delta;
lambda0 = param.lambda;
kappa0 = param.kappa;

%% Initial conditions
N = numel(t);
Y = zeros(7,N);
Y(1,1) = Npop-Q0-E0-R0-D0-I0;
Y(2,1) = E0;
Y(3,1) = I0;
Y(4,1) = Q0;
Y(5,1) = R0;
Y(6,1) = D0;

if round(sum(Y(:,1))-Npop)~=0
    error('the sum must be zero because the total population (including the deads) is assumed constant');
end
%%
modelFun = @(Y,A,F) A*Y + F;
dt = median(diff(t));
% ODE resolution

lambda = lambda0(1)*(1-exp(-lambda0(2).*t)); % I use these functions for illustrative purpose only
kappa = kappa0(1)*exp(-kappa0(2).*t); % I use these functions for illustrative purpose only


for ii=1:N-1
    A = getA(alpha,gamma,delta,lambda(ii),kappa(ii));
    SI = Y(1,ii)*Y(3,ii);
    F = zeros(7,1);
    F(1:2,1) = [-beta/Npop;beta/Npop].*SI;
    Y(:,ii+1) = RK4(modelFun,Y(:,ii),A,F,dt);
end


S = Y(1,1:N);
E = Y(2,1:N);
I = Y(3,1:N);
Q = Y(4,1:N);
R = Y(5,1:N);
D = Y(6,1:N);
P = Y(7,1:N);



    function [A] = getA(alpha,gamma,delta,lambda,kappa)
        A = zeros(7);
        % S
        A(1,1) = -alpha;
        % E
        A(2,2) = -gamma;
        % I
        A(3,2:3) = [gamma,-delta];
        % Q
        A(4,3:4) = [delta,-kappa-lambda];
        % R
        A(5,4) = lambda;
        % D
        A(6,4) = kappa;
        % P
        A(7,1) = alpha;
    end
    function [Y] = RK4(Fun,Y,A,F,dt)
        % Runge-Kutta of order 4
        k_1 = Fun(Y,A,F);
        k_2 = Fun(Y+0.5*dt*k_1,A,F);
        k_3 = Fun(Y+0.5*dt*k_2,A,F);
        k_4 = Fun(Y+k_3*dt,A,F);
        % output
        Y = Y + (1/6)*(k_1+2*k_2+2*k_3+k_4)*dt;
    end

end


