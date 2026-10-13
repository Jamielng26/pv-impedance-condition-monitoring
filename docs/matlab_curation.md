# MATLAB curation and provenance

The source MATLAB archive contains the full development history of the project. The public repository is intentionally curated so that a reviewer sees the scripts that contributed directly to the final report or document an important part of the final analysis workflow.

## What was retained

The retained set covers:

- laboratory import and QC;
- validated FRA/DC feature extraction;
- environmental DC / SDM analysis;
- report figure generation;
- healthy `Rp`–`Rdiff` synthesis;
- controlled shading and mismatch analysis;
- exploratory hotspot analysis;
- the supporting single-diode Simulink model.

See `matlab/MANIFEST.md` for the file-by-file list.

## What was excluded

The private MATLAB archive also contains:

- earlier versions of `PVLabAnalyzer`;
- `*_FIXED`, `*_v2`, temporary and debugging copies that were superseded;
- helper scripts replaced by the final self-contained shading pipeline;
- generated raw-data caches;
- duplicate raw-data archives stored inside MATLAB working folders;
- macOS metadata files;
- exploratory scripts that are not referenced by the final report.

These remain part of the author's working archive but are omitted from the reviewer-facing repository to avoid ambiguity over which files produced the submitted results.

## Portability pass

The retained Chapter 4 scripts that previously referenced the author's local OneDrive paths have been updated in this repository payload to resolve:

- raw data from `data/raw/Raw_Data_2026_Clean.zip`;
- the master log from `data/metadata/PV_Lab_Master_Log.xlsx`;
- generated outputs to `figures/generated/`.

No numerical analysis logic was intentionally changed by this path-only portability pass.

## Operating-point version warning

The working archive contains a later experimental operating-point calculator that used a different OPX definition. That development file is not included as a final-report reproduction script.

The final report defines the normalised high-voltage coordinate as:

`xi = (Vbias - Vmp)/(Voc - Vmp)`

with `xi = 0` at `Vmp` and `xi = 1` at `Voc`. The retained final-report scripts are documented against that definition.
