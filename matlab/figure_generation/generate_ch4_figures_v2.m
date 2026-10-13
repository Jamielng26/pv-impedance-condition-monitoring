%% generate_ch4_figures_v2.m
% Chapter 4.1 figure generation for PV operating-point visualisation
% Revised version: cleaner report graphics + fixes for TeX/legend errors.
%
% Generates:
%   Fig 4.1 - Representative I-V / P-V operating-point map
%   Fig 4.2 - Operating-point migration across healthy conditions
%   Fig 4.3 - Normalised xi operating-point definition
%
% IMPORTANT:
%   1) Extract Raw Data.zip first.
%   2) Edit the three USER SETTINGS paths below.
%   3) Run this script.
%
% Output: .fig, vector .pdf and 300 dpi .png

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

% Representative healthy DC curve used for Figs 4.1 and 4.3
repStem = '20260909_GSM_HLT_DC_R01';

% Healthy curves used in Fig 4.2
overlayStems = { ...
    '20260909_GSM_HLT_DC_R01'; ...
    '20260909_GSM_HLT_DC_R04'; ...
    '20260910_GSM_HLT_DC_R03'; ...
    '20260914_GSM_HLT_DC_R03' ...
    };

exportDPI = 300;

%% ===================== GLOBAL PLOT DEFAULTS =====================

set(groot, 'defaultAxesFontName', 'Helvetica');
set(groot, 'defaultAxesFontSize', 11);
set(groot, 'defaultAxesLineWidth', 0.8);
set(groot, 'defaultLineLineWidth', 1.8);
set(groot, 'defaultLegendFontSize', 9);
set(groot, 'defaultTextInterpreter', 'tex');
set(groot, 'defaultLegendInterpreter', 'tex');

%% ===================== LOAD MASTER LOG =====================

runLog = readtable(masterLogPath, ...
    'Sheet', 'Run Log', ...
    'VariableNamingRule', 'preserve');

%% ===================== FIGURE 4.1 =====================
% Representative DC characterisation and initial operating points

rep = readDcCurve(rawRoot, repStem);
[Vphys, Iphys, Pphys] = physicalBranch(rep);

Vopf = 20.0;
Vopb = 0.9 * rep.Voc;

Iopf = interpCurve(rep.V, rep.I, Vopf);
Iopb = interpCurve(rep.V, rep.I, Vopb);
Popf = interpCurve(rep.V, rep.P, Vopf);
Popb = interpCurve(rep.V, rep.P, Vopb);

fig1 = figure('Color','w','Position',[80 80 1180 500]);
tl = tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

% -------- (a) I-V --------
ax1 = nexttile(tl,1);
hold(ax1,'on'); grid(ax1,'on'); box(ax1,'on');

hIV = plot(ax1, Vphys, Iphys, 'LineWidth', 2.0);
hMPP1 = plot(ax1, rep.Vmp, rep.Imp, 's', ...
    'MarkerSize', 8, 'LineWidth', 1.5);
hOPB1 = plot(ax1, Vopb, Iopb, 'o', ...
    'MarkerSize', 8, 'LineWidth', 1.5);
hOPF1 = plot(ax1, Vopf, Iopf, 'd', ...
    'MarkerSize', 8, 'LineWidth', 1.5);

% End-point markers
plot(ax1, 0, rep.Isc, 'o', 'MarkerSize',7, ...
    'LineWidth',1.2, 'HandleVisibility','off');
plot(ax1, rep.Voc, 0, '^', 'MarkerSize',7, ...
    'LineWidth',1.2, 'HandleVisibility','off');

% Reference verticals (no text on lines; prevents clutter)
xline(ax1, rep.Vmp, ':', 'HandleVisibility','off');
xline(ax1, Vopb, '--', 'HandleVisibility','off');
xline(ax1, Vopf, '-.', 'HandleVisibility','off');
xline(ax1, rep.Voc, ':', 'HandleVisibility','off');

xlabel(ax1,'Voltage, V (V)');
ylabel(ax1,'Current, I (A)');
title(ax1,'(a) I-V characteristic');

xlim(ax1,[0, ceil(rep.Voc + 0.5)]);
ylim(ax1,[0, 1.10*max(Iphys)]);

