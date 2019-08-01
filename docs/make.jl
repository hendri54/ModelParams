using Documenter, ModelParams

makedocs(
    modules = [ModelParams],
    format = :html,
    checkdocs = :exports,
    sitename = "ModelParams.jl",
    pages = Any["index.md"]
)

deploydocs(
    repo = "github.com/hendri54/ModelParams.jl.git",
)
