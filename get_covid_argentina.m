function [tableConfirmed_AR,tableDeaths_AR,tableRecovered_AR,time_AR] = get_covid_argentina( source, directory )
% get_covid_argentina() gets Argentina data from the COVID-19 epidemy from [1].
% Based on E. Cheynet's work [2].
%
% References:
% [1] https://github.com/SistemasMapache/Covid19arData/blob/master/CSV/Covid19arData%20-%20historico.csv
% [2] https://github.com/ECheynet/SEIR
%
% Version: 001
% Date:    2020/04/01
% Author:  Rodrigo Gonzalez <rodralez@frm.utn.edu.ar>
% URL:     https://github.com/rodralez/navego

%% Input handling

if nargin < 1
    
    source = 'offline';
    directory = './';
end

%%

province_ar = {'CABA';'Buenos Aires';'Catamarca';'Chaco';'Chubut'; ... Capital Federal
    'Córdoba';'Corrientes';'Entre Ríos';'Formosa';'Jujuy';'La Pampa'; ...
    'La Rioja';'Mendoza';'Misiones';'Neuquén';'Río Negro';'Salta'; ...
    'San Juan';'San Luis';'Santa Cruz';'Santa Fe';'Santiago del Estero';...
    'Tierra del Fuego';'Tucumán'; ''};

population_ar = [ 3075646; 17541141; 415438; 1204541; 618994; ...
    3760450; 1120801; 1385961; 605193; 770881; 358428;...
    393531; 1990338; 1261294; 664057; 747610; 1424397;...
    781217; 508328; 365698; 3536418; 978313;...
    173432; 1694656; 45376763; ];

%% RECOVERIES TABLE IS EMPTY

tableRecovered_AR = [];

if ( strcmp (source, 'online'))
    
    % Import the data
    
    url = 'https://raw.githubusercontent.com/SistemasMapache/Covid19arData/master/CSV/Covid19arData - historico.csv';
    
    name = 'Covid19arData - historico.csv';
    filename = [directory , name ];
