function [tableConfirmed,tableDeaths,tableRecovered,time] = get_data_covid_harpomaxx( source )
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

address = 'https://raw.githubusercontent.com/harpomaxx/COVID19/master/';

filename = 'COVID19_ARG.tsv';

if ( strcmp (source, 'online'))
    
    fullName = [address, filename];
    websave(filename, fullName );
    
end

opts = detectImportOptions(filename, 'FileType','text'); % , 'Delimiter', '\b\t'

table_dumb = readtable(filename, opts);

time = table_dumb{:,1};

tableConfirmed = table_dumb{:,2};
    
tableDeaths = table_dumb{:,3};
    
%% ESTE DATO NO ESTA TODAVIA
tableRecovered = table_dumb{:,7};

%%

% fid = fopen(filename);
% time = textscan(fid, repmat('%s',1, size(tableConfirmed,1) ));
% time = time {1,1};
% time = datetime([time{1:end}])+years(2000);
% fclose(fid);

end

