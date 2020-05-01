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

if (~exist('ITERATIVE','var')),  ITERATIVE  = 'OFF'; end

if strcmp( ITERATIVE, 'OFF' )
    
    clear
    close all
    clc
    if (~exist('ITERATIVE','var')),  ITERATIVE  = 'OFF'; end
end

if (~exist('ENGLISH','var')), ENGLISH  = 'OFF'; end
if (~exist('PEAK','var')),    PEAK     = 'OFF'; end

addpath ./
addpath /home/rodralez/my/investigacion/work-in-progress/covid-19/matlab/
addpath ./num2sip/

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
% Province = 'CABA';
% Country = 'Argentina';
% Country = 'Ecuador';
% Country = 'Brazil';
% Country = 'Chile';
% Country = 'Uruguay';

% Country = 'United Kingdom';
% Country = 'Spain';
% Country = 'Italy';
% Country = 'US';

% Country = 'Belgium';
% Country = 'Germany';
% Country = 'Turkey';
% Country = 'France';

% Country = 'Singapore';
Country = 'Korea, South';
% Country = 'China';
% Province = 'Hubei';

%% SIMULATION CONFIG

% Argentina
FIT_UNTIL =  datetime(2020, 4, 30);
FIT_FROM  =  FIT_UNTIL - 15;
% % FIT_FROM  =  datetime(2020, 3, 1);

FORECAST_DAYS = 15; % DAYS TO FORECAST

FORECAST_DAYS = 60; % DAYS TO FORECAST
% PEAK     = 'ON'

ENGLISH  = 'ON'

% MODEL_EVAL = 'ON';
% FIT_UNTIL =  datetime(2020, 4, 13);
% FIT_FROM  =  FIT_UNTIL - 14;
% FIT_FROM  =  datetime(2020, 3, 1);

source = 'HOPKINS';
% source = 'MINSAL';

% source_input = 'online' ;
source_input = 'offline' ;

if (~exist('MODEL_EVAL','var')),  MODEL_EVAL  = 'OFF'; end


%% GET DATA JH

[tableConfirmed_jh,tableDeaths_jh,tableRecovered_jh,time_jh] = get_covid_global_hopkins ( source_input, './hopkins/' );

% [tableConfirmed,tableDeaths,tableRecovered,time] = get_covid_us_hopkins ( source, './hopkins/' );

% FIND COUNTRY
[indC, indR, indD, Npop] = find_country (tableConfirmed_jh,tableRecovered_jh,tableDeaths_jh, Country, Province);

Confirmed_jh = table2array(tableConfirmed_jh(indC, 4:end));
Deaths_jh    = table2array(tableDeaths_jh(indD, 4:end));

if ~isempty(tableRecovered_jh)
    Recovered_jh = table2array(tableRecovered_jh(indR, 4:end));
end

%% GET DATA MINSAL

if strcmp(Country, 'Argentina')
    
    [tableConfirmed_ar,tableDeaths_ar,tableRecovered_ar,time_ar] = get_covid_argentina( source_input, './csv/', Recovered_jh );

    % FIND COUNTRY
    [indC_ar, indR_ar, indD_ar, Npop_ar] = find_country (tableConfirmed_ar,tableRecovered_ar,tableDeaths_ar, Country, Province);
    
    compare_hopkins_minsal(tableConfirmed_jh,tableRecovered_jh,tableDeaths_jh, time_jh, tableConfirmed_ar,tableRecovered_ar,tableDeaths_ar, time_ar)
    
    Confirmed_ar = table2array(tableConfirmed_ar(indC_ar, 4:end));
    Deaths_ar    = table2array(tableDeaths_ar(indD_ar, 4:end));
    
    if ~isempty(tableRecovered_jh)
        Recovered_ar = table2array(tableRecovered_ar(indR_ar, 4:end));
    end
    
    minNum = 50;
    
    time_ar(Confirmed_ar <= minNum)= [];
    if ~isempty(tableRecovered_ar)
        Recovered_ar(Confirmed_ar <= minNum)=[];
    end
    Deaths_ar(Confirmed_ar <= minNum)=[];
    Confirmed_ar(Confirmed_ar <= minNum)=[];