% Compact metric box
metricText = { ...
    sprintf('I_{sc} = %.3f A', rep.Isc), ...
    sprintf('V_{mp} = %.2f V', rep.Vmp), ...
    sprintf('I_{mp} = %.3f A', rep.Imp), ...
    sprintf('V_{oc} = %.2f V', rep.Voc) ...
    };
text(ax1, 0.03, 0.06, metricText, ...
    'Units','normalized', ...
    'VerticalAlignment','bottom', ...
    'BackgroundColor','w', ...
    'EdgeColor',[0.75 0.75 0.75], ...
    'Margin',5);

legend(ax1,[hIV hMPP1 hOPB1 hOPF1], ...
    {'Measured I-V','MPP','OPB = 0.9V_{oc}','OPF = 20 V'}, ...
    'Location','southwest');

% -------- (b) P-V --------
ax2 = nexttile(tl,2);
hold(ax2,'on'); grid(ax2,'on'); box(ax2,'on');

hPV = plot(ax2, Vphys, Pphys, 'LineWidth', 2.0);
hMPP2 = plot(ax2, rep.Vmp, rep.Pmp, 's', ...
    'MarkerSize', 8, 'LineWidth', 1.5);
hOPB2 = plot(ax2, Vopb, Popb, 'o', ...
    'MarkerSize', 8, 'LineWidth', 1.5);
hOPF2 = plot(ax2, Vopf, Popf, 'd', ...
    'MarkerSize', 8, 'LineWidth', 1.5);

xline(ax2, rep.Vmp, ':', 'HandleVisibility','off');
xline(ax2, Vopb, '--', 'HandleVisibility','off');
xline(ax2, Vopf, '-.', 'HandleVisibility','off');

xlabel(ax2,'Voltage, V (V)');
ylabel(ax2,'Power, P (W)');
title(ax2,'(b) P-V characteristic');

xlim(ax2,[0, ceil(rep.Voc + 0.5)]);
ylim(ax2,[0, 1.12*max(Pphys)]);

text(ax2, 0.03, 0.94, ...
    sprintf('P_{mp} = %.2f W', rep.Pmp), ...
    'Units','normalized', ...
    'VerticalAlignment','top', ...
    'BackgroundColor','w', ...
    'EdgeColor',[0.75 0.75 0.75], ...
    'Margin',5);

legend(ax2,[hPV hMPP2 hOPB2 hOPF2], ...
    {'Measured P-V','MPP','OPB = 0.9V_{oc}','OPF = 20 V'}, ...
    'Location','northwest');

exportFigure(fig1, outDir, 'Fig4_1_IV_PV_operating_point_map', exportDPI);

%% ===================== FIGURE 4.2 =====================
% Demonstrate that fixed 20 V and 0.9Voc do not uniquely identify the
% same position relative to the knee when the I-V curve changes.

fig2 = figure('Color','w','Position',[100 100 1050 620]);
ax = axes(fig2);
hold(ax,'on'); grid(ax,'on'); box(ax,'on');

nCurves = numel(overlayStems);
hCurve = gobjects(nCurves,1);
labels = cell(nCurves,1);

allVoc = nan(nCurves,1);
allImax = nan(nCurves,1);

for k = 1:nCurves
    C = readDcCurve(rawRoot, overlayStems{k});
    [Vc, Ic, ~] = physicalBranch(C);

    info_k = getRunInfo(runLog, overlayStems{k});
    env_k = getEnvMeta(rawRoot, info_k);

    hCurve(k) = plot(ax, Vc, Ic, 'LineWidth', 1.8);
    thisColour = hCurve(k).Color;

    % MPP marker
    plot(ax, C.Vmp, C.Imp, '^', ...
        'Color',thisColour, ...
        'MarkerSize',7, ...
        'LineWidth',1.3, ...
        'HandleVisibility','off');

    % OPB marker = 0.9Voc
    V09 = 0.9*C.Voc;
    I09 = interpCurve(C.V, C.I, V09);
    plot(ax, V09, I09, 'o', ...
        'Color',thisColour, ...
        'MarkerSize',7, ...
        'LineWidth',1.3, ...
        'HandleVisibility','off');

    % Legend text
    if ~isempty(env_k) && isfiniteScalar(env_k.Gavg) && isfiniteScalar(env_k.Tavg)
        labels{k} = sprintf('G = %.0f W/m^2, T = %.1f ^\\circC', ...
            double(env_k.Gavg), double(env_k.Tavg));
    else
        labels{k} = char(overlayStems{k});
    end

    allVoc(k) = C.Voc;
    allImax(k) = max(Ic);
