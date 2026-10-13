%% generate_ch4_2_story_figures_v3.m
% Chapter 4.2 - FRA Protocol Qualification
% Final story-focused figure revision.
%
% Generates:
%   Fig4_4_frequency_range_decision_v3
%   Fig4_5_control_mode_story_v3
%   Fig4_6_amplitude_requalification_story_v3
%
% Repository paths are resolved automatically; run from any location.

clear; close all; clc;

%% ===================== REPOSITORY PATHS =====================
% This repository copy resolves data and output paths relative to the script.
scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir), scriptDir = pwd; end
repoRoot = fileparts(fileparts(scriptDir));

zipPath = fullfile(repoRoot,'data','raw','Raw_Data_2026_Clean.zip');
cacheRoot = fullfile(repoRoot,'data','raw','_RawData_cache');
rawRoot = fullfile(cacheRoot,'Raw Data');

if ~isfile(zipPath)
    error('Raw-data archive not found: %s', zipPath);
end
if ~isfolder(rawRoot)
    if isfolder(cacheRoot), rmdir(cacheRoot,'s'); end
    mkdir(cacheRoot);
    fprintf('Extracting raw-data archive:\n  %s\n',zipPath);
    unzip(zipPath,cacheRoot);
end

masterLogPath = fullfile(repoRoot,'data','metadata','PV_Lab_Master_Log.xlsx');
if ~isfile(masterLogPath)
    error('Master log not found: %s', masterLogPath);
end

outDir = fullfile(repoRoot,'figures','generated');
if ~exist(outDir,'dir')
    mkdir(outDir);
end

exportDPI = 300;

%% ===================== PLOT DEFAULTS =====================

set(groot,'defaultAxesFontName','Helvetica');
set(groot,'defaultAxesFontSize',11);
set(groot,'defaultAxesLineWidth',0.8);
set(groot,'defaultLineLineWidth',1.7);
set(groot,'defaultLegendFontSize',9);
set(groot,'defaultTextInterpreter','tex');
set(groot,'defaultLegendInterpreter','tex');

%% ===================== MASTER LOG =====================

runLog = readtable(masterLogPath, ...
    'Sheet','Run Log', ...
    'VariableNamingRule','preserve');

%% ========================================================================
% FIGURE 4.4 - FREQUENCY WINDOW QUALIFICATION
% ========================================================================

freqPrimary = { ...
    '20260820_GSM_HLT_FRA_POT_OPA_R01'; ...
    '20260820_GSM_HLT_FRA_POT_OPA_R02'; ...
    '20260820_GSM_HLT_FRA_POT_OPA_R03' ...
    };

freqRepeat = { ...
    '20260820_GSM_HLT_FRA_POT_OPA_R04'; ...
    '20260820_GSM_HLT_FRA_POT_OPA_R05'; ...
    '20260820_GSM_HLT_FRA_POT_OPA_R06' ...
    };

fmins = [0.1 1 10];

F1 = cell(3,1);
F2 = cell(3,1);

meanKK = nan(3,1);
repeatDZ = nan(3,1);
nPoints = nan(3,1);
slowestPeriod = nan(3,1);

for k = 1:3
    F1{k} = readFra(rawRoot,freqPrimary{k});
    F2{k} = readFra(rawRoot,freqRepeat{k});

    kk1 = getLogValue(runLog,freqPrimary{k},"Mean |K-K Error Z'| (%)");
    kk2 = getLogValue(runLog,freqRepeat{k},"Mean |K-K Error Z'| (%)");

    meanKK(k) = mean([kk1 kk2],'omitnan');
    repeatDZ(k) = symmetricSpectrumDifference(F1{k},F2{k});
    nPoints(k) = numel(F1{k}.freq);
    slowestPeriod(k) = 1/min(F1{k}.freq);
end

fig44 = figure('Color','w','Position',[70 80 1240 520]);

ax441 = axes(fig44,'Position',[0.065 0.14 0.43 0.77]);
hold(ax441,'on'); grid(ax441,'on'); box(ax441,'on');

