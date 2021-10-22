module H5PLEXOS

import Dates: DateTime, DateFormat, format
import HDF5
import HDF5: attributes, create_group, create_dataset, datatype, h5open
import PLEXOSUtils: PLEXOSCollection, PLEXOSMembership, PLEXOSProperty,
                    PLEXOSSample, PLEXOSKeyIndex, PLEXOSSolutionDataset,
                    plexostables, open_plexoszip

export process

const H5PLEXOS_VERSION = "v0.6.2"

include("process.jl")
include("utils.jl")

end # module
