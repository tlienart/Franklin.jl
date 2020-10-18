<!--
reviewed: 18/10/20
-->

# RSS and Sitemap

\toc

## Sitemap

Franklin automatically generates a [sitemap](https://www.sitemaps.org/protocol.html) for your website which you can adjust as required.
By default, the sitemap will have an entry for every page on your website, with a default priority of `0.5` and a change frequency set to `monthly`.

For a given _markdown_ page (extension `.md`) you can change this by setting the following [page variables](/syntax/page-variables/):

@@tlist
- `sitemap_exclude`: set it to `false` to remove the page from the sitemap,
- `sitemap_changefreq`: the change frequency, it can be one of `["always", "hourly", "daily", "weekly", "monthly", "yearly", "never"]`,
- `sitemap_priority`: the relative priority of the page compared to other pages (a value between `0` and `1`).
@@

So for instance you could have in your markdown:

```plaintext
+++
sitemap_changefreq = "yearly"
sitemap_priority = 0.2
+++
```

For a given _html_ page (extension `.html`) you can also specify these options using the [`hfun`](/utils/#html_functions_hfun_) `sitemap_opts`:

```plaintext
{{sitemap_opts yearly 0.2}}
```

or to exclude the page from the sitemap

```plaintext
{{sitemap_opts exclude}}
```

Note that you can also disable the sitemap generation completely by setting the global page variable `generate_sitemap` to `false` in your `config.md`.

## RSS

Franklin supports generating an [RSS feed](https://validator.w3.org/feed/docs/rss2.html) for your website which you can adjust at will.
This is only supported for pages with a _markdown_ source for now and you must define the `rss` or `rss_description` page variable which will contain the short description corresponding to the RSS entry for instance:

```plaintext
@def rss = "This page is about XXX and YYY."
```

Click [here](/page-variables/#rss) for more details on the page variables related to the RSS feed.

Note that you can also disable the rss generation completely by setting the global page variable `generate_rss` to `false` in your `config.md`.
