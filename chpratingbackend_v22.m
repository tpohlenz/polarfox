function result = chpratingbackend_v22(input)

% Column renaming from total profit to Contributuion Margin
% (Deckungsbeitrag) - Short: CM

% 1 = CHP
% 2 = gas holder 
% 3 = storage

% TM1_1 - total margin with heat revenue & electricity revenue 
% TM1_2 - total margin with heat revenue, electricity revenue OR gas holder
% usage
% TM1_3 - total margin with heat revenue & electricity revenue OR storage
% usage

%% initial output table
result = table;

%% calculate heat demand 
result.heatdemand = HeatDemand(input.heatdemand.currentyear,input.heatdemand.maxtemperature,input.heatdemand.mintemperature);

%% partial load depending
% initial table columns 
result.phase(:,1) = 0;
result.newdemand(:,1) = 0;
result.heatrevenue(:,1) = 0;
result.variablecost(:,1) = 0;
result.CM_th(:,1) = 0;
result.eexprice = input.market.electricity.currentyear;
result.CM_el(:,1) = 0;
result.storagelevel (:,1) = 0; 
result.gasholder(:,1) = 0; 
result.TM1_1(:,1) = 0;
result.TM1_2(:,1) = 0;
result.TM1_3(:,1) = 0;
result.usage(:,1) = 1;  % equal to CHP 

% get partial load powerlevel informations
phase1 = input.plant.partialload.phase1;
phase2 = input.plant.partialload.phase2;
phase3 = input.plant.partialload.phase3;

% determine partial load case
result.phase(:,1) = phase1.powerlevel;
result.phase(result.heatdemand<=phase2.powerlevel) = phase2.powerlevel;
result.phase(result.heatdemand<=phase3.powerlevel) = phase3.powerlevel;

% calculate demand based on the partial load cases
result.newdemand(result.phase==phase1.powerlevel) = result.heatdemand(result.phase==phase1.powerlevel);
result.newdemand(result.newdemand>=1) = 1;                              % <-- limitation on maximum power    
result.newdemand(result.phase==phase2.powerlevel) = result.heatdemand(result.phase==phase2.powerlevel)/phase2.powerlevel;
result.newdemand(result.phase==phase3.powerlevel) = result.heatdemand(result.phase==phase3.powerlevel)/phase3.powerlevel;

% calculate heat revenue
result.heatrevenue(result.phase==phase1.powerlevel) = (phase1.th_efficiency/phase1.el_efficiency) * result.newdemand(result.phase==phase1.powerlevel) * input.market.heatprice;  
result.heatrevenue(result.phase==phase2.powerlevel) = (phase2.th_efficiency/phase2.el_efficiency) * result.newdemand(result.phase==phase2.powerlevel) * input.market.heatprice;
result.heatrevenue(result.phase==phase3.powerlevel) = (phase3.th_efficiency/phase3.el_efficiency) * result.newdemand(result.phase==phase3.powerlevel) * input.market.heatprice;

% calculate variablecost
result.variablecost(result.phase==phase1.powerlevel) = input.market.gasprice/phase1.el_efficiency;
result.variablecost(result.phase==phase2.powerlevel) = input.market.gasprice/phase2.el_efficiency;
result.variablecost(result.phase==phase3.powerlevel) = input.market.gasprice/phase3.el_efficiency;

% calculate CM_th --> equal to marginal cost for electricity 
result.CM_th = result.heatrevenue - result.variablecost;

% calculate CM_el
result.CM_el =  result.eexprice + result.CM_th;
        
%% calculate total margin without storage
result.TM1_1(result.phase==phase1.powerlevel) = result.CM_el(result.phase==phase1.powerlevel) * input.plant.partialload.phase1.powerlevel * input.plant.peakpower;
result.TM1_1(result.phase==phase2.powerlevel) = result.CM_el(result.phase==phase2.powerlevel) * input.plant.partialload.phase2.powerlevel * input.plant.peakpower;
result.TM1_1(result.phase==phase3.powerlevel) = result.CM_el(result.phase==phase3.powerlevel) * input.plant.partialload.phase3.powerlevel * input.plant.peakpower;

%% add gas holder 
% initial TM1_2
% result.TM1_2 = result.TM1_1;

