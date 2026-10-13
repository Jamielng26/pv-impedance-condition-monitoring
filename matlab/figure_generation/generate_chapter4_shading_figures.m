%% generate_chapter4_shading_figures.m
% =========================================================================
% CLEAN-SLATE CHAPTER 4 SHADING / MISMATCH FIGURE PIPELINE
%
% Generates:
%   Fig4_13_PS50_location_response
%   Fig4_14_single_cell_severity
%   Fig4_15_two_cell_mismatch
%   Fig4_16_progressive_mismatch
%   Fig4_17_boundary_bypass_test
%
% This script is self-contained. No helper .m files are required.
%
% FOLDER SETUP
% ------------
% Put this script in a clean folder together with:
%
%   Raw Data.zip
%
% The script:
%   1) locates Raw Data.zip relative to THIS SCRIPT,
%   2) extracts it to a local cache,
%   3) validates the exact Day 13--18 filenames,
%   4) generates Figures 4.13--4.17,
%   5) exports PNG, PDF and FIG files,
%   6) exports compact CSV tables containing the plotted metrics.
%
% IMPORTANT INTERPRETIVE CHOICES
% -------------------------------
% - All FRA comparisons use the positive-capacitive region from 1 Hz--2 kHz.
% - Day 15 is treated as TWO severity sequences, each normalised to its own
%   healthy reference. This avoids falsely treating R01 and R02 as stationary
%   repeats when their healthy spectra are materially different.
% - The extra PS75 R01_2 run is used in the Day-15 K-K validity panel only.
% - PS100 is shown but is not treated as a clean monotonic calibration point.
% - Day 17 Delta-BIC values are the verified one-vs-two-relaxation model
%   comparison values obtained from the same raw spectra over 1 Hz--2 kHz.
% - Day 18 labels the pair geometry as SUSPECTED same/cross substring;
%   the figure does not claim verified internal substring topology.
%
% No AC perturbation amplitude is written into the figures; resolve the
% report's current 20 mV / 50 mV documentation discrepancy separately.
% =========================================================================

clear; close all; clc;

%% =========================== USER SETTINGS ===============================

EXPORT_DPI = 300;
FREQ_MIN   = 1;        % Hz
FREQ_MAX   = 2000;     % Hz

FORCE_REEXTRACT = false;

% If the zip has a slightly different name (e.g. Raw Data(1).zip), the script
% will automatically accept the first "Raw Data*.zip" found beside itself.

%% =========================== SCRIPT PATHS ================================

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;
end

zipPath = findRawDataZip(scriptDir);
repoRoot = fileparts(fileparts(scriptDir));
cacheRoot = fullfile(repoRoot,'data','raw','_RawData_cache');
outDir = fullfile(repoRoot,'figures','generated');

if FORCE_REEXTRACT && isfolder(cacheRoot)
    rmdir(cacheRoot,'s');
end

if ~isfolder(fullfile(cacheRoot,'Raw Data'))
    fprintf('Extracting:\n  %s\ninto:\n  %s\n\n',zipPath,cacheRoot);
    if isfolder(cacheRoot)
        rmdir(cacheRoot,'s');
    end
    mkdir(cacheRoot);
    unzip(zipPath,cacheRoot);
end

rawRoot = fullfile(cacheRoot,'Raw Data');

if ~isfolder(rawRoot)
    error('Expected extracted folder not found: %s',rawRoot);
end

if ~isfolder(outDir)
    mkdir(outDir);
end

%% =========================== PLOT DEFAULTS ===============================

set(groot,'defaultAxesFontName','Helvetica');
set(groot,'defaultAxesFontSize',11);
set(groot,'defaultAxesLineWidth',0.8);
set(groot,'defaultLineLineWidth',1.7);
set(groot,'defaultLegendFontSize',9);
set(groot,'defaultTextInterpreter','tex');
set(groot,'defaultLegendInterpreter','tex');

%% =========================== EXACT FILE AUDIT ============================

fprintf('============================================================\n');
fprintf('CHAPTER 4 SHADING DATA AUDIT\n');
fprintf('============================================================\n');
fprintf('Raw-data root:\n%s\n\n',rawRoot);

required = buildRequiredFileList();
missing = {};

for k = 1:numel(required)
    p = locateExact(rawRoot,required{k},false);
    if isempty(p)
        missing{end+1} = required{k}; %#ok<AGROW>
    end
end

if ~isempty(missing)
    fprintf(2,'Missing %d expected files:\n',numel(missing));
    for k = 1:numel(missing)
        fprintf(2,'  %s\n',missing{k});
    end
    error(['The uploaded archive does not match the validated Day 13--18 map.\n' ...
           'No figures were generated.']);
end

fprintf('Validated %d required Day 13--18 files.\n\n',numel(required));

%% ========================================================================
% FIGURE 4.13
% CONTROLLED PS50 RESPONSE: FAULT PRESENCE VS SPATIAL LOCATION
% ========================================================================

fprintf('Generating Figure 4.13...\n');

% ---------------- Day 13: equivalent PS50 faults on different cells -------
D13_H = makeState(rawRoot, ...
    {'20260922_GSM_HLT_FRA_POT_OPX70_R01.xlsx', ...
     '20260922_GSM_HLT_FRA_POT_OPX70_R02.xlsx', ...
     '20260922_GSM_HLT_FRA_POT_OPX70_R03.xlsx'}, ...
    {'20260922_GSM_HLT_DC_R01.xlsx', ...
     '20260922_GSM_HLT_DC_R02.xlsx', ...
     '20260922_GSM_HLT_DC_R03.xlsx'},FREQ_MIN,FREQ_MAX);

D13_41 = makeState(rawRoot, ...
    {'20260922_GSM_PS50_41_FRA_POT_OPX70_R01.xlsx', ...
     '20260922_GSM_PS50_41_FRA_POT_OPX70_R02.xlsx'}, ...
    {'20260922_GSM_PS50_41_DC_R01.xlsx', ...
     '20260922_GSM_PS50_41_DC_R02.xlsx'},FREQ_MIN,FREQ_MAX);

D13_42 = makeState(rawRoot, ...
    {'20260922_GSM_PS50_42_FRA_POT_OPX70_R01.xlsx', ...
     '20260922_GSM_PS50_42_FRA_POT_OPX70_R02.xlsx'}, ...
    {'20260922_GSM_PS50_42_DC_R01.xlsx', ...
     '20260922_GSM_PS50_42_DC_R02.xlsx'},FREQ_MIN,FREQ_MAX);

D13_52 = makeState(rawRoot, ...
    {'20260922_GSM_PS50_52_FRA_POT_OPX70_R01.xlsx', ...
     '20260922_GSM_PS50_52_FRA_POT_OPX70_R02.xlsx'}, ...
    {'20260922_GSM_PS50_52_DC_R01.xlsx', ...
     '20260922_GSM_PS50_52_DC_R02.xlsx'},FREQ_MIN,FREQ_MAX);

% ---------------- Day 14: TOP / MID / BOT within cell (5,2) ---------------
D14_H = makeState(rawRoot, ...
    {'20260923_GSM_HLT_FRA_POT_OPX70_R01.xlsx', ...
     '20260923_GSM_HLT_FRA_POT_OPX70_R02.xlsx'}, ...
    {'20260923_GSM_HLT_DC_R01.xlsx', ...
     '20260923_GSM_HLT_DC_R02.xlsx'},FREQ_MIN,FREQ_MAX);

D14_T = makeState(rawRoot, ...
    {'20260923_GSM_PS50_52_TOP50_FRA_POT_OPX70_R01.xlsx', ...
     '20260923_GSM_PS50_52_TOP50_FRA_POT_OPX70_R02.xlsx'}, ...
    {'20260923_GSM_PS50_52_TOP50_DC_R01.xlsx', ...
     '20260923_GSM_PS50_52_TOP50_DC_R02.xlsx'},FREQ_MIN,FREQ_MAX);

