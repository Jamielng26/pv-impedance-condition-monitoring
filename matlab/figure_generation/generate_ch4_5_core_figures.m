%% generate_ch4_5_core_figures.m
% Chapter 4.5 - Healthy Environmental FRA Characterisation
%
% Story-focused figures for the first major results section.
%
% Generates:
%   Fig 4.9  - Why the initial temperature result became suspicious:
%              same environmental pair, very different response at OPF vs OPB.
%
%   Fig 4.10 - Irradiance response at approximately constant temperature:
%              raw Nyquist contraction + model / model-independent features.
%
%   Fig 4.11 - Matched-xi reconciliation matrix:
%              temperature vs irradiance at xi ~ 0.30 and xi ~ 0.70.
%
% Figure 4.12 (Rp vs Rdiff healthy-state relationship) is intentionally
% treated separately after these core experimental figures are reviewed.
%
% -------------------------------------------------------------------------
% IMPORTANT
% -------------------------------------------------------------------------
% 1) Extract Raw Data.zip.
% 2) Set rawRoot to the extracted "Raw Data" folder.
% 3) Set outDir to your Chapter 4 figures folder.
% 4) Run the script.
%
% The percentage changes in Rp used in the compact comparison panels are
% the values currently reported in the Chapter 4 results tables. Direct
% spectral quantities (-Z''max and K-K residuals) are calculated from the
% raw FRA files.
% -------------------------------------------------------------------------

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

%% ========================================================================
% FILE MAP
% ========================================================================
%
% Temperature campaign, 60 cm:
%   R03 = fan OFF / warm state: 44.59 C, 299.6 W/m^2
%   R04 = fan ON  / cool state: 33.76 C, 298.1 W/m^2
%
% Irradiance campaign:
%   20260910 R03 = low G:  253.9 W/m^2, 43.22 C
%   20260910 R01 = mid G:  316.1 W/m^2, 45.93 C
%   20260910 R02 = high G: 633.3 W/m^2, 43.41 C
%
% Targeted OPX follow-up:
%   20260914 OPX30 R02 = low-G state near xi = 0.30
%   20260914 OPX70 R01 = cool-temperature state near xi = 0.70
%   20260914 OPX70 R03 = high-G state near xi = 0.70
%
% Existing spectra used for the matched-xi matrix:
%   xi ~ 0.30 temperature: 20260909 OPB R04 / R03
%   xi ~ 0.30 irradiance:  20260914 OPX30 R02 / 20260910 OPB R02
%   xi ~ 0.70 temperature: 20260914 OPX70 R01 / 20260909 OPF R03
%   xi ~ 0.70 irradiance:  20260910 OPF R03 / 20260914 OPX70 R03

%% ========================================================================
% FIGURE 4.9
% INITIAL TEMPERATURE RESPONSE: WHY THE RESULT BECAME SUSPICIOUS
% ========================================================================

tempCoolOPF = readFra(rawRoot,'20260909_GSM_HLT_FRA_POT_OPF_R04');
tempWarmOPF = readFra(rawRoot,'20260909_GSM_HLT_FRA_POT_OPF_R03');

tempCoolOPB = readFra(rawRoot,'20260909_GSM_HLT_FRA_POT_OPB_R04');
tempWarmOPB = readFra(rawRoot,'20260909_GSM_HLT_FRA_POT_OPB_R03');

% Current reported fitted-Rp changes for the clean 60 cm pair.
dRp_OPF = -38.85;
dRp_OPB =  -9.81;

% Directly measured arc-height changes from raw spectra.
dZmax_OPF = percentChange(maxPositiveZim(tempCoolOPF), ...
                          maxPositiveZim(tempWarmOPF));
dZmax_OPB = percentChange(maxPositiveZim(tempCoolOPB), ...
                          maxPositiveZim(tempWarmOPB));

fig49 = figure('Color','w','Position',[70 70 1250 560]);

% ---- (a) Fixed 20 V ----
ax491 = axes(fig49,'Position',[0.055 0.14 0.35 0.77]);
hold(ax491,'on'); grid(ax491,'on'); box(ax491,'on');

h1 = plotCapacitiveArc(ax491,tempCoolOPF,'-o');
h2 = plotCapacitiveArc(ax491,tempWarmOPF,'-s');

