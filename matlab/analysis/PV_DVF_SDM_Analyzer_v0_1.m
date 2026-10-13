%% PV_DVF_SDM_Analyzer_v0_1
% Exploratory single-diode-model (SDM) analysis for the DVF environmental
% characterisation campaign.
%
% What this script does
%   1) Recursively finds DC I-V .xlsx files in a selected DVF folder.
%   2) Reads "Corrected Potential (V)" and "Corrected Current (A)".
%   3) Overlays every measured I-V curve.
%   4) Extracts Voc, Isc, Vmp, Imp and Pmp for every curve.
%   5) Fits the five-parameter SDM independently to every curve:
%          Iph, I0, a (= n*Ns*Vt), Rs, Rsh
%   6) If the environmental tracker is in the same folder tree, links each
%      DC file to Config ID, Tavg, Gavg, distance, Variac and fan state.
%   7) Plots fitted SDM parameters versus run, irradiance and temperature.
%   8) Exports a compact results .xlsx next to the data.
%
% IMPORTANT INTERPRETATION NOTE
% Five-parameter SDM fits can be correlated/non-identifiable, especially
% with one I-V curve per condition. Treat independent fitted parameters as
% exploratory trends, not yet as proof that a physical parameter changed.
% Once the DVF dataset is larger, a stronger next step is a GLOBAL fit that
% tests constrained hypotheses, e.g. only Iph varies with G while selected
% parameters are shared across curves.
%
% Requires base MATLAB. If Optimization Toolbox is available, lsqnonlin is
% used. Otherwise the script falls back to bounded fminsearch.
%
% Version: v0.1 | 2026-09-02

clear; clc; close all;

%% USER SETTINGS
maxFitPoints = 300;       % downsample each curve for faster optimisation
showCandidateBias = true;
candidateBiasV = [19.5 20.0];

%% SELECT DVF DATA FOLDER
rootFolder = uigetdir(pwd, 'Select the folder containing the DVF DC curves');
if isequal(rootFolder,0)
    error('No folder selected.');
end

%% FIND DC FILES
files = dir(fullfile(rootFolder, '**', '*_DC_R*.xlsx'));
files = files(~startsWith({files.name}, '~$'));

if isempty(files)
    error('No *_DC_R*.xlsx files were found below:\n%s', rootFolder);
end

% Sort by full path/name for deterministic order
fullNames = string(fullfile({files.folder}, {files.name}));
[~,ord] = sort(fullNames);
files = files(ord);

fprintf('\nPV DVF SDM Analyzer v0.1\n');
fprintf('Found %d DC files.\n\n', numel(files));

%% OPTIONAL ENVIRONMENT TRACKER
tracker = dir(fullfile(rootFolder, '**', 'PV_Environmental_Rig_Characterisation_Tracker*.xlsx'));
tracker = tracker(~startsWith({tracker.name}, '~$'));
trackerTable = table();
trackerPath = "";

if ~isempty(tracker)
    % Use most recently modified tracker if several copies exist.
    [~,k] = max([tracker.datenum]); %#ok<DATNM>
    trackerPath = fullfile(tracker(k).folder, tracker(k).name);
    try
        trackerTable = readtable(trackerPath, ...
            'Sheet','Summary', 'Range','A8:V21', ...
            'VariableNamingRule','preserve');
        fprintf('Environment tracker linked: %s\n\n', trackerPath);
    catch ME
        warning('Tracker found but could not be read: %s', ME.message);
        trackerTable = table();
    end
else
    fprintf('No environmental tracker found. T/G linking will be skipped.\n\n');
end

%% STORAGE
nFiles = numel(files);
curves = struct([]);

File = strings(nFiles,1);
RunLabel = strings(nFiles,1);
ConfigID = strings(nFiles,1);
Distance_cm = nan(nFiles,1);
Variac_V = nan(nFiles,1);
Fan = strings(nFiles,1);
Tavg_C = nan(nFiles,1);
Gavg_Wm2 = nan(nFiles,1);

Voc_V = nan(nFiles,1);
Isc_A = nan(nFiles,1);
Vmp_V = nan(nFiles,1);
Imp_A = nan(nFiles,1);
Pmp_W = nan(nFiles,1);

Iph_A = nan(nFiles,1);
I0_A = nan(nFiles,1);
a_V = nan(nFiles,1);
Rs_ohm = nan(nFiles,1);
Rsh_ohm = nan(nFiles,1);
RMSE_A = nan(nFiles,1);
NRMSE_pct = nan(nFiles,1);
R2 = nan(nFiles,1);
FitMethod = strings(nFiles,1);

