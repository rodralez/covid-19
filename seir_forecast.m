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

addpath ./num2sip

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
Country = 'Argentina';
% Country = 'Spain';
% Country = 'Italy';
% Country = 'Germany';
% Country = 'Brazil';
% Country = 'Ecuador';
% Country = 'Chile';
% Country = 'Turkey';
% Country = 'France';
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

% MODEL_EVAL = 'ON';
if (~exist('MODEL_EVAL','var')),  MODEL_EVAL  = 'OFF'; end

% FIT_UNTIL =  datenum(2020, 3, 28);
% FORECAST = 7; % DAYS TO FORECAST
% DAYS_BACK = 5;
    
FIT_UNTIL =  datenum(2020, 4, 5);
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

guess.LT = 5; % 1-14 days, latent time in days, incubation period, gamma^(-1)
guess.QT = 6; % 2 weeks, quarantine time in days, recovery time, infectious period, delta^(-1)

% Definition of the first estimates for the parameters
guess.alpha = 1.0; % protection rate
guess.beta  = 1.0; % Infection rate

guess.lambda = [0.5, 0.1]; % recovery rate
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

dt = 1/24; % time step

time_sim  = datetime( time(1) ): dt : datetime( time(tdx) + FORECAST );

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
% ro_str     = sprintf( 'Ro: %.2f', BRN );
alpha_str   = sprintf( 'alpha : %.2f', param_fit.alpha );
beta_str    = sprintf( 'beta: %.2f', param_fit.beta );
gamma_str   = sprintf( 'gamma^-1: %.1f days', 1/param_fit.gamma);
delta_str   = sprintf( 'delta^-1: %.1f days', 1/param_fit.delta);
lambda_str  = sprintf( 'Recovery rate: [%f %f]', param_fit.lambda(1), param_fit.lambda(2) );
kappa_str   = sprintf( 'Death rate: [%f %f]', param_fit.kappa(1), param_fit.kappa(2) );

fprintf( '\n %s \n', Q_fore_str );
fprintf( ' %s \n', I_fore_str );
fprintf( ' %s \n', N_fore_str );
% fprintf( ' %s \n', ro_str );
fprintf( ' %s \n', alpha_str );
fprintf( ' %s \n', beta_str );
fprintf( ' %s \n', gamma_str );
fprintf( ' %s \n', delta_str );
fprintf( ' %s \n', lambda_str );
fprintf( ' %s \n', kappa_str );

%% PLOT

%--------------------------------------------------------------------------
% COLORS
%--------------------------------------------------------------------------
blue = [0, 0.4470, 0.7410];
orange = [0.8500, 0.3250, 0.0980];
yellow = [0.9290, 0.6940, 0.1250] ;
purple = [0.4940, 0.1840, 0.5560];
green =  [0.4660, 0.6740, 0.1880];
blue_light = [0.3010, 0.7450, 0.9330] ;
gray = ones(1,3) * 0.5;
red_dark =  [0.6350, 0.0780, 0.1840] ;

%--------------------------------------------------------------------------
% FONT SIZE, LINE WIDTH, POINT WIDTH
%--------------------------------------------------------------------------

font_title = 30;
font_label = 25;
font_tick  = 20;
font_legend = 16;
font_point = 13;

line_width = 2.5;
line_width_pt= 2;
mks = 9;

%--------------------------------------------------------------------------
% VECTOR INDEX FOR FIGURE
%--------------------------------------------------------------------------

fodx = time_sim > time( tdx );
fopx = contains( cellstr( datestr( time_sim ) ), '00:00:00') & fodx';

if strcmp (MODEL_EVAL, 'OFF')
    
    fidx = time_sim <= time(tdx);
    rdx = time == time;
else
    fidx = time_sim >= time(tdx-DAYS_BACK) & time_sim <= time(tdx) ;
    rdx = time >= time(tdx-DAYS_BACK);
end

%--------------------------------------------------------------------------

figure

%--------------------------------------------------------------------------
% FITING, LINES
%--------------------------------------------------------------------------

q1 = semilogy(time_sim (fidx), Q1 (fidx),  'color', red_dark, 'LineWidth', line_width);
hold on

r1 = semilogy(time_sim (fidx), R1 (fidx),  'color', blue, 'LineWidth', line_width);

d1 = semilogy(time_sim (fidx), D1 (fidx),  'k', 'LineWidth', line_width);

c1 = semilogy(time_sim (fidx), C1 (fidx),  'color', green, 'LineWidth', line_width);

