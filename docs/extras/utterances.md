@def hascode = true

# Add comments with utterances

\toc\skipline

Although Franklin generates static sites, you can add a comment widget to any webpage by using an external commenting system. There are several such systems, which work through some javascript or iframe code embedded in the page. The code works by calling an external server or app that handles the comment database and the interface with the user.

We describe below how to implement a comment widget through [utterances](https://utteranc.es), which is a free, open-source, no-ads solution, which is pretty easy to set up. All the comments are saved in a Github repository of your choosing, which can be the same repo that hosts the website or a different one. Each page that contains the javascript code for utterances is associated with an issue in the selected repository, and all the comments on that page are added as comments to that issue.

The comments on your page work just like comments in github issues, which means they have markdown rendering, code highlighting, and the basic github reaction emojis. Unfortunately, github's markdown does not render latex formulas, but they can be added by using an external renderer as described in [
a-rodin/A hack for showing LaTeX formulas in GitHub markdown.md](https://gist.github.com/a-rodin/fef3f543412d6e1ec5b6cf55bf197d7b). It's not as friendly but is doable. It is the same render used by Github to display jupyter notebooks.

A notable thing missing from utterances are nested replies. Another drawback is that, since it is based on Github issues, any user that wants to leave a comment has to have a Github account and log in to proceed.

If one is interested in trying other comment engines, here is a list of options, with some of them being paid and/or closed source: [Commento](https://commento.io), [GraphComment](https://graphcomment.com/en/), [IntenseDebate](https://intensedebate.com), [Isso](https://posativ.org/isso/),  [Muut](https://muut.com), [Remark42](https://github.com/umputun/remark42), [StaticMan](https://staticman.net), and [Talkyard](https://www.talkyard.io).

## Pre-requisites

The installation is pretty simple, and the [utterances](https://utteranc.es) page is clear in explaining it. Here is a quick rundown of the configuration.

### Selecting the repository for storing the comments

You need to choose a repository for storing the comments. It can be the same repository for the website, in case your site is hosted on Github, or a different repository, if so you wish or need.

The selected page has to be public, so your commentators can write to it via utterances. In fact, utterances just provides the interface. The comment itself is owned by the user and can, in fact, also be written and accessed directly at the repo.

### Installing the utterances app

There is an [utterances app](https://github.com/apps/utterances) that needs permission to access your Github repo in order to write the comments. It is just a matter of clicking the `Configure` button that appears on the app's page and following the steps to select the right repository.

### Configuring the javascript code

With the name of the repository at hand and the utterances app installed, it is time to configure the javascript code that is going to be inserted in the desired pages.

There are two required configurations to be made:

@@tlist
- *The blog post issue mapping*, which defines the form of the name to be given to the issue associated with each page containing the comment widget. There are a few options, as described in the [utterances](https://utteranc.es) page. The default is to have the title of the issue be the page pathname.
- *The theme for the widget*. The default is "Github Light", but there are a few others.
@@

And there is one optional configuration:

@@tlist
- *The issue label*, which is the title of the comment widget. The default is simply "Comment", but you can change it at will.
@@

The script itself has the general form

```html
<script src="https://utteranc.es/client.js"
        repo="[ENTER REPO HERE]"
        issue-term="pathname"
        theme="github-light"
        crossorigin="anonymous"
        async>
</script>
```

One can directly edit the `repo`, `issue-term` and `theme` fields above or just fill out the corresponding forms in [utterances](https://utteranc.es) that the proper filled-out script shows up that the end of the page for copying and pasting.

The *issue label* is optional, so it does not appear in the script above, but if you want something different than "Comment", then the argument `label="Comment"` should be added to the script, with whatever you want in place of "Comment".

## Adding the comment widget

With the javascript code ready, you need to add it to the desired page, be it a blog post or any other page. Of course, you can just add the code above directly to a html file, or inject it into a markdown file by fencing it with `~~~...~~~`.

But if you want to add it to several pages, as in posts for a blog, the best way is to add an `hfun_*` function to `utils.jl` and simply call this function at the end of each page.

For instance, the following function will do it

```julia
"""
    {{ addcomments }}

Add a comment widget, managed by utterances <https://utteranc.es>.
"""
function hfun_addcomments()
    html_str = """
        <script src="https://utteranc.es/client.js"
            repo="[ENTER REPO HERE]"
            issue-term="pathname"
            label="Comment"
            theme="github-light"
            crossorigin="anonymous"
            async>
        </script>
    """
    return html_str
end
```

Then, at the end of a markdown file, you just need to add

```html
{{ addcomments }}
```

With that done, each time someone leaves a comment on a page, the comment will be written to the repo, and you will receive an email from Github telling you so.

## Working example

Prof. Ricardo Rosa's website uses Utterances for comments:

@@flist
* [example page](https://rmsrosa.github.io/blog/2021/02/time_ave_bounds_SoS/)
* [source repo](https://github.com/rmsrosa/rmsrosa.github.io)
@@

Kind thanks to Ricardo who kindly wrote most of this page 💯.
