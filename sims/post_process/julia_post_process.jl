using HDF5
using LegendHDF5IO
using DataFrames, DataFramesMeta
using CSV
using SolidStateDetectors
using Unitful
using Plots; pyplot(fmt = :png);

raw_filename = "/Users/gothman/analysis/CAGE/sims//alpha/raw_out/test_newDet_sourceRotNorm_y6mm_ICPC_Pb_241Am_100000.hdf5"
outfilename = "/Users/gothman/analysis/CAGE/sims//alpha/processed_out/test_juliaProcess.csv"

# Read raw g4simple HDF5 output file and construct arrays of corresponding data
g4sfile = h5open(raw_filename, "r")
g4sntuple = g4sfile["default_ntuples"]["g4sntuple"]

event = g4sntuple["event"]["pages"]
energy = g4sntuple["Edep"]["pages"]
volID = g4sntuple["volID"]["pages"]
iRep = g4sntuple["iRep"]["pages"]
pid = g4sntuple["pid"]["pages"]
x = g4sntuple["x"]["pages"]
y = g4sntuple["y"]["pages"]
z = g4sntuple["z"]["pages"]

# Example of how to read data directly from the HDF5 file
# data = read(y)
# println("type: ", typeof(data),data)

# Construct a Julia DataFrame with the arrays we just constructed from the g4sfile data
raw_df = DataFrame(event = read(event), energy = read(energy), volID = read(volID), iRep = read(iRep), pid = read(pid), x = read(x), y = read(y), z = read(z))

# Filter by volID to get only interactions in the detector. In this case, volID is only either 0 or 1, and selecting gdf[2] selects volID=1
gdf = groupby(raw_df, :volID)
det_hits = gdf[2]

# Filter the new det_hits dataframe to only give hits that deposit more than 1 eV
hit_df = @where(det_hits, :energy.>1e-6)

# Calculate cylindrical coordinates r and phi from x and y positions and add them as a new column in the dataframe
hit_df.r = sqrt.((hit_df[!,:x]).^2 + (hit_df[!,:y]).^2)
hit_df.phi = atan.(hit_df[!,:y], hit_df[!,:x])

# Transform z variable. In sims, pass surface is at z = -22.5 mm, in SSD coords it's at z = 86.4 mm
ssd_coords_df = hit_df
ssd_coords_df.z = hit_df[!,:z].+(22.5+86.4)

# Write the final dataframe to lh5 file. First have to convert it to a table
table_test = Table(ssd_coords_df)

h5open("test_out.lh5", "w") do f
    LegendDataTypes.writedata(f, "forSSD_detHits", table_test)
end