D14_M = makeState(rawRoot, ...
    {'20260923_GSM_PS50_52_MID50_FRA_POT_OPX70_R01.xlsx', ...
     '20260923_GSM_PS50_52_MID50_FRA_POT_OPX70_R02.xlsx'}, ...
    {'20260923_GSM_PS50_52_MID50_DC_R01.xlsx', ...
     '20260923_GSM_PS50_52_MID50_DC_R02.xlsx'},FREQ_MIN,FREQ_MAX);

D14_B = makeState(rawRoot, ...
    {'20260923_GSM_PS50_52_BOT50_FRA_POT_OPX70_R01.xlsx', ...
     '20260923_GSM_PS50_52_BOT50_FRA_POT_OPX70_R02.xlsx'}, ...
    {'20260923_GSM_PS50_52_BOT50_DC_R01.xlsx', ...
     '20260923_GSM_PS50_52_BOT50_DC_R02.xlsx'},FREQ_MIN,FREQ_MAX);

names413 = {'Cell (4,1)','Cell (4,2)','Cell (5,2)', ...
            'TOP, cell (5,2)','MID, cell (5,2)','BOT, cell (5,2)'};

fault413 = {D13_41,D13_42,D13_52,D14_T,D14_M,D14_B};
refs413  = {D13_H,D13_H,D13_H,D14_H,D14_H,D14_H};

dRp413   = nan(6,1);
dZ413    = nan(6,1);
dP413    = nan(6,1);

for k = 1:6
    dRp413(k) = pctChange(refs413{k}.RpMean,fault413{k}.RpMean);
    dZ413(k)  = pctChange(refs413{k}.ZmaxMean,fault413{k}.ZmaxMean);
    dP413(k)  = pctChange(refs413{k}.PmpMean,fault413{k}.PmpMean);
end

faultVsHealthy = [ ...
    spectrumDifference(D13_H,D13_41,FREQ_MIN,FREQ_MAX), ...
    spectrumDifference(D13_H,D13_42,FREQ_MIN,FREQ_MAX), ...
    spectrumDifference(D13_H,D13_52,FREQ_MIN,FREQ_MAX)];

betweenCells = [ ...
    spectrumDifference(D13_41,D13_42,FREQ_MIN,FREQ_MAX), ...
    spectrumDifference(D13_41,D13_52,FREQ_MIN,FREQ_MAX), ...
    spectrumDifference(D13_42,D13_52,FREQ_MIN,FREQ_MAX)];

placementVsHealthy = [ ...
    spectrumDifference(D14_H,D14_T,FREQ_MIN,FREQ_MAX), ...
    spectrumDifference(D14_H,D14_M,FREQ_MIN,FREQ_MAX), ...
    spectrumDifference(D14_H,D14_B,FREQ_MIN,FREQ_MAX)];

topBotDz = spectrumDifference(D14_T,D14_B,FREQ_MIN,FREQ_MAX);

fig = figure('Color','w','Position',[60 40 1240 790]);
tl = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
co = lines(6);

ax1 = nexttile(tl,1); hold(ax1,'on'); grid(ax1,'on'); box(ax1,'on');
hH = plotState(ax1,D13_H,[0.18 0.18 0.18],'-','o',true);
h1 = plotState(ax1,D13_41,co(1,:),'-','o',true);
h2 = plotState(ax1,D13_42,co(2,:),'-','s',true);
h3 = plotState(ax1,D13_52,co(3,:),'-','^',true);
xlabel(ax1,'Real impedance, Z'' (\Omega)');
ylabel(ax1,'Imaginary impedance, -Z'''' (\Omega)');
title(ax1,'(a) Equivalent PS50 faults on different cells');
legend(ax1,[hH h1 h2 h3], ...
    {'Healthy','PS50 cell (4,1)','PS50 cell (4,2)','PS50 cell (5,2)'}, ...
    'Location','best');
axis(ax1,'tight');
text(ax1,0.04,0.05, ...
    sprintf('Mean D_Z: healthy \\leftrightarrow PS50 = %.1f%%\nMean D_Z: between PS50 cells = %.1f%%', ...
    mean(faultVsHealthy),mean(betweenCells)), ...
    'Units','normalized','VerticalAlignment','bottom', ...
    'BackgroundColor','w','EdgeColor',[0.82 0.82 0.82],'Margin',4,'FontSize',8.7);

ax2 = nexttile(tl,2); hold(ax2,'on'); grid(ax2,'on'); box(ax2,'on');
hH = plotState(ax2,D14_H,[0.18 0.18 0.18],'-','o',true);
hT = plotState(ax2,D14_T,co(4,:),'-','o',true);
hM = plotState(ax2,D14_M,co(5,:),'-','s',true);
hB = plotState(ax2,D14_B,co(6,:),'-','^',true);
xlabel(ax2,'Real impedance, Z'' (\Omega)');
ylabel(ax2,'Imaginary impedance, -Z'''' (\Omega)');
title(ax2,'(b) PS50 position within cell (5,2)');
legend(ax2,[hH hT hM hB],{'Healthy','TOP','MID','BOT'},'Location','best');
axis(ax2,'tight');
text(ax2,0.04,0.05, ...
    sprintf('Mean D_Z: healthy \\leftrightarrow placement = %.1f%%\nD_Z: TOP \\leftrightarrow BOT = %.1f%%', ...
    mean(placementVsHealthy),topBotDz), ...
    'Units','normalized','VerticalAlignment','bottom', ...
    'BackgroundColor','w','EdgeColor',[0.82 0.82 0.82],'Margin',4,'FontSize',8.7);

ax3 = nexttile(tl,3,[1 2]); hold(ax3,'on'); grid(ax3,'on'); box(ax3,'on');
y = [1 2 3 5 6 7];

for k = 1:6
    xmin = min([dRp413(k),dZ413(k),dP413(k)]);
    xmax = max([dRp413(k),dZ413(k),dP413(k)]);
    plot(ax3,[xmin xmax],[y(k) y(k)],'-','Color',[0.82 0.82 0.82], ...
        'LineWidth',1,'HandleVisibility','off');
end

hRp = plot(ax3,dRp413,y,'o','LineStyle','none','MarkerSize',8,'LineWidth',1.6);
hZm = plot(ax3,dZ413,y,'s','LineStyle','none','MarkerSize',8,'LineWidth',1.6);
hPm = plot(ax3,dP413,y,'^','LineStyle','none','MarkerSize',8,'LineWidth',1.6);

