using ERGData
using Test
using Aqua
using Dates
using SpaceDataModel: remotefiles

@testset "Code quality (Aqua.jl)" begin
    Aqua.test_all(ERGData)
end

@testset "Registry selection" begin
    product = MGF[datatype = "8sec"]
    @test NamedTuple(product.selectors) == (; level = "l2", datatype = "8sec")
    # An unknown datatype names the ones the archive has.
    @test_throws ArgumentError MGF[datatype = "1hz"]
    @test only(remotefiles(product.source.pattern, Date(2017, 3, 27), Date(2017, 3, 28); version = "01")) ==
        "https://ergsc.isee.nagoya-u.ac.jp/data/ergsc/satellite/erg/mgf/l2/8sec/2017/03/erg_mgf_l2_8sec_20170327_v01.cdf"

    ds = getdata(product, Date(2017, 3, 27), Date(2017, 3, 28))
    @test haskey(ds, "epoch_8sec")
    @test haskey(ds, "mag_8sec_sm")
    close(ds)
end

@testset "High-rate MGF is hourly" begin
    # 64hz files are one per hour; a daily cadence would ask for hour 00 and miss the rest.
    product = MGF[datatype = "64hz", coord = "gse"]
    us = remotefiles(product.source.pattern, Date(2017, 3, 27), Date(2017, 3, 28); version = "01")
    @test length(us) == 24
    @test first(us) ==
        "https://ergsc.isee.nagoya-u.ac.jp/data/ergsc/satellite/erg/mgf/l2/64hz/2017/03/erg_mgf_l2_64hz_gse_2017032700_v01.cdf"
end

@testset "Orbit layouts" begin
    # def drops the month directory and the datatype from the file name; pre keeps both.
    @test only(remotefiles(ORB[datatype = "def"].source.pattern, Date(2017, 3, 27), Date(2017, 3, 28); version = "01")) ==
        "https://ergsc.isee.nagoya-u.ac.jp/data/ergsc/satellite/erg/orb/def/2017/erg_orb_l2_20170327_v01.cdf"
    @test only(remotefiles(ORB[datatype = "pre"].source.pattern, Date(2017, 3, 27), Date(2017, 3, 28); version = "01")) ==
        "https://ergsc.isee.nagoya-u.ac.jp/data/ergsc/satellite/erg/orb/pre/2017/03/erg_orb_pre_l2_20170327_v01.cdf"
end


@testset "PWE layouts" begin
    @test only(remotefiles(PWE_EFD[datatype = "E64Hz"].source.pattern, Date(2022, 6, 3), Date(2022, 6, 4); version = "01_03")) ==
        "https://ergsc.isee.nagoya-u.ac.jp/data/ergsc/satellite/erg/pwe/efd/l2/E64Hz/2022/06/erg_pwe_efd_l2_E64Hz_dsi_20220603_v01_03.cdf"
    @test only(remotefiles(PWE_HFA[].source.pattern, Date(2022, 6, 3), Date(2022, 6, 4); version = "01_02")) ==
        "https://ergsc.isee.nagoya-u.ac.jp/data/ergsc/satellite/erg/pwe/hfa/l2/spec/high/2022/06/erg_pwe_hfa_l2_spec_high_20220603_v01_02.cdf"
    @test only(remotefiles(PWE_HFA[datatype = "1min"].source.pattern, Date(2022, 8, 11), Date(2022, 8, 12); version = "05_09")) ==
        "https://ergsc.isee.nagoya-u.ac.jp/data/ergsc/satellite/erg/pwe/hfa/l3/2022/08/erg_pwe_hfa_l3_1min_20220811_v05_09.cdf"
end

@testset "ISEE induction" begin
    ds = ISEE_INDUCTION[site = "HUS"]
    @test ds.name == "ISEE_INDUCTION_HUS"
    # Sites are spelled as the archive's directories are, uppercased.
    @test_throws ArgumentError ISEE_INDUCTION[site = "hus"]
    us = remotefiles(ds.source.pattern, DateTime(2022, 6, 3, 20), DateTime(2022, 6, 3, 23); version = "01")
    @test length(us) == 3
    @test first(us) ==
        "https://ergsc.isee.nagoya-u.ac.jp/data/ergsc/ground/geomag/isee/induction/hus/2022/06/isee_induction_hus_2022060320_v01.cdf"
    # Hours the archive publishes, from its directory listing.
    hs = available(ISEE_INDUCTION[site = "HUS"], DateTime(2022, 6, 3, 20), DateTime(2022, 6, 3, 23))
    @test hs == DateTime(2022, 6, 3, 20):Hour(1):DateTime(2022, 6, 3, 22)
    # Files come back whole: 64 Hz for three hours, not clipped on the jittery epoch.
    rec = getdata(ISEE_INDUCTION[site = "HUS"], DateTime(2022, 6, 3, 20), DateTime(2022, 6, 3, 23))
    @test size(rec["db_dt"]) == (3, 3 * 3600 * 64)
    @test size(rec["sensitivity"]) == (3, 120)
end

@testset "Induction response tables" begin
    using ERGData.Induction: sensitivity
    # Float32 table rows: 0.1 Hz reads back as 0.10000000149 and must still match 0.1.
    rec = (; freq = Float64.(Float32[0.1, 1.0]), sens = [1.0 100.0])
    @test sensitivity(rec, 1, 0.1) ≈ 1
    @test sensitivity(rec, 1, sqrt(0.1)) ≈ 10       # log-log, not linear
    @test isnan(sensitivity(rec, 1, 2.0))
end
