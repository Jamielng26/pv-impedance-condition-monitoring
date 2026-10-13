# PV Impedance Condition Monitoring

Experimental investigation of impedance-based fault classification and condition monitoring of a photovoltaic module using frequency response analysis (FRA) / impedance spectroscopy.

This repository accompanies the final-year Electrical Engineering project:

**Impedance-Based Fault Classification and Condition Monitoring of Photovoltaic Panels**

Author: **Jamie Langeveldt**  
University of Cape Town, Department of Electrical Engineering  
Supervisor: **Prof. P. Barendse**  
Year: **2026**

## Project overview

The project investigates whether module-level impedance measurements can distinguish normal operating-state variation from controlled photovoltaic mismatch and fault conditions.

The experimental work used a **Goldstone GSM80W monocrystalline-silicon PV module** and a **Metrohm Autolab PGSTAT302N/FRA** laboratory setup. The final FRA workflow used potentiostatic control over **1 Hz to 100 kHz**, with Kramers–Kronig checks, repeatability assessment and equivalent-circuit fitting used to support measurement validation and interpretation.

The work progressed through:

1. PV DC characterisation and operating-point reconciliation.
2. FRA protocol qualification.
3. Healthy environmental and electrical-state characterisation.
4. Single-cell partial-shading experiments.
5. Two-cell and progressive multi-cell mismatch experiments.
6. Targeted tests of a suspected substring / bypass-diode interpretation.
7. Exploratory local-hotspot testing.

## Main findings

### Healthy-state conditioning

Across 22 retained healthy spectra, the fitted parallel/polarisation resistance \(R_p\) followed the local DC differential resistance \(R_{diff}=dV/dI\) closely:

```text
ln(Rp) = -2.730 + 1.188 ln(Rdiff)
R² = 0.994
```

Leave-one-environment-out validation gave a median absolute prediction residual of approximately **3.5%**.

This supports treating healthy PV impedance as **state-conditioned**, rather than comparing every measurement with one fixed reference spectrum.

### Progressive mismatch beyond DC saturation

During progressive PS75 multi-cell mismatch, the conventional terminal DC response became comparatively insensitive after the first few shaded cells. Between the four- and nine-cell states:

- \(P_{mp}\): **-6.1%**
- \(I_{sc}\): **-4.6%**
- \(R_p\): **+63.4%**
- measured \(-Z''_{max}\): **+62.2%**

A two-relaxation impedance description also became strongly favoured from the four-cell state onward.

The report therefore concludes that **EIS/FRA can retain sensitivity to increasing internal mismatch after conventional terminal DC quantities have become comparatively insensitive**, provided that measurements are interpreted relative to a validated and electrically conditioned healthy baseline.

The experiments did **not** isolate a conducting bypass-diode impedance, and the exploratory hotspot tests did **not** establish a reproducible hotspot-specific impedance signature.

## Repository contents

```text
.
├── README.md
├── CITATION.cff
├── .gitignore
├── data/
│   ├── raw/
│   │   └── Raw_Data_2026_Clean.zip
│   └── metadata/
│       ├── PV_Lab_Master_Log.xlsx
│       ├── PV_Environmental_Rig_Characterisation_Tracker.xlsx
│       └── PV_Validated_FRA_Crosswalk_20260917.xlsx
├── matlab/
│   ├── analysis/
│   ├── apps/
│   ├── figure_generation/
│   ├── models/
│   └── verify_repository_payload.m
├── figures/
│   └── chapter4/
├── docs/
│   ├── data_dictionary.md
│   ├── experimental_protocol.md
│   ├── reproducibility.md
│   └── matlab_curation.md
└── report/
    └── README.md
```

## Reproducibility

See [docs/reproducibility.md](docs/reproducibility.md) for the analysis workflow, data locations and mapping between report results and MATLAB scripts.

A quick local preflight is provided at:

```matlab
verify_repository_payload
```

## Data

The complete retained laboratory dataset is available as:

[**data/raw/Raw_Data_2026_Clean.zip**](data/raw/Raw_Data_2026_Clean.zip)

The package contains **17 experimental sessions and 347 retained files**. Its checksum and session inventory are documented in [data/raw/README.md](data/raw/README.md).

Supporting metadata are available under [data/metadata/](data/metadata/), including the current master log, environmental-rig tracker and validated FRA crosswalk.

## MATLAB

The public MATLAB set has been curated from the full project-development archive. It includes final analysis scripts, report figure-generation scripts, the retained lab-analysis app and the supporting single-diode Simulink model.

See [matlab/MANIFEST.md](matlab/MANIFEST.md) for the retained code set and [docs/matlab_curation.md](docs/matlab_curation.md) for version-selection and provenance notes.

## Figures

Selected retained exports for the main controlled-mismatch and hotspot results are available under [figures/chapter4/](figures/chapter4/), together with compact CSV metric summaries.

## Report

The final submitted report PDF will be added under [report/](report/) after the final compression, proofreading and formatting pass.

## Citation

Citation metadata are provided in [CITATION.cff](CITATION.cff).

## Licence and reuse

No open-source software or data licence has been assigned. Unless a licence is added later, the repository contents remain copyright of the author and are provided primarily for academic review and reproducibility.
