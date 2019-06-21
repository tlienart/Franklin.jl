# NEWS

## v0.2

Thanks a lot to @Invarianz, @cserteGT3 and @mbaz for help and feedback leading to this version.

**Features**

* [docs](https://tlienart.github.io/JuDoc.jl/dev/man/syntax/#Code-insertions-1) - Julia code blocks can now be evaluated on the fly and their output displayed
* [docs](https://tlienart.github.io/JuDoc.jl/dev/man/syntax/#File-insertions-1) - Additional convenience commands for insertions (`\file`, `\figalt`, `\fig`, `\output`, `\textoutput`)
* [docs](https://tlienart.github.io/JuDoc.jl/dev/man/syntax/#More-on-paths-1) - More consistent use of relative paths for inserting assets and keeping folders organised
* [docs](https://tlienart.github.io/JuDoc.jl/dev/man/syntax/#Hyper-references-1) - `\label` allows to define anchor points for convenient hyper-references, also header sections are now anchor points themselves
* [docs](https://tlienart.github.io/JuDoc.jl/dev/#External-dependencies-1) - Users can now specify the paths to the python, pip and node executables via `ENV` if they prefer to do that
* [docs](https://tlienart.github.io/JuDoc.jl/dev/man/workflow/#Hosting-the-website-as-a-project-website-1) - Allow a site to be hosted as a project website (where the root is `/project/` instead of just `/`)

**Bug fixes**

* better error message if starting the server from the wrong dir ([#155](https://github.com/tlienart/JuDoc.jl/issues/155))
* numerous fixes for windows (read-only files, paths errors, installation instructions, ...) ([#179](https://github.com/tlienart/JuDoc.jl/issues/179), [#177](https://github.com/tlienart/JuDoc.jl/issues/177), [#174](https://github.com/tlienart/JuDoc.jl/issues/174), [#167](https://github.com/tlienart/JuDoc.jl/issues/167), [#16](https://github.com/tlienart/JuDoc.jl/issues/16)0)
* fix an issue when mixing code, italic/bold (whitespace issue) ([#163](https://github.com/tlienart/JuDoc.jl/issues/163))
* (_in 1.3_) fix an issue with parsing of nested code blocks within an escape block and paths issues ([#151](https://github.com/tlienart/JuDoc.jl/issues/151), [#15](https://github.com/tlienart/JuDoc.jl/issues/15)0)
* (_in 1.2_) fix a problem with the use of `@async` which caused hyper references to fail
* (_in 1.1_) fix toml issues and bumped KaTeX up to 0.10.2

**Templates**

* [docs](https://tlienart.github.io/JuDoc.jl/dev/man/themes/#Adapting-a-theme-to-JuDoc-1) - how to adapt a theme to JuDoc / add a new template
* [demo](https://tlienart.github.io/JuDocTemplates.jl/) - a few new template: `template=sandbox`, an ultra bare bone site to just play with the JuDoc syntax and try things out; `template=hyde`, `template=lanyon`, well-known templates adapted from Jekyll.
