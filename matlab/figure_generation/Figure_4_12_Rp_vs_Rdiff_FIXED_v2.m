%% Figure 4.12 -- Healthy-state relationship between fitted Rp and local DC differential resistance
% Jamie Langeveldt / ChatGPT draft
%
% PURPOSE
% -------
% Build the Chapter 4 healthy-only synthesis figure:
%   (a) fitted Rp versus local DC differential resistance, Rdiff
%   (b) leave-one-environment-out prediction residuals
%
% The script uses the healthy spectra already used in Chapter 4:
%   - 6 temperature states (2026-09-09), each with OPF and OPB
%   - 3 irradiance states (2026-09-10), each with OPF and OPB
%   - 3 targeted OPX follow-up states (2026-09-14)
%   - 1 additional healthy OPX70 reference (2026-09-16)
%
% Total healthy spectra used here: 22
%
% HOW IT WORKS
% ------------
% 1) Reads the fitted Rp values from the *_PARAMS.xlsx files
% 2) Reads the corresponding DC curves from the healthy DC files
% 3) Reconstructs the nominal FRA bias voltage from the operating-point label:
%       OPF   -> 20 V
%       OPB   -> 0.9 Voc
%       OPX30 -> Vmp + 0.30*(Voc - Vmp)
%       OPX70 -> Vmp + 0.70*(Voc - Vmp)
% 4) Estimates the local DC differential resistance with a 19-point linear fit:
%       Rdiff = dV/dI evaluated locally around Vbias
% 5) Fits the empirical healthy relation:
%       ln(Rp) = a + b*ln(Rdiff)
% 6) Performs leave-one-environment-out validation, where both operating-point
%    spectra from the same environmental state are excluded together.
%
% NOTES
% -----
% - This is written to work either from the zipped "Raw Data.zip" archive
%   or from an already-unzipped "Raw Data" folder.
% - If your local path differs, update RAW_SOURCE below.
% - Styling is deliberately simple so that you can tune it later.

clear; clc; close all;

%% -------------------------- REPOSITORY SETTINGS --------------------------
scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir), scriptDir = pwd; end
repoRoot = fileparts(fileparts(scriptDir));

RAW_SOURCE = fullfile(repoRoot,'data','raw','Raw_Data_2026_Clean.zip');
SAVE_FIG   = true;
OUT_DIR    = fullfile(repoRoot,'figures','generated');
FIG_NAME   = 'Fig4_12_healthy_Rp_vs_Rdiff';
EXPORT_CSV = true;
SHOW_LABELS = false;           % true = annotate every point
LOCAL_FIT_WINDOW = 19;         % number of DC points in local dI/dV fit
% -------------------------------------------------------------------------
if SAVE_FIG && ~exist(OUT_DIR,'dir')
    mkdir(OUT_DIR);
end

rootDir = prepareRawDataRoot(RAW_SOURCE);

%% ---------------------------- DATASET DEFINITION -------------------------
% stateID groups spectra that came from the same environmental/DC state.
% This is what the leave-one-environment-out validation uses.

S = struct( ...
    'label', {}, ...
    'stateID', {}, ...
    'campaign', {}, ...
    'biasFamily', {}, ...
    'paramFile', {}, ...
    'dcFile', {});

% ---------- Temperature campaign (2026-09-09): six states, OPF + OPB ----------
S(end+1) = makeEntry('T30 warm, OPF', 'T30_warm', 'Temperature', 'OPF',  ...
    '20260909_GSM_HLT_FRA_POT_OPF_R01_PARAMS.xlsx', '20260909_GSM_HLT_DC_R01.xlsx');
S(end+1) = makeEntry('T30 cool, OPF', 'T30_cool', 'Temperature', 'OPF',  ...
    '20260909_GSM_HLT_FRA_POT_OPF_R02_PARAMS.xlsx', '20260909_GSM_HLT_DC_R02.xlsx');
S(end+1) = makeEntry('T60 warm, OPF', 'T60_warm', 'Temperature', 'OPF',  ...
    '20260909_GSM_HLT_FRA_POT_OPF_R03_PARAMS.xlsx', '20260909_GSM_HLT_DC_R03.xlsx');
