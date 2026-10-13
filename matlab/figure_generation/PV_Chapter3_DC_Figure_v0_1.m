function PV_Chapter3_DC_Figure_v0_1(dcFile, outFolder)
% Reproduces the measured I-V / P-V example used in Chapter 3 Section 3.2.
% The source must be the original NOVA DC export for 2026-09-09 R04,
% healthy, 60 cm / 150 V / fan ON. No single-diode or smoothing fit is used.
% Usage: PV_Chapter3_DC_Figure_v0_1
%    or: PV_Chapter3_DC_Figure_v0_1('/path/to/DC_R04.xlsx', '/path/to/figures')

if nargin < 1 || isempty(dcFile)
    [n,p] = uigetfile('*.xlsx', 'Select 20260909_GSM_HLT_DC_R04.xlsx');
    if isequal(n,0), return; end
    dcFile = fullfile(p,n);
end
if nargin < 2 || isempty(outFolder)
    outFolder = fullfile(fileparts(dcFile),'Chapter3_Figures');
end
if ~exist(outFolder,'dir'), mkdir(outFolder); end

% Nova spreadsheet columns: (3) WE(1).Current (A),
% (7) Corrected Potential (V), already including the x10 multiplier.
M = readmatrix(dcFile);
assert(size(M,2)>=7, 'Expected the original NOVA DC export (at least 7 columns).');
V = M(:,7); I = -M(:,3);
valid = isfinite(V) & isfinite(I);
V=V(valid); I=I(valid);
[V,idx]=sort(V); I=I(idx);
assert(numel(V)>100 && max(V)>15 && min(V)<1, ...
    'Voltage units or spreadsheet columns appear incorrect; check the export.');

% Locate the measured MPP, without including negative-current extension.
physical=(V>=0 & I>=0);
Vpos=V(physical); Ipos=I(physical); Ppos=Vpos.*Ipos;
[Pmp,im]=max(Ppos); Vmp=Vpos(im); Imp=Ipos(im);

% Interpolate the final positive-to-negative current crossing for Voc.
zc=find(I(1:end-1)>=0 & I(2:end)<0);
assert(~isempty(zc), 'No zero-current crossing found in the DC export.');
k=zc(end);
Voc=V(k)-I(k)*(V(k+1)-V(k))/(I(k+1)-I(k));

% Estimate Isc by regression over first 1 V, not from model fitting.
near0=V>=0 & V<=1;
assert(nnz(near0)>8,'Not enough short-circuit-region DC points.');
p=polyfit(V(near0), I(near0),1);
Isc=polyval(p,0);

% Restrict presentation to the generating quadrant, preserve full raw export.
plotmask=(V>=0 & V<=Voc & I>=0);
Vp=V(plotmask); Ip=I(plotmask); Pp=Vp.*Ip;
ix=unique(round(linspace(1,numel(Vp),23)));

f=figure('Color','w','Units','pixels','Position',[100 100 1160 440]);
t=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');

ax1=nexttile(t);
plot(Vp,Ip,'-','LineWidth',1.3); hold on;
plot(Vp(ix),Ip(ix),'o','MarkerSize',3.4,'LineWidth',0.7);
plot(Vmp,Imp,'s','MarkerSize',6,'MarkerFaceColor','w','LineWidth',1.2);
plot(Voc,0,'d','MarkerSize',6,'MarkerFaceColor','w','LineWidth',1.2);
xline(Vmp,':','HandleVisibility','off');
xline(Voc,':','HandleVisibility','off');
xlim([0 max(22.1,ceil(Voc*1.02))]); ylim([0 max(Isc,Imp)*1.14]);
xlabel('Corrected module voltage, V (V)'); ylabel('Module current, I (A)');
title('(a) Measured I--V characteristic');
legend({'Measured trace','Representative raw points','MPP','Open circuit'}, ...
    'Location','southwest','FontSize',8,'Box','off');
grid on; box on;

ax2=nexttile(t);
plot(Vp,Pp,'-','LineWidth',1.3); hold on;
plot(Vp(ix),Pp(ix),'o','MarkerSize',3.4,'LineWidth',0.7);
plot(Vmp,Pmp,'s','MarkerSize',6,'MarkerFaceColor','w','LineWidth',1.2);
xline(Vmp,':','HandleVisibility','off');
xlim([0 max(22.1,ceil(Voc*1.02))]); ylim([0 Pmp*1.13]);
xlabel('Corrected module voltage, V (V)'); ylabel('Module output power, P (W)');
title('(b) P--V and measured maximum-power point');
legend({'Measured-derived P=VI','Representative raw points','MPP'}, ...
    'Location','northwest','FontSize',8,'Box','off');
grid on; box on;

set([ax1 ax2], 'FontName','Helvetica','FontSize',9,'LineWidth',0.75);
base=fullfile(outFolder,'ch3_dc_example_iv_pv');
exportgraphics(f,[base '.pdf'],'ContentType','vector');
exportgraphics(f,[base '.png'],'Resolution',300);
fprintf('Source: %s\nVoc=%.4f V, Isc≈%.4f A, Vmp=%.4f V, Imp=%.4f A, Pmp=%.4f W\n', ...
    dcFile,Voc,Isc,Vmp,Imp,Pmp);
fprintf('Figure exports: %s.pdf and .png\n',base);
end
