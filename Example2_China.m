%% Example: COVID-2019 data for Hubei, China (22-Jan-2020 - )
% I am taking some data, collected into DATA.mat from John Hopkins university 
% [1]
% 
% [1] <https://github.com/CSSEGISandData/COVID-19 https://github.com/CSSEGISandData/COVID-19>
% 
% 
% 
% *Important notice:*
% 
% The fitting is here more challenging than in Example 1 because the term 
% "Confirmed patient" used in the database does not precise whether they have 
% been quarantined or not. In a previous version of the submision (version <1.5) 
% , the infectious cases were erroneously used instead of the quarantined cases. 
%% Initialisation
% The parameters are here taken as constant except the death rate and the cure 
% rate.

clearvars;close all;clc;

addpath /home/rodralez/my/investigacion/work-in-progress/covid-19/cheynet/SEIR/

% Download the data from ref [1] and read them with the function getDataCOVID
[tableConfirmed,tableDeaths,tableRecovered,time] = getDataCOVID();

Location = 'Hubei';

Npop= 14e6; % population

try
    indR = find(contains(tableRecovered.ProvinceState,Location)==1);
    indC = find(contains(tableConfirmed.ProvinceState,Location)==1);
    indD = find(contains(tableDeaths.ProvinceState,Location)==1);
catch exception
    searchLoc = strfind(tableRecovered.ProvinceState,Location);
    indR = find([searchLoc{:}]==1);
    
    searchLoc = strfind(tableConfirmed.ProvinceState,Location);
    indC = find([searchLoc{:}]==1);
    
    searchLoc = strfind(tableConfirmed.ProvinceState,Location);
    indD = find([searchLoc{:}]==1);  
    
end


%% Fitting of the generalized SEIR model to the real data



%% SCENARIO 1

% Definition of the first estimates for the parameters
guess.alpha = 1; % protection rate
guess.beta = 1.0; % Infection rate
guess.LT = 5; % latent time in days
guess.QT = 30; % quarantine time in days
guess.lambda = [0.1, 0.05]; % recovery rate
guess.kappa  = [0.1, 0.05]; % death rate

D = 55; %01/03/2020

Recovered = table2array(tableRecovered(indR,5:D+4));
Deaths = table2array(tableDeaths(indD,5:D+4));
Confirmed = table2array(tableConfirmed(indC,5:D+4));

param_23 = my_fit_SEIQRDP(Confirmed, Recovered, Deaths, Npop, time(1:D), guess);

fprintf(['Most recent update: ', datestr(time(end)),'\n'])

%% SCENARIO 2

D = length(time);

% Definition of the first estimates for the parameters
guess.alpha = 0.06; % protection rate
guess.beta = 1.0; % Infection rate
guess.LT = 5; % latent time in days
guess.QT = 21; % quarantine time in days
guess.lambda = [0.1,0.05]; % recovery rate
guess.kappa = [0.1,0.05]; % death rate

Recovered = table2array(tableRecovered(indR,5:D+4));
Deaths = table2array(tableDeaths(indD,5:D+4));
Confirmed = table2array(tableConfirmed(indC,5:D+4));

param = my_fit_SEIQRDP(Confirmed, Recovered, Deaths, Npop, time, guess);

%% Simulate the epidemy outbreak based on the fitted parameters

% Initial conditions
E0 = Confirmed(1); % Initial number of exposed cases. Unknown but unlikely to be zero.
I0 = Confirmed(1); % Initial number of infectious cases. Unknown but unlikely to be zero.
Q0 = Confirmed(1);
R0 = Recovered(1);
D0 = Deaths(1);

dt = 0.1; % time step
time1 = datetime(time(1)):dt:datetime(time(D));
N = numel(time1);
t1 = [0:N-1].*dt;

[S1,E1,I1,Q1,R1,D1,P1] = SEIQRDP(param_23, Npop, E0, I0, Q0, R0, D0, t1);

time2 = datetime( time(1)):dt:datetime(datestr( floor( datenum(now) ) + datenum(10) ) );
N = numel(time2);
t2 = [0:N-1].*dt;

[S2,E2,I2,Q2,R2,D2,P2] = SEIQRDP(param, Npop, E0, I0, Q0, R0, D0, t2);

%% Comparison of the fitted and real data
 
figure
semilogy(time2,Q2,'r',time2,R2,'b',time2,D2,'k');
hold on
semilogy(time,Confirmed-Recovered-Deaths,'ro',time,Recovered,'bo',time,Deaths,'ko');
% ylim([0,1.1*Npop])
ylabel('Number of cases')
xlabel('time (days)')
leg = {'Confirmed (fitted)',...
        'Recovered (fitted)','Deceased (fitted)',...
        'Confirmed (reported)','Recovered (reported)','Deceased  (reported)'};
legend(leg{:},'location','southoutside')
set(gcf,'color','w')
grid on
axis tight
% ylim([1,8e4])
set(gca,'yscale','lin')