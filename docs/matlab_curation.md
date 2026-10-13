# MATLAB curation and provenance

The uploaded MATLAB archive contained the full development history of the project: final report scripts, earlier versions, debugging copies, generated figure caches, embedded raw-data copies and exploratory analyses.

The public repository is intentionally curated so that a reviewer sees the files that either contributed directly to the final report or document a major part of the analysis workflow.

## Retained for the final repository

### Core analysis

- `PV_Research_Feature_Extractor_v0_1.m` — crosswalk-driven extraction of validated FRA, DC and environment records.
- `PV_DVF_SDM_Analyzer_v0_1.m` — exploratory/multi-curve single-diode-model analysis used during environmental characterisation.
- `PVLabAnalyzer_v0_1_9.m` — final retained laboratory import/analysis dashboard version.

### Report figure generation

- `PV_Chapter3_DC_Figure_v0_1.m`
- `PV_Chapter3_FRA_Figure_v0_1.m`
- `generate_ch4_figures_v2.m` — Figures 4.1–4.3.
- `generate_ch4_2_story_figures_v3.m` — FRA protocol qualification figures.
- `generate_ch4_3_figures.m` — environmental-rig characterisation figures.
- `generate_ch4_5_core_figures.m` — healthy FRA comparison figures.
- `Figure_4_12_Rp_vs_Rdiff_FIXED_v2.m` — healthy \(R_p\)-\(R_{diff}\) synthesis.
- `generate_chapter4_shading_figures.m` — clean-slate Figures 4.13–4.17.
- `generate_Fig4_18_hotspot_exploratory.m` — Figure 4.18.

### Supporting model

The `models/single_diode/` directory contains the retained single-diode Simulink model and the scripts used to build/configure and compare it.

## Development files deliberately excluded

The source archive also contained superseded or duplicated files such as:

- earlier `PVLabAnalyzer` versions;
- `*_FIXED`, `*_FIXED_v2`, `v0_1`, `v0_2` development chains where a later retained version exists;
- one-off helper scripts replaced by the self-contained Chapter 4 shading pipeline;
- generated `_RawData_cache` folders;
- duplicated copies of `Raw Data.zip` inside MATLAB folders;
- macOS metadata files;
- historical figure-generation attempts that are no longer referenced by the final report.

These files remain in the author's private working archive but are omitted from the reviewer-facing repository to avoid ambiguity over which version produced the submitted results.

## Important operating-point version note

The working MATLAB archive contains a later experimental version of `PV_DC_Operating_Point_Calculator.m` that redefines OPX using the terminal-current collapse. The submitted report, however, defines

```text
xi = (Vbias - Vmp) / (Voc - Vmp)
Vbias = Vmp + xi (Voc - Vmp)
```

and the final report figures and healthy \(R_p\)-\(R_{diff}\) synthesis use that report definition.

The later current-collapse calculator is therefore **not included as a final-report reproduction script**. It is a development experiment rather than the definition reported in the thesis.

## Portability status

The clean-slate Figures 4.13–4.18 pipelines are largely self-contained once the full raw-data ZIP is available.

Several earlier Chapter 4 scripts still contain the author's original local path settings, and the protocol-qualification script also expects the project master log. They are retained as provenance copies. A portability pass may be applied before final submission so that all paths resolve from the repository root without changing the underlying analysis logic.
