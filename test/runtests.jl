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

