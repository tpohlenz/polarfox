function [ pltdat ] = DisplayPlots(result,input)

% Initial Value
scrsz = get(groot,'ScreenSize');
pltdat = struct;
%% Verhalten W�rme
pltdat.heat = figure('OuterPosition',[scrsz(3)/2 1 scrsz(3)/2 scrsz(4)/2.5]) % [left bottom width height]

ax1 = subplot(3,1,1);
plot(result.eexprice);
ylabel('EEX Preis in Euro/Mwh');
title('Entwicklung EEX-Preis');

helpArray(1:height(result),1) = 0;
helpArray(result.usage == 1) = result.phase(result.usage == 1) .* input.plant.peakpower_el; 

ax2 = subplot(3,1,2);
plot(helpArray);
ylabel('Leistung in MW');
title('Stromproduktion der KWK-Anlage');

ax3 = subplot(3,1,3);
plot(result.heatdemand .* input.plant.peakpower_th);
hold on
plot(get(gca,'xlim'), [input.plant.peakpower_th input.plant.peakpower_th]);
hold off

ylabel('W�rmebedarf in MW');
title('Verlauf des W�rmebedarfs');
legend('W�rmebedraf','maximale thermische Leistung der KWK-Anlage');

% ax3 = subplot(3,1,3);
% plot(result.lostheat);
% ylabel('Verlorene W�rme in MWh');
% title('An Umwelt abgegebene W�rme');

linkaxes([ax3,ax2,ax1],'x');
ylim(ax1,[-220 220]);
pan off
pan xon

h = zoom
h.Motion = 'horizontal';
h.Enable = 'on';


%% Zuwachs Deckungsbeitrag
pltdat.ctmarg = figure('Position',[scrsz(3)/2 scrsz(4)/2 scrsz(3)/2 scrsz(4)/2.5]) % [left bottom width height]
x = 1:length(result.TM1_1(isnan(result.TM1_3) == 0));
plot(cumsum(result.TM1_1(isnan(result.TM1_1) == 0)),'--');


hold on
plot(cumsum(result.TM1_2(isnan(result.TM1_2) == 0)),'--');
[hAx,hLine1,hLine2] = plotyy(x,cumsum(result.TM1_3(isnan(result.TM1_3) == 0)),x,result.heatdemand(isnan(result.TM1_3) == 0));
hLine1.LineStyle = '--';

title('Zuwachs des Deckungsbeitrags und W�rmebedraf')
xlabel('Jahresstunden')

ylabel(hAx(1),'Zuwachs in Euro');
ylabel(hAx(2),'W�rmebedarf der maximalen KWK-W�rmeleistung');

legend('KWK ohne Kessel, ohne Speicher','KWK mit Kessel, ohne Speicher','KWK mit Kessel, mit Speicher','W�rmebedarf')
hold off

%% Anteil Nutzung in % 
totalUsage = height(result);
Usage(1,1) = sum(result.usage == 1) / totalUsage;
Usage(2,1) = sum(result.usage == 2) / totalUsage;
Usage(3,1) = sum(result.usage == 3) / totalUsage;

pltdat.usage = figure('Position',[1 scrsz(4)/2 scrsz(3)/2 scrsz(4)/2.5]) % [left bottom width height]

bar(Usage,0.4);
ax = gca;
ax.XTickLabel = {'CHP', 'Gas', 'Storage'};
title('Anteil an der Nutzung in %');

% %% Jahresdauerlinie_v1: Bezogen auf die Spitzenleistung der Anlage 
% pltdat.ducrv = figure('Position',[1 1 scrsz(3)/2 scrsz(4)/2.5]) % [left bottom width height] 
% 
% plot(sort(result.newdemand,'descend'))
% ylabel('Auslastung in Prozent')
% xlabel('Jahresstunden')
% title('Jahresdauerlinie')

%% Jahresdauerlinie_v2: Bezogen auf die H�chstw�rmelast an der Anlage

pltdat.ducrv = figure('Position',[1 1 scrsz(3)/2 scrsz(4)/2.5]) % [left bottom width height] 

plot(sort(result.heatdemand .* input.plant.peakpower_th,'descend'))
hold on 
plot(get(gca,'xlim'), [input.plant.peakpower_th input.plant.peakpower_th])

ylabel('W�rmebedarf in MW')
xlabel('Jahresstunden')
title('Jahresdauerlinie des W�rmebedarfs')
legend('W�rmebedraf','maximale thermische Leistung der KWK-Anlage')

%% Anfahrten der KWK-Anlage 
k = 0;
for i = 2:height(result)
    if result.usage(i) == 1 & result.usage(i-1) ~= 1
        k = k + 1;
    end
end

%% 3D Scatter
% Color Map
for i = 1 : height(result)
    switch result.usage(i)
        case 1
            color(i,1:3) = [0 0 1];
        case 2
            color(i,1:3) = [1 0 1];
        case 3
            color(i,1:3) = [0 0 0];
    end
end

pltdat.scat = figure; 


% 
% mKWK = uicontrol('style','text')
% set(mKWK,'String','KWK','ForegroundColor',[0 0 1],'Position',[500 100 60 20])
% 
% 
% mGas = uicontrol('style','text')
% set(mGas,'String','Gaskessel','ForegroundColor',[1 0 1],'Position',[500 200 60 20])
% 
% mStoreage = uicontrol('style','text')
% set(mStoreage,'String','Speicher','ForegroundColor',[0 0 0],'Position',[500 300 60 20])


h = scatter3(result.date.Hour,result.date.Month,result.heatdemand,36,color,'.');
title('W�rmebedarf und Einsatzweise nach Monat und Tagesstunde');
xlabel('Tagesstunde');
ylabel('Monat');
zlabel('W�rmebedarf (bezogen auf max. thermmische Leistung)');

% text(0,0,0,'KWK','Color',[0 0 1]);
% text(0,0,0,'Gaskessel','Color',[1 0 1]);
% text(0,0,0,'Speicher','Color',[0 0 0]);

annotation('textbox','String','KWK-Anlage','Color',[0 0 1],'Position',[0.87 0.8 0 0],'FitBoxToText','on');
annotation('textbox','String','Gaskessel','Color',[1 0 1],'Position',[0.87 0.75 0 0],'FitBoxToText','on');
annotation('textbox','String','Speicher','Color',[0 0 0],'Position',[0.87 0.7 0 0],'FitBoxToText','on');

%% Zusatzinformationen: Volllaststunden, Anzahl Anfahrtsvorg�nge
helpArray = result.phase(result.usage == 1);
disp(['Volllaststunden der KWK-Anlage: ' num2str(sum(helpArray)) 'h'])
disp(['Anzahl der Anfahrtsvorg�nge der KWK-Anlage: ' num2str(k)]);

% pltdat.Anfahrt = ['Anzahl der Anfahrtsvorg�nge der KWK-Anlage: ' num2str(k)]



%% Print all figures
fldnam = fieldnames(pltdat);
k = length(fldnam);

for i = 1:k
    print(pltdat.(fldnam{i}),'Diagramme','-append','-dpsc2');
end