h44 = gobjects(3,1);
for k = 1:3
    mask = F1{k}.freq <= 2e3 & F1{k}.zim >= 0;
    h44(k) = plot(ax441,F1{k}.zre(mask),F1{k}.zim(mask),'-o', ...
        'MarkerSize',3.3,'LineWidth',1.5);
end

xlabel(ax441,'Real impedance, Z'' (\Omega)');
ylabel(ax441,'Imaginary impedance, -Z'''' (\Omega)');
title(ax441,'(a) Spectral response retained');
legend(ax441,h44, ...
    {'0.1 Hz--100 kHz','1 Hz--100 kHz','10 Hz--100 kHz'}, ...
    'Location','best');
axis(ax441,'tight');

ax442 = axes(fig44,'Position',[0.535 0.105 0.445 0.82]);
drawFrequencyDecisionTableV3(ax442, ...
    fmins,nPoints,slowestPeriod,meanKK,repeatDZ);

exportFigure(fig44,outDir,'Fig4_4_frequency_range_decision_v3',exportDPI);

%% ========================================================================
% FIGURE 4.5 - OPERATING STATE + CONTROL MODE STORY
% ========================================================================

dcStem21 = '20260821_GSM_HLT_DC_R01';
DC21 = readDcCurve(rawRoot,dcStem21);
[V21,I21,~] = physicalBranch(DC21);

pairs = struct([]);

pairs(1).short = 'OPA';
pairs(1).pot = '20260821_GSM_HLT_FRA_POT_OPA_R01';
pairs(1).gal = '20260821_GSM_HLT_FRA_GAL_OPA_R01';

pairs(2).short = 'OPB';
pairs(2).pot = '20260821_GSM_HLT_FRA_POT_OPB_R01';
pairs(2).gal = '20260821_GSM_HLT_FRA_GAL_OPB_R01';

pairs(3).short = 'OPC';
pairs(3).pot = '20260821_GSM_HLT_FRA_POT_OPC_R01';
pairs(3).gal = '20260821_GSM_HLT_FRA_GAL_OPC_R01';

pairs(4).short = 'OPD';
pairs(4).pot = '20260821_GSM_HLT_FRA_POT_OPD_R01';
pairs(4).gal = '20260821_GSM_HLT_FRA_GAL_OPD_R01';

pairColours = lines(4);

fig45 = figure('Color','w','Position',[70 60 1240 760]);

ax451 = axes(fig45,'Position',[0.06 0.115 0.445 0.805]);
hold(ax451,'on'); grid(ax451,'on'); box(ax451,'on');

plot(ax451,V21,I21,'LineWidth',2.0,'Color',[0.20 0.20 0.20], ...
    'DisplayName','Measured I-V');

xline(ax451,DC21.Vmp,':','V_{mp}', ...
    'Color',[0.55 0.55 0.55], ...
    'LabelVerticalAlignment','bottom', ...
    'HandleVisibility','off');
xline(ax451,DC21.Voc,':','V_{oc}', ...
    'Color',[0.55 0.55 0.55], ...
    'LabelVerticalAlignment','bottom', ...
    'HandleVisibility','off');

for k = 1:4

    vp = getLogValue(runLog,pairs(k).pot,"Actual Settled DC V (V)");
    vg = getLogValue(runLog,pairs(k).gal,"Actual Settled DC V (V)");

    ip = abs(getLogValue(runLog,pairs(k).pot,"Actual Settled DC I (A)"));
    ig = abs(getLogValue(runLog,pairs(k).gal,"Actual Settled DC I (A)"));

    plot(ax451,[vp vg],[ip ig],'--', ...
        'Color',pairColours(k,:), ...
        'LineWidth',1.35, ...
        'HandleVisibility','off');

    plot(ax451,vp,ip,'o', ...
        'Color',pairColours(k,:), ...
        'MarkerFaceColor','w', ...
        'MarkerSize',9, ...
        'LineWidth',1.8, ...
        'HandleVisibility','off');

    plot(ax451,vg,ig,'x', ...
        'Color',pairColours(k,:), ...
        'MarkerSize',10, ...
        'LineWidth',2.0, ...
        'HandleVisibility','off');

    xm = mean([vp vg]);
    ym = mean([ip ig]);

    switch k
        case 1
            dx = -1.55; dy = 0.045;
        case 2
            dx =  0.15; dy = 0.025;
        case 3
            dx =  0.00; dy = 0.055;
        case 4
            dx = -0.20; dy = -0.095;
    end

    text(ax451,xm+dx,ym+dy,pairs(k).short, ...
        'FontWeight','bold', ...
        'Color',pairColours(k,:), ...
        'FontSize',10, ...
        'BackgroundColor','w', ...
        'Margin',1);
end

hPOT = plot(ax451,nan,nan,'ok','MarkerFaceColor','w', ...
    'MarkerSize',8,'LineWidth',1.6);
hGAL = plot(ax451,nan,nan,'xk','MarkerSize',9,'LineWidth',1.8);

xlabel(ax451,'Module voltage, V (V)');
ylabel(ax451,'Module current, I (A)');
title(ax451,'(a) Actual settled operating states');
xlim(ax451,[0 ceil(DC21.Voc+0.5)]);
ylim(ax451,[0 1.08*max(I21)]);

legend(ax451,[hPOT hGAL], ...
    {'POT actual state','GAL actual state'}, ...
    'Location','southwest');

text(ax451,0.03,0.955, ...
    {'OPA / OPB: matched DC state', ...
     'OPC / OPD: GAL settled away from POT'}, ...
    'Units','normalized', ...
    'VerticalAlignment','top', ...
    'BackgroundColor','w', ...
    'EdgeColor',[0.78 0.78 0.78], ...
    'Margin',5, ...
    'FontSize',9);

P_voc = readFra(rawRoot,pairs(1).pot);
G_voc = readFra(rawRoot,pairs(1).gal);

ax452 = axes(fig45,'Position',[0.585 0.575 0.375 0.345]);
hold(ax452,'on'); grid(ax452,'on'); box(ax452,'on');

maskP = P_voc.freq <= 2e3 & P_voc.zim >= 0;
maskG = G_voc.freq <= 2e3 & G_voc.zim >= 0;

hp = plot(ax452,P_voc.zre(maskP),P_voc.zim(maskP),'-o', ...
    'MarkerSize',3.2,'LineWidth',1.5);
hg = plot(ax452,G_voc.zre(maskG),G_voc.zim(maskG),'-s', ...
    'MarkerSize',3.2,'LineWidth',1.5);

DZvoc = symmetricSpectrumDifference(P_voc,G_voc);
KKP_voc = getLogValue(runLog,pairs(1).pot,"Mean |K-K Error Z'| (%)");
KKG_voc = getLogValue(runLog,pairs(1).gal,"Mean |K-K Error Z'| (%)");

xlabel(ax452,'Z'' (\Omega)');
ylabel(ax452,'-Z'''' (\Omega)');
title(ax452,'(b) Near V_{oc}: matched state \rightarrow matched spectrum');

