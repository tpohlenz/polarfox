function result = chpratingbackend_v21(input)

% Column renaming from total profit to Contributuion Margin
% (Deckungsbeitrag) - Short: CM

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
result.usage(:,1) = {'CHP'};

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

% calculate
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
        % charge storage if CM_el is positive
        if (result.CM_el(i)>0) && (result.storagelevel(i-1) < 1)
            result.storagelevel(i) = result.storagelevel(i-1) + ((1-result.newdemand(i)) * phase.powerlevel * input.plant.peakpower * (phase.th_efficiency/phase.el_efficiency))/input.storage.capacity;
            if result.storagelevel(i) > 1
                result.storagelevel(i) = 1;
            end
            
        % neither charge nor discharge if CM_el is positive and the
        % storage is full
        elseif (result.CM_el(i)>0) && (result.storagelevel(i-1) >= 1)
            result.storagelevel(i) = result.storagelevel(i-1); 
            
        % discharge storage if CM_el is negative  -> only if storage can
        % supply demand completly 
        elseif (result.CM_el(i)<0) && ((result.storagelevel(i-1) * input.storage.capacity) >= (result.heatdemand(i) * input.plant.peakpower * (phase1.th_efficiency/phase1.el_efficiency)))
            result.storagelevel(i) = result.storagelevel(i-1) - (result.heatdemand(i) * input.plant.peakpower * (phase1.th_efficiency/phase1.el_efficiency))/input.storage.capacity;
            result.TM1_3(i) = result.heatdemand(i) * input.plant.peakpower * (phase1.th_efficiency/phase1.el_efficiency) * input.market.heatprice;
            result.usage(i) = {'storage'};
            
        % old: charge storage if CM_el is negative but the storage level is to low  
        % new: use gas holder instead --> deactivated
        else
            
            result.storagelevel(i) = result.storagelevel(i-1) + ((1-result.newdemand(i)) * phase.powerlevel * input.plant.peakpower * (phase.th_efficiency/phase.el_efficiency))/input.storage.capacity; 
            if result.storagelevel(i) > 1
            result.storagelevel(i) = 1;
            end
        
        end
    end
    

end



