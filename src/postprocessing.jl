"""
    convert_to_time_series(df::DataFrame)

Converts a `DataFrame` loaded via `load_data_file` from the original format, in which each
row contains a month's worth of data for a particular ELEMENT (variable type e.g. precip,
temperature, etc), to a format in which each row contains a single day's worth of data with
for a single ELEMENT type. Only the element types already present in `df` will be included
in the new `DataFrame`.
"""
function convert_to_time_series(df::DataFrame)

    # A dataframe in which each lines containing a single day _and_ a single element.
    tmp = stack(df, 5:size(df, 2))

    # Compute day-of-month.
    tmp.DAY = map(x -> parse(Int, string(x)[6:end]), tmp.variable)

    # Filter to remove invalid dates.
    filter!(row -> Dates.validargs(Date, row.YEAR, row.MONTH, row.DAY) === nothing, tmp)

    # Merge date information into a single column.
    tmp.DATE = Date.(tmp.YEAR, tmp.MONTH, tmp.DAY)

    # Merge element and variable-type into a single underscore-separated column.
    tmp.col_index = map(zip(tmp.ELEMENT, tmp.variable)) do (element, variable)
        element * "_" * string(variable)[1:5]
    end

    # Drop redundant columns.
    tmp2 = tmp[!, [:DATE, :col_index, :value]]

    # Widen the currently very tall data frame.
    tmp3 = unstack(tmp2, [:DATE], :col_index, :value)

    # Reduce type unions over `Any` columns.
    for c in 2:size(tmp3, 2)
        name = names(tmp3)[c]
        if name[6:end] == "VALUE"
            tmp3[!, name] = convert(Vector{Union{Int, Missing}}, tmp3[!, name])
        else
            tmp3[!, name] = convert(Vector{Union{String, Missing}}, tmp3[!, name])
        end
    end

    # Re-order the data in a more natural order.
    sort!(tmp3, :DATE)

    return tmp3
end



"""
    select_data(
        time_interval::Tuple{Date, Date},
        lat_interval::Tuple{Real, Real},
        lon_interval::Tuple{Real, Real},
        element::String,
    )

Load all of the data from a particular region and time period of type `element` e.g. `TMAX`.
See section III of NOAA's readme [1] for more details on available elements.

Returns the results in a ...

Example:
```julia
using Dates, GHCNData
lat_interval = (50, 60);
lon_interval = (-10, 2);
time_interval = (Date(2010), Date(2020));
element = "TMAX"
data = select_data(time_interval, lat_interval, lon_interval, element)
```

[1] - https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/readme.txt
"""
function select_data(
    time_interval::Tuple{Date, Date},
    lat_interval::Tuple{Real, Real},
    lon_interval::Tuple{Real, Real},
    element::String,
)
    # Load all of the inventories.
    inventories = load_inventories()

    # Filter them to exclude stations whose data don't live inside the specified time period
    # and region.
    df = filter(inventories) do row
        row.ELEMENT == element &&
            lat_interval[1] < row.LATITUDE < lat_interval[2] &&
            lon_interval[1] < row.LONGITUDE < lon_interval[2] &&
            (
                time_interval[1] <= Date(row.FIRSTYEAR) <= time_interval[2] ||
                time_interval[1] <= Date(row.LASTYEAR) <= time_interval[2]
            )
    end

    # Load the data from the individual files.
    big_dfs = map(zip(enumerate(df.ID), df.LATITUDE, df.LONGITUDE)) do ((n, id), lat, lon)

        # Load the data and convert it into a time-series format.
        data = load_data_file(id)
        time_series = convert_to_time_series(data)

        # Extract only the columns requested.
        return DataFrame(
            "date" => time_series.DATE,
            "lat_lon_$n" => fill((lat, lon), size(time_series, 1)),
            "value_$n" => getproperty(time_series, Symbol(element * "_VALUE")),
        )
    end

    # Align all dates.
    joint_data_df = foldl(
        (a, b) -> leftjoin(a, b; on=:date, makeunique=true), big_dfs;
        init=DataFrame(date=time_interval[1]:Day(1):(time_interval[2]-Day(1))),
    )

    # Rearrange into a time x lat-lon matrix, and pull out lat-lon pairs.
    value_vecs = map(eachindex(df.ID)) do n
        return getproperty(joint_data_df, Symbol("value_$n"))
    end
    joint_data_matrix = collect(transpose(hcat(value_vecs...)))

    # Collect lat-lon pairs.
    lat_lon_pairs = map(eachindex(df.ID)) do n

        # These should all be missing or equal.
        lat_lon_vals = getproperty(joint_data_df, Symbol("lat_lon_$n"))

        # Pull out unique lat-lon pair.
        if all(ismissing, lat_lon_vals)
            return missing
        else
            return only(unique(filter(!ismissing, lat_lon_vals)))
        end
    end

    present_idx = findall(!ismissing, lat_lon_pairs)
    joint_data_matrix = joint_data_matrix[present_idx, :]
    lat_lon_pairs = lat_lon_pairs[present_idx]
    ID = df.ID[present_idx]

    return joint_data_matrix, lat_lon_pairs, ID
end
