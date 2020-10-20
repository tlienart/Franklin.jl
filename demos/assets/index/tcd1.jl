# This file was generated, do not modify it. # hide
#hideall
  save(SVG(joinpath(@OUTPUT, "tcd1.svg")),
       TikzCD(raw"""A \arrow[r, "\phi"] \arrow[d, red]
  & B \arrow[d, "\psi" red] \\
  C \arrow[r, red, "\eta" blue]
  & D"""))