S(end+1) = makeEntry('T60 cool, OPF', 'T60_cool', 'Temperature', 'OPF',  ...
    '20260909_GSM_HLT_FRA_POT_OPF_R04_PARAMS.xlsx', '20260909_GSM_HLT_DC_R04.xlsx');
S(end+1) = makeEntry('T90 warm, OPF', 'T90_warm', 'Temperature', 'OPF',  ...
    '20260909_GSM_HLT_FRA_POT_OPF_R05_PARAMS.xlsx', '20260909_GSM_HLT_DC_R05.xlsx');
S(end+1) = makeEntry('T90 cool, OPF', 'T90_cool', 'Temperature', 'OPF',  ...
    '20260909_GSM_HLT_FRA_POT_OPF_R06_PARAMS.xlsx', '20260909_GSM_HLT_DC_R06.xlsx');

S(end+1) = makeEntry('T30 warm, OPB', 'T30_warm', 'Temperature', 'OPB',  ...
    '20260909_GSM_HLT_FRA_POT_OPB_R01_PARAMS.xlsx', '20260909_GSM_HLT_DC_R01.xlsx');
S(end+1) = makeEntry('T30 cool, OPB', 'T30_cool', 'Temperature', 'OPB',  ...
    '20260909_GSM_HLT_FRA_POT_OPB_R02_PARAMS.xlsx', '20260909_GSM_HLT_DC_R02.xlsx');
S(end+1) = makeEntry('T60 warm, OPB', 'T60_warm', 'Temperature', 'OPB',  ...
    '20260909_GSM_HLT_FRA_POT_OPB_R03_PARAMS.xlsx', '20260909_GSM_HLT_DC_R03.xlsx');
S(end+1) = makeEntry('T60 cool, OPB', 'T60_cool', 'Temperature', 'OPB',  ...
    '20260909_GSM_HLT_FRA_POT_OPB_R04_PARAMS.xlsx', '20260909_GSM_HLT_DC_R04.xlsx');
S(end+1) = makeEntry('T90 warm, OPB', 'T90_warm', 'Temperature', 'OPB',  ...
    '20260909_GSM_HLT_FRA_POT_OPB_R05_PARAMS.xlsx', '20260909_GSM_HLT_DC_R05.xlsx');
S(end+1) = makeEntry('T90 cool, OPB', 'T90_cool', 'Temperature', 'OPB',  ...
    '20260909_GSM_HLT_FRA_POT_OPB_R06_PARAMS.xlsx', '20260909_GSM_HLT_DC_R06.xlsx');

% ---------- Irradiance campaign (2026-09-10): three states, OPF + OPB ----------
% R03 = low irradiance, R01 = mid irradiance, R02 = high irradiance
S(end+1) = makeEntry('G mid, OPF',  'G_mid',  'Irradiance', 'OPF', ...
    '20260910_GSM_HLT_FRA_POT_OPF_R01_PARAMS.xlsx', '20260910_GSM_HLT_DC_R01.xlsx');
S(end+1) = makeEntry('G high, OPF', 'G_high', 'Irradiance', 'OPF', ...
    '20260910_GSM_HLT_FRA_POT_OPF_R02_PARAMS.xlsx', '20260910_GSM_HLT_DC_R02.xlsx');
S(end+1) = makeEntry('G low, OPF',  'G_low',  'Irradiance', 'OPF', ...
    '20260910_GSM_HLT_FRA_POT_OPF_R03_PARAMS.xlsx', '20260910_GSM_HLT_DC_R03.xlsx');

S(end+1) = makeEntry('G mid, OPB',  'G_mid',  'Irradiance', 'OPB', ...
    '20260910_GSM_HLT_FRA_POT_OPB_R01_PARAMS.xlsx', '20260910_GSM_HLT_DC_R01.xlsx');
S(end+1) = makeEntry('G high, OPB', 'G_high', 'Irradiance', 'OPB', ...
    '20260910_GSM_HLT_FRA_POT_OPB_R02_PARAMS.xlsx', '20260910_GSM_HLT_DC_R02.xlsx');
S(end+1) = makeEntry('G low, OPB',  'G_low',  'Irradiance', 'OPB', ...
    '20260910_GSM_HLT_FRA_POT_OPB_R03_PARAMS.xlsx', '20260910_GSM_HLT_DC_R03.xlsx');