xlabel(ax491,'Real impedance, Z'' (\Omega)');
ylabel(ax491,'Imaginary impedance, -Z'''' (\Omega)');
title(ax491,'(a) Fixed 20 V (OPF)');

legend(ax491,[h1 h2], ...
    {'Cool: 33.76^\circC, 298.1 W/m^2', ...
     'Warm: 44.59^\circC, 299.6 W/m^2'}, ...
    'Location','best');

kkCool = meanKK(tempCoolOPF);
kkWarm = meanKK(tempWarmOPF);

text(ax491,0.04,0.05, ...
    sprintf(['\\DeltaR_p = %.1f%%\n' ...
             '\\Delta(-Z''''_{max}) = %.1f%%\n' ...
             'mean |e_{KK}| = %.2f / %.2f%%'], ...
             dRp_OPF,dZmax_OPF,kkCool,kkWarm), ...
    'Units','normalized', ...
    'VerticalAlignment','bottom', ...
    'BackgroundColor','w', ...
    'EdgeColor',[0.80 0.80 0.80], ...
    'Margin',5, ...
    'FontSize',9);

axis(ax491,'tight');

% ---- (b) 0.9Voc ----
ax492 = axes(fig49,'Position',[0.435 0.14 0.35 0.77]);
hold(ax492,'on'); grid(ax492,'on'); box(ax492,'on');

h3 = plotCapacitiveArc(ax492,tempCoolOPB,'-o');
h4 = plotCapacitiveArc(ax492,tempWarmOPB,'-s');

xlabel(ax492,'Real impedance, Z'' (\Omega)');
ylabel(ax492,'Imaginary impedance, -Z'''' (\Omega)');
title(ax492,'(b) 0.9V_{oc} (OPB)');

legend(ax492,[h3 h4], ...
    {'Cool: 33.76^\circC, 298.1 W/m^2', ...
     'Warm: 44.59^\circC, 299.6 W/m^2'}, ...
    'Location','best');

kkCool = meanKK(tempCoolOPB);
kkWarm = meanKK(tempWarmOPB);

text(ax492,0.04,0.05, ...
    sprintf(['\\DeltaR_p = %.1f%%\n' ...
             '\\Delta(-Z''''_{max}) = %+.1f%%\n' ...
             'mean |e_{KK}| = %.2f / %.2f%%'], ...
             dRp_OPB,dZmax_OPB,kkCool,kkWarm), ...
    'Units','normalized', ...
    'VerticalAlignment','bottom', ...
    'BackgroundColor','w', ...
    'EdgeColor',[0.80 0.80 0.80], ...
    'Margin',5, ...
    'FontSize',9);

axis(ax492,'tight');

% ---- (c) Same environmental change, different apparent sensitivity ----
ax493 = axes(fig49,'Position',[0.825 0.18 0.15 0.69]);
hold(ax493,'on'); grid(ax493,'on'); box(ax493,'on');

Y = [dRp_OPF dZmax_OPF; dRp_OPB dZmax_OPB];
b = bar(ax493,Y,'grouped');

yline(ax493,0,'k-','HandleVisibility','off');
xticks(ax493,1:2);
xticklabels(ax493,{'OPF','OPB'});
ylabel(ax493,'Warm-state change (%)');
title(ax493,'(c) Apparent sensitivity');

