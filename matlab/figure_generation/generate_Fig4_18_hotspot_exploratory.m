%% generate_Fig4_18_hotspot_exploratory.m
% =========================================================================
% Figure 4.18 - Exploratory hotspot testing
%
% Clean, self-contained script for Day 19 / Day 20 hotspot data.
%
% Put this script beside the FULL Raw Data.zip archive containing:
%   Raw Data/20261008_Day19/
%   Raw Data/20261009_Day20/
%
% The figure deliberately treats HOT70/HOT80/HOT90 as TARGET labels.
% The locally heated cell was not held at a verified constant temperature
% throughout the FRA sweep; therefore the figure does not claim a calibrated
% hotspot-temperature response.
%
% Outputs:
%   Chapter4_Figures/Fig4_18_exploratory_hotspot.pdf
%   Chapter4_Figures/Fig4_18_exploratory_hotspot.png
%   Chapter4_Figures/Fig4_18_exploratory_hotspot.fig
%
% FRA comparison window: 1 Hz -- 2 kHz, positive-capacitive region.
% =========================================================================

clear; close all; clc;

FREQ_MIN   = 1;
FREQ_MAX   = 2000;
EXPORT_DPI = 300;

%% Paths
scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir), scriptDir = pwd; end
repoRoot = fileparts(fileparts(scriptDir));

zipPath = fullfile(repoRoot,'data','raw','Raw_Data_2026_Clean.zip');
if ~isfile(zipPath)
    % Backward-compatible fallback if the script is copied elsewhere.
    hits = dir(fullfile(scriptDir,'Raw Data*.zip'));
    if isempty(hits)
        error('Raw-data ZIP not found at %s or beside this script.',zipPath);
    end
    zipPath = fullfile(hits(1).folder,hits(1).name);
end

cacheRoot = fullfile(repoRoot,'data','raw','_RawData_cache_hotspot');
rawRoot   = fullfile(cacheRoot,'Raw Data');
outDir    = fullfile(repoRoot,'figures','generated');

if ~isfolder(rawRoot)
    if isfolder(cacheRoot), rmdir(cacheRoot,'s'); end
    mkdir(cacheRoot);
    fprintf('Extracting %s...\n',zipPath);
    unzip(zipPath,cacheRoot);
end

if ~isfolder(outDir), mkdir(outDir); end
%% Exact file map
D19 = fullfile(rawRoot,'20261008_Day19');
D20 = fullfile(rawRoot,'20261009_Day20');

% Day 19
A19 = loadState(D19, ...
    '20261008_GSM_HLT_FRA_POT_OPX70_R01.xlsx', ...
    '20261008_GSM_HLT_FRA_POT_OPX70_R01_PARAMS.xlsx', ...
    '20261008_GSM_HLT_DC_R01.xlsx',FREQ_MIN,FREQ_MAX);

H90 = loadState(D19, ...
    '20261008_GSM_HOT90_FRA_POT_OPX70_R01.xlsx', ...
    '20261008_GSM_HOT90_FRA_POT_OPX70_R01_PARAMS.xlsx', ...
    '20261008_GSM_HOT90_DC_R01.xlsx',FREQ_MIN,FREQ_MAX);

% Day 20
A20_1 = loadState(D20, ...
    '20261009_GSM_HLT_FRA_POT_OPX70_R01.xlsx', ...
    '20261009_GSM_HLT_FRA_POT_OPX70_R01_PARAMS.xlsx', ...
    '20261009_GSM_HLT_DC_R01.xlsx',FREQ_MIN,FREQ_MAX);

H70 = loadState(D20, ...
    '20261009_GSM_HOT70_52_FRA_POT_OPX70_R01.xlsx', ...
    '20261009_GSM_HOT70_52_FRA_POT_OPX70_R01_PARAMS.xlsx', ...
    '20261009_GSM_HOT70_52_DC_R01.xlsx',FREQ_MIN,FREQ_MAX);

A20_2 = loadState(D20, ...
    '20261009_GSM_HLT_FRA_POT_OPX70_R02.xlsx', ...
    '20261009_GSM_HLT_FRA_POT_OPX70_R02_PARAMS.xlsx', ...
    '20261009_GSM_HLT_DC_R02.xlsx',FREQ_MIN,FREQ_MAX);

H80 = loadState(D20, ...
    '20261009_GSM_HOT80_52_FRA_POT_OPX70_R02.xlsx', ...
    '20261009_GSM_HOT80_52_FRA_POT_OPX70_R02_PARAMS.xlsx', ...
    '20261009_GSM_HOT80_52_DC_R02.xlsx',FREQ_MIN,FREQ_MAX);

