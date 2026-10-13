PV Single-Diode Simulink Model v0.1
===================================

Purpose
-------
This is the minimum steady-state PV single-diode model requested for the
PB02 project. It is intended to do something useful rather than exist only
as a diagram:

  1. reproduce the broad measured I-V / P-V behaviour of the GSM80W panel;
  2. validate that experimental DC curves are physically plausible;
  3. provide a model reference when choosing FRA DC operating points;
  4. later provide a baseline for studying irradiance / temperature changes.

Calibration
-----------
The initial empirical parameters were fitted to:
    20260821_GSM_HLT_DC_R01.xlsx

Approximate measured curve:
    Voc = 20.914 V
    Isc = 0.700 A
    Vmp = 17.969 V
    Imp = 0.662 A
    Pmp = 11.889 W

Files
-----
PV_SingleDiode_Params_v0_1.m
    Holds the provisional fitted single-diode parameters.

build_PV_SingleDiode_Simulink_v0_1.m
    Programmatically builds and saves:
        PV_SingleDiode_Model_v0_1.slx

compare_PV_SingleDiode_to_DC_v0_1.m
    Reads a Nova DC export and plots measured vs model I-V and P-V curves.

How to use
----------
Put all files in the same MATLAB Current Folder.

1. Copy the relevant DC .xlsx export into the same folder.
2. Run:
       build_PV_SingleDiode_Simulink_v0_1
3. MATLAB creates:
       PV_SingleDiode_Model_v0_1.slx
4. Run the Simulink model.
5. To compare against measured DC data, run:
       compare_PV_SingleDiode_to_DC_v0_1

Model equation
--------------
    I = Iph - I0[exp((V + I*Rs)/a)-1] - (V + I*Rs)/Rsh

where:
    Iph = photocurrent
    I0  = diode reverse saturation current
    a   = effective module diode-voltage factor (n Ns Vt)
    Rs  = series resistance
    Rsh = shunt resistance

Important limitation
--------------------
v0.1 is calibrated to one laboratory I-V curve. Its irradiance multiplier
scales photocurrent only and is therefore a provisional qualitative control,
not yet a validated W/m^2 model.

Once healthy I-V curves have been collected at several measured irradiance
conditions, the next version should fit/validate irradiance dependence.
Temperature dependence should only be added once the required coefficients
or sufficiently controlled experimental data are available.

This is deliberate: the model should grow from measured evidence rather than
adding unverified parameters simply to make the model look more sophisticated.
