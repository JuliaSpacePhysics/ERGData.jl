"""
Calibration and spectra of [`ISEE_INDUCTION`](@ref) search-coil records.

    rec = Induction.load("HUS", t0, t1)
    f, P = Induction.psd(rec)       # nT²/Hz, needs `using DSP`
"""
module Induction

using Dates
import SpaceDataModel
using ..ERGData: ISEE_INDUCTION

const SAMPLE_RATE = 64.0
const NFFT = 4096       # 64 s segments, resolving 0.016 Hz

dataset(site) = ISEE_INDUCTION[site = uppercase(site)]

"Does the archive hold every hourly file covering `[t0, t1)`?"
function available(site, t0, t1)
    h0, h1 = floor(t0, Hour), ceil(t1, Hour)
    return length(SpaceDataModel.available(dataset(site), h0, h1)) == length(h0:Hour(1):(h1 - Hour(1)))
end

"""
    load(site, t0, t1) -> (; t0, H, D, freq, sens, phase)

Coil voltage of the whole hourly files covering `[t0, t1)`, from the first epoch `t0`, with
the first file's sensitivity (V/nT) and phase (deg) tables, rows H, D, Z. Z is dropped: its
sensitivity row is fill.

`nothing` if any hour is missing: the files concatenate without gap checks, so a partial set
would read as a continuous record.
"""
function load(site, t0, t1)
    available(site, t0, t1) || return nothing
    c = SpaceDataModel.getdata(dataset(site), floor(t0, Hour), ceil(t1, Hour))
    d = Float64.(c["db_dt"][:, :])
    return (; t0 = DateTime(c["epoch_db_dt"][1]), H = d[1, :], D = d[2, :],
        freq = Float64.(c["frequency"][:]), sens = Float64.(c["sensitivity"][:, :]),
        phase = Float64.(c["phase_difference"][:, :]))
end

# The tables hold Float32 decimals, so the 0.1 Hz row reads back as 0.10000000149.
const FTOL = 1.0e-6

# Table value at `f`, interpolated against log f (and log y if `logy`) over entries passing
# `valid`; NaN outside the table, no extrapolation.
function interp_table(freq, y, f, valid; logy)
    ks = findall(valid, y)
    length(ks) >= 2 || return NaN
    fr = freq[ks]
    v = logy ? log.(y[ks]) : y[ks]
    fr[1] * (1 - FTOL) <= f <= fr[end] * (1 + FTOL) || return NaN
    out = if f >= fr[end]
        v[end]
    elseif f <= fr[1]
        v[1]
    else
        j = searchsortedlast(fr, f)
        v[j] + (log(f) - log(fr[j])) / (log(fr[j + 1]) - log(fr[j])) * (v[j + 1] - v[j])
    end
    return logy ? exp(out) : out
end

"Sensitivity (V/nT) of component `comp` (1 = H, 2 = D) at `f`, log-log interpolated."
sensitivity(rec, comp::Integer, f) =
    interp_table(rec.freq, view(rec.sens, comp, :), f, s -> isfinite(s) && s > 0; logy = true)

"Response phase (deg) of component `comp` at `f`, interpolated against log f."
response_phase(rec, comp::Integer, f) =
    interp_table(rec.freq, view(rec.phase, comp, :), f, p -> isfinite(p) && p > -1.0e20; logy = false)

"Sample index of `t` in a record starting at `t0`, clamped to `1:n`."
sample_index(t0::DateTime, t::DateTime, n) =
    clamp(round(Int, Dates.value(t - t0) / 1000 * SAMPLE_RATE) + 1, 1, n)

"Time of sample `k` of a record starting at `t0`."
sample_time(t0::DateTime, k) = t0 + Millisecond(round(Int, 1000 * (k - 1) / SAMPLE_RATE))

"""
    psd(rec, idx = eachindex(rec.H); nfft = NFFT) -> (f, P)

Transverse power spectral density (nT²/Hz) over samples `idx`: Welch on the coil voltage over
squared sensitivity, H and D summed.

Raw dB/dt spectra, as the archive quicklooks show them, overstate 1 Hz against 0.1 Hz by up to
two decades: the coil response rises ∝ f through the Pc1 band. H + D because ducted Pc1
arrives with an arbitrary, often near-linear polarisation axis.
"""
function psd end

"`psd` against time: `(; time, f, P)`, `time` in seconds from `rec.t0`."
function dynamic_spectrum end

"""
    dynamic_stokes_v(rec; nfft = NFFT, navg = 8) -> (; time, f, v_over_i)

Normalised Stokes V of the calibrated horizontal field, `2imag(B_H B_D*) / (|B_H|² + |B_D|²)`,
with cross and auto spectra averaged over `navg` adjacent STFT slices.
"""
function dynamic_stokes_v end

end