legend(ax493,{'R_p','-Z''''_{max}'}, ...
    'Location','southwest');

% Dynamic limits with a little breathing room.
ylim(ax493,[min(Y(:))-8, max([5;Y(:)])+5]);

text(ax493,0.50,0.96, ...
    {'Same 60 cm', ...
     'temperature pair'}, ...
    'Units','normalized', ...
    'HorizontalAlignment','center', ...
    'VerticalAlignment','top', ...
    'FontSize',9, ...
    'BackgroundColor','w', ...
    'EdgeColor',[0.82 0.82 0.82], ...
    'Margin',4);

exportFigure(fig49,outDir,'Fig4_9_temperature_bias_dependence',exportDPI);

%% ========================================================================
% FIGURE 4.10
% IRRADIANCE RESPONSE AT APPROXIMATELY CONSTANT TEMPERATURE
% ========================================================================

irrLow  = readFra(rawRoot,'20260910_GSM_HLT_FRA_POT_OPF_R03');
irrMid  = readFra(rawRoot,'20260910_GSM_HLT_FRA_POT_OPF_R01');
irrHigh = readFra(rawRoot,'20260910_GSM_HLT_FRA_POT_OPF_R02');

G = [253.9 316.1 633.3];

% Values currently reported in the results table.
Rp = [0.3354 0.2729 0.2196];
Rs = [0.05794 0.05699 0.05599];

% Direct raw spectral feature.
Zmax = [maxPositiveZim(irrLow), ...
        maxPositiveZim(irrMid), ...
        maxPositiveZim(irrHigh)];

KK = [meanKK(irrLow),meanKK(irrMid),meanKK(irrHigh)];

fig410 = figure('Color','w','Position',[80 80 1180 500]);
tl410 = tiledlayout(fig410,1,2,'TileSpacing','compact','Padding','compact');

% ---- (a) Raw spectra ----
ax = nexttile(tl410,1);
hold(ax,'on'); grid(ax,'on'); box(ax,'on');

h1 = plotCapacitiveArc(ax,irrLow,'-o');
h2 = plotCapacitiveArc(ax,irrMid,'-s');
h3 = plotCapacitiveArc(ax,irrHigh,'-^');

xlabel(ax,'Real impedance, Z'' (\Omega)');
ylabel(ax,'Imaginary impedance, -Z'''' (\Omega)');
title(ax,'(a) Fixed-20-V healthy Nyquist response');

legend(ax,[h1 h2 h3], ...
    {'254 W/m^2, 43.22^\circC', ...
     '316 W/m^2, 45.93^\circC', ...
     '633 W/m^2, 43.41^\circC'}, ...
    'Location','best');

text(ax,0.04,0.05, ...
    sprintf(['mean |e_{KK}| = %.2f / %.2f / %.2f%%'],KK(1),KK(2),KK(3)), ...
    'Units','normalized', ...
    'BackgroundColor','w', ...
    'EdgeColor',[0.82 0.82 0.82], ...
    'Margin',4, ...
    'FontSize',8.8);

axis(ax,'tight');

% ---- (b) Normalised features ----
ax = nexttile(tl410,2);
hold(ax,'on'); grid(ax,'on'); box(ax,'on');

RpN   = 100*Rp/Rp(1);
RsN   = 100*Rs/Rs(1);
ZmaxN = 100*Zmax/Zmax(1);

plot(ax,G,RpN,'-o','MarkerSize',7,'LineWidth',1.7);
plot(ax,G,RsN,'-s','MarkerSize',7,'LineWidth',1.7);
plot(ax,G,ZmaxN,'-^','MarkerSize',7,'LineWidth',1.7);

xlabel(ax,'Mean irradiance, G_{avg} (W/m^2)');
ylabel(ax,'Normalised feature (% of low-G state)');
title(ax,'(b) Model and directly measured features');

legend(ax,{'R_p','R_s','-Z''''_{max}'}, ...
    'Location','best');

ylim(ax,[55 105]);

text(ax,0.04,0.07, ...
    sprintf(['Low \\rightarrow high irradiance:\n' ...
             '\\DeltaR_p = %.1f%%\n' ...
             '\\DeltaR_s = %.1f%%\n' ...
             '\\Delta(-Z''''_{max}) = %.1f%%'], ...
             percentChange(Rp(1),Rp(3)), ...
             percentChange(Rs(1),Rs(3)), ...
             percentChange(Zmax(1),Zmax(3))), ...
    'Units','normalized', ...
    'VerticalAlignment','bottom', ...
    'BackgroundColor','w', ...
    'EdgeColor',[0.82 0.82 0.82], ...
    'Margin',5, ...
    'FontSize',9);

exportFigure(fig410,outDir,'Fig4_10_irradiance_fixed_bias_response',exportDPI);

%% ========================================================================
% FIGURE 4.11
% MATCHED-xi RECONCILIATION MATRIX
%
% The row comparison is the key:
%   xi ~ 0.30: temperature still changes fitted Rp modestly; irradiance large.
%   xi ~ 0.70: temperature spectra nearly invariant; irradiance still large.
% ========================================================================

% ---- xi ~ 0.30, temperature ----
T30_low  = readFra(rawRoot,'20260909_GSM_HLT_FRA_POT_OPB_R04');
T30_high = readFra(rawRoot,'20260909_GSM_HLT_FRA_POT_OPB_R03');

