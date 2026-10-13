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

The experimental work used a **Goldstone GSM80W monocrystalline-silicon PV module** and a **Metrohm Autolab PGSTAT302N/FRA** laboratory setup. The final FRA workflow used potentiostatic control and a retained measurement band of **1 Hz to 100 kHz**, with Kramers-Kronig checks and equivalent-circuit fitting used as measurement and interpretation tools.

The work progressed through:

1. PV DC characterisation and operating-point reconciliation.
2. FRA protocol qualification.
3. Healthy environmental and electrical-state characterisation.
4. Single-cell partial-shading experiments.
5. Two-cell and progressive multi-cell mismatch experiments.
6. Targeted tests of a suspected substring / bypass-diode interpretation.
7. Exploratory local-hotspot testing.

## Main findings

Two results are central to the report.

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

The report therefore concludes that **EIS/FRA can retain sensitivity to increasing internal mismatch after conventional terminal DC quantities have become comparatively insensitive**, provided the measurement is interpreted relative to a validated electrical and environmental baseline.

The experiments did **not** isolate a conducting bypass-diode impedance, and the exploratory hotspot tests did **not** establish a reproducible hotspot-specific impedance signature.

## Repository structure

```text
.
├── README.md
├── CITATION.cff
├── .gitignore
├── data/
│   └── README.md
├── matlab/
│   └── README.md
├── docs/
│   ├── data_dictionary.md
│   ├── experimental_protocol.md
│   └── reproducibility.md
├── figures/
│   └── README.md
└── report/
    └── README.md
```

The repository will be populated with the retained raw data, final analysis scripts, report figure-generation scripts, and the submitted report.

## Reproducibility

See [docs/reproducibility.md](docs/reproducibility.md) for the intended analysis workflow and the mapping between datasets, MATLAB scripts, and report figures.

## Data

See [data/README.md](data/README.md) for the raw-data organisation and notes on file naming.

## MATLAB

See [matlab/README.md](matlab/README.md) for the planned code layout and the distinction between final retained scripts and superseded development/debugging versions.

## Citation

Citation metadata are provided in [CITATION.cff](CITATION.cff).

## License

No open-source software or data licence has been assigned yet. Unless a licence is added later, the repository contents remain copyright of the author and should not be redistributed or reused beyond normal academic review without permission.
