if result.gasholder_profit > result.CM_el && input.gasholder.value == 1 
    %% gas holder branch
    if result.storagelevel * input.plant.peakpower_th <= result.newdemand * result.phasepower_th 
        % gas holder 
    else
        run(dischargeStorage)
else
    %% CHP branch
    if result.CM_el >= 0 && input.plant.startup < result.cum_loss && result.storagelevel * input.plant.peakpower_th <= result.newdemand * result.phasepower_th 
        % CHP usage possible
        if result.storagelevel(i) >= 1
            run(dischargeStorage);
        else
            % CHP usage and charge storage
        end
    else
        run(dischargeStorage);
    end
end