xline(ax3,0,'k-','HandleVisibility','off');
yline(ax3,4,':','HandleVisibility','off');
yticks(ax3,y);
yticklabels(ax3,names413);
ylim(ax3,[0.5 7.5]);
set(ax3,'YDir','reverse');
xlabel(ax3,'Change from paired healthy reference (%)');
title(ax3,'(c) Fault presence is the primary effect; spatial position modifies its magnitude');
legend(ax3,[hRp hZm hPm],{'Fitted R_p','Measured -Z''''_{max}','P_{mp}'}, ...
    'Location','southeast');

all413 = [dRp413;dZ413;dP413];
xlim(ax3,[floor(min(all413)/5)*5-5,5]);

exportFigure(fig,outDir,'Fig4_13_PS50_location_response',EXPORT_DPI);

T413 = table(string(names413(:)),dRp413,dZ413,dP413, ...
    'VariableNames',{'Condition','Delta_Rp_pct','Delta_Zmax_pct','Delta_Pmp_pct'});
writetable(T413,fullfile(outDir,'Fig4_13_metrics.csv'));

%% ========================================================================
% FIGURE 4.14
% SINGLE-CELL SHADING SEVERITY: DC CLEAR, EIS NOT SIMPLY MONOTONIC
% ========================================================================

fprintf('Generating Figure 4.14...\n');

sev = [0 25 50 75 100];

% Two primary experimental sequences are treated separately.
fraSeq1 = { ...
    '20260928_GSM_HLT_FRA_POT_OPX70_R01.xlsx', ...
    '20260928_GSM_PS25_FRA_POT_OPX70_R01.xlsx', ...
    '20260928_GSM_PS50_FRA_POT_OPX70_R01.xlsx', ...
    '20260928_GSM_PS75_FRA_POT_OPX70_R01.xlsx', ...
    '20260928_GSM_PS100_FRA_POT_OPX70_R01.xlsx'};

fraSeq2 = { ...
    '20260928_GSM_HLT_FRA_POT_OPX70_R02.xlsx', ...
    '20260928_GSM_PS25_FRA_POT_OPX70_R02.xlsx', ...
    '20260928_GSM_PS50_FRA_POT_OPX70_R02.xlsx', ...
    '20260928_GSM_PS75_FRA_POT_OPX70_R02.xlsx', ...
    '20260928_GSM_PS100_FRA_POT_OPX70_R02.xlsx'};

dcSeq1 = { ...
    '20260928_GSM_HLT_DC_R01.xlsx', ...
    '20260928_GSM_PS25_DC_R01.xlsx', ...
    '20260928_GSM_PS50_DC_R01.xlsx', ...
    '20260928_GSM_PS75_DC_R01.xlsx', ...
    '20260928_GSM_PS100_DC_R01.xlsx'};

dcSeq2 = { ...
    '20260928_GSM_HLT_DC_R02.xlsx', ...
    '20260928_GSM_PS25_DC_R02.xlsx', ...
    '20260928_GSM_PS50_DC_R02.xlsx', ...
    '20260928_GSM_PS75_DC_R02.xlsx', ...
    '20260928_GSM_PS100_DC_R02.xlsx'};

S1 = cell(5,1);
S2 = cell(5,1);

for k = 1:5
    S1{k} = makeSingleState(rawRoot,fraSeq1{k},dcSeq1{k},FREQ_MIN,FREQ_MAX);
    S2{k} = makeSingleState(rawRoot,fraSeq2{k},dcSeq2{k},FREQ_MIN,FREQ_MAX);
end

% Normalise each sequence to ITS OWN healthy state.
I1 = cellfun(@(s)s.IscMean,S1);  P1 = cellfun(@(s)s.PmpMean,S1);
R1 = cellfun(@(s)s.RpMean,S1);   Z1 = cellfun(@(s)s.ZmaxMean,S1);
K1 = cellfun(@(s)s.KKMean,S1);

I2 = cellfun(@(s)s.IscMean,S2);  P2 = cellfun(@(s)s.PmpMean,S2);
R2 = cellfun(@(s)s.RpMean,S2);   Z2 = cellfun(@(s)s.ZmaxMean,S2);
K2 = cellfun(@(s)s.KKMean,S2);

I1n = 100*I1/I1(1); P1n = 100*P1/P1(1);
R1n = 100*R1/R1(1); Z1n = 100*Z1/Z1(1);

I2n = 100*I2/I2(1); P2n = 100*P2/P2(1);
R2n = 100*R2/R2(1); Z2n = 100*Z2/Z2(1);

% Additional PS75 retest is a validity point, not a third severity sequence.
extra75 = makeSingleState(rawRoot, ...
    '20260928_GSM_PS75_FRA_POT_OPX70_R01_2.xlsx','',FREQ_MIN,FREQ_MAX);

fig = figure('Color','w','Position',[55 45 1210 760]);
tl = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
co = lines(4);

ax1 = nexttile(tl,1); hold(ax1,'on'); grid(ax1,'on'); box(ax1,'on');

% Sequence 1 solid, sequence 2 dashed.
plot(ax1,sev,I1n,'-o','Color',co(1,:),'MarkerFaceColor','w','LineWidth',1.8);
plot(ax1,sev,P1n,'-s','Color',co(2,:),'MarkerFaceColor','w','LineWidth',1.8);
plot(ax1,sev,I2n,'--o','Color',co(1,:),'MarkerFaceColor','w','LineWidth',1.4);
plot(ax1,sev,P2n,'--s','Color',co(2,:),'MarkerFaceColor','w','LineWidth',1.4);

xlabel(ax1,'Shaded area on one cell (%)');
ylabel(ax1,'Normalised DC quantity (% of sequence healthy state)');
title(ax1,'(a) DC current and power provide a clear severity ordering');
legend(ax1,{'I_{sc}, sequence 1','P_{mp}, sequence 1', ...
            'I_{sc}, sequence 2','P_{mp}, sequence 2'}, ...
            'Location','southwest');
ylim(ax1,[0 110]);

ax2 = nexttile(tl,2); hold(ax2,'on'); grid(ax2,'on'); box(ax2,'on');

plot(ax2,sev(1:4),R1n(1:4),'-o','Color',co(3,:),'MarkerFaceColor','w','LineWidth',1.8);
plot(ax2,sev(1:4),Z1n(1:4),'-s','Color',co(4,:),'MarkerFaceColor','w','LineWidth',1.8);
plot(ax2,sev(1:4),R2n(1:4),'--o','Color',co(3,:),'MarkerFaceColor','w','LineWidth',1.4);
plot(ax2,sev(1:4),Z2n(1:4),'--s','Color',co(4,:),'MarkerFaceColor','w','LineWidth',1.4);

% PS100 shown explicitly as open, disconnected points.
plot(ax2,100,R1n(5),'o','Color',co(3,:),'MarkerFaceColor','none','MarkerSize',9,'LineWidth',1.8);
plot(ax2,100,Z1n(5),'s','Color',co(4,:),'MarkerFaceColor','none','MarkerSize',9,'LineWidth',1.8);
plot(ax2,100,R2n(5),'o','Color',co(3,:),'MarkerFaceColor','none','MarkerSize',9,'LineWidth',1.8);
plot(ax2,100,Z2n(5),'s','Color',co(4,:),'MarkerFaceColor','none','MarkerSize',9,'LineWidth',1.8);

xlabel(ax2,'Shaded area on one cell (%)');
ylabel(ax2,'Normalised EIS feature (% of sequence healthy state)');
title(ax2,'(b) No single EIS feature remains monotonic over the full range');
legend(ax2,{'R_p, sequence 1','-Z''''_{max}, sequence 1', ...
            'R_p, sequence 2','-Z''''_{max}, sequence 2'}, ...
            'Location','best');

text(ax2,0.04,0.05, ...
    {'PS100 is shown as a regime / validity change,', ...
     'not as a monotonic calibration point.'}, ...
    'Units','normalized','VerticalAlignment','bottom', ...
    'BackgroundColor','w','EdgeColor',[0.82 0.82 0.82],'Margin',4,'FontSize',8.6);

ax3 = nexttile(tl,3,[1 2]); hold(ax3,'on'); grid(ax3,'on'); box(ax3,'on');

hK1 = plot(ax3,sev,K1,'-o','Color',[0.15 0.15 0.15], ...
    'MarkerFaceColor','w','LineWidth',1.6);
hK2 = plot(ax3,sev,K2,'--s','Color',[0.55 0.2 0.75], ...
    'MarkerFaceColor','w','LineWidth',1.6);
hKe = plot(ax3,75,extra75.KKMean,'d','Color',[0.85 0.33 0.10], ...
    'MarkerFaceColor','w','MarkerSize',8,'LineWidth',1.5);

yline(ax3,1,':','1% guide','HandleVisibility','off');
xlabel(ax3,'Shaded area on one cell (%)');
ylabel(ax3,'Mean |K--K residual| (%)');
title(ax3,'(c) Stronger shading increasingly challenges measurement consistency');
legend(ax3,[hK1 hK2 hKe], ...
    {'Sequence 1','Sequence 2','Additional PS75 retest'}, ...
    'Location','northwest');

text(ax3,100,max([K1(:);K2(:)])*0.88,'PS100', ...
    'HorizontalAlignment','right','FontWeight','bold');

exportFigure(fig,outDir,'Fig4_14_single_cell_severity',EXPORT_DPI);

T414 = table(sev(:),I1n(:),P1n(:),R1n(:),Z1n(:),K1(:), ...
                     I2n(:),P2n(:),R2n(:),Z2n(:),K2(:), ...
    'VariableNames',{'Shade_pct','Isc_seq1_pct','Pmp_seq1_pct','Rp_seq1_pct','Zmax_seq1_pct','KK_seq1_pct', ...
                                  'Isc_seq2_pct','Pmp_seq2_pct','Rp_seq2_pct','Zmax_seq2_pct','KK_seq2_pct'});
writetable(T414,fullfile(outDir,'Fig4_14_metrics.csv'));

%% ========================================================================
% FIGURE 4.15
% TWO-CELL MISMATCH: A FIXED AT 75%, B INCREASED
% ========================================================================

fprintf('Generating Figure 4.15...\n');

names415 = {'A75B0','A75B25','A75B50','A75B75','A75B100'};
shadeB = [0 25 50 75 100];

G415 = cell(5,1);

for k = 1:5
    G415{k} = makeSingleState(rawRoot, ...
        sprintf('20260929_GSM_%s_FRA_POT_OPX70_R01.xlsx',names415{k}), ...
        sprintf('20260929_GSM_%s_DC_R01.xlsx',names415{k}), ...
        FREQ_MIN,FREQ_MAX);
end

I415 = cellfun(@(s)s.IscMean,G415);
P415 = cellfun(@(s)s.PmpMean,G415);
R415 = cellfun(@(s)s.RpMean,G415);
Z415 = cellfun(@(s)s.ZmaxMean,G415);
Rs415 = cellfun(@(s)s.RsMean,G415);
n415 = cellfun(@(s)s.nMean,G415);
K415 = cellfun(@(s)s.KKMean,G415);

I415n = 100*I415/I415(1);
P415n = 100*P415/P415(1);
R415n = 100*R415/R415(1);
Z415n = 100*Z415/Z415(1);
Rs415n = 100*Rs415/Rs415(1);

fig = figure('Color','w','Position',[55 45 1210 760]);
tl = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
co = lines(5);

ax1 = nexttile(tl,1); hold(ax1,'on'); grid(ax1,'on'); box(ax1,'on');
plot(ax1,shadeB,I415n,'-o','Color',co(1,:),'MarkerFaceColor','w','LineWidth',1.8);
plot(ax1,shadeB,P415n,'-s','Color',co(2,:),'MarkerFaceColor','w','LineWidth',1.8);
xlabel(ax1,'Second-cell shaded area, B (%)  [A fixed at PS75]');
ylabel(ax1,'Normalised DC quantity (% of A75B0)');
title(ax1,'(a) A weaker second fault adds little to the DC response');
legend(ax1,{'I_{sc}','P_{mp}'},'Location','southwest');

ax2 = nexttile(tl,2); hold(ax2,'on'); grid(ax2,'on'); box(ax2,'on');
plot(ax2,shadeB,R415n,'-o','Color',co(3,:),'MarkerFaceColor','w','LineWidth',1.8);
plot(ax2,shadeB,Z415n,'-s','Color',co(4,:),'MarkerFaceColor','w','LineWidth',1.8);
plot(ax2,shadeB,Rs415n,'-^','Color',co(5,:),'MarkerFaceColor','w','LineWidth',1.8);
xlabel(ax2,'Second-cell shaded area, B (%)  [A fixed at PS75]');
ylabel(ax2,'Normalised EIS feature (% of A75B0)');
title(ax2,'(b) Incremental impedance change grows as B becomes restrictive');
legend(ax2,{'R_p','-Z''''_{max}','R_s'},'Location','best');

