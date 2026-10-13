function result = PV_Research_Feature_Extractor_v0_1(rootFolder, crosswalkFile, outputFolder)
% PV_RESEARCH_FEATURE_EXTRACTOR_v0_1 -- structure-fix and alias-safe revision (2026-09-17)
% Replaces the previous file WITHOUT requiring changes to PVLabAnalyzer_v0_1_9.m.
% Fix: MATLAB disallows assigning structs with fields into struct([]).
% Reproducible, READ-ONLY, crosswalk-driven extraction of the validated
% September PV spectra, corresponding DC curves and 3x3 environment grids.
% Does not modify source files, the master log, or the crosswalk.
% Usage: result = PV_Research_Feature_Extractor_v0_1(root, crosswalk, output);
% With no arguments, prompts for the required inputs.
%
% IMPORTANT: Vbias below is calculated from each DC curve and NOMINAL OP
% definition. It is NOT an independently measured settled FRA DC voltage.
% True measured settled bias is left NaN until acquired from a valid source.
%
% Output: FRA_Features.csv, Raw_Spectra.csv, Environment_Features.csv,
%         Audit_Queue.csv, Research_Dataset.mat, Extraction_Notes.txt.

if nargin < 1 || isempty(rootFolder)
    rootFolder = uigetdir(pwd, 'Select top-level PV Impedance Project folder');
    if isequal(rootFolder,0), result = struct(); return; end
end
if nargin < 2 || isempty(crosswalkFile)
    [f,p] = uigetfile('*.xlsx', 'Select PV_Validated_FRA_Crosswalk_20260917.xlsx', rootFolder);
    if isequal(f,0), result = struct(); return; end
    crosswalkFile = fullfile(p,f);
end
if nargin < 3 || isempty(outputFolder)
    outputFolder = fullfile(rootFolder,'Processed Data','Research_Analysis_Phase1');
end
if ~isfolder(outputFolder), mkdir(outputFolder); end
rootFolder = char(rootFolder); crosswalkFile = char(crosswalkFile);
if ~isfolder(rootFolder)
    error('The selected project folder does not exist: %s',rootFolder);
end
if ~isfile(crosswalkFile)
    error('The selected crosswalk does not exist: %s',crosswalkFile);
end

C = readcell(crosswalkFile,'Sheet','Validated FRA links');
required = {'Date','Environment ID','Condition','Operating Point','Source Run', ...
    'DC filename','Raw FRA filename','Parameter filename','Environment workbook'};
for k=1:numel(required)
    if ~any(strcmp(string(C(1,:)),required{k}))
        error('Crosswalk is missing required column: %s', required{k});
    end
end
ix = zeros(1,numel(required));
for k=1:numel(required), ix(k)=find(strcmp(string(C(1,:)),required{k}),1); end

% Index all existing files once. Exact basenames only; never infer R01/R02.
allFiles = dir(fullfile(rootFolder,'**','*.xlsx'));
fullPaths = strings(numel(allFiles),1);
baseNames = strings(numel(allFiles),1);
for k=1:numel(allFiles)
    fullPaths(k) = string(fullfile(allFiles(k).folder,allFiles(k).name));
    baseNames(k) = string(allFiles(k).name);
end
% Preflight checks: write diagnostics before attempting any extraction.
% This is important because the old version did not write Audit_Queue.csv
% until AFTER a row succeeded, so a zero-row error concealed its own cause.
preflightPath=fullfile(outputFolder,'Extraction_Preflight.txt');
pfid=fopen(preflightPath,'w');
if pfid<0, error('Cannot write diagnostic folder: %s',outputFolder); end
fprintf(pfid,'PV research extractor - preflight diagnostics (struct-fix 2026-09-17)\n');
fprintf(pfid,'Project root: %s\nCrosswalk: %s\nIndexed XLSX files: %d\nCrosswalk rows: %d\n', ...
    rootFolder,crosswalkFile,numel(allFiles),size(C,1)-1);
