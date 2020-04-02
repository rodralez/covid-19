% seir_forecast() forecasts a generalized SEIR model n days.
% Based on E. Cheynet's work [1].
%
% References:
% [1] https://www.mathworks.com/matlabcentral/fileexchange/74545-generalized-seir-epidemic-model-fitting-and-computation
%
% Version: 001
% Date:    2020/04/02
% Author:  Rodrigo Gonzalez <rodralez@frm.utn.edu.ar>
% URL:     https://github.com/rodralez/covid-19 
%
% The fitting is here more challenging than in Example 1 because the term 
% "Confirmed patient" used in the database does not precise whether they have 
% been quarantined or not. In a previous version of the submision (version <1.5) 
% , the infectious cases were erroneously used instead of the quarantined cases. 

clear
close all
clc

%% Cases

% S(t): susceptible cases,
% P(t): insusceptible cases, 
% E(t): exposed cases(infected but not yet be infectious, in a latent period),
% I(t): infectious cases(with infectious capacity and not yet be quarantined),
% Q(t): quarantinedcases(confirmed and infected),
% R(t): recovered cases and 
% D(t): % closed cases(or death

%% Rates

% alpha: protection rate, 
% beta: infection rate, 
% gamma: average latent time, 
% delta: average quarantine time, 
% lambda: cure rate, and 
% kappa: mortalityrate, separately

%% COUNTRY

% Country = 'Germany';
% Npop = 82.79e6; % population
% guess.LT = 5.1; % latent time in days
% guess.QT = 20; % quarantine time in days

% Country = 'Brazil';
% Province = '';
% Npop = 209.3e6; % population
% guess.LT = 4; % latent time in days
% guess.QT = 6; % quarantine time in days

% Country = 'Chile';
% Province = '';
% Npop = 18.5e6; % population
% guess.LT = 4; % latent time in days
% guess.QT = 6; % quarantine time in days

% Country = 'Turkey';
% Province = '';
% Npop = 80.81e6; % population
% guess.LT = 4; % latent time in days
% guess.QT = 6; % quarantine time in days

% Country = 'Spain';
% Province = '';
% Npop = 46.66e6; % population
% guess.LT = 2; % latent time in days
% guess.QT = 5; % quarantine time in days

% Country = 'Italy';
% Province = '';
% Npop = 60.48e6; % population
% guess.LT = 4; % latent time in days
% guess.QT = 6; % quara

% Country = 'France';
% Province = '';
% Npop= 66.99e6; % population
% guess.LT = 1; % latent time in days
% guess.QT = 5; % quarantine time in days

% Country = 'Argentina';
% Province = '';
% Npop= 45e6; % population
% guess.LT = 5; % latent time in days, incubation period, gamma^(-1)
% guess.QT = 23; % quarantine time in days, infectious period, delta^(-1)

Country = 'China';
% Province = '';
% Npop = 1386e6; % population
Province = 'Hubei';
Npop = 59e6; % population
guess.LT = 1; % latent time in days
guess.QT = 2; % quarantine time in days

%% SOURCE

% source = 'online' ;
source = 'offline' ;

[tableConfirmed,tableDeaths,tableRecovered,time] = get_covid_global_hopkins( source, './hopkins/' );

% [tableConfirmed,tableDeaths,time] = get_covid_global_hopkins( source );


%% DAYS TO FORECAST 

FORECAST = 7;

%% FIND COUNTRY

try
    indR = find( contains(  tableRecovered.CountryRegion, Country) == 1 );
    indR = indR( ismissing( tableRecovered.ProvinceState(indR), Province) );
     
    indC = find( contains(  tableConfirmed.CountryRegion, Country) == 1 );
    indC = indC( ismissing( tableConfirmed.ProvinceState(indC), Province) );
   
    indD = find(contains(tableDeaths.CountryRegion, Country)==1);
    indD = indD( ismissing( tableConfirmed.ProvinceState(indD), Province) );
    
catch exception
    
    searchLoc = strfind(tableRecovered.ProvinceState,Country);
    indR = find([searchLoc{:}]==1);
    
    searchLoc = strfind(tableConfirmed.ProvinceState,Country);
    indC = find([searchLoc{:}]==1);
    
    searchLoc = strfind(tableConfirmed.ProvinceState,Country);
    indD = find([searchLoc{:}]==1); 
end

if ( isempty(indR) & isempty(indC) & isempty(indD))
    
    error('%s was not found in COVID data!', Country)    
    
end

%% FIND FIRST 50 CASES

% If the number of confirmed Confirmed cases is small, it is difficult to know whether
% the quarantine has been rigorously applied or not. In addition, this
% suggests that the number of infectious is much larger than the number of
% confirmed cases

Recovered = table2array(tableRecovered(indR,5:end));
Deaths    = table2array(tableDeaths(indD,5:end));
Confirmed = table2array(tableConfirmed(indC,5:end));

minNum = 50;
Recovered(Confirmed<=minNum)=[];
Deaths(Confirmed<=minNum)=[];
time(Confirmed<=minNum)= [];
Confirmed(Confirmed<=minNum)=[];

DAYS = length(time);

%% FITTING

% Initial conditions
E0 = Confirmed(1) ; % Initial number of exposed cases. Unknown but unlikely to be zero.
I0 = Confirmed(1) ; % Initial number of infectious cases. Unknown but unlikely to be zero.

% Definition of the first estimates for the parameters
guess.alpha = 0.5; % protection rate
guess.beta  = 1.0; % Infection rate

% guess.lambda = [0.1, 0.05]; % recovery rate
guess.lambda = [0.5, 0.05]; % recovery rate
guess.kappa  = [0.05, 0.1]; % death rate

param_fit = my_fit_SEIQRDP(Confirmed, Recovered, Deaths, Npop, E0, I0, time, guess);

Active = Confirmed-Recovered-Deaths;

%% FORECAST Simulate the epidemy outbreak based on the fitted parameters

% Initial conditions
E0 = Confirmed(1) ; % Initial number of exposed cases. Unknown but unlikely to be zero.
I0 = Confirmed(1) ; % Initial number of infectious cases. Unknown but unlikely to be zero.
Q0 = Confirmed(1) ;

R0 = Recovered(1);
D0 = Deaths(1);

dt = 0.1; % time step

time_sim  = datetime( time(1) ):dt:datetime( time(end) + FORECAST );

N = numel(time_sim);
t1 = (0:N-1).*dt;

% param_fit.delta = 1 / 8; % Argentina 

[S1,E1,I1,Q1,R1,D1,P1] = my_SEIQRDP(param_fit, Npop, E0, I0, Q0, R0, D0, t1);


%% DOUBLING ANALYSYS

fdx = find ( Active < Active(end)/2, 1, 'last');
doubling = datenum ( time(end)- time(fdx) );

%% PRINT

fprintf(['Country: ', Country,'\n'] );

fprintf(['Time series start on ',datestr(time(1)),'\n'] );
fprintf(['Time series stop on ' ,datestr(time(end)),'\n'] );
fprintf('Time series forecast %d days\n', FORECAST );

BRN = param_fit.beta / param_fit.delta * (1 - param_fit.alpha)^DAYS; 

Q_fore_str  = sprintf( 'Models predicts %d active cases on %s', round( (Q1(end)) ), datestr( time_sim(end) ) );
N_fore_str  = sprintf( 'Models predicts new %d active cases on %s', round( (Q1(end)) - Active(end) ), datestr( time_sim(end) ) );
I_fore_str  = sprintf( 'Models predicts %d potential infected on %s', round( Q1(end) + I1(end) ), datestr( time_sim(end) ) );
doubling_str  = sprintf( 'Active cases are doubled in %d days', doubling );
brn_str     = sprintf( 'Ro: %.2f', BRN );
alpha_str   = sprintf( 'alpha : %.2f', param_fit.alpha );
beta_str    = sprintf( 'beta: %.2f', param_fit.beta );
gamma_str   = sprintf( 'gamma^-1: %.1f days', 1/param_fit.gamma);
delta_str   = sprintf( 'delta^-1: %.1f days', 1/param_fit.delta);
lambda_str  = sprintf( 'Recovery rate: %.2f%%', param_fit.lambda(1)*100  );
kappa_str   = sprintf( 'Death rate: %.2f%%', param_fit.kappa(1)*100 );

fprintf( '\n %s \n', Q_fore_str );
fprintf( ' %s \n', I_fore_str );
fprintf( ' %s \n', N_fore_str );
fprintf( ' %s \n', brn_str );
fprintf( ' %s \n', alpha_str );
fprintf( ' %s \n', beta_str );
fprintf( ' %s \n', gamma_str );
fprintf( ' %s \n', delta_str );
fprintf( ' %s \n', lambda_str );
fprintf( ' %s \n', kappa_str );

%% PLOT

blue = [0, 0.4470, 0.7410];
orange = [0.8500, 0.3250, 0.0980];
yellow = [0.9290, 0.6940, 0.1250] ;
purple = [0.4940, 0.1840, 0.5560];
green =  [0.4660, 0.6740, 0.1880];
blue_light = [0.3010, 0.7450, 0.9330] ;
gray = ones(1,3) * 0.65;
red_dark =  [0.6350, 0.0780, 0.1840] ;

font_tick  = 24;
font_label = 30;
font_legend = 18;
font_title = 35;
line_width = 3;

figure

time_fit  = time_sim (time_sim <= time(end));
time_fore = time_sim (time_sim > time(end));

q_fit  = Q1(time_sim <= time(end));
q_fore = Q1(time_sim > time(end));

i_fit  = I1(time_sim <= time(end)) + q_fit;
i_fore = I1(time_sim > time(end))  + q_fore;

r_fit  = R1(time_sim <= time(end));
r_fore = R1(time_sim > time(end));

d_fit  = D1(time_sim <= time(end));
d_fore = D1(time_sim > time(end));

q1 = semilogy(time_fit,  q_fit,  'color', red_dark, 'LineWidth', line_width);
hold on
     semilogy(time_fore, q_fore, 'color', red_dark, 'LineWidth', line_width, 'LineStyle', '--');

r1 = semilogy(time_fit,  r_fit,  'color', blue, 'LineWidth', line_width);
     semilogy(time_fore, r_fore, 'color', blue, 'LineWidth', line_width, 'LineStyle', '--');

d1 = semilogy(time_fit,  d_fit,  'k', 'LineWidth', line_width);
     semilogy(time_fore, d_fore, 'k', 'LineWidth', line_width, 'LineStyle', '--');

qr = semilogy(time, Active, 'color', red_dark, 'Marker', 'o', 'LineStyle', 'none', 'LineWidth', line_width);
rr = semilogy(time, Recovered,'color', blue, 'Marker', 'o', 'LineStyle', 'none', 'LineWidth', line_width);
dr = semilogy(time, Deaths,'ko', 'LineWidth', line_width);

i1 = semilogy(time_fit,  i_fit,  'color', orange, 'LineWidth', line_width, 'LineStyle', '--');
     semilogy(time_fore, i_fore, 'color', orange, 'LineWidth', line_width, 'LineStyle', '--');

% l1_fit = line ([time(1) time(1)], [0 infected_peak], 'color', blue, 'linewidth', 2, 'LineStyle', '--');
% l2_fit = line ([time(DAYS) time(DAYS)], [0 infected_peak ], 'color', blue, 'linewidth', 2, 'LineStyle', '--');
% l1_fore = line ([time(DAYS+1) time(DAYS+1)], [0 infected_peak], 'color', orange, 'linewidth', 2, 'LineStyle', '--');
% l2_fore = line ([time(DAYS+FORECAST) time(DAYS+FORECAST)], [0 infected_peak ], 'color', orange, 'linewidth', 2, 'LineStyle', '--');

yl = ylabel('Number of cases');
xl = xlabel('Time (days)');

leg = { 'Active (fitted)',...
        'Recoveries (fitted)','Deaths (fitted)',...
        'Active + Potential Infected', 'Active (reported)','Recoveries (reported)','Deaths  (reported)'};

ll = legend([q1, r1, d1, i1, qr, rr, dr], leg{:}, 'Location','NorthWest'); % 'Country','SouthWest'

date_str = datestr(time_fit(end));
title_srt = sprintf('%s %s, SEIR model is fitted with %d days,\n forecasted %d days from %s', Country, Province, DAYS, FORECAST, date_str(1:11) );
tl =  title(title_srt);

set(gcf,'color','w')

grid on

% axis tight

xlim([time_sim(1) time_sim(end) ])

set(gca,'yscale','lin')
% set(gca,'yscale','log')

text_box = sprintf('%s.\n%s.\n%s.\n%s.', Q_fore_str, I_fore_str, doubling_str, brn_str);

annotation('textbox', [0.4, 0.735, 0.1, 0.1], 'string', text_box, ...
    'LineStyle','-',...
    'FontSize', 20,...
    'FontName','Arial');
%     'FontWeight','bold',...

set(gca, 'XTickMode', 'manual', 'YTickMode', 'auto', 'XTick', time(1):2:time_sim(end), 'FontSize', font_tick, 'XTickLabelRotation', 45);

set(tl,'FontSize', font_title);
set(xl,'FontSize', font_label);
set(yl,'FontSize', font_label);
set(ll,'FontSize', font_legend);

file_str = sprintf('./png/%s_covid-19_forecast_from_present_%s.png', Country, datetime() );

set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
saveas(gcf,file_str)

%% WRITE TO CSV

tt = [time_fit time_fore]';
qq = [q_fit q_fore]';
ii = [i_fit i_fore]';
rr = [r_fit r_fore]';
dd = [d_fit d_fore]';

file_str = sprintf('./csv/%s_covid-19_fit_forecast_%s.csv', Country, date() );

fid = fopen(file_str, 'w');
fprintf(fid, '%s, %s, %s, %s, %s,\n', 'Date', 'Active', 'Recoveries', 'Deaths', 'Infected') ; % Print the time string

for idx = 1:size(qq, 1)  % Loop through each time/value row size(qq, 1)
    
   fprintf(fid, '%s,', datestr ( tt(idx,:) , 31 ) ) ; % date
   fprintf(fid, '%12.5f,', qq(idx) ) ; % active
   fprintf(fid, '%12.5f,', rr(idx) ) ; % active
   fprintf(fid, '%12.5f,', dd(idx) ) ; % active
   fprintf(fid, '%12.5f,', ii(idx) ) ; % active
   fprintf(fid, '\n' ) ; % active
end

fclose(fid) ;

file_str = sprintf('./csv/%s_covid-19_reported_%s.csv', Country, date() );

fid = fopen(file_str, 'w');
fprintf(fid, '%s, %s, %s, %s,\n', 'Date', 'Active', 'Recoveries', 'Deaths') ; % Print the time string

for idx = 1:size(Active, 2)  % Loop through each time/value row size(qq, 1)
    
   fprintf(fid, '%s,', datestr ( time(1, idx) , 31 ) ) ; % date
   fprintf(fid, '%12.5f,', Active(idx) ) ; % active
   fprintf(fid, '%12.5f,', Recovered(idx) ) ; % active
   fprintf(fid, '%12.5f,', Deaths(idx) ) ; % active
   fprintf(fid, '\n' ) ; % active
end




