%% This script calculate which power source should be used. 
% Standard use is CHP
% afterwards try to use gasholder and/or storage

%% Conditions to use gas_holder
result.TM1_2 = result.TM1_1;
if input.gasholder.enable == 1
    helpArray = result.gasholder_profit .* result.abs_heatdemand;
    for i = 2:height(result)
        if helpArray(i) > result.TM1_1(i) %  condition to use gas holder
            if result.usage(i-1) == 2 % remain if gas holder is already in use, continue using
                result.usage(i) = 2;
            elseif result.cum_loss3(i) - result.cum_loss2(i) > input.plant.startup % Entry Condition: if gas holder is not in use, profit by using gas holder mut be higher then startup costs  
                result.usage(i) = 2; 
            end
        elseif result.usage(i-1) == 2 & result.cum_loss3(i) - result.cum_loss2(i) > input.plant.startup % remain condition if gas holder TM is lesser then chp TM  
            result.usage(i) = 2;
        end
    end
end

%% Condition to use storage
result.TM1_3 = result.TM1_2;
if input.storage.enable == 1 
    result.storagelevel(1) = 0.5;
    for i = 2:height(result)
        
        if result.storagelevel(i-1) * input.storage.capacity >= result.newdemand(i) * result.phasepower_th(i) & ... % storage must be able to fullfill demand to 100 %  
           (result.usage(i) == 2 | result.cum_loss4(i) - result.cum_loss2(i) > input.plant.startup) % (result.storagelevel(i) * input.storage.capacity * input.market.heatprice) - result.cum_loss2(i) > input.plant.startup) 
            dischargeStorage; 
        elseif result.usage(i) == 1     
            chargeStorage; 
        else
            result.storagelevel(i) = result.storagelevel(i-1);
        end
    end
    
end

 %% result.CM_el(i) < 0 &
    


