function tableData = improve_covid_argentina(tableData)
% FUente: https://www.indec.gob.ar/indec/web/Nivel4-Tema-2-24-85

%% ADD POPULATION

province_name = {'Capital Federal';'Buenos Aires';'Catamarca';'Chaco';'Chubut'; ...
    'Cordoba';'Corrientes';'Entre Rios';'Formosa';'Jujuy';'La Pampa'; ...
    'La Rioja';'Mendoza';'Misiones';'Neuquen';'Rio Negro';'Salta'; ...
    'San Juan';'San Luis';'Santa Cruz';'Santa Fe';'Santiago del Estero';...
    'Tierra del Fuego';'Tucuman'};

population = [ 3075646; 17541141; 415438; 1204541; 618994; ...
    3760450; 1120801; 1385961; 605193; 770881; 358428;...
    393531; 1990338; 1261294; 664057; 747610; 1424397;...
    781217; 508328; 365698; 3536418; 978313;...
    173432; 1694656 ];

for idx = 1:size(tableData, 1)
    
    province = tableData.ProvinceState( idx );
    
    ldx = strcmp( province_name, province );
    
    NPop = population ( ldx );
    
    if (~ any(ldx))
        
        NPop = Inf;
        
    end
    
    tableData.Population ( idx ) = NPop;
end

%% ADD TOTAL VALUES FOR THE COUNTRY

country_total = sum ( (table2array ( tableData(: , 3:end)  ) ) ) ;

t1 = array2table( country_total );
t2 = table( {''}, 'Argentina');
t3 = [t2, t1];

% t1 = table( {''}, 'Argentina',  array2table( country_npop ), array2table( country_data ) );
% t2 = [t1, array2table( country_npop ) ];
t3.Properties.VariableNames = tableData.Properties.VariableNames;

tableData = [tableData; t3];


end