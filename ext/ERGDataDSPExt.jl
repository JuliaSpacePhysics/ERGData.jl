module ERGDataDSPExt

using DSP: welch_pgram, spectrogram, stft, freq, power, hanning
using ERGData.Induction: SAMPLE_RATE, NFFT, sensitivity, response_phase
import ERGData.Induction: psd, dynamic_spectrum, dynamic_stokes_v

demean(v) = (x = Float64.(v); x .- sum(x) / length(x))
calibrated(p, rec, comp) = power(p) ./ [sensitivity(rec, comp, f)^2 for f in freq(p)]

function psd(rec, idx = eachindex(rec.H); nfft = NFFT)
    H, D = (welch_pgram(demean(view(v, idx)), nfft, nfft ÷ 2; fs = SAMPLE_RATE, window = hanning)
            for v in (rec.H, rec.D))
    return freq(H), calibrated(H, rec, 1) .+ calibrated(D, rec, 2)
end

function dynamic_spectrum(rec; nfft = NFFT)
    H, D = (spectrogram(demean(v), nfft, nfft ÷ 2; fs = SAMPLE_RATE, window = hanning)
            for v in (rec.H, rec.D))
    return (; H.time, f = freq(H), P = calibrated(H, rec, 1) .+ calibrated(D, rec, 2))
end

function dynamic_stokes_v(rec; nfft = NFFT, navg = 8)
    noverlap = nfft ÷ 2
    fq = (0:(nfft ÷ 2)) .* (SAMPLE_RATE / nfft)
    function calibrated_stft(comp, v)
        response = [sensitivity(rec, comp, f) * cis(deg2rad(response_phase(rec, comp, f))) for f in fq]
        return stft(demean(v), nfft, noverlap; fs = SAMPLE_RATE, window = hanning) ./ response
    end
    H, D = calibrated_stft(1, rec.H), calibrated_stft(2, rec.D)
    hop, n = nfft - noverlap, size(H, 2)
    time = collect(((nfft / 2):hop:((n - 1) * hop + nfft / 2)) ./ SAMPLE_RATE)
    v_over_i = fill(NaN, size(H))
    for j in axes(H, 2)
        lo = clamp(j - navg ÷ 2, 1, max(1, n - navg + 1))
        ks = lo:min(lo + navg - 1, n)
        cross = vec(sum(H[:, ks] .* conj.(D[:, ks]); dims = 2))
        total = vec(sum(abs2.(H[:, ks]) .+ abs2.(D[:, ks]); dims = 2))
        v_over_i[:, j] = clamp.(2 .* imag.(cross) ./ total, -1, 1)
    end
    return (; time, f = collect(fq), v_over_i)
end

end