matchCount=0;
for q=2:size(C,1)
    if isempty(C{q,ix(1)}), continue; end
    namesWanted=string(C(q,ix(6:8)));
    hits=[sum(strcmpi(baseNames,namesWanted(1))), ...
          sum(strcmpi(baseNames,namesWanted(2))), ...
          sum(strcmpi(baseNames,namesWanted(3)))];
    if all(hits>0), matchCount=matchCount+1; end
    if any(hits~=1)
        fprintf(pfid,'Crosswalk row %d: DC/FRA/PARAMS filename match counts = [%d,%d,%d]\n', ...
            q,hits(1),hits(2),hits(3));
        fprintf(pfid,'  %s | %s | %s\n',namesWanted(1),namesWanted(2),namesWanted(3));
    end
end
fprintf(pfid,'Rows with all three exact filenames present (duplicates included): %d\n',matchCount);
fprintf(pfid,'This exact-match count excludes explicitly approved OPX70/OPX filename aliases.\n');
fprintf(pfid,'Missing files are not assumed to be inside archives: extract archives into Raw Data first.\n');
fclose(pfid);
fprintf('PV extractor preflight: %d indexed XLSX files; %d/%d rows have all three exact filenames.\n', ...
    numel(allFiles),matchCount,size(C,1)-1);
fprintf('Preflight log: %s\n',preflightPath);

% Include the independently selected crosswalk only as a mapping source.
% MATLAB struct([]) is a no-field struct; assigning a populated struct to it
% throws 'Subscripted assignment between dissimilar structures'. Store
% individually in cells and concatenate only after successful extraction.
features = cell(0,1); spectra = table(); envRecords = cell(0,1);
audit = cell(0,5); envCache = containers.Map('KeyType','char','ValueType','any');
dcCache = containers.Map('KeyType','char','ValueType','any');

