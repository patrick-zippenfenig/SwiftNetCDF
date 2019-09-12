//
//  Nc.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-10.
//
import CNetCDF
import Foundation


public enum NetCDFError: Error {
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

public extension ExternalDataType {
    var typeId: TypeId {
        return TypeId(rawValue)
    }
}

public struct TypeId: Equatable {
    let typeid: Int32
    
    fileprivate init(_ typeid: Int32) {
        self.typeid = typeid
    }
}

/**
 A VarId is always bound to a NcId. We make sure this stays this way.
 */
public struct VarId {
    let ncid: NcId
    let varid: Int32
    
    fileprivate init(ncid: NcId, varid: Int32) {
        self.ncid = ncid
        self.varid = varid
    }
    
    public func inq_var() throws -> (name: String, typeid: TypeId, dimensionIds: [DimId], nAttributes: Int32) {
        let nDimensions = try inq_varndims()
        var dimensionIds = [Int32](repeating: 0, count: Int(nDimensions))
        var nAttribudes: Int32 = 0
        var typeid: Int32 = 0
        let name = try Nc.execWithStringBuffer {
            nc_inq_var(ncid.ncid, varid, $0, &typeid, nil, &dimensionIds, &nAttribudes)
        }
        return (name, TypeId(typeid), dimensionIds.map(DimId.init), nAttribudes)
    }
    
    public func inq_attname(attid: Int32) throws -> String {
        return try Nc.execWithStringBuffer {
            nc_inq_attname(ncid.ncid, varid, attid, $0)
        }
    }
    
    public func inq_att(name: String) throws -> (typeid: TypeId, length: Int) {
        var typeid: Int32 = 0
        var len: Int = 0
        try Nc.exec {
            nc_inq_att(ncid.ncid, varid, name, &typeid, &len)
        }
        return (TypeId(typeid), len)
    }
    
    
    /// Get all variable IDs of a group id
    public func inq_varndims() throws -> Int32 {
        var count: Int32 = 0
        try Nc.exec {
            nc_inq_varndims(ncid.ncid, varid, &count)
        }
        return count
    }
    
    public func put_att(name: String, type: TypeId, length: Int, ptr: UnsafeRawPointer) throws {
        try Nc.exec {
            nc_put_att(ncid.ncid, varid, name, type.typeid, length, ptr)
        }
    }
    
    public func put_att_text(name: String, length: Int, text: String) throws {
        try Nc.exec {
            nc_put_att_text(ncid.ncid, varid, name, length, text)
        }
    }
    
    public func inq_attlen(name: String) throws -> Int {
        var len: Int = 0
        try Nc.exec {
            nc_inq_attlen(ncid.ncid, varid, name, &len)
        }
        return len
    }
    
    public func get_att(name: String, buffer: UnsafeMutableRawPointer) throws {
        try Nc.exec {
            nc_get_att(ncid.ncid, varid, name, buffer)
        }
    }
    
    
    public func get_vara(offset: [Int], count: [Int], buffer: UnsafeMutableRawPointer) throws {
        try Nc.exec {
            nc_get_vara(ncid.ncid, varid, offset, count, buffer)
        }
    }
    
    public func get_vars(offset: [Int], count: [Int], stride: [Int], buffer: UnsafeMutableRawPointer) throws {
        try Nc.exec {
            nc_get_vars(ncid.ncid, varid, offset, count, stride, buffer)
        }
    }
    
    public func put_vara(offset: [Int], count: [Int], ptr: UnsafeRawPointer) throws {
        try Nc.exec {
            nc_put_vara(ncid.ncid, varid, offset, count, ptr)
        }
    }
    
    public func put_vars(offset: [Int], count: [Int], stride: [Int], ptr: UnsafeRawPointer) throws {
        try Nc.exec {
            nc_put_vars(ncid.ncid, varid, offset, count, stride, ptr)
        }
    }
    
    public func def_var_deflate(shuffle: Bool, deflate: Bool, deflate_level: Int32) throws {
        try Nc.exec {
            nc_def_var_deflate(ncid.ncid, varid, shuffle ? 1 : 0, deflate ? 1 : 0, deflate_level)
        }
    }
    
    public func def_var_chunking(type: Chunking, chunks: [Int]) throws {
        try Nc.exec {
            return nc_def_var_chunking(ncid.ncid, varid, type.netcdfValue, chunks)
        }
    }
    
    public func def_var_flechter32(enable: Bool) throws {
        try Nc.exec {
            nc_def_var_fletcher32(ncid.ncid, varid, enable ? 1 : 0)
        }
    }
    
    public func def_var_endian(type: Endian) throws {
        try Nc.exec {
            nc_def_var_endian(ncid.ncid, varid, type.netcdfValue)
        }
    }
    
    public func def_var_filter(id: UInt32, params: [UInt32]) throws {
        try Nc.exec {
            nc_def_var_filter(ncid.ncid, varid, id, params.count, params)
        }
    }
}



public struct DimId: Equatable {
    let dimid: Int32
    
