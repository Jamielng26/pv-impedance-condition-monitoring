# Final repository MATLAB manifest

| Repository path | Role in project | Final-report status |
|---|---|---|
| `matlab/apps/PVLabAnalyzer_v0_1_9.m` | Laboratory import, QC and exploratory dashboard | Retained final app version |
| `matlab/analysis/PV_Research_Feature_Extractor_v0_1.m` | Crosswalk-driven validated feature extraction | Retained |
| `matlab/analysis/PV_DVF_SDM_Analyzer_v0_1.m` | Environmental DC / single-diode analysis | Retained |
| `matlab/figure_generation/PV_Chapter3_DC_Figure_v0_1.m` | Representative Chapter 3 DC figure | Retained |
| `matlab/figure_generation/PV_Chapter3_FRA_Figure_v0_1.m` | Representative Chapter 3 FRA/Nyquist figure | Retained |
| `matlab/figure_generation/generate_ch4_figures_v2.m` | Figures 4.1–4.3 | Retained provenance copy |
| `matlab/figure_generation/generate_ch4_2_story_figures_v3.m` | FRA protocol qualification | Retained; requires master log |
| `matlab/figure_generation/generate_ch4_3_figures.m` | Environmental-rig characterisation | Retained |
| `matlab/figure_generation/generate_ch4_5_core_figures.m` | Healthy environmental FRA results | Retained |
| `matlab/figure_generation/Figure_4_12_Rp_vs_Rdiff_FIXED_v2.m` | Healthy state synthesis | Retained |
| `matlab/figure_generation/generate_chapter4_shading_figures.m` | Figures 4.13–4.17 | Core clean-slate reproduction script |
| `matlab/figure_generation/generate_Fig4_18_hotspot_exploratory.m` | Figure 4.18 | Core clean-slate reproduction script |
| `matlab/models/single_diode/` | Supporting single-diode Simulink model | Retained supporting model |

## Not included as final-report code

The later `PV_DC_Operating_Point_Calculator.m` development version is intentionally excluded because it changed the OPX definition after the report had adopted the voltage-normalised \(\xi\) definition. Historical script chains are also excluded where a later retained version supersedes them.