end

% Fixed OPF = 20 V
hOPF = xline(ax,20,'--','20 V (OPF)', ...
    'LabelVerticalAlignment','bottom', ...
    'LabelHorizontalAlignment','left', ...
    'LineWidth',1.2);

% Dummy marker handles for legend explanation
hVmpLegend = plot(ax,nan,nan,'^k', ...
    'MarkerSize',7,'LineWidth',1.3);
hOPBLegend = plot(ax,nan,nan,'ok', ...
    'MarkerSize',7,'LineWidth',1.3);

xlabel(ax,'Voltage, V (V)');
ylabel(ax,'Current, I (A)');
title(ax,'Operating-point migration across healthy I-V characteristics');

xlim(ax,[0, ceil(max(allVoc)+0.5)]);
ylim(ax,[0, 1.08*max(allImax)]);

legendHandles = [hCurve(:); hVmpLegend; hOPBLegend; hOPF];
legendLabels  = [labels(:); {'V_{mp}'; '0.9V_{oc} (OPB)'; '20 V (OPF)'}];

legend(ax,legendHandles,legendLabels, ...
    'Location','eastoutside');

exportFigure(fig2, outDir, 'Fig4_2_operating_point_migration', exportDPI);

%% ===================== FIGURE 4.3 (IMPROVED) =====================
% Full I-V inset + zoomed high-voltage operating region

fig3 = figure('Color','w','Position',[120 120 1150 620]);

% Read representative curve
rep = readDcCurve(rawRoot, repStem);
[Vphys, Iphys, ~] = physicalBranch(rep);

% Define xi positions
xiVals = [0.00 0.30 0.70 1.00];
Vxi = rep.Vmp + xiVals .* (rep.Voc - rep.Vmp);
Ixi = arrayfun(@(x) interpCurve(rep.V, rep.I, x), Vxi);
Ixi(end) = 0;   % xi = 1 is Voc

%% -------- MAIN AXIS: ZOOMED HIGH-VOLTAGE REGION --------
axMain = axes(fig3, 'Position', [0.08 0.14 0.63 0.76]);
hold(axMain,'on'); grid(axMain,'on'); box(axMain,'on');

plot(axMain, Vphys, Iphys, 'LineWidth', 2.2);

% Plot xi markers
plot(axMain, Vxi, Ixi, 'o', 'MarkerSize', 8, 'LineWidth', 1.4);
plot(axMain, Vxi(3), Ixi(3), 'p', 'MarkerSize', 16, 'LineWidth', 2.0); % OPX70

% Reference lines
xline(axMain, rep.Vmp, ':', 'HandleVisibility','off');
xline(axMain, rep.Voc, ':', 'HandleVisibility','off');

% Labels
dy = 0.035 * max(Iphys);

text(axMain, Vxi(1)-0.03, Ixi(1)+dy, '\xi = 0  (V_{mp})', ...
    'HorizontalAlignment','right', 'VerticalAlignment','bottom', 'FontSize',11);

text(axMain, Vxi(2)+0.02, Ixi(2)+dy, '\xi = 0.30', ...
    'HorizontalAlignment','left', 'VerticalAlignment','bottom', 'FontSize',11);

text(axMain, Vxi(3)-0.10, Ixi(3)+dy, '\xi = 0.70  (OPX70)', ...
    'HorizontalAlignment','center', 'VerticalAlignment','bottom', ...
    'FontSize',12, 'FontWeight','bold');

text(axMain, Vxi(4)-0.08, Ixi(4)+dy, '\xi = 1  (V_{oc})', ...
    'HorizontalAlignment','right', 'VerticalAlignment','bottom', 'FontSize',11);

% Normalised xi scale drawn below
yScale = -0.11 * max(Iphys);
tickHalf = 0.015 * max(Iphys);

plot(axMain, [rep.Vmp rep.Voc], [yScale yScale], 'k-', 'LineWidth', 1.3);

for k = 1:numel(Vxi)
    plot(axMain, [Vxi(k) Vxi(k)], [yScale-tickHalf yScale+tickHalf], ...
        'k-', 'LineWidth', 1.1);
