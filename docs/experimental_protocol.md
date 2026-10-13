# Experimental protocol summary

This document summarises the final retained laboratory workflow used in the project.

## Hardware

- Goldstone GSM80W monocrystalline-silicon PV module.
- Metrohm Autolab PGSTAT302N with FRA capability.
- Indoor lamp-array illumination.
- Irradiance and temperature measurement instrumentation as recorded in the report.

## DC characterisation

DC I-V measurements were used to establish the operating state of the module and derive terminal quantities including:

- short-circuit current \(I_{sc}\);
- open-circuit voltage \(V_{oc}\);
- maximum power \(P_{mp}\);
- maximum-power voltage and current;
- local differential resistance \(R_{diff}=dV/dI\).

## FRA / impedance measurements

The final retained FRA workflow used:

- potentiostatic control;
- retained frequency range: **1 Hz to 100 kHz**;
- OPX70 as the standard fault-comparison operating condition;
- Kramers-Kronig behaviour and repeatability as validity checks;
- a Randles-CPE-type single-relaxation model as the default fitted description;
- more complex models only where supported by the measured spectral evidence and model-selection criteria.

## Operating-point principle

A major methodological outcome of the project is that fixed absolute voltage is not sufficient to define a comparable healthy electrical state across changing irradiance and temperature.

The report therefore distinguishes:

- fixed absolute-voltage operation;
- voltage-normalised positions;
- the reconciled OPX coordinate / electrical-state approach;
- local DC differential resistance as an additional state descriptor.

## Fault methodology

Controlled mismatch was imposed physically rather than inferred from the resulting impedance response. The main shading campaign progressively tested:

1. fault presence,
2. spatial sensitivity,
3. shaded-area severity,
4. relative two-cell restriction,
5. progressive multi-cell mismatch,
6. suspected substring / bypass-boundary effects.

Physical claims are restricted to what was independently supported by the measurements.
