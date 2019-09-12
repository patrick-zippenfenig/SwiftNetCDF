//
//  Variable.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-10.
//

import Foundation
import CNetCDF


// TODO adding an attributes modified the numberOfAttributes

/// A netcdf variable of unspecified type
public struct Variable {
    public let group: Group
    let name: String
    public let varid: Int32
    public var numberOfAttributes: Int32
    let dimensions: [Dimension]
    let dataType: DataType
    
    var count: Int { return dimensions.reduce(1, {$0 * $1.length}) }
    
    /**
     Initialise from an existing variable id
     */
    init(fromVarId varid: Int32, group: Group) throws {
        let varinq = try netcdfLock.inq_var(ncid: group.ncid, varid: varid)
        let unlimitedDimensions = try netcdfLock.inq_unlimdims(ncid: group.ncid)
        self.group = group
        self.varid = varid
        self.name = varinq.name
        self.dimensions = try varinq.dimensionIds.map {
            try Dimension(fromDimId: $0, isUnlimited: unlimitedDimensions.contains($0), group: group)
        }
        self.numberOfAttributes = varinq.nAttributes
        self.dataType = try DataType(fromTypeId: varinq.typeid, group: group)
    }
    
    /**
     Define a new variable in the NetCDF file
     */
    init(name: String, dataType: DataType, dimensions: [Dimension], group: Group) throws {
        let dimensionIds = dimensions.map { $0.dimid }
        let varid = try netcdfLock.def_var(ncid: group.ncid, name: name, typeid: dataType.typeid, dimensionIds: dimensionIds)
        self.group = group
        self.name = name
        self.varid = varid
        self.dimensions = dimensions
        self.dataType = dataType
        self.numberOfAttributes = 0
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
    public func asType<T: NetcdfConvertible>(_ of: T.Type) -> VariableGeneric<T>? {
        guard T.canRead(type: dataType) else {
            return nil
        }
        return VariableGeneric(variable: self)
    }
    
    /// Read raw by using the datatype size directly
    public func readRaw(offset: [Int], count: [Int]) throws -> Data {
        assert(dimensions.count == offset.count)
        assert(dimensions.count == count.count)
        let n_elements = count.reduce(1, *)
        let n_bytes = n_elements * dataType.byteSize
        var data = Data(capacity: n_bytes)
        try withUnsafeMutablePointer(to: &data) { ptr in
            try netcdfLock.nc_exec {
                nc_get_vara(group.ncid, varid, offset, count, ptr)
            }
        }
        return data
    }
    
    public func getCdl(indent: Int) -> String {
        let ind = String(repeating: " ", count: indent)
        let dims = dimensions.map { $0.name }.joined(separator: ", ")
        return "\(ind)\(dataType.name) \(name)(\(dims)) ;\n"
    }
}

extension Variable: AttributeProvider { }


/// A generic netcdf variable of a fixed data type
public struct VariableGeneric<T: NetcdfConvertible> {
    let variable: Variable
    
    public func read(offset: [Int], count: [Int]) throws -> [T] {
        assert(offset.count == variable.dimensions.count)
        assert(count.count == variable.dimensions.count)
        let n_elements = count.reduce(1, *)
        
        return try T.createFromBuffer(length: n_elements) { ptr in
            try netcdfLock.get_vara(ncid: variable.group.ncid, varid: variable.varid, offset: offset, count: count, buffer: ptr)
        }
    }
    
    public func read(offset: [Int], count: [Int], stride: [Int]) throws -> [T] {
        assert(offset.count == variable.dimensions.count)
        assert(count.count == variable.dimensions.count)
        assert(stride.count == variable.dimensions.count)
        let n_elements = count.reduce(1, *)
        
        return try T.createFromBuffer(length: n_elements) { ptr in
            try netcdfLock.get_vars(ncid: variable.group.ncid, varid: variable.varid, offset: offset, count: count, stride: stride, buffer: ptr)
        }
    }
    
    /// Read the whole variable
    public func read() throws -> [T] {
        let offset = [Int](repeating: 0, count: variable.dimensions.count)
        let count = variable.dimensions.map { $0.length }
        return try read(offset: offset, count: count)
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
        try T.withPointer(to: data) { ptr in
            try netcdfLock.put_vara(ncid: variable.group.ncid, varid: variable.varid, offset: offset, count: count, ptr: ptr)
        }
    }
    
    /// Write only a defined subset specified by offset, count and stride
    public func write(_ data: [T], offset: [Int], count: [Int], stride: [Int]) throws {
        assert(variable.dimensions.count == offset.count)
        assert(variable.dimensions.count == count.count)
        assert(variable.dimensions.count == stride.count)
        try T.withPointer(to: data) { ptr in
            try netcdfLock.put_vars(ncid: variable.group.ncid, varid: variable.varid, offset: offset, count: count, stride: stride, ptr: ptr)
        }
    }
}