end

% FIND FIRST 50 CASES

% If the number of confirmed Confirmed cases is small, it is difficult to know whether
% the quarantine has been rigorously applied or not. In addition, this
% suggests that the number of infectious is much larger than the number of
% confirmed cases

minNum = 50;
time_jh(Confirmed_jh <= minNum)= [];
if ~isempty(tableRecovered_jh)
    Recovered_jh(Confirmed_jh <= minNum)=[];
end
Deaths_jh(Confirmed_jh <= minNum)=[];
Confirmed_jh(Confirmed_jh <= minNum)=[];


%% CHOOSE DATASET

if strcmp(source, 'HOPKINS')
    
    Confirmed = Confirmed_jh;
    Recovered = Recovered_jh;
    Deaths = Deaths_jh;
    time = time_jh;
    
    source_str   = sprintf( 'Johns Hopkins CSSE');

elseif strcmp(source, 'MINSAL')
    
    Confirmed = Confirmed_ar;
    Recovered = Recovered_ar;
    Deaths = Deaths_ar;
    time = time_ar;
    
    source_str   = sprintf( 'Ministerio de Salud');    
else
    
    error('No data source selected!')
end

%% FITTING

tidx = datefind( FIT_FROM,  time);
tfdx = datefind( FIT_UNTIL, time);

tfit = time >= FIT_FROM;
tfit = time <= FIT_UNTIL & tfit;

% Initial conditions
C0 = Confirmed(tfit);
E0 = C0(1) ; % Initial number of exposed cases. Unknown but unlikely to be zero.
I0 = C0(1) ; % Initial number of infectious cases. Unknown but unlikely to be zero.

param_fit = my_fit_SEIQRDP(Confirmed(tfit), Recovered(tfit), Deaths(tfit), Npop, E0, I0, time(tfit));
    
Active = Confirmed - Recovered - Deaths;

FIT_DAYS = length(time(tfit));

%% FORECAST Simulate the epidemy outbreak based on the fitted parameters

% Initial conditions
C0 = Confirmed(tfit);
E0 = C0(1) ; % Initial number of exposed cases. Unknown but unlikely to be zero.
I0 = C0(1) ; % Initial number of infectious cases. Unknown but unlikely to be zero.

R0 = Recovered(tfit);
D0 = Deaths(tfit);
R0 = R0(1);
D0 = D0(1);

Q0 = C0(1)- R0 - D0;

dt = 1/24; % time step, 1 hour

time_adj = time(tfit);
time_sim  = datetime( time_adj(1) ): dt : datetime( time_adj(end) + FORECAST_DAYS );

[S1,E1,I1,Q1,R1,D1,P1] = my_SEIQRDP(param_fit, Npop, E0, I0, Q0, R0, D0, time_sim, dt);

C1 = Q1 + R1 + D1 ;

%% DOUBLING ANALYSYS

% fdx = find ( c1 <= ceil( C1(end) / 2 ), 1, 'last');
fdx = find ( Q1 >= floor( Q1(end) / 2 ), 1, 'first');
doubling_q = round( datenum ( time_sim(end)- time_sim(fdx) ) );

fdx = find ( D1 >= floor( D1(end) / 2 ), 1, 'first');
doubling_d = round( datenum ( time_sim(end)- time_sim(fdx) ) );

if isempty(doubling_q | doubling_d)
    warning ('doubling is empty.')
end

%% PRINT

