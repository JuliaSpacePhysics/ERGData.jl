# A dataset's files open as one CDF, or as a multi-file CDFDataset when the time range spans more than one.
_open(files, t0, t1) = cdfopen(length(files) == 1 ? files[1] : files, t0, t1)

_ds(name, url, selectors) = Dataset(name, Archive(url, _open); selectors)

const LEVELS = (; level = Any)  # not enumerated here: the archive publishes l2 and l3 unevenly

# Most instruments share one layout, differing only in the abbreviation that appears in both the
# directory and the file name.
const STD_URL = FilePattern("$ERG_BASE_URL/satellite/erg/{inst}/{level}/{datatype}/{t:yyyy}/{t:mm}/erg_{inst}_{level}_{datatype}_{t:yyyymmdd}_v{version}.cdf")

_std(name, inst, datatypes) = Registry(name, [_ds(name, STD_URL(; inst), (; LEVELS..., datatype = datatypes))];
    defaults = (; level = "l2", datatype = first(datatypes)))

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
const MGF_HZ_URL = FilePattern("$ERG_BASE_URL/satellite/erg/mgf/{level}/{datatype}/{t:yyyy}/{t:mm}/erg_mgf_{level}_{datatype}_{coord}_{t:yyyymmddHH}_v{version}.cdf"; cadence = Hour(1))
"""Magnetic Field (MGF)"""
const MGF = Registry(
    "MGF", [
        _ds("MGF_8SEC", MGF_8SEC_URL, (; LEVELS..., datatype = "8sec")),
        _ds("MGF_HZ", MGF_HZ_URL, (; LEVELS..., datatype = ("64hz", "128hz", "256hz"), coord = ("dsi", "gse", "gsm", "sm"))),
    ]; defaults = (; level = "l2", datatype = "8sec", coord = "dsi")
)

# ORB - Orbit data. Archive layouts differ: def has no month dir and no datatype in the file name;
# pre nests {t:yyyy}/{t:mm} and prefixes datatype before level.
const ORB_DEF_URL = FilePattern("$ERG_BASE_URL/satellite/erg/orb/def/{t:yyyy}/erg_orb_{level}_{t:yyyymmdd}_v{version}.cdf")
const ORB_PRE_URL = FilePattern("$ERG_BASE_URL/satellite/erg/orb/{datatype}/{t:yyyy}/{t:mm}/erg_orb_{datatype}_{level}_{t:yyyymmdd}_v{version}.cdf")
"""Orbit data (ORB): definitive (`def`) or predicted (`pre`)"""
const ORB = Registry(
    "ORB", [
        _ds("ORB_DEF", ORB_DEF_URL, (; LEVELS..., datatype = "def")),
        _ds("ORB_PRE", ORB_PRE_URL, (; LEVELS..., datatype = "pre")),
    ]; defaults = (; level = "l2", datatype = "def")
)

# PWE - Plasma Wave Experiment. Each receiver adds a directory and a name segment; HFA alone is hourly.
const PWE_URL = FilePattern("$ERG_BASE_URL/satellite/erg/pwe/{rx}/{level}/{datatype}/{t:yyyy}/{t:mm}/erg_pwe_{rx}_{level}_{datatype}_{t:yyyymmdd}_v{version}.cdf")
const PWE_HFA_URL = FilePattern("$ERG_BASE_URL/satellite/erg/pwe/hfa/{level}/{datatype}/{t:yyyy}/{t:mm}/erg_pwe_hfa_{level}_{datatype}_{t:yyyymmddHH}_v{version}.cdf"; cadence = Hour(1))

_pwe(name, rx, datatypes, url = PWE_URL(; rx)) = Registry(name, [_ds(name, url, (; LEVELS..., datatype = datatypes))];
    defaults = (; level = "l2", datatype = first(datatypes)))

"""Plasma Wave Experiment - Electric Field Detector (PWE_EFD)"""
const PWE_EFD = _pwe("PWE_EFD", "efd", ("E_spin", "pot", "spec"))
"""Plasma Wave Experiment - Onboard Frequency Analyzer (PWE_OFA)"""
const PWE_OFA = _pwe("PWE_OFA", "ofa", ("spec", "matrix"))
"""Plasma Wave Experiment - High Frequency Analyzer (PWE_HFA)"""
const PWE_HFA = _pwe("PWE_HFA", "hfa", ("spec", "low", "high"), PWE_HFA_URL)
