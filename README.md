# ERGData

Download and load data from the [Arase (ERG)](https://ergsc.isee.nagoya-u.ac.jp/) mission.

## Usage

```julia
using Pkg; Pkg.add("ERGData")
using ERGData, Dates

# Select an MGF product, then open its files over a time range
product = MGF[datatype="8sec"]
ds = getdata(product, Date(2017,3,27), Date(2017,3,28))
ds["mag_8sec_sm"]  # Access magnetic field in SM coordinates

# Load orbit data
orb = getdata(ORB[], Date(2017,3,27), Date(2017,3,28))

# Ground induction magnetometer: three hourly files of one site, opened whole
rec = getdata(ISEE_INDUCTION[site="HUS"], DateTime(2022,6,3,20), DateTime(2022,6,3,23))
rec["db_dt"]  # (3, 64 Hz samples): H, D, Z coil voltage
available(ISEE_INDUCTION[site="HUS"], DateTime(2022,6,3), DateTime(2022,6,4))  # hours the archive publishes
```

## Instruments

| Instrument | Description |
|------------|-------------|
| MGF | Magnetic Field (8sec, 64hz, 128hz, 256hz) |
| HEP | High-energy Electron Experiments |
| LEPe | Low Energy Particle - electron |
| LEPi | Low Energy Particle - ion |
| MEPe | Medium-energy Particle - electron |
| MEPi | Medium-energy Particle - ion |
| XEP | Extremely High-energy Electron |
| ORB | Orbit data |
| PWE_EFD | Electric Field Detector |
| PWE_OFA | Onboard Frequency Analyzer |
| PWE_HFA | High Frequency Analyzer |
| ISEE_INDUCTION | Ground induction magnetometers of the PWING network (hourly 64 Hz files per site) |

## Data Source

Data is downloaded from the [ERG Science Center](https://ergsc.isee.nagoya-u.ac.jp/data/ergsc/) and cached under SpaceDataModel's data directory, `~/.cache/spacedata/` unless `SPACE_DATA_DIR` says otherwise.

## Elsewhere

- [pyspedas - Arase (ERG)](https://github.com/spedas/pyspedas/tree/master/pyspedas/projects/erg)
