module ERGData

using Dates
using CDFDatasets
using SpaceDataModel: Registry, Dataset, Archive, FilePattern, localize, remotefiles
using SpaceDataModel: getdata, available

export getdata, available
export MGF, HEP, LEPe, LEPi, MEPe, MEPi, XEP, ORB, PWE_EFD, PWE_OFA, PWE_HFA

const ERG_BASE_URL = "https://ergsc.isee.nagoya-u.ac.jp/data/ergsc"

include("instruments.jl")

end
