import CNetCDF

struct SwiftNetCDF {
    var text = "Hello, World!"
    var netCDFVersion = String(cString: nc_inq_libvers())
}

enum NetCDFError: Error {
    case ncerror(code: Int32, error: String)
}

/**
 NetCDF is not thread safe, but the Swift API uses threads heavily. Previously ALL requests for data had been moved to single thread queue. Using locks, many threads can perform data requests at once and only lock for a short time. Only 1 thread can access netcdf functions at any time.
 
 This is now thread safe, but not multi-threaded.
 */
let netcdfLock = Lock()

extension Lock {
    /**
     Execute a netcdf command in a thread safe lock and check the error code. Call fatal error otherwise.
     */
    func nc_exec(_ fn: () -> Int32) throws {
        let ncerr = withLock(fn)
        guard ncerr == NC_NOERR else {
            let error = String(describing: nc_strerror(ncerr))
            throw NetCDFError.ncerror(code: ncerr, error: error)
        }
    }
}
