function tableCOVIDItaly = getDataCOVID_ITA(fileURL, dataLines)
% The function tableCOVIDItaly = getDataCOVID
% collects the updated data of the COVID-19 pandemic in Italy from the
% Italian governement [1]
% 
% References:
% [1] https://github.com/pcm-dpc/COVID-19
% 
% Author: Matteo Seclì - Last modified - 22-03-2020
% 
% see also fit_SEIQRDP.m SEIQRDP.m

%% Input handling
% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
    if nargin < 1
        fileURL = 'https://raw.githubusercontent.com/pcm-dpc/COVID-19/master/dati-regioni/dpc-covid19-ita-regioni.csv';
    end
end

%% Setup the Import Options and import the data

% Download the CSV file
filename = 'dpc-covid19-ita-regioni.csv.csv';
websave(filename,fileURL);
opts = detectImportOptions(filename);

% Set the number of columns
% opts = delimitedTextImportOptions('NumVariables', 16);

% Specify range and delimiter
% opts.DataLines = dataLines;
% opts.Delimiter = ',';

% Specify column names and types
% data, stato, codice_regione, denominazione_regione, lat, long, 
% ricoverati_con_sintomi, terapia_intensiva, totale_ospedalizzati, 
% isolamento_domiciliare, totale_attualmente_positivi, nuovi_attualmente_positivi, 
% dimessi_guariti, deceduti, totale_casi, tamponi, note_it, note_en

opts.VariableNames(1:end) = { 'Date' , 'CountryCode', 'RegionCode', 'RegionName', 'Lat'   , 'Long'  , ... 
    'HospitalizedWithSymptoms', 'HospitalizedInIntensiveCare', 'Hospitalized', ... 
    'Quarantined', 'Positive' , 'NewPositive' , ... 
    'Recovered', 'Deaths',  'Confirmed', 'Tested', 'Note_IT' , 'Note_EN' }; % 'NewQuarantined', 
opts.VariableTypes = {'string', 'string' , 'uint8' , 'string' , 'double' ,  'double' , ... 
    'double' , 'double', 'double' , 'double'  , 'double' , 'double' , 'double' , ... 
    'double', 'double' , 'double', 'string', 'string' };

% Specify file level properties
opts.ExtraColumnsRule = 'ignore';
opts.EmptyLineRule = 'read';

% Specify variable properties
% Can create an error with older Matlab versions
% opts = setvaropts(opts, 'Date', 'InputFormat', 'yyyy-MM-dd HH:mm:ss'); % Use 'Format','yyyy-MM-dd'T'HH:mm:ss' from Mar 23, 2020 on


% Import the data
fid = fopen(filename);
tableCOVIDItaly = readtable(filename, opts);
fclose(fid);


end
