function results = PV_Chapter3_FRA_Figure_v0_1(dataFolder)
% Generates Chapter 3 representative measured/fitted Nyquist figure.
% Source is Phase 1 Raw_Spectra.csv (exported with validated crosswalk).
% Requires base MATLAB with exportgraphics; no fitting toolbox required.
% Usage: PV_Chapter3_FRA_Figure_v0_1('/path/to/Research_Analysis_Phase1')
% Does not modify existing raw data, research dataset or Nova fit exports.
if nargin<1 || strlength(string(dataFolder))==0
    dataFolder=uigetdir(pwd,'Select Research_Analysis_Phase1 folder');
    if isequal(dataFolder,0), error('No dataset folder selected.'); end
end
src=fullfile(dataFolder,'Raw_Spectra.csv');
if ~isfile(src),src=fullfile(dataFolder,'Raw_Spectra(1).csv');end
assert(isfile(src),'Raw_Spectra.csv was not found in %s',dataFolder);
T=readtable(src,'TextType','string');
k="20260909_R04_HLT_OPF";
S=sortrows(T(T.RunKey==k,:),'Frequency_Hz');
assert(height(S)==51,'Expected 51 measured frequencies for %s, got %d.',k,height(S));
f=double(S.Frequency_Hz);
z=double(S.Zreal_Ohm)-1i*double(S.MinusZimag_Ohm);
cap=(f>=1 & f<=2000 & -imag(z)>=0 & isfinite(real(z)) & isfinite(imag(z)));
ff=f(cap);zz=z(cap);
assert(numel(ff)>=20,'Too few valid capacitive data points.');
[~,pk]=max(-imag(zz));
rs0=min(real(zz));rp0=max(real(zz))-rs0;tau0=1/(2*pi*ff(pk));
% Transform to positive Rs, Rp, tau and 0.6<n<1.
start=[log(rs0),log(rp0),log(tau0),log((0.95-0.6)/(1-0.95))];
starts=[start;start+[.1,-.1,.2,-.4];start+[-.1,.1,-.2,.4]];
opt=optimset('Display','off','MaxFunEvals',30000,'MaxIter',20000,...
    'TolX',1e-11,'TolFun',1e-14);
best=Inf;p=[];
for j=1:size(starts,1)
    [u,v]=fminsearch(@(q)objective(q,ff,zz),starts(j,:),opt);
    if isfinite(v) && v<best, best=v; p=unpack(u); end
end
assert(~isempty(p),'No valid fit found.');
err=randles(ff,p)-zz;
rmse=sqrt(mean(abs(err).^2)); peak=max(-imag(zz));
relPct=100*rmse/peak;
assert(relPct<=10,'Fit quality check failed: %.2f%% of measured arc peak.',relPct);
fFine=logspace(log10(min(ff)),log10(max(ff)),500).';
zFine=randles(fFine,p);
out=fullfile(dataFolder,'Chapter3_FRA_Figure');
if ~isfolder(out),mkdir(out);end
fig=figure('Color','w','Units','centimeters','Position',[2 2 16.5 11]);
ax=axes(fig);hold(ax,'on');
plot(ax,real(zFine),-imag(zFine),'-','LineWidth',1.8,...
    'Color',[.15 .39 .66], 'DisplayName','Independent Randles-CPE fit (1 Hz-2 kHz)');
plot(ax,real(zz),-imag(zz),'o','MarkerSize',4.4,'LineStyle','none',...
    'Color',[.71 .36 .13],'DisplayName','Measured FRA');
set(ax,'FontName','Arial','FontSize',9,'LineWidth',.8,'TickDir','out');
grid(ax,'on');box(ax,'on');
xlabel(ax,'Real impedance, Z'' (\Omega)');
ylabel(ax,'Negative imaginary impedance, -Z'''' (\Omega)');
ylim(ax,[0 1.1*max(-imag([zz;zFine]))]);
axis(ax,'equal');
legend(ax,'Location','northoutside','Orientation','horizontal','Box','off');
exportgraphics(fig,fullfile(out,'ch3_fra_example_nyquist_fit.pdf'),'ContentType','vector');
exportgraphics(fig,fullfile(out,'ch3_fra_example_nyquist_fit.png'),'Resolution',300);
close(fig);
results=struct('RunKey',k,'Source',src,'Rs_Ohm',p(1),'Rp_Ohm',p(2),...
    'Tau_s',p(3),'n',p(4),'Q',p(3)^p(4)/p(2),'RMSE_Ohm',rmse,...
    'RMSE_pct_of_arc_peak',relPct,'N_fit',numel(ff),'OutputFolder',out);
save(fullfile(out,'Ch3_Representative_Fit_Diagnostics.mat'),'results');
fid=fopen(fullfile(out,'Fit_Diagnostics.txt'),'w');
if fid>0
    fprintf(fid,'Run: %s\nSource: %s\nFit points: %d\n',k,src,numel(ff));
    fprintf(fid,'Rs %.8g ohm; Rp %.8g ohm; tau %.8g s; n %.8g; Q %.8g\n',...
        p(1),p(2),p(3),p(4),results.Q);
    fprintf(fid,'Complex RMSE %.8g ohm (%.3f%% of measured arc peak).\n',rmse,relPct);
    fprintf(fid,'Independent illustration fit only; original Nova parameters unchanged.\n');
    fclose(fid);
end
fprintf('Figure exported: %s (fit RMSE %.3f mOhm; %.2f%% arc peak).\n',out,1e3*rmse,relPct);
end
function val=objective(u,f,z)
p=unpack(u);
if any(~isfinite(p)) || p(1)<.001 || p(1)>.2 || p(2)<.005 || ...
        p(2)>5 || p(3)<1e-6 || p(3)>1 || p(4)<.6
    val=1e12;return
end
err=randles(f,p)-z;
val=mean(abs(err).^2);
if ~isfinite(val),val=1e12;end
end
function p=unpack(u)
t=max(-40,min(40,u(4)));
p=[exp(u(1)),exp(u(2)),exp(u(3)),.6+.4/(1+exp(-t))];
end
function z=randles(f,p)
z=p(1)+p(2)./(1+(1i*2*pi*f*p(3)).^p(4));
end
