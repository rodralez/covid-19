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
    
end

%% Import the data

status = {'confirmed','deaths','recovered'};

address = 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/';

for i=1:numel(status)
    
    filename = [directory,'time_series_covid19_',status{i},'_global.csv'];
    
    if ( strcmp (source, 'online'))
        
        fullName = [address, filename];
        websave(filename, fullName );
        
    end
    
    opts = detectImportOptions(filename);

    opts.VariableNames(1) = {'ProvinceState'};
    opts.VariableNames(2) = {'CountryRegion'};
    opts.VariableNames(3) = {'Lat'};
    opts.VariableNames(4) = {'Long'};    
%     opts.HeaderLines = 1;  
    
    % Specify file level properties
    opts.ExtraColumnsRule = "ignore";
    opts.EmptyLineRule = "read";
    
    if strcmpi(status{i},'Confirmed')
        tableConfirmed = readtable(filename, opts);
        tableConfirmed = tableConfirmed(2:end,:); % First line is header and is descarted
        tableConfirmed = improve_covid_global_hopkins( tableConfirmed );
                 
    elseif strcmpi(status{i},'Deaths')
        tableDeaths = readtable(filename, opts);
        tableDeaths = tableDeaths(2:end,:); % First line is header and is descarted
        tableDeaths = sortrows(tableDeaths, 2);
        tableDeaths = improve_covid_global_hopkins( tableDeaths );
        
    elseif strcmpi(status{i},'Recovered')
        tableRecovered = readtable(filename, opts);
        tableRecovered = tableRecovered(2:end,:); % First line is header and is descarted
        tableRecovered = sortrows(tableRecovered, 2);   
        tableRecovered = improve_covid_global_hopkins( tableRecovered );
    else
        error('Unknown status')
    end
end

%% TIME

fid = fopen(filename);
time_str = textscan(fid,repmat('%s',1,size(tableRecovered,2)), 1, 'Delimiter',',');
time = datetime( [time_str{5:end}] ) + years(2000);
fclose(fid);