%     websave( filename, url );
    
    opts = detectImportOptions(filename);
    
    % Specify file level properties
    opts.ExtraColumnsRule = "ignore";
    opts.EmptyLineRule = "read";
    
    % Create input table with data in file
    tableData = readtable(filename, opts);
    
    tableData.Properties.VariableNames(1) = {'Dates'};
    tableData.Properties.VariableNames(4) = {'CountryRegion'};
    tableData.Properties.VariableNames(5) = {'ProvinceState'};
    tableData.Properties.VariableNames(8) = {'NewActives'};
    tableData.Properties.VariableNames(10) = {'NewDeaths'};
    
    % Days in currect time series
    FIRST_DAY = table2array(tableData(1,1));
    LAST_DAY = table2array(tableData(end,1));
    DAYS = days (LAST_DAY - FIRST_DAY) + 1;
    
    % Country cells
    country_c = cell(1, 25);
    [country_c{:}] = deal('Argentina');
    
    % Vartype cells
    vartype_c = cell(1, DAYS+3);
    [vartype_c{:}] = deal('double');
    vartype_c(1) = {'string'};
    vartype_c(2) = {'string'};
    
    % Confirmed table
    tableConfirmed_AR = table('Size', [25 DAYS+3], 'VariableTypes', vartype_c );
    tableConfirmed_AR.Properties.VariableNames(1:3) = {'ProvinceState','CountryRegion','Population'};
    tableConfirmed_AR.CountryRegion = country_c';
    tableConfirmed_AR.ProvinceState = province_ar;
    tableConfirmed_AR.Population = population_ar;
    
    % Daytime cells
    for ddx = 1:DAYS
        time_s = ['Day_',datestr(FIRST_DAY+ddx-1,'dd_mm_yy') ];
        tableConfirmed_AR.Properties.VariableNames(3+ddx) = { time_s };
    end
    
    % Deaths table
    tableDeaths_AR = table('Size', [25 DAYS+3], 'VariableTypes', vartype_c );
    tableDeaths_AR.Properties.VariableNames(1:3) = {'ProvinceState','CountryRegion','Population'};
    tableDeaths_AR.CountryRegion = country_c';
    tableDeaths_AR.ProvinceState = province_ar;
    tableDeaths_AR.Population = population_ar;
    
    % Daytime cells
    for ddx = 1:DAYS
        time_s = ['Day_',datestr(FIRST_DAY+ddx-1,'dd_mm_yy') ];
        tableDeaths_AR.Properties.VariableNames(3+ddx) = { time_s };
    end
    
    % Index for Indeterminado
    hdx = ~ (contains( tableData.ProvinceState, 'Indeterminado' ) );
    
    % Index for badspelled provinces
    bdx = (contains( tableData.ProvinceState, 'Tierra Del Fuego' ) );
    tableData.ProvinceState (bdx) = {'Tierra del Fuego'};
    
    bdx = (contains( tableData.ProvinceState, 'Santiago Del Estero' ) );
    tableData.ProvinceState (bdx) = {'Santiago del Estero'};
    
    if any(tableData.NewActives(~hdx))
        
        error('get_covid_argentina: data in NewActives for "Indeterminado".')
    end
    
    if any(tableData.NewDeaths(~hdx))
        
        error('get_covid_argentina: data in NewDeaths for "Indeterminado".')
    end
    
    %% Fill table with cases per day
    for idx = 1:DAYS
        
        ldx = table2array ( tableData(:,1) ) == FIRST_DAY + idx - 1;
        
        % Do not select Indeterminado
        ldx = ldx & hdx;
        
        provinces = tableData.ProvinceState(ldx);
        new_actives =  tableData.NewActives(ldx);
        new_deaths =  tableData.NewDeaths(ldx);
        
        for pdx = 1:size(provinces, 1)
            
            cdx = contains( tableConfirmed_AR.ProvinceState,  provinces(pdx) );
            
            tableConfirmed_AR(cdx, idx+3) = num2cell ( table2array ( tableConfirmed_AR(cdx, idx+3)) +  new_actives(pdx) );
            tableDeaths_AR(cdx, idx+3)    = num2cell ( table2array ( tableDeaths_AR(cdx, idx+3))  +  new_deaths(pdx) );
        end
    end
    
    for idx = 2:DAYS
        
        ldx = table2array( tableConfirmed_AR(: , idx+3) ) == 0;
        
        tableConfirmed_AR(ldx , idx+3) = tableConfirmed_AR(ldx , idx+3-1) ;
        
        tableConfirmed_AR(~ldx , idx+3) = array2table( ...
            table2array(tableConfirmed_AR(~ldx , idx+3-1)) + table2array(tableConfirmed_AR(~ldx , idx+3)));
        
        ldx = table2array( tableDeaths_AR(: , idx+3) ) == 0;
        
        tableDeaths_AR(ldx , idx+3) = tableDeaths_AR(ldx , idx+3-1) ;
        
        tableDeaths_AR(~ldx , idx+3) = array2table( ...
            table2array(tableDeaths_AR(~ldx , idx+3-1)) + table2array(tableDeaths_AR(~ldx , idx+3)));
    end
    
    total_c = sum ( table2array(tableConfirmed_AR(1:24, 3:end) ) );
    tableConfirmed_AR( 25, 3:end ) = array2table( total_c );
    
    %% TIME
    
    time_AR = FIRST_DAY:LAST_DAY;
    
    %% SAVE TABLES   
    
    save tableConfirmed_AR tableConfirmed_AR
    save tableDeaths_AR tableDeaths_AR
    save time_AR time_AR
    
    %     time_series_covid19_confirmed_global.csv
    name = 'time_series_covid19_confirmed_ARG.csv';
    filename = [directory , name ];
    writetable(tableConfirmed_AR, filename );
    
    name = 'time_series_covid19_deaths_ARG.csv';
    filename = [directory , name ];
    writetable(tableDeaths_AR, filename );
    

elseif (strcmp (source, 'offline') )

    %% LOAD TABLES
    
    load tableConfirmed_AR
    load tableDeaths_AR
    load time_AR
    
else
    error('get_covid_argentina: bad source.')
end

end