text(ax2,0.04,0.05, ...
    sprintf('B100: n = %.3f, mean |K--K| = %.2f%%',n415(end),K415(end)), ...
    'Units','normalized','BackgroundColor','w','EdgeColor',[0.82 0.82 0.82], ...
    'Margin',4,'FontSize',8.7);

ax3 = nexttile(tl,3,[1 2]); hold(ax3,'on'); grid(ax3,'on'); box(ax3,'on');
idx415 = [1 3 4 5];
lab415 = {'B0','B50','B75','B100'};
col415 = lines(numel(idx415));
h = gobjects(numel(idx415),1);

for j = 1:numel(idx415)
    h(j) = plotState(ax3,G415{idx415(j)},col415(j,:),'-','o',false);
end

xlabel(ax3,'Real impedance, Z'' (\Omega)');
ylabel(ax3,'Imaginary impedance, -Z'''' (\Omega)');
title(ax3,'(c) Selected spectra reveal the major B100 regime change');
legend(ax3,h,lab415,'Location','best');
axis(ax3,'tight');

exportFigure(fig,outDir,'Fig4_15_two_cell_mismatch',EXPORT_DPI);

T415 = table(shadeB(:),I415n(:),P415n(:),R415n(:),Z415n(:),Rs415n(:),n415(:),K415(:), ...
    'VariableNames',{'B_shade_pct','Isc_pct','Pmp_pct','Rp_pct','Zmax_pct','Rs_pct','CPE_n','KK_pct'});
writetable(T415,fullfile(outDir,'Fig4_15_metrics.csv'));

%% ========================================================================
% FIGURE 4.16
% PROGRESSIVE MULTI-CELL MISMATCH: DC SATURATION, EIS CONTINUES
% ========================================================================

fprintf('Generating Figure 4.16...\n');

lab416 = { ...
    'HLT', ...
    'PS75_31', ...
    'PS75_31_61', ...
    'PS75_31_61_91', ...
    'PS75_31_61_91_112', ...
    'PS75_31_61_91_112_82', ...
    'PS75_31_61_91_112_82_41', ...
    'PS75_31_61_91_112_82_41_71', ...
    'PS75_31_61_91_112_82_41_71_101', ...
    'PS75_31_61_91_112_82_41_71_101_102'};

N = 0:9;
G416 = cell(10,1);

for k = 1:10

    if k == 1
        fraName = '20261002_GSM_HLT_FRA_POT_OPX70_R01.xlsx';
        dcName  = '20261002_GSM_HLT_DC_R01.xlsx';
    else
        fraName = sprintf('20261002_GSM_%s_FRA_POT_OPX70_R01.xlsx',lab416{k});
        dcName  = sprintf('20261002_GSM_%s_DC_R01.xlsx',lab416{k});
    end

    G416{k} = makeSingleState(rawRoot,fraName,dcName,FREQ_MIN,FREQ_MAX);
end

I416 = cellfun(@(s)s.IscMean,G416);
P416 = cellfun(@(s)s.PmpMean,G416);
R416 = cellfun(@(s)s.RpMean,G416);
Z416 = cellfun(@(s)s.ZmaxMean,G416);

I416n = 100*I416/I416(1);
P416n = 100*P416/P416(1);

% EIS panel deliberately normalised to the 4-cell state.
R416_4 = 100*R416/R416(5);
Z416_4 = 100*Z416/Z416(5);

% Verified Day-17 one-vs-two-relaxation BIC comparison over 1 Hz--2 kHz:
% DeltaBIC = BIC_M3 - BIC_M2. Negative values favour the two-relaxation M3.
dBIC = [NaN, ...
         0.285, ...
        -7.045, ...
         0.053, ...
       -33.463, ...
       -55.810, ...
       -75.529, ...
       -33.460, ...
       -77.293, ...
       -44.535];

fig = figure('Color','w','Position',[45 35 1240 820]);
tl = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
co = lines(5);

ax1 = nexttile(tl,1); hold(ax1,'on'); grid(ax1,'on'); box(ax1,'on');
patch(ax1,[4 9 9 4],[0 0 110 110],[0.92 0.92 0.92], ...
    'EdgeColor','none','FaceAlpha',0.35,'HandleVisibility','off');
plot(ax1,N,I416n,'-o','Color',co(1,:),'MarkerFaceColor','w','LineWidth',1.8);
plot(ax1,N,P416n,'-s','Color',co(2,:),'MarkerFaceColor','w','LineWidth',1.8);
xlabel(ax1,'Number of PS75 cells');
ylabel(ax1,'Normalised DC quantity (% of healthy)');
title(ax1,'(a) Terminal DC response becomes comparatively insensitive');
legend(ax1,{'I_{sc}','P_{mp}'},'Location','southwest');
ylim(ax1,[0 110]);

dP4to9 = pctChange(P416(5),P416(10));
dI4to9 = pctChange(I416(5),I416(10));

text(ax1,0.61,0.88, ...
    sprintf('N = 4 \\rightarrow 9:\n\\DeltaP_{mp} = %.1f%%\n\\DeltaI_{sc} = %.1f%%', ...
    dP4to9,dI4to9), ...
    'Units','normalized','BackgroundColor','w','EdgeColor',[0.82 0.82 0.82], ...
    'Margin',4,'FontSize',8.7);

ax2 = nexttile(tl,2); hold(ax2,'on'); grid(ax2,'on'); box(ax2,'on');
yMax = max([R416_4(:);Z416_4(:)])*1.08;
patch(ax2,[4 9 9 4],[0 0 yMax yMax],[0.92 0.92 0.92], ...
    'EdgeColor','none','FaceAlpha',0.35,'HandleVisibility','off');
plot(ax2,N,R416_4,'-o','Color',co(3,:),'MarkerFaceColor','w','LineWidth',1.8);
plot(ax2,N,Z416_4,'-s','Color',co(4,:),'MarkerFaceColor','w','LineWidth',1.8);
xlabel(ax2,'Number of PS75 cells');
ylabel(ax2,'Normalised EIS feature (% of 4-cell state)');
title(ax2,'(b) Impedance continues evolving over the same region');
legend(ax2,{'R_p','-Z''''_{max}'},'Location','best');