for j=2:size(C,1)
    if isempty(C{j,ix(1)}) || (isstring(C{j,ix(1)}) && ismissing(C{j,ix(1)}))
        continue;
    end
    dateTag = string(C{j,ix(1)}); envID=string(C{j,ix(2)});
    condition=string(C{j,ix(3)}); op=string(C{j,ix(4)});
    runID=string(C{j,ix(5)});
    dcName=string(C{j,ix(6)}); fraName=string(C{j,ix(7)});
    paramName=string(C{j,ix(8)}); envWorkbook=string(C{j,ix(9)});
    key=char(dateTag+"_"+runID+"_"+condition+"_"+op);
    try
        dcPath = resolveExact(baseNames,fullPaths,dcName);
        fraPath = resolveExact(baseNames,fullPaths,fraName);
        parPath = resolveExact(baseNames,fullPaths,paramName);
        if isempty(dcPath) || isempty(fraPath) || isempty(parPath)
            missing="";
            if isempty(dcPath), missing=missing+" DC"; end
            if isempty(fraPath), missing=missing+" FRA"; end
            if isempty(parPath), missing=missing+" PARAMS"; end
            audit(end+1,:)={key,'BLOCKED','MISSING_FILE',char(strtrim(missing)), ...
                'Provide original export; do not infer identity'}; %#ok<AGROW>
            continue;
        end
        if isKey(dcCache,dcPath)
            dc=dcCache(dcPath);
        else
            dc=extractDC(dcPath);
            dcCache(dcPath)=dc;
        end
        fr=extractFRA(fraPath);
        pa=extractParams(parPath);
        if isKey(envCache,char(envID))
            en=envCache(char(envID));
        else
            en=resolveEnvironment(envID,envWorkbook,baseNames,fullPaths);
            envCache(char(envID))=en;
            envRecords{end+1,1}=en; %#ok<AGROW>
        end
        [vNominal,nominalDescription] = nominalBias(op,dc);
        ibias=NaN; slope=NaN; diffR=NaN;
        if isfinite(vNominal)
            ibias=interp1(dc.V,dc.I,vNominal,'linear',NaN);
            slope=localSlope(dc.V,dc.I,vNominal);
            if isfinite(slope) && abs(slope)>1e-9, diffR=abs(1/slope); end
        end
        ff=NaN;
        if dc.Voc>0 && dc.Isc>0, ff=dc.Pmp/(dc.Voc*dc.Isc); end
        xi=NaN; ratio=NaN; relI=NaN; deltaVmp=NaN;
        if isfinite(vNominal) && dc.Voc>dc.Vmp
            xi=(vNominal-dc.Vmp)/(dc.Voc-dc.Vmp);
        end
        if isfinite(vNominal), ratio=vNominal/dc.Voc; deltaVmp=vNominal-dc.Vmp; end
        if isfinite(ibias) && dc.Isc>0, relI=ibias/dc.Isc; end
        flags=strings(0,1);
        if ~en.Valid, flags(end+1)="ENV_MISSING_OR_AMBIGUOUS"; end %#ok<AGROW>
        if fr.KKRealMean>1, flags(end+1)="KK_REAL_OVER_1_PERCENT_REVIEW"; end %#ok<AGROW>
        if fr.KKImagMean>5, flags(end+1)="KK_IMAG_OVER_5_PERCENT_REVIEW"; end %#ok<AGROW>
        if fr.N<40, flags(end+1)="SPECTRUM_SHORT_REVIEW"; end %#ok<AGROW>
        if ~isfinite(vNominal) || vNominal<0 || vNominal>dc.Voc
            flags(end+1)="NOMINAL_BIAS_INVALID_OR_UNKNOWN"; %#ok<AGROW>
        end
        if ~(isfinite(pa.CPEn) && pa.CPEn>=0 && pa.CPEn<=1)
            flags(end+1)="FIT_CPE_N_REVIEW"; %#ok<AGROW>
        end
        if ~(isfinite(pa.Y0) && pa.Y0>0)
            flags(end+1)="FIT_CPE_Y0_REVIEW"; %#ok<AGROW>
        end
        if dc.PowerPeakCount>1, flags(end+1)="POTENTIAL_MULTIPLE_PV_PEAKS_INSPECT"; end %#ok<AGROW>
        if ~isfinite(en.Tavg) || ~isfinite(en.Gavg)
            flags(end+1)="NO_ENVIRONMENT_SENSITIVITY"; %#ok<AGROW>
        end
        if ~isempty(flags)
            audit(end+1,:)={key,'REVIEW','QUALITY_OR_PROVENANCE',char(strjoin(flags,'; ')), ...
                'Review raw curve/metadata; thresholds are screening flags, not pass/fail'}; %#ok<AGROW>
        end
        f=struct();
        f.RunKey=string(key); f.Date=dateTag; f.EnvironmentID=envID;
        f.Condition=condition; f.OP=op; f.SourceRun=runID;
        f.DCFile=dcName; f.FRAFile=fraName; f.ParamsFile=paramName;
        f.EnvFile=en.SourceFile; f.EnvStatus=en.Status;
        f.Fan=en.Fan; f.Distance_cm=en.Distance; f.Variac_V=en.Variac;
        f.Tavg_C=en.Tavg; f.Tmin_C=en.Tmin; f.Tmax_C=en.Tmax;
        f.TsdSpatial_C=en.Tsd; f.TcvSpatial_pct=en.Tcv;
        f.Gavg_Wm2=en.Gavg; f.Gmin_Wm2=en.Gmin; f.Gmax_Wm2=en.Gmax;
        f.GsdSpatial_Wm2=en.Gsd; f.GcvSpatial_pct=en.Gcv;
        f.Voc_V=dc.Voc; f.Isc_A=dc.Isc; f.Vmp_V=dc.Vmp;
        f.Imp_A=dc.Imp; f.Pmp_W=dc.Pmp; f.FillFactor=ff;
        f.DCValidPointCount=dc.N; f.DCPowerPeakCountHeuristic=dc.PowerPeakCount;
        f.VbiasNominal_V=vNominal; f.VbiasNominalDefinition=nominalDescription;
        f.VbiasMeasured_V=NaN; f.IbiasMeasured_A=NaN;
        f.VbiasSource="DERIVED_NOMINAL_NOT_SETTLED";
        f.IbiasInterpolated_A=ibias; f.VoverVocNominal=ratio;
        f.DeltaVmpNominal_V=deltaVmp; f.XiNominal=xi; f.IoverIscNominal=relI;
        f.DIdVLocal_AperV=slope; f.RdiffLocal_Ohm=diffR;
        f.FRApointCount=fr.N; f.Fmin_Hz=fr.Fmin; f.Fmax_Hz=fr.Fmax;
        f.KKRealMeanAbs_pct=fr.KKRealMean; f.KKRealMedianAbs_pct=fr.KKRealMedian;
        f.KKRealP95Abs_pct=fr.KKRealP95;
        f.KKImagMeanAbs_pct=fr.KKImagMean; f.KKImagMedianAbs_pct=fr.KKImagMedian;
        f.KKImagP95Abs_pct=fr.KKImagP95;
        f.ZimagMax_Ohm=fr.ZimagPeak; f.Fpeak_Hz=fr.Fpeak;
        f.ZrealAtImagPeak_Ohm=fr.ZrealPeak;
        f.ZrealSpan_Ohm=fr.ZrealSpan;
        f.ZrealMin_Ohm=fr.ZrealMin; f.ZrealMax_Ohm=fr.ZrealMax;
        f.RsFit_Ohm=pa.Rs; f.RpFit_Ohm=pa.Rp;
        f.CPE_Y0=pa.Y0; f.CPE_n=pa.CPEn;
        f.FitStatus=pa.Status; f.QualityFlags=strjoin(flags,'; ');
        m=numel(fr.freq);
        single=table(repmat(string(key),m,1),fr.freq(:),fr.zre(:),fr.minusZim(:), ...
            fr.mag(:),fr.phase(:),fr.kkReal(:),fr.kkImag(:), ...
            'VariableNames',{'RunKey','Frequency_Hz','Zreal_Ohm','MinusZimag_Ohm', ...
            'Zmag_Ohm','ExportedMinusPhase_deg','KKRealError_pct','KKImagError_pct'});
        if isempty(spectra.Properties.VariableNames)
            spectra=single;
        else
            spectra=[spectra;single]; %#ok<AGROW>
        end
        features{end+1,1}=f; %#ok<AGROW>
        fprintf('  EXTRACTED %s\n',key);
    catch ME
        loc='';
        if ~isempty(ME.stack)
            loc=sprintf(' [%s line %d]',ME.stack(1).name,ME.stack(1).line);
        end
        details=[ME.message loc];
        audit(end+1,:)={key,'BLOCKED','EXTRACTION_ERROR',details, ...
            'Inspect exact source file, then rerun; do not substitute another run'}; %#ok<AGROW>
        fprintf(2,'  BLOCKED %s: %s\n',key,details);
    end