legend(ax452,[hp hg], ...
    {'POT, 50 mV RMS','GAL, 85 mA RMS'}, ...
    'Location','northwest');

infoVoc = sprintf(['V_{DC}: 20.9 / 20.9 V\n' ...
                   'D_Z: %.2f%%\n' ...
                   'mean |e_{KK}|: %.2f / %.2f%%'], ...
                   DZvoc,KKP_voc,KKG_voc);

text(ax452,0.03,0.045,infoVoc, ...
    'Units','normalized', ...
    'VerticalAlignment','bottom', ...
    'BackgroundColor','w', ...
    'EdgeColor',[0.80 0.80 0.80], ...
    'Margin',4, ...
    'FontSize',8.5);

axis(ax452,'tight');

P_opb = readFra(rawRoot,pairs(2).pot);
G_opb = readFra(rawRoot,pairs(2).gal);

ax453 = axes(fig45,'Position',[0.585 0.105 0.375 0.345]);
hold(ax453,'on'); grid(ax453,'on'); box(ax453,'on');

maskP = P_opb.freq <= 2e3 & P_opb.zim >= 0;
maskG = G_opb.freq <= 2e3 & G_opb.zim >= 0;

hp = plot(ax453,P_opb.zre(maskP),P_opb.zim(maskP),'-o', ...
    'MarkerSize',3.2,'LineWidth',1.5);
