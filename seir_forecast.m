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

Province = '';
% Country = 'Germany';
% Country = 'Brazil';
% Country = 'Ecuador';
% Country = 'Chile';
% Country = 'Turkey';
% Country = 'Spain';
% Country = 'Italy';
% Country = 'France';
Country = 'Argentina';
% Country = 'Singapore';
% Country = 'Korea, South';

% Country = 'China';
% Province = 'Hubei';

%% SOURCE

% source = 'online' ;
source = 'offline' ;

[tableConfirmed,tableDeaths,tableRecovered,time] = get_covid_global_hopkins( source, './hopkins/' );

% [tableConfirmed,tableDeaths,time] = get_covid_global_hopkins( source );

%% FITTIN INTERVAL
% 
% FIT_UNTIL =  datenum(2020, 3, 31);
% FORECAST = 4; % DAYS TO FORECAST 

FIT_UNTIL =  datenum(2020, 4, 4);
FORECAST = 7; % DAYS TO FORECAST 

%% FIND COUNTRY

try
    indC = find( contains(  tableConfirmed.CountryRegion, Country) == 1 );
    indC = indC( ismissing( tableConfirmed.ProvinceState(indC), Province) );

    % Population
    Npop = tableConfirmed.Population (indC); 
 
    indR = find( contains(  tableRecovered.CountryRegion, Country) == 1 );
    indR = indR( ismissing( tableRecovered.ProvinceState(indR), Province) );
   
    indD = find(contains(   tableDeaths.CountryRegion, Country)==1);
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

Confirmed = table2array(tableConfirmed(indC, 4:end));
Recovered = table2array(tableRecovered(indR, 4:end));
Deaths    = table2array(tableDeaths(indD, 4:end));

minNum = 50;
time(Confirmed <= minNum)= [];
Recovered(Confirmed <= minNum)=[];
Deaths(Confirmed <= minNum)=[];
Confirmed(Confirmed <= minNum)=[];

DAYS = length(time);

%% FITTING

% Initial conditions
E0 = Confirmed(1)  ; % Initial number of exposed cases. Unknown but unlikely to be zero.
I0 = Confirmed(1)  ; % Initial number of infectious cases. Unknown but unlikely to be zero.

guess.LT = 5; % latent time in days, incubation period, gamma^(-1)
guess.QT = 4; % quarantine time in days, infectious period, delta^(-1)

% Definition of the first estimates for the parameters
guess.alpha = 1.0; % protection rate
guess.beta  = 1.0; % Infection rate

guess.lambda = [0.5, 0.05]; % recovery rate
guess.kappa  = [0.1, 0.05]; % death rate

tdx = datefind( FIT_UNTIL, time);

param_fit = my_fit_SEIQRDP(Confirmed(1:tdx), Recovered(1:tdx), Deaths(1:tdx), Npop, E0, I0, time(1:tdx), guess);

Active = Confirmed-Recovered-Deaths;

%% FORECAST Simulate the epidemy outbreak based on the fitted parameters

% Initial conditions
E0 = Confirmed(1) * 1.0; % Initial number of exposed cases. Unknown but unlikely to be zero.
I0 = Confirmed(1) * 1.0; % Initial number of infectious cases. Unknown but unlikely to be zero.
Q0 = Confirmed(1) ;

R0 = Recovered(1);
D0 = Deaths(1);

dt = 0.1; % time step

time_sim  = datetime( time(1) ):dt:datetime( time(tdx) + FORECAST );

N = numel(time_sim);
t1 = (0:N-1).*dt;

[S1,E1,I1,Q1,R1,D1,P1] = my_SEIQRDP(param_fit, Npop, E0, I0, Q0, R0, D0, t1);

C1 = Q1 + R1 + D1 ;

%% DOUBLING ANALYSYS

fdx = find ( Active >= Active(end)/2, 1, 'first');
doubling = datenum ( time(end)- time(fdx) );

%% PRINT

fprintf(['Country: ', Country,'\n'] );

fprintf(['Time series start on ',datestr(time(1)),'\n'] );
fprintf(['Time series stop on ' ,datestr(time(end)),'\n'] );
fprintf('Time series forecast %d days\n', FORECAST );

% BRN = param_fit.beta / param_fit.delta * (1 - param_fit.alpha)^DAYS; 
BRN = param_fit.beta / param_fit.gamma ; 