%% PROCESS + FIT EACH CURVE
for k = 1:nFiles
    filePath = fullfile(files(k).folder, files(k).name);
    File(k) = string(files(k).name);
    RunLabel(k) = erase(File(k), '.xlsx');

    fprintf('[%d/%d] %s\n', k, nFiles, files(k).name);

    [V,I] = readCorrectedIV(filePath);
    [V,I] = cleanIV(V,I);

    dc = extractDCmetrics(V,I);
    Voc_V(k) = dc.Voc;
    Isc_A(k) = dc.Isc;
    Vmp_V(k) = dc.Vmp;
    Imp_A(k) = dc.Imp;
    Pmp_W(k) = dc.Pmp;

    % Link environmental metadata from tracker when possible.
    if ~isempty(trackerTable)
        meta = lookupTrackerMetadata(trackerTable, RunLabel(k));
        ConfigID(k) = meta.ConfigID;
        Distance_cm(k) = meta.Distance_cm;
        Variac_V(k) = meta.Variac_V;
        Fan(k) = meta.Fan;
        Tavg_C(k) = meta.Tavg_C;
        Gavg_Wm2(k) = meta.Gavg_Wm2;
    end

    % Positive-current region up to measured Voc.
    keep = isfinite(V) & isfinite(I) & V >= 0 & I >= 0;
    if isfinite(dc.Voc)
        keep = keep & V <= dc.Voc;
    end
    Vf = V(keep);
    If = I(keep);

    if numel(Vf) < 20
        warning('Insufficient fit points in %s; fit skipped.', files(k).name);
        curves(k).V = V; curves(k).I = I;
        curves(k).Vmodel = []; curves(k).Imodel = [];
        continue;
    end

    % Evenly downsample in acquisition order / voltage.
    if numel(Vf) > maxFitPoints
        idx = unique(round(linspace(1,numel(Vf),maxFitPoints)));
        Vf = Vf(idx); If = If(idx);
    end

    [p,stats] = fitSDM(Vf,If,dc.Voc,dc.Isc);
    Iph_A(k) = p(1);
    I0_A(k) = p(2);
    a_V(k) = p(3);
    Rs_ohm(k) = p(4);
    Rsh_ohm(k) = p(5);
    RMSE_A(k) = stats.RMSE;
    NRMSE_pct(k) = stats.NRMSE_pct;
    R2(k) = stats.R2;
    FitMethod(k) = stats.Method;

    Vmodel = linspace(max(0,min(V)), min(max(V), dc.Voc), 500)';
    Imodel = sdmCurrent(Vmodel,p);

    curves(k).V = V;
    curves(k).I = I;
    curves(k).Vmodel = Vmodel;
    curves(k).Imodel = Imodel;
end

%% RESULTS TABLE
Results = table(File,RunLabel,ConfigID,Distance_cm,Variac_V,Fan,Tavg_C,Gavg_Wm2, ...
    Voc_V,Isc_A,Vmp_V,Imp_A,Pmp_W, ...
    Iph_A,I0_A,a_V,Rs_ohm,Rsh_ohm,RMSE_A,NRMSE_pct,R2,FitMethod);

fprintf('\n=== FIT SUMMARY ===\n');
disp(Results);

outXlsx = fullfile(rootFolder, 'PV_DVF_SDM_Fit_Results_v0_1.xlsx');
writetable(Results,outXlsx);
fprintf('Results exported to:\n%s\n', outXlsx);

%% FIGURE 1: ALL MEASURED I-V CURVES OVERLAID
figure('Name','DVF DC Overlay','Color','w'); hold on; grid on; box on;
co = lines(nFiles);
legendText = strings(nFiles,1);
for k = 1:nFiles
    plot(curves(k).V,curves(k).I,'LineWidth',1.5,'Color',co(k,:));
    if strlength(ConfigID(k)) > 0 && isfinite(Tavg_C(k)) && isfinite(Gavg_Wm2(k))
        legendText(k) = sprintf('%s | %.1f ^\circC | %.0f W/m^2', ...
            ConfigID(k),Tavg_C(k),Gavg_Wm2(k));
    else
        legendText(k) = RunLabel(k);
    end
end
if showCandidateBias
    for b = candidateBiasV
        xline(b,'--',sprintf('%.1f V',b),'LineWidth',1.0);
    end
