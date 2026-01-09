using ERGData
using Test
using Aqua

@testset "ERGData.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(ERGData)
    end
    # Write your tests here.
end
