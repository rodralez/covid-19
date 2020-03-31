function [tableConfirmed,tableDeaths,tableRecovered,time] = get_data_covid_hopkins( source )
% The function [tableConfirmed,tableDeaths,tableRecovered,time] = getDataCOVID
% collect the updated data from the COVID-19 epidemy from the
% John Hopkins university [1]
% 
% References:
% [1] https://github.com/CSSEGISandData/COVID-19
% 
% Author: E. Cheynet - Last modified - 20-03-2020
% 
% see also fit_SEIQRDP.m SEIQRDP.m

%% Input handling

if nargin < 1
    
    source = 'offline';
    
end

%% Import the data

status = {'confirmed','deaths','recovered'};

address = 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/';

for i=1:numel(status)
    
    filename = ['time_series_covid19_',status{i},'_global.csv'];
    
    if ( strcmp (source, 'online'))
        
        fullName = [address, filename];
        websave(filename, fullName );
        
    end
    
    opts = detectImportOptions(filename);

    opts.VariableNames(1) = {'ProvinceState'};
    opts.VariableNames(2) = {'CountryRegion'};
    opts.VariableNames(3) = {'Lat'};
    opts.VariableNames(4) = {'Long'};    
     
    % Specify file level properties
    opts.ExtraColumnsRule = "ignore";
    opts.EmptyLineRule = "read";
    
    if strcmpi(status{i},'Confirmed')
        tableConfirmed =readtable(filename, opts);
        
    elseif strcmpi(status{i},'Deaths')
        tableDeaths =readtable(filename, opts);
        
    elseif strcmpi(status{i},'Recovered')
        tableRecovered =readtable(filename, opts);
    else
        error('Unknown status')
    end
end

%% TIME

fid = fopen(filename);
time_str = textscan(fid,repmat('%s',1,size(tableRecovered,2)), 1, 'Delimiter',',');
time = datetime( [time_str{5:end}] ) + years(2000);
fclose(fid);

end

