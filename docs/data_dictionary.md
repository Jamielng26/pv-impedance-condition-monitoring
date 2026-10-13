# Data dictionary

This is a high-level guide to the quantities repeatedly used in the analysis.

| Quantity | Meaning |
|---|---|
| \(I_{sc}\) | Short-circuit current from the DC I-V curve |
| \(V_{oc}\) | Open-circuit voltage from the DC I-V curve |
| \(P_{mp}\) | Maximum DC power |
| \(V_{mp}\) | Voltage at maximum power |
| \(I_{mp}\) | Current at maximum power |
| \(R_{diff}\) | Local differential resistance, \(dV/dI\), evaluated from the DC characteristic near the FRA operating state |
| \(R_s\) | Fitted series resistance in the retained equivalent-circuit model |
| \(R_p\) | Fitted parallel / polarisation resistance |
| CPE \(Y_0\) | Constant-phase-element magnitude parameter |
| CPE \(n\) | Constant-phase-element exponent / dispersion parameter |
| \(-Z''_{max}\) | Directly measured maximum of the positive-capacitive imaginary impedance feature within the analysed window |
| \(D_Z\) | Complex-spectrum distance used to quantify separation between two impedance spectra |
| \(\Delta BIC\) | Difference in Bayesian Information Criterion between competing circuit descriptions; negative values in the report's convention favour the more complex two-relaxation model |
| OPX70 | Reconciled operating point used as the standard condition for much of the fault campaign |
| PS25 / PS50 / PS75 / PS95 / PS100 | Controlled partial-shading labels indicating nominal shaded fraction |
| HLT | Healthy reference state |
| HOT70 / HOT80 / HOT90 | Exploratory local-heating target labels; not verified constant cell temperatures during the full FRA sweep |

## Interpretation cautions

- Equivalent-circuit parameters are effective terminal descriptions and are not assumed to map one-to-one onto unique microscopic mechanisms.
- A second fitted relaxation is not treated as proof of bypass-diode conduction.
- Severe states with poorer repeatability or Kramers-Kronig consistency are not forced into monotonic calibration relationships.