%% Metrics
Dz90       = spectrumDz(A19,H90,FREQ_MIN,FREQ_MAX);
Dz70       = spectrumDz(A20_1,H70,FREQ_MIN,FREQ_MAX);
Dz80       = spectrumDz(A20_2,H80,FREQ_MIN,FREQ_MAX);
DzHealthy  = spectrumDz(A20_1,A20_2,FREQ_MIN,FREQ_MAX);

dP90   = pct(A19.Pmp,H90.Pmp);
dRp90  = pct(A19.Rp,H90.Rp);
dZ90   = pct(A19.Zmax,H90.Zmax);

dP70   = pct(A20_1.Pmp,H70.Pmp);
dRp70  = pct(A20_1.Rp,H70.Rp);
dZ70   = pct(A20_1.Zmax,H70.Zmax);

dP80   = pct(A20_2.Pmp,H80.Pmp);
dRp80  = pct(A20_2.Rp,H80.Rp);
dZ80   = pct(A20_2.Zmax,H80.Zmax);

%% Figure
set(groot,'defaultAxesFontName','Helvetica');
set(groot,'defaultAxesFontSize',11);

fig = figure('Color','w','Position',[50 60 1280 760]);
tl = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');

% -------------------------------------------------------------------------
% (a) Day 19
ax1 = nexttile(tl,1);
hold(ax1,'on'); box(ax1,'on'); grid(ax1,'on');

plotFra(ax1,A19,[0.10 0.38 0.72],'-','o');
plotFra(ax1,H90,[0.85 0.33 0.10],'-','s');

xlabel(ax1,'Real impedance, Z'' (\Omega)');
ylabel(ax1,'Imaginary impedance, -Z'''' (\Omega)');
title(ax1,'(a) Day 19: high local-temperature target');
legend(ax1,{'Healthy','HOT90 target, cell (5,2)'},'Location','best');

text(ax1,0.04,0.05, ...
    sprintf(['D_Z = %.2f%%\n' ...
             '\\DeltaP_{mp} = %+.2f%%\n' ...
             '\\DeltaR_p = %+.2f%%\n' ...
             '\\Delta(-Z''''_{max}) = %+.2f%%\n' ...
             'f_{peak}: %.1f \\rightarrow %.1f Hz'], ...
             Dz90,dP90,dRp90,dZ90,A19.fpeak,H90.fpeak), ...
    'Units','normalized','VerticalAlignment','bottom', ...
    'BackgroundColor','w','EdgeColor',[0.82 0.82 0.82], ...
    'Margin',4,'FontSize',8.7);

% -------------------------------------------------------------------------
% (b) Day 20
ax2 = nexttile(tl,2);
hold(ax2,'on'); box(ax2,'on'); grid(ax2,'on');

plotFra(ax2,A20_1,[0.10 0.38 0.72],'-','o');
plotFra(ax2,H70,[0.47 0.67 0.19],'-','^');
plotFra(ax2,A20_2,[0.49 0.18 0.56],'--','o');
plotFra(ax2,H80,[0.85 0.33 0.10],'--','s');