end
% Always write the audit, including when ZERO rows succeed.
if isempty(audit)
    AuditTable=cell2table(cell(0,5),'VariableNames', ...
        {'RunKey','Severity','Type','Details','RecommendedAction'});
else
    AuditTable=cell2table(audit,'VariableNames', ...
        {'RunKey','Severity','Type','Details','RecommendedAction'});
end
auditPath=fullfile(outputFolder,'Audit_Queue.csv');
writetable(AuditTable,auditPath);
if isempty(features)
    message='No rows extracted.';
    if ~isempty(audit)
        message=sprintf('%s First diagnostic: %s -- %s',message, ...
            char(string(audit{1,3})),char(string(audit{1,4})));
    end
    error('%s\nDetails saved to: %s\nPreflight: %s',message,auditPath,preflightPath);
end
FeatureTable=struct2table(vertcat(features{:}));
if isempty(envRecords)
    EnvTable=table();
else
    EnvTable=struct2table(vertcat(envRecords{:}));
end
writetable(FeatureTable,fullfile(outputFolder,'FRA_Features.csv'));
writetable(spectra,fullfile(outputFolder,'Raw_Spectra.csv'));
writetable(EnvTable,fullfile(outputFolder,'Environment_Features.csv'));
writetable(AuditTable,fullfile(outputFolder,'Audit_Queue.csv'));
save(fullfile(outputFolder,'Research_Dataset.mat'), ...
    'FeatureTable','spectra','EnvTable','AuditTable','crosswalkFile');
