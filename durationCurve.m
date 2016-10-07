function helpArray = durationCurve(y_Values,nbins)
    
maxTemp = max(y_Values);
minTemp = min(y_Values);
range = maxTemp - minTemp;
steps = range/nbins;
helpArray = table;
helpArray.range(1:nbins,1) = 0;
helpArray.number(1:nbins,1) = 0;

for i = 1:nbins
    helpArray.number(i,1) = sum(y_Values < (maxTemp - (steps * (i-1))));
    helpArray.range(i,1) = maxTemp - (steps * (i-1));
end
end