model_str   = sprintf( 'GeSEIR predicts on %s:', datestr( time_sim(end) ) );
c_fore_str  = sprintf( '%d confirmed cases (%+d)', round( C1(end) ) , round( C1(end) - Confirmed(end) ) );
q_fore_str  = sprintf( '%d active cases (%+d)', round( Q1(end) ) , round( Q1(end) - Active(end) ) );
r_fore_str  = sprintf( '%d recoveries (%+d)', round( R1(end) ) , round( R1(end) - Recovered(end) ) );
d_fore_str  = sprintf( '%d deaths (%+d)', round( D1(end) ) , round( D1(end) - Deaths(end) ) );

i_fore_str  = sprintf( '%d potential active cases', round( Q1(end) + I1(end) ) );

Q_fore_str  = sprintf( 'Models predicts %d active cases on %s', round( (Q1(end)) ), datestr( time_sim(end) ) );
N_fore_str  = sprintf( 'Models predicts new %d active cases on %s', round( (Q1(end)) - Active(end) ), datestr( time_sim(end) ) );
I_fore_str  = sprintf( 'Models predicts %d potential infected on %s', round( Q1(end) + I1(end) ), datestr( time_sim(end) ) );
doub_str  = sprintf( 'Active cases are doubled in %d days', doubling );
ro_str     = sprintf( 'Ro: %.2f', BRN );
alpha_str   = sprintf( 'alpha : %.2f', param_fit.alpha );
beta_str    = sprintf( 'beta: %.2f', param_fit.beta );
gamma_str   = sprintf( 'gamma^-1: %.1f days', 1/param_fit.gamma);
delta_str   = sprintf( 'delta^-1: %.1f days', 1/param_fit.delta);
lambda_str  = sprintf( 'Recovery rate: %.2f%%', param_fit.lambda(1)*100  );
kappa_str   = sprintf( 'Death rate: %.2f%%', param_fit.kappa(1)*100 );

fprintf( '\n %s \n', Q_fore_str );
fprintf( ' %s \n', I_fore_str );
fprintf( ' %s \n', N_fore_str );
fprintf( ' %s \n', ro_str );
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
gray = ones(1,3) * 0.5;
red_dark =  [0.6350, 0.0780, 0.1840] ;


font_title = 33;
font_label = 27;
font_tick  = 21;
font_legend = 16;

font_point = 12;
line_width = 2.5;
line_width_pt= 2;
mks = 9;

figure

time_fit  = time_sim (time_sim <= time(tdx));
time_fore = time_sim (time_sim > time(tdx));

q_fit  = Q1(time_sim <= time(tdx));
q_fore = Q1(time_sim > time(tdx));

i_fit  = I1(time_sim <= time(tdx)) + q_fit;
i_fore = I1(time_sim > time(tdx))  + q_fore;

r_fit  = R1(time_sim <= time(tdx));
r_fore = R1(time_sim > time(tdx));

d_fit  = D1(time_sim <= time(tdx));
d_fore = D1(time_sim > time(tdx));

c_fit = q_fit + r_fit + d_fit;
c_fore = q_fore + r_fore + d_fore;

ldx = contains( cellstr( datestr(time_fore) ), '00:00:00');
time_fore_pt = time_fore( ldx );
c_fore_pt = c_fore( ldx );
q_fore_pt = q_fore( ldx );
r_fore_pt = r_fore( ldx );
d_fore_pt = d_fore( ldx );

q1 = semilogy(time_fit,  q_fit,  'color', red_dark, 'LineWidth', line_width);
hold on
%      semilogy(time_fore, q_fore, 'color', red_dark, 'LineWidth', line_width, 'LineStyle', '--');

r1 = semilogy(time_fit,  r_fit,  'color', blue, 'LineWidth', line_width);
%      semilogy(time_fore, r_fore, 'color', blue, 'LineWidth', line_width, 'LineStyle', '--');

d1 = semilogy(time_fit,  d_fit,  'k', 'LineWidth', line_width);
%      semilogy(time_fore, d_fore, 'k', 'LineWidth', line_width, 'LineStyle', '--');

c1 = semilogy(time_fit,  c_fit,  'color', green, 'LineWidth', line_width);
%      semilogy(time_fore, c_fore, 'color', green, 'LineWidth', line_width, 'LineStyle', '--');

i1 = semilogy(time_fit,  i_fit,  'color', orange, 'LineWidth', line_width, 'LineStyle', '--');
     semilogy(time_fore, i_fore, 'color', orange, 'LineWidth', line_width, 'LineStyle', '--');
     
