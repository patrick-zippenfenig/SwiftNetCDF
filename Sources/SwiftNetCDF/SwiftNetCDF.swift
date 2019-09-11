import CNetCDF
import Foundation

struct SwiftNetCDF {
    var text = "Hello, World!"
    var netCDFVersion = String(cString: nc_inq_libvers())
}

enum NetCDFError: Error {
    case ncerror(code: Int32, error: String)
    case invalidVariable
    case badNcid
    case badVarid
    case badGroupid
    case badName
    case attributeNotFound
    case valueCanNotBeConverted
    
    init(ncerr: Int32) {
        switch ncerr {
        case NC_ENOTVAR: self = .invalidVariable
        case NC_EBADID: self = .badNcid
        case NC_ENOTVAR: self = .badVarid
        case NC_EBADGRPID: self = .badGroupid
        case NC_EBADNAME: self = .badName
        case NC_ENOTATT: self = .attributeNotFound
        default:
            let error = String(cString: nc_strerror(ncerr))
            self = .ncerror(code: ncerr, error: error)
        }
    }
}

/**
 NetCDF is not thread safe, but the Swift API uses threads heavily. Previously ALL requests for data had been moved to single thread queue. Using locks, many threads can perform data requests at once and only lock for a short time. Only 1 thread can access netcdf functions at any time.
 
 This is now thread safe, but not multi-threaded.
 */
let netcdfLock = Lock()

fileprivate var maxNameBuffer = [Int8](repeating: 0, count: Int(NC_MAX_NAME+1))

extension Lock {
    /**
     Execute a netcdf command in a thread safe lock and check the error code. Call fatal error otherwise.
     */
    func nc_exec(_ fn: () -> Int32) throws {
        let ncerr = withLock(fn)
        guard ncerr == NC_NOERR else {
            throw NetCDFError(ncerr: ncerr)
        }
    }
    
    /// Execute a closure which takes a buffer for a netcdf variable NC_MAX_NAME const string
    func nc_max_name(_ fn: (UnsafeMutablePointer<Int8>) -> Int32) throws -> String {
        let ncerr = withLock { fn(&maxNameBuffer) }
        guard ncerr == NC_NOERR else {
            throw NetCDFError(ncerr: ncerr)
        }
        return String(cString: &maxNameBuffer)
    }
    
    var NC_UNLIMITED: Int { return CNetCDF.NC_UNLIMITED }
    
    var NC_GLOBAL: Int32 { return CNetCDF.NC_GLOBAL }
    
    /// Get all group IDs of a group id
    func inq_grps(ncid: Int32) throws -> [Int32] {
        var count: Int32 = 0
        try nc_exec {
            nc_inq_grps(ncid, &count, nil)
        }
        var ids = [Int32](repeating: 0, count: Int(count))
        try nc_exec {
            nc_inq_grps(ncid, nil, &ids)
        }
        return ids
    }
    
    func open(path: String, omode: Int32) throws -> Int32 {
        var ncid: Int32 = 0
        try nc_exec {
            nc_open(path, omode, &ncid)
        }
        return ncid
    }
    
    func open(path: String, allowWrite: Bool) throws -> Int32 {
        return try open(path: path, omode: allowWrite ? NC_WRITE : 0)
    }
    
    func create(path: String, cmode: Int32) throws -> Int32 {
        var ncid: Int32 = 0
        try nc_exec {
            nc_create(path, cmode, &ncid)
        }
        return ncid
    }
    
    func create(path: String, overwriteExisting: Bool, useNetCDF4: Bool) throws -> Int32 {
        var cmode = Int32(0)
        if overwriteExisting == false {
            cmode |= NC_NOCLOBBER
        }
        if useNetCDF4 {
            cmode |= NC_NETCDF4
        }
        return try create(path: path, cmode: cmode)
    }
    
    func sync(ncid: Int32) throws {
        try nc_exec {
            nc_sync(ncid)
        }
    }
    
    func inq_natts(ncid: Int32) throws -> Int32 {
        var count: Int32 = 0
        try nc_exec {
            nc_inq_natts(ncid, &count)
        }
        return count
    }
    
    func inq_type(ncid: Int32, typeid: Int32) throws -> (name: String, size: Int) {
        var size = 0
        let name = try nc_max_name {
            nc_inq_type(ncid, typeid, $0, &size)
        }
        return (name, size)
    }
    
    func inq_user_type(ncid: Int32, typeid: Int32) throws -> (name: String, size: Int, baseTypeId: Int32, numberOfFields: Int, classType: Int32) {
        
        var size = 0
        var baseTypeId: Int32 = 0
        var numberOfFields = 0
        var classType: Int32 = 0
        let name = try nc_max_name {
            nc_inq_user_type(ncid, typeid, $0, &size, &baseTypeId, &numberOfFields, &classType)
        }
        return (name, size, baseTypeId, numberOfFields, classType)
    }
    
    /// Get all variable IDs of a group id
    func inq_varids(ncid: Int32) throws -> [Int32] {
        var count: Int32 = 0
        try nc_exec {
            nc_inq_varids(ncid, &count, nil)
        }
        var ids = [Int32](repeating: 0, count: Int(count))
        try nc_exec {
            nc_inq_varids(ncid, nil, &ids)
        }
        return ids
    }
    
    /// Get the name of a group
    func inq_grpname(ncid: Int32) throws -> String {
        var nameLength = 0
        try netcdfLock.nc_exec {
            nc_inq_grpname_len(ncid, &nameLength)
        }
        var nameBuffer = [Int8](repeating: 0, count: nameLength) // CHECK +1 needed?
        try netcdfLock.nc_exec {
            nc_inq_grpname(ncid, &nameBuffer)
        }
        return String(cString: nameBuffer)
    }
    
