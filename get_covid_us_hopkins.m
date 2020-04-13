function [tableConfirmed,tableDeaths,tableRecovered,time] = get_covid_us_hopkins( source, directory )
% get_covid_us_hopkins() gets US data from the COVID-19 epidemy from the
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

tableRecovered = [];

%% Import the data

status = {'confirmed','deaths'};

address = 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/';

%          https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/

for i=1:numel(status)
    
    filename = [directory,'time_series_covid19_',status{i},'_US.csv'];
    
    if ( strcmp (source, 'online'))
        
        fullName = [address, filename];
        websave(filename, fullName );
        
    end
    
    opts = detectImportOptions(filename);
    
    opts.VariableNames(6) = {'City'};           % Admin2
    opts.VariableNames(7) = {'ProvinceState'};  % Province_State
    opts.VariableNames(8) = {'CountryRegion'};  % Country_Region
    opts.VariableNames(9) = {'Lat'};
    opts.VariableNames(10) = {'Long'};    
    opts.VariableNames(11) = {'Combined_Key'};
    
    % Specify file level properties
    opts.ExtraColumnsRule = "ignore";
    opts.EmptyLineRule = "read";
    
    if strcmpi(status{i},'Confirmed')
        tableConfirmed =readtable(filename, opts);
        tableConfirmed.Var1 = []; % al
        tableConfirmed.Var2 = []; % is02
        tableConfirmed.Var3 = []; % is03
        tableConfirmed.Var4 = []; % code3
        tableConfirmed.Var5 = []; % FIPS
        
    elseif strcmpi(status{i},'Deaths')
        tableDeaths =readtable(filename, opts);
        tableDeaths.Properties.VariableNames(12) = {'Population'};
        tableDeaths.Var1 = []; % al
        tableDeaths.Var2 = []; % is02
        tableDeaths.Var3 = []; % is03
        tableDeaths.Var4 = []; % code3
        tableDeaths.Var5 = []; % FIPS

    else
        error('Unknown status')
    end
    
end

%% TIME

fid = fopen(filename);
time_str = textscan(fid,repmat('%s',1,size(tableDeaths,2)), 1, 'Delimiter',',');
time = datetime( [time_str{13:end}] ) + years(2000);
fclose(fid);

end

