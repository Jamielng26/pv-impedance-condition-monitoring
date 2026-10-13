# Data

This directory contains the retained experimental data and metadata used in the final project analysis.

## Raw data

The complete cleaned laboratory archive is available at:

`data/raw/Raw_Data_2026_Clean.zip`

The package preserves the original day/session folder hierarchy and filenames while excluding macOS metadata files.

The archive contains:

- **17 experimental sessions**
- **347 retained files**
- **339 Excel workbooks**
- **7 PNG files**
- **1 PDF file**

See [raw/README.md](raw/README.md) for the full session inventory and checksum.

## Metadata

The `metadata/` directory contains the principal project indexing and provenance files:

- `PV_Lab_Master_Log.xlsx` — current authoritative laboratory run log.
- `PV_Environmental_Rig_Characterisation_Tracker.xlsx` — environmental-rig characterisation record.
- `PV_Validated_FRA_Crosswalk_20260917.xlsx` — validated FRA/DC crosswalk.
- `archive/` — retained historical master-log backups for provenance.

## Raw-data convention

Each laboratory session may contain combinations of:

- **DC Characterisation** — I–V sweep exports used to determine quantities such as \(I_{sc}\), \(V_{oc}\), \(P_{mp}\), \(V_{mp}\), \(I_{mp}\), and local differential resistance.
- **FRA** — impedance / frequency-response exports.
- **Nova results** — fitted equivalent-circuit parameter exports and related fitting outputs.
- **Environmental / log files** — irradiance, temperature and test-state records where available.

The final report uses day/session labels primarily for provenance; the scientific analysis is organised by experimental question rather than chronology.

## Key controlled-fault campaigns

The retained dataset includes:

- equivalent PS50 faults on different cells;
- TOP / MID / BOT PS50 placement within one cell;
- single-cell severity progression through PS25 / PS50 / PS75 / PS100;
- two-cell mismatch with one PS75 cell fixed and the second cell progressively restricted;
- progressive addition of PS75 cells;
- matched suspected same-substring and cross-substring pair tests;
- PS95 tests intended to probe a possible bypass-active regime;
- exploratory local-heating / hotspot-mimicking tests.

## Interpretation note for hotspot labels

Labels such as `HOT70`, `HOT80` and `HOT90` denote local temperature targets reached before FRA acquisition. The heated cell was not held at a verified constant temperature throughout the complete sweep; these datasets are therefore treated as exploratory rather than as a calibrated hotspot-temperature response.
