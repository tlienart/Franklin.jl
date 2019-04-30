# Contributing

Contributions, questions and comments are very welcome.
In particular, I can see two main ways you can contribute:

1. use JuDoc, ask questions, report bugs or ask for features by [opening issue(s)](https://github.com/tlienart/JuDoc.jl/issues/new),
1. suggest improvements to the code, html generation, or themes.

The first one is self-explanatory, please just check that your issue is somewhat aligned with the [Judoc spirit](#Judoc-spirit-1).

For the second one, all suggestions will be welcome though I will prioritise help in the following three areas which I believe would make the user experience better:

1. _bug fixes_,
1. _error handling_: at the moment the error handling is basic to say the least, anything to would help errors being better/more sensibly handled would be great,
1. _improving the templates_: the current templates are meant to be simple and easily adjustable but there could be more of them and they may be improved to have better cross-browser support, responsiveness etc. For template improvement, please refer to [JuDocTemplates.jl](https://github.com/tlienart/JuDocTemplates.jl).


## JuDoc spirit

Some of the key objectives of JuDoc are to have a package that...

* can be used easily by people who have little experience with web-dev,
* is in Julia, is fast™ for local editing, and can be easily extended,
* generates pages that are light and load very quickly.

In particular, for the last point, I would favour theme contributions that minimise the use of complex javascript libraries or intricate CSS stylesheets if possible.
Beyond trying to avoid the [bloated](https://idlewords.com/talks/website_obesity.htm) [web](https://pxlnv.com/blog/bullshit-web/), I will be more supportive of extensions that avoid intruding on people's privacy.
Although it is trivial to plug in elements like Google Analytics, Discourse comments or social media buttons in the templates, it is not done by default for a reason;
I'd prefer writing docs that explains how to add those than to add them by default 😅 .

If you know of good alternatives, open issues!
For instance the GitHub-issues based comment system [utterances](https://github.com/utterance/utterances) looks great (but I haven't tried it yet).
