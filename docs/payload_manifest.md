# Complete payload manifest

This file describes the single repository payload prepared on 2026-10-13.

## Primary binary inputs

- `data/raw/Raw_Data_2026_Clean.zip`
  - size: 9,907,606 bytes
  - SHA-256: `3268849d68197b5f6da3c28153c641192c2a8b61743ce31cd0e5ece66c1563bb`
- `data/metadata/PV_Lab_Master_Log.xlsx`
  - size: 32,122 bytes
  - SHA-256: `0e4d1976c241ae3eb2e6c0204a7dedb7dff8b4b08a0486745de145f4257b323a`
- `data/metadata/PV_Environmental_Rig_Characterisation_Tracker.xlsx`
  - size: 45,680 bytes
  - SHA-256: `2dda6341906302286a2638d9cb548ef636efadabf9b33c18e9c7c70dac9014a0`
- `data/metadata/PV_Validated_FRA_Crosswalk_20260917.xlsx`
  - size: 6,735 bytes
  - SHA-256: `bfade27fbb9a93d2139ca615113df888f5146dd42b5c981b8e9ad753b2a2a881`

## Curated code

- MATLAB analysis scripts: `matlab/analysis/`
- MATLAB app: `matlab/apps/`
- Report figure scripts: `matlab/figure_generation/`
- Simulink supporting model: `matlab/models/single_diode/`
- Preflight check: `matlab/verify_repository_payload.m`

The two master-log backups under `data/metadata/archive/` are retained for provenance only.
