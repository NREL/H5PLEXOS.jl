function process(
    zipfilein::String, h5fileout::String;
    compressionlevel=1, strlen=128,
    timestampformat::DateFormat=DateFormat("d/m/y H:M:S"))

    systemdata, resultvalues = open_plexoszip(zipfilein)

    h5open(h5fileout, "w") do h5file::HDF5.File
        addconfigs!(h5file, systemdata)
        membership_idxs = addcollections!(h5file, systemdata, strlen, compressionlevel)
        addtimes!(h5file, systemdata, timestampformat, compressionlevel)
        addvalues!(h5file, systemdata, membership_idxs, resultvalues, compressionlevel)
    end

end

function addconfigs!(f::HDF5.File, data::PLEXOSSolutionDataset)

    rootattrs = attributes(f)
    rootattrs["h5plexos"] = H5PLEXOS_VERSION

    for config in data.configs
        rootattrs[config.element] = config.value
    end

end

function addcollections!(
    f::HDF5.File, data::PLEXOSSolutionDataset,
    strlen::Int, compressionlevel::Int)

    counts = Dict{PLEXOSCollection,Int}()

    for membership in data.memberships
        if membership.collection in keys(counts)
            counts[membership.collection] += 1
        else
            counts[membership.collection] = 1
        end
    end

    collections = Dict(
         collection => (Vector{Tuple{String,String}}(undef, counts[collection]), 0)
         for collection in keys(counts))

    membership_idxs = Dict{PLEXOSMembership, Int}()

    for membership in data.memberships

        collection = membership.collection
        collection_memberships, collection_idx = collections[collection]
        collection_idx += 1

        membership_idxs[membership] = collection_idx

        collection_memberships[collection_idx] =
            isobjects(collection) ?
                (membership.childobject.name, # object collection
                 membership.childobject.category.name) :
                (membership.parentobject.name, # relation collection
                 membership.childobject.name)

        collections[collection] = (collection_memberships, collection_idx)

    end

    h5meta = create_group(f, "metadata")
    h5objects = create_group(h5meta, "objects")
    h5relations = create_group(h5meta, "relations")

    for collection in keys(collections)

        collection_memberships, _ = collections[collection]
        name = h5plexosname(collection)

        group, colnames = isobjects(collection) ?
            (h5objects, ("name", "category")) :
            (h5relations, ("parent", "child"))

        string_table!(group, name, strlen, colnames, collection_memberships)

    end

    return membership_idxs

end

function addvalues!(
    f::HDF5.File, data::PLEXOSSolutionDataset,
    membership_idxs::Dict{PLEXOSMembership,Int},
    resultvalues::Dict{Int,Vector{UInt8}},
    compressionlevel::Int)

    propertybands = Dict{PLEXOSProperty,Int}()

    # Advance pass through keys to determine number of bands per property
    for key in data.keys
        if key.property in keys(propertybands)
            propertybands[key.property] =
                max(propertybands[key.property], key.band)
        else
            propertybands[key.property] = key.band
        end
    end

    h5data = create_group(f, "data")

    for ki in data.keyindices

        dset = dataset!(h5data, ki, propertybands, compressionlevel)
        member_idx = membership_idxs[ki.key.membership]

        start_idx = ki.position + 1
        end_idx = ki.position + 8*ki.length
        rawvalues = view(resultvalues[ki.periodtype], start_idx:end_idx)
        values = reinterpret(Float64, rawvalues)

        dset[ki.key.band, :, member_idx] = values

    end

end

function dataset!(h5data::HDF5.Group, ki::PLEXOSKeyIndex,
                  propertybands::Dict{PLEXOSProperty,Int},
                  compressionlevel::Int)

    collection = ki.key.membership.collection
    property = ki.key.property

    phase = phasenames[ki.key.phase]
    period = periodnames[ki.periodtype]
    coll = h5plexosname(collection)
    summarydata = property.issummary && (ki.periodtype != 0)
    prop = summarydata ? property.summaryname : property.name

    h5phase = haskey(h5data, phase) ? h5data[phase] : create_group(h5data, phase)
    h5period = haskey(h5phase, period) ? h5phase[period] : create_group(h5phase, period)
    h5coll = haskey(h5period, coll) ? h5period[coll] : create_group(h5period, coll)

    if haskey(h5coll, prop)

        dset = h5coll[prop]

    else

        nbands = propertybands[property]
        ntimes = ki.length

        collectiontype = isobjects(collection) ? "objects" : "relations"
        members = HDF5.root(h5data)["metadata/" * collectiontype * "/" * coll]
        nmembers = length(members)

        dset = create_dataset(h5coll, prop, HDF5.datatype(Float64),
                        HDF5.dataspace(nbands, ntimes, nmembers),
                        chunk=(nbands, ntimes, 1),
                        compress=compressionlevel)

        dset_attrs = attributes(dset)
        dset_attrs["period_offset"] = ki.periodoffset
        dset_attrs["units"] =
            summarydata ? property.summaryunit.value : property.unit.value

    end

    return dset

end

function addtimes!(f::HDF5.File, data::PLEXOSSolutionDataset,
                   localformat::DateFormat, compressionlevel::Int)

    # PLEXOS data format notes:
    # Period type 0 - phase-native interval / block data
    # Maps to ST periodtype 0 via relevant phase table
    # Store both block and interval results on disk (if not ST)?

    # Period type 1-7 - period-type-specific data
    # Direct mapping to period labels

    stdformat = DateFormat("yyyy-mm-ddTHH:MM:SS")
    h5times = create_group(f["metadata"], "times")

    periodtypes = [(t.fieldname, t.timestampfield)
                   for t in plexostables
                   if t.timestampfield !== nothing]

    for (dfield, pfield) in periodtypes

        uselocalformat = dfield == :intervals || dfield == :hours
        periodset = getfield(data, dfield)
        length(periodset) == 0 && continue

        period_dts = DateTime.(getfield.(periodset, pfield),
                               uselocalformat ? localformat : stdformat)
        issorted(period_dts) || error("$(string(dfield)) not sorted")
        h5times[periodname(dfield)] = format.(period_dts, stdformat)

    end

end