hg = plot(ax453,G_opb.zre(maskG),G_opb.zim(maskG),'-s', ...
    'MarkerSize',3.2,'LineWidth',1.5);

DZopb = symmetricSpectrumDifference(P_opb,G_opb);
KKP_opb = getLogValue(runLog,pairs(2).pot,"Mean |K-K Error Z'| (%)");
KKG_opb = getLogValue(runLog,pairs(2).gal,"Mean |K-K Error Z'| (%)");

xlabel(ax453,'Z'' (\Omega)');
ylabel(ax453,'-Z'''' (\Omega)');
title(ax453,'(c) 0.9V_{oc}: matched state, invalid GAL excitation');

legend(ax453,[hp hg], ...
    {'POT, 50 mV RMS','GAL, 85 mA RMS'}, ...
    'Location','northeast');

infoOpb = sprintf(['V_{DC}: 18.8 / 18.8 V\n' ...
                   'D_Z: %.1f%%\n' ...
                   'mean |e_{KK}|: %.2f / %.1f%%'], ...
                   DZopb,KKP_opb,KKG_opb);

text(ax453,0.03,0.045,infoOpb, ...
    'Units','normalized', ...
    'VerticalAlignment','bottom', ...
    'BackgroundColor','w', ...
    'EdgeColor',[0.80 0.80 0.80], ...
    'Margin',4, ...
    'FontSize',8.5);

axis(ax453,'tight');

exportFigure(fig45,outDir,'Fig4_5_control_mode_story_v3',exportDPI);

%% ========================================================================
% FIGURE 4.6 - AMPLITUDE RE-QUALIFICATION
% ========================================================================

ampStems = { ...
    '20260826_GSM_HLT_FRA_POT_OPB_R01'; ...
    '20260826_GSM_HLT_FRA_POT_OPB_R02'; ...
    '20260826_GSM_HLT_FRA_POT_OPB_R03'; ...
    '20260826_GSM_HLT_FRA_POT_OPB_R04' ...
    };

ampLabels = {'50 mV','20 mV A','10 mV','20 mV B'};

A = cell(4,1);
kkAmp = nan(4,1);
y0Amp = nan(4,1);
rpAmp = nan(4,1);

for k = 1:4
    A{k} = readFra(rawRoot,ampStems{k});
    kkAmp(k) = getLogValue(runLog,ampStems{k},"Mean |K-K Error Z'| (%)");
    y0Amp(k) = getLogValue(runLog,ampStems{k},"CPE Y0");
    rpAmp(k) = getLogValue(runLog,ampStems{k},"Rp / Rct (Ω)");
end

fig46 = figure('Color','w','Position',[70 70 1260 620]);

baseColours = lines(3);
col50 = baseColours(1,:);
col20 = baseColours(2,:);
col10 = baseColours(3,:);

ampColours = [col50; col20; col10; col20];
ampStyles = {'-','-','-','--'};

ax461 = axes(fig46,'Position',[0.06 0.13 0.415 0.80]);
hold(ax461,'on'); grid(ax461,'on'); box(ax461,'on');

h46a = gobjects(4,1);

for k = 1:4
    mask = A{k}.freq <= 2e3 & A{k}.zim >= 0;

    h46a(k) = plot(ax461,A{k}.zre(mask),A{k}.zim(mask), ...
        'LineStyle',ampStyles{k}, ...
        'Color',ampColours(k,:), ...
        'Marker','o', ...
        'MarkerSize',3.0, ...
        'LineWidth',1.5);
end

xlabel(ax461,'Real impedance, Z'' (\Omega)');
ylabel(ax461,'Imaginary impedance, -Z'''' (\Omega)');
title(ax461,'(a) Measured spectra at 0.9V_{oc}');
legend(ax461,h46a,ampLabels,'Location','best');
axis(ax461,'tight');

ax462 = axes(fig46,'Position',[0.55 0.425 0.41 0.505]);
hold(ax462,'on'); grid(ax462,'on'); box(ax462,'on');
set(ax462,'XScale','log');

