//
//  Variable.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-10.
//

import Foundation


public protocol VariableDefinable {
    var varid: VarId { get }
    var dimensions: [Dimension] { get }
}
public extension VariableDefinable {
    /// Number of elements in all dimensions
    var count: Int {
        return dimensions.reduce(1, {$0 * $1.length})
    }
    
    /// Dimensions array with only the amount of elements in each dimension
    var dimensionsFlat: [Int] {
        return dimensions.map { $0.length }
    }
    
    /**
     Set the compression settings for a netCDF-4/HDF5 variable.
     
     This function must be called after nc_def_var and before nc_enddef or any functions which writes data to the file.
     
     Deflation and shuffline require chunked data. If this function is called on a variable with contiguous data, then the data is changed to chunked data, with default chunksizes. Use defineChunks() to tune performance with user-defined chunksizes.
     
     If this function is called on a scalar variable, it is ignored.
     
     - Parameters:
     - enable: True to turn on deflation for this variable.
     - level: Compression level between 0 (no compression) and 9 (maximum compression). Default 6.
     - shuffle: True to turn on the shuffle filter. The shuffle filter can assist with the compression of integer data by changing the byte order in the data stream. It makes no sense to use the shuffle filter without setting a deflate level, or to use shuffle on non-integer data.
     
     - Throws:
     - `NetCDFError.badNcid`
     - `NetCDFError.badVarid`
     - ...
     */
    func defineDeflate(enable: Bool, level: Int = 6, shuffle: Bool = false) throws {
        try varid.def_var_deflate(shuffle: shuffle, deflate: enable, deflate_level: Int32(level))
    }
    
    
    /**
     Define chunking parameters for a variable.
     
     The function nc_def_var_chunking sets the chunking parameters for a variable in a netCDF-4 file. It can set the chunk sizes to get chunked storage, or it can set the contiguous flag to get contiguous storage.
     
     The total size of a chunk must be less than 4 GiB. That is, the product of all chunksizes and the size of the data (or the size of nc_vlen_t for VLEN types) must be less than 4 GiB.
     
     This function may only be called after the variable is defined, but before nc_enddef is called. Once the chunking parameters are set for a variable, they cannot be changed.
     
     Note that this does not work for scalar variables. Only non-scalar variables can have chunking.
     */
    func defineChunking(chunking: VarId.Chunking, chunks: [Int]) throws {
        guard chunks.count == dimensions.count else {
            throw NetCDFError.numberOfDimensionsInvalid
        }
        try varid.def_var_chunking(type: chunking, chunks: chunks)
    }
    
    /**
     Set checksum for a var.
     
     This function must be called after nc_def_var and before nc_enddef or any functions which writes data to the file.
     
     Checksums require chunked data. If this function is called on a variable with contiguous data, then the data is changed to chunked data, with default chunksizes. Use nc_def_var_chunking() to tune performance with user-defined chunksizes.
     */
    func defineChecksuming(enable: Bool) throws {
        try varid.def_var_flechter32(enable: enable)
    }
    
    /**
     Define endianness of a variable.
     
     With this function the endianness (i.e. order of bits in integers) can be changed on a per-variable basis. By default, the endianness is the same as the default endianness of the platform. But with nc_def_var_endianness the endianness can be explicitly set for a variable.
     
     Warning: this function is only defined if the type of the variable is an atomic integer or float type.
     
     This function may only be called after the variable is defined, but before nc_enddef is called.
     */
    func defineEndian(endian: VarId.Endian) throws {
        try varid.def_var_endian(type: endian)
    }
    
    /**
     Define a new variable filter.
     */
    func defineFilter(id: UInt32, params: [UInt32]) throws {
        try varid.def_var_filter(id: id, params: params)
    }
}


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

extension Variable: AttributeProvider {
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
extension VariableGeneric: AttributeProvider {
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


