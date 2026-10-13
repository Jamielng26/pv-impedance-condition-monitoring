# Repository publication payload

The complete project publication payload has now been assembled.

## Included in the payload

- `data/raw/Raw_Data_2026_Clean.zip` — complete cleaned laboratory archive.
- `data/metadata/PV_Lab_Master_Log.xlsx` — current authoritative laboratory master log.
- `data/metadata/PV_Environmental_Rig_Characterisation_Tracker.xlsx` — environmental-rig characterisation workbook.
- `data/metadata/PV_Validated_FRA_Crosswalk_20260917.xlsx` — validated FRA/DC crosswalk.
- curated MATLAB analysis and figure-generation scripts.
- retained single-diode Simulink model.
- selected final Chapter 4 figures and compact metrics.
- provenance copies of two historical master-log backups.
- repository-relative path updates for the principal Chapter 4 reproduction scripts.
- `matlab/verify_repository_payload.m` for a quick local preflight.

There is no longer a missing master-log dependency in the prepared payload.

## Expected publication command

Use the accompanying `publish_complete_repo_payload.sh` script to overlay the payload onto the repository and push the complete curated project to `main`.
