# Data

This directory is intended to contain the experimental data used in the final report.

## Raw-data convention

The laboratory archive is organised by experimental day/session. Each session may contain combinations of:

- **DC Characterisation** — I-V sweep exports used to determine quantities such as \(I_{sc}\), \(V_{oc}\), \(P_{mp}\), \(V_{mp}\), \(I_{mp}\), and local differential resistance.
- **FRA** — impedance / frequency-response exports.
- **Nova results** — fitted equivalent-circuit parameter exports and related fitting outputs.
- **Environmental / log files** — irradiance, temperature and test-state records where available.

The final report uses day/session labels primarily as provenance. Scientific interpretation is organised by experimental question rather than by chronological day.

## Key fault campaigns

The final controlled mismatch campaign includes:

- equivalent PS50 faults on different cells;
- TOP / MID / BOT PS50 placement within one cell;
- single-cell severity progression from healthy through PS25 / PS50 / PS75 / PS100;
- two-cell mismatch with one PS75 cell fixed and the second cell progressively restricted;
- progressive addition of PS75 cells;
- matched suspected same-substring and cross-substring pair tests;
- PS95 tests intended to probe a possible bypass-active regime;
- exploratory local-heating / hotspot-mimicking tests.

## Important interpretation note

The raw labels such as `HOT70`, `HOT80` and `HOT90` denote local temperature targets reached before FRA acquisition. The heated cell was not held at a verified constant temperature throughout the complete sweep; these datasets are therefore treated as exploratory rather than as a calibrated hotspot-temperature response.

## Planned contents

The full retained raw archive will be added here or linked from this directory once file-size handling has been finalised.

Large binary datasets may be distributed through Git LFS or a GitHub Release rather than ordinary Git history.