notes=fullfile(outputFolder,'Extraction_Notes.txt');
fid=fopen(notes,'w');
fprintf(fid,'PV research feature extraction, Phase 1 v0.1\n');
fprintf(fid,'Source crosswalk: %s\nData folder: %s\n',crosswalkFile,rootFolder);
fprintf(fid,'Linked rows: %d; extracted rows: %d; audit flags: %d\n', ...
    size(C,1)-1,height(FeatureTable),height(AuditTable));
fprintf(fid,'Run labels R01-R06 are not technical replicates unless experiment metadata confirms.\n');
fprintf(fid,'All VbiasNominal values are DERIVED FROM THE DC CURVE, not measured FRA settled V.\n');
fprintf(fid,'Environment grids are spatial snapshots, not independent temporal replicates.\n');
fprintf(fid,'Index sheet and internal environment ID may contain stale template labels; source sheet NAME controls identity.\n');
fprintf(fid,'Do not call fit Rp/Rs the same parameters as DC single-diode Rsh/Rs.\n');
fprintf(fid,'P95 K-K and >1%% / >5%% error flags are exploratory screens, never sole validation.\n');
fprintf(fid,'Power-peak count is noise-sensitive, inspect original P-V before invoking bypass effects.\n');
fprintf(fid,'No inferential statistics or classifier accuracy can be claimed from unreplicated states.\n');
fclose(fid);
result=struct('Features',FeatureTable,'Spectra',spectra, ...
    'Environments',EnvTable,'Audit',AuditTable,'OutputFolder',string(outputFolder));
fprintf('\nPhase 1: extracted %d/%d linked FRA records. Audit flags: %d.\n', ...
    height(FeatureTable),size(C,1)-1,height(AuditTable));
fprintf('Saved all results to: %s\n',outputFolder);
end

function path=resolveExact(names,paths,target)
    % Exact filename first, then safe naming aliases ONLY. Never infer a
    % different date, sample, R number, or experimental condition.
    target=string(target);
    hits=find(strcmpi(names,target));
    if isempty(hits)
        % Finder/macOS suffix '(1)' is not part of the Nova run identity.
        normalized=regexprep(names,'\(\d+\)(?=\.xlsx$)','');
        hits=find(strcmpi(normalized,target));
    end
    if isempty(hits)
        % Documented discrepancy: crosswalk encodes OPX70, Nova filenames
        % encode OPX for the same run. Match date, sample, mode and R tag.
        opAlias=regexprep(target,'_FRA_POT_OPX70_','_FRA_POT_OPX_');
        if opAlias~=target
            normalized=regexprep(names,'\(\d+\)(?=\.xlsx$)','');
            hits=find(strcmpi(normalized,opAlias));
        end
    end
    if isempty(hits), path=''; return; end
    if numel(hits)>1
        base=char(paths(hits(1)));
        for q=2:numel(hits)
            candidate=char(paths(hits(q)));
            if ~filesHaveSameBytes(base,candidate)
                listing=strjoin(paths(hits),newline);
                error('Conflicting copies for filename %s; cannot choose safely. Files:\n%s', ...
                    target,char(listing));
            end
        end
        % If truly byte-identical, prefer the original Raw Data directory.
        raw=find(contains(lower(paths(hits)),[filesep 'raw data' filesep]),1);
        if ~isempty(raw)
            path=char(paths(hits(raw)));
        else
            path=char(paths(hits(1)));
        end
    else
        path=char(paths(hits));
    end
    if ~strcmpi(string(extractBasename(path)),target)
        fprintf('    File alias verified: %s -> %s\n',char(target),extractBasename(path));
    end
