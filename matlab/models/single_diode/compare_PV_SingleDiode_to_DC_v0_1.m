%% compare_PV_SingleDiode_to_DC_v0_1.m
% Compares the provisional single-diode model against a Nova DC export.
%
% Default file:
%   20260821_GSM_HLT_DC_R01.xlsx
%
% The script expects:
%   Corrected Potential (V)
%   Corrected Current (A)

clear; clc;
run('PV_SingleDiode_Params_v0_1.m');

dcFile = PVSDM.CalibrationFile;

if ~isfile(dcFile)
    [f,p] = uigetfile('*.xlsx','Select Nova DC I-V export');
    if isequal(f,0)
        error('No DC file selected.');
    end
    dcFile = fullfile(p,f);
end

T = readtable(dcFile,'VariableNamingRule','preserve');

vName = 'Corrected Potential (V)';
iName = 'Corrected Current (A)';

if ~ismember(vName,T.Properties.VariableNames) || ~ismember(iName,T.Properties.VariableNames)
    error('Required corrected V/I columns were not found in the selected workbook.');
end

V = double(T.(vName));
Imeas = double(T.(iName));

good = isfinite(V) & isfinite(Imeas);
V = V(good);
Imeas = Imeas(good);

[V,ord] = sort(V);
Imeas = Imeas(ord);

Imodel = zeros(size(V));
previousI = PVSDM.Iph_ref*PVSDM.Gpu;

for m = 1:numel(V)
    I = previousI;
    Iph = max(0,PVSDM.Iph_ref*PVSDM.Gpu);

    for k = 1:PVSDM.NewtonIterations
        arg = (V(m) + I*PVSDM.Rs)/max(PVSDM.a_ref,1e-9);
        arg = min(max(arg,-PVSDM.ExpLimit),PVSDM.ExpLimit);
        ea = exp(arg);

        F = I - Iph + PVSDM.I0_ref*(ea-1) + ...
            (V(m)+I*PVSDM.Rs)/max(PVSDM.Rsh,1e-9);

        dF = 1 + PVSDM.I0_ref*ea*(PVSDM.Rs/max(PVSDM.a_ref,1e-9)) + ...
            PVSDM.Rs/max(PVSDM.Rsh,1e-9);

        step = F/max(dF,1e-12);
        step = min(max(step,-0.5),0.5);
        I = I-step;
    end

    Imodel(m)=I;
    previousI=I;
end

Pmeas = V.*Imeas;
Pmodel = V.*Imodel;

rmseI = sqrt(mean((Imeas-Imodel).^2,'omitnan'));

[Pmp_meas,km] = max(Pmeas);
[Pmp_model,ks] = max(Pmodel);

fprintf('\nSingle-Diode Validation\n');
fprintf('-----------------------\n');
fprintf('DC file: %s\n',dcFile);
fprintf('Current RMSE: %.5f A\n',rmseI);
fprintf('Measured MPP: Vmp = %.3f V, Imp = %.3f A, Pmp = %.3f W\n', ...
    V(km),Imeas(km),Pmp_meas);
fprintf('Model MPP:    Vmp = %.3f V, Imp = %.3f A, Pmp = %.3f W\n\n', ...
    V(ks),Imodel(ks),Pmp_model);

figure('Name','Single-Diode Model Validation - I-V');
plot(V,Imeas,'LineWidth',1.5); hold on;
plot(V,Imodel,'--','LineWidth',1.5);
grid on;
xlabel('Module Voltage (V)');
ylabel('Module Current (A)');
title('Measured vs Single-Diode I-V Curve');
legend('Measured','Single-diode model','Location','best');

figure('Name','Single-Diode Model Validation - P-V');
plot(V,Pmeas,'LineWidth',1.5); hold on;
plot(V,Pmodel,'--','LineWidth',1.5);
grid on;
xlabel('Module Voltage (V)');
ylabel('Module Power (W)');
title('Measured vs Single-Diode P-V Curve');
legend('Measured','Single-diode model','Location','best');
