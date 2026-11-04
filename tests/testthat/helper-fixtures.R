fixture <- function (name) {
    testthat::test_path ("fixtures", name)
}

# Known content of fixtures/denmark-mini.osm.pbf (a ~96 KB extract of
# tests/../../test-data/denmark-260713.osm.pbf around central Copenhagen,
# `osmium extract --strategy simple`), established once via
# `osmium fileinfo --extended fixtures/denmark-mini.osm.pbf` and pinned
# here as the ground truth these tests check against.
mini_counts <- list (nodes = 5735L, ways = 905L, relations = 31L)

# A relation known to be present in fixtures/denmark-mini.osm.pbf (a
# building multipolygon), for getid()/tags-filter tests.
mini_relation_id <- "r165391"

# A way known to be present, tagged highway=pedestrian.
mini_highway_way_id <- "w12645062"

skip_if_no_osmium_cli <- function () {
    testthat::skip_if (Sys.which ("osmium") == "", "system osmium CLI not available for cross-validation")
    # The binary may exist on the PATH yet be unusable (e.g. broken shared
    # library links after a system upgrade), so check that it actually runs.
    works <- tryCatch (
        suppressWarnings (system2 ("osmium", "--version", stdout = FALSE, stderr = FALSE)) == 0L,
        error = function (e) FALSE
    )
    testthat::skip_if_not (works, "system osmium CLI is present but not runnable")
}