% ---- xi ~ 0.30, irradiance ----
G30_low  = readFra(rawRoot,'20260914_GSM_HLT_FRA_POT_OPX30_R02');
G30_high = readFra(rawRoot,'20260910_GSM_HLT_FRA_POT_OPB_R02');

% ---- xi ~ 0.70, temperature ----
T70_low  = readFra(rawRoot,'20260914_GSM_HLT_FRA_POT_OPX70_R01');
T70_high = readFra(rawRoot,'20260909_GSM_HLT_FRA_POT_OPF_R03');

% ---- xi ~ 0.70, irradiance ----
G70_low  = readFra(rawRoot,'20260910_GSM_HLT_FRA_POT_OPF_R03');
G70_high = readFra(rawRoot,'20260914_GSM_HLT_FRA_POT_OPX70_R03');

% Current reported fitted-Rp changes.
dRp_T30 =  -9.81;
dRp_G30 = -65.13;
dRp_T70 =  +1.11;
dRp_G70 = -62.73;

% Direct arc-height changes, calculated from raw spectra.
dZm_T30 = percentChange(maxPositiveZim(T30_low),maxPositiveZim(T30_high));
dZm_G30 = percentChange(maxPositiveZim(G30_low),maxPositiveZim(G30_high));
dZm_T70 = percentChange(maxPositiveZim(T70_low),maxPositiveZim(T70_high));
dZm_G70 = percentChange(maxPositiveZim(G70_low),maxPositiveZim(G70_high));

fig411 = figure('Color','w','Position',[70 50 1160 800]);
tl411 = tiledlayout(fig411,2,2,'TileSpacing','compact','Padding','compact');

% Common row limits make temperature vs irradiance visually comparable
% at each approximate xi.
row30_x = [0.05 1.02];
row30_y = [0 0.47];

row70_x = [0.05 0.41];
row70_y = [0 0.175];

% ---- (a) xi ~ 0.30 temperature ----
ax = nexttile(tl411,1);
plotMatchedPair(ax,T30_low,T30_high, ...
    {'Cool: 33.76^\circC','Warm: 44.59^\circC'});
title(ax,'(a) \xi \approx 0.30: temperature');
xlim(ax,row30_x); ylim(ax,row30_y);

addMatchedSummary(ax,dRp_T30,dZm_T30, ...
    meanKK(T30_low),meanKK(T30_high));

% ---- (b) xi ~ 0.30 irradiance ----
ax = nexttile(tl411,2);
plotMatchedPair(ax,G30_low,G30_high, ...
    {'Low G: 234 W/m^2','High G: 633 W/m^2'});
title(ax,'(b) \xi \approx 0.30: irradiance');
xlim(ax,row30_x); ylim(ax,row30_y);

addMatchedSummary(ax,dRp_G30,dZm_G30, ...
    meanKK(G30_low),meanKK(G30_high));

% ---- (c) xi ~ 0.70 temperature ----
ax = nexttile(tl411,3);
plotMatchedPair(ax,T70_low,T70_high, ...
    {'Cool: 33.48^\circC','Warm: 44.59^\circC'});
title(ax,'(c) \xi \approx 0.70: temperature');
xlim(ax,row70_x); ylim(ax,row70_y);

addMatchedSummary(ax,dRp_T70,dZm_T70, ...
    meanKK(T70_low),meanKK(T70_high));

% ---- (d) xi ~ 0.70 irradiance ----
ax = nexttile(tl411,4);
plotMatchedPair(ax,G70_low,G70_high, ...
    {'Low G: 254 W/m^2','High G: 598 W/m^2'});
title(ax,'(d) \xi \approx 0.70: irradiance');
xlim(ax,row70_x); ylim(ax,row70_y);

addMatchedSummary(ax,dRp_G70,dZm_G70, ...
    meanKK(G70_low),meanKK(G70_high));

exportFigure(fig411,outDir,'Fig4_11_matched_xi_environmental_matrix',exportDPI);

%% ===================== CONSOLE SUMMARY =====================

fprintf('\nChapter 4.5 core figures generated.\n');
fprintf('Output folder:\n%s\n\n',outDir);

