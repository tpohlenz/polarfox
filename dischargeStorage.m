% This script discharge the storage
result.storagelevel(i) = result.storagelevel(i-1) - (result.newdemand(i)) * result.phasepower_th(i) / input.storage.capacity;
                    result.TM1_3(i) = result.newdemand(i)) * result.phasepower_th(i) * input.market.heatprice;
                    result.usage(i) = 3; % equal to storage