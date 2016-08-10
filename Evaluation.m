function [ output_table] = Evaluation(first_value, last_value, steps, input)
% Evalutes different storage capacity scenarios

    k = (abs(last_value-first_value))/steps + 1;
    str1 = ['Number of Iterations: ',num2str(k)];
    disp (str1) 
    pos = 0;
    
    % Create Table
    output_table = table; 
    
for i = first_value:steps:last_value
    
    pos = pos + 1;
    str2 = ['Iteration ',num2str(pos),' of ',num2str(k)];
    disp (str2)
    input.storage.capacity = i;
    result = chpratingbackend_v22(input);
    totmarg1 = nansum(result.TM1_1);
    totmarg2 = nansum(result.TM1_3);
    margdiff = totmarg2 - totmarg1;
    output_table(pos,1:4) = {i,totmarg1,totmarg2,margdiff};
end
output_table.Properties.VariableNames ={'Capacity' 'TM' 'TM_storage' 'TM_Difference'}

% Plot plot
figure
ax1 = subplot(2,1,1);
ax2 = subplot(2,1,2);
x = output_table.Capacity;

plot(ax1,x,output_table.TM_Difference)
title(ax1,'Total Margin Difference')

plot(ax2,x,output_table.TM,x,output_table.TM_storage)
title(ax2,'Absolute Total Margin')
end

