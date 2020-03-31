%% Example: COVID-2019 data for South korea  (22-Jan-2020 - )
% I am taking some data, collected into DATA.mat from John Hopkins university 
% [1]
% 
% [1] <https://github.com/CSSEGISandData/COVID-19 https://github.com/CSSEGISandData/COVID-19>

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

%% SOURCE

% source = 'online' ;
source = 'offline' ;

[tableConfirmed,tableDeaths,tableRecovered,time] = get_data_covid_hopkins( source );

% [tableConfirmed,tableDeaths,tableRecovered,time] = get_data_covid_harpomaxx( source );

% time = time(1:end-1);
fprintf(['Most recent update: ',datestr(time(end)),'\n'])

%% COUNTRY

Location = 'Italy';
Npop= 60.48e6; % population

try
    indR = find(contains(tableRecovered.CountryRegion,Location)==1);
    indC = find(contains(tableConfirmed.CountryRegion,Location)==1);
    indD = find(contains(tableDeaths.CountryRegion,Location)==1);
catch exception
    searchLoc = strfind(tableRecovered.CountryRegion,Location);
    indR = find([searchLoc{:}]==1);
    
    searchLoc = strfind(tableConfirmed.CountryRegion,Location);
    indC = find([searchLoc{:}]==1);
    
    searchLoc = strfind(tableConfirmed.CountryRegion,Location);
    indD = find([searchLoc{:}]==1);
end

% tableRecovered(indR,1:2)
% indR = indR(1)

Recovered = table2array(tableRecovered(indR,5:end));
Deaths = table2array(tableDeaths(indD,5:end));
Confirmed = table2array(tableConfirmed(indC,5:end));

% If the number of confirmed Confirmed cases is small, it is difficult to know whether
% the quarantine has been rigorously applied or not. In addition, this
% suggests that the number of infectious is much larger than the number of
% confirmed cases

minNum= 50;
Recovered(Confirmed<=minNum)=[];
Deaths(Confirmed<=minNum)=[];
time(Confirmed<=minNum)= [];
Confirmed(Confirmed<=minNum)=[];

%% Fitting of the generalized SEIR model to the real data

% Definition of the first estimates for the parameters
alpha_guess = 0.06; % protection rate
beta_guess = 1.0; % Infection rate
LT_guess = 5; % latent time in days
QT_guess = 10; % quarantine time in days
lambda_guess = [0.1,0.05]; % recovery rate
kappa_guess = [0.1,0.05]; % death rate

guess = [alpha_guess,...
    beta_guess,...
    1/LT_guess,...
    1/QT_guess,...
    lambda_guess,...
    kappa_guess];

% Initial conditions
E0 = Confirmed(1); % Initial number of exposed cases. Unknown but unlikely to be zero.
I0 = Confirmed(1); % Initial number of infectious cases. Unknown but unlikely to be zero.
Q0 = Confirmed(1);
R0 = Recovered(1);
D0 = Deaths(1);

[alpha1, beta1, gamma1, delta1, Lambda1, Kappa1] = ...
    fit_SEIQRDP(Confirmed-Recovered-Deaths, Recovered, Deaths, Npop, E0, I0, time, guess);



%% Simulate the epidemy outbreak based on the fitted parameters

dt = 1; % time step

time1 = datetime(time(1)):dt:datetime( datestr(floor(datenum(now)) + datenum(15)) );

N = numel(time1);

t = [0:N-1].*dt;

[S,E,I,Q,R,D,P] = SEIQRDP(alpha1,beta1,gamma1,delta1,Lambda1,Kappa1,Npop,E0,I0,Q0,R0,D0,t);


 %% ANALYSIS
 
 format bank
  
 infectados_pico = (max(Q))
 decesos_pico = (max(D))
 dia_pico = time1(Q == infectados_pico)
 
 
%%

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
font_legend = 20;
font_title = 40;

figure

semilogy(time1, Q,'r',time1, R,'b',time1, D,'k', 'linewidth', 2);

hold on

semilogy(time, Confirmed-Recovered-Deaths,'ro', time, Recovered,'bo', time, Deaths,'ko', 'linewidth', 2);

l1 = line ([dia_pico dia_pico], [0 infectados_pico], 'color', orange, 'linewidth', 2, 'LineStyle', '--');

% ylim([0,1.1*Npop])

str1 = sprintf('Predicción de casos de \nCOVID-19 en %s', Location);
tl =  title(str1);

% leg = {'Confirmed (fitted)',...
%         'Recovered (fitted)','Deceased (fitted)',...
%         'Confirmed (reported)','Recovered (reported)','Deceased  (reported)'};

leg = {'Infectados actuales (estimados)',...
        'Curados (estimados)','Decesos (estimados)',...
        'Infectados actuales  (reportados)','Curados (reportados)','Decesos  (reportados)'};
    
% yl = ylabel('Number of cases');
% xl = xlabel('Time (days)');

yl = ylabel('Número de casos');
xl = xlabel('Tiempo (días)');


ll = legend(leg{:},'location','SouthEast');

set(gcf,'color','w')

str2 = sprintf('Se espera un pico de infectados de %d el día %s', round(infectados_pico), datestr(dia_pico));

% x y width height
annotation('textbox', [0.14, 0.68, 0.1, 0.1], 'string', str2, ...
    'LineStyle','-',...
    'FontWeight','bold',...
    'FontSize', 20,...
    'FontName','Arial');

grid on
% axis tight
% ylim([1,8e4])
 
set(gca,'yscale','lin')
set(gca, 'YTickMode', 'auto', 'FontSize', font_tick, 'XTickLabelRotation', 45);

set(tl,'FontSize', font_title);
set(xl,'FontSize', font_label);
set(yl,'FontSize', font_label);
set(ll,'FontSize', font_legend);

set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
saveas(gcf,'argentina_covid-19_forecast.png')

 

 
 
 