fprintf('Figure 4.9 - clean 60 cm temperature pair:\n');
fprintf('  OPF: dRp = %.2f%%, d(-Zmax) = %.2f%%\n',dRp_OPF,dZmax_OPF);
fprintf('  OPB: dRp = %.2f%%, d(-Zmax) = %.2f%%\n\n',dRp_OPB,dZmax_OPB);

fprintf('Figure 4.10 - fixed-bias irradiance endpoints:\n');
fprintf('  dRp = %.2f%%\n',percentChange(Rp(1),Rp(3)));
fprintf('  dRs = %.2f%%\n',percentChange(Rs(1),Rs(3)));
fprintf('  d(-Zmax) = %.2f%%\n\n',percentChange(Zmax(1),Zmax(3)));

fprintf('Figure 4.11 - matched-xi matrix:\n');
fprintf('  xi~0.30 temperature: dRp %.2f%%, dZmax %.2f%%\n',dRp_T30,dZm_T30);
fprintf('  xi~0.30 irradiance:  dRp %.2f%%, dZmax %.2f%%\n',dRp_G30,dZm_G30);
fprintf('  xi~0.70 temperature: dRp %+.2f%%, dZmax %+.2f%%\n',dRp_T70,dZm_T70);
fprintf('  xi~0.70 irradiance:  dRp %.2f%%, dZmax %.2f%%\n',dRp_G70,dZm_G70);

%% ===================== LOCAL FUNCTIONS =====================

function S = readFra(rawRoot,fileStem)

    filePath = findFileRecursive(rawRoot,fileStem);
    T = readtable(filePath,'VariableNamingRule','preserve');

    S.filePath = filePath;
    S.zre   = double(pickVar(T,{"Z' (Ω)","Z' (\Omega)"}));
    S.zim   = double(pickVar(T,{"-Z'' (Ω)","-Z'' (\Omega)"}));
    S.zmag  = double(pickVar(T,{"Z (Ω)","Z (\Omega)"}));
    S.phase = double(pickVar(T,{"-Phase (°)","-Phase (deg)"}));
    S.freq  = double(pickVar(T,{"Frequency (Hz)"}));
    S.errZre = double(pickVar(T,{"Error Z' (%)"}));

    fields = {'zre','zim','zmag','phase','freq','errZre'};

    for k = 1:numel(fields)
        S.(fields{k}) = S.(fields{k})(:);
    end
end

function h = plotCapacitiveArc(ax,S,lineSpec)

    mask = S.freq <= 2e3 & S.zim >= 0 & ...
           isfinite(S.zre) & isfinite(S.zim);

    h = plot(ax,S.zre(mask),S.zim(mask),lineSpec, ...
        'MarkerSize',3.2,'LineWidth',1.55);
end

function plotMatchedPair(ax,S1,S2,legendText)

    hold(ax,'on'); grid(ax,'on'); box(ax,'on');

    h1 = plotCapacitiveArc(ax,S1,'-o');
    h2 = plotCapacitiveArc(ax,S2,'-s');

    xlabel(ax,'Real impedance, Z'' (\Omega)');
    ylabel(ax,'Imaginary impedance, -Z'''' (\Omega)');

    legend(ax,[h1 h2],legendText,'Location','best');
end

function addMatchedSummary(ax,dRp,dZmax,kk1,kk2)

    text(ax,0.04,0.05, ...
        sprintf(['\\DeltaR_p = %+.1f%%\n' ...
                 '\\Delta(-Z''''_{max}) = %+.1f%%\n' ...
                 'mean |e_{KK}| = %.2f / %.2f%%'], ...
                 dRp,dZmax,kk1,kk2), ...
        'Units','normalized', ...
        'VerticalAlignment','bottom', ...
        'BackgroundColor','w', ...
        'EdgeColor',[0.82 0.82 0.82], ...
        'Margin',4, ...
        'FontSize',8.7);
end

function kk = meanKK(S)

    kk = mean(abs(S.errZre),'omitnan');
end

function zmax = maxPositiveZim(S)

    vals = S.zim(isfinite(S.zim) & S.zim >= 0);

    if isempty(vals)
        zmax = NaN;
    else
        zmax = max(vals);
    end
end

function pct = percentChange(referenceValue,newValue)

    pct = 100*(newValue-referenceValue)/referenceValue;
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
