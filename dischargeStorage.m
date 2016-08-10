%% This script discharge the storage

% Conditions for discharge
% 1. Contribution margin of CHP (1) must be negative
% 2. Cummulative lost must be higher then input.plant.startup


if result.cum_loss(i) * -1 > input.plant.startup | result.usage(i) == 2    
    result.storagelevel(i) = result.storagelevel(i-1) - (result.newdemand(i)) * result.phasepower_th(i) / input.storage.capacity;
    result.TM1_3(i) = result.newdemand(i) * result.phasepower_th(i) * input.market.heatprice;
    result.usage(i) = 3; % equal to storage
end
       
% end