end

scaleLabels = {'0','0.30','0.70','1'};
for k = 1:numel(Vxi)
    text(axMain, Vxi(k), yScale-0.03*max(Iphys), scaleLabels{k}, ...
        'HorizontalAlignment','center', 'VerticalAlignment','top', 'FontSize',10);
end

text(axMain, mean([rep.Vmp rep.Voc]), yScale+0.04*max(Iphys), ...
    '\xi = (V_{bias} - V_{mp}) / (V_{oc} - V_{mp})', ...
    'HorizontalAlignment','center', 'VerticalAlignment','bottom', ...
    'FontWeight','bold', 'FontSize',11);

xlabel(axMain, 'Voltage, V (V)');
ylabel(axMain, 'Current, I (A)');
title(axMain, 'High-voltage operating region used for FRA bias definition');

% Zoom only into the relevant region
xMarginLeft  = 0.35;
xMarginRight = 0.35;
xlim(axMain, [rep.Vmp - xMarginLeft, rep.Voc + xMarginRight]);
ylim(axMain, [-0.16*max(Iphys), 1.08*max(Iphys)]);

%% -------- INSET AXIS: FULL I-V CURVE --------
axInset = axes(fig3, 'Position', [0.77 0.58 0.18 0.25]);
hold(axInset,'on'); grid(axInset,'on'); box(axInset,'on');

plot(axInset, Vphys, Iphys, 'LineWidth', 1.6);
plot(axInset, rep.Vmp, rep.Imp, 'o', 'MarkerSize', 6, 'LineWidth', 1.2);
plot(axInset, rep.Voc, 0, '^', 'MarkerSize', 6, 'LineWidth', 1.2);

xlabel(axInset, 'V (V)', 'FontSize', 9);
ylabel(axInset, 'I (A)', 'FontSize', 9);
title(axInset, 'Full I-V curve', 'FontSize', 10);

xlim(axInset, [0, ceil(rep.Voc + 0.5)]);
ylim(axInset, [0, 1.08*max(Iphys)]);
set(axInset, 'FontSize', 9);

% Rectangle showing zoomed region
zoomX = [rep.Vmp - xMarginLeft, rep.Voc + xMarginRight];
zoomY = [0, 1.08*max(Iphys)];

rectangle(axInset, ...
    'Position', [zoomX(1), zoomY(1), zoomX(2)-zoomX(1), zoomY(2)-zoomY(1)], ...
    'EdgeColor', 'r', 'LineStyle', '--', 'LineWidth', 1.2);

%% -------- OPTIONAL CONNECTING ANNOTATION --------
annotation(fig3, 'textbox', [0.76 0.50 0.20 0.05], ...
    'String', 'Zoomed region shown at left', ...
    'LineStyle', 'none', ...
    'HorizontalAlignment', 'center', ...
    'FontSize', 10, ...
    'Color', [0.25 0.25 0.25]);

exportFigure(fig3, outDir, 'Fig4_3_xi_definition_OPX70_zoomed', exportDPI);

%% ===================== LOCAL FUNCTIONS =====================

function S = readDcCurve(rawRoot,fileStem)

    filePath = findFileRecursive(rawRoot,fileStem);

    T = readtable(filePath,'VariableNamingRule','preserve');

    V = pickVar(T,{'Corrected Potential (V)','Corrected Potential'});
    I = pickVar(T,{'Corrected Current (A)','Corrected Current'});
    P = pickVar(T,{'Corrected Power (W)','Corrected Power'});

    V = double(V(:));
    I = double(I(:));
    P = double(P(:));

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
    Isc = interpCurve(V,I,0);

    physical = (V >= 0) & (V <= Voc) & (I >= 0);

    [Pmp,localIdx] = max(P(physical));
    physicalIndices = find(physical);
    idxP = physicalIndices(localIdx);

    Vmp = V(idxP);
    Imp = I(idxP);

    S.filePath = filePath;
    S.V = V;
    S.I = I;
    S.P = P;
    S.Voc = Voc;
    S.Isc = Isc;
    S.Vmp = Vmp;
    S.Imp = Imp;
    S.Pmp = Pmp;
end

