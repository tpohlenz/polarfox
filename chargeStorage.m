%% This script charge the storage

result.storagelevel(i) = result.storagelevel(i-1) + ((1-result.newdemand(i)) * result.phasepower_th(i) / input.storage.capacity); 
                if result.storagelevel(i) > 1
                    lostPart = result.storagelevel(i) - 1;
                    result.lostheat(i) = input.storage.capacity * lostPart;
                    result.storagelevel(i) = 1;   
                end