if strcmp( ITERATIVE, 'OFF' )
    
    fprintf(' *** Country: %s ***\n\n', Country );
    
    fprintf(' Fiting time series starts on %s. \n', datestr(time(1)) );
    fprintf(' Fiting time series stops  on %s. \n' , datestr(time(end)) );
    fprintf(' Forecasting time series stops on %s. \n', datestr(time_sim(end)) );
    fprintf(' Forecasting days are %d.\n', FORECAST_DAYS );
    
    
    if strcmp (ENGLISH, 'ON')
        
        model_str   = sprintf( 'It is forecasted on %s:', datestr( time_sim(end), 'mmmm dd' ) );
        c_fore_str  = sprintf( '%d confirmed cases (%+d)', round( C1(end) ) , round( C1(end) - Confirmed(end) ) );
        q_fore_str  = sprintf( '%d active cases (%+d)', round( Q1(end) ) , round( Q1(end) - Active(end) ) );
        r_fore_str  = sprintf( '%d recoveries (%+d)', round( R1(end) ) , round( R1(end) - Recovered(end) ) );
        d_fore_str  = sprintf( '%d deaths (%+d)', round( D1(end) ) , round( D1(end) - Deaths(end) ) );
        double_q_str  = sprintf( 'Active cases are doubled in %d days', doubling_q );
        double_d_str    = sprintf( 'Deaths are doubled in %d days', doubling_d );
    else
        model_str   = sprintf( 'Se proyecta para el %s:', datestr( time_sim(end), 'dd/mm/yy' ) );
        c_fore_str  = sprintf( '%d casos confirmados (%+d)', round( C1(end) ) , round( C1(end) - Confirmed(end) ) );
        q_fore_str  = sprintf( '%d casos activos (%+d)', round( Q1(end) ) , round( Q1(end) - Active(end) ) );
        r_fore_str  = sprintf( '%d recuperados (%+d)', round( R1(end) ) , round( R1(end) - Recovered(end) ) );
        d_fore_str  = sprintf( '%d fallecidos (%+d)', round( D1(end) ) , round( D1(end) - Deaths(end) ) );
        double_q_str    = sprintf( 'Activos se duplican cada %d días', doubling_q );
        double_d_str    = sprintf( 'Fallecidos se duplican cada %d días', doubling_d );
    end
    
    i_fore_str  = sprintf( '%d potential active cases', round( Q1(end) + I1(end) ) );
    
    Q_fore_str  = sprintf( 'Models predicts %d active cases on %s', round( ( Q1(end)) ), datestr( time_sim(end) ) );
    N_fore_str  = sprintf( 'Models predicts new %d active cases on %s', round( ( Q1(end) ) - Active(end) ), datestr( time_sim(end) ) );
    I_fore_str  = sprintf( 'Models predicts %d infected on %s', round( I1(end) ), datestr( time_sim(end) ) );
    
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
    fprintf( ' %s \n', double_q_str );
    fprintf( ' %s \n', double_d_str );
    
end

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
red = [1 0 0];

%--------------------------------------------------------------------------
% FONT SIZE, LINE WIDTH, POINT WIDTH
%--------------------------------------------------------------------------

font_title = 25;
font_label = 23;
font_tick  = 17;
font_legend = 16;
font_point = 13;

line_width = 2.5;
line_width_pt= 2;
mks = 9;

%--------------------------------------------------------------------------
% VECTOR INDEX FOR FIGURE
%--------------------------------------------------------------------------

fodx = time_sim > FIT_UNTIL;
fopx = contains( cellstr( datestr( time_sim ) ), '00:00:00') & fodx';

fidx = time_sim <= FIT_UNTIL;

time_fore_pt = time_sim (fopx);
c_fore_pt = C1 (fopx);
q_fore_pt = Q1 (fopx);
r_fore_pt = R1 (fopx);
d_fore_pt = D1 (fopx);

if strcmp( ITERATIVE, 'OFF' )
    
    %--------------------------------------------------------------------------
    
    figure
    
    %--------------------------------------------------------------------------
    % FITING, LINES
    %--------------------------------------------------------------------------
    
    %     c1 = semilogy(time_sim (fidx), C1 (fidx), 'color', green, 'LineWidth', line_width);
    
    q1 = semilogy(time_sim (fidx), Q1 (fidx), 'color', red_dark, 'LineWidth', line_width);
    hold on
    r1 = semilogy(time_sim (fidx), R1 (fidx), 'color', blue, 'LineWidth', line_width);
    
    d1 = semilogy(time_sim (fidx), D1 (fidx), 'k', 'LineWidth', line_width);
    
    %--------------------------------------------------------------------------
    % PEAK LINE
    %--------------------------------------------------------------------------
    
    if strcmp (PEAK, 'ON')
        
        qdx = find (Q1 == max(Q1));
        adx = find (Active == max(Active));
        
        if max(Q1) > max(Active )
            
            peak_max = max(Q1);
            peak_time = time_sim (qdx);
        else
            
            peak_max = max(Active);
            peak_time = time (adx);
        end
        
        line([peak_time peak_time], [1 peak_max], 'color', red, 'linewidth', line_width, 'LineStyle', '--');
        semilogy(peak_time, peak_max, 'color', red, 'Marker','d', 'LineStyle', 'none', 'LineWidth', line_width_pt,'MarkerSize', mks+3);        
        
        if strcmp (ENGLISH, 'OFF')
            
            peak_str   = sprintf( 'Pico el %s con %s casos activos', datestr( peak_time, 'dd/mm' ), num2sip(round( peak_max ) , 3) ) ;        
        else            
            peak_str   = sprintf( 'Peak with %s active cases on %s', num2sip(round( peak_max ) , 3), datestr( peak_time, 'mmmm dd' )  ) ;
        end
        
        fprintf(' %s \n', peak_str )        
    end
    
    %--------------------------------------------------------------------------
    
    %--------------------------------------------------------------------------
    % FORECASTING, POINTS
    %--------------------------------------------------------------------------
    
    %     cp = semilogy(time_sim (fopx), C1(fopx), 'color', green, 'Marker','x', 'LineStyle', 'none', 'LineWidth', line_width_pt,'MarkerSize', mks);
    qp = semilogy(time_sim (fopx), Q1(fopx), 'color', red_dark, 'Marker','x', 'LineStyle', 'none', 'LineWidth', line_width_pt,'MarkerSize', mks);
    rp = semilogy(time_sim (fopx), R1(fopx), 'color', blue, 'Marker','x', 'LineStyle', 'none', 'LineWidth', line_width_pt,'MarkerSize', mks);
    dp = semilogy(time_sim (fopx), D1(fopx), 'color', 'black', 'Marker','x', 'LineStyle', 'none', 'LineWidth', line_width_pt,'MarkerSize', mks);
    
    %     cr = semilogy(time, Confirmed, 'color', green, 'Marker', 'o', 'LineStyle', 'none', 'LineWidth', line_width_pt, 'MarkerSize', mks);
    qr = semilogy(time, Active,    'color', red_dark, 'Marker', 'o', 'LineStyle', 'none', 'LineWidth', line_width_pt, 'MarkerSize', mks);
    rr = semilogy(time, Recovered, 'color', blue, 'Marker', 'o', 'LineStyle', 'none', 'LineWidth', line_width_pt, 'MarkerSize', mks);
    dr = semilogy(time, Deaths,    'color', 'black', 'Marker', 'o', 'LineStyle', 'none', 'LineWidth', line_width_pt, 'MarkerSize', mks);
    
    grid on
    %--------------------------------------------------------------------------
    
    %--------------------------------------------------------------------------
    % AXES PROPIETIES
    %--------------------------------------------------------------------------
    
    if strcmp (ENGLISH, 'ON')
        yl = ylabel('Number of cases');
        xl = xlabel('Time (days)');
    else
        yl = ylabel('Número de casos');
        xl = xlabel('Tiempo (días)');
    end
    
    set(gcf,'color','w')
