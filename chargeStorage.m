% This script charge the storage

result.storagelevel(i) = result.storagelevel(i-1) + ((1-result.newdemand(i)) * result.phasepower_th(i) / input.storage.capacity; 
                if result.storagelevel(i) > 1
                result.storagelevel(i) = 1;
                end