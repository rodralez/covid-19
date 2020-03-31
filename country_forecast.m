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

% Location = 'Hubei';
% Npop = 14e6; % population

% Location = 'Italy';
% Npop = 60.48e6; % population

% Location = 'Spain';
% Npop = 46.66e6; % population

Location = 'Argentina';
Npop= 45e6; % population

fprintf(['Country: ', Location,'\n'] );

%% SOURCE

% source = 'online' ;
source = 'offline' ;

[tableConfirmed,tableDeaths,tableRecovered,time] = get_data_covid_hopkins( source );

%% FIND COUNTRY

try
    indR = find(contains(tableRecovered.CountryRegion,Location)==1);
    indC = find(contains(tableConfirmed.CountryRegion,Location)==1);
    indD = find(contains(tableDeaths.CountryRegion,Location)==1);
catch exception
    searchLoc = strfind(tableRecovered.ProvinceState,Location);
    indR = find([searchLoc{:}]==1);
    
    searchLoc = strfind(tableConfirmed.ProvinceState,Location);
    indC = find([searchLoc{:}]==1);
    
    searchLoc = strfind(tableConfirmed.ProvinceState,Location);
    indD = find([searchLoc{:}]==1);  
    
end

if (isempty(indR))
    
    error('%s was not found in COVID data!', Location)    
    
end


%% FIND FIRST 50 CASES

% If the number of confirmed Confirmed cases is small, it is difficult to know whether
% the quarantine has been rigorously applied or not. In addition, this
% suggests that the number of infectious is much larger than the number of
% confirmed cases

Recovered = table2array(tableRecovered(indR,5:end));
Deaths = table2array(tableDeaths(indD,5:end));
Confirmed = table2array(tableConfirmed(indC,5:end));

minNum = 50;
Recovered(Confirmed<=minNum)=[];
Deaths(Confirmed<=minNum)=[];
time(Confirmed<=minNum)= [];
Confirmed(Confirmed<=minNum)=[];

%% FORECAST SCENARIO

START = 1; % 01/03/2020
DAYS = 14; 
FORECAST = 15;

fprintf(['Time series start on ',datestr(time(1)),'\n'] );
fprintf(['Time series stop on ',datestr(time(DAYS)),'\n'] );
fprintf(['Time series forecast ', (DAYS+FORECAST) ,'\n'] );
% fprintf(['Time series forecast until ',datestr(time(DAYS+FORECAST)),'\n'] );

%% FIT WITH DAYS

% Definition of the first estimates for the parameters
guess.alpha = 1; % protection rate
guess.beta = 1.0; % Infection rate
guess.LT = 5; % latent time in days
guess.QT = 14; % quarantine time in days
guess.lambda = [0.05, 0.1]; % recovery rate
guess.kappa  = [0.1, 0.1]; % death rate

Confirmed_short = Confirmed(1:DAYS);
Recovered_short = Recovered(1:DAYS);
Deaths_short    = Deaths(1:DAYS);

param_short = my_fit_SEIQRDP(Confirmed_short, Recovered_short, Deaths_short, Npop, time(1:DAYS), guess);

BRN = param_short.beta / param_short.delta * (1 - param_short.alpha)^DAYS; 

fprintf( 'Basic Reproduction Number (BRN) is %f \n', BRN );

%% FORECAST Simulate the epidemy outbreak based on the fitted parameters

% Initial conditions
E0 = Confirmed(1); % Initial number of exposed cases. Unknown but unlikely to be zero.
I0 = Confirmed(1); % Initial number of infectious cases. Unknown but unlikely to be zero.
Q0 = Confirmed(1);
R0 = Recovered(1);
D0 = Deaths(1);

dt = 0.1; % time step

time_sim = datetime(time(1)):dt:datetime(time(DAYS+FORECAST));

% time_sim  = datetime(time(1)):dt:datetime( datestr(floor(datenum(now)) + datenum(FORECAST)) );

N = numel(time_sim);
t1 = (0:N-1).*dt;

[S1,E1,I1,Q1,R1,D1,P1] = my_SEIQRDP(param_short, Npop, E0, I0, Q0, R0, D0, t1);

%% Comparison of the fitted and real data

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

Infected = Confirmed-Recovered-Deaths;
infected_peak = max (Infected);

