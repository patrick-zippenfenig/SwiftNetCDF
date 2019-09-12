//
//  Variable.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-10.
//

import Foundation

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
    
    /**
     Set the compression settings for a netCDF-4/HDF5 variable.
     
     This function must be called after nc_def_var and before nc_enddef or any functions which writes data to the file.
     
     Deflation and shuffline require chunked data. If this function is called on a variable with contiguous data, then the data is changed to chunked data, with default chunksizes. Use defineChunks() to tune performance with user-defined chunksizes.
     
     If this function is called on a scalar variable, it is ignored.
     */
    public func defineCompression(enable: Bool, level: Int = 6, shuffle: Bool = false) throws {
        try netcdfLock.def_var_deflate(ncid: group.ncid, varid: varid, shuffle: shuffle, deflate: enable, deflate_level: Int32(level))
    }
    

    /**
     Define chunking parameters for a variable.
     
     The function nc_def_var_chunking sets the chunking parameters for a variable in a netCDF-4 file. It can set the chunk sizes to get chunked storage, or it can set the contiguous flag to get contiguous storage.
     
     The total size of a chunk must be less than 4 GiB. That is, the product of all chunksizes and the size of the data (or the size of nc_vlen_t for VLEN types) must be less than 4 GiB.
     
     This function may only be called after the variable is defined, but before nc_enddef is called. Once the chunking parameters are set for a variable, they cannot be changed.
     
     Note that this does not work for scalar variables. Only non-scalar variables can have chunking.
     */
    public func defineChunks(chunking: Chunking, chunks: [Int]) throws {
        precondition(chunks.count == dimensions.count, "Chunk dimensions must have the same amount of elements as variable dimensions")
        try netcdfLock.def_var_chunking(ncid: group.ncid, varid: varid, type: chunking, chunks: chunks)
    }
    
    
    public func defineChecksuming(enable: Bool) throws {
        try netcdfLock.def_var_flechter32(ncid: group.ncid, varid: varid, enable: enable)
    }
    
    /**
     Define endianness of a variable.
     
     With this function the endianness (i.e. order of bits in integers) can be changed on a per-variable basis. By default, the endianness is the same as the default endianness of the platform. But with nc_def_var_endianness the endianness can be explicitly set for a variable.
     
     Warning: this function is only defined if the type of the variable is an atomic integer or float type.
     
     This function may only be called after the variable is defined, but before nc_enddef is called.
     */
    public func defineEndian(endian: Endian) throws {
        try netcdfLock.def_var_endian(ncid: group.ncid, varid: varid, type: endian)
    }
    
    /**
     Define a new variable filter.
     */
    public func defineFilter(id: UInt32, params: [UInt32]) throws {
        try netcdfLock.def_var_filter(ncid: group.ncid, varid: varid, id: id, params: params)
    }
    
    
    /// Try to cast this netcdf variable to a specfic primitive type for read and write operations
    public func asType<T: NetcdfConvertible>(_ of: T.Type) -> VariableGeneric<T>? {
        guard T.canRead(type: dataType) else {
            return nil
        }
        return VariableGeneric(variable: self)
    }
    
    /// Read raw by using the datatype size directly
    /*public func readRaw(offset: [Int], count: [Int]) throws -> Data {
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
    }*/
    
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
