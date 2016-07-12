function result = chpratingbackend_v21(input)

% Test Comment
% Test Comment 2
%% initial output table
result = table;

%% calculate heat demand 
result.heatdemand = HeatDemand(input.heatdemand.currentyear,input.heatdemand.maxtemperature,input.heatdemand.mintemperature);

%% partial load depending
% initial table columns 
result.phase(:,1) = 0;
result.newdemand(:,1) = 0;
result.heatrevenue(:,1) = 0;
result.marginalcost(:,1) = 0;
result.remainingcost(:,1) = 0;
result.eexprice = input.market.electricity.currentyear;
result.profit(:,1) = 0;
result.storagelevel (:,1) = 0; 
result.gasholder(:,1) = 0; 
result.totalprofit(:,1) = 0;
result.totalprofit1(:,1) = 0;
result.totalprofit2(:,1) = 0;
result.usage(:,1) = 0;

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

% calculate marginalcost
result.marginalcost(result.phase==phase1.powerlevel) = input.market.gasprice/phase1.el_efficiency;
result.marginalcost(result.phase==phase2.powerlevel) = input.market.gasprice/phase2.el_efficiency;
result.marginalcost(result.phase==phase3.powerlevel) = input.market.gasprice/phase3.el_efficiency;

% calculate remainingcost --> equal to marginal cost for electricity 
result.remainingcost = result.marginalcost - result.heatrevenue;

% calculate profit
result.profit =  result.eexprice - result.remainingcost;
        
%% calculate total profit
result.totalprofit(result.phase==phase1.powerlevel) = result.profit(result.phase==phase1.powerlevel) * input.plant.partialload.phase1.powerlevel * input.plant.peakpower;
result.totalprofit(result.phase==phase2.powerlevel) = result.profit(result.phase==phase2.powerlevel) * input.plant.partialload.phase2.powerlevel * input.plant.peakpower;
result.totalprofit(result.phase==phase3.powerlevel) = result.profit(result.phase==phase3.powerlevel) * input.plant.partialload.phase3.powerlevel * input.plant.peakpower;

%% add gas holder 
% initial totalprofit1
result.totalprofit1 = result.totalprofit;

% calculate
result.gasholder(:,1) = input.market.gasprice/input.gasholder.efficiency;
gasholdercosts = input.market.heatprice - input.market.gasprice/input.gasholder.efficiency;

result.totalprofit1(result.profit < gasholdercosts) = result.heatdemand(result.profit < gasholdercosts) * input.plant.peakpower * (phase1.th_efficiency/phase1.el_efficiency) * gasholdercosts;

%% add storagelevel 
% inital toalprofit2
result.totalprofit2(:,1) = 0;

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
        % charge storage if profit is positive
        if (result.profit(i)>0) && (result.storagelevel(i-1) < 1)
            result.storagelevel(i) = result.storagelevel(i-1) + ((1-result.newdemand(i)) * phase.powerlevel * input.plant.peakpower * (phase.th_efficiency/phase.el_efficiency))/input.storage.capacity;
            if result.storagelevel(i) > 1
                result.storagelevel(i) = 1;
            end
            
        % neither charge nor discharge if profit is positive and the
        % storage is full
        elseif (result.profit(i)>0) && (result.storagelevel(i-1) >= 1)
            result.storagelevel(i) = result.storagelevel(i-1); 
            
        % discharge storage if profit is negative  -> only if storage can
        % supply demand completly 
        elseif (result.profit(i)<0) && ((result.storagelevel(i-1) * input.storage.capacity) >= (result.heatdemand(i) * input.plant.peakpower * (phase1.th_efficiency/phase1.el_efficiency)))
            result.storagelevel(i) = result.storagelevel(i-1) - (result.heatdemand(i) * input.plant.peakpower * (phase1.th_efficiency/phase1.el_efficiency))/input.storage.capacity;
            result.totalprofit2(i) = result.heatdemand(i) * input.plant.peakpower * (phase1.th_efficiency/phase1.el_efficiency) * input.market.heatprice;
            % result.usage(i) = 3;
            
        % old: charge storage if profit is negative but the storage level is to low  
        % new: use gas holder instead 
        else
            
            % result.storagelevel(i) = result.storagelevel(i-1) + ((1-result.newdemand(i)) * phase.powerlevel * input.plant.peakpower * (phase.th_efficiency/phase.el_efficiency))/input.storage.capacity; 
            % if result.storagelevel(i) > 1
            %    result.storagelevel(i) = 1;
            % end
        
        end
    end
    

end



