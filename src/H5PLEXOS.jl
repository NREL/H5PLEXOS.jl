module H5PLEXOS

import Dates: DateTime, DateFormat, format
import HDF5
import HDF5: attrs, d_create, exists, g_create, h5open, HDF5File, HDF5Group
import PLEXOSUtils: PLEXOSCollection, PLEXOSMembership, PLEXOSProperty,
                    PLEXOSKeyIndex, PLEXOSSolutionDataset, plexostables,
                    open_plexoszip

export process

const H5PLEXOS_VERSION = "v0.6.0"

include("process.jl")
include("utils.jl")

end # module
