function [tableConfirmed,tableDeaths,tableRecovered,time] = getDataCOVID_hopking( source )
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


%% Import the data

status = {'confirmed','deaths','recovered'};

address = 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/';
% ext = '.csv';

for ii=1:numel(status)
    
    filename = ['time_series_covid19_',status{ii},'_global.csv'];
    
    
    fullName = [address, filename];
    websave(filename, fullName );
    
    opts = detectImportOptions(filename);

    opts.VariableNames(1) = {'ProvinceState'};
    opts.VariableNames(2) = {'CountryRegion'};
    opts.VariableNames(3) = {'Lat'};
    opts.VariableNames(4) = {'Long'};    
     
    % Specify file level properties
    opts.ExtraColumnsRule = "ignore";
    opts.EmptyLineRule = "read";
    
    if strcmpi(status{ii},'Confirmed')
        tableConfirmed =readtable(filename, opts);
        
    elseif strcmpi(status{ii},'Deaths')
        tableDeaths =readtable(filename, opts);
        
    elseif strcmpi(status{ii},'Recovered')
        tableRecovered =readtable(filename, opts);
    else
        error('Unknown status')
    end
end


fid = fopen(filename);
time = textscan(fid,repmat('%s',1,size(tableRecovered,2)), 1, 'Delimiter',',');
time(1:4)=[];
time = datetime([time{1:end}])+years(2000);
fclose(fid);

% delete('dummy.csv')

end

