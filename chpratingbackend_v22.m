function result = chpratingbackend_v22(input)

%% Column renaming from total profit to Contributuion Margin
% (Deckungsbeitrag) - Short: CM
% 1 = CHP 2 = gas holder 3 = storage 
% TM1_1 - total margin with heat revenue & electricity revenue 
% TM1_2 - total margin with heat revenue & electricity revenue OR gas holder usage
% TM1_3 - total margin with heat revenue & electricity revenue OR storage
% usage.

%% initial output table
result = table;

%% calculate heat demand 
result.heatdemand = HeatDemand(input.heatdemand.currentyear,input.heatdemand.maxtemperature,input.heatdemand.mintemperature);

%% initial table columns 
result.phase(:,1) = 0;
result.phasepower_th(:,1) = 0;
result.phasepower_el(:,1) = 0;
result.newdemand(:,1) = 0;
result.heatrevenue(:,1) = 0;
result.variablecost(:,1) = 0;
result.CM_th(:,1) = 0;
result.eexprice = input.market.electricity.currentyear;
result.CM_el(:,1) = 0;
result.gasholder_profit(:,1) = 0; 
result.abs_heatdemand(:,1) = 0;
result.storagelevel (:,1) = 0; 
result.TM1_1(:,1) = 0;
result.TM1_2(:,1) = 0;
result.TM1_3(:,1) = 0;
result.cum_loss(:,1) = 0;
result.cum_loss1(:,1) = 0;
result.cum_loss2(:,1) = 0;
result.usage(:,1) = 1;

%% Add CHP funding
if isnumeric(input.market.electricity.funding) == 1 
    result.eexprice = result.eexprice + input.market.electricity.funding;
end

%% get partial load powerlevel informations
phase1 = input.plant.partialload.phase1;
phase2 = input.plant.partialload.phase2;
phase3 = input.plant.partialload.phase3;


%% determine partial load case
% Phase 1
result.phase(:,1) = phase1.powerlevel;
result.phasepower_th(result.phase == phase1.powerlevel) = input.plant.peakpower_th * result.phase(result.phase == phase1.powerlevel);
result.phasepower_el(result.phase == phase1.powerlevel) = input.plant.peakpower_el * result.phase(result.phase == phase1.powerlevel);
% Phase 2
result.phase(result.heatdemand <= phase2.powerlevel) = phase2.powerlevel;
result.phasepower_th(result.phase == phase2.powerlevel) = input.plant.peakpower_th * result.phase(result.phase == phase2.powerlevel);
result.phasepower_el(result.phase == phase2.powerlevel) = input.plant.peakpower_el * result.phase(result.phase == phase2.powerlevel);
% Phase 3
result.phase(result.heatdemand <= phase3.powerlevel) = phase3.powerlevel;
result.phasepower_th(result.phase == phase3.powerlevel) = input.plant.peakpower_th * result.phase(result.phase == phase3.powerlevel);
result.phasepower_el(result.phase == phase3.powerlevel) = input.plant.peakpower_el * result.phase(result.phase == phase3.powerlevel);

%% calculate new demand based on the partial load cases
result.newdemand(result.phase == phase1.powerlevel) = result.heatdemand(result.phase==phase1.powerlevel);
result.newdemand(result.newdemand >= 1) = 1;                              % <-- limitation on maximum power    
result.newdemand(result.phase == phase2.powerlevel) = result.heatdemand(result.phase == phase2.powerlevel) ./ (result.phasepower_th(result.phase == phase2.powerlevel) / input.plant.peakpower_th);
result.newdemand(result.phase == phase3.powerlevel) = result.heatdemand(result.phase == phase3.powerlevel) ./ (result.phasepower_th(result.phase == phase3.powerlevel) / input.plant.peakpower_th);

%% calculate absolute heat demand 
result.abs_heatdemand = result.newdemand .* result.phasepower_th;

%% calculate heat revenue
result.heatrevenue(result.phase == phase1.powerlevel) = (phase1.th_efficiency/phase1.el_efficiency) * result.newdemand(result.phase == phase1.powerlevel) * input.market.heatprice;  
result.heatrevenue(result.phase == phase2.powerlevel) = (phase2.th_efficiency/phase2.el_efficiency) * result.newdemand(result.phase == phase2.powerlevel) * input.market.heatprice;
result.heatrevenue(result.phase == phase3.powerlevel) = (phase3.th_efficiency/phase3.el_efficiency) * result.newdemand(result.phase == phase3.powerlevel) * input.market.heatprice;

%% calculate variablecost
result.variablecost(result.phase == phase1.powerlevel) = input.market.gasprice/phase1.el_efficiency;
result.variablecost(result.phase == phase2.powerlevel) = input.market.gasprice/phase2.el_efficiency;
result.variablecost(result.phase == phase3.powerlevel) = input.market.gasprice/phase3.el_efficiency;

% calculate CM_th --> equal to marginal cost for electricity 
result.CM_th = result.heatrevenue - result.variablecost;

% calculate CM_el
result.CM_el =  result.eexprice + result.CM_th;
        
%% calculate TM1_1 (total margin without storage)
result.TM1_1(result.phase == phase1.powerlevel) = result.CM_el(result.phase == phase1.powerlevel) .* result.phasepower_el(result.phase == phase1.powerlevel);
result.TM1_1(result.phase == phase2.powerlevel) = result.CM_el(result.phase == phase2.powerlevel) .* result.phasepower_el(result.phase == phase2.powerlevel);
result.TM1_1(result.phase == phase3.powerlevel) = result.CM_el(result.phase == phase3.powerlevel) .* result.phasepower_el(result.phase == phase3.powerlevel);


%% add gas holder 
result.gasholder_profit(:,1) = input.market.heatprice - (input.market.gasprice / input.gasholder.efficiency);

%% calculate cum_loss
for i = (height(result)-1):-1:1
    if result.TM1_1(i) <= 0 
        if result.cum_loss(i+1) < 0
            result.cum_loss(i) = result.cum_loss(i+1) + result.TM1_1(i); 
        else
            result.cum_loss(i) = result.TM1_1(i);
        end
    else
        if result.cum_loss(i+1) >= 0 
           result.cum_loss(i) = result.cum_loss(i+1) + result.TM1_1(i); 
        else
           result.cum_loss(i) = result.TM1_1(i);
        end
    end
end
 % cum_loss1
n = 0; % n stands for negative numbers
p = 0; % p stands for positive numbers
for i = 1:height(result) 
    switch sign(result.cum_loss(i))
        case -1
            if p > 0 
                result.cum_loss1(i-p:i-1) = result.cum_loss(i-p);
                p = 0;
            end
            n = n + 1;
        case {0, 1}
            if n > 0
                result.cum_loss1(i-n:i-1) = result.cum_loss(i-n);
                n = 0;
            end
            p = p + 1;
    end
end 

% cum_loss2
for i = 1:height(result)-24
    result.cum_loss2(i) = sum(result.TM1_1(i:i+24),'omitnan');
end


%% Start Decision Process
DecisionTree;
  
end



