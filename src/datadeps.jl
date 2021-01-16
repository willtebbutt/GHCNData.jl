"""
    const ghcn_root_dir

The location of the GHCN data.
"""
const ghcn_root_dir = "https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/"

"""
    const station_metadata_fname

Name of the file containing station metadata.
"""
const station_metadata_fname = "ghcnd-stations.txt"

"""
    const countries_fname

Name of the file containing country-code -- code pairing data set. See
`download_countries` and `parse_countries_metadata` for functionality.
"""
const countries_fname = "ghcnd-countries.txt"

"""
    const inventory_fname

Name of the inventory file in the GHCN daily data.
"""
const inventory_fname = "ghcnd-inventory.txt"

"""
    const ghcnd_data

Name of the file containing all of the ghcn daily data.
"""
const ghcnd_data = "ghcnd_all.tar.gz"
const ghcnd_data_dir = "ghcnd_all"

"""
    uncompress_all_data(fname=$ghcnd_data)

`download_all_data` obtained a `tar.gz`. This function uncompresses it.
"""
function uncompress_all_data(fname=ghcnd_data)
    unpack(fname)
end

# As per the suggestion in the DataDeps doc, we perform DataDep registration in __init__.
function __init__()
    register(DataDep(
        "ghcn-stations",
        "GHCN station metadata.",
        ghcn_root_dir * station_metadata_fname,
    ))
    register(DataDep(
        "ghcn-countries",
        "GHCN country codes.",
        ghcn_root_dir * countries_fname,
    ))
    register(DataDep(
        "ghcn-inventories",
        "GHCN country codes.",
        ghcn_root_dir * inventory_fname,
    ))
    register(DataDep(
        "ghcn-data",
        "GHCN country codes.",
        ghcn_root_dir * ghcnd_data,
        post_fetch_method=unpack,
    ))
end
