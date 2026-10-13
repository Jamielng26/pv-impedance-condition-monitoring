# Reproducibility guide

The final repository is intended to let a reviewer trace each reported result back to the retained experimental data and MATLAB analysis.

## Recommended environment

- MATLAB R2025b or later.
- No internet connection should be required for the final analysis scripts.
- Keep the raw-data archive in the location expected by each top-level reproduction script, or update the script's `DATA_SOURCE` / root-path setting.

## Reproduction workflow

1. Obtain the retained raw dataset from `data/`.
2. Open MATLAB in the repository root or the relevant `matlab/` subdirectory.
3. Run the final data-audit / import script first where one is supplied.
4. Run the relevant analysis or figure-generation script.
5. Compare generated numerical summaries and figures with the values reported in the final project report.

## Key report results to reproduce

The final curated repository should provide direct reproduction paths for at least:

| Report result | Target reproduction |
|---|---|
| Healthy operating-point reconciliation | Healthy environmental / OPX analysis script |
| Healthy \(R_p\)-\(R_{diff}\) relationship | Final \(R_p\) vs \(R_{diff}\) analysis |
| PS50 spatial sensitivity | Chapter 4 shading figure pipeline |
| Single-cell severity behaviour | Chapter 4 shading figure pipeline |
| Two-cell mismatch experiment | Chapter 4 shading figure pipeline |
| Progressive mismatch and \(\Delta BIC\) transition | Chapter 4 shading figure pipeline |
| Suspected substring / bypass interpretation test | Chapter 4 shading figure pipeline |
| Exploratory hotspot comparison | Hotspot figure-generation script |

## Expected headline checks

A correct reproduction of the final data should recover, within normal rounding:

- healthy \(R_p\)-\(R_{diff}\) fit: \(R^2 \approx 0.994\);
- four-to-nine-cell PS75 progression:
  - \(\Delta P_{mp} \approx -6.1\%\),
  - \(\Delta I_{sc} \approx -4.6\%\),
  - \(\Delta R_p \approx +63.4\%\),
  - \(\Delta(-Z''_{max}) \approx +62.2\%\);
- sustained strong preference for the two-relaxation model from the four-cell state onward;
- no uniquely boundary-dependent impedance response in the matched Day-18 pair test;
- hotspot-associated spectral changes that are not consistently larger than healthy run-to-run drift.

## Provenance

Development/debugging versions of scripts are intentionally excluded from the final public-facing repository. The goal is to preserve the shortest reproducible path from retained raw data to the submitted figures and conclusions.