xlabel(ax2,'Real impedance, Z'' (\Omega)');
ylabel(ax2,'Imaginary impedance, -Z'''' (\Omega)');
title(ax2,'(b) Day 20: repeatability benchmark against HOT70/HOT80');
legend(ax2,{'Healthy R01','HOT70 target','Healthy R02','HOT80 target'}, ...
    'Location','best');

text(ax2,0.04,0.05, ...
    sprintf(['Healthy R01 \\leftrightarrow R02: D_Z = %.2f%%\n' ...
             'R01 \\rightarrow HOT70: D_Z = %.2f%%\n' ...
             'R02 \\rightarrow HOT80: D_Z = %.2f%%'], ...
             DzHealthy,Dz70,Dz80), ...
    'Units','normalized','VerticalAlignment','bottom', ...
    'BackgroundColor','w','EdgeColor',[0.82 0.82 0.82], ...
    'Margin',4,'FontSize',8.7);

% -------------------------------------------------------------------------
% (c) Direct effect-vs-drift comparison
ax3 = nexttile(tl,3,[1 2]);
hold(ax3,'on'); box(ax3,'on'); grid(ax3,'on');

vals = [Dz90 Dz70 Dz80 DzHealthy];
b = bar(ax3,1:4,vals,0.62);
xticks(ax3,1:4);
xticklabels(ax3,{'Day 19 HOT90','Day 20 HOT70','Day 20 HOT80','Day 20 healthy drift'});
ylabel(ax3,'Complex-spectrum difference, D_Z (%)');
title(ax3,'(c) Hotspot contrasts were not consistently larger than healthy run-to-run drift');

for k = 1:numel(vals)
    text(ax3,k,vals(k)+0.10,sprintf('%.2f%%',vals(k)), ...
        'HorizontalAlignment','center','FontSize',9);
end

ylim(ax3,[0 max(vals)*1.35]);

text(ax3,0.50,0.90, ...
    ['Target labels describe the local temperature reached before FRA; ' ...
     'the heated cell cooled during acquisition.'], ...
    'Units','normalized','HorizontalAlignment','center', ...
    'BackgroundColor','w','EdgeColor',[0.82 0.82 0.82], ...
    'Margin',4,'FontSize',8.8);

sgtitle(tl,'Figure 4.18: Exploratory local-hotspot impedance response', ...
    'FontWeight','bold');

%% Export
exportgraphics(fig,fullfile(outDir,'Fig4_18_exploratory_hotspot.png'), ...
    'Resolution',EXPORT_DPI);
exportgraphics(fig,fullfile(outDir,'Fig4_18_exploratory_hotspot.pdf'), ...
    'ContentType','vector');
savefig(fig,fullfile(outDir,'Fig4_18_exploratory_hotspot.fig'));

%% Console summary
fprintf('\n============================================================\n');
fprintf('FIGURE 4.18 HOTSPOT SUMMARY\n');
fprintf('============================================================\n');

fprintf('\nDay 19: healthy -> HOT90 target\n');
fprintf('  D_Z                 = %.3f %%\n',Dz90);
fprintf('  Delta Pmp           = %+.3f %%\n',dP90);
fprintf('  Delta Rp            = %+.3f %%\n',dRp90);
fprintf('  Delta -Z''''max       = %+.3f %%\n',dZ90);
fprintf('  n                   = %.5f -> %.5f\n',A19.n,H90.n);
fprintf('  f_peak              = %.3f -> %.3f Hz\n',A19.fpeak,H90.fpeak);
fprintf('  mean |K-K residual| = %.3f -> %.3f %%\n',A19.KK,H90.KK);

fprintf('\nDay 20 paired comparisons\n');
fprintf('  Healthy R01 -> HOT70: D_Z = %.3f %%\n',Dz70);
fprintf('     Delta Pmp = %+.3f %%, Delta Rp = %+.3f %%, Delta -Z''''max = %+.3f %%\n', ...
    dP70,dRp70,dZ70);

fprintf('  Healthy R02 -> HOT80: D_Z = %.3f %%\n',Dz80);
fprintf('     Delta Pmp = %+.3f %%, Delta Rp = %+.3f %%, Delta -Z''''max = %+.3f %%\n', ...
    dP80,dRp80,dZ80);

fprintf('  Healthy R01 -> Healthy R02 drift: D_Z = %.3f %%\n',DzHealthy);

fprintf('\nInterpretation: hotspot-state spectral changes were small and not\n');
fprintf('consistently larger than the healthy run-to-run change. Because the\n');
fprintf('local cell temperature was not maintained or continuously recorded\n');
fprintf('during FRA, this remains an exploratory result rather than a calibrated\n');
fprintf('hotspot-temperature response.\n');

%% =========================================================================
% Local functions
% =========================================================================

function S = loadState(dayRoot,fraName,paramName,dcName,fmin,fmax)

fraPath   = fullfile(dayRoot,'FRA',fraName);
paramPath = fullfile(dayRoot,'Nova results',paramName);
dcPath    = fullfile(dayRoot,'DC Characterisation',dcName);

mustExist(fraPath);
mustExist(paramPath);
mustExist(dcPath);

F = readFra(fraPath);
P = readParams(paramPath);
D = readDc(dcPath);

mk = F.freq >= fmin & F.freq <= fmax & F.zim >= 0;

S.freq = F.freq;
S.zre  = F.zre;
S.zim  = F.zim;
S.plotMask = mk;

S.Zmax = max(F.zim(mk));
[~,ii] = max(F.zim(mk));
ff = F.freq(mk);
S.fpeak = ff(ii);

S.KK = mean(abs(F.errRe),'omitnan');

S.Rp = P.Rp;
S.Rs = P.Rs;
S.Y0 = P.Y0;
S.n  = P.n;