dR4to9 = pctChange(R416(5),R416(10));
dZ4to9 = pctChange(Z416(5),Z416(10));

text(ax2,0.61,0.08, ...
    sprintf('N = 4 \\rightarrow 9:\n\\DeltaR_p = %+.1f%%\n\\Delta(-Z''''_{max}) = %+.1f%%', ...
    dR4to9,dZ4to9), ...
    'Units','normalized','BackgroundColor','w','EdgeColor',[0.82 0.82 0.82], ...
    'Margin',4,'FontSize',8.7);

ax3 = nexttile(tl,3); hold(ax3,'on'); grid(ax3,'on'); box(ax3,'on');

idx416 = [1 2 5 7 10];
labelsShow = {'Healthy','1 cell','4 cells','6 cells','9 cells'};
cols416 = parula(numel(idx416));
h = gobjects(numel(idx416),1);

for j = 1:numel(idx416)
    h(j) = plotState(ax3,G416{idx416(j)},cols416(j,:),'-','o',false);
end

xlabel(ax3,'Real impedance, Z'' (\Omega)');
ylabel(ax3,'Imaginary impedance, -Z'''' (\Omega)');
title(ax3,'(c) Representative Nyquist evolution');
legend(ax3,h,labelsShow,'Location','best');
axis(ax3,'tight');

ax4 = nexttile(tl,4); hold(ax4,'on'); grid(ax4,'on'); box(ax4,'on');
plot(ax4,N,dBIC,'-o','Color',[0.15 0.15 0.15], ...
    'MarkerFaceColor','w','LineWidth',1.8);
yline(ax4,0,'k-','HandleVisibility','off');
yline(ax4,-10,':','Strong preference guide','HandleVisibility','off');
xlabel(ax4,'Number of PS75 cells');
ylabel(ax4,'\DeltaBIC = BIC_{M3} - BIC_{M2}');
title(ax4,'(d) A sustained two-relaxation description emerges');
xlim(ax4,[0 9]);

text(ax4,4,-29,'sustained strong preference', ...
    'FontSize',8.5,'HorizontalAlignment','left');

exportFigure(fig,outDir,'Fig4_16_progressive_mismatch',EXPORT_DPI);

T416 = table(N(:),I416(:),P416(:),R416(:),Z416(:),I416n(:),P416n(:),R416_4(:),Z416_4(:),dBIC(:), ...
    'VariableNames',{'N_PS75_cells','Isc_A','Pmp_W','Rp_Ohm','Zmax_Ohm', ...
    'Isc_pctHealthy','Pmp_pctHealthy','Rp_pctOf4cell','Zmax_pctOf4cell','DeltaBIC'});
writetable(T416,fullfile(outDir,'Fig4_16_metrics.csv'));

%% ========================================================================
% FIGURE 4.17
% TESTING THE SUSPECTED SUBSTRING / BYPASS-DIODE INTERPRETATION
% ========================================================================

fprintf('Generating Figure 4.17...\n');

samePair = makeSingleState(rawRoot, ...
    '20261006_GSM_PS75_21_23_FRA_POT_OPX70_R01.xlsx', ...
    '20261006_GSM_PS75_21_23_DC_R01.xlsx',FREQ_MIN,FREQ_MAX);

crossPair = makeSingleState(rawRoot, ...
    '20261006_GSM_PS75_21_31_FRA_POT_OPX70_R01.xlsx', ...
    '20261006_GSM_PS75_21_31_DC_R01.xlsx',FREQ_MIN,FREQ_MAX);

HLT18 = makeSingleState(rawRoot, ...
    '20261006_GSM_HLT_FRA_POT_OPX70_R01.xlsx', ...
    '20261006_GSM_HLT_DC_R01.xlsx',FREQ_MIN,FREQ_MAX);

PS95_1 = makeSingleState(rawRoot, ...
    '20261006_GSM_PS95_21_FRA_POT_OPX70_R01.xlsx', ...
    '20261006_GSM_PS95_21_DC_R01.xlsx',FREQ_MIN,FREQ_MAX);

PS95_2 = makeSingleState(rawRoot, ...
    '20261006_GSM_PS95_21_41_FRA_POT_OPX70_R01.xlsx', ...
    '20261006_GSM_PS95_21_41_DC_R01.xlsx',FREQ_MIN,FREQ_MAX);

dRp17 = pctChange(samePair.RpMean,crossPair.RpMean);
dZ17  = pctChange(samePair.ZmaxMean,crossPair.ZmaxMean);
dP17  = pctChange(samePair.PmpMean,crossPair.PmpMean);
dz17  = spectrumDifference(samePair,crossPair,FREQ_MIN,FREQ_MAX);

fig = figure('Color','w','Position',[45 35 1240 810]);
tl = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
co = lines(4);

ax1 = nexttile(tl,1); hold(ax1,'on'); grid(ax1,'on'); box(ax1,'on');
h1 = plotState(ax1,samePair,co(1,:),'-','o',false);
h2 = plotState(ax1,crossPair,co(2,:),'-','s',false);
xlabel(ax1,'Real impedance, Z'' (\Omega)');
ylabel(ax1,'Imaginary impedance, -Z'''' (\Omega)');
title(ax1,'(a) Matched PS75 pair geometries remain closely similar');
legend(ax1,[h1 h2], ...
    {'Suspected same-substring: (2,1)+(2,3)', ...
     'Suspected cross-substring: (2,1)+(3,1)'}, ...
    'Location','best');
axis(ax1,'tight');

text(ax1,0.04,0.06,sprintf('Complex-spectrum D_Z = %.1f%%',dz17), ...
    'Units','normalized','BackgroundColor','w','EdgeColor',[0.82 0.82 0.82], ...
    'Margin',4,'FontSize',8.7);

ax2 = nexttile(tl,2); hold(ax2,'on'); grid(ax2,'on'); box(ax2,'on');
vals17 = [dRp17 dZ17 dP17];
bar(ax2,1:3,vals17);
xticks(ax2,1:3);
xticklabels(ax2,{'R_p','-Z''''_{max}','P_{mp}'});
ylabel(ax2,'Cross-pair change relative to same pair (%)');
title(ax2,'(b) No large boundary-specific feature emerges');
yline(ax2,0,'k-','HandleVisibility','off');