end
xlabel('Corrected Panel Voltage (V)');
ylabel('Corrected Current (A)');
title(sprintf('DVF Healthy I-V Curves (%d conditions)',nFiles));
legend(legendText,'Interpreter','none','Location','best');

%% FIGURE 2: EACH MEASURED CURVE VS ITS SDM FIT
nCols = ceil(sqrt(nFiles));
nRows = ceil(nFiles/nCols);
figure('Name','SDM Fit Validation','Color','w');
tl = tiledlayout(nRows,nCols,'TileSpacing','compact','Padding','compact');
for k = 1:nFiles
    nexttile; hold on; grid on; box on;
    plot(curves(k).V,curves(k).I,'LineWidth',1.0,'DisplayName','Measured');
    if ~isempty(curves(k).Vmodel)
        plot(curves(k).Vmodel,curves(k).Imodel,'--','LineWidth',1.5,'DisplayName','SDM');
    end
    xlabel('V (V)'); ylabel('I (A)');
    if strlength(ConfigID(k)) > 0
        title(sprintf('%s | NRMSE %.2f%%',ConfigID(k),NRMSE_pct(k)));
    else
        title(sprintf('Run %d | NRMSE %.2f%%',k,NRMSE_pct(k)));
    end
end
title(tl,'Independent Five-Parameter SDM Fits');

%% FIGURE 3: FITTED PARAMETERS BY CONDITION
paramData = {Iph_A,I0_A,a_V,Rs_ohm,Rsh_ohm};
paramNames = {'I_{ph} (A)','I_0 (A)','a (V)','R_s (\Omega)','R_{sh} (\Omega)'};
figure('Name','SDM Parameter Trends by Run','Color','w');
tl = tiledlayout(3,2,'TileSpacing','compact','Padding','compact');
for j = 1:5
    nexttile; grid on; box on;
    plot(1:nFiles,paramData{j},'-o','LineWidth',1.4);
    xlabel('Condition / run'); ylabel(paramNames{j});
    xticks(1:nFiles);
    if all(strlength(ConfigID)>0)
        xticklabels(ConfigID); xtickangle(45);
    end
    if j==2
        set(gca,'YScale','log');
    end
end
nexttile; axis off;
text(0,1,{ ...
    'Interpretation warning:', ...
    'Independent 5-parameter SDM fits can trade', ...
    'off parameters against each other.', ...
    'Use these plots to identify hypotheses;', ...
    'confirm them later with constrained/global fitting.'}, ...
    'VerticalAlignment','top','FontWeight','bold');
title(tl,'Exploratory SDM Parameter Movement');

%% FIGURES 4-5: PARAMETERS VS G AND T (IF TRACKER LINKED)
if any(isfinite(Gavg_Wm2))
    plotParametersVsEnvironment(Gavg_Wm2,paramData,paramNames,ConfigID, ...
        'Average irradiance G (W/m^2)','SDM Parameters vs Irradiance');
end
if any(isfinite(Tavg_C))
    plotParametersVsEnvironment(Tavg_C,paramData,paramNames,ConfigID, ...
        'Average module temperature T (^{\circ}C)','SDM Parameters vs Temperature');
end

%% FIGURE 6: T-G COVERAGE MAP
if any(isfinite(Tavg_C) & isfinite(Gavg_Wm2))
    figure('Name','DVF T-G Coverage','Color','w');
    valid = isfinite(Tavg_C) & isfinite(Gavg_Wm2);
    scatter(Gavg_Wm2(valid),Tavg_C(valid),70,'filled'); grid on; box on;
    xlabel('Average irradiance G (W/m^2)');
    ylabel('Average module temperature T (^\circC)');
    title('Measured DVF Environmental Coverage');
    ids = ConfigID(valid);
    x = Gavg_Wm2(valid); y = Tavg_C(valid);
    for k = 1:numel(x)
        text(x(k),y(k),"  "+ids(k),'FontWeight','bold');
    end
end

fprintf('\nDone.\n');
fprintf(['Next scientific step after enough DVF curves: compare independent fits with\n' ...
         'a constrained GLOBAL SDM fit (for example shared Rs/Rsh/a with Iph allowed\n' ...
         'to vary with irradiance). That is much stronger for parameter attribution.\n']);