h46b = gobjects(4,1);

for k = 1:4
    [freqSorted,idx] = sort(A{k}.freq);
    errSorted = A{k}.errZre(idx);

    h46b(k) = plot(ax462,freqSorted,errSorted, ...
        'LineStyle',ampStyles{k}, ...
        'Color',ampColours(k,:), ...
        'Marker','o', ...
        'MarkerSize',2.8, ...
        'LineWidth',1.30);
end

yline(ax462,0,'-','HandleVisibility','off');
yline(ax462,1,':','+1% guide', ...
    'HandleVisibility','off', ...
    'LabelHorizontalAlignment','left');
yline(ax462,-1,':','-1% guide', ...
    'HandleVisibility','off', ...
    'LabelHorizontalAlignment','left');

xlabel(ax462,'Frequency, f (Hz)');
ylabel(ax462,'K-K residual, Error Z'' (%)');
title(ax462,'(b) Frequency-resolved K-K residual');
xlim(ax462,[1 1e5]);
xticks(ax462,[1 10 100 1e3 1e4 1e5]);

legendLabels = cell(4,1);
for k = 1:4
    legendLabels{k} = sprintf('%s: mean |e| = %.2f%%', ...
        ampLabels{k},kkAmp(k));
end

legend(ax462,h46b,legendLabels,'Location','best');

ax463 = axes(fig46,'Position',[0.55 0.075 0.41 0.265]);
drawAmplitudeDecisionTable(ax463,ampLabels,kkAmp,y0Amp,rpAmp);

exportFigure(fig46,outDir,'Fig4_6_amplitude_requalification_story_v3',exportDPI);

%% ===================== LOCAL FUNCTIONS =====================

function S = readFra(rawRoot,fileStem)

    filePath = findFileRecursive(rawRoot,fileStem);
    T = readtable(filePath,'VariableNamingRule','preserve');

    S.filePath = filePath;
    S.zre = double(pickVar(T,{"Z' (Ω)","Z' (\Omega)"}));
    S.zim = double(pickVar(T,{"-Z'' (Ω)","-Z'' (\Omega)"}));
    S.zmag = double(pickVar(T,{"Z (Ω)","Z (\Omega)"}));
    S.phase = double(pickVar(T,{"-Phase (°)","-Phase (deg)"}));
    S.freq = double(pickVar(T,{"Frequency (Hz)"}));
    S.errZre = double(pickVar(T,{"Error Z' (%)"}));

    try
        S.errZim = double(pickVar(T,{"Error Z'' (%)"}));
    catch
        S.errZim = nan(size(S.freq));
    end

    fields = {'zre','zim','zmag','phase','freq','errZre','errZim'};
    for k = 1:numel(fields)
        S.(fields{k}) = S.(fields{k})(:);
    end
end

function S = readDcCurve(rawRoot,fileStem)

    filePath = findFileRecursive(rawRoot,fileStem);
    T = readtable(filePath,'VariableNamingRule','preserve');

    V = double(pickVar(T, ...
        {"Corrected Potential (V)","Corrected Potential"}));
    I = double(pickVar(T, ...
        {"Corrected Current (A)","Corrected Current"}));
    P = double(pickVar(T, ...
        {"Corrected Power (W)","Corrected Power"}));

    V = V(:); I = I(:); P = P(:);

    mask = isfinite(V) & isfinite(I) & isfinite(P);
    V = V(mask); I = I(mask); P = P(mask);

    [V,idx] = sort(V);
    I = I(idx); P = P(idx);

    [V,ia] = unique(V,'stable');
    I = I(ia); P = P(ia);

    Voc = estimateVoc(V,I);
    Isc = interp1(V,I,0,'pchip','extrap');

    physical = V >= 0 & V <= Voc & I >= 0;
    idxPhys = find(physical);

    [Pmp,idxLocal] = max(P(physical));
    idxP = idxPhys(idxLocal);

    S.filePath = filePath;
    S.V = V;
    S.I = I;
    S.P = P;
    S.Voc = Voc;
    S.Isc = Isc;
    S.Vmp = V(idxP);
    S.Imp = I(idxP);
    S.Pmp = Pmp;
