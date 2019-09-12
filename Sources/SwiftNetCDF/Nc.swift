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

public struct VarId {
    let varid: Int32
    
    fileprivate init(_ varid: Int32) {
        self.varid = varid
    }
    
}

public struct DimId: Equatable {
    let dimid: Int32
    
    fileprivate init(_ dimid: Int32) {
        self.dimid = dimid
    }
}

public struct NcId {
    let ncid: Int32
    
    fileprivate init(_ ncid: Int32) {
        self.ncid = ncid
    }
    
    public func inq_type(typeid: TypeId) throws -> (name: String, size: Int) {
        var size = 0
        let name = try Nc.execWithStringBuffer {
            nc_inq_type(ncid, typeid.typeid, $0, &size)
        }
        return (name, size)
    }
    
    public func inq_user_type(typeid: TypeId) throws -> (name: String, size: Int, baseTypeId: Int32, numberOfFields: Int, classType: Int32) {
        var size = 0
        var baseTypeId: Int32 = 0
        var numberOfFields = 0
        var classType: Int32 = 0
        let name = try Nc.execWithStringBuffer {
            nc_inq_user_type(ncid, typeid.typeid, $0, &size, &baseTypeId, &numberOfFields, &classType)
        }
        return (name, size, baseTypeId, numberOfFields, classType)
    }
    
