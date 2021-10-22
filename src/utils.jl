const stdformat = DateFormat("yyyy-mm-ddTHH:MM:SS")

isobjects(coll::PLEXOSCollection) = coll.parentclass.name == "System"

phase_rgx = r"^t_phase_(\d)$"
phasenames = Dict{Int,String}()
phasetypes = Symbol[]
phasename(s::Symbol) = uppercase(string(s))

period_rgx = r"^t_period_(\d)$"
periodnames = Dict{Int,String}()
periodtypes = Tuple{Symbol,Symbol}[]
periodname(s::Symbol) = replace(string(s), r"^(.+)s$" => s"\1")

for x in plexostables

    phasematch = match(phase_rgx, x.name)
    if phasematch !== nothing
        phase = parse(Int, phasematch[1])
        phasenames[phase] = phasename(x.fieldname)
        push!(phasetypes, x.fieldname)
    end

    isnothing(x.timestampfield) && continue
    periodmatch = match(period_rgx, x.name)
    if periodmatch !== nothing
        periodtype = parse(Int, periodmatch[1])
        periodnames[periodtype] = periodname(x.fieldname)
        push!(periodtypes, (x.fieldname, x.timestampfield))
    end

end

function h5plexosname(coll::PLEXOSCollection)
    prefix = if isobjects(coll)
        ""
    elseif isnothing(coll.complementname)
        coll.parentclass.name * "_"
    else
        coll.complementname * "_"
    end
    return sanitize(prefix * coll.name)
end

function string_uint32_table!(
    f::HDF5.Group, tablename::String, strlen::Int,
    colnames::Tuple{String,String}, data::Vector{Tuple{String,UInt32}})

    nrows = length(data)

    stringtype_id = HDF5.h5t_copy(HDF5.hdf5_type_id(String))
    HDF5.h5t_set_size(stringtype_id, strlen)
    stringtype = HDF5.Datatype(stringtype_id)
    rowlen = strlen + sizeof(UInt32)

    dt_id = HDF5.h5t_create(HDF5.H5T_COMPOUND, rowlen)
    HDF5.h5t_insert(dt_id, first(colnames), 0, stringtype)
    HDF5.h5t_insert(dt_id, last(colnames), strlen, datatype(UInt32))

    rawdata = Vector{UInt8}(undef, rowlen * nrows)
    for (i, row) in enumerate(data)
        rowbytes = vcat(UInt8.(convertstring(first(row), strlen)),
                        reinterpret(UInt8, [last(row)]))
        rawdata[((i-1)*rowlen + 1):(i*rowlen)] = rowbytes
    end

    dset = create_dataset(f, tablename, HDF5.Datatype(dt_id),
                          HDF5.dataspace((nrows,)))

    HDF5.h5d_write(
        dset, dt_id, HDF5.H5S_ALL, HDF5.H5S_ALL, HDF5.H5P_DEFAULT, rawdata)

    return

end

function string_table!(
    f::HDF5.Group, tablename::String, strlen::Int,
    colnames::NTuple{N,String}, data::Vector{NTuple{N,String}}) where N

    nrows = length(data)

    stringtype_id = HDF5.h5t_copy(HDF5.hdf5_type_id(String))
    HDF5.h5t_set_size(stringtype_id, strlen)
    stringtype = HDF5.Datatype(stringtype_id)

    dt_id = HDF5.h5t_create(HDF5.H5T_COMPOUND, N * strlen)
    for (i, colname) in enumerate(colnames)
        HDF5.h5t_insert(dt_id, colname, (i-1)*strlen, stringtype)
    end

    strings = vcat(collect.(data)...)
    charlists = convertstring.(strings, strlen)
    rawdata = UInt8.(vcat(charlists...))

    dset = create_dataset(f, tablename, HDF5.Datatype(dt_id),
                    HDF5.dataspace((nrows,)))
    HDF5.h5d_write(
        dset, dt_id, HDF5.H5S_ALL, HDF5.H5S_ALL, HDF5.H5P_DEFAULT, rawdata)

    return

end

convertstring(s::AbstractString, strlen::Int) =
    Vector{Char}.(rpad(ascii(s), strlen, '\0')[1:strlen])

sanitize(s::AbstractString) = replace(lowercase(ascii(s)), " " => "")

function findsample(systemdata::PLEXOSSolutionDataset, samplename::String)
    i = findfirst(s -> s.name == samplename, systemdata.samples)
    isnothing(i) && error("Sample '$samplename' does not exist in the solution.")
    return systemdata.samples[i]
end
