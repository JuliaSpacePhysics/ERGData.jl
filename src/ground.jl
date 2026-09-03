# Ground-based observations the ERG Science Center archives.

# ISEE induction magnetometers (the PWING network): one file per site per hour of 64 Hz
# search-coil dB/dt (H, D, Z).
const INDUCTION_URL = FilePattern("$ERG_BASE_URL/ground/geomag/isee/induction/{site|L}/{t:yyyy}/{t:mm}/isee_induction_{site|L}_{t:yyyymmddHH}_v{version}.cdf"; cadence = Hour(1))
const INDUCTION_SITES = ("ATH", "CNG", "GAK", "HUS", "IST", "KAG", "KAP", "KDU", "KNG", "LCL", "MGD", "MSR", "MUT", "NAI", "PTK", "RIK", "STA", "ZGN")

# Files are returned whole rather than clipped to `[t0, t1)`: each holds exactly one hour
# starting a few seconds early, and its epoch carries ms jitter and is not monotone, so
# clipping on epoch fails while the sample count is exact.
_open_whole(files, _, _) = cdfopen(length(files) == 1 ? files[1] : files)

"""ISEE induction magnetometers (PWING network): hourly files of 64 Hz search-coil dB/dt"""
const ISEE_INDUCTION = Registry("ISEE_INDUCTION", [Dataset("ISEE_INDUCTION_{site}", Archive(INDUCTION_URL, _open_whole); selectors = (; site = INDUCTION_SITES))])
