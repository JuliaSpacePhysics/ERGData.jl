using ERGData
using Documenter

DocMeta.setdocmeta!(ERGData, :DocTestSetup, :(using ERGData); recursive=true)

makedocs(;
    modules=[ERGData],
    authors="Beforerr <zzj956959688@gmail.com> and contributors",
    sitename="ERGData.jl",
    format=Documenter.HTML(;
        canonical="https://JuliaSpacePhysics.github.io/ERGData.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaSpacePhysics/ERGData.jl",
    devbranch="main",
)
