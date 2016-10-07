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

%% import Date 
result.date = input.market.electricity.rawData.EEXDayAhead.Date(input.market.electricity.rawData.EEXDayAhead.Date.Year == input.year)

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
result.raw_eexprice = input.market.electricity.currentyear;
result.funding(:,1) = input.market.funding; 
result.eexprice(:,1) = 0;
result.CM_el(:,1) = 0;
result.gasholder_profit(:,1) = 0; 
result.abs_heatdemand(:,1) = 0;
result.storagelevel (:,1) = 0;
result.lostheat(:,1) = 0;
result.lostratio(:,1) = 0;
result.lostamount(:,1) = 0;

result.TM1_1(:,1) = 0;
result.TM1_2(:,1) = 0;
result.TM1_3(:,1) = 0;

result.cum_loss1(:,1) = 0;
result.cum_loss2(:,1) = 0;
result.cum_loss3(:,1) = 0;
result.usage(:,1) = 1;

%% Add CHP funding
if isnumeric(input.market.funding) == 1 
    result.eexprice = result.raw_eexprice + result.funding;
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
% Optimazitaion Forecast: 10 hours 
helpArray = result.gasholder_profit .* result.abs_heatdemand;

for i = 1:height(result)-10
    result.cum_loss1(i) = sum(result.TM1_1(i:i+10),'omitnan');
    result.cum_loss2(i) = sum(helpArray(i:i+10),'omitnan');
    result.cum_loss3(i) = sum(result.abs_heatdemand(i:i+10) * input.market.heatprice,'omitnan'); 
end


%% Start Decision Process
DecisionTree;
  
end