end

function name=extractBasename(path)
    [~,stem,ext]=fileparts(path);
    name=[stem ext];
end

function same=filesHaveSameBytes(a,b)
    % Exact byte comparison, not merely equal filenames or equal sizes.
    da=dir(a); db=dir(b);
    same=false;
    if isempty(da)||isempty(db)||da.bytes~=db.bytes, return; end
    fa=fopen(a,'rb'); fb=fopen(b,'rb');
    if fa<0||fb<0
        if fa>=0,fclose(fa);end
        if fb>=0,fclose(fb);end
        error('Could not open duplicate workbook for verification: %s / %s',a,b);
    end
    cleaner=onCleanup(@()closeBoth(fa,fb)); %#ok<NASGU>
    while true
        aa=fread(fa,65536,'*uint8');bb=fread(fb,65536,'*uint8');
        if ~isequal(aa,bb),return;end
        if isempty(aa),break;end
    end
    same=true;
end

function closeBoth(a,b)
    fclose(a);fclose(b);
end

function out=extractDC(path)
    R=readcell(path,'Sheet',1);
    h=string(R(1,:));
    vcol=find(h=="Corrected Potential (V)",1);
    icol=find(h=="Corrected Current (A)",1);
    if isempty(vcol)||isempty(icol), error('DC corrected V/I columns missing: %s',path); end
    v=nan(size(R,1)-1,1); i=v;
    for k=2:size(R,1)
        v(k-1)=asNumber(R{k,vcol}); i(k-1)=asNumber(R{k,icol});
    end
    good=isfinite(v)&isfinite(i);
    v=v(good);i=i(good);
    [v,ord]=sort(v);i=i(ord);
    [v,uniqueID]=unique(v,'stable');i=i(uniqueID);
    if numel(v)<20, error('Insufficient DC points: %s',path); end
    zeroCross=find(i(1:end-1).*i(2:end)<=0 & i(1:end-1)~=i(2:end));
    if isempty(zeroCross), error('No open-circuit current crossing in %s',path); end
    k=zeroCross(end);
    voc=v(k)-i(k)*(v(k+1)-v(k))/(i(k+1)-i(k));
    valid=v>=0&i>=0&v<=voc;
    if nnz(valid)<15, error('Too few positive-generating DC points: %s',path); end
    vv=v(valid);ii=i(valid);pp=vv.*ii;
    [pmp,im]=max(pp);vmp=vv(im);imp=ii(im);
    near=vv<=min(max(vv)*0.03,0.65);
    if nnz(near)<5, near=false(size(vv));near(1:min(20,numel(vv)))=true; end
    coeff=polyfit(vv(near),ii(near),1);
    isc=polyval(coeff,0);
    if isc<=0, isc=interp1(vv,ii,0,'linear','extrap'); end
    % Conservative prominence heuristic; informational flag, not bypass diagnosis.
    peaks=find(pp(2:end-1)>pp(1:end-2) & pp(2:end-1)>=pp(3:end))+1;
    peaks=peaks(pp(peaks)>0.90*pmp);
    strong=0; prev=-Inf;
    for k=1:numel(peaks)
        if vv(peaks(k))-prev>0.4, strong=strong+1;prev=vv(peaks(k)); end
    end
    out=struct('V',v,'I',i,'Voc',voc,'Isc',isc,'Vmp',vmp, ...
        'Imp',imp,'Pmp',pmp,'N',numel(v),'PowerPeakCount',strong);
end

function slope=localSlope(v,i,target)
    slope=NaN;
    if ~isfinite(target)||target<min(v)||target>max(v), return; end
    [~,k]=min(abs(v-target));
    ids=max(1,k-9):min(numel(v),k+9);
    if numel(ids)<5, return; end
    pp=polyfit(v(ids),i(ids),1);slope=pp(1);
end

function out=extractFRA(path)
    C=readcell(path,'Sheet',1);h=string(C(1,:));
    names={"Frequency (Hz)","Z' (Ω)","-Z'' (Ω)","Z (Ω)", ...
        "-Phase (°)","Error Z' (%)","Error Z'' (%)"};
    ids=zeros(1,numel(names));
    for z=1:numel(names)
        col=find(h==names{z},1);
        if isempty(col),error('FRA column missing %s: %s',names{z},path);end
        ids(z)=col;
    end
    A=nan(size(C,1)-1,numel(ids));
    for k=2:size(C,1)
        for z=1:numel(ids), A(k-1,z)=asNumber(C{k,ids(z)}); end
    end
    good=isfinite(A(:,1))&isfinite(A(:,2))&isfinite(A(:,3))&A(:,1)>0;
    A=A(good,:);[~,order]=sort(A(:,1));A=A(order,:);
    if size(A,1)<10,error('Too few valid FRA rows: %s',path);end
    o=struct();o.freq=A(:,1);o.zre=A(:,2);o.minusZim=A(:,3);
    o.mag=A(:,4);o.phase=A(:,5);o.kkReal=A(:,6);o.kkImag=A(:,7);
    o.N=size(A,1);o.Fmin=min(o.freq);o.Fmax=max(o.freq);
    absR=abs(o.kkReal(isfinite(o.kkReal)));
    absI=abs(o.kkImag(isfinite(o.kkImag)));
    o.KKRealMean=mean(absR);o.KKRealMedian=median(absR);
    o.KKRealP95=percentile95(absR);
    o.KKImagMean=mean(absI);o.KKImagMedian=median(absI);
    o.KKImagP95=percentile95(absI);
    region=o.freq>=1&o.freq<=10000&o.minusZim>=0;
    if ~any(region),region=o.minusZim>=0;end
    if ~any(region),error('No positive capacitive imaginary impedance: %s',path);end
    z=o.minusZim(region);fz=o.freq(region);rx=o.zre(region);
    [o.ZimagPeak,ind]=max(z);o.Fpeak=fz(ind);o.ZrealPeak=rx(ind);
    o.ZrealSpan=max(rx)-min(rx);o.ZrealMin=min(rx);o.ZrealMax=max(rx);
    out=o;
end

function out=extractParams(path)
    C=readcell(path,'Sheet',1);h=string(C(1,:));
    keys={"Rp.R (Ω)","Rs.R (Ω)","CPE.Y0 (F)","CPE.N"};
    vals=nan(1,4);
    for j=1:numel(keys)
        k=find(h==keys{j},1);
        if ~isempty(k)&&size(C,1)>1, vals(j)=asNumber(C{2,k});end
    end
    out=struct('Rp',vals(1),'Rs',vals(2),'Y0',vals(3),'CPEn',vals(4), ...
        'Status',"Nova circle fit exported; topology/identifiability not independently verified");
end

function [v,def]=nominalBias(op,dc)
    op=upper(string(op));
    switch op
        case {'OPB','0P9VOC'},v=0.9*dc.Voc;def="0.90*Voc";
        case {'OPF','FIXED20'},v=20;def="fixed 20 V";
        case {'OPX70','OPX'},v=dc.Vmp+0.70*(dc.Voc-dc.Vmp);def="Vmp+0.70*(Voc-Vmp)";
        case 'OPX30',v=dc.Vmp+0.30*(dc.Voc-dc.Vmp);def="Vmp+0.30*(Voc-Vmp)";
        otherwise,v=NaN;def="undefined in crosswalk; do not infer";
    end
end

function en=resolveEnvironment(id,preferred,names,paths)
    en=struct('ID',string(id),'SourceFile',"",'Status',"MISSING",'Valid',false, ...
        'Fan',"",'Distance',NaN,'Variac',NaN,'Tavg',NaN,'Tmin',NaN, ...
        'Tmax',NaN,'Tsd',NaN,'Tcv',NaN,'Gavg',NaN,'Gmin',NaN, ...
        'Gmax',NaN,'Gsd',NaN,'Gcv',NaN);
    % Explicitly prefer crosswalk workbook, with Mac-vs-upload '(1)' alias.
    primary=string(preferred);
    primary=regexprep(primary,'\(\d+\)(?=\.xlsx$)','');
    hit=find(strcmpi(names,primary));
    others=find(contains(lower(names),'environment') & endsWith(lower(names),'.xlsx'));
    candidates=unique([hit(:);others(:)],'stable');
    % Cell storage avoids MATLAB dissimilar-structure assignment and allows
    % adding RawT/RawG only to temporary comparison records.
    match=cell(0,1);
    for k=1:numel(candidates)
        p=char(paths(candidates(k)));
        try
            sn=string(sheetnames(p));
            if ~any(sn==string(id)),continue;end
            c=readcell(p,'Sheet',char(id),'Range','A1:O13');
            t=zeros(3,3);g=t;
            for row=1:3
                for col=1:3
                    t(row,col)=asNumber(c{row+3,col+1});
                    g(row,col)=asNumber(c{row+3,col+9});
                end
            end
            if ~all(isfinite(t(:)))||~all(isfinite(g(:))),continue;end
            next=en;next.Valid=true;next.Status="SHEET_MATCH_GRID_READ";
            next.SourceFile=string(paths(candidates(k)));
            next.Tavg=mean(t(:));next.Tmin=min(t(:));next.Tmax=max(t(:));
            next.Tsd=std(t(:),0);next.Tcv=100*next.Tsd/next.Tavg;
            next.Gavg=mean(g(:));next.Gmin=min(g(:));next.Gmax=max(g(:));
            next.Gsd=std(g(:),0);next.Gcv=100*next.Gsd/next.Gavg;
            next.Fan=string(c{11,8});
            next.Variac=asNumber(c{12,2});next.Distance=asNumber(c{13,2});
            next.RawT=t;next.RawG=g;
            match{end+1,1}=next; %#ok<AGROW>
        catch
            continue; % Another candidate may hold the exact uncorrupted sheet.
        end
    end
    if isempty(match),return;end
    for k=2:numel(match)
        if any(abs(match{k}.RawT(:)-match{1}.RawT(:))>0.01)|| ...
           any(abs(match{k}.RawG(:)-match{1}.RawG(:))>0.01)
            en.Status="AMBIGUOUS_ENV_GRID_CONFLICT";
            en.SourceFile="More than one workbook contains conflicting grids: inspect";
            return;
        end
    end
    en=rmfield(match{1},{'RawT','RawG'});
    if numel(match)>1, en.Status="GRID_VERIFIED_ACROSS_DUPLICATE_WORKBOOKS";end
    en.SourceFile=string(match{1}.SourceFile);
end

function v=asNumber(x)
    v=NaN;
    if isnumeric(x)&&isscalar(x),v=double(x);
    elseif ischar(x)||isstring(x)
        v=str2double(string(x));
    end
end

function value=percentile95(x)
    x=sort(x(isfinite(x)));
    if isempty(x), value=NaN;return;end
    pos=1+0.95*(numel(x)-1);
    lo=floor(pos);hi=ceil(pos);
    value=x(lo)+(pos-lo)*(x(hi)-x(lo));
end
