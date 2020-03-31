function [tableConfirmed,tableDeaths,tableRecovered,time] = getDataCOVID_2()


Ndays = floor(now)-datenum(2020,01,22)-1; % minus one day because the data are updated with a delay of 24 h


status = {'confirmed','deaths','recovered'};
url = 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/';
ext = '.csv';

for ii=1:numel(status)
    
    filename = ['time_series_covid19_',status{ii},'_global.csv'];
    fullurl = [url, filename];
%     disp(fullName)
%     urlwrite(fullName,'dummy.csv');
    websave(filename, fullurl );
    
% For more information, see the TEXTSCAN documentation.
formatNum = repmat(' %s',1, Ndays+3);
formatSpec = ['%s %s', formatNum];


%% Open the text file.
fileID = fopen(filename,'r');

covid_data = textscan( fileID, formatSpec, 'Delimiter',',' );

dumb = 0;    
    
%     if strcmpi(status{ii},'Confirmed')
%         tableConfirmed =readtable('dummy.csv', opts);
%         
%     elseif strcmpi(status{ii},'Deaths')
%         tableDeaths =readtable('dummy.csv', opts);
%         
%     elseif strcmpi(status{ii},'Recovered')
%         tableRecovered =readtable('dummy.csv', opts);
%     else
%         error('Unknown status')
%     end
end