%% ========================= LOCAL FUNCTIONS =============================
function [V,I] = readCorrectedIV(filePath)
    T = readtable(filePath,'VariableNamingRule','preserve');
    names = string(T.Properties.VariableNames);
    low = lower(names);
    vIdx = find(contains(low,'corrected potential'),1);
    iIdx = find(contains(low,'corrected current'),1);
    if isempty(vIdx) || isempty(iIdx)
        error('Could not find Corrected Potential/Current columns in %s.',filePath);
    end
    V = double(T{:,vIdx});
    I = double(T{:,iIdx});
end

function [V,I] = cleanIV(V,I)
    valid = isfinite(V) & isfinite(I);
    V = V(valid); I = I(valid);
    [V,ord] = sort(V);
    I = I(ord);
    [V,ia] = unique(V,'stable');
    I = I(ia);
end

function dc = extractDCmetrics(V,I)
    dc = struct('Voc',NaN,'Isc',NaN,'Vmp',NaN,'Imp',NaN,'Pmp',NaN);

    % Isc from local interpolation/extrapolation near V=0.
    n = min(8,numel(V));
    if n >= 2
        pp = polyfit(V(1:n),I(1:n),1);
        dc.Isc = polyval(pp,0);
    end

    % Voc from first positive-to-nonpositive current crossing.
    ix = find(I(1:end-1) >= 0 & I(2:end) <= 0,1,'first');
    if ~isempty(ix)
        v1=V(ix); v2=V(ix+1); i1=I(ix); i2=I(ix+1);
        dc.Voc = v1 + (0-i1)*(v2-v1)/(i2-i1);
    else
        % fallback: nearest-to-zero current in the high-voltage region
        [~,j] = min(abs(I));
        dc.Voc = V(j);
    end

    pos = I >= 0 & V >= 0;
    P = V(pos).*I(pos);
    Vp = V(pos); Ip = I(pos);
    if ~isempty(P)
        [dc.Pmp,j] = max(P);
        dc.Vmp = Vp(j);
        dc.Imp = Ip(j);
    end
end

function [pBest,stats] = fitSDM(V,I,Voc,Isc)
    % p = [Iph, I0, a, Rs, Rsh]
    Isc = max(Isc,1e-3);
    Voc = max(Voc,1);

    lb = [max(0.5*Isc,1e-4), 1e-20, 0.15, 1e-4, 5];
    ub = [max(2.0*Isc,0.2),     1e-3,  3.0,  5.0, 1e5];
    qlb = log10(lb); qub = log10(ub);

    a0 = min(max(Voc/36,0.30),1.2);
    Iph0 = max(1.01*Isc,1e-3);
    I00 = Iph0 / max(exp(min(Voc/a0,70))-1,1);
    I00 = min(max(I00,1e-18),1e-6);
    Rs0 = min(max(0.5,lb(4)*10),ub(4)/2);
    Rsh0 = min(max(300,lb(5)*2),ub(5)/2);

    starts = [ ...
        Iph0 I00       a0       Rs0       Rsh0; ...
        Iph0 I00       a0*0.8   Rs0*0.4   Rsh0*3; ...
        Iph0 I00       a0*1.2   Rs0*2.0   Rsh0/3; ...
        Iph0 I00*100   a0       Rs0*0.8   Rsh0*6];

    % Emphasise the knee/high-voltage region without ignoring the plateau.
    vv = V/max(Voc,eps);
    w = 1 + 3*vv.^4;
    scale = max(Isc,0.05);

    bestCost = inf;
    pBest = starts(1,:);
    method = "";

    hasOpt = exist('lsqnonlin','file') == 2;

    for s = 1:size(starts,1)
        p0 = min(max(starts(s,:),lb),ub);
        q0 = log10(p0);

        if hasOpt
            opts = optimoptions('lsqnonlin','Display','off', ...
                'MaxFunctionEvaluations',4000,'MaxIterations',800, ...
                'FunctionTolerance',1e-10,'StepTolerance',1e-10);
            fun = @(q) sqrt(w).*(sdmCurrent(V,10.^q)-I)/scale;
            try
                q = lsqnonlin(fun,q0,qlb,qub,opts);
                p = 10.^q;
                cost = sum(fun(q).^2);
                thisMethod = "lsqnonlin";
            catch
                [p,cost] = fitWithFminsearch(q0,qlb,qub,V,I,w,scale);
                thisMethod = "fminsearch fallback";
            end
        else
            [p,cost] = fitWithFminsearch(q0,qlb,qub,V,I,w,scale);
            thisMethod = "fminsearch";
        end

        if isfinite(cost) && cost < bestCost
            bestCost = cost;
            pBest = p;
            method = thisMethod;
        end
    end

    pred = sdmCurrent(V,pBest);
    resid = pred-I;
    stats.RMSE = sqrt(mean(resid.^2));
    stats.NRMSE_pct = 100*stats.RMSE/max(max(I)-min(I),eps);
    sst = sum((I-mean(I)).^2);
    stats.R2 = 1-sum(resid.^2)/max(sst,eps);
    stats.Method = method;