% calculate
% result.gasholder(:,1) = input.market.gasprice/input.gasholder.efficiency;
% gasholdercosts = input.market.heatprice - input.market.gasprice/input.gasholder.efficiency;

% result.TM1_2(result.CM_el < gasholdercosts) = result.heatdemand(result.CM_el < gasholdercosts) * input.plant.peakpower * (phase1.th_efficiency/phase1.el_efficiency) * gasholdercosts;

%% add storagelevel 
% inital toalprofit2
result.TM1_3 = result.TM1_1;
if (input.storage.capacity > 0)
    % Initial storage level
    result.storagelevel(1) = 0.5;
        for i = 2:height(result)
            switch result.phase(i)
                case input.plant.partialload.phase1.powerlevel
                    phase = input.plant.partialload.phase1;

                case input.plant.partialload.phase2.powerlevel
                    phase = input.plant.partialload.phase2;

                case input.plant.partialload.phase3.powerlevel
                    phase = input.plant.partialload.phase3;
            end
            % i = i
            % if i == 24
            %    x = 1
            % end

            %% charge storage if CM_el is positive or equal 0
            if (result.CM_el(i) >= 0)
                input.plant.state(1,1) = 1; % turn on power plant 
                result.storagelevel(i) = result.storagelevel(i-1) + ((1-result.newdemand(i)) * phase.powerlevel * input.plant.peakpower * (phase.th_efficiency/phase.el_efficiency))/input.storage.capacity;
                if result.storagelevel(i) >= 1
                    result.storagelevel(i) = 1;
                end

            % neither charge nor discharge if CM_el is positive and the
            % storage is full
            % elseif (result.CM_el(i)>0) && (result.storagelevel(i-1) >= 1)
            %    input.plant.state(1,1) = 1; % turn on power plant
            %    result.storagelevel(i) = result.storagelevel(i-1); 

            % discharge storage if CM_el is negative and storage can
            % supply demand completly and TurnOn Costs are lower then the loss

            %% charge storage if CM_el is negative but the storage level is to low  
            elseif (result.CM_el(i) < 0) && ((result.storagelevel(i-1) * input.storage.capacity) < (result.heatdemand(i) * input.plant.peakpower * (phase1.th_efficiency/phase1.el_efficiency)))   
                input.plant.state(1,1) = 1;
                result.storagelevel(i) = result.storagelevel(i-1) + ((1-result.newdemand(i)) * phase.powerlevel * input.plant.peakpower * (phase.th_efficiency/phase.el_efficiency))/input.storage.capacity; 
                if result.storagelevel(i) > 1
                result.storagelevel(i) = 1;
                end

            %% discharge storage if loss is higer then turnon costs      
            else % for the elseif condition: (result.CM_el(i) < 0) && ((result.storagelevel(i-1) * input.storage.capacity) >= (result.heatdemand(i) * input.plant.peakpower * (phase1.th_efficiency/phase1.el_efficiency)))
                k = 0;
                sumTM1_1 = 0;
                % calculate cumulated loss
                while result.CM_el(i+k) <= 0
                    sumTM1_1 = sumTM1_1 + result.TM1_1(i+k);
                    if i + k >= height(result)
                        break
                    end 
                    k = k + 1;
                end

                % check if cumulated loss is higher then turn on costs     
                if abs(sumTM1_1) > input.plant.startup % discharge storage 
                    input.plant.state(1,1) = 0;
                    result.storagelevel(i) = result.storagelevel(i-1) - (result.heatdemand(i) * input.plant.peakpower * (phase1.th_efficiency/phase1.el_efficiency))/input.storage.capacity;
                    result.TM1_3(i) = result.heatdemand(i) * input.plant.peakpower * (phase1.th_efficiency/phase1.el_efficiency) * input.market.heatprice;
                    result.usage(i) = 3; % equal to storage
                % charge storage beacause loss is lower then turnon costs
                else 
                    input.plant.state(1,1) = 1;
                    result.storagelevel(i) = result.storagelevel(i-1) + ((1-result.newdemand(i)) * phase.powerlevel * input.plant.peakpower * (phase.th_efficiency/phase.el_efficiency))/input.storage.capacity; 
                    if result.storagelevel(i) > 1
                        result.storagelevel(i) = 1;
                    end
                end       
            end
        end
end
    
end



