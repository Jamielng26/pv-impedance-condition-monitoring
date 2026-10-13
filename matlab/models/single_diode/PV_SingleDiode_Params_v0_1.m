%% PV_SingleDiode_Params_v0_1.m
% Provisional single-diode module parameters for the Goldstone GSM80W.
%
% Calibration basis:
%   20260821_GSM_HLT_DC_R01.xlsx
%
% IMPORTANT:
% These are empirical parameters fitted to ONE measured laboratory I-V
% curve. They are intended as a starting single-diode model for model
% validation and Simulink implementation. Do not treat them as immutable
% manufacturer parameters.
%
% The model equation is:
%
% I = Iph - I0*(exp((V + I*Rs)/a) - 1) - (V + I*Rs)/Rsh
%
% where a is the effective module diode-voltage factor (n*Ns*Vt).
%
% The Day-4 measured curve used for the provisional fit had approximately:
%   Voc = 20.914 V
%   Isc = 0.700 A
%   Vmp = 17.969 V
%   Imp = 0.662 A
%   Pmp = 11.889 W
%
% A least-squares single-diode fit to the full measured curve produced the
% provisional values below. The single-diode model cannot reproduce every
% local irregularity/noise feature of the measured halogen-illuminated curve.

clear PVSDM

PVSDM.Panel = "Goldstone GSM80W";
PVSDM.CalibrationFile = "20260821_GSM_HLT_DC_R01.xlsx";

% Provisional fitted parameters
PVSDM.Iph_ref = 0.7116000346;    % A
PVSDM.I0_ref  = 1.0e-16;        % A
PVSDM.a_ref   = 0.5742995208;   % V, effective n*Ns*Vt
PVSDM.Rs      = 1.3833604868;   % ohm
PVSDM.Rsh     = 362.5924505;    % ohm

% Simulink voltage-sweep settings
PVSDM.Vmax = 21.2;              % V
PVSDM.SweepTime = 10;           % s

% Irradiance multiplier.
% 1.0 means "the illumination condition used to calibrate the model".
% It is NOT yet an absolute W/m^2 calibration.
PVSDM.Gpu = 1.0;

% Numerical solver settings used inside the MATLAB Function block
PVSDM.NewtonIterations = 20;
PVSDM.ExpLimit = 50;

% Reference measured values, useful for report/validation plots
PVSDM.MeasuredVoc = 20.9137;
PVSDM.MeasuredIsc = 0.6998;
PVSDM.MeasuredVmp = 17.9688;
PVSDM.MeasuredImp = 0.6616;
PVSDM.MeasuredPmp = 11.8885;