figure

time_fit  = time_sim (time_sim < time(DAYS));
time_fore = time_sim (time_sim > time(DAYS));

q_fit  = Q1(time_sim < time(DAYS));
q_fore = Q1(time_sim > time(DAYS));

r_fit  = R1(time_sim < time(DAYS));
r_fore = R1(time_sim > time(DAYS));

d_fit  = D1(time_sim < time(DAYS));
d_fore = D1(time_sim > time(DAYS));

q1 = semilogy(time_fit,  q_fit,  'color', red_dark, 'LineWidth', line_width);
hold on
     semilogy(time_fore, q_fore, 'color', red_dark, 'LineWidth', line_width, 'LineStyle', '--');

r1 = semilogy(time_fit,  r_fit,  'color', blue, 'LineWidth', line_width);
     semilogy(time_fore, r_fore, 'color', blue, 'LineWidth', line_width, 'LineStyle', '--');

d1 = semilogy(time_fit,  d_fit,  'k', 'LineWidth', line_width);
     semilogy(time_fore, d_fore, 'k', 'LineWidth', line_width, 'LineStyle', '--');

qr = semilogy(time, Infected, 'color', red_dark, 'Marker', 'o', 'LineStyle', 'none', 'LineWidth', line_width);
rr = semilogy(time, Recovered,'color', blue, 'Marker', 'o', 'LineStyle', 'none', 'LineWidth', line_width);
dr = semilogy(time, Deaths,'ko', 'LineWidth', line_width);

% l1_fit = line ([time(1) time(1)], [0 infected_peak], 'color', blue, 'linewidth', 2, 'LineStyle', '--');
% 
% l2_fit = line ([time(DAYS) time(DAYS)], [0 infected_peak ], 'color', blue, 'linewidth', 2, 'LineStyle', '--');
% 
% l1_fore = line ([time(DAYS+1) time(DAYS+1)], [0 infected_peak], 'color', orange, 'linewidth', 2, 'LineStyle', '--');
% 
% l2_fore = line ([time(DAYS+FORECAST) time(DAYS+FORECAST)], [0 infected_peak ], 'color', orange, 'linewidth', 2, 'LineStyle', '--');

yl = ylabel('Number of cases');
xl = xlabel('Time (days)');

leg = {  'Infected (fitted)',...
        'Recovered (fitted)','Deceased (fitted)',...
        'Infected (reported)','Recovered (reported)','Deceased  (reported)'};

ll = legend([q1, r1, d1, qr, rr, dr], leg{:}, 'location','NorthWest'); % 'location','SouthWest'

title_srt = sprintf('%s, SEIR model fitted with \n%d days, forecast %d days', Location, DAYS, FORECAST);
tl =  title(title_srt);

set(gcf,'color','w')

grid on

% axis tight
xlim([time(1) time(end) ])

set(gca,'yscale','lin')

days_str = sprintf('SEIR fits from %s to %s', datestr( time(1) ), datestr( time(DAYS) ) );
fore_str = sprintf('and forecasts from %s to %s.', datestr( time(DAYS+1) ), datestr( time(DAYS) + datenum(FORECAST)) );
infec_fore_srt = sprintf('SEIR predicts %d infected on %s',  round( (Q1(end))), datestr( time(DAYS) + datenum(FORECAST)) );
infec_repo_srt = sprintf('and in fact there were %d on this day.',  Infected (DAYS+FORECAST) );

text_box = sprintf('%s\n%s\n%s\n%s', days_str , fore_str, infec_fore_srt, infec_repo_srt);

annotation('textbox', [0.14, 0.40, 0.1, 0.1], 'string', text_box, ...
    'LineStyle','none',...
    'FontSize', 20,...
    'FontName','Arial');
%     'FontWeight','bold',...

set(gca, 'XTickMode', 'manual', 'YTickMode', 'auto', 'XTick', time(1):2:time(end), 'FontSize', font_tick, 'XTickLabelRotation', 45);

set(tl,'FontSize', font_title);
set(xl,'FontSize', font_label);
set(yl,'FontSize', font_label);
set(ll,'FontSize', font_legend);

file_str = sprintf('%s_covid-19_forecast.png', Location );

set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
saveas(gcf,file_str)


