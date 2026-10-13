%% generate_ch4_3_figures.m
% Chapter 4.3 - Environmental Rig Characterisation
%
% Generates:
%   Fig 4.7 - Rig coupling and selection of targeted environmental contrasts
%   Fig 4.8 - DC response of the selected temperature- and irradiance-dominant pairs
%
% The environmental summary values below are the measured DVF values currently
% reported in Section 4.3. The DC curves themselves are read from Raw Data.zip.
%
% Repository paths are resolved automatically.

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
% FIGURE 4.7 - RIG RESPONSE AND SELECTION OF TARGETED CONTRASTS
% ========================================================================

% ----- Distance sweep: 150 V Variac, fan ON -----
distance_cm = [90 60 30];
Tavg_C      = [30.59 34.69 41.58];
Gavg_Wm2    = [174.6 288.6 544.2];
CVG_pct     = [9.4 12.5 13.6];

% ----- Targeted DVF contrasts identified from the rig map -----
% Temperature-dominant pair: 60 cm, 150 V, fan ON -> OFF
tempPair.G = [292 298];
tempPair.T = [33.7 41.9];

% Irradiance-dominant pair: 60 cm, fan ON, 120 V -> 150 V
irrPair.G  = [223 292];
irrPair.T  = [33.4 33.7];

fig47 = figure('Color','w','Position',[80 80 1180 520]);

% ---- (a) Distance changes both G and T ----
ax1 = axes(fig47,'Position',[0.07 0.14 0.42 0.76]);
hold(ax1,'on'); grid(ax1,'on'); box(ax1,'on');

yyaxis(ax1,'left');
hG = plot(ax1,distance_cm,Gavg_Wm2,'-o', ...
    'MarkerSize',8,'LineWidth',1.8);
ylabel(ax1,'Mean irradiance, G_{avg} (W/m^2)');

yyaxis(ax1,'right');
hT = plot(ax1,distance_cm,Tavg_C,'-s', ...
    'MarkerSize',8,'LineWidth',1.8);
ylabel(ax1,'Mean module temperature, T_{avg} (^\circC)');

xlabel(ax1,'Lamp--module distance, D (cm)');
title(ax1,'(a) Distance is a coupled environmental control');

% Show 90 cm -> 30 cm from left to right.
set(ax1,'XDir','reverse');
xticks(ax1,[30 60 90]);

% CV labels refer to irradiance spatial non-uniformity.
yyaxis(ax1,'left');
for k = 1:numel(distance_cm)
    text(ax1,distance_cm(k),Gavg_Wm2(k)+25, ...
        sprintf('CV_G = %.1f%%',CVG_pct(k)), ...
        'HorizontalAlignment','center', ...
        'FontSize',8.8);
end

legend(ax1,[hG hT],{'Irradiance','Temperature'}, ...
    'Location','northwest');

text(ax1,0.04,0.08, ...
    {'150 V Variac, fan ON', ...
     'Closer lamps increased optical loading, heating and non-uniformity.'}, ...
    'Units','normalized', ...
    'BackgroundColor','w', ...
    'EdgeColor',[0.80 0.80 0.80], ...
    'Margin',4, ...
    'FontSize',8.7);

% ---- (b) Environmental-state map ----
ax2 = axes(fig47,'Position',[0.56 0.14 0.40 0.76]);
hold(ax2,'on'); grid(ax2,'on'); box(ax2,'on');

% Distance sweep background path.
hDist = plot(ax2,Gavg_Wm2,Tavg_C,'-o', ...
    'MarkerSize',7,'LineWidth',1.4);

for k = 1:numel(distance_cm)
    text(ax2,Gavg_Wm2(k)+8,Tavg_C(k)+0.3, ...
        sprintf('%d cm',distance_cm(k)), ...
        'FontSize',8.5);
end

% Temperature-dominant selected direction.
hTemp = plot(ax2,tempPair.G,tempPair.T,'-s', ...
    'MarkerSize',9,'LineWidth',2.0);

% Irradiance-dominant selected direction.
hIrr = plot(ax2,irrPair.G,irrPair.T,'-d', ...
    'MarkerSize',9,'LineWidth',2.0);

% Highlight shared 150 V / fan ON neighbourhood.
plot(ax2,292,33.7,'o','MarkerSize',11,'LineWidth',1.6, ...
    'HandleVisibility','off');

xlabel(ax2,'Mean irradiance, G_{avg} (W/m^2)');
ylabel(ax2,'Mean module temperature, T_{avg} (^\circC)');
title(ax2,'(b) Selecting high-information environmental contrasts');

