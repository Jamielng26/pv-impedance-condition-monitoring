# MATLAB

This directory contains the **curated final-report MATLAB code set** retained from the full project-development archive.

The aim is to preserve the shortest clear path from the raw data to the submitted analyses and figures, rather than publishing every temporary, debugging or superseded development file.

## Layout

```text
matlab/
├── analysis/
├── apps/
├── figure_generation/
├── models/
├── MANIFEST.md
└── verify_repository_payload.m
```

## Analysis

`analysis/` contains the retained project analysis scripts, including:

- validated FRA / DC feature extraction;
- environmental DC and single-diode analysis.

## App

`apps/PVLabAnalyzer_v0_1_9.m` is the final retained laboratory-analysis dashboard version.

## Figure generation

`figure_generation/` contains the scripts used for the principal report figures, including:

- Chapter 3 representative DC and FRA plots;
- operating-point reconciliation;
- FRA protocol qualification;
- environmental-rig characterisation;
- healthy environmental FRA comparisons;
- the healthy \(R_p\)-vs-\(R_{diff}\) relation;
- controlled shading and progressive mismatch Figures 4.13–4.17;
- exploratory hotspot Figure 4.18.

## Models

`models/` contains the retained supporting single-diode Simulink model and associated build/configuration files.

## Reproducibility preflight

From MATLAB, with the repository available locally, run:

```matlab
verify_repository_payload
```

This checks that the key raw-data archive, metadata workbooks and principal final-report scripts are present.

## Version policy

Superseded development chains, one-off debugging scripts, generated caches and duplicate embedded raw-data archives are intentionally excluded from the public repository.

See [MANIFEST.md](MANIFEST.md) for the final retained file list and [../docs/matlab_curation.md](../docs/matlab_curation.md) for the curation rationale.