% ---------- Targeted OPX follow-up (2026-09-14) ----------
S(end+1) = makeEntry('OPX70 follow-up R01', 'OPX_R01', 'OPX follow-up', 'OPX70', ...
    '20260914_GSM_HLT_FRA_POT_OPX70_R01_PARAMS.xlsx', '20260914_GSM_HLT_DC_R01.xlsx');
S(end+1) = makeEntry('OPX30 follow-up R02', 'OPX_R02', 'OPX follow-up', 'OPX30', ...
    '20260914_GSM_HLT_FRA_POT_OPX30_R02_PARAMS.xlsx', '20260914_GSM_HLT_DC_R02.xlsx');
S(end+1) = makeEntry('OPX70 follow-up R03', 'OPX_R03', 'OPX follow-up', 'OPX70', ...
    '20260914_GSM_HLT_FRA_POT_OPX70_R03_PARAMS.xlsx', '20260914_GSM_HLT_DC_R03.xlsx');

% ---------- Additional healthy OPX70 reference (2026-09-16) ----------
S(end+1) = makeEntry('Healthy OPX70 reference', 'HLT_20260916', 'OPX follow-up', 'OPX70', ...
    '20260916_GSM_HLT_FRA_POT_OPX70_R01_PARAMS.xlsx', '20260916_GSM_HLT_DC_R01.xlsx');

n = numel(S);

%% ----------------------------- READ THE DATA -----------------------------
for k = 1:n
    paramsPath = findFileRecursive(rootDir, S(k).paramFile);
    dcPath     = findFileRecursive(rootDir, S(k).dcFile);

    params = readParamsFile(paramsPath);
    dc     = readDCFile(dcPath);

    [Vmp, Imp, Voc, Isc] = extractDCMetrics(dc.V, dc.I);
    Vbias = operatingBiasFromLabel(S(k).biasFamily, Vmp, Voc);
    Rdiff = localDifferentialResistance(dc.V, dc.I, Vbias, LOCAL_FIT_WINDOW);

    S(k).paramsPath = paramsPath;
    S(k).dcPath     = dcPath;
    S(k).Rp         = params.Rp;
    S(k).Rs         = params.Rs;
    S(k).Y0         = params.Y0;
    S(k).nCPE       = params.nCPE;
    S(k).Vmp        = Vmp;
    S(k).Imp        = Imp;
    S(k).Voc        = Voc;
    S(k).Isc        = Isc;
    S(k).Vbias      = Vbias;
    S(k).Rdiff      = Rdiff;
end

%% ----------------------- EMPIRICAL HEALTHY RELATION ---------------------
Rp    = [S.Rp]';
Rdiff = [S.Rdiff]';

x = log(Rdiff);
y = log(Rp);

coeff = polyfit(x, y, 1);              % y = m*x + b
m = coeff(1);
b = coeff(2);

yhat = polyval(coeff, x);
R2_in = 1 - sum((y - yhat).^2) / sum((y - mean(y)).^2);

Rp_pred_in = exp(yhat);

%% --------------- LEAVE-ONE-ENVIRONMENT-OUT VALIDATION -------------------
stateIDs = string({S.stateID})';
uniqueStates = unique(stateIDs, 'stable');

absResidualPct = [];
cvRows = {};

for i = 1:numel(uniqueStates)
    heldState = uniqueStates(i);
    idxTest  = stateIDs == heldState;
    idxTrain = ~idxTest;

    c = polyfit(log(Rdiff(idxTrain)), log(Rp(idxTrain)), 1);
    pred = exp(polyval(c, log(Rdiff(idxTest))));
    errPct = 100 * (pred - Rp(idxTest)) ./ Rp(idxTest);

    absResidualPct = [absResidualPct; abs(errPct)]; %#ok<AGROW>

    testIndices = find(idxTest);
    for q = 1:numel(testIndices)
        j = testIndices(q);
        cvRows = [cvRows; {S(j).label, heldState, S(j).campaign, S(j).biasFamily, ...
            Rdiff(j), Rp(j), pred(q), errPct(q)}]; %#ok<AGROW>
    end
end

cvMedian = median(absResidualPct);
cvP90    = prctile(absResidualPct, 90);
cvRMS    = sqrt(mean(absResidualPct.^2));

