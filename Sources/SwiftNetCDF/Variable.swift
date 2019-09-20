//
//  Variable.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-10.
//

import Foundation

/// A netcdf variable of unspecified type
public struct Variable {
    public let group: Group
    public let name: String
    public let varid: VarId
    public var dimensions: [Dimension]
    public let type: TypeId
    
    /**
     Initialise from an existing variable id
     */
    init(fromVarId varid: VarId, group: Group) {
        let varinq = varid.inq_var()
        // Unlimited dimensions are not available in NetCDF v3
        let unlimitedDimensions = (try? group.ncid.inq_unlimdims()) ?? []
        self.group = group
        self.varid = varid
        self.name = varinq.name
        self.dimensions = varinq.dimensionIds.map {
            Dimension(fromDimId: $0, isUnlimited: unlimitedDimensions.contains($0), group: group)
        }
        self.type = varinq.type
    }
    
    /**
     Define a new variable in the NetCDF file
     */
    init(name: String, type: TypeId, dimensions: [Dimension], group: Group) throws {
        let dimensionIds = dimensions.map { $0.dimid }
        let varid = try group.ncid.def_var(name: name, type: type, dimensionIds: dimensionIds)
        self.group = group
        self.name = name
        self.varid = varid
        self.dimensions = dimensions
        self.type = type
    }
    
    
    
    /// Try to cast this netcdf variable to a specfic primitive type for read and write operations
    /// This function is inlinable to allow type specialisation across modules at compile time
    @inlinable public func asType<T: NetcdfConvertible>(_ of: T.Type) -> VariableGeneric<T>? {
        guard T.canRead(type: type) else {
            return nil
        }
        return VariableGeneric(variable: self)
    }
    
    /// Unsafe because the data length is not validated.
    func readUnsafe(into: UnsafeMutableRawPointer, offset: [Int], count: [Int]) throws {
        guard dimensions.count == offset.count else {
            throw NetCDFError.numberOfDimensionsInvalid
        }
        guard dimensions.count == count.count else {
            throw NetCDFError.numberOfDimensionsInvalid
        }
        try varid.get_vara(offset: offset, count: count, buffer: into)
    }
    
    /// Unsafe because the data length is not validated.
    func readUnsafe(into: UnsafeMutableRawPointer, offset: [Int], count: [Int], stride: [Int]) throws {
        guard dimensions.count == offset.count else {
            throw NetCDFError.numberOfDimensionsInvalid
        }
        guard dimensions.count == count.count else {
            throw NetCDFError.numberOfDimensionsInvalid
        }
        guard dimensions.count == stride.count else {
            throw NetCDFError.numberOfDimensionsInvalid
        }
        try varid.get_vars(offset: offset, count: count, stride: stride, buffer: into)
    }
    
    /// Unsafe because the data length is not validated.
    mutating func writeUnsafe(from: UnsafeRawPointer, offset: [Int], count: [Int]) throws {
        guard dimensions.count == offset.count else {
            throw NetCDFError.numberOfDimensionsInvalid
        }
        guard dimensions.count == count.count else {
            throw NetCDFError.numberOfDimensionsInvalid
        }
        try varid.put_vara(offset: offset, count: count, ptr: from)
        for i in dimensions.indices {
            dimensions[i].update(group: group)
        }
    }
    
    /// Unsafe because the data length is not validated.
    mutating func writeUnsafe(from: UnsafeRawPointer, offset: [Int], count: [Int], stride: [Int]) throws {
        guard dimensions.count == offset.count else {
            throw NetCDFError.numberOfDimensionsInvalid
        }
        guard dimensions.count == count.count else {
            throw NetCDFError.numberOfDimensionsInvalid
        }
        guard dimensions.count == stride.count else {
            throw NetCDFError.numberOfDimensionsInvalid
        }
        try varid.put_vars(offset: offset, count: count, stride: stride, ptr: from)
        for i in dimensions.indices {
            dimensions[i].update(group: group)
        }
    }
}

extension Variable: AttributeProvidable {
    /// Number for attributes for this variable
    public var numberOfAttributes: Int32 {
        return varid.inq_varnatts()
    }
}

extension Variable: VariableDefinable { }


/// A generic netcdf variable of a fixed data type
public struct VariableGeneric<T: NetcdfConvertible> {
    /// The non generic underlaying variable
    public var variable: Variable
    
    public init(variable: Variable) {
        self.variable = variable
    }
    
    /// Read by offset and count vector
    public func read(offset: [Int], count: [Int]) throws -> [T] {
        let n_elements = count.reduce(1, *)
        return try T.createFromBuffer(length: n_elements) { ptr in
            try variable.readUnsafe(into: ptr, offset: offset, count: count)
        }
    }
    
    /// Read by offset, count and stride vector
    public func read(offset: [Int], count: [Int], stride: [Int]) throws -> [T] {
        let n_elements = count.reduce(1, *)
        return try T.createFromBuffer(length: n_elements) { ptr in
            try variable.readUnsafe(into: ptr, offset: offset, count: count, stride: stride)
        }
    }
    
    /// Read the whole variable
    public func read() throws -> [T] {
        let offset = [Int](repeating: 0, count: variable.dimensions.count)
        let count = variable.dimensions.map { $0.length }
        return try read(offset: offset, count: count)
    }
    
    /// Write a complete array to the file. The array must be as large as the defined dimensions
    public mutating func write(_ data: [T]) throws {
        guard variable.count == data.count else {
            throw NetCDFError.numberOfElementsInvalid
        }
        let offest = [Int](repeating: 0, count: variable.dimensions.count)
        let dimensions = variable.dimensions.map { $0.length }
        try write(data, offset: offest, count: dimensions)
    }
    
    /// Write only a defined subset specified by offset and count
    public mutating func write(_ data: [T], offset: [Int], count: [Int]) throws {
        try T.withPointer(to: data) { ptr in
            try variable.writeUnsafe(from: ptr, offset: offset, count: count)
        }
    }
    
    /// Write only a defined subset specified by offset, count and stride
    public mutating func write(_ data: [T], offset: [Int], count: [Int], stride: [Int]) throws {
        try T.withPointer(to: data) { ptr in
            try variable.writeUnsafe(from: ptr, offset: offset, count: count, stride: stride)
        }
    }
}

/// Enable attributes getter and setter
extension VariableGeneric: AttributeProvidable {
    public var varid: VarId {
        return variable.varid
    }
    
    public var group: Group {
        return variable.group
    }
    
    public var numberOfAttributes: Int32 {
        return variable.numberOfAttributes
    }
}

/// Enable varibale define functions like compression
extension VariableGeneric: VariableDefinable {
    public var dimensions: [Dimension] {
        return variable.dimensions
    }
}