    fileprivate init(_ dimid: Int32) {
        self.dimid = dimid
    }
    
    public enum Length {
        case unlimited
        case length(Int)
        
        var netCdfValue: Int {
            switch self {
            case .unlimited: return NC_UNLIMITED
            case .length(let length): return length
            }
        }
    }
}

/**
 A ncid might be a file or a group handle.
 */
public struct NcId {
    let ncid: Int32
    
    fileprivate init(_ ncid: Int32) {
        self.ncid = ncid
    }
    
    /**
     A global var is used for global attributes on ncid
     */
    func NC_GLOBAL() -> VarId {
        return VarId(ncid: self, varid: CNetCDF.NC_GLOBAL)
    }
    
    /// Get information on a type. Works for external and user types
    public func inq_type(typeid: TypeId) throws -> (name: String, size: Int) {
        var size = 0
        let name = try Nc.execWithStringBuffer {
            nc_inq_type(ncid, typeid.typeid, $0, &size)
        }
        return (name, size)
    }
    
    /// Get information on user types. Does not work for external types
    public func inq_user_type(typeid: TypeId) throws -> (name: String, size: Int, baseTypeId: TypeId, numberOfFields: Int, classType: Int32) {
        var size = 0
        var baseTypeId: Int32 = 0
        var numberOfFields = 0
        var classType: Int32 = 0
        let name = try Nc.execWithStringBuffer {
            nc_inq_user_type(ncid, typeid.typeid, $0, &size, &baseTypeId, &numberOfFields, &classType)
        }
        return (name, size, TypeId(baseTypeId), numberOfFields, classType)
    }
    
    /// Sync to disk
    public func sync() throws {
        try Nc.exec {
            nc_sync(ncid)
        }
    }
    
    /// Close the netcdf file
    public func close() throws {
        try Nc.exec {
            nc_close(ncid)
        }
    }
    
    /// Numer of attributes for this ncid
    public func inq_natts() throws -> Int32 {
        var count: Int32 = 0
        try Nc.exec {
            nc_inq_natts(ncid, &count)
        }
        return count
    }
    
    /// Get all variable IDs of a group id
    public func inq_varids() throws -> [VarId] {
        var count: Int32 = 0
        try Nc.exec {
            nc_inq_varids(ncid, &count, nil)
        }
        var ids = [Int32](repeating: 0, count: Int(count))
        try Nc.exec {
            nc_inq_varids(ncid, nil, &ids)
        }
        return ids.map { VarId(ncid: self, varid: $0) }
    }
    
    /// Get the name of this group
    public func inq_grpname() throws -> String {
        var nameLength = 0
        try Nc.exec {
            nc_inq_grpname_len(ncid, &nameLength)
        }
        var nameBuffer = [Int8](repeating: 0, count: nameLength) // CHECK +1 needed?
        try Nc.exec {
            nc_inq_grpname(ncid, &nameBuffer)
        }
        return String(cString: nameBuffer)
    }
    
    /// Define a new sub group
    public func def_grp(name: String) throws -> NcId {
        var newNcid: Int32 = 0
        try Nc.exec {
            nc_def_grp(ncid, name, &newNcid)
        }
        return NcId(newNcid)
    }
    
    /// Get a variable by name
    public func inq_varid(name: String) throws -> VarId {
        var id: Int32 = 0
        try Nc.exec { nc_inq_varid(ncid, name, &id) }
        return VarId(ncid: self, varid: id)
    }
    
    /// Get all sub group IDs
    public func inq_grps() throws -> [NcId] {
        var count: Int32 = 0
        try Nc.exec {
            nc_inq_grps(ncid, &count, nil)
        }
        var ids = [Int32](repeating: 0, count: Int(count))
        try Nc.exec {
            nc_inq_grps(ncid, nil, &ids)
        }
        return ids.map(NcId.init)
    }
    
    /// Get a group by name
    public func inq_grp_ncid(name: String) throws -> NcId {
        var id: Int32 = 0
        try Nc.exec { nc_inq_grp_ncid(ncid, name, &id) }
        return NcId(id)
    }
    
    /**
     Get a list of IDs of unlimited dimensions.
     In netCDF-4 files, it's possible to have multiple unlimited dimensions. This function returns a list of the unlimited dimension ids visible in a group.
     Dimensions are visible in a group if they have been defined in that group, or any ancestor group.
     */
    public func inq_unlimdims() throws -> [DimId] {
        // Get the number of dimensions
        var count: Int32 = 0
        try Nc.exec {
            nc_inq_unlimdims(ncid, &count, nil)
        }
        // Allocate array and get the IDs
        var dimensions = [Int32](repeating: 0, count: Int(count))
        try Nc.exec {
            nc_inq_unlimdims(ncid, nil, &dimensions)
        }
        return dimensions.map(DimId.init)
    }

