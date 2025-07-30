
<!-- README.md is generated from README.Rmd. Please edit that file -->

# flexfont

<!-- badges: start -->

![](https://img.shields.io/badge/cool-useless-green.svg)
[![CRAN](https://www.r-pkg.org/badges/version/flexfont)](https://CRAN.R-project.org/package=flexfont)
<!-- badges: end -->

`flexfont` is an R version of the javascript font
[flexflex](https://github.com/ronikaufman/flexflex) by Roni Kaufman.

This package includes a very minimal SVG path render. Arc path rendering
was borrowed from
[`{svgparser}`](https://github.com/coolbutuseless/svgparser).

### What’s in the box

- `flex_coords()` gives stroke information for drawing this font (in a
  data.frame). The user can then render this however they want.
- `flextextGrob()` is like `grid::textGrob()` but using this flex font

## Installation

<!-- This package can be installed from CRAN -->

<!-- ``` r -->

<!-- install.packages('flexfont') -->

<!-- ``` -->

You can install the latest development version from
[GitHub](https://github.com/coolbutuseless/flexfont) with:

``` r
# install.package('remotes')
remotes::install_github('coolbutuseless/flexfont')
```

Pre-built source/binary versions can also be installed from
[R-universe](https://r-universe.dev)

``` r
install.packages('flexfont', repos = c('https://coolbutuseless.r-universe.dev', 'https://cloud.r-project.org'))
```

# Creating a graphics object

``` r
library(grid)
x <- "abcdefghijklm\nnopqrstuvwxyz"
g1 <- flextextGrob(x, gp = gpar(lwd = 1.5), default.units = 'cm', vgap = 0.3, hgap = 0.2) 
grid.newpage(); 
grid.draw(g1)
```

<img src="man/figures/README-unnamed-chunk-2-1.png" width="100%" />

## Custom plotting of coordinates

This example illustrates how to get the raw coordinates for the letters
and plot manually.

``` r
library(flexfont)
library(ggplot2)  

coords <- flex_coords('hello\nrstats', w = 1.5, vgap = 0.3, hgap = 0.2)
head(coords)
#>   chr_idx chr stroke_idx   x             y
#> 1       1   h          1 0.0  5.551115e-17
#> 2       1   h          1 0.0 -1.000000e+00
#> 3       1   h          2 1.5  5.551115e-17
#> 4       1   h          2 1.5 -1.000000e+00
#> 5       1   h          3 0.0 -5.000000e-01
#> 6       1   h          3 1.5 -5.000000e-01

ggplot(coords) + 
  geom_path(aes(x, y, group = interaction(chr_idx, stroke_idx)), linewidth = 3, lineend = 'round') + 
  coord_equal() +
  theme_void()
```

<img src="man/figures/README-unnamed-chunk-3-1.png" width="100%" />

## Related Software

- [`{lofifonts`}](https://cran.r-project.org/package=lofifonts)
- [`{bittermelon}`](https://cran.r-project.org/package=bittermelon)
