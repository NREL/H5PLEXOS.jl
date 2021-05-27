module H5PLEXOS

import Dates: DateTime, DateFormat, format
import HDF5
import HDF5: attributes, create_group, create_dataset, h5open
import PLEXOSUtils: PLEXOSCollection, PLEXOSMembership, PLEXOSProperty,
                    PLEXOSKeyIndex, PLEXOSSolutionDataset, plexostables,
                    open_plexoszip

export process

const H5PLEXOS_VERSION = "v0.6.1"

include("process.jl")
include("utils.jl")

end # module
