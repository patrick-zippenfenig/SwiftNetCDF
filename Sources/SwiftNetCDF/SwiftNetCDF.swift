import CNetcdf

struct SwiftNetCDF {
    var text = "Hello, World!"
    var netCDFVersion = String(cString: nc_inq_libvers())
}
