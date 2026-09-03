# A dataset's files open as one CDF, or as a multi-file CDFDataset when the time range spans more than one.
_open(files, t0, t1) = cdfopen(length(files) == 1 ? files[1] : files, t0, t1)

_ds(name, url, selectors) = Dataset(name, Archive(url, _open); selectors)

const LEVELS = (; level=Any)  # not enumerated here: the archive publishes l2 and l3 unevenly

# Most instruments share one layout, differing only in the abbreviation that appears in both the
# directory and the file name.
const STD_URL = FilePattern("$ERG_BASE_URL/satellite/erg/{inst}/{level}/{datatype}/{t:yyyy}/{t:mm}/erg_{inst}_{level}_{datatype}_{t:yyyymmdd}_v{version}.cdf")

_std(name, inst, datatypes) = Registry(name, [_ds(name, STD_URL(; inst), (; LEVELS..., datatype=datatypes))];
    defaults=(; level="l2", datatype=first(datatypes)))

"""High-energy Electron Experiments (HEP)"""
const HEP = _std("HEP", "hep", ("omniflux", "3dflux"))
"""Low Energy Particle experiments - electron (LEPe)"""
const LEPe = _std("LEPe", "lepe", ("omniflux", "3dflux"))
"""Low Energy Particle experiments - ion (LEPi)"""
const LEPi = _std("LEPi", "lepi", ("omniflux", "3dflux"))
"""Medium-energy Particle experiments - electron (MEPe)"""
const MEPe = _std("MEPe", "mepe", ("omniflux", "3dflux"))
"""Medium-energy Particle experiments - ion (MEPi)"""
const MEPi = _std("MEPi", "mepi", ("omniflux", "3dflux", "tof"))
"""Extremely High-energy Electron Experiment (XEP)"""
const XEP = _std("XEP", "xep", ("omniflux", "2dflux"))

# MGF - Magnetic Field. Only 8sec is daily and coordinate-free; the high-rate datatypes are hourly
# files carrying the coordinate system in their name.
const MGF_8SEC_URL = FilePattern("$ERG_BASE_URL/satellite/erg/mgf/{level}/{datatype}/{t:yyyy}/{t:mm}/erg_mgf_{level}_{datatype}_{t:yyyymmdd}_v{version}.cdf")
const MGF_HZ_URL = FilePattern("$ERG_BASE_URL/satellite/erg/mgf/{level}/{datatype}/{t:yyyy}/{t:mm}/erg_mgf_{level}_{datatype}_{coord}_{t:yyyymmddHH}_v{version}.cdf"; cadence=Hour(1))
"""Magnetic Field (MGF)"""
const MGF = Registry(
    "MGF", [
        _ds("MGF_8SEC", MGF_8SEC_URL, (; LEVELS..., datatype="8sec")),
        _ds("MGF_HZ", MGF_HZ_URL, (; LEVELS..., datatype=("64hz", "128hz", "256hz"), coord=("dsi", "gse", "gsm", "sm"))),
    ]; defaults=(; level="l2", datatype="8sec", coord="dsi")
)

# ORB - Orbit data. Archive layouts differ: def has no month dir and no datatype in the file name;
# pre nests {t:yyyy}/{t:mm} and prefixes datatype before level.
const ORB_DEF_URL = FilePattern("$ERG_BASE_URL/satellite/erg/orb/def/{t:yyyy}/erg_orb_{level}_{t:yyyymmdd}_v{version}.cdf")
const ORB_PRE_URL = FilePattern("$ERG_BASE_URL/satellite/erg/orb/{datatype}/{t:yyyy}/{t:mm}/erg_orb_{datatype}_{level}_{t:yyyymmdd}_v{version}.cdf")
"""Orbit data (ORB): definitive (`def`) or predicted (`pre`)"""
const ORB = Registry(
    "ORB", [
        _ds("ORB_DEF", ORB_DEF_URL, (; LEVELS..., datatype="def")),
        _ds("ORB_PRE", ORB_PRE_URL, (; LEVELS..., datatype="pre")),
    ]; defaults=(; level="l2", datatype="def")
)

# PWE - Plasma Wave Experiment. Each receiver adds a directory and a name segment. EFD's
# waveform datatypes carry the coordinate system in the name; HFA L2 spectra sit under
# spec/{mode}.
const PWE_URL = FilePattern("$ERG_BASE_URL/satellite/erg/pwe/{rx}/{level}/{datatype}/{t:yyyy}/{t:mm}/erg_pwe_{rx}_{level}_{datatype}_{t:yyyymmdd}_v{version}.cdf")
const PWE_EFD_WF_URL = FilePattern("$ERG_BASE_URL/satellite/erg/pwe/efd/{level}/{datatype}/{t:yyyy}/{t:mm}/erg_pwe_efd_{level}_{datatype}_{coord}_{t:yyyymmdd}_v{version}.cdf")
const PWE_HFA_L2_URL = FilePattern("$ERG_BASE_URL/satellite/erg/pwe/hfa/l2/spec/{datatype}/{t:yyyy}/{t:mm}/erg_pwe_hfa_l2_spec_{datatype}_{t:yyyymmdd}_v{version}.cdf")
const PWE_HFA_L3_URL = FilePattern("$ERG_BASE_URL/satellite/erg/pwe/hfa/l3/{t:yyyy}/{t:mm}/erg_pwe_hfa_l3_1min_{t:yyyymmdd}_v{version}.cdf")

"""Plasma Wave Experiment - Electric Field Detector (PWE_EFD): spin-fit fields, potentials and spectra, or the `E64Hz`/`E256Hz` waveforms"""
const PWE_EFD = Registry(
    "PWE_EFD", [
        _ds("PWE_EFD", PWE_URL(; rx="efd"), (; LEVELS..., datatype=("E_spin", "pot", "spec"))),
        _ds("PWE_EFD_WF", PWE_EFD_WF_URL, (; LEVELS..., datatype=("E64Hz", "E256Hz"), coord="dsi")),
    ]; defaults=(; level="l2", datatype="E_spin", coord="dsi")
)
"""Plasma Wave Experiment - Onboard Frequency Analyzer (PWE_OFA)"""
const PWE_OFA = Registry("PWE_OFA", [_ds("PWE_OFA", PWE_URL(; rx="ofa"), (; LEVELS..., datatype=("spec", "matrix")))];
    defaults=(; level="l2", datatype="spec"))

"""Plasma Wave Experiment - High Frequency Analyzer (PWE_HFA): L2 spectra (`high`, `low`, `monit`) or the L3 `1min` density product"""
const PWE_HFA = Registry(
    "PWE_HFA", [
        _ds("PWE_HFA_L2", PWE_HFA_L2_URL, (; level="l2", datatype=("high", "low", "monit"))),
        _ds("PWE_HFA_L3", PWE_HFA_L3_URL, (; level="l3", datatype="1min")),
    ]; defaults=(; datatype="high")
)
