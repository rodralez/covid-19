function tableData = improve_covid_global_hopkins( tableData )
% improve_covid_global_hopkins
% get_covid_global_hopkins() sorts and add data to the  global data from the COVID-19 epidemy from the
% John Hopkins university [1]. e.
%
% References:
% [1] https://github.com/CSSEGISandData/COVID-19
%
% Version: 001
% Date:    2020/04/02
% Author:  Rodrigo Gonzalez <rodralez@frm.utn.edu.ar>
% URL:     https://github.com/rodralez/navego

tableData = sortrows(tableData, 2);


%% Some countries have only data for provinces but not for the whole country as China.

idx = 1;

tsize = size(tableData, 1);

while ( idx < tsize )
    
    country = tableData.CountryRegion(idx);
    
    ldx = contains( tableData.CountryRegion, country );
    province_count = sum(  ldx );
    mdx = ismissing( tableData.ProvinceState(ldx), '');
    province_missing = sum(  mdx );
    
    % if there are several rows for a country but no row for the country only...
    if (province_count > 1 & province_missing == 0)
        
        country_total = sum ( table2array(tableData(ldx, 5:end) ) );
        
        t1 = table( {''}, country, 0, 0 );
        t2 = [t1, array2table( country_total ) ];
        t2.Properties.VariableNames = tableData.Properties.VariableNames;
        
        tableData = [tableData; t2];
        
        idx = idx + province_count;
        
        % if there are several rows for a country and a row for the country only...
    elseif  (province_count > 1 & province_missing == 1)
        
        idx = idx + province_count;
        
        % if there is a  only one row for the country...
    else
        idx = idx + 1;
    end
end

%% ADD POPULATION

filename = './hopkins/WPP2019_TotalPopulationBySex.csv';

opts = detectImportOptions(filename);

tablePop = readtable(filename, opts);

% Only year 2020
tablePop( ~ismember (tablePop.Time, 2020) , :)=[];
% Only medium values
tablePop( ~ismember (tablePop.Variant, 'Medium') , :)=[];

for idx = 1:size(tableData, 1)
    
    country = tableData.CountryRegion( idx );

    % Special cases
    if (strcmp( country, 'US')), country = 'United States of America'; end
    if (strcmp( country, 'Vietnam')), country = 'Viet Nam'; end
    if (strcmp( country, 'Korea, South')), country = 'Republic of Korea'; end
    
    ldx = strcmp(  tablePop.Location, country );    
    NPop = tablePop.PopTotal ( ldx ) * 1000;   
    
    if (~ any(ldx))        
    
        ldx = contains(  tablePop.Location, country );
        NPop = tablePop.PopTotal ( ldx ) * 1000;   
        
        if (~ any(ldx))
            
            NPop = Inf;
        end
    end
    
    tableData.Population (idx) = NPop;
end

%% 

tableData = sortrows(tableData, 2);

