//
//  Dimension.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-08.
//

import Foundation
import CNetCDF

public final class File {
    let ncid: Int32 = 0
    
    static func create(file: String, overwriteExisting: Bool, useNetCDF4: Bool) throws -> File {
        fatalError()
    }
    
    static func open(file: String, allowWrite: Bool) throws -> File {
        fatalError()
    }
    
    func getRootGroup() -> Group {
        fatalError()
    }
}

/*public indirect enum FileOrGroup {
    case file(File)
    case group(Group)
}*/

public struct Dimension {
    let dimid: Int32
    let name: String
    let length: Int
    // is unlimited?
}

public struct Group {
    let file: File
    /// id of the group
    let ncid: Int32
    
    // list groups / variables
    
    public func getVariable(byName name: String) -> Variable? {
        var varid: Int32 = 0
        let ncerr = netcdfLock.withLock { nc_inq_varid(ncid, name, &varid) }
        if ncerr != NC_NOERR {
            return nil
        }
        return Variable.init(fromVarId: varid, ncid: ncid, file: file)
    }
    
    public func createVariable<T: Primitive>(name: String, type: T.Type, dimensions: [Dimension]) -> VariablePrimitive<T> {
        // compression?
        fatalError()
    }
    
    public func getGroup() { }
    
    public func createGroup() { }
}

/// A netcdf variable of unspecified type
public struct Variable {
    let group: Group
    let name: String
    let varid: Int32
    let dimensions: [Dimension]
    let typeid: nc_type
    
    var count: Int { return dimensions.reduce(1, {$0 * $1.length}) }
    
    public init(fromVarId: Int32, ncid: Int32, file: File) {
        /*var dimids: [Int32] = [0,0,0,0,0,0,0,0]
         var nattribudes: Int32 = 0
         var typeid: Int32 = 0
         var ndims: Int32 = 0
         var nameBuffer = [Int8](repeating: 0, count: Int(NC_MAX_NAME+1))
         netcdfLock.nc_exec {
         nc_inq_var(ncfile.ncid, varid, &nameBuffer, &typeid, &ndims, &dimids, &nattribudes)
         }
         name = String(cString: nameBuffer)
         
         self.nattribudes = nattribudes
         self.ndimensions = ndims
         self.type = AtomicType(rawValue: typeid)!
         self.dimensions = dimids[0...Int(ndims)-1].map { dimid in
         var len: Int = 0
         netcdfLock.nc_exec { nc_inq_dim(ncfile.ncid, dimid, nil, &len) }
         return len
         }*/
        
        fatalError()
    }
    
    public init(name: String, typeid: nc_type, dimensions: [Dimension], group: Group) throws {
        let dimensionIds = dimensions.map { $0.dimid }
        var varid: Int32 = 0
        try netcdfLock.nc_exec {
            nc_def_var(group.ncid, name, typeid, Int32(dimensions.count), dimensionIds, &varid)
        }
        self.group = group
        self.name = name
        self.varid = varid
        self.dimensions = dimensions
        self.typeid = typeid
    }
    
    /// enable compression for this netcdf variable. This should be set before any data is written
    public func enableCompression(level: Int = 6, shuffle: Bool = false, chunks: [Int]? = nil) throws {
        try netcdfLock.nc_exec {
            nc_def_var_deflate(group.ncid, varid, shuffle ? 1 : 0, 1, Int32(level))
        }
        if let chunks = chunks {
            precondition(chunks.count == dimensions.count, "Chunk dimensions must have the same amount of elements as variable dimensions")
            try netcdfLock.nc_exec {
                nc_def_var_chunking(group.ncid, varid, NC_CHUNKED, chunks)
            }
        }
    }
    
    /// Try to cast this netcdf variable to a specfic primitive type for read and write operations
    public func asPrimitive<T: Primitive>(of: T.Type) -> VariablePrimitive<T>? {
        fatalError()
    }
}


/// A generic netcdf variable of a fixed data type
public struct VariablePrimitive<T: Primitive> {
    let variable: Variable
    
    public func read(offset: [Int], count: [Int]) throws -> [T] {
        assert(offset.count == variable.dimensions.count)
        assert(count.count == variable.dimensions.count)
        let n_elements = count.reduce(1, *)
        var array = T.netCdfCreateNaNArray(count: n_elements)
        try netcdfLock.nc_exec {
            T.nc_get_vara(variable.group.ncid, variable.varid, start: offset, count: count, data: &array)
        }
        return array
    }
    
    /// Write a complete array to the file. The array must be as large as the defined dimensions
    public func write(_ data: [T]) throws {
        assert(variable.count == data.count, "Array counts \(data.count) does not match \(variable.count)")
        
        let offest = [Int](repeating: 0, count: variable.dimensions.count)
        let dimensions = variable.dimensions.map { $0.length }
        try write(data, offset: offest, count: dimensions)
    }
    
    /// Write only a defined subset specified by offset and count
    public func write(_ data: [T], offset: [Int], count: [Int]) throws {
        assert(variable.dimensions.count == offset.count)
        assert(variable.dimensions.count == count.count)
        try netcdfLock.nc_exec {
            T.nc_put_vara(variable.group.ncid, variable.varid, start: offset, count: count, data: data)
        }
    }
}
