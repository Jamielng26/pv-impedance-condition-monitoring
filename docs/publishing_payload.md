# Publishing the curated project payload

The raw-data and MATLAB source archives were reviewed before publication. A curated payload was prepared containing:

- the cleaned full raw-data archive;
- the validated FRA crosswalk;
- final/retained MATLAB analysis scripts;
- final report figure-generation scripts;
- the retained PV single-diode Simulink model;
- exported Figures 4.13–4.18 and compact CSV metrics.

The payload is designed to be extracted at the repository root.

## Expected paths after extraction

```text
data/raw/Raw_Data_2026_Clean.zip
data/metadata/PV_Validated_FRA_Crosswalk_20260917.xlsx
matlab/analysis/...
matlab/apps/...
matlab/figure_generation/...
matlab/models/single_diode/...
figures/chapter4/...
```

## Missing dependency still required

The uploaded MATLAB and raw-data archives did **not** contain the project master log (`PV_Lab_Master_Log.xlsx`).

That workbook is required by the retained protocol-qualification script `generate_ch4_2_story_figures_v3.m`, and by some early Chapter 4 operating-point visualisation code that reads actual settled FRA bias/current fields from the master log.

The rest of the clean-slate fault pipelines (Figures 4.13–4.18) operate directly from the raw-data archive.

## Data package checksum

`Raw_Data_2026_Clean.zip`

SHA-256:

```text
3268849d68197b5f6da3c28153c641192c2a8b61743ce31cd0e5ece66c1563bb
```