end

function [V,I,P] = physicalBranch(S)

    mask = S.V >= 0 & S.V < S.Voc & S.I >= 0;

    V = S.V(mask);
    I = S.I(mask);
    P = S.P(mask);

    V = [V; S.Voc];
    I = [I; 0];
    P = [P; 0];
end

function Voc = estimateVoc(V,I)

    crossing = find(I(1:end-1).*I(2:end) <= 0,1,'first');

    if ~isempty(crossing)
        Voc = interp1(I(crossing:crossing+1), ...
                      V(crossing:crossing+1), ...
                      0,'linear','extrap');
        return;
    end

    n = min(8,numel(V));
    idx = (numel(V)-n+1):numel(V);

    p = polyfit(I(idx),V(idx),1);
    Voc = polyval(p,0);
end

function value = getLogValue(runLog,fileStem,varName)

    names = string(runLog.("Data File Name"));
    names = strip(erase(names,'.xlsx'));

    idx = find(names == string(fileStem),1,'first');

    if isempty(idx)
        error('Master-log row not found for %s',fileStem);
    end

    value = runLog{idx,varName};

    if iscell(value)
        value = value{1};
    end

    if isstring(value) || ischar(value)
        value = str2double(value);
    end

    value = double(value);
end

function DZ = symmetricSpectrumDifference(A,B)

    [~,ia,ib] = intersect(A.freq,B.freq);

    ZA = A.zre(ia) - 1i*A.zim(ia);
    ZB = B.zre(ib) - 1i*B.zim(ib);

    denom = (abs(ZA)+abs(ZB))/2;
    valid = isfinite(ZA) & isfinite(ZB) & denom > 0;

    DZ = 100*mean(abs(ZA(valid)-ZB(valid))./denom(valid),'omitnan');
end

function drawFrequencyDecisionTableV3(ax, ...
    fmins,nPoints,slowestPeriod,meanKK,repeatDZ)

    cla(ax);
    axis(ax,[0 1 0 1]);
    axis(ax,'off');
    hold(ax,'on');

    title(ax,'(b) Frequency-window trade-off');

    x = [0.09 0.27 0.46 0.67 0.86];
    headers = { ...
        'Lower limit', ...
        'Points', ...
        '1/f_{min}', ...
        'Mean |e_{KK}|', ...
        'Repeat D_Z' ...
        };

    yHeader = 0.82;
    yRows = [0.64 0.46 0.28];

    patch(ax,[0.015 0.985 0.985 0.015], ...
        [0.385 0.385 0.545 0.545], ...
        [0.92 0.96 0.92], ...
        'EdgeColor','none');

    plot(ax,[0.02 0.98],[0.74 0.74],'k-','LineWidth',0.8);
    plot(ax,[0.02 0.98],[0.19 0.19],'k-','LineWidth',0.8);

    for c = 1:numel(headers)
        text(ax,x(c),yHeader,headers{c}, ...
            'HorizontalAlignment','center', ...
            'FontWeight','bold', ...
            'FontSize',9);
    end

    for r = 1:3

        text(ax,x(1),yRows(r),sprintf('%g Hz',fmins(r)), ...
            'HorizontalAlignment','center','FontSize',10);

        text(ax,x(2),yRows(r),sprintf('%d',nPoints(r)), ...
            'HorizontalAlignment','center','FontSize',10);

        text(ax,x(3),yRows(r),sprintf('%.1f s',slowestPeriod(r)), ...
            'HorizontalAlignment','center','FontSize',10);

        text(ax,x(4),yRows(r),sprintf('%.3f%%',meanKK(r)), ...
            'HorizontalAlignment','center','FontSize',10);

        text(ax,x(5),yRows(r),sprintf('%.2f%%',repeatDZ(r)), ...
            'HorizontalAlignment','center','FontSize',10);
    end

    text(ax,0.03,0.125, ...
        '0.1 Hz: adds one slow decade with negligible K-K improvement', ...
        'FontSize',9.1,'Color',[0.30 0.30 0.30]);

    text(ax,0.03,0.075, ...
        '\bfRetain 1 Hz--100 kHz: low-frequency response preserved', ...
        'FontSize',9.4);

    text(ax,0.03,0.025, ...
        '10 Hz: shortest sweep, but removes the 1--10 Hz response', ...
        'FontSize',9.1,'Color',[0.30 0.30 0.30]);