end

function [p,cost] = fitWithFminsearch(q0,qlb,qub,V,I,w,scale)
    z0 = qToZ(q0,qlb,qub);
    opts = optimset('Display','off','MaxFunEvals',5000,'MaxIter',1500, ...
        'TolX',1e-8,'TolFun',1e-10);
    obj = @(z) sum((sqrt(w).*(sdmCurrent(V,10.^zToQ(z,qlb,qub))-I)/scale).^2);
    z = fminsearch(obj,z0,opts);
    q = zToQ(z,qlb,qub);
    p = 10.^q;
    cost = obj(z);
end

function z = qToZ(q,lb,ub)
    r = (q-lb)./(ub-lb);
    r = min(max(r,1e-8),1-1e-8);
    z = log(r./(1-r));
end

function q = zToQ(z,lb,ub)
    r = 1./(1+exp(-z));
    q = lb + (ub-lb).*r;
end

function I = sdmCurrent(V,p)
    Iph=p(1); I0=p(2); a=p(3); Rs=p(4); Rsh=p(5);
    V = V(:);
    I = max(Iph - V./max(Rsh,eps),0);

    for it = 1:35
        arg = (V + I*Rs)/a;
        arg = min(max(arg,-60),80);
        ea = exp(arg);
        F = I - Iph + I0*(ea-1) + (V+I*Rs)/Rsh;
        dF = 1 + I0*ea*(Rs/a) + Rs/Rsh;
        step = F./dF;
        Inew = I-step;
        if max(abs(Inew-I),[],'omitnan') < 1e-10
            I = Inew; break;
        end
        I = Inew;
    end
end

function meta = lookupTrackerMetadata(T,runLabel)
    meta = struct('ConfigID',"",'Distance_cm',NaN,'Variac_V',NaN, ...
        'Fan',"",'Tavg_C',NaN,'Gavg_Wm2',NaN);
    try
        names = string(T.Properties.VariableNames);
        runCol = find(strcmpi(names,'DC Curve File'),1);
        if isempty(runCol), return; end
        vals = string(T{:,runCol});
        vals = erase(vals,'.xlsx');
        ix = find(strcmpi(strtrim(vals),strtrim(runLabel)),1);
        if isempty(ix), return; end

        meta.ConfigID = getTableValue(T,names,ix,'Config ID',"");
        meta.Distance_cm = getTableValue(T,names,ix,'Distance (cm)',NaN);
        meta.Variac_V = getTableValue(T,names,ix,'Variac (V)',NaN);
        meta.Fan = getTableValue(T,names,ix,'Fan',"");
        meta.Tavg_C = getTableValue(T,names,ix,'T Avg (°C)',NaN);
        meta.Gavg_Wm2 = getTableValue(T,names,ix,'G Avg (W/m²)',NaN);
    catch
        % Leave metadata blank rather than failing the analysis.
    end
end

function val = getTableValue(T,names,row,target,default)
    j = find(strcmpi(names,target),1);
    if isempty(j), val=default; return; end
    x = T{row,j};
    if iscell(x), x=x{1}; end
    if isnumeric(default)
        if isnumeric(x), val=double(x); else, val=str2double(string(x)); end
    else
        val=string(x);
    end
end

function plotParametersVsEnvironment(x,paramData,paramNames,ids,xLabelText,figTitle)
    figure('Name',figTitle,'Color','w');
    tl=tiledlayout(3,2,'TileSpacing','compact','Padding','compact');
    for j=1:5
        nexttile; hold on; grid on; box on;
        valid=isfinite(x) & isfinite(paramData{j});
        scatter(x(valid),paramData{j}(valid),55,'filled');
        xlabel(xLabelText); ylabel(paramNames{j});
        if j==2, set(gca,'YScale','log'); end
        xv=x(valid); yv=paramData{j}(valid); idv=ids(valid);
        for k=1:numel(xv)
            text(xv(k),yv(k),"  "+idv(k));
        end
    end
    nexttile; axis off;
    text(0,1,'Look for trends, not causal proof yet.','VerticalAlignment','top','FontWeight','bold');
    title(tl,figTitle);
end
