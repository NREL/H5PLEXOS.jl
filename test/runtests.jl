using H5PLEXOS

zipfiles = ["Model Base_8200 Solution.zip",
            "Model DAY_AHEAD_ALL_TX Solution.zip",
            "Model DA_h2hybrid_SCUC_select_lines_Test_1day Solution.zip",
            "Model DAY_AHEAD_PRAS Solution.zip"]

testfolder = dirname(@__FILE__) * "/"

for zipfile in zipfiles
    println(zipfile)
    zippath = testfolder * zipfile
    # TODO: Actually test things
    process(zippath, replace(zippath, ".zip" => ".h5"))
end
