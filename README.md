
<!-- README.md is generated from README.Rmd. Please edit that file -->

# rosmium

<!-- badges: start -->

[![R-CMD-check](https://github.com/mpadge/rosmium/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/mpadge/rosmium/actions/workflows/R-CMD-check.yaml)
[![codecov](https://codecov.io/gh/mpadge/rosmium/branch/main/graph/badge.svg)](https://app.codecov.io/gh/mpadge/rosmium)
[![Project Status:
WIP](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
<!-- badges: end -->

R bindings for [`osmium-tool`](https://osmcode.org/osmium-tool/), a
command-line tool for working with OpenStreetMap (OSM) data built on the
[`libosmium`](https://osmcode.org/libosmium/) library. The package
contains R functions for most of the `osmium-tool` functionality
described in [the manual](https://osmcode.org/osmium-tool/manual.html).

**NOTE** Unlike most R packages, this package operates exclusively on
local files. The main functions generally return paths to files only,
rather than actual values. All workflows start with a local OSM extract,
with functions then enabling that to be cut, filtered, merged, or
otherwise transformed into new, modified versions also written to local
storage.

## Installation

You can install the development version of rosmium from
[GitHub](https://github.com/) with:

``` r
# install.packages("remotes")
remotes::install_github("mpadge/rosmium")
```

Then load for use:

``` r
library (rosmium)
```

## Example

The following sections demonstrate most of the main functionality.

### Local example data

As said above, all functions start with a local OSM data file. Here, we
grab a small real-world `.pbf` (Protocol Buffer Format) extract – the
“ITS Leeds” test file used in the [`osmextract`
package](https://docs.ropensci.org/osmextract/):

``` r
its_example <- osmextract::oe_match ("ITS Leeds", quiet = TRUE)

f <- osmextract::oe_download (
    file_url = its_example$url,
    file_size = its_example$file_size,
    provider = "test",
    download_directory = tempdir (),
    quiet = TRUE
)
```

### File information

`osmium_fileinfo()` reports header and content summary information,
mirroring `osmium fileinfo --extended`:

``` r
info <- osmium_fileinfo (input = f, extended = TRUE)
info$data$count
#> $changesets
#> [1] 0
#> 
#> $nodes
#> [1] 1678
#> 
#> $ways
#> [1] 294
#> 
#> $relations
#> [1] 14
```

### Geographic extraction

`osmium_extract()` trims a file down to a geographic boundary – given as
a bounding box here (`c(left, bottom, right, top)`), or alternatively a
`.poly`/GeoJSON polygon file via `polygon`. The default
`strategy = "complete_ways"` keeps every way with at least one node in
the box, pulling in its remaining nodes even if they fall outside it –
which is why the extract’s own bounding box below ends up slightly
larger than the box requested:

``` r
leeds_centre <- tempfile (fileext = ".osm.pbf")
osmium_extract (
    input = f,
    output = leeds_centre,
    bbox = c (-1.57, 53.803, -1.56, 53.809)
)

osmium_fileinfo (input = leeds_centre, extended = TRUE)$data$count
#> $changesets
#> [1] 0
#> 
#> $nodes
#> [1] 237
#> 
#> $ways
#> [1] 34
#> 
#> $relations
#> [1] 5
osmium_fileinfo (input = leeds_centre, extended = TRUE)$data$bbox
#> [1] -1.568766 53.804705 -1.558123 53.811020
```

### Filtering by tags and values

`osmium_tags_filter()` extracts objects matching a tag expression –
here, every way tagged `highway=*`, plus the nodes and relations they
reference:

``` r
highways <- tempfile (fileext = ".osm.pbf")
osmium_tags_filter (input = f, output = highways, expressions = "w/highway")
osmium_fileinfo (input = highways, extended = TRUE)$data$count
#> $changesets
#> [1] 0
#> 
#> $nodes
#> [1] 626
#> 
#> $ways
#> [1] 184
#> 
#> $relations
#> [1] 0
```

Or filter by both a tag and corresponding values, here both “cycleway”
and “footway”:

``` r
cycleways <- tempfile (fileext = ".osm.pbf")
osmium_tags_filter (
    input = f,
    output = cycleways,
    expressions = "w/highway=cycleway,footway"
)
osmium_fileinfo (input = cycleways, extended = TRUE)$data$count
#> $changesets
#> [1] 0
#> 
#> $nodes
#> [1] 315
#> 
#> $ways
#> [1] 76
#> 
#> $relations
#> [1] 0
```

### Conversion to other formats

The `output` argument to most functions can be a filename with any
suffix described in the “File formats” vignette. A suffix of `.osm`, for
example, generates output in `.osm` XML format:

``` r
cycleways <- tempfile (fileext = ".osm")
osmium_tags_filter (
    input = f,
    output = cycleways,
    expressions = "w/highway=cycleway,footway"
)
head (readLines (cycleways))
#> [1] "<?xml version='1.0' encoding='UTF-8'?>"                                                                                                                                
#> [2] "<osm version=\"0.6\" generator=\"osmium/1.19.1\">"                                                                                                                     
#> [3] "  <bounds minlat=\"53.8063025\" minlon=\"-1.5611959\" maxlat=\"53.8092928\" maxlon=\"-1.5498447\"/>"                                                                   
#> [4] "  <node id=\"21069418\" version=\"7\" timestamp=\"2018-06-25T11:30:43Z\" uid=\"2700471\" user=\"JayCBR\" changeset=\"60147062\" lat=\"53.8086048\" lon=\"-1.5525082\">"
#> [5] "    <tag k=\"crossing\" v=\"traffic_signals\"/>"                                                                                                                       
#> [6] "    <tag k=\"crossing_ref\" v=\"pelican\"/>"
```

This is the expected format for all functionality of [the `osmdata`
pacakge](https://docs.ropensci.org/osmdata), and the output file name
can be passed as the `doc` parameter to most functions there (like
[`osmdata_sf()`](https://docs.ropensci.org/osmdata/reference/osmdata_sf.html)
or
[`osmdata_sc()`](https://docs.ropensci.org/osmdata/reference/osmdata_sc.html)).

## All available commands

Each `osmium-tool` command vendored into rosmium has a corresponding
`osmium_*()` R function:

| Function | Wraps | Purpose |
|----|----|----|
| `osmium_cat()` | `osmium cat` | Concatenate OSM files and convert between formats |
| `osmium_export()` | `osmium export` | Export to GeoJSON, geopackage-friendly text, or PostgreSQL COPY format |
| `osmium_extract()` | `osmium extract` | Create a geographic extract (bbox, polygon, or config-file-defined) |
| `osmium_fileinfo()` | `osmium fileinfo` | Show header/content information about an OSM file |
| `osmium_getid()` | `osmium getid` | Get objects with given IDs (optionally with referenced objects) |
| `osmium_merge()` | `osmium merge` | Merge several sorted OSM files into one |
| `osmium_sort()` | `osmium sort` | Sort OSM data files by type then ID |
| `osmium_tags_filter()` | `osmium tags-filter` | Keep (or drop) objects matching tag expressions |

See each function’s documentation (e.g. `?osmium_extract`) for its full
set of options.