function [V,I,P] = physicalBranch(S)
    % Retain only the power-producing I-V branch and append the interpolated
    % open-circuit point, so negative-current forward-bias data do not appear
    % in the report plots.

    mask = S.V >= 0 & S.V < S.Voc & S.I >= 0;

    V = S.V(mask);
    I = S.I(mask);
    P = S.P(mask);

    % Append the derived open-circuit endpoint.
    V = [V; S.Voc];
    I = [I; 0];
    P = [P; 0];
end

function val = interpCurve(x,y,xq)
    val = interp1(x,y,xq,'pchip','extrap');
end

function Voc = estimateVoc(V,I)
    % Prefer a measured zero-current crossing.
    crossing = find(I(1:end-1).*I(2:end) <= 0,1,'first');

    if ~isempty(crossing)
        Voc = interp1( ...
            I(crossing:crossing+1), ...
            V(crossing:crossing+1), ...
            0,'linear','extrap');
        return;
    end

    % Otherwise extrapolate from the highest-voltage points.
    n = min(8,numel(V));
    idx = (numel(V)-n+1):numel(V);

    p = polyfit(I(idx),V(idx),1);
    Voc = polyval(p,0);
end

function row = getRunInfo(runLog,fileStem)

    names = string(runLog.("Data File Name"));
    names = erase(names,'.xlsx');
    names = strip(names);

    idx = find(names == string(fileStem),1,'first');

    if isempty(idx)
        row = [];
    else
        row = runLog(idx,:);
    end
end

function env = getEnvMeta(rawRoot,runRow)

    env = [];

    if isempty(runRow)
        return;
    end

    envFile = runRow.("Environment File");
    envID   = runRow.("Environment ID");

    if ismissing(envFile) || ismissing(envID)
        return;
    end

    envFileStem = erase(string(envFile),'.xlsx');

    try
        envPath = findFileRecursive(rawRoot,envFileStem);
    catch
        return;
    end

    T = readtable(envPath, ...
        'Sheet','Environment Index', ...
        'VariableNamingRule','preserve');

    envIDs = string(pickVar(T,{'Environment ID'}));
    idx = find(envIDs == string(envID),1,'first');

    if isempty(idx)
        return;
    end

    env.Tavg = getCellValue(T,idx, ...
        {'Temp Avg (°C)','Temp Avg (degC)','Temp Avg'});

    env.Gavg = getCellValue(T,idx, ...
        {'Irradiance Avg (W/m²)', ...
         'Irradiance Avg (W/m^2)', ...
         'Irradiance Avg'});

    env.Variac = getCellValue(T,idx,{'Variac'});

    env.Distance = getCellValue(T,idx, ...
        {'Lamp–Panel Distance (cm)', ...
         'Lamp-Panel Distance (cm)'});

    env.Fan = getCellValue(T,idx,{'Fan'});
end

function value = getCellValue(T,rowIdx,candidateNames)

    value = NaN;
    names = string(T.Properties.VariableNames);

    for c = 1:numel(candidateNames)
        idx = find(names == string(candidateNames{c}),1,'first');

        if ~isempty(idx)
            v = T{rowIdx,idx};

            if iscell(v)
                v = v{1};
            end

            value = v;
            return;
        end
    end
end

function tf = isfiniteScalar(x)
    tf = isnumeric(x) && isscalar(x) && isfinite(x);
end

function var = pickVar(T,candidateNames)

    names = string(T.Properties.VariableNames);

    for c = 1:numel(candidateNames)
        idx = find(names == string(candidateNames{c}),1,'first');

        if ~isempty(idx)
            var = T.(names(idx));
            return;
        end
    end

    error('Could not find any of these variables: %s', ...
        strjoin(candidateNames,', '));
end

function filePath = findFileRecursive(rootDir,fileStem)

    fileStem = erase(string(fileStem),'.xlsx');

    hits = dir(fullfile(rootDir,'**',[char(fileStem) '.xlsx']));

    if isempty(hits)
        hits = dir(fullfile(rootDir,'**',[char(fileStem) '*']));
    end

    if isempty(hits)
        error('Could not find file "%s" under:\n%s',fileStem,rootDir);
    end

    % Ignore Apple resource-fork files if present.
    bad = startsWith({hits.name},'._');
    hits = hits(~bad);

    if isempty(hits)
        error('Only Apple resource-fork copies found for "%s".',fileStem);
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