    /// Define a new group
    func def_grp(ncid: Int32, name: String) throws -> Int32 {
        var newNcid: Int32 = 0
        try netcdfLock.nc_exec {
            nc_def_grp(ncid, name, &newNcid)
        }
        return newNcid
    }
    
    /// Get a variable by name
    func inq_varid(ncid: Int32, name: String) throws -> Int32 {
        var id: Int32 = 0
        try netcdfLock.nc_exec { nc_inq_varid(ncid, name, &id) }
        return id
    }
    
    /// Get a group by name
    func inq_grp_ncid(ncid: Int32, name: String) throws -> Int32 {
        var id: Int32 = 0
        try netcdfLock.nc_exec { nc_inq_grp_ncid(ncid, name, &id) }
        return id
    }
    
    /// Close the netcdf file
    func close(ncid: Int32) throws {
        try netcdfLock.nc_exec {
            nc_close(ncid)
        }
    }
    
    /**
     Get a list of IDs of unlimited dimensions.
     In netCDF-4 files, it's possible to have multiple unlimited dimensions. This function returns a list of the unlimited dimension ids visible in a group.
     Dimensions are visible in a group if they have been defined in that group, or any ancestor group.
     */
    func inq_unlimdims(ncid: Int32) throws -> [Int32] {
        // Get the number of dimensions
        var count: Int32 = 0
        try nc_exec {
            nc_inq_unlimdims(ncid, &count, nil)
        }
        // Allocate array and get the IDs
        var dimensions = [Int32](repeating: 0, count: Int(count))
        try nc_exec {
            nc_inq_unlimdims(ncid, nil, &dimensions)
        }
        return dimensions
    }
    
    /// Get all variable IDs of a group id
    func inq_varndims(ncid: Int32, varid: Int32) throws -> Int32 {
        var count: Int32 = 0
        try nc_exec {
            nc_inq_varndims(ncid, varid, &count)
        }
        return count
    }
    
    func inq_dimids(ncid: Int32, includeParents: Bool) throws -> [Int32] {
        // Get the number of dimensions
        var count: Int32 = 0
        try nc_exec {
            nc_inq_dimids(ncid, &count, nil, includeParents ? 1 : 0)
        }
        // Allocate array and get the IDs
        var ids = [Int32](repeating: 0, count: Int(count))
        try nc_exec {
            nc_inq_dimids(ncid, nil, &ids, includeParents ? 1 : 0)
        }
        return ids
    }
    
    
    func inq_var(ncid: Int32, varid: Int32) throws -> (name: String, typeid: Int32, dimensionIds: [Int32], nAttributes: Int32) {
        let nDimensions = try inq_varndims(ncid: ncid, varid: varid)
        var dimensionIds = [Int32](repeating: 0, count: Int(nDimensions))
        var nAttribudes: Int32 = 0
        var typeid: Int32 = 0
        let name = try nc_max_name {
            nc_inq_var(ncid, varid, $0, &typeid, nil, &dimensionIds, &nAttribudes)
        }
        return (name, typeid, dimensionIds, nAttribudes)
    }
    
    func def_var(ncid: Int32, name: String, typeid: Int32, dimensionIds: [Int32]) throws -> Int32 {
        var varid: Int32 = 0
        try nc_exec {
            nc_def_var(ncid, name, typeid, Int32(dimensionIds.count), dimensionIds, &varid)
        }
        return varid
    }
    
    func inq_dim(ncid: Int32, dimid: Int32) throws -> (name: String, length: Int) {
        var len: Int = 0
        let name = try nc_max_name {
            nc_inq_dim(ncid, dimid, $0, &len)
        }
        return (name, len)
    }
    
    func def_dim(ncid: Int32, name: String, length: Int) throws -> Int32 {
        var dimid: Int32 = 0
        try netcdfLock.nc_exec {
            nc_def_dim(ncid, name, length, &dimid)
        }
        return dimid
    }
    
    func inq_attname(ncid: Int32, varid: Int32, attid: Int32) throws -> String {
        return try nc_max_name {
            nc_inq_attname(ncid, varid, attid, $0)
        }
    }
    
    func inq_att(ncid: Int32, varid: Int32, name: String) throws -> (typeid: Int32, length: Int) {
        var typeid: Int32 = 0
        var len: Int = 0
        try nc_exec {
            nc_inq_att(ncid, varid, name, &typeid, &len)
        }
        return (typeid, len)
    }
    
    func put_att(ncid: Int32, varid: Int32, name: String, type: Int32, length: Int, ptr: UnsafeRawPointer) throws {
        try netcdfLock.nc_exec {
            nc_put_att(ncid, varid, name, type, length, ptr)
        }
    }
    
    func put_att_text(ncid: Int32, varid: Int32, name: String, length: Int, text: String) throws {
        try netcdfLock.nc_exec {
            nc_put_att_text(ncid, varid, name, length, text)
        }
    }
    
    
    func inq_attlen(ncid: Int32, varid: Int32, name: String) throws -> Int {
        var len: Int = 0
        try nc_exec {
            nc_inq_attlen(ncid, varid, name, &len)
        }
        return len
    }
    
    func get_att(ncid: Int32, varid: Int32, name: String, buffer: UnsafeMutableRawPointer) throws {
        try nc_exec {
            nc_get_att(ncid, varid, name, buffer)
        }
    }
    
    func free_string(len: Int, stringArray: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>) throws {
        try nc_exec {
            nc_free_string(len, stringArray)
        }
    }
}
