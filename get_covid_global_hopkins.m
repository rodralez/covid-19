function [tableConfirmed,tableDeaths,tableRecovered,time] = get_covid_global_hopkins( source, directory )
% get_covid_global_hopkins() gets global data from the COVID-19 epidemy from the
% John Hopkins university [1]. Source can be online or offline.
% Based on E. Cheynet's work [2].
%
% References:
% [1] https://github.com/CSSEGISandData/COVID-19
% [2] https://www.mathworks.com/matlabcentral/fileexchange/74545-generalized-seir-epidemic-model-fitting-and-computation
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

fprintf('get_covid_global_hopkins: getting data %s...\n', source)

if ( strcmp (source, 'online'))

    status = {'confirmed','deaths','recovered'};
    server = 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/';
        
    %% 
    
    for i=1:numel(status)
        
        filename = [directory,'time_series_covid19_',status{i},'_global.csv'];
        
        url = [server,'time_series_covid19_',status{i},'_global.csv'];
        websave( filename, url );
        
        opts = detectImportOptions(filename);        
        opts.VariableNames(1) = {'ProvinceState'};
        opts.VariableNames(2) = {'CountryRegion'};
        opts.VariableNames(3) = {'Population'};
        opts.VariableNames(4) = {'Long'};
        %     opts.HeaderLines = 1;
        
        % Specify file level properties
        opts.ExtraColumnsRule = "ignore";
        opts.EmptyLineRule = "read";
        
        if strcmpi(status{i},'Confirmed')
            tableConfirmed = readtable(filename, opts);
            tableConfirmed = tableConfirmed(2:end,:); % First line is header and is descarted
            tableConfirmed.Long = []; % Long column is descarted
            tableConfirmed = improve_covid_global_hopkins( tableConfirmed , filename );
            
        elseif strcmpi(status{i},'Deaths')
            tableDeaths = readtable(filename, opts);
            tableDeaths = tableDeaths(2:end,:); % First line is header and is descarted
            tableDeaths.Long = []; % Long column is descarted
            tableDeaths = improve_covid_global_hopkins( tableDeaths , filename );
            
        elseif strcmpi(status{i},'Recovered')
            tableRecovered = readtable(filename, opts);
            tableRecovered = tableRecovered(2:end,:); % First line is header and is descarted
            tableRecovered.Long = []; % Long column is descarted
            tableRecovered = improve_covid_global_hopkins( tableRecovered , filename );
        else
            error('Unknown status')
        end
    end

    %% TIME
    
    fid = fopen(filename);
    time_str = textscan( fid, repmat('%s', 1, size(tableConfirmed,2)+1 ), 1, 'Delimiter',',');
    time = datetime( [time_str{5:end}] ) + years(2000);
    fclose(fid);
    
%% SAVE

    save tableConfirmed tableConfirmed
    save tableRecovered tableRecovered
    save tableDeaths tableDeaths
    save time time
    
elseif (strcmp (source, 'offline') )
    
    load tableConfirmed
    load tableRecovered
    load tableDeaths
    load time
    
else
    error('get_covid_global_hopkins: bad source.')
end

disp('get_covid_global_hopkins: exit.')

