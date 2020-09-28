Pkg.activate("./docs")

using Documenter, ModelParams, FilesLH

makedocs(
    modules = [ModelParams],
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    checkdocs = :exports,
    sitename = "ModelParams",
    pages = Any["index.md"]
)

pkgDir = rstrip(normpath(@__DIR__, ".."), '/');
@assert endswith(pkgDir, "ModelParams")
deploy_docs(pkgDir);

Pkg.activate(".")

# deploydocs(
#     repo = "github.com/hendri54/ModelParams.git",
# )