end

function drawAmplitudeDecisionTable(ax,ampLabels,kkAmp,y0Amp,rpAmp)

    cla(ax);
    axis(ax,[0 1 0 1]);
    axis(ax,'off');
    hold(ax,'on');

    title(ax,'(c) Why 20 mV RMS was retained');

    x = [0.11 0.35 0.61 0.84];
    headers = {'Amplitude','Mean |e_{KK}|','CPE Y_0','R_p (\Omega)'};

    yHeader = 0.80;
    yRows = [0.62 0.47 0.32 0.17];

    patch(ax,[0.015 0.985 0.985 0.015], ...
        [0.395 0.395 0.545 0.545], ...
        [0.92 0.96 0.92], ...
        'EdgeColor','none');

    patch(ax,[0.015 0.985 0.985 0.015], ...
        [0.095 0.095 0.245 0.245], ...
        [0.92 0.96 0.92], ...
        'EdgeColor','none');

    plot(ax,[0.02 0.98],[0.73 0.73],'k-','LineWidth',0.7);
    plot(ax,[0.02 0.98],[0.08 0.08],'k-','LineWidth',0.7);

    for c = 1:numel(headers)
        text(ax,x(c),yHeader,headers{c}, ...
            'HorizontalAlignment','center', ...
            'FontWeight','bold', ...
            'FontSize',8.8);
    end

    for r = 1:4

        text(ax,x(1),yRows(r),ampLabels{r}, ...
            'HorizontalAlignment','center','FontSize',9);

        text(ax,x(2),yRows(r),sprintf('%.2f%%',kkAmp(r)), ...
            'HorizontalAlignment','center','FontSize',9);

        text(ax,x(3),yRows(r),sprintf('%.4g',y0Amp(r)), ...
            'HorizontalAlignment','center','FontSize',9);

        text(ax,x(4),yRows(r),sprintf('%.4f',rpAmp(r)), ...
            'HorizontalAlignment','center','FontSize',9);
    end

    text(ax,0.02,0.015, ...
        '\bfDecision: 10 mV reduced mean K-K error but produced an unstable Y_0; the 20 mV repeat pair remained comparable.', ...
        'FontSize',8.7);
end

function var = pickVar(T,candidateNames)

    names = string(T.Properties.VariableNames);

    for k = 1:numel(candidateNames)
        idx = find(names == string(candidateNames{k}),1,'first');

        if ~isempty(idx)
            var = T.(names(idx));
            return;
        end
    end

    error('Could not find expected variable. Available variables:\n%s', ...
        strjoin(T.Properties.VariableNames,', '));
end

function filePath = findFileRecursive(rootDir,fileStem)

    fileStem = erase(string(fileStem),'.xlsx');

    hits = dir(fullfile(rootDir,'**',[char(fileStem) '.xlsx']));

    if isempty(hits)
        hits = dir(fullfile(rootDir,'**',[char(fileStem) '*']));
    end

    if isempty(hits)
        error('Could not find %s under:\n%s',fileStem,rootDir);
    end

    bad = startsWith({hits.name},'._');
    hits = hits(~bad);

    if isempty(hits)
        error('Only macOS resource-fork copies found for %s',fileStem);
    end

    filePath = fullfile(hits(1).folder,hits(1).name);
end

function exportFigure(figHandle,outDir,baseName,exportDPI)

    drawnow;

    exportgraphics(figHandle, ...
        fullfile(outDir,[baseName '.png']), ...
        'Resolution',exportDPI);

    exportgraphics(figHandle, ...
        fullfile(outDir,[baseName '.pdf']), ...
        'ContentType','vector');

    savefig(figHandle, ...
        fullfile(outDir,[baseName '.fig']));
end