cp = semilogy(time_fore_pt, c_fore_pt, 'color', green, 'Marker','x', 'LineStyle', 'none', 'LineWidth', line_width_pt,'MarkerSize', mks); 
qp = semilogy(time_fore_pt, q_fore_pt, 'color', red_dark, 'Marker','x', 'LineStyle', 'none', 'LineWidth', line_width_pt,'MarkerSize', mks); 
rp = semilogy(time_fore_pt, r_fore_pt, 'color', blue, 'Marker','x', 'LineStyle', 'none', 'LineWidth', line_width_pt,'MarkerSize', mks); 
dp = semilogy(time_fore_pt, d_fore_pt, 'color', 'black', 'Marker','x', 'LineStyle', 'none', 'LineWidth', line_width_pt,'MarkerSize', mks); 

cr = semilogy(time, Confirmed, 'color', green, 'Marker', 'o', 'LineStyle', 'none', 'LineWidth', line_width_pt, 'MarkerSize', mks);     
qr = semilogy(time, Active, 'color', red_dark, 'Marker', 'o', 'LineStyle', 'none', 'LineWidth', line_width_pt, 'MarkerSize', mks); 
rr = semilogy(time, Recovered,'color', blue, 'Marker', 'o', 'LineStyle', 'none', 'LineWidth', line_width_pt, 'MarkerSize', mks); 
dr = semilogy(time, Deaths,'ko', 'LineWidth', line_width);

% l1_fit = line ([time(1) time(1)], [0 infected_peak], 'color', blue, 'linewidth', 2, 'LineStyle', '--');
% l2_fit = line ([time(DAYS) time(DAYS)], [0 infected_peak ], 'color', blue, 'linewidth', 2, 'LineStyle', '--');
% l1_fore = line ([time(DAYS+1) time(DAYS+1)], [0 infected_peak], 'color', orange, 'linewidth', 2, 'LineStyle', '--');
% l2_fore = line ([time(DAYS+FORECAST) time(DAYS+FORECAST)], [0 infected_peak ], 'color', orange, 'linewidth', 2, 'LineStyle', '--');

yl = ylabel('Number of cases');
xl = xlabel('Time (days)');

% LEGEND
%-------------------------------------------------------------------------- 
leg = { 'Confirmed (fitted)', 'Active (fitted)', ...
        'Recoveries (fitted)','Deaths (fitted)',...
        'Active + Potential Infected', ... 
        'Confirmed (reported)', 'Active (reported)', ... 
        'Recoveries (reported)','Deaths (reported)'};

ll = legend([c1, q1, r1, d1, i1, cr, qr, rr, dr], leg{:}, 'Location','NorthWest'); % 'Country','SouthWest'
%--------------------------------------------------------------------------

% TITLE
%--------------------------------------------------------------------------
date_str = datestr(time_fit(end));

if (strcmp(Province, ''))
    title_srt = sprintf('%s, GeSEIR model is fitted with %d days,\n forecasted %d days from %s', Country, DAYS, FORECAST, date_str(1:11) );
else
    title_srt = sprintf('%s (%s), GeSEIR model is fitted with %d days,\n forecasted %d days from %s', Province, Country, DAYS, FORECAST, date_str(1:11) );
end

tl =  title(title_srt);
%--------------------------------------------------------------------------

set(gcf,'color','w')
set(gca,'yscale','lin')
% set(gca,'yscale','log')

grid on

xlim([time_sim(1) time_sim(end) ])

set(gca, 'XTickMode', 'manual', 'YTickMode', 'auto', 'XTick', time(1):2:time_sim(end), 'FontSize', font_tick, 'XTickLabelRotation', 45);

set(tl,'FontSize', font_title);
set(xl,'FontSize', font_label);
set(yl,'FontSize', font_label);
set(ll,'FontSize', font_legend);

% TEXT BOX
%--------------------------------------------------------------------------
text_box = sprintf('%s\n  * %s.\n  * %s.\n  * %s.\n  * %s.\n  * %s.\n%s.', model_str, ... 
        c_fore_str, q_fore_str, r_fore_str, d_fore_str, i_fore_str, doub_str);

annotation('textbox', [0.36, 0.735, 0.1, 0.1], 'string', text_box, ...
    'LineStyle','-',...
    'FontSize', font_legend,...
    'FontName','Arial');
%     'FontWeight','bold',...
%--------------------------------------------------------------------------