%     set(gca,'yscale','lin')
    set(gca,'yscale','log')
    
    xlim([ time(1) time_sim(end) ])
    
    if max(R1) > max(Q1)
        ylim([ 1 max(R1)*3  ]); 
    else
        ylim([ 1 max(Q1)*3  ]); 
    end
    
    set(gca, 'XTickMode', 'manual', 'YTickMode', 'auto', 'XTick', time(1):4:time_sim(end), 'FontSize', font_tick, 'XTickLabelRotation', 45);
    %--------------------------------------------------------------------------
    
    %--------------------------------------------------------------------------
    % TITLE
    %--------------------------------------------------------------------------    
    
    if (strcmp(Province, ''))
        country_str = Country;
    else
        country_str = [Province,' (',Country,')'];
    end
    
    if strcmp (ENGLISH, 'ON')
        
        date_str = datestr(time(tfdx), 'mmmm dd');
        
        if strcmp (MODEL_EVAL, 'OFF')
            title_type = 'GeSEIR model for COVID-19 forecasting';
        else
            title_type = 'GeSEIR model for COVID-19 evaluation';
        end
        
        sub_title_srt     = ['\fontsize{20}\color{gray}\rm Source: ', source_str, '.'];
        
        switch (country_str)
            case 'Korea, South', country_str = 'South Korea'; Country = 'South Korea';
        end
        
        title_srt = sprintf('%s, %s.\nFitted with %d days, forecasted %d days from %s.', ...
            country_str, title_type, FIT_DAYS, FORECAST_DAYS, date_str );
    else
    
        date_str = datestr(time(tfdx), 'dd/mm/yy');
        
        switch (country_str)           
            case 'Spain', country_str = 'España';
            case 'Italy', country_str = 'Italia';
            case 'US', country_str = 'EE.UU.';
            case 'Korea, South', country_str = 'Corea del Sur'; Country = 'South Korea';
        end
        
        if strcmp (MODEL_EVAL, 'OFF')
            title_type = 'Modelo GeSEIR para la predicción de COVID-19';
        else
            title_type = 'Modelo GeSEIR para la evaluación de COVID-19';
        end
        
        sub_title_srt     = ['\fontsize{20}\color{gray}\rm Fuente: ', source_str, '.'];
                
        title_srt = sprintf('%s, %s.\nAjuste con %d días, proyección de %d días desde %s.', ...
            country_str, title_type, FIT_DAYS, FORECAST_DAYS, date_str );
    end
    
    tl =  title( { title_srt ; sub_title_srt } );
    %--------------------------------------------------------------------------
    
    %--------------------------------------------------------------------------
    % Points with value labels
    %--------------------------------------------------------------------------
    
    if FORECAST_DAYS < 30
        P = 5;
    else
        P = 7;
    end
        
    hght = 1.75;
    delay = 0;  %  -1/2
    
    if strcmp (MODEL_EVAL, 'OFF')
        
        
        for i = 1 : P : size(Active, 2)
            text( time(i)+delay , Active(i)*hght , sprintf('%s', num2sip( Active(i) , 3)), 'FontSize',  font_point, 'color', red_dark ) ;
        end
        
        for i = 1 : P : size(Recovered, 2)
            text( time(i)+delay, Recovered(i)/hght , sprintf('%s', num2sip(Recovered(i) , 3)), 'FontSize',  font_point, 'color', blue );
        end
        
        for i = 1 : P : size(Deaths, 2)
            text( time(i)+delay, Deaths(i)/hght , sprintf('%s',   num2sip(Deaths(i) , 3)), 'FontSize',  font_point, 'color', 'black' );
        end
        
        S = P;
        for i = S : P : size(time_fore_pt, 2)
            text( time_fore_pt(i)+delay, q_fore_pt(i)*hght , sprintf('%s', num2sip(round( q_fore_pt(i)) , 3)), 'FontSize',  font_point, 'Color', red_dark);
        end
        
        for i = S : P : size(time_fore_pt, 2)
            text(time_fore_pt(i)+delay, r_fore_pt(i)/hght , sprintf('%s', num2sip(round( r_fore_pt(i)) , 3)), 'FontSize',  font_point, 'Color', blue);
        end
        
        for i = S : P : size(time_fore_pt, 2)
            text(time_fore_pt(i)+delay, d_fore_pt(i)/hght , sprintf('%s', num2sip(round( d_fore_pt(i)) , 3)), 'FontSize',  font_point, 'Color', 'black');
        end
        
        % Print last vector element
        text( time_fore_pt(end)+delay, q_fore_pt(end)*hght , sprintf('%s', num2sip(round( q_fore_pt(end)) , 3)), 'FontSize',  font_point, 'Color', red_dark);
        text( time_fore_pt(end)+delay, r_fore_pt(end)/hght , sprintf('%s', num2sip(round( r_fore_pt(end)) , 3)), 'FontSize',  font_point, 'Color', blue);
        text( time_fore_pt(end)+delay, d_fore_pt(end)/hght , sprintf('%s', num2sip(round( d_fore_pt(end)) , 3)), 'FontSize',  font_point, 'Color', 'black');
    else
        %--------------------------------------------------------------------------
        % Points with errors percent labels
        %--------------------------------------------------------------------------
        
        P = 2;
        
        for i = 1 : P : size(q_fore_pt, 2)
            
            if ( tfdx+i <= size (Active, 2))
                
                error = (round(q_fore_pt(i)) - Active(tfdx+i)) / Active(tfdx+i) * 100;
                text( time_fore_pt(i)+delay, q_fore_pt(i)*hght , sprintf('%.0f%%',  error) , 'FontSize',  font_point, 'color', red_dark )  ;
            end
        end
        
        for i = 1 : P : size(r_fore_pt, 2)
            
            if ( tfdx+i <= size (Recovered, 2))
                
                error = (round(r_fore_pt(i)) - Recovered(tfdx+i)) / Recovered(tfdx+i) * 100;
                text( time_fore_pt(i)+delay, r_fore_pt(i)/hght , sprintf('%.0f%%',  error) , 'FontSize',  font_point, 'color', blue );
            end
        end
        
        for i = 1 : P : size(d_fore_pt, 2)
            
            if ( tfdx+i <= size (Deaths, 2))
                
                error = (round(d_fore_pt(i)) - Deaths(tfdx+i)) / Deaths(tfdx+i) * 100;
                text( time_fore_pt(i)+delay, d_fore_pt(i)/hght , sprintf('%.0f%%',  error) , 'FontSize',  font_point, 'color', 'black' );
            end
        end
    end
    %--------------------------------------------------------------------------
    
    %--------------------------------------------------------------------------
    % LEGEND
    %--------------------------------------------------------------------------
    
    if strcmp (ENGLISH, 'ON')
        leg = {
            'Active (fitted)', ...
            'Recoveries (fitted)',...
            'Deaths (fitted)',...
            'Active (reported)', ...
            'Recoveries (reported)',...
            'Deaths (reported)'};
    else
        leg = {
            'Activos (ajustado)', ...
            'Recuperados (ajustado)',...
            'Fallecidos (ajustado)',...
            'Activos (reportados)', ...
            'Recuperados (reportados)',...
            'Fallecidos (reportados)'};
    end
    
    ll = legend( [q1, r1, d1, qr, rr, dr], leg{:}, 'Location','SouthEast' ); % NorthWest
    
    set(ll,'color','none');
    
    %--------------------------------------------------------------------------
    
    %--------------------------------------------------------------------------
    % TEXT BOX
    %--------------------------------------------------------------------------
    
    if strcmp (PEAK, 'OFF')
        
        text_box = sprintf('%s\n * %s.\n * %s.\n * %s.\n * %s.\n * %s.', model_str, ...
            q_fore_str, r_fore_str, d_fore_str, double_q_str, double_d_str);
        
    else
        
        text_box = sprintf('%s\n * %s.\n * %s.\n * %s.\n * %s.', model_str, ...
            q_fore_str, r_fore_str, d_fore_str, peak_str);
        
    end
    
    al = annotation('textbox', [0.42, 0.25, 0.1, 0.1], 'string', text_box, ...
        'LineStyle','-',...
        'FontSize', font_legend,...
        'FontName','Arial', ...
        'FaceAlpha', 0.5, ...
        'BackgroundColor', 'white');
    %     'FontWeight','bold',...

    %--------------------------------------------------------------------------
    % FIRM
    %-------------------------------------------------------------------------- 
    
    % Create textbox
    annotation('textbox', [0.14 0.8 0.3 0.04],...
    'Color', ones(1,3) * 0.50 ,...
    'String',{'Rodrigo Gonzalez (Twitter @RGonzalez\_PhD)'},...
            'LineStyle','none',...
        'FontSize', font_legend ,...
        'FontName','Arial', ...
        'FaceAlpha', 0.5, ...
        'BackgroundColor', 'white');
    %--------------------------------------------------------------------------
    
    %--------------------------------------------------------------------------
    % WATERMARK
    %-------------------------------------------------------------------------- 
    
    for i=1:3
        x = 0.14 + i*0.15;
        y = 0.78 - i*0.14;
        annotation('textbox', [x y 0.3 0.05],...
    'Color', ones(1,3) * 0.875 , ...
    'String',{'Rodrigo Gonzalez (Twitter @RGonzalez\_PhD)'},...
            'LineStyle','none',...
        'FontSize', font_legend ,...
        'FontName','Arial', ...
        'FaceAlpha', 0.05, ...
        'BackgroundColor', 'white');
    end
    
    %--------------------------------------------------------------------------
    
    set(tl,'FontSize', font_title, 'FontName','Arial');
    set(xl,'FontSize', font_label, 'FontName','Arial');
    set(yl,'FontSize', font_label, 'FontName','Arial');
    set(ll,'FontSize', font_legend, 'FontName','Arial');
    set(al,'FontSize', font_legend, 'FontName','Arial');
    
    hold off
    
    
    %% SAVE FIGURE TO PNG FILE
        
    Country = regexprep(Country, ' ', '_');
    
    if strcmp (MODEL_EVAL, 'OFF')
        
        file_name = sprintf('%s_covid-19_fit_forecast_%s', Country, datestr( FIT_UNTIL ) );
    else
        file_name = sprintf('%s_covid-19_eval_%s', Country, datestr( FIT_UNTIL ) );
    end
    
    if strcmp (PEAK, 'ON')
        
        file_name = [file_name,'_peak'];
    end
    
    file_str = sprintf('./png/%s.png', file_name );
    
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
    
    saveas(gcf,file_str)
    
    %% INFECTED FIGURE
    
    
    %% PLOT INFECTED AND EXPOSED
    
