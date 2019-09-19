using Documenter, ModelParams

makedocs(
    modules = [ModelParams],
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    checkdocs = :exports,
    sitename = "ModelParams",
    pages = Any["index.md"]
)

# deploydocs(
#     repo = "github.com/hendri54/ModelParams.git",
# )