S.Pmp = D.Pmp;
S.Vmp = D.Vmp;
S.Imp = D.Imp;
S.Voc = D.Voc;
end

function F = readFra(filePath)

C = readcell(filePath);

headers = string(C(1,:));
iRe  = findHeader(headers,"Z' (Ω)");
iIm  = findHeader(headers,"-Z'' (Ω)");
iF   = findHeader(headers,"Frequency (Hz)");
iErr = findHeader(headers,"Error Z' (%)");

F.zre   = toNumericColumn(C(2:end,iRe));
F.zim   = toNumericColumn(C(2:end,iIm));
F.freq  = toNumericColumn(C(2:end,iF));
F.errRe = toNumericColumn(C(2:end,iErr));

good = isfinite(F.zre) & isfinite(F.zim) & isfinite(F.freq) & F.freq > 0;

F.zre   = F.zre(good);
F.zim   = F.zim(good);
F.freq  = F.freq(good);
F.errRe = F.errRe(good);
end

function P = readParams(filePath)

C = readcell(filePath);
headers = string(C(1,:));

P.Y0 = numericCell(C{2,findHeader(headers,"CPE.Y0 (F)")});
P.Rp = numericCell(C{2,findHeader(headers,"Rp.R (Ω)")});
P.Rs = numericCell(C{2,findHeader(headers,"Rs.R (Ω)")});
P.n  = numericCell(C{2,findHeader(headers,"CPE.N")});
end

function D = readDc(filePath)

C = readcell(filePath);
headers = string(C(1,:));

iV = findHeader(headers,"Corrected Potential (V)");
iI = findHeader(headers,"Corrected Current (A)");

V = toNumericColumn(C(2:end,iV));
I = toNumericColumn(C(2:end,iI));

good = isfinite(V) & isfinite(I);
V = V(good);
I = I(good);

[V,ord] = sort(V);
I = I(ord);

P = V.*I;
mk = V >= 0 & I >= 0 & P >= 0;

Vp = V(mk);
Ip = I(mk);
Pp = P(mk);

[D.Pmp,j] = max(Pp);
D.Vmp = Vp(j);
D.Imp = Ip(j);

D.Voc = max(V);
for k = 1:numel(I)-1
    if I(k) >= 0 && I(k+1) <= 0
        D.Voc = interp1(I(k:k+1),V(k:k+1),0,'linear','extrap');
        break;
    end
end
end

function plotFra(ax,S,colour,lineStyle,marker)

mk = S.plotMask;
idx = find(mk);
mark = idx(1:2:end);

plot(ax,S.zre(mk),S.zim(mk), ...
    'LineStyle',lineStyle,'Color',colour,'LineWidth',1.9);

plot(ax,S.zre(mark),S.zim(mark), ...
    'LineStyle','none','Marker',marker,'MarkerSize',4.8, ...
    'MarkerFaceColor','w','Color',colour,'HandleVisibility','off');
end

function Dz = spectrumDz(A,B,fmin,fmax)

fA = A.freq;
fB = B.freq;

common = intersect(fA,fB);
common = common(common >= fmin & common <= fmax);

q = [];

for k = 1:numel(common)
    f = common(k);

    ia = find(fA == f,1);
    ib = find(fB == f,1);

    if isempty(ia) || isempty(ib), continue; end
    if A.zim(ia) < 0 || B.zim(ib) < 0, continue; end

    ZA = A.zre(ia) - 1i*A.zim(ia);
    ZB = B.zre(ib) - 1i*B.zim(ib);

    den = (abs(ZA)+abs(ZB))/2;

    if den > 0
        q(end+1) = abs(ZA-ZB)/den; %#ok<AGROW>
    end
end

Dz = 100*mean(q,'omitnan');
end

function y = pct(a,b)
y = 100*(b-a)/a;
end

function idx = findHeader(headers,target)

idx = find(headers == string(target),1);

if isempty(idx)
    error('Header "%s" not found.',target);
end
end

function x = toNumericColumn(c)

x = nan(numel(c),1);

for k = 1:numel(c)
    x(k) = numericCell(c{k});
end
end

function x = numericCell(v)

if isnumeric(v)
    x = double(v);
elseif islogical(v)
    x = double(v);
elseif ischar(v) || isstring(v)
    x = str2double(string(v));
else
    x = NaN;
end
end

function mustExist(p)

if ~isfile(p)
    error('Required file not found:\n%s',p);
end
end
