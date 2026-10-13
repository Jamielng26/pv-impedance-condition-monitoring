# Reproducibility guide

The repository is organised so that a reviewer can trace the main report results back to the retained experimental data and MATLAB analysis.

## Recommended environment

- MATLAB R2025b or later.
- Simulink is required only for the supporting single-diode model.
- No internet connection is required for the retained analysis scripts after the repository has been cloned.

## Preflight

From MATLAB, add/open the repository and run:

```matlab
verify_repository_payload
```

The preflight checks the raw-data archive, current master log, environmental tracker, validated crosswalk and key final-report scripts.

## Data locations

- Raw laboratory archive: `data/raw/Raw_Data_2026_Clean.zip`
- Current run log: `data/metadata/PV_Lab_Master_Log.xlsx`
- Environmental rig tracker: `data/metadata/PV_Environmental_Rig_Characterisation_Tracker.xlsx`
- Validated FRA crosswalk: `data/metadata/PV_Validated_FRA_Crosswalk_20260917.xlsx`

The principal Chapter 4 scripts now resolve these paths relative to their location in the repository. Where raw files are needed, the ZIP is extracted automatically into ignored local cache directories.

## Figure-generation paths

Newly reproduced Chapter 4 figures are written to:

`figures/generated/`

The `figures/chapter4/` directory contains selected retained exports generated during the project.

## Key report results to reproduce

| Report result | Reproduction script |
|---|---|
| Operating-point definition and reconciliation figures | `matlab/figure_generation/generate_ch4_figures_v2.m` |
| FRA protocol qualification | `matlab/figure_generation/generate_ch4_2_story_figures_v3.m` |
| Environmental-rig characterisation | `matlab/figure_generation/generate_ch4_3_figures.m` |
| Healthy environmental FRA comparisons | `matlab/figure_generation/generate_ch4_5_core_figures.m` |
| Healthy `Rp`–`Rdiff` relation | `matlab/figure_generation/Figure_4_12_Rp_vs_Rdiff_FIXED_v2.m` |
| PS50 spatial sensitivity through progressive mismatch and boundary test | `matlab/figure_generation/generate_chapter4_shading_figures.m` |
| Exploratory hotspot comparison | `matlab/figure_generation/generate_Fig4_18_hotspot_exploratory.m` |

## Headline numerical checks

A correct reproduction should recover, within normal rounding:

- healthy `Rp`–`Rdiff` in-sample `R^2 ≈ 0.994`;
- four-to-nine-cell PS75 progression:
  - `ΔPmp ≈ -6.1%`,
  - `ΔIsc ≈ -4.6%`,
  - `ΔRp ≈ +63.4%`,
  - `Δ(-Z''max) ≈ +62.2%`;
- sustained preference for the two-relaxation model from the four-cell state onward;
- closely similar suspected same-substring and cross-substring responses in the targeted boundary test;
- hotspot-associated spectral differences that are not consistently larger than healthy run-to-run drift.

## Provenance and curation

Development/debugging versions are intentionally excluded from the public-facing MATLAB set where a later retained version supersedes them. See `docs/matlab_curation.md` and `matlab/MANIFEST.md`.