%     figure
%     
%     q1 = semilogy(time_sim (fidx), I1 (fidx), 'color', red_dark, 'LineWidth', line_width);
%     hold on
%     r1 = semilogy(time_sim (fidx), E1 (fidx), 'color', blue, 'LineWidth', line_width);
%     
%     grid on
%     
%     legend('INFECTED', 'EXPOSED')
%     
%     hold off
    
    %% SAVE DATA TO CSV FILE
    
    %--------------------------------------------------------------------------
    % FITTING AND FORECASTING
    %--------------------------------------------------------------------------
    
    % lambda_str  = sprintf( 'Recovery rate: [%f %f]', param_fit.lambda(1), param_fit.lambda(2) );
    % kappa_str   = sprintf( 'Death rate: [%f %f]', param_fit.kappa(1), param_fit.kappa(2) );
    
    t = 0:size(time_sim, 2);
    lambda = param_fit.lambda(1) * (1-exp(- param_fit.lambda(2) .* t));
    kappa  = param_fit.kappa(1)  * exp(-  param_fit.kappa(1) .* t);
    
    file_str = sprintf('./csv/%s.csv', file_name );
    
    fid = fopen(file_str, 'w');
    fprintf(fid, '%s, %s, %s, %s, %s, %s, %s,\n', 'Date', 'Active', 'Recoveries', 'Deaths', 'Active+Infected', 'lambda', 'kappa') ; % Print the time string
    
    for idx = 1:size(time_sim, 2)  % Loop through each time/value row size(qq, 1)
        
        fprintf(fid, '%s,', datestr ( time_sim(:, idx) , 31 ) ) ; % date
        fprintf(fid, '%12.5f,', Q1(idx) ) ; %
        fprintf(fid, '%12.5f,', R1(idx) ) ; %
        fprintf(fid, '%12.5f,', D1(idx) ) ; %
        fprintf(fid, '%12.5f,', Q1(idx)+I1(idx) ) ; %
        fprintf(fid, '%12.5f,', lambda(idx) ) ; %
        fprintf(fid, '%12.5f,', kappa(idx) ) ; %
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
        file_name = sprintf('%s_covid-19_eval_reported_%s', Country, datestr( FIT_UNTIL ) );
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
        cp_command = sprintf('cp %s ./csv/%s_covid-19_reported_lastest.csv', file_str, regexprep(Country, ' ', '_') );
        ret = system(cp_command);
        if ret ~= 0
            error('cp error!');
        end
    end
end