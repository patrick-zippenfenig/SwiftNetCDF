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
    
    /// length my be updated for unlimited dimensions
    let length: Int
    
    let isUnlimited: Bool
    
    /**
     Initialise from existing dimension ID. isUlimited must be supplied, because it can not be self discovered.
     */
    init(fromDimId dimid: Int32, isUnlimited: Bool, group: Group) throws {
        var len: Int = 0
        var nameBuffer = [Int8](repeating: 0, count: Int(NC_MAX_NAME+1))
        try netcdfLock.nc_exec {
            nc_inq_dim(group.ncid, dimid, &nameBuffer, &len)
        }
        self.dimid = dimid
        self.name = String(cString: nameBuffer)
        self.length = len
        self.isUnlimited = isUnlimited
    }
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
        fatalError()
        //return Variable.init(fromVarId: varid, ncid: ncid, file: file)
    }
    
    public func createVariable<T: Primitive>(name: String, type: T.Type, dimensions: [Dimension]) -> VariablePrimitive<T> {
        // compression?
        fatalError()
    }
    
    public func getGroup() { }
    
    public func createGroup() { }
    
    /**
     Get a list of IDs of unlimited dimensions.
     In netCDF-4 files, it's possible to have multiple unlimited dimensions. This function returns a list of the unlimited dimension ids visible in a group.
     Dimensions are visible in a group if they have been defined in that group, or any ancestor group.
     */
    public func getUnlimitedDimensionIds() throws -> [Int32] {
        // Get the number of dimesions
        var nUnlimited: Int32 = 0
        try netcdfLock.nc_exec {
            nc_inq_unlimdims(ncid, &nUnlimited, nil)
        }
        // Allocate array and get the IDs
        var unlimitedDimensions = [Int32](repeating: 0, count: Int(nUnlimited))
        try netcdfLock.nc_exec {
            nc_inq_unlimdims(ncid, nil, &unlimitedDimensions)
        }
        return unlimitedDimensions
    }
}


public enum DataClass: Int32 {
    case nc_vlen = 9999 // NC_VLEN
}

public enum DataType {
    case primitive(PrimitiveType)
    case userDefined(UserDefinedType)
    
    var typeid: nc_type { fatalError() }
    var size: Int { fatalError() }
    
    init(fromTypeId typeid: nc_type, group: Group) {
        fatalError()
        // https://www.unidata.ucar.edu/software/netcdf/docs/group__user__types.html#gaf4340ce9486b1b38e853d75ed23303da
        // nc_inq_user_type return the user type
    }
}

public enum UserDefinedType {
    case enumeration(Enumeration)
    case compound(Compound)
    case opaque(Opaque)
    case variableLength(VariableLength)
}

public struct Compound {
    let group: Group
    let typeid: nc_type
    let name: String
    let size: Int
    let numerOfFields: Int
}

public struct Opaque {
    let group: Group
    let typeid: nc_type
    let name: String
    let size: Int
}

public struct Enumeration {
    let group: Group
    let typeid: nc_type
    let name: String
    let size: Int
    let numerOfFields: Int
}

public struct VariableLength {
    let group: Group
    let typeid: nc_type
    let name: String
    let size: Int
    let baseTypeId: nc_type
}

/// A netcdf variable of unspecified type
public struct Variable {
    let group: Group
    let name: String
    let varid: Int32
    let dimensions: [Dimension]
    let dataType: DataType
    
    var count: Int { return dimensions.reduce(1, {$0 * $1.length}) }
    
    /**
     Initialise from an existing variable id
     */
    public init(fromVarId varid: Int32, group: Group) throws {
        var nDimensions: Int32 = 0
        try netcdfLock.nc_exec {
            nc_inq_varndims(group.ncid, varid, &nDimensions)
        }
        var dimensionIds = [Int32](repeating: 0, count: Int(nDimensions))
        var nAttribudes: Int32 = 0
        var typeid: Int32 = 0
        var nameBuffer = [Int8](repeating: 0, count: Int(NC_MAX_NAME+1))
        try netcdfLock.nc_exec {
            nc_inq_var(group.ncid, varid, &nameBuffer, &typeid, nil, &dimensionIds, &nAttribudes)
        }
        
        let unlimitedDimensions = try group.getUnlimitedDimensionIds()
        
        self.group = group
        self.varid = varid
        self.name = String(cString: nameBuffer)
        self.dimensions = try dimensionIds.map {
            try Dimension(fromDimId: $0, isUnlimited: unlimitedDimensions.contains($0), group: group)
        }
        self.dataType = DataType(fromTypeId: typeid, group: group)
    }
    
    public init(name: String, dataType: DataType, dimensions: [Dimension], group: Group) throws {
        let dimensionIds = dimensions.map { $0.dimid }
        var varid: Int32 = 0
        try netcdfLock.nc_exec {
            nc_def_var(group.ncid, name, dataType.typeid, Int32(dimensions.count), dimensionIds, &varid)
        }
        self.group = group
        self.name = name
        self.varid = varid
        self.dimensions = dimensions
        self.dataType = dataType
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
    
    /// Read raw by using the datatype size directly
    public func readRaw(offset: [Int], count: [Int]) throws -> Data {
        assert(dimensions.count == offset.count)
        assert(dimensions.count == count.count)
        let n_elements = count.reduce(1, *)
        let n_bytes = n_elements * dataType.size
        var data = Data(capacity: n_bytes)
        try withUnsafeMutablePointer(to: &data) { ptr in
            try netcdfLock.nc_exec {
                nc_get_vara(group.ncid, varid, offset, count, ptr)
            }
        }
        return data
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