    public func sync() throws {
        try Nc.exec {
            nc_sync(ncid)
        }
    }
    
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
        return ids.map(VarId.init)
    }
    
    /// Get the name of a group
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
    
    /// Define a new group
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
        return VarId(id)
    }
    
    /// Get all group IDs of a group id
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
    
    /// Close the netcdf file
    public func close() throws {
        try Nc.exec {
            nc_close(ncid)
        }
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
    
    /// Get all variable IDs of a group id
    public func inq_varndims(varid: VarId) throws -> Int32 {
        var count: Int32 = 0
        try Nc.exec {
            nc_inq_varndims(ncid, varid.varid, &count)
        }
        return count
    }
    
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
    
    
    public func inq_var(varid: VarId) throws -> (name: String, typeid: TypeId, dimensionIds: [DimId], nAttributes: Int32) {
        let nDimensions = try inq_varndims(varid: varid)
        var dimensionIds = [Int32](repeating: 0, count: Int(nDimensions))
        var nAttribudes: Int32 = 0
        var typeid: Int32 = 0
        let name = try Nc.execWithStringBuffer {
            nc_inq_var(ncid, varid.varid, $0, &typeid, nil, &dimensionIds, &nAttribudes)
        }
        return (name, TypeId(typeid), dimensionIds.map(DimId.init), nAttribudes)
    }
    
    public func def_var( name: String, typeid: TypeId, dimensionIds: [DimId]) throws -> VarId {
        var varid: Int32 = 0
        try Nc.exec {
            nc_def_var(ncid, name, typeid.typeid, Int32(dimensionIds.count), dimensionIds.map{$0.dimid}, &varid)
        }
        return VarId(varid)
    }
    
    public func inq_dim(dimid: DimId) throws -> (name: String, length: Int) {
        var len: Int = 0
        let name = try Nc.execWithStringBuffer {
            nc_inq_dim(ncid, dimid.dimid, $0, &len)
        }
        return (name, len)
    }
    
    public func def_dim(name: String, length: Int) throws -> DimId {
        var dimid: Int32 = 0
        try Nc.exec {
            nc_def_dim(ncid, name, length, &dimid)
        }
        return DimId(dimid)
    }
    
    public func inq_attname(varid: VarId, attid: Int32) throws -> String {
        return try Nc.execWithStringBuffer {
            nc_inq_attname(ncid, varid.varid, attid, $0)
        }
    }
    
    public func inq_att(varid: VarId, name: String) throws -> (typeid: TypeId, length: Int) {
        var typeid: Int32 = 0
        var len: Int = 0
        try Nc.exec {
            nc_inq_att(ncid, varid.varid, name, &typeid, &len)
        }
        return (TypeId(typeid), len)
    }
    
    public func put_att(varid: VarId, name: String, type: TypeId, length: Int, ptr: UnsafeRawPointer) throws {
        try Nc.exec {
            nc_put_att(ncid, varid.varid, name, type.typeid, length, ptr)
        }
    }
    
    public func put_att_text(varid: VarId, name: String, length: Int, text: String) throws {
        try Nc.exec {
            nc_put_att_text(ncid, varid.varid, name, length, text)
        }
    }
    
    
    public func inq_attlen(varid: VarId, name: String) throws -> Int {
        var len: Int = 0
        try Nc.exec {
            nc_inq_attlen(ncid, varid.varid, name, &len)
        }
        return len
    }
    
    public func get_att(varid: VarId, name: String, buffer: UnsafeMutableRawPointer) throws {
        try Nc.exec {
            nc_get_att(ncid, varid.varid, name, buffer)
        }
    }
    
    
    public func get_vara(varid: VarId, offset: [Int], count: [Int], buffer: UnsafeMutableRawPointer) throws {
        try Nc.exec {
            nc_get_vara(ncid, varid.varid, offset, count, buffer)
        }
    }
    
    public func get_vars(varid: VarId, offset: [Int], count: [Int], stride: [Int], buffer: UnsafeMutableRawPointer) throws {
        try Nc.exec {
            nc_get_vars(ncid, varid.varid, offset, count, stride, buffer)
        }
    }
    
    public func put_vara(varid: VarId, offset: [Int], count: [Int], ptr: UnsafeRawPointer) throws {
        try Nc.exec {
            nc_put_vara(ncid, varid.varid, offset, count, ptr)
        }
    }
    public func put_vars(varid: VarId, offset: [Int], count: [Int], stride: [Int], ptr: UnsafeRawPointer) throws {
        try Nc.exec {
            nc_put_vars(ncid, varid.varid, offset, count, stride, ptr)
        }
    }
    
    public func def_var_deflate(varid: VarId, shuffle: Bool, deflate: Bool, deflate_level: Int32) throws {
        try Nc.exec {
            nc_def_var_deflate(ncid, varid.varid, shuffle ? 1 : 0, deflate ? 1 : 0, deflate_level)
        }
    }
    
    public func def_var_chunking(varid: VarId, type: Chunking, chunks: [Int]) throws {
        try Nc.exec {
            return nc_def_var_chunking(ncid, varid.varid, type.netcdfValue, chunks)
        }
    }
    
    public func def_var_flechter32(varid: VarId, enable: Bool) throws {
        try Nc.exec {
            nc_def_var_fletcher32(ncid, varid.varid, enable ? 1 : 0)
        }
    }
    
    public func def_var_endian(varid: VarId, type: Endian) throws {
        try Nc.exec {
            nc_def_var_endian(ncid, varid.varid, type.netcdfValue)
        }
    }
    
    public func def_var_filter(varid: VarId, id: UInt32, params: [UInt32]) throws {
        try Nc.exec {
            nc_def_var_filter(ncid, varid.varid, id, params.count, params)
        }
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
    static var NC_UNLIMITED: Int { return CNetCDF.NC_UNLIMITED }
    
    static var NC_GLOBAL: VarId { return VarId(CNetCDF.NC_GLOBAL) }
    
    /**
     NetCDF library version string like: "4.6.3 of May  8 2019 00:09:03 $"
     */
    static func inq_libvers() -> String {
        return Nc.lock.withLock {
            String(cString: nc_inq_libvers())
        }
    }
    
    static func open(path: String, omode: Int32) throws -> NcId {
        var ncid: Int32 = 0
        try exec {
            nc_open(path, omode, &ncid)
        }
        return NcId(ncid)
    }
    
    static func open(path: String, allowWrite: Bool) throws -> NcId {
        return try open(path: path, omode: allowWrite ? NC_WRITE : 0)
    }
    
    static func create(path: String, cmode: Int32) throws -> NcId {
        var ncid: Int32 = 0
        try exec {
            nc_create(path, cmode, &ncid)
        }
        return NcId(ncid)
    }
    
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