legend(ax2,[hDist hTemp hIrr], ...
    {'Distance sweep','Temperature-dominant pair','Irradiance-dominant pair'}, ...
    'Location','northwest');

text(ax2,305,38.2, ...
    sprintf('Temperature contrast\n\\DeltaT \\approx 8.2 ^\\circC\n\\DeltaG \\approx 2%%'), ...
    'FontSize',9, ...
    'BackgroundColor','w', ...
    'EdgeColor',[0.82 0.82 0.82], ...
    'Margin',4);

text(ax2,235,32.0, ...
    sprintf('Irradiance contrast\n\\DeltaG \\approx 31%%\n|\\DeltaT| < 0.4 ^\\circC'), ...
    'FontSize',9, ...
    'BackgroundColor','w', ...
    'EdgeColor',[0.82 0.82 0.82], ...
    'Margin',4);

exportFigure(fig47,outDir,'Fig4_7_environmental_rig_selection',exportDPI);

%% ========================================================================
% FIGURE 4.8 - DC CONSEQUENCES OF THE SELECTED CONTRASTS
%
% Mapping inferred from the archived DVF DC files:
%   Temperature pair:
%       20260902 R01 = 60 cm, 150 V, fan ON
%       20260902 R02 = 60 cm, 150 V, fan OFF
%
%   Irradiance pair:
%       20260901 R04 = 60 cm, 120 V, fan ON
%       20260901 R01 = 60 cm, 150 V, fan ON
% ========================================================================

tempCoolStem = '20260902_GSM_HLT_DC_R01';
tempWarmStem = '20260902_GSM_HLT_DC_R02';

irrLowStem   = '20260901_GSM_HLT_DC_R04';
irrHighStem  = '20260901_GSM_HLT_DC_R01';

TCool = readDcCurve(rawRoot,tempCoolStem);
TWarm = readDcCurve(rawRoot,tempWarmStem);
GLow  = readDcCurve(rawRoot,irrLowStem);
GHigh = readDcCurve(rawRoot,irrHighStem);

[VTCool,ITCool,~] = physicalBranch(TCool);
[VTWarm,ITWarm,~] = physicalBranch(TWarm);
[VGLow,IGLow,~]   = physicalBranch(GLow);
[VGHigh,IGHigh,~] = physicalBranch(GHigh);

fig48 = figure('Color','w','Position',[80 80 1180 500]);
tl = tiledlayout(fig48,1,2,'TileSpacing','compact','Padding','compact');

% ---- (a) Temperature-dominant DC contrast ----
ax = nexttile(tl,1);
hold(ax,'on'); grid(ax,'on'); box(ax,'on');

h1 = plot(ax,VTCool,ITCool,'LineWidth',2.0);
h2 = plot(ax,VTWarm,ITWarm,'LineWidth',2.0);

plot(ax,TCool.Vmp,TCool.Imp,'o','MarkerSize',7,'LineWidth',1.3, ...
    'HandleVisibility','off');
plot(ax,TWarm.Vmp,TWarm.Imp,'o','MarkerSize',7,'LineWidth',1.3, ...
    'HandleVisibility','off');

xlabel(ax,'Voltage, V (V)');
ylabel(ax,'Current, I (A)');
title(ax,'(a) Temperature-dominant pair');

legend(ax,[h1 h2], ...
    {'33.7^\circC, 292 W/m^2, fan ON', ...
     '41.9^\circC, 298 W/m^2, fan OFF'}, ...
    'Location','southwest');

xlim(ax,[0 ceil(max([TCool.Voc TWarm.Voc])+0.3)]);
ylim(ax,[0 1.08*max([ITCool; ITWarm])]);

text(ax,0.04,0.95, ...
    sprintf(['Current plateau changes little;\n' ...
             'the warm-state knee shifts to lower voltage.']), ...
    'Units','normalized', ...
    'VerticalAlignment','top', ...
    'BackgroundColor','w', ...
    'EdgeColor',[0.82 0.82 0.82], ...
    'Margin',4, ...
    'FontSize',8.8);

% ---- (b) Irradiance-dominant DC contrast ----
ax = nexttile(tl,2);
hold(ax,'on'); grid(ax,'on'); box(ax,'on');

h3 = plot(ax,VGLow,IGLow,'LineWidth',2.0);
h4 = plot(ax,VGHigh,IGHigh,'LineWidth',2.0);

