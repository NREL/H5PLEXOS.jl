# H5PLEXOS

This package provides functionality for converting PLEXOS 8 .zip solution files
into H5PLEXOS-formatted HDF5 files (using H5PLEXOS format version 0.6).

## Installation

Installing this package requires adding the
`NREL` Julia package registry. If you've never used Julia before,
run `update` in the package management prompt to make sure the `General`
registry is installed first:

```julia
pkg> update
```

Now you can add the NREL registry:

```julia
pkg> registry add https://github.com/NREL/JuliaRegistry.git
```

Once this is done the package can be installed normally.

```julia
pkg> add H5PLEXOS
```

## Processing solutions

The module exports the  function `process` which handles conversion. For
example, to convert a file named `plexossolution.zip` to `plexossolution.h5`:

```julia
using H5PLEXOS
process("plexossolution.zip", "plexossolution.h5")
```

If processing the file is all you need to do in Julia, you may find it simpler
to call the function directly from the shell, rather than writing a script:

```sh
julia -e 'using H5PLEXOS; process("plexossolution.zip", "plexossolution.h5")'
```

The function accepts a number of keyword arguments to customize the process:

`compressionlevel`: Set the level of compression to be used (0-9).
Default is `1`.

`strlen`: PLEXOS object and category names are saved in the HDF5 file as
fixed-length strings. Use this parameter to adjust the length of those strings
(if long names are being truncated, for example). Default is `128`.

`dateformat`: A Julia `DateFormat` object explaining how to parse localized
timestamps reported by PLEXOS. Default is `DateFormat("d/m/y H:M:S")`.

`sample`: A `String` providing the name of the stochastic sample to be
processed. Defaults to `"Mean"`.

## Querying solutions

The package does does not currently provide tools for querying the generated
files (see the [h5plexos](https://github.com/NREL/h5plexos) Python package
for that). If you would be interested in having this functionality in Julia,
leave an issue or email Gord to let him know. Of course, you can always read
the HDF5 data directly with [HDF5.jl](https://github.com/JuliaIO/HDF5.jl).