% Points
%--------------------------------------------------------------------------

cr = semilogy(time, Confirmed, 'color', green, 'Marker', 'o', 'LineStyle', 'none', 'LineWidth', line_width_pt, 'MarkerSize', mks);     
qr = semilogy(time, Active, 'color', red_dark, 'Marker', 'o', 'LineStyle', 'none', 'LineWidth', line_width_pt, 'MarkerSize', mks); 
rr = semilogy(time, Recovered,'color', blue, 'Marker', 'o', 'LineStyle', 'none', 'LineWidth', line_width_pt, 'MarkerSize', mks); 
dr = semilogy(time, Deaths,'ko', 'LineWidth', line_width);

py = -60;
B = 5;
for i = size(Active, 2)-B : size(Active, 2)
    text(time(i), Active(i) + py, sprintf('%d', Active(i)), 'FontSize',  font_point, 'color', red_dark);
end

for i = size(Confirmed, 2)-B: size(Confirmed, 2)
    text(time(i), Confirmed(i) + py, sprintf('%d', Confirmed(i)), 'FontSize',  font_point, 'color', green);
end

for i = size(Recovered, 2)-B: size(Recovered, 2)
    text(time(i), Recovered(i)+py, sprintf('%d', Recovered(i)), 'FontSize',  font_point, 'color', blue);
end

for i = size(Deaths, 2)-B: size(Deaths, 2)
    text(time(i), Deaths(i)+py, sprintf('%d', Deaths(i)), 'FontSize',  font_point, 'color', 'black');
end

py = 60;
T = 0.1;
for i = 1 : size(c_fore_pt, 2)
    text(time_fore_pt(i)-T, c_fore_pt(i)+py, sprintf('%d', round( c_fore_pt(i)) ), 'FontSize',  font_point, 'Color', gray);
end

for i = 1 : size(q_fore_pt, 2)
    text(time_fore_pt(i)-T, q_fore_pt(i)+py, sprintf('%d', round( q_fore_pt(i)) ), 'FontSize',  font_point, 'Color', gray);
end

for i = 1 : size(r_fore_pt, 2)
    text(time_fore_pt(i)-T, r_fore_pt(i)+py, sprintf('%d', round( r_fore_pt(i)) ), 'FontSize',  font_point, 'Color', gray);
end

for i = 1 : size(d_fore_pt, 2)
    text(time_fore_pt(i)-T, d_fore_pt(i)+py, sprintf('%d', round( d_fore_pt(i)) ), 'FontSize',  font_point, 'Color', gray);
end
%--------------------------------------------------------------------------


%% SAVE FIGURE TO PNG FILE

file_name = sprintf('%s_covid-19_fit_forecast_%s', Country, datestr( FIT_UNTIL ) );

file_str = sprintf('./png/%s.png', file_name );

set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);

saveas(gcf,file_str)


%% SAVE DATA TO CSV FILE

tt = [time_fit time_fore]';
qq = [q_fit q_fore]';
ii = [i_fit i_fore]';
rr = [r_fit r_fore]';
dd = [d_fit d_fore]';

file_str = sprintf('./csv/%s.csv', file_name );

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

cp_command = sprintf('cp %s ./csv/%s_covid-19_fit_forecast_lastest.csv', file_str, Country );
ret = system(cp_command);
if ret ~= 0
    error('cp error!');
end

%--------------------------------------------------------------------------

file_name = sprintf('%s_covid-19_reported_%s', Country, datestr( FIT_UNTIL ) );

file_str = sprintf('./csv/%s.csv', file_name);

fid = fopen(file_str, 'w');
fprintf(fid, '%s, %s, %s, %s,\n', 'Date', 'Active', 'Recoveries', 'Deaths') ; % Print the time string

for idx = 1:size(time(1:tdx), 2)  % Loop through each time/value row size(qq, 1)
    
   fprintf(fid, '%s,',     datestr ( time(1, idx) , 31 ) ) ; % date
   fprintf(fid, '%12.5f,', Active(idx) ) ; % active
   fprintf(fid, '%12.5f,', Recovered(idx) ) ; % active
   fprintf(fid, '%12.5f,', Deaths(idx) ) ; % active
   fprintf(fid, '\n' ) ; % active
end

cp_command = sprintf('cp %s ./csv/%s_covid-19_reported_lastest.csv', file_str, Country );
ret = system(cp_command);
if ret ~= 0
    error('cp error!');
end