plot(ax,GLow.Vmp,GLow.Imp,'o','MarkerSize',7,'LineWidth',1.3, ...
    'HandleVisibility','off');
plot(ax,GHigh.Vmp,GHigh.Imp,'o','MarkerSize',7,'LineWidth',1.3, ...
    'HandleVisibility','off');

xlabel(ax,'Voltage, V (V)');
ylabel(ax,'Current, I (A)');
title(ax,'(b) Irradiance-dominant pair');

legend(ax,[h3 h4], ...
    {'33.4^\circC, 223 W/m^2, 120 V', ...
     '33.7^\circC, 292 W/m^2, 150 V'}, ...
    'Location','southwest');

xlim(ax,[0 ceil(max([GLow.Voc GHigh.Voc])+0.3)]);
ylim(ax,[0 1.08*max([IGLow; IGHigh])]);

text(ax,0.04,0.95, ...
    sprintf(['Increasing irradiance raises the\n' ...
             'current-generating level and maximum power.']), ...
    'Units','normalized', ...
    'VerticalAlignment','top', ...
    'BackgroundColor','w', ...
    'EdgeColor',[0.82 0.82 0.82], ...
    'Margin',4, ...
    'FontSize',8.8);

exportFigure(fig48,outDir,'Fig4_8_targeted_environmental_DC_contrasts',exportDPI);

%% ===================== CONSOLE SUMMARY =====================

fprintf('\nChapter 4.3 figures generated.\n');
fprintf('Output folder:\n%s\n\n',outDir);

fprintf('Distance sweep DC values from archived raw files:\n');
distanceStems = { ...
    '20260901_GSM_HLT_DC_R02'; ... % 90 cm
    '20260901_GSM_HLT_DC_R01'; ... % 60 cm
    '20260901_GSM_HLT_DC_R03'  ... % 30 cm
    };

for k = 1:3
    C = readDcCurve(rawRoot,distanceStems{k});
    fprintf('  %2d cm: Isc = %.3f A, Pmp = %.2f W, Voc = %.3f V, Vmp = %.3f V\n', ...
        distance_cm(k),C.Isc,C.Pmp,C.Voc,C.Vmp);
end

fprintf('\nTemperature pair raw DC metrics:\n');
fprintf('  Cool: Voc %.3f V, Isc %.3f A, Vmp %.3f V, Pmp %.2f W\n', ...
    TCool.Voc,TCool.Isc,TCool.Vmp,TCool.Pmp);
fprintf('  Warm: Voc %.3f V, Isc %.3f A, Vmp %.3f V, Pmp %.2f W\n', ...
    TWarm.Voc,TWarm.Isc,TWarm.Vmp,TWarm.Pmp);

fprintf('\nIrradiance pair raw DC metrics:\n');
fprintf('  Low G:  Voc %.3f V, Isc %.3f A, Vmp %.3f V, Pmp %.2f W\n', ...
    GLow.Voc,GLow.Isc,GLow.Vmp,GLow.Pmp);
fprintf('  High G: Voc %.3f V, Isc %.3f A, Vmp %.3f V, Pmp %.2f W\n', ...
    GHigh.Voc,GHigh.Isc,GHigh.Vmp,GHigh.Pmp);

%% ===================== LOCAL FUNCTIONS =====================

function S = readDcCurve(rawRoot,fileStem)

    filePath = findFileRecursive(rawRoot,fileStem);
    T = readtable(filePath,'VariableNamingRule','preserve');

    V = double(pickVar(T, ...
        {"Corrected Potential (V)","Corrected Potential"}));
    I = double(pickVar(T, ...
        {"Corrected Current (A)","Corrected Current"}));
    P = double(pickVar(T, ...
        {"Corrected Power (W)","Corrected Power"}));

    V = V(:);
    I = I(:);
    P = P(:);

    mask = isfinite(V) & isfinite(I) & isfinite(P);
    V = V(mask);
    I = I(mask);
    P = P(mask);

    [V,idx] = sort(V);
    I = I(idx);
    P = P(idx);

    [V,ia] = unique(V,'stable');
    I = I(ia);
    P = P(ia);

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
        k = crossing;
        Voc = V(k) + (0-I(k))*(V(k+1)-V(k))/(I(k+1)-I(k));
        return;
    end

    n = min(8,numel(V));
    idx = (numel(V)-n+1):numel(V);
    p = polyfit(I(idx),V(idx),1);
    Voc = polyval(p,0);
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
