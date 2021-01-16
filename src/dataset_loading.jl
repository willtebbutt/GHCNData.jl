"""
    load_station_metadata() -> DataFrame

Loads the station metadata detailed in section 4 of [1], returning it in a `DataFrame` with
columns named according the the `Variable` column below:

```
------------------------------
Variable   Columns   Type
------------------------------
ID            1-11   Character
LATITUDE     13-20   Real
LONGITUDE    22-30   Real
ELEVATION    32-37   Real
STATE        39-40   Character
NAME         42-71   Character
GSN FLAG     73-75   Character
HCN/CRN FLAG 77-79   Character
WMO ID       81-85   Character
------------------------------
```

[1] - https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/readme.txt
"""
function load_station_metadata()
    raw_data = CSV.read(
        datadep"ghcn-stations" * "/" * station_metadata_fname, DataFrame;
        header=0, delim='\t',
    ).Column1
    N_stations = length(raw_data)

    parsed_data = (
        ID = Vector{String}(undef, N_stations),
        LATITUDE = Vector{Float32}(undef, N_stations),
        LONGITUDE = Vector{Float32}(undef, N_stations),
        ELEVATION = Vector{Float32}(undef, N_stations),
        STATE = Vector{String}(undef, N_stations),
        NAME = Vector{String}(undef, N_stations),
        GSN_FLAG = Vector{String}(undef, N_stations),
        HCN_CRN_FLAG = Vector{String}(undef, N_stations),
        WMO_ID = Vector{String}(undef, N_stations),
    )

    for (n, row) in enumerate(raw_data)
        parsed_data.ID[n] = row[1:11]
        parsed_data.LATITUDE[n] = parse(Float32, row[13:20])
        parsed_data.LONGITUDE[n] = parse(Float32, row[22:30])
        parsed_data.ELEVATION[n] = parse(Float32, row[32:37])
        parsed_data.STATE[n] = strip(row[39:40])
        parsed_data.NAME[n] = strip(row[42:71])
        parsed_data.GSN_FLAG[n] = strip(row[73:75])
        parsed_data.HCN_CRN_FLAG[n] = strip(row[77:79])
        parsed_data.WMO_ID[n] = strip(row[81:85])
    end

    return DataFrame(parsed_data)
end



"""
    load_countries_metadata() -> DataFrame

Loads the countries metadata detailed in section 5 of [1], returning the result as a
`DataFrame` with columns `CODE` and `NAME`.

[1] - https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/readme.txt
"""
function load_countries_metadata()
    raw_data = CSV.read(
        datadep"ghcn-countries" * "/" * countries_fname, DataFrame;
        header=0, delim='\t',
    ).Column1
    N_countries = length(raw_data)

    parsed_data = (
        CODE = Vector{String}(undef, N_countries),
        NAME = Vector{String}(undef, N_countries),
    )

    for (n, row) in enumerate(raw_data)
        parsed_data.CODE[n] = row[1:2]
        parsed_data.NAME[n] = strip(row[4:end])
    end
    return DataFrame(parsed_data)
end



"""
    load_inventories() -> DataFrame

Loads the inventory file detailed in section 7 of [1], and returns a `DataFrame` with
columns named according to the variables listed in the file-format information below.

```
------------------------------
Variable   Columns   Type
------------------------------
ID            1-11   Character
LATITUDE     13-20   Real
LONGITUDE    22-30   Real
ELEMENT      32-35   Character
FIRSTYEAR    37-40   Integer
LASTYEAR     42-45   Integer
------------------------------
```

[1] - https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/readme.txt
"""
function load_inventories()
    raw_data = CSV.read(
        datadep"ghcn-inventories" * "/" * inventory_fname, DataFrame;
        header=0, delim='\t',
    ).Column1
    N_stations = length(raw_data)

    parsed_data = (
        ID = Vector{String}(undef, N_stations),
        LATITUDE = Vector{Float32}(undef, N_stations),
        LONGITUDE = Vector{Float32}(undef, N_stations),
        ELEMENT = Vector{String}(undef, N_stations),
        FIRSTYEAR = Vector{Int}(undef, N_stations),
        LASTYEAR = Vector{Int}(undef, N_stations),
    )

    for (n, row) in enumerate(raw_data)
        parsed_data.ID[n] = row[1:11]
        parsed_data.LATITUDE[n] = parse(Float32, row[13:20])
        parsed_data.LONGITUDE[n] = parse(Float32, row[22:30])
        parsed_data.ELEMENT[n] = row[32:35]
        parsed_data.FIRSTYEAR[n] = parse(Int, row[37:40])
        parsed_data.LASTYEAR[n] = parse(Int, row[42:45])
    end

    return DataFrame(parsed_data)
end



"""
    load_data_file(station_id::String) -> DataFrame

See section 3 of [1].

```
------------------------------
Variable   Columns   Type
------------------------------
ID            1-11   Character
YEAR         12-15   Integer
MONTH        16-17   Integer
ELEMENT      18-21   Character
VALUE1       22-26   Integer
MFLAG1       27-27   Character
QFLAG1       28-28   Character
SFLAG1       29-29   Character
VALUE2       30-34   Integer
MFLAG2       35-35   Character
QFLAG2       36-36   Character
SFLAG2       37-37   Character
  .           .          .
  .           .          .
  .           .          .
VALUE31    262-266   Integer
MFLAG31    267-267   Character
QFLAG31    268-268   Character
SFLAG31    269-269   Character
------------------------------
```

[1] - https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/readme.txt
"""
function load_data_file(station_id::String)
    fdir = datadep"ghcn-data" * "/" * ghcnd_data_dir
    file_name = joinpath(fdir, station_id * ".dly")
    raw_data = CSV.read(
        file_name, DataFrame;
        header=0, delim='\t',
    ).Column1
    N_months = length(raw_data)

    # Construct a `NamedTuple` to store the parsed data.
    column_names = vcat(
        [:ID, :YEAR, :MONTH, :ELEMENT],
        map(1:31) do n
            [Symbol("VALUE$n"), Symbol("MFLAG$n"), Symbol("QFLAG$n"), Symbol("SFLAG$n")]
        end...,
    )
    columns = vcat(
        [
            Vector{String}(undef, N_months),
            Vector{Int}(undef, N_months),
            Vector{Int}(undef, N_months),
            Vector{String}(undef, N_months),
        ],
        map(1:31) do n
            [
                Vector{Union{Int, Missing}}(undef, N_months),
                Vector{String}(undef, N_months),
                Vector{String}(undef, N_months),
                Vector{String}(undef, N_months),
            ]
        end...,
    )

    # Specify the beginning and end location of each column of the data.
    column_locations = vcat(
        [(1, 11), (12, 15), (16, 17), (18, 21)],
        map(1:31) do n
            start_pos = 22 + 8 * (n - 1)
            [
                (start_pos, start_pos + 4),
                (start_pos + 5, start_pos + 5),
                (start_pos + 6, start_pos + 6),
                (start_pos + 7, start_pos + 7),
            ]
        end...,
    )

    # Iterate over the data.
    for (n, row) in enumerate(raw_data)
        for col in eachindex(columns)
            start_pos = first(column_locations[col])
            end_pos = last(column_locations[col])
            columns[col][n] = _to(eltype(columns[col]), row[start_pos:end_pos])
        end
    end

    return DataFrame(columns, column_names)
end

function _to(::Type{Union{Missing, T}}, s::String) where {T<:Number}
    if s == "-9999"
        return missing
    else
        return parse(T, s)
    end
end
_to(::Type{String}, s::String) = s
_to(::Type{Int}, s::String) = parse(Int, s)