ax3 = nexttile(tl,3); hold(ax3,'on'); grid(ax3,'on'); box(ax3,'on');
plotPhysicalIV(ax3,HLT18,[0.15 0.15 0.15],1.9);
plotPhysicalIV(ax3,PS95_1,co(3,:),1.8);
plotPhysicalIV(ax3,PS95_2,co(4,:),1.8);
xlabel(ax3,'Voltage, V (V)');
ylabel(ax3,'Current, I (A)');
title(ax3,'(c) PS95 I--V response');
legend(ax3,{'Healthy','PS95 one cell','PS95 two cells'},'Location','best');

ax4 = nexttile(tl,4); hold(ax4,'on'); grid(ax4,'on'); box(ax4,'on');
plotPhysicalPV(ax4,HLT18,[0.15 0.15 0.15],1.9);
plotPhysicalPV(ax4,PS95_1,co(3,:),1.8);
plotPhysicalPV(ax4,PS95_2,co(4,:),1.8);
xlabel(ax4,'Voltage, V (V)');
ylabel(ax4,'Power, P (W)');
title(ax4,'(d) PS95 P--V response');
legend(ax4,{'Healthy','PS95 one cell','PS95 two cells'},'Location','best');

text(ax4,0.04,0.06, ...
    {'No unambiguous bypass-active DC branch', ...
     'or additional dominant power maximum resolved.'}, ...
    'Units','normalized','VerticalAlignment','bottom', ...
    'BackgroundColor','w','EdgeColor',[0.82 0.82 0.82], ...
    'Margin',4,'FontSize',8.6);

exportFigure(fig,outDir,'Fig4_17_boundary_bypass_test',EXPORT_DPI);

T417 = table(dRp17,dZ17,dP17,dz17, ...
    PS95_1.IscMean,PS95_1.PmpMean,PS95_2.IscMean,PS95_2.PmpMean, ...
    'VariableNames',{'CrossVsSame_Rp_pct','CrossVsSame_Zmax_pct','CrossVsSame_Pmp_pct','SameVsCross_Dz_pct', ...
    'PS95_1cell_Isc_A','PS95_1cell_Pmp_W','PS95_2cell_Isc_A','PS95_2cell_Pmp_W'});
writetable(T417,fullfile(outDir,'Fig4_17_metrics.csv'));

%% =========================== FINAL CONSOLE SUMMARY =======================

fprintf('\n============================================================\n');
fprintf('ALL SHADING FIGURES GENERATED SUCCESSFULLY\n');
fprintf('============================================================\n');
fprintf('Output folder:\n  %s\n\n',outDir);

