@def author = "Thibaut Lienart"
@def prepath = "demos"
@def generate_rss = false
@def mintoclevel = 2
@def maxtoclevel = 3
@def mathjax=false

<!-- supports question 001 -->
@def members_from_csv = eachrow(readdlm("_assets/members.csv", ',', skipstart=1))

@def ignore = ["foo/content.md"]

<!-- supports question 003 -->
\newcommand{\prettyshow}[1]{@@code-output \show{#1} @@}