%% ------------------------------- TABLES ---------------------------------
T = struct2table(S);
T = movevars(T, {'label','stateID','campaign','biasFamily','Rdiff','Rp','Rs','Y0','nCPE','Vbias','Vmp','Voc'}, 'Before', 1);

CVT = cell2table(cvRows, 'VariableNames', ...
    {'Label','HeldOutState','Campaign','BiasFamily','Rdiff','Rp_measured','Rp_predicted','ResidualPct'});

if EXPORT_CSV
    writetable(T, fullfile(OUT_DIR, 'Fig4_12_healthy_dataset.csv'));
    writetable(CVT, fullfile(OUT_DIR, 'Fig4_12_leave_one_state_out.csv'));
end

%% ------------------------------- PLOTTING -------------------------------
fig = figure('Color','w', 'Units','normalized', 'Position',[0.04 0.08 0.88 0.76]);
t = tiledlayout(1,2, 'TileSpacing','compact', 'Padding','compact');

% Styling dictionaries
campaignNames = {'Temperature','Irradiance','OPX follow-up'};
campaignColors = [0.00 0.45 0.74; 0.85 0.33 0.10; 0.47 0.67 0.19];

markerMap = containers.Map( ...
    {'OPF','OPB','OPX30','OPX70'}, ...
    {'o','s','d','^'} );

% ---------------- Panel (a) ----------------
ax1 = nexttile(t,1); hold(ax1,'on'); box(ax1,'on'); grid(ax1,'on');
title(ax1, '(a) Healthy-state relation between fitted R_p and local DC slope', ...
    'FontWeight','bold');
xlabel(ax1, 'Local differential resistance, R_{diff} = dV/dI (\Omega)');
ylabel(ax1, 'Fitted parallel resistance, R_p (\Omega)');
set(ax1, 'XScale','log', 'YScale','log');

% plot grouped points
legendHandles = gobjects(0);
legendLabels  = {};

for cIdx = 1:numel(campaignNames)
    campaign = campaignNames{cIdx};
    for bias = ["OPF","OPB","OPX30","OPX70"]
        idx = strcmp({S.campaign}, campaign) & strcmp({S.biasFamily}, bias);
        if ~any(idx), continue; end

        hh = plot(ax1, Rdiff(idx), Rp(idx), ...
            'LineStyle','none', ...
            'Marker', markerMap(char(bias)), ...
            'MarkerSize', 7.5, ...
            'LineWidth', 1.2, ...
            'Color', campaignColors(cIdx,:), ...
            'MarkerFaceColor', campaignColors(cIdx,:));
        legendHandles(end+1) = hh; %#ok<AGROW>
        legendLabels{end+1} = sprintf('%s, %s', campaign, char(bias)); %#ok<AGROW>
    end
end

% best-fit line
xfit = logspace(log10(min(Rdiff)*0.9), log10(max(Rdiff)*1.1), 300);
yfit = exp(b + m*log(xfit));
hFit = plot(ax1, xfit, yfit, 'k--', 'LineWidth', 1.6);

% Include the empirical healthy relation in the legend.
legendHandles(end+1) = hFit;
legendLabels{end+1} = 'Healthy log--log fit';
legend(ax1, legendHandles, legendLabels, 'Location','northwest', 'FontSize',9);

% optional labels
if SHOW_LABELS
    for k = 1:n
        text(ax1, Rdiff(k)*1.02, Rp(k)*1.02, S(k).label, 'FontSize',7);
    end
end

% fit annotation
eqText = sprintf(['Healthy fit (N = %d spectra)\n' ...
    'ln(R_p) = %.3f %+0.3f ln(R_{diff})\n' ...
    'R^2_{in-sample} = %.3f\n\n' ...
    'LOEO validation:\n' ...
    'median |residual| = %.1f%%\n' ...
    '90th percentile = %.1f%%\n' ...
    'RMS |residual| = %.1f%%'], ...
    n, b, m, R2_in, cvMedian, cvP90, cvRMS);
text(ax1, 0.05, 0.05, eqText, 'Units','normalized', ...
    'FontSize',10, 'VerticalAlignment','bottom', ...
    'BackgroundColor',[1 1 1], 'Margin',8);

