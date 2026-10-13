# Final MATLAB manifest

This is the curated code set intended to accompany the final report.

| Repository path | Role | Status |
|---|---|---|
| `matlab/apps/PVLabAnalyzer_v0_1_9.m` | Laboratory import, QC and exploratory dashboard | Retained final app version |
| `matlab/analysis/PV_Research_Feature_Extractor_v0_1.m` | Crosswalk-driven validated feature extraction | Retained |
| `matlab/analysis/PV_DVF_SDM_Analyzer_v0_1.m` | Environmental DC / single-diode analysis | Retained |
| `matlab/figure_generation/PV_Chapter3_DC_Figure_v0_1.m` | Representative Chapter 3 DC figure | Retained |
| `matlab/figure_generation/PV_Chapter3_FRA_Figure_v0_1.m` | Representative Chapter 3 FRA figure | Retained |
| `matlab/figure_generation/generate_ch4_figures_v2.m` | Figures 4.1–4.3 | Retained, repository paths enabled |
| `matlab/figure_generation/generate_ch4_2_story_figures_v3.m` | FRA protocol qualification figures | Retained, repository paths enabled |
| `matlab/figure_generation/generate_ch4_3_figures.m` | Environmental-rig figures | Retained, repository paths enabled |
| `matlab/figure_generation/generate_ch4_5_core_figures.m` | Healthy FRA figures | Retained, repository paths enabled |
| `matlab/figure_generation/Figure_4_12_Rp_vs_Rdiff_FIXED_v2.m` | Healthy-state synthesis | Retained, repository paths enabled |
| `matlab/figure_generation/generate_chapter4_shading_figures.m` | Figures 4.13–4.17 | Core self-contained reproduction script |
| `matlab/figure_generation/generate_Fig4_18_hotspot_exploratory.m` | Figure 4.18 | Core self-contained reproduction script |
| `matlab/models/single_diode/` | Supporting single-diode Simulink model | Retained supporting model |
| `matlab/verify_repository_payload.m` | Repository preflight check | Added for reproducibility |

## Curation policy

Superseded debugging copies and historical version chains are excluded where a later retained version exists. The private development archive remains the full historical record; this public set is the shortest reproducible path to the submitted report.

## Operating-point version note

A later experimental version of `PV_DC_Operating_Point_Calculator.m` redefined OPX using a current-collapse criterion. It is intentionally excluded from the final-report reproduction set because the submitted report uses the voltage-normalised coordinate

`xi = (Vbias - Vmp)/(Voc - Vmp)`.

The retained Figure 4.12 script follows the report definition.
