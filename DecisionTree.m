%% This script calculate which power source should be used. 
% Standard use is CHP
% afterwards try to use gasholder and/or storage

%% Conditions to use gas_holder
result.TM1_2 = result.TM1_1;
if input.gasholder.value == 1
%     % Entry Condition
%     % Option 1:
%     helpArray = result.gasholder_profit .* result.abs_heatdemand; 
%     % entrCond = helpArray > result.TM1_1; 
%     % Option 2: Use gas holder only if startup costs are lesser then cum_loss1 or startup costs are higher the cum_loss 
%     entrCond = helpArray > result.TM1_1
%     result.usage(entrCond) = 2;
%     
%     % Exit Condition: Where switch to gas holder use is less profitable then cum_loss  
%     extCond = result.cum_loss > input.plant.startup;
%     result.usage(extCond) = 1;
%     
%     result.TM1_2(result.usage == 2) = result.gasholder_profit(result.usage == 2) .* result.abs_heatdemand(result.usage == 2);

% Entry Condition 
entCond = result.cum_loss1 - input.plant.startup < 0;
result.usage(entCond) = 2;

% Exit Condition
extCond = (result.cum_loss1(result.usage == 2) * -1) - input.plant.startup < 0
result.usage(extCond) = 1;

result.TM1_2(result.usage == 2) = result.gasholder_profit(result.usage == 2) .* result.abs_heatdemand(result.usage == 2);
end

%% Condition to use storage
result.TM1_3 = result.TM1_2;
if input.storage.value == 1
    result.storagelevel(1) = 0.5;
    for i = 2:height(result)
        if result.storagelevel(i-1) * input.plant.peakpower_th >= result.newdemand(i) * result.phasepower_th(i) 
            dischargeStorage;
        elseif result.usage(i) == 1    
            chargeStorage; 
        else
            result.storagelevel(i) = result.storagelevel(i-1);
        end
    end
end

    


