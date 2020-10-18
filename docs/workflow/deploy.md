<!--
reviewed: 18/10/20
-->

# Deploying your website

\blurb{Set it up once then don't think about it.}

\lineskip

\toc

\lineskip

Deploying the website is trivial on GitHub, Gitlab and services like Netlify.

## Deploying on GitHub

### Creating a repo on GitHub

Start by creating an empty GitHub repository

@@tlist
* for a personal (or org) website the repository **must** be named `username.github.io` (or `orgname.github.io`) see also [the github pages docs](https://pages.github.com/),
* for a project website the repo can be named anything you want, let's say `myWebsite`.
@@

### Synchronise your local folder

You now just need to synchronise your repository and your local website folder; to do so, go to your terminal, `cd` to the website folder and follow the steps below:

@@tlist
- `git init && git remote add origin URL_TO_YOUR_REPO`
- `git add -A && git commit -am "initial files"`
- `git push`
@@

the GitHub action will be triggered and deploy the content of the `__site` folder to  the `gh-pages` branch from which GitHub will deploy the website.

\note{It takes a couple of minutes for the whole process to complete.}

Once a green check mark appears on the GitHub repo like so:

![](/assets/img/action_check.png)

your site has finished building and the generated files are on the `gh-pages` branch.
If you see a red cross instead, click on it to see what failed, _usually_ if you manage to build your site locally, the build process should work on GitHub too.

The final step is to tell GitHub to deploy the `gh-pages` branch, for this, on the repository go to `Settings` then scroll down to `GitHub Pages` and in the `Source` dropdown, pick `gh-pages`.

Your website should now be online. To view it, on the repository page, click on `github-pages` in the right margin,

@@small-img ![](/assets/img/deployment.png)@@

then on `View deployment`.

@@small-img ![](/assets/img/deployment2.png)@@

### Examples

@@tlist
- [basic user webpage](https://github.com/tlienart2/tlienart2.github.io)
- [basic project webpage](https://github.com/tlienart2/myWebsite)
@@

### Customising the GitHub action

You might want to customise the GitHub action for instance:

@@tlist
- your website uses [`PyPlot.jl`](https://github.com/JuliaPy/PyPlot.jl) and so you need to make sure [`matplotlib`](https://matplotlib.org/) is installed,
- you want to apply some node library such as [`purgecss`](https://purgecss.com/)
- you want to disable minification or prerendering
- ...
@@

For all such operations, modify the file `.github/workflows/deploy.yml` in your site folder.
It should be fairly straightforward to see how to extend it but if you get stuck, ask on the **#franklin** slack channel.

### Troubleshooting

If something failed, that you can't debug, ask on the **#franklin** slack channel explaining what's the issue and we'll try to help you out.

## Deploying on GitLab

### Creating a repo on GitLab

Start by creating an empty GitLab repository

@@tlist
* for a personal website the repository **must** be named `username.gitlab.io` see also [the gitlab pages docs](https://about.gitlab.com/stages-devops-lifecycle/pages/),
* for a project website the repo can be named anything you want.
@@

### Synchronise your local folder

Now you need to synchronise your repository and your local website folder; to do so, go to your terminal, `cd` to the website folder and follow the steps below:

@@tlist
- `git init && git remote add origin URL_TO_YOUR_REPO`
- `git add -A && git commit -am "initial files"`
@@

That's it! when you push your updates to the `master` branch, the GitLab CI will copy the `__site` folder to a virtual `public` folder and deploy its content.

\note{It takes a couple of minutes for the whole process to complete and your site to be available online.}

## Deploying on Netlify

Synchronise your local website folder with a repository (e.g. a GitHub or GitLab repository) then select that repository on Netlify and indicate you want to deploy the `__site` folder.

That's it!
