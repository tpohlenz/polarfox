function [ output_table] = Evaluation(first_value, last_value, steps, input)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    k = (abs(last_value-first_value))/steps + 1;
    pos = 0;
    output_table = table; 
    
for i = first_value:steps:last_value
    
    pos = pos + 1;
    input.storage.capacity = i;
    result = chpratingbackend_v22(input);
    totmarg1 = nansum(result.TM1_1);
    totmarg2 = nansum(result.TM1_3);
    margdiff = totmarg2 - totmarg1;
    output_table(pos,1:4) = {i,totmarg1,totmarg2,margdiff};
end
end

