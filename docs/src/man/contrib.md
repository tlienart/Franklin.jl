# Contributing

All contributions are welcome and there are effectively two main ways you can contribute:

1. use JuDoc, ask questions, report bugs or ask for features by [opening issue(s)](https://github.com/tlienart/JuDoc.jl/issues/new),
1. suggest improvements to the code, html generation, or themes.

The first one is straightforward, please just quickly check that your issue is aligned with the [Judoc spirit](#Judoc-spirit-1).

For the second one, all suggestions are good to take though I will prioritise help in the following three areas which I believe would make the user experience better:

1. _bug fixes_: any fixes to problematic behaviour.
1. _error handling_: at the moment the error handling is basic to say the least, anything to would help errors being better/more sensibly handled would be great.
1. _improving the templates_: the current templates are meant to be simple and easily adjustable but there could be more of them and they may be improved to have better cross-browser support, responsiveness etc. For template improvement, please refer to [JuDocTemplates.jl](https://github.com/tlienart/JuDocTemplates.jl).


## JuDoc spirit

The key objectives of JuDoc is to have something that:

* can be used easily by people who have little experience with webdev,
* is in Julia, is fast™ for local editing, and can be easily extended,
* generates pages that are light and load very quickly,

In particular, for the last point, I would favour theme contributions that minimise the use of complex javascript libraries or intricate CSS stylesheets if possible.