if strcmp (MODEL_EVAL, 'OFF')
    
    i1 = semilogy(time_sim (fidx), Q1(fidx) + I1 (fidx),  'color', orange, 'LineWidth', line_width, 'LineStyle', '--');
    semilogy(time_sim (fodx), Q1(fodx) + I1 (fodx), 'color', orange, 'LineWidth', line_width, 'LineStyle', '--');
end

%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% FORECASTING, POINTS
%--------------------------------------------------------------------------

cp = semilogy(time_sim (fopx), C1(fopx), 'color', green, 'Marker','x', 'LineStyle', 'none', 'LineWidth', line_width_pt,'MarkerSize', mks);
qp = semilogy(time_sim (fopx), Q1(fopx), 'color', red_dark, 'Marker','x', 'LineStyle', 'none', 'LineWidth', line_width_pt,'MarkerSize', mks);
rp = semilogy(time_sim (fopx), R1(fopx), 'color', blue, 'Marker','x', 'LineStyle', 'none', 'LineWidth', line_width_pt,'MarkerSize', mks);
dp = semilogy(time_sim (fopx), D1(fopx), 'color', 'black', 'Marker','x', 'LineStyle', 'none', 'LineWidth', line_width_pt,'MarkerSize', mks);

cr = semilogy(time(rdx), Confirmed(rdx), 'color', green, 'Marker', 'o', 'LineStyle', 'none', 'LineWidth', line_width_pt, 'MarkerSize', mks);
qr = semilogy(time(rdx), Active(rdx), 'color', red_dark, 'Marker', 'o', 'LineStyle', 'none', 'LineWidth', line_width_pt, 'MarkerSize', mks);
rr = semilogy(time(rdx), Recovered(rdx),'color', blue, 'Marker', 'o', 'LineStyle', 'none', 'LineWidth', line_width_pt, 'MarkerSize', mks);
dr = semilogy(time(rdx), Deaths(rdx),'ko', 'LineWidth', line_width);

grid on

%--------------------------------------------------------------------------

yl = ylabel('Number of cases');
xl = xlabel('Time (days)');

set(gcf,'color','w')
set(gca,'yscale','lin')
% set(gca,'yscale','log')

time_lim = time_sim;
xlim([time_lim(1) time_lim(end) ])
% xlim([time_sim(1) time_sim(end) ])

set(gca, 'XTickMode', 'manual', 'YTickMode', 'auto', 'XTick', time_lim(1):2:time_lim(end), 'FontSize', font_tick, 'XTickLabelRotation', 45);

%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% TITLE
%--------------------------------------------------------------------------

date_str = datestr(time(tdx));

if strcmp (MODEL_EVAL, 'OFF')
    
    if (strcmp(Province, ''))
        
        title_srt = sprintf('%s, GeSEIR model forecasting. Fitted with %d days,\n forecasted %d days from %s', Country, DAYS, FORECAST, date_str(1:11) );
    else
        title_srt = sprintf('%s (%s), GeSEIR model forecasting. Fitted with %d days,\n forecasted %d days from %s', Province, Country, DAYS, FORECAST, date_str(1:11) );
    end
    
else
    
    if (strcmp(Province, ''))
        
        title_srt = sprintf('%s, GeSEIR model evaluation. Fitted with %d days,\n forecasted %d days from %s', Country, DAYS, FORECAST, date_str(1:11) );
    else
        title_srt = sprintf('%s (%s), GeSEIR model evaluation. Fitted with %d days,\n forecasted %d days from %s', Province, Country, DAYS, FORECAST, date_str(1:11) );
    end
    
    
end

tl =  title(title_srt);

%--------------------------------------------------------------------------
% Points with values
%--------------------------------------------------------------------------

semilogy(time, Confirmed, 'color', green, 'Marker', 'o', 'LineStyle', 'none', 'LineWidth', line_width_pt, 'MarkerSize', mks);
semilogy(time, Active, 'color', red_dark, 'Marker', 'o', 'LineStyle', 'none', 'LineWidth', line_width_pt, 'MarkerSize', mks);
semilogy(time, Recovered,'color', blue, 'Marker', 'o', 'LineStyle', 'none', 'LineWidth', line_width_pt, 'MarkerSize', mks);
semilogy(time, Deaths,'ko', 'LineWidth', line_width);

time_fore_pt = time_sim (fopx);
c_fore_pt = C1 (fopx);
q_fore_pt = Q1 (fopx);
i_fore_pt = I1 (fopx);
r_fore_pt = R1 (fopx);
d_fore_pt = D1 (fopx);

B = 5;
delay = -1/2;

