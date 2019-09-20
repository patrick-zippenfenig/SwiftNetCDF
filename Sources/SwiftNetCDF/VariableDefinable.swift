//
//  VariableDefinable.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-20.
//

import Foundation

/// Offers `define` functions like `defineDeflate`. Used for `Variable` and `VariableGeneric`
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
     This is not available in older NetCDF versions
     */
    /*func defineFilter(id: UInt32, params: [UInt32]) throws {
        try varid.def_var_filter(id: id, params: params)
    }*/
}