% ---------------- Panel (b) ----------------
ax2 = nexttile(t,2); hold(ax2,'on'); box(ax2,'on'); grid(ax2,'on');
title(ax2, '(b) Leave-one-environment-out residuals', 'FontWeight','bold');
xlabel(ax2, 'Held-out healthy spectra (sorted by |residual|)');
ylabel(ax2, 'Absolute prediction residual, |e| (%)');

absErr = abs(CVT.ResidualPct);
[absErrSorted, idxSort] = sort(absErr, 'ascend');
scatter(ax2, 1:numel(absErrSorted), absErrSorted, 42, 'filled');
plot(ax2, 1:numel(absErrSorted), absErrSorted, '-', 'LineWidth', 1.0);

yline(ax2, cvMedian, '--', 'Median', 'LineWidth',1.2, 'LabelVerticalAlignment','bottom');
yline(ax2, cvP90, ':', '90th percentile', 'LineWidth',1.2, 'LabelVerticalAlignment','bottom');

stateGroupNames = string(CVT.HeldOutState(idxSort));
xticks(ax2, 1:numel(absErrSorted));
xticklabels(ax2, repmat("", size(absErrSorted))); % avoid clutter
ylim(ax2, [0 max(15, ceil(max(absErrSorted))+1)]);

resText = sprintf(['Grouped by environmental state:\n' ...
    '%d unique states, %d spectra\n\n' ...
    'median |e| = %.1f%%\n' ...
    '90th percentile = %.1f%%\n' ...
    'RMS |e| = %.1f%%'], ...
    numel(uniqueStates), n, cvMedian, cvP90, cvRMS);
text(ax2, 0.03, 0.95, resText, 'Units','normalized', ...
    'FontSize',10, 'VerticalAlignment','top', ...
    'BackgroundColor',[1 1 1], 'Margin',8);

sgtitle(t, 'Figure 4.12: Healthy-state electrical-slope dependence of fitted impedance', ...
    'FontWeight','bold', 'FontSize',15);

%% ------------------------------- EXPORT ---------------------------------
if SAVE_FIG
    exportgraphics(fig, fullfile(OUT_DIR, [FIG_NAME '.png']), 'Resolution', 300);
    exportgraphics(fig, fullfile(OUT_DIR, [FIG_NAME '.pdf']), 'ContentType', 'vector');
end

%% ------------------------------ CONSOLE ---------------------------------
fprintf('\nFigure 4.12 healthy-state synthesis complete.\n');
fprintf('------------------------------------------------------------\n');
fprintf('Healthy spectra used            : %d\n', n);
fprintf('Unique environmental states     : %d\n', numel(uniqueStates));
fprintf('Fit: ln(Rp) = %.6f %+0.6f ln(Rdiff)\n', b, m);
fprintf('In-sample R^2                   : %.6f\n', R2_in);
fprintf('LOEO median |residual| (%%)      : %.3f\n', cvMedian);
fprintf('LOEO 90th percentile (%%)        : %.3f\n', cvP90);
fprintf('LOEO RMS |residual| (%%)         : %.3f\n', cvRMS);
fprintf('Output folder                   : %s\n', OUT_DIR);
fprintf('------------------------------------------------------------\n\n');

%% ============================ LOCAL FUNCTIONS ============================
function s = makeEntry(label, stateID, campaign, biasFamily, paramFile, dcFile)
s = struct();
s.label      = label;
s.stateID    = stateID;
s.campaign   = campaign;
s.biasFamily = biasFamily;
s.paramFile  = paramFile;
s.dcFile     = dcFile;
end

function rootDir = prepareRawDataRoot(rawSource)
% Accept either:
%   1) a zip archive containing "Raw Data/..."
%   2) an already-unzipped "Raw Data" folder
if isfolder(rawSource)
    rootDir = rawSource;
    return;
end

if isfile(rawSource)
    [~,name,ext] = fileparts(rawSource);
    if strcmpi(ext,'.zip')
        cacheRoot = fullfile(tempdir, 'chatgpt_raw_data_cache');
        if ~exist(cacheRoot,'dir')
            mkdir(cacheRoot);
        end
        unzipRoot = fullfile(cacheRoot, name);
        rawFolder = fullfile(unzipRoot, 'Raw Data');
        if ~exist(rawFolder,'dir')
            fprintf('Unzipping raw data archive to: %s\n', unzipRoot);
            unzip(rawSource, unzipRoot);
        end
        rootDir = rawFolder;
        return;
    end