fprintf('Headline Day-17 result, N=4 -> 9:\n');
fprintf('  Pmp:       %+.2f %%\n',dP4to9);
fprintf('  Isc:       %+.2f %%\n',dI4to9);
fprintf('  Rp:        %+.2f %%\n',dR4to9);
fprintf('  -Z''''max:   %+.2f %%\n\n',dZ4to9);

fprintf('Day-18 suspected same vs cross pair:\n');
fprintf('  Delta Rp:      %+.2f %%\n',dRp17);
fprintf('  Delta -Zmax:   %+.2f %%\n',dZ17);
fprintf('  Delta Pmp:     %+.2f %%\n',dP17);
fprintf('  Spectrum D_Z:   %.2f %%\n\n',dz17);

fprintf('PS95 DC states:\n');
fprintf('  One cell: Isc = %.3f A, Pmp = %.3f W\n',PS95_1.IscMean,PS95_1.PmpMean);
fprintf('  Two cells: Isc = %.3f A, Pmp = %.3f W\n',PS95_2.IscMean,PS95_2.PmpMean);

%% =========================================================================
% LOCAL FUNCTIONS
% =========================================================================

function zipPath = findRawDataZip(scriptDir)

% First allow the legacy beside-script layout.
exact = fullfile(scriptDir,'Raw Data.zip');
if isfile(exact)
    zipPath = exact;
    return;
end

hits = dir(fullfile(scriptDir,'Raw Data*.zip'));
if ~isempty(hits)
    zipPath = fullfile(hits(1).folder,hits(1).name);
    return;
end

% Repository layout: <repo>/matlab/figure_generation/<script>
repoRoot = fileparts(fileparts(scriptDir));
repoZip = fullfile(repoRoot,'data','raw','Raw_Data_2026_Clean.zip');
if isfile(repoZip)
    zipPath = repoZip;
    return;
end

error('No raw-data ZIP was found. Checked beside this script and:\n%s',repoZip);
end

%% ------------------------------------------------------------------------
function required = buildRequiredFileList()

required = {};

% Day 13
required = [required, { ...
'20260922_GSM_HLT_FRA_POT_OPX70_R01.xlsx', ...
'20260922_GSM_HLT_FRA_POT_OPX70_R02.xlsx', ...
'20260922_GSM_HLT_FRA_POT_OPX70_R03.xlsx', ...
'20260922_GSM_PS50_41_FRA_POT_OPX70_R01.xlsx', ...
'20260922_GSM_PS50_41_FRA_POT_OPX70_R02.xlsx', ...
'20260922_GSM_PS50_42_FRA_POT_OPX70_R01.xlsx', ...
'20260922_GSM_PS50_42_FRA_POT_OPX70_R02.xlsx', ...
'20260922_GSM_PS50_52_FRA_POT_OPX70_R01.xlsx', ...
'20260922_GSM_PS50_52_FRA_POT_OPX70_R02.xlsx', ...
'20260922_GSM_HLT_DC_R01.xlsx', ...
'20260922_GSM_HLT_DC_R02.xlsx', ...
'20260922_GSM_HLT_DC_R03.xlsx', ...
'20260922_GSM_PS50_41_DC_R01.xlsx', ...
'20260922_GSM_PS50_41_DC_R02.xlsx', ...
'20260922_GSM_PS50_42_DC_R01.xlsx', ...
'20260922_GSM_PS50_42_DC_R02.xlsx', ...
'20260922_GSM_PS50_52_DC_R01.xlsx', ...
'20260922_GSM_PS50_52_DC_R02.xlsx'}];

% Day 14
required = [required, { ...
'20260923_GSM_HLT_FRA_POT_OPX70_R01.xlsx', ...
'20260923_GSM_HLT_FRA_POT_OPX70_R02.xlsx', ...
'20260923_GSM_PS50_52_TOP50_FRA_POT_OPX70_R01.xlsx', ...
'20260923_GSM_PS50_52_TOP50_FRA_POT_OPX70_R02.xlsx', ...
'20260923_GSM_PS50_52_MID50_FRA_POT_OPX70_R01.xlsx', ...
'20260923_GSM_PS50_52_MID50_FRA_POT_OPX70_R02.xlsx', ...
'20260923_GSM_PS50_52_BOT50_FRA_POT_OPX70_R01.xlsx', ...
'20260923_GSM_PS50_52_BOT50_FRA_POT_OPX70_R02.xlsx'}];

% Day 15
required = [required, { ...
'20260928_GSM_HLT_FRA_POT_OPX70_R01.xlsx', ...
'20260928_GSM_HLT_FRA_POT_OPX70_R02.xlsx', ...
'20260928_GSM_PS25_FRA_POT_OPX70_R01.xlsx', ...
'20260928_GSM_PS25_FRA_POT_OPX70_R02.xlsx', ...
'20260928_GSM_PS50_FRA_POT_OPX70_R01.xlsx', ...
'20260928_GSM_PS50_FRA_POT_OPX70_R02.xlsx', ...
'20260928_GSM_PS75_FRA_POT_OPX70_R01.xlsx', ...
'20260928_GSM_PS75_FRA_POT_OPX70_R01_2.xlsx', ...
'20260928_GSM_PS75_FRA_POT_OPX70_R02.xlsx', ...
'20260928_GSM_PS100_FRA_POT_OPX70_R01.xlsx', ...
'20260928_GSM_PS100_FRA_POT_OPX70_R02.xlsx', ...
'20260928_GSM_HLT_DC_R01.xlsx', ...
'20260928_GSM_HLT_DC_R02.xlsx', ...
'20260928_GSM_PS25_DC_R01.xlsx', ...
'20260928_GSM_PS25_DC_R02.xlsx', ...
'20260928_GSM_PS50_DC_R01.xlsx', ...
'20260928_GSM_PS50_DC_R02.xlsx', ...
'20260928_GSM_PS75_DC_R01.xlsx', ...
'20260928_GSM_PS75_DC_R02.xlsx', ...
'20260928_GSM_PS100_DC_R01.xlsx', ...
'20260928_GSM_PS100_DC_R02.xlsx'}];

% Day 16
for s = ["A75B0","A75B25","A75B50","A75B75","A75B100"]
    required{end+1} = sprintf('20260929_GSM_%s_FRA_POT_OPX70_R01.xlsx',s); %#ok<AGROW>
    required{end+1} = sprintf('20260929_GSM_%s_DC_R01.xlsx',s); %#ok<AGROW>
end

% Day 17
lab = { ...
'PS75_31', ...
'PS75_31_61', ...
'PS75_31_61_91', ...
'PS75_31_61_91_112', ...
'PS75_31_61_91_112_82', ...
'PS75_31_61_91_112_82_41', ...
'PS75_31_61_91_112_82_41_71', ...
'PS75_31_61_91_112_82_41_71_101', ...
'PS75_31_61_91_112_82_41_71_101_102'};

required{end+1} = '20261002_GSM_HLT_FRA_POT_OPX70_R01.xlsx';
required{end+1} = '20261002_GSM_HLT_DC_R01.xlsx';

for k = 1:numel(lab)
    required{end+1} = sprintf('20261002_GSM_%s_FRA_POT_OPX70_R01.xlsx',lab{k}); %#ok<AGROW>
    required{end+1} = sprintf('20261002_GSM_%s_DC_R01.xlsx',lab{k}); %#ok<AGROW>
end

% Day 18
for s = ["HLT","PS75_21_23","PS75_21_31","PS95_21","PS95_21_41"]
    required{end+1} = sprintf('20261006_GSM_%s_FRA_POT_OPX70_R01.xlsx',s); %#ok<AGROW>
    required{end+1} = sprintf('20261006_GSM_%s_DC_R01.xlsx',s); %#ok<AGROW>
end

% Parameter files are validated automatically when each FRA file is loaded.
end

%% ------------------------------------------------------------------------
function S = makeSingleState(rawRoot,fraName,dcName,fmin,fmax)

if nargin < 3
    dcName = '';
end

fraPath = locateExact(rawRoot,fraName,true);
paramName = strrep(fraName,'.xlsx','_PARAMS.xlsx');
paramPath = locateExact(rawRoot,paramName,true);

F = readFra(fraPath);
P = readParams(paramPath);

S = summariseFraRuns({F},fmin,fmax);
S.RpValues = P.Rp;
S.RsValues = P.Rs;
S.nValues = P.n;
S.RpMean = P.Rp;
S.RsMean = P.Rs;
S.nMean = P.n;
S.KKMean = mean(abs(F.errZre),'omitnan');

if ~isempty(dcName)
    D = readDc(locateExact(rawRoot,dcName,true));
    S.IscMean = D.Isc;
    S.PmpMean = D.Pmp;
    S.VocMean = D.Voc;
    S.VmpMean = D.Vmp;
    S.ImpMean = D.Imp;
    S.dcCurves = {D};
else
    S.IscMean = NaN;
    S.PmpMean = NaN;
    S.VocMean = NaN;
    S.VmpMean = NaN;
    S.ImpMean = NaN;
    S.dcCurves = {};
end
end

%% ------------------------------------------------------------------------
function S = makeState(rawRoot,fraNames,dcNames,fmin,fmax)

F = cell(numel(fraNames),1);
rp = nan(numel(fraNames),1);
rs = nan(numel(fraNames),1);
nn = nan(numel(fraNames),1);
kk = nan(numel(fraNames),1);

for k = 1:numel(fraNames)
    F{k} = readFra(locateExact(rawRoot,fraNames{k},true));

    paramName = strrep(fraNames{k},'.xlsx','_PARAMS.xlsx');
    P = readParams(locateExact(rawRoot,paramName,true));

    rp(k) = P.Rp;
    rs(k) = P.Rs;
    nn(k) = P.n;
    kk(k) = mean(abs(F{k}.errZre),'omitnan');
end

S = summariseFraRuns(F,fmin,fmax);

S.RpValues = rp;
S.RsValues = rs;
S.nValues = nn;
S.RpMean = mean(rp,'omitnan');
S.RsMean = mean(rs,'omitnan');
S.nMean = mean(nn,'omitnan');
S.KKMean = mean(kk,'omitnan');

if nargin >= 3 && ~isempty(dcNames)
    D = cell(numel(dcNames),1);
    isc = nan(numel(dcNames),1);
    pmp = nan(numel(dcNames),1);
    voc = nan(numel(dcNames),1);
    vmp = nan(numel(dcNames),1);
    imp = nan(numel(dcNames),1);

    for k = 1:numel(dcNames)
        D{k} = readDc(locateExact(rawRoot,dcNames{k},true));
        isc(k) = D{k}.Isc;
        pmp(k) = D{k}.Pmp;
        voc(k) = D{k}.Voc;
        vmp(k) = D{k}.Vmp;
        imp(k) = D{k}.Imp;
    end

    S.IscMean = mean(isc,'omitnan');
    S.PmpMean = mean(pmp,'omitnan');
    S.VocMean = mean(voc,'omitnan');
    S.VmpMean = mean(vmp,'omitnan');
    S.ImpMean = mean(imp,'omitnan');
    S.dcCurves = D;
else
    S.IscMean = NaN;
    S.PmpMean = NaN;
    S.VocMean = NaN;
    S.VmpMean = NaN;
    S.ImpMean = NaN;
    S.dcCurves = {};
end
end

%% ------------------------------------------------------------------------
function S = summariseFraRuns(F,fmin,fmax)

fRef = F{1}.freq(:);
ZreMat = nan(numel(fRef),numel(F));
ZimMat = nan(numel(fRef),numel(F));

for k = 1:numel(F)
    [fu,ia] = unique(F{k}.freq(:),'stable');
    zr = F{k}.zre(ia);
    zi = F{k}.zim(ia);

    ZreMat(:,k) = interp1(log10(fu),zr,log10(fRef),'linear',NaN);
    ZimMat(:,k) = interp1(log10(fu),zi,log10(fRef),'linear',NaN);
end

S.freq = fRef;
S.zreRepeats = ZreMat;
S.zimRepeats = ZimMat;
S.zreMean = mean(ZreMat,2,'omitnan');
S.zimMean = mean(ZimMat,2,'omitnan');

S.plotMask = S.freq >= fmin & S.freq <= fmax & S.zimMean >= 0;

zmax = nan(numel(F),1);

for k = 1:numel(F)
    mk = F{k}.freq >= fmin & F{k}.freq <= fmax & F{k}.zim >= 0;
    zmax(k) = max(F{k}.zim(mk),[],'omitnan');
end

S.ZmaxValues = zmax;
S.ZmaxMean = mean(zmax,'omitnan');
end

%% ------------------------------------------------------------------------
function h = plotState(ax,S,colour,lineStyle,marker,showRepeats)

if showRepeats
    pale = 0.75 + 0.25*colour;

    for k = 1:size(S.zreRepeats,2)
        mk = S.freq >= 1 & S.freq <= 2000 & S.zimRepeats(:,k) >= 0;

        plot(ax,S.zreRepeats(mk,k),S.zimRepeats(mk,k),'-', ...
            'Color',pale,'LineWidth',0.8,'HandleVisibility','off');
    end
end

mk = S.plotMask;
idx = find(mk);

h = plot(ax,S.zreMean(mk),S.zimMean(mk), ...
    'LineStyle',lineStyle,'Color',colour,'LineWidth',2.0);

if isempty(idx)
    return;
end

markerIdx = idx(1:2:end);

plot(ax,S.zreMean(markerIdx),S.zimMean(markerIdx), ...
    'LineStyle','none','Marker',marker,'MarkerSize',4.5, ...
    'Color',colour,'MarkerFaceColor','w','HandleVisibility','off');
end

%% ------------------------------------------------------------------------
function Dz = spectrumDifference(A,B,fmin,fmax)

f = A.freq(:);

[fb,ib] = unique(B.freq(:),'stable');
bRe = interp1(log10(fb),B.zreMean(ib),log10(f),'linear',NaN);
bIm = interp1(log10(fb),B.zimMean(ib),log10(f),'linear',NaN);

mk = f >= fmin & f <= fmax & ...
     A.zimMean >= 0 & bIm >= 0 & ...
     isfinite(A.zreMean) & isfinite(A.zimMean) & ...
     isfinite(bRe) & isfinite(bIm);

ZA = A.zreMean(mk) - 1i*A.zimMean(mk);
ZB = bRe(mk)       - 1i*bIm(mk);

den = (abs(ZA)+abs(ZB))/2;
valid = den > 0 & isfinite(den);

Dz = 100*mean(abs(ZA(valid)-ZB(valid))./den(valid),'omitnan');
end

%% ------------------------------------------------------------------------
function pct = pctChange(ref,new)
pct = 100*(new-ref)/ref;
end

%% ------------------------------------------------------------------------
function F = readFra(filePath)

C = readcell(filePath);
headers = string(C(1,:));

iRe  = findHeader(headers,{"Z' (Ω)","Z' (\Omega)"});
iIm  = findHeader(headers,{"-Z'' (Ω)","-Z'' (\Omega)"});
iF   = findHeader(headers,{"Frequency (Hz)"});
iErr = findHeader(headers,{"Error Z' (%)"});

zr = columnNumeric(C,iRe);
zi = columnNumeric(C,iIm);
ff = columnNumeric(C,iF);
er = columnNumeric(C,iErr);

good = isfinite(zr) & isfinite(zi) & isfinite(ff) & ff > 0;

F.zre = zr(good);
F.zim = zi(good);
F.freq = ff(good);
F.errZre = er(good);
end

%% ------------------------------------------------------------------------
function P = readParams(filePath)

C = readcell(filePath);
headers = string(C(1,:));

P.Rp = forceNumeric(C{2,findHeader(headers,{"Rp.R (Ω)","Rp.R (\Omega)"})});
P.Rs = forceNumeric(C{2,findHeader(headers,{"Rs.R (Ω)","Rs.R (\Omega)"})});
P.n  = forceNumeric(C{2,findHeader(headers,{"CPE.N"})});
end

%% ------------------------------------------------------------------------
function D = readDc(filePath)

C = readcell(filePath);
headers = string(C(1,:));

iV = findHeader(headers,{"Corrected Potential (V)","Corrected Potential"});
iI = findHeader(headers,{"Corrected Current (A)","Corrected Current"});

V = columnNumeric(C,iV);
I = columnNumeric(C,iI);

good = isfinite(V) & isfinite(I);
V = V(good);
I = I(good);

[V,ord] = sort(V);
I = I(ord);

P = V.*I;

physical = V >= 0 & I >= 0 & P >= 0;

if any(physical)
    Vp = V(physical);
    Ip = I(physical);
    Pp = P(physical);

    [Pmp,j] = max(Pp,[],'omitnan');
    Vmp = Vp(j);
    Imp = Ip(j);
else
    [Pmp,j] = max(P,[],'omitnan');
    Vmp = V(j);
    Imp = I(j);
end

% Voc from zero-current crossing.
Voc = max(V);

for k = 1:numel(I)-1
    if I(k) >= 0 && I(k+1) <= 0
        Voc = interp1(I(k:k+1),V(k:k+1),0,'linear','extrap');
        break;
    end
end

% Isc from V=0 interpolation.
Isc = I(1);

for k = 1:numel(V)-1
    if V(k) <= 0 && V(k+1) >= 0
        Isc = interp1(V(k:k+1),I(k:k+1),0,'linear','extrap');
        break;
    end
end

D.V = V;
D.I = I;
D.P = P;
D.Isc = Isc;
D.Pmp = Pmp;
D.Vmp = Vmp;
D.Imp = Imp;
D.Voc = Voc;
end

%% ------------------------------------------------------------------------
function h = plotPhysicalIV(ax,S,colour,lw)

D = S.dcCurves{1};
mk = D.V >= 0 & D.I >= 0;

h = plot(ax,D.V(mk),D.I(mk),'-','Color',colour,'LineWidth',lw);
end

%% ------------------------------------------------------------------------
function h = plotPhysicalPV(ax,S,colour,lw)

D = S.dcCurves{1};
mk = D.V >= 0 & D.I >= 0;

h = plot(ax,D.V(mk),D.P(mk),'-','Color',colour,'LineWidth',lw);
end

%% ------------------------------------------------------------------------
function idx = findHeader(headers,candidates)

idx = [];

for k = 1:numel(candidates)
    j = find(headers == string(candidates{k}),1,'first');

    if ~isempty(j)
        idx = j;
        return;
    end
end

error('Expected header not found. Available headers:\n%s', ...
    strjoin(cellstr(headers),', '));
end

%% ------------------------------------------------------------------------
function x = columnNumeric(C,col)

x = nan(size(C,1)-1,1);

for r = 2:size(C,1)
    x(r-1) = forceNumeric(C{r,col});
end
end

%% ------------------------------------------------------------------------
function x = forceNumeric(v)

if isnumeric(v)
    x = double(v);

elseif islogical(v)
    x = double(v);

elseif isempty(v)
    x = NaN;

elseif ischar(v) || isstring(v)
    s = strtrim(string(v));

    if strlength(s)==0 || strcmpi(s,"NaN")
        x = NaN;
    else
        x = str2double(s);
    end

else
    try
        if ismissing(v)
            x = NaN;
        else
            x = double(v);
        end
    catch
        x = NaN;
    end
end
end

%% ------------------------------------------------------------------------
function filePath = locateExact(rawRoot,fileName,throwIfMissing)

hits = dir(fullfile(rawRoot,'**',fileName));

if ~isempty(hits)
    good = true(numel(hits),1);

    for k = 1:numel(hits)
        fullp = fullfile(hits(k).folder,hits(k).name);

        if contains(fullp,'__MACOSX') || startsWith(hits(k).name,'._')
            good(k) = false;
        end
    end

    hits = hits(good);
end

if isempty(hits)

    filePath = '';

    if throwIfMissing
        % Useful diagnostic: print files sharing the first date prefix.
        tok = regexp(fileName,'^\d{8}','match','once');

        if isempty(tok)
            cand = dir(fullfile(rawRoot,'**','*.xlsx'));
        else
            cand = dir(fullfile(rawRoot,'**',[tok '*.xlsx']));
        end

        fprintf(2,'\nExpected file not found:\n  %s\n',fileName);

        if ~isempty(cand)
            fprintf(2,'Candidates from the same date:\n');

            for j = 1:min(numel(cand),50)
                fprintf(2,'  %s\n',cand(j).name);
            end
        end

        error('Required file not found.');
    end

    return;
end

if numel(hits) > 1
    % Exact base filenames may appear in separate metadata copies; after
    % filtering, choose the first real data file.
    fprintf('Multiple exact matches for %s; using first real-data copy.\n',fileName);
end

filePath = fullfile(hits(1).folder,hits(1).name);
end

%% ------------------------------------------------------------------------
function exportFigure(figHandle,outDir,baseName,dpi)

drawnow;

exportgraphics(figHandle,fullfile(outDir,[baseName '.png']),'Resolution',dpi);
exportgraphics(figHandle,fullfile(outDir,[baseName '.pdf']),'ContentType','vector');
savefig(figHandle,fullfile(outDir,[baseName '.fig']));
end
