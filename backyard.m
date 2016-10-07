%% old code

% initial TM1_2
% result.TM1_2 = result.TM1_1;

% calculate
% result.gasholder(:,1) = input.market.gasprice/input.gasholder.efficiency;
% gasholdercosts = input.market.heatprice - input.market.gasprice/input.gasholder.efficiency;

% result.TM1_2(result.CM_el < gasholdercosts) = result.heatdemand(result.CM_el < gasholdercosts) * input.plant.peakpower_el * (phase1.th_efficiency/phase1.el_efficiency) * gasholdercosts;

%% add storagelevel 
% inital toalprofit2
% result.TM1_3 = result.TM1_1;
% if (input.storage.capacity > 0)
%     % Initial storage level
%     result.storagelevel(1) = 0.5;
%         for i = 2:height(result)
%             switch result.phase(i)
%                 case input.plant.partialload.phase1.powerlevel
%                     phase = input.plant.partialload.phase1;
% 
%                 case input.plant.partialload.phase2.powerlevel
%                     phase = input.plant.partialload.phase2;
% 
%                 case input.plant.partialload.phase3.powerlevel
%                     phase = input.plant.partialload.phase3;
%             end
%             % i = i
%             % if i == 24
%             %    x = 1
%             % end
% 
%             %% charge storage if CM_el is positive or equal 0
%             if (result.CM_el(i) >= 0)
%                 input.plant.state(1,1) = 1; % turn on power plant 
%                 result.storagelevel(i) = result.storagelevel(i-1) + ((1-result.newdemand(i)) * phase.powerlevel * input.plant.peakpower_el * (phase.th_efficiency/phase.el_efficiency))/input.storage.capacity;
%                 if result.storagelevel(i) >= 1
%                     result.storagelevel(i) = 1;
%                 end
% 
%             % neither charge nor discharge if CM_el is positive and the
%             % storage is full
%             % elseif (result.CM_el(i)>0) && (result.storagelevel(i-1) >= 1)
%             %    input.plant.state(1,1) = 1; % turn on power plant
%             %    result.storagelevel(i) = result.storagelevel(i-1); 
% 
%             % discharge storage if CM_el is negative and storage can
%             % supply demand completly and TurnOn Costs are lower then the loss
% 
%             %% charge storage if CM_el is negative but the storage level is to low  
%             elseif (result.CM_el(i) < 0) && ((result.storagelevel(i-1) * input.storage.capacity) < (result.heatdemand(i) * input.plant.peakpower_el * (phase1.th_efficiency/phase1.el_efficiency)))   
%                 input.plant.state(1,1) = 1;
%                 result.storagelevel(i) = result.storagelevel(i-1) + ((1-result.newdemand(i)) * phase.powerlevel * input.plant.peakpower_el * (phase.th_efficiency/phase.el_efficiency))/input.storage.capacity; 
%                 if result.storagelevel(i) > 1
%                 result.storagelevel(i) = 1;
%                 end
% 
%             %% discharge storage if loss is higer then turnon costs      
%             else % for the elseif condition: (result.CM_el(i) < 0) && ((result.storagelevel(i-1) * input.storage.capacity) >= (result.heatdemand(i) * input.plant.peakpower_el * (phase1.th_efficiency/phase1.el_efficiency)))
%                 k = 0;
%                 sumTM1_1 = 0;
%                 % calculate cumulated loss
%                 while result.CM_el(i+k) <= 0
%                     sumTM1_1 = sumTM1_1 + result.TM1_1(i+k);
%                     if i + k >= height(result)
%                         break
%                     end 
%                     k = k + 1;
%                 end
% 
%                 % check if cumulated loss is higher then turn on costs     
%                 if abs(sumTM1_1) > input.plant.startup % discharge storage 
%                     input.plant.state(1,1) = 0;
%                     result.storagelevel(i) = result.storagelevel(i-1) - (result.heatdemand(i) * input.plant.peakpower_el * (phase1.th_efficiency/phase1.el_efficiency))/input.storage.capacity;
%                     result.TM1_3(i) = result.heatdemand(i) * input.plant.peakpower_el * (phase1.th_efficiency/phase1.el_efficiency) * input.market.heatprice;
%                     result.usage(i) = 3; % equal to storage
%                 % charge storage beacause loss is lower then turnon costs
%                 else 
%                     input.plant.state(1,1) = 1;
%                     result.storagelevel(i) = result.storagelevel(i-1) + ((1-result.newdemand(i)) * phase.powerlevel * input.plant.peakpower_el * (phase.th_efficiency/phase.el_efficiency))/input.storage.capacity; 
%                     if result.storagelevel(i) > 1
%                         result.storagelevel(i) = 1;
%                     end
%                 end       
%             end
%         end
% end

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
% entCond = result.cum_loss1 - input.plant.startup < 0;
% result.usage(entCond) = 2;

% Exit Condition
% helpArray = result.cum_loss1(result.usage == 2) < 0 & result.cum_loss1(result.usage == 2) > (input.plant.startup * -1);
% extCond = result.cum_loss1(helpArray == 1) > (input.plant.startup * -1);
% input.plant.startup < 0;
% result.usage(extCond) = 1;

% result.TM1_2(result.usage == 2) = result.gasholder_profit(result.usage == 2) .* result.abs_heatdemand(result.usage == 2);