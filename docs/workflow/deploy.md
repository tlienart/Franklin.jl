<!--
reviewed: 18/4/20
-->

# Deploying your website

\blurb{Set it up once then don't think about it.}

\lineskip

\toc

\lineskip

Deploying the website is trivial on Gitlab and services like Netlify. On GitHub there are a few extra steps **especially if you want a user/org website**.

## Deploying on GitHub

**Warning**: the setup to synchronise your local folder and the remote repository is _different_ based on whether you want a user/org website:
@@tlist
* a _user_ website has a base URL looking like `username.github.io`.
* a _project_ website has a base URL looking like `username.github.io/project/`.
@@
Make sure to follow the appropriate instructions!

### Creating a repo on GitHub

Start by creating an empty GitHub repository

@@tlist
* for a personal (or org) website the repository **must** be named `username.github.io` (or `orgname.github.io`) see also [the github pages docs](https://pages.github.com/),
* for a project website the repo can be named anything you want, let's say `myWebsite`.
@@

### Adding access tokens

In order for the deployment action to work on GitHub, you need to set up an access token on GitHub. The steps are explained below but you [can read more on the topic here](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line).

**STEP 1**:

@@tlist
* Make a public/private key pair on your local machine with `ssh-keygen -N "" -f franklin` ([see also here](https://help.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#generating-a-new-ssh-key) for more information about generating ssh keys).
* This creates 2 files, the private key: `franklin`, and the public key `franklin.pub`.
@@

**STEP 2**:

@@tlist
* Go to the repository and select *Settings > Secrets* then click on **Add new secret**,
* Name the secret `FRANKLIN_PRIV` and copy the contents of the **private key** (`franklin`) from the previous step.
@@

![](/assets/img/add_secret.png)

**STEP 3**:

@@tlist
* Go to the repository and select *Settings > Deploy keys* then click on **Add deploy key**,
* Name the deploy key `FRANKLIN_PUB` and copy the contents of the **public key** (`franklin.pub`) from step 1.
* Give the key write access.
@@

![](/assets/img/add_deploy_key.png)

**STEP 4**:

Remove both files (`franklin`, `franklin.pub`) from your local folder.

### Synchronise your local folder [User/Org website]

> This assumes that you're working on a user folder with base URL looking like  `username.github.io`. See [this example](https://github.com/tlienart2/tlienart2.github.io) for instance.

You need to synchronise your repository and your local website folder; to do so, go to your terminal, `cd` to the website folder and follow the steps below:

@@tlist
- `git init && git remote add origin URL_TO_YOUR_REPO`
- `git checkout -b dev`
- `git add -A && git commit -am "initial files"`
@@

It is **crucial** to change the branch to `dev` (or any other name that you like that is not `master`).
This is because a user/org site **must** be deployed from the `master` branch on GitHub.

Now, in an editor, open the file [`.github/workflows/deploy.yml`](https://github.com/tlienart2/tlienart2.github.io/blob/dev/.github/workflows/deploy.yml) and change the `on` section to

```yaml
on:
  push:
    branches:
      - dev
```

change also the `BRANCH` line at the end to `BRANCH: master`:

```yaml
BRANCH: master
FOLDER: __site
```

With all this, if you push changes to `dev` with

```
git push -u origin dev
```

the GitHub action will be triggered and deploy the content of the `__site` folder to  the `master` branch.
GitHub pages will then deploy the website from the master branch.

\note{It takes a couple of minutes for the whole process to complete and your site to be available online.}

\note{It is recommended to change your default branch on the repository to `dev` (GitHub may have done that automatically for you). To do this, click on *Settings > Branches* and select the default branch.}

### Synchronise your local folder [Project website]

> This assumes that you're working on a user folder with base URL looking like  `username.github.io/myWebsite`. See [this example](https://github.com/tlienart2/myWebsite) for instance.

Now you need to synchronise your repository and your local website folder; to do so, go to your terminal, `cd` to the website folder and follow the steps below:

@@tlist
- `git init && git remote add origin URL_TO_YOUR_REPO`
- `git add -A && git commit -am "initial files"`
@@

That's it! when you push your updates to the `master` branch, the [GitHub action](https://github.com/tlienart2/myWebsite/blob/master/.github/workflows/deploy.yml) will deploy the `__site` folder to  a `gh-pages` branch that GitHub Pages will then use to deploy your website.

\note{It takes a couple of minutes for the whole process to complete and your site to be available online.}

### Troubleshooting

@@tlist
- Make sure you have set the access tokens properly,
- Make sure GitHub Pages is pointing at the right branch (see screenshot below),
- Open an issue on Franklin's GitHub or ask on the **#franklin** juliaslack channel.
@@

![](/assets/img/deploy_branch.png)

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