if strcmp (MODEL_EVAL, 'OFF')

    py = max(q_fore_pt+i_fore_pt) / 20;
    
    for i = size(Active, 2)-B : 2 : size(Active, 2)
        text( time(i)+delay , Active(i) + py, sprintf('%s', num2sip( Active(i) , 3)), 'FontSize',  font_point, 'color', red_dark ) ;
    end
    
    for i = size(Confirmed, 2)-B: 2 :size(Confirmed, 2)
        text( time(i)+delay, Confirmed(i) + py, sprintf('%s', num2sip(Confirmed(i) , 3)), 'FontSize',  font_point, 'color', green );
    end
    
    for i = size(Recovered, 2)-B: 2 : size(Recovered, 2)
        text( time(i)+delay, Recovered(i)+py, sprintf('%s', num2sip(Recovered(i) , 3)), 'FontSize',  font_point, 'color', blue );
    end
    
    for i = size(Deaths, 2)-B: 2 : size(Deaths, 2)
        text( time(i)+delay/2, Deaths(i)+py, sprintf('%s',   num2sip(Deaths(i) , 3)), 'FontSize',  font_point, 'color', 'black' );
    end
    
    
    for i = 1 : 2 : size(c_fore_pt, 2)
        text( time_fore_pt(i)+delay, c_fore_pt(i)+py, sprintf('%s', num2sip(round( c_fore_pt(i) ) , 3)), 'FontSize',  font_point, 'Color', gray);
    end
    
    for i = 1 : 2 : size(q_fore_pt, 2)
        text( time_fore_pt(i)+delay, q_fore_pt(i)+py, sprintf('%s', num2sip(round( q_fore_pt(i)) , 3)), 'FontSize',  font_point, 'Color', gray);
    end
    
    for i = 1 : 2 : size(r_fore_pt, 2)
        text(time_fore_pt(i)+delay, r_fore_pt(i)+py, sprintf('%s', num2sip(round( r_fore_pt(i)) , 3)), 'FontSize',  font_point, 'Color', gray);
    end
    
    for i = 1 : 2 : size(d_fore_pt, 2)
        text(time_fore_pt(i)+delay/2, d_fore_pt(i)+py, sprintf('%s', num2sip(round( d_fore_pt(i)) , 3)), 'FontSize',  font_point, 'Color', gray);
    end
    
else
    %--------------------------------------------------------------------------
    % Points with errors
    %--------------------------------------------------------------------------
    
    py = max(c_fore_pt) / 20;
    
    for i = 1 : 2 : size(q_fore_pt, 2)
        
        error = (round(q_fore_pt(i)) - Active(tdx+i)) / Active(tdx+i) * 100;
        
        text( time_fore_pt(i)+delay, q_fore_pt(i)+py , sprintf('%.2f%%',  error) , 'FontSize',  font_point, 'color', red_dark )  ;
    end
    
    for i = 1 : 2 : size(c_fore_pt, 2)
        
        error = (round(c_fore_pt(i)) - Confirmed(tdx+i)) / Confirmed(tdx+i) * 100;
        
        text( time_fore_pt(i)+delay, c_fore_pt(i)+py , sprintf('%.2f%%',  error) , 'FontSize',  font_point, 'color', green );
    end
    
    for i = 1 : 2 : size(r_fore_pt, 2)
        
        error = (round(r_fore_pt(i)) - Recovered(tdx+i)) / Recovered(tdx+i) * 100;
        
        text( time_fore_pt(i)+delay, r_fore_pt(i)+py , sprintf('%.2f%%',  error) , 'FontSize',  font_point, 'color', blue );
    end
    
    for i = 1 : 2 : size(d_fore_pt, 2)
        
        error = (round(d_fore_pt(i)) - Deaths(tdx+i)) / Deaths(tdx+i) * 100;
        
        text( time_fore_pt(i)+delay/2, d_fore_pt(i)-py*2/3 , sprintf('%.2f%%',  error) , 'FontSize',  font_point, 'color', 'black' );
    end
    
end

%--------------------------------------------------------------------------

% LEGEND
%--------------------------------------------------------------------------

if strcmp (MODEL_EVAL, 'OFF')
    leg = { 'Confirmed (fitted)', 'Active (fitted)', ...
        'Recoveries (fitted)','Deaths (fitted)',...
        'Active + Potential Infected', ...
        'Confirmed (reported)', 'Active (reported)', ...
        'Recoveries (reported)','Deaths (reported)'};

    ll = legend([c1, q1, r1, d1, i1, cr, qr, rr, dr], leg{:}, 'Location','NorthWest'); 
else
    leg = { 'Confirmed (fitted)', 'Active (fitted)', ...
    'Recoveries (fitted)','Deaths (fitted)',...
%     'Active + Potential Infected', ...
    'Confirmed (reported)', 'Active (reported)', ...
    'Recoveries (reported)','Deaths (reported)'};

    ll = legend([c1, q1, r1, d1, cr, qr, rr, dr], leg{:}, 'Location','NorthWest'); 
end

%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% TEXT BOX
%--------------------------------------------------------------------------

text_box = sprintf('%s\n  * %s.\n  * %s.\n  * %s.\n  * %s.\n  * %s.\n%s.', model_str, ...
    c_fore_str, q_fore_str, r_fore_str, d_fore_str, i_fore_str, doub_str);

al = annotation('textbox', [0.36, 0.755, 0.1, 0.1], 'string', text_box, ...
    'LineStyle','-',...
    'FontSize', font_legend,...
    'FontName','Arial', ... 
    'FaceAlpha', 0.5, ... 
    'BackgroundColor', 'white');
%     'FontWeight','bold',...
%--------------------------------------------------------------------------

set(tl,'FontSize', font_title);
set(xl,'FontSize', font_label);
set(yl,'FontSize', font_label);
set(ll,'FontSize', font_legend);
set(al,'FontSize', font_legend);

%% SAVE FIGURE TO PNG FILE

if strcmp (MODEL_EVAL, 'OFF')
    file_name = sprintf('%s_covid-19_fit_forecast_%s', Country, datestr( FIT_UNTIL ) );
else
    file_name = sprintf('%s_covid-19_fit_forecast_eval_%s', Country, datestr( FIT_UNTIL ) );
end

file_str = sprintf('./png/%s.png', file_name );

set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);

saveas(gcf,file_str)


%% SAVE DATA TO CSV FILE

%--------------------------------------------------------------------------
% FITTING AND FORECASTING
%--------------------------------------------------------------------------

file_str = sprintf('./csv/%s.csv', file_name );

fid = fopen(file_str, 'w');
fprintf(fid, '%s, %s, %s, %s, %s,\n', 'Date', 'Active', 'Recoveries', 'Deaths', 'Active+Infected') ; % Print the time string

for idx = 1:size(time_sim, 2)  % Loop through each time/value row size(qq, 1)
    
    fprintf(fid, '%s,', datestr ( time_sim(:, idx) , 31 ) ) ; % date
    fprintf(fid, '%12.5f,', Q1(idx) ) ; % active
    fprintf(fid, '%12.5f,', R1(idx) ) ; % active
    fprintf(fid, '%12.5f,', D1(idx) ) ; % active
    fprintf(fid, '%12.5f,', Q1(idx)+I1(idx) ) ; % active
    fprintf(fid, '\n' ) ; % active
end

fclose(fid) ;

%--------------------------------------------------------------------------
% FITTING AND FORECASTING, LASTEST
%--------------------------------------------------------------------------

if strcmp (MODEL_EVAL, 'OFF')
    
    cp_command = sprintf('cp %s ./csv/%s_covid-19_fit_forecast_lastest.csv', file_str, Country );
    ret = system(cp_command);
    if ret ~= 0
        error('cp error!');
    end
    
end

%--------------------------------------------------------------------------
% REPORTED
%--------------------------------------------------------------------------

if strcmp (MODEL_EVAL, 'OFF')
    
    file_name = sprintf('%s_covid-19_reported_%s', Country, datestr( FIT_UNTIL ) );
else
    file_name = sprintf('%s_covid-19_reported_eval_%s', Country, datestr( FIT_UNTIL ) );
end

file_str = sprintf('./csv/%s.csv', file_name);

fid = fopen(file_str, 'w');
fprintf(fid, '%s, %s, %s, %s,\n', 'Date', 'Active', 'Recoveries', 'Deaths') ; % Print the time string

for idx = 1:size(time, 2)  % Loop through each time/value row size(qq, 1)
    
    fprintf(fid, '%s,',     datestr ( time(1, idx) , 31 ) ) ; % date
    fprintf(fid, '%12.5f,', Active(idx) ) ; % active
    fprintf(fid, '%12.5f,', Recovered(idx) ) ; % active
    fprintf(fid, '%12.5f,', Deaths(idx) ) ; % active
    fprintf(fid, '\n' ) ; % active
end

%--------------------------------------------------------------------------
% REPORTED, LASTEST
%--------------------------------------------------------------------------

if strcmp (MODEL_EVAL, 'OFF')
    cp_command = sprintf('cp %s ./csv/%s_covid-19_reported_lastest.csv', file_str, Country );
    ret = system(cp_command);
    if ret ~= 0
        error('cp error!');
    end
end