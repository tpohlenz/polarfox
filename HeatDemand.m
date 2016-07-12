function [exportArray,helpArray] = HeatDemand(Temperature,maxtemperature,mintemperature)
% HeatDemand calculates the hourly heat demand based on hourly temperature
% value array. 
% Scale:    above maxtemperature --> 10 % heat demand
%           below maxtempartaure --> creates linear function 
% Caution:  Results can be above 100%!
% To Do: Scale as an input from the GUI! --> 15.03.2016: first
% implementation




% Smooth temprature based on 1,2 and 3 day`s back  
helpArray(1:length(Temperature),1) = 0;
helpArray(1:72,1) = Temperature(1:72,1);
for i = 73:length(Temperature)
    helpArray(i,1) = (Temperature(i)+0.5*Temperature(i-24)+0.25*Temperature(i-48)+0.125*Temperature(i-72))/1.875; 
end

% create linear function below 15 °C; Goal: y = mx + n
m = (0.1-1)/(maxtemperature-mintemperature);
n = 0.1-(m*maxtemperature);


% calculate the heat demand based on the scaling
exportArray(1:length(helpArray),1) = 0;
    for i = 1:length(helpArray)
        if helpArray(i) > maxtemperature
            exportArray(i,1) = 0.1; 
        % elseif helpArray(i) < -5  Begrenzung auf 100 % ab -5 °C
        %    exportArray(i,1) = 1;
        else
            exportArray(i,1) = m*helpArray(i)+n; 
        end
       
    end
end