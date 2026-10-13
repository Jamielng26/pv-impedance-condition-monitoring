# MATLAB

This directory is reserved for the **final retained MATLAB code** used to analyse the data and generate the figures in the submitted report.

The repository should contain reproducible final versions, not the complete history of temporary/debugging scripts.

## Planned layout

```text
matlab/
├── analysis/
├── figure_generation/
├── apps/
├── models/
└── utilities/
```

## Expected retained code

The final curated set is expected to include scripts or apps for:

- DC curve import and operating-point extraction;
- FRA import and spectral processing;
- Kramers-Kronig / validity summaries where implemented in MATLAB;
- equivalent-circuit parameter extraction and comparison;
- local differential resistance \(R_{diff}\) analysis;
- healthy \(R_p\) versus \(R_{diff}\) synthesis;
- controlled shading / mismatch figure generation;
- exploratory hotspot figure generation;
- any final single-diode-model or supporting model used in the report;
- reusable plotting and export helpers that are genuinely required by the retained scripts.

## Version policy

Only the final reproducible version of each analysis should be committed. Superseded files with names such as `FIXED`, `v2`, `old`, `temp`, or one-off debugging scripts should not be included unless they are required to reproduce a published result.

## MATLAB version

The report-generation work was performed using MATLAB R2025b on macOS during the final project phase. Scripts should be written to remain portable where practical.