end

error('RAW_SOURCE must be either the unzipped "Raw Data" folder or the "Raw Data.zip" archive.');
end

function filePath = findFileRecursive(rootDir, fileName)
matches = dir(fullfile(rootDir, '**', fileName));
if isempty(matches)
    error('Could not find file: %s', fileName);
end
% Prefer the first match that is not inside "__MACOSX"
keep = ~contains(string(fullfile({matches.folder}, {matches.name})), '__MACOSX');
matches = matches(keep);
if isempty(matches)
    error('Only __MACOSX copies were found for: %s', fileName);
end
filePath = fullfile(matches(1).folder, matches(1).name);
end

function params = readParamsFile(filePath)
raw = readcell(filePath);
headers = string(raw(1,:));
values  = raw(2,:);

params = struct();
params.Y0  = forceNumeric(values{headers == "CPE.Y0 (F)"});
params.Rp  = forceNumeric(values{headers == "Rp.R (Ω)"});
params.Rs  = forceNumeric(values{headers == "Rs.R (Ω)"});
params.nCPE = forceNumeric(values{headers == "CPE.N"});
end

function dc = readDCFile(filePath)
raw = readcell(filePath);
headers = string(raw(1,:));

vCol = find(headers == "Corrected Potential (V)", 1);
iCol = find(headers == "Corrected Current (A)", 1);

if isempty(vCol) || isempty(iCol)
    error('Could not find corrected V/I columns in %s', filePath);
end

V = nan(size(raw,1)-1,1);
I = nan(size(raw,1)-1,1);

for r = 2:size(raw,1)
    V(r-1) = forceNumeric(raw{r,vCol});
    I(r-1) = forceNumeric(raw{r,iCol});
end

good = isfinite(V) & isfinite(I);
V = V(good);
I = I(good);

% Sort ascending in voltage
[V, idx] = sort(V);
I = I(idx);

dc = struct('V', V, 'I', I);
end

function [Vmp, Imp, Voc, Isc] = extractDCMetrics(V, I)
P = V .* I;
[~, idxMax] = max(P);
Vmp = V(idxMax);
Imp = I(idxMax);

Voc = V(end);
for k = 1:numel(I)-1
    if I(k) >= 0 && I(k+1) <= 0
        Voc = interp1(I(k:k+1), V(k:k+1), 0, 'linear', 'extrap');
        break;
    end
end

Isc = I(1);
for k = 1:numel(V)-1
    if V(k) <= 0 && V(k+1) >= 0
        Isc = interp1(V(k:k+1), I(k:k+1), 0, 'linear', 'extrap');
        break;
    end
end
end

function Vbias = operatingBiasFromLabel(biasFamily, Vmp, Voc)
switch upper(string(biasFamily))
    case "OPF"
        Vbias = 20.0;
    case "OPB"
        Vbias = 0.9 * Voc;
    case "OPX30"
        Vbias = Vmp + 0.30*(Voc - Vmp);
    case "OPX70"
        Vbias = Vmp + 0.70*(Voc - Vmp);
    otherwise
        error('Unknown bias family: %s', biasFamily);
end
end

function Rdiff = localDifferentialResistance(V, I, Vbias, windowN)
[~, idx0] = min(abs(V - Vbias));
halfWin = floor(windowN/2);

i1 = max(1, idx0 - halfWin);
i2 = min(numel(V), idx0 + halfWin);

% Try to maintain exact window length where possible
if (i2 - i1 + 1) < windowN
    if i1 == 1
        i2 = min(numel(V), windowN);
    elseif i2 == numel(V)
        i1 = max(1, numel(V) - windowN + 1);
    end
end

VV = V(i1:i2);
II = I(i1:i2);

p = polyfit(VV, II, 1);  % I(V) local slope
dIdV = p(1);
Rdiff = abs(1 / dIdV);
end

function x = forceNumeric(v)
if isnumeric(v)
    x = double(v);
elseif ismissing(v) || isempty(v)
    x = NaN;
elseif ischar(v) || isstring(v)
    x = str2double(string(v));
else
    try
        x = double(v);
    catch
        x = NaN;
    end
end
end