    /// List all Dimension ids of this ncid
    public func inq_dimids(includeParents: Bool) throws -> [DimId] {
        // Get the number of dimensions
        var count: Int32 = 0
        try Nc.exec {
            nc_inq_dimids(ncid, &count, nil, includeParents ? 1 : 0)
        }
        // Allocate array and get the IDs
        var ids = [Int32](repeating: 0, count: Int(count))
        try Nc.exec {
            nc_inq_dimids(ncid, nil, &ids, includeParents ? 1 : 0)
        }
        return ids.map(DimId.init)
    }
    
    /// Get name and length of a dimension
    public func inq_dim(dimid: DimId) throws -> (name: String, length: Int) {
        var len: Int = 0
        let name = try Nc.execWithStringBuffer {
            nc_inq_dim(ncid, dimid.dimid, $0, &len)
        }
        return (name, len)
    }
    
    /// Define a new dimension
    public func def_dim(name: String, length: DimId.Length) throws -> DimId {
        var dimid: Int32 = 0
        try Nc.exec {
            nc_def_dim(ncid, name, length.netCdfValue, &dimid)
        }
        return DimId(dimid)
    }
    
    /// Define a new variable
    public func def_var( name: String, typeid: TypeId, dimensionIds: [DimId]) throws -> VarId {
        var varid: Int32 = 0
        try Nc.exec {
            nc_def_var(ncid, name, typeid.typeid, Int32(dimensionIds.count), dimensionIds.map{$0.dimid}, &varid)
        }
        return VarId(ncid: self, varid: varid)
    }
}



/**
 This struct wraps NetCDF C library functions to a more safe Swift syntax.
 A lock is used to ensure the library is not acessed from multiple threads simultaniously.
 */
public struct Nc {
    /**
     A Lock to serialise access to the NetCDF C library.
     */
    private static let lock = Lock()
    
    /**
     Reused buffer which some NetCDF routines can write names into. Afterwards it should be converted to a Swift String.
     The buffer should only be used with a thread lock.
     */
    private static var maxNameBuffer = [Int8](repeating: 0, count: Int(NC_MAX_NAME+1))
    
    /**
     Execute a netcdf command in a thread safe lock and check the error code. Throw an exception otherwise.
     */
    fileprivate static func exec(_ fn: () -> Int32) throws {
        let ncerr = Nc.lock.withLock(fn)
        guard ncerr == NC_NOERR else {
            throw NetCDFError(ncerr: ncerr)
        }
    }
    
    /**
     Execute a closure which takes a buffer for a netcdf variable NC_MAX_NAME const string.
     Afterwards the buffer is converted to a Swift string
     */
    fileprivate static func execWithStringBuffer(_ fn: (UnsafeMutablePointer<Int8>) -> Int32) throws -> String {
        return try Nc.lock.withLock {
            let error = fn(&Nc.maxNameBuffer)
            guard error == NC_NOERR else {
                throw NetCDFError(ncerr: error)
            }
            return String(cString: &Nc.maxNameBuffer)
        }
    }
}

public extension Nc {
    /**
     NetCDF library version string like: "4.6.3 of May  8 2019 00:09:03 $"
     */
    static func inq_libvers() -> String {
        return Nc.lock.withLock {
            String(cString: nc_inq_libvers())
        }
    }
    
    /// Open an exsiting NetCDF file
    static func open(path: String, omode: Int32) throws -> NcId {
        var ncid: Int32 = 0
        try exec {
            nc_open(path, omode, &ncid)
        }
        return NcId(ncid)
    }
    
    /// Open an exsiting NetCDF file
    static func open(path: String, allowWrite: Bool) throws -> NcId {
        return try open(path: path, omode: allowWrite ? NC_WRITE : 0)
    }
    
    /// Create a new NetCDF file
    static func create(path: String, cmode: Int32) throws -> NcId {
        var ncid: Int32 = 0
        try exec {
            nc_create(path, cmode, &ncid)
        }
        return NcId(ncid)
    }
    
    /// Create a new NetCDF file
    static func create(path: String, overwriteExisting: Bool, useNetCDF4: Bool) throws -> NcId {
        var cmode = Int32(0)
        if overwriteExisting == false {
            cmode |= NC_NOCLOBBER
        }
        if useNetCDF4 {
            cmode |= NC_NETCDF4
        }
        return try create(path: path, cmode: cmode)
    }
    
    /// Free memory for returned string arrays
    static func free_string(len: Int, stringArray: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>) {
        /// no error should be possible
        try! exec {
            nc_free_string(len, stringArray)
        }
    }
}

public enum Chunking {
    case chunked
    case contingous
    
    fileprivate var netcdfValue: Int32 {
        switch self {
        case .chunked: return NC_CHUNKED
        case .contingous: return NC_CONTIGUOUS
        }
    }
}

public enum Endian {
    case native
    case little
    case big
    
    fileprivate var netcdfValue: Int32 {
        switch self {
        case .native: return NC_ENDIAN_NATIVE
        case .little: return NC_ENDIAN_LITTLE
        case .big: return NC_ENDIAN_BIG
        }
    }
}