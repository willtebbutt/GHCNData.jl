# GHCNData

[![Build Status](https://github.com/willtebbutt/GHCNData.jl/workflows/CI/badge.svg)](https://github.com/willtebbutt/GHCNData.jl/actions)
[![Coverage](https://codecov.io/gh/willtebbutt/GHCNData.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/willtebbutt/GHCNData.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://img.shields.io/badge/ColPrac-Contributor's%20Guide-blueviolet)](https://github.com/SciML/ColPrac)

Utility functionality to help getting hold of daily data from the Global Historical Climatology Network archive.

If you use this data, you should acknowledge it appropriately. Instruction for doing so can be found at the top of [NOAA's readme](https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/readme.txt).



# Why Bother?

While the GHCN data is fairly straightforward, it's not as simple as just downloading a single file and opening it as a `DataFrame`.
There are a few different kinds of files that you need to be aware of, each of which has a well-documented but non-standard format.
As such, it makes sense to implement the functionality to load the files in a format more amenable to standard workflows.


# Usage

## Data Loading

This package provides helper functions to download and load the data offered by NOAA. There are four core functions that you should be aware of
```julia
load_station_metadata
load_inventories
load_data_file
load_countries_metadata
```
Each of these functions download the corresponding data using [`DataDeps.jl`](https://github.com/oxinabox/DataDeps.jl) if it's not already available, and parses it into a [`DataFrame`](https://github.com/JuliaData/DataFrames.jl).

[NOAA's documentation](https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/readme.txt) is the best place to look to understand these files, but the docstrings in this package provide a brief overview.

## Typical Workflows

Commonly, you'll want to load all of the data associated with a particular collection of stations in a particular region of the world. There are basically two steps to do this:

1. Use `load_inventories()` to find out which stations exist at which latitudes / longitude, and their corresponding ID.
2. Use `load_data_file(station_id)` to load each station that you've found in your region of interest.

For an example of this kind of thing, see the code for `select_data` in `dataset_loading.jl`.

You might also be interested in, for example, the properties of the station in question (e.g. its elevation). For that data, use `load_station_metadata()`.

## Helper Functions

This package presently provides two bits of functionality to process the data a bit once it's been loaded.

`select_data` pretty much implements the workflow discussed above.

`convert_to_time_series` "stacks" the output of `load_data_file`, converting from 1 row == 1 month (different day's data live in different columns in the raw data), to a format in which 1 row == 1 day.

Both functions are quite opinionated, so while they're hopefully helpful examples of things that you might want to do with the GHCN data, you'll probably need to tweak them a bit for your use-case.



# Missing Functionality and Contributing

If you build on this functionality, please consider contributing back so that we can make all of our lives easier! Similarly, please open an issue (or, even better, a PR) if you feel that something that would be useful is missing.

Development has been driven on an as-needed basis, so while this is package will grab most (all?) of the daily data for you, it is a little sparse on utility functionality.
In particular, please note that `convert_to_time_series` and `select_data` may not make assumptions about the data that are appropriate for your use case. If in doubt, I would recommend using the functionality in `dataset_loading.jl`, as it just provides helpful functionality to extract the data.

Moreover, it doesn't currently implement anything to grab or process the monthly data, but it should be a straightforward extension of the existing functionality to do so.



# Bug Reporting

If you either find a bug, or think something looks suspicious, please open an issue / PR. When considering whether or not to open an issue / PR, note that it's generally better to open an issue erroneously (no harm is done if it turns out there wasn't a problem after all) than it is for a problem to slip by (data-related bugs cause papers to be retracted and generally hold back progress). If in doubt, open an issue.




# Why are there no tests?

I'm not really sure how to test this stuff using CI because it involves rather large data sets.
If you have any thoughts on how this might be made to work, please open an issue / PR.



# Related Work

Scott Hosking [provides similar functionality](https://github.com/scotthosking/get-station-data) in a Python package.
