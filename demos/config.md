+++
using DelimitedFiles

author = "Thibaut Lienart"
prepath = "demos"
generate_rss = false
mintoclevel = 2
maxtoclevel = 3
mathjax = false
ignore = ["foo/content.md"]
weave = false

isAppleARM = Sys.isapple() && Sys.ARCH === :aarch64

# supports question 001
members_from_csv = eachrow(readdlm("_assets/members.csv", ',', skipstart=1))
+++

<!-- supports question 003 -->
\newcommand{\prettyshow}[1]{@@code-output \show{#1} @@}
