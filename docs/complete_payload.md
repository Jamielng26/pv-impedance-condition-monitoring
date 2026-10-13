# Complete repository payload

This payload contains all code/data assets currently intended for the public final-year-project repository in one extraction step.

## Included

- cleaned full raw-data archive;
- current laboratory master log;
- environmental-rig characterisation tracker;
- validated FRA crosswalk;
- two historical master-log backups under `data/metadata/archive/`;
- curated MATLAB analysis scripts;
- report figure-generation scripts;
- retained single-diode Simulink model;
- final Figures 4.13–4.18 and compact metrics already generated during analysis;
- metadata/readme files and a repository preflight script.

## Repository-relative paths

The principal Chapter 4 scripts have been made portable so that they look for:

- `data/raw/Raw_Data_2026_Clean.zip`
- `data/metadata/PV_Lab_Master_Log.xlsx`

and export newly generated figures to:

- `figures/generated/`

The raw-data ZIP is extracted automatically to ignored cache folders when those scripts are run.

## Publication

Use the accompanying `publish_complete_repo_payload.sh` script. It will clone or update the public repository, extract this payload at the repository root, stage the relevant folders, commit, and push to `main`.
