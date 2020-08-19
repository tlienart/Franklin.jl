@def hascode = true

# Generating auxiliary files with Literate

See also [how to interact with literate scripts](/code/literate/).

[Literate.jl](https://github.com/fredrikekre/Literate.jl) allows to pre and post-process a script in order, for instance, to generate a notebook out  of a script.
This can be convenient if you want to have a tutorial be downloadable as a standalone notebook or as a scrubbed script.

This page presents one way  of doing this which is used in [MLJTutorials](https://github.com/alan-turing-institute/MLJTutorials) and which  might inspire your own approach.

The key ingredients are:

@@tlist
1. use Literate to generate derived files,
1. use `gh-pages` to push the generated file to GitHub,
1. add this as a `final` hook to `publish`.
@@

In what follows, it is assumed you have your Literate scripts  in a folder `/scripts/` and that you're using GitHub.
It shouldn't be hard  to modify that to suit your own case.


## Using Literate to generate auxiliary files

Literate can manipulate scripts fairly easily, for instance to  generate notebooks:

```julia
scripts = joinpath.("scripts", readdir("scripts"))
nbpath = joinpath("generated", "notebooks")
isdir(nbpath) || mkpath(nbpath)

for script in scripts
   # Generate annotated notebooks
   Literate.notebook(script, nbpath,
                     execute=false, documenter=false)
end
```

This will go over all scripts in `/scripts/` and call `Literate.notebook` to generate a derived notebook in a `/generated/` folder (which you will want to add to your `.gitignore`).

## Push the generated files to a page branch

Start by installing  `gh-pages` with `npm`:

```bash
$> npm install gh-pages
```

Using the package [NodeJS.jl](https://github.com/davidanthoff/NodeJS.jl) it is then easy to use `gh-pages` to push the generated notebooks to a folder on the `gh-pages` branch:

```julia
using NodeJS

JS_GHP = """
    var ghpages = require('gh-pages');
    ghpages.publish('generated/', function(err) {});
    """

run(`$(nodejs_cmd()) -e $JS_GHP`)
```

Now these generated files are available on that branch without polluting your `master` branch.
You can see this live on the [MLJTutorials repo](https://github.com/alan-turing-institute/MLJTutorials/tree/gh-pages).

You can link to these generated notebooks with links adapted from:

```plaintext
https://raw.githubusercontent.com/username/project/gh-pages/notebooks/theNotebook.ipynb
```

See [this page](https://alan-turing-institute.github.io/MLJTutorials/pub/isl/lab-2.html) for example.

## Add the whole process to `publish`

You may want to re-generate all notebooks prior to pushing updates to GitHub.
For this, use the `final` keyword of `publish` to which you can pass a function to use before publishing updates.
For instance:

```julia
function gen_literate()
    scripts = joinpath.("scripts", readdir("scripts"))
    nbpath  = joinpath("generated", "notebooks")
    isdir(nbpath) || mkpath(nbpath)

    for script in scripts
       # Generate annotated notebooks
       Literate.notebook(script, nbpath,
                         execute=false, documenter=false)
    end
    JS_GHP = """
        var ghpages = require('gh-pages');
        ghpages.publish('generated/', function(err) {});
        """
    run(`$(nodejs_cmd()) -e $JS_GHP`)
end
# ... serve etc ...
# ... then finally ...
publish(final=gen_literate)
```
