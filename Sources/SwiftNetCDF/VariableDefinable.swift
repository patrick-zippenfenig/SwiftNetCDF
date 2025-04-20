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
        return dimensions.reduce(1, { $0 * $1.length })
    }

    /// Dimensions array with only the amount of elements in each dimension
    var dimensionsFlat: [Int] {
        return dimensions.map { $0.length }
    }

    /// Set the compression settings for a netCDF-4/HDF5 variable.
    ///
    /// This function must be called after nc_def_var and before nc_enddef or any functions which writes data to the file.
    ///
    /// Deflation and shuffline require chunked data. If this function is called on a variable with contiguous data, then the data is changed to chunked data, with default chunksizes. Use defineChunks() to tune performance with user-defined chunksizes.
    ///
    /// If this function is called on a scalar variable, it is ignored.
    ///
    /// - Parameters:
    /// - enable: True to turn on deflation for this variable.
    /// - level: Compression level between 0 (no compression) and 9 (maximum compression). Default 6.
    /// - shuffle: True to turn on the shuffle filter. The shuffle filter can assist with the compression of integer data by changing the byte order in the data stream. It makes no sense to use the shuffle filter without setting a deflate level, or to use shuffle on non-integer data.
    ///
    /// - Throws:
    /// - `NetCDFError.badNcid`
    /// - `NetCDFError.badVarid`
    /// - ...
    func defineDeflate(enable: Bool, level: Int = 6, shuffle: Bool = false) throws {
        try varid.def_var_deflate(shuffle: shuffle, deflate: enable, deflate_level: Int32(level))
    }

    /// Set szip compression settings on a variable.
    ///
    /// Szip is an implementation of the extended-Rice lossless compression algorithm; it is reported to provide fast and effective compression. Szip is only available to netCDF if HDF5 was built with szip support.
    ///
    /// SZIP compression cannot be applied to variables with any user-defined type.
    ///
    /// If zlib compression has already be turned on for a variable, then this function will return NC_EINVAL.
    ///
    /// To learn the szip settings for a variable, use nc_inq_var_szip().
    ///
    /// Note: The options_mask parameter may be either NC_SZIP_EC (entropy coding) or NC_SZIP_NN (nearest neighbor):
    ///  - The entropy coding method is best suited for data that has been processed. The EC method works best for small numbers.
    ///  - The nearest neighbor coding method preprocesses the data then the applies EC method as above.
    /// For more information about HDF5 and szip, see https://support.hdfgroup.org/HDF5/doc/RM/RM_H5P.html#Property-SetSzip and https://support.hdfgroup.org/doc_resource/SZIP/index.html.
    ///
    /// - Parameters-
    /// - options_mask    The options mask. Can be NC_SZIP_EC or NC_SZIP_NN.
    /// - pixels_per_block    Pixels per block. Must be even and not greater than 32, with typical values being 8, 10, 16, or 32. This parameter affects compression ratio; the more pixel values vary, the smaller this number should be to achieve better performance. If pixels_per_block is bigger than the total number of elements in a dataset chunk, NC_EINVAL will be returned.
    func defineSzip(options: VarId.SzipOptions, pixelPerBlock: Int32) throws {
        try varid.def_var_szip(options: options, pixel_per_block: pixelPerBlock)
    }

    /// Define chunking parameters for a variable.
    ///
    /// The function nc_def_var_chunking sets the chunking parameters for a variable in a netCDF-4 file. It can set the chunk sizes to get chunked storage, or it can set the contiguous flag to get contiguous storage.
    ///
    /// The total size of a chunk must be less than 4 GiB. That is, the product of all chunksizes and the size of the data (or the size of nc_vlen_t for VLEN types) must be less than 4 GiB.
    ///
    /// This function may only be called after the variable is defined, but before nc_enddef is called. Once the chunking parameters are set for a variable, they cannot be changed.
    ///
    /// Note that this does not work for scalar variables. Only non-scalar variables can have chunking.
    func defineChunking(chunking: VarId.Chunking, chunks: [Int]) throws {
        guard chunks.count == dimensions.count else {
            throw NetCDFError.numberOfDimensionsInvalid
        }
        try varid.def_var_chunking(type: chunking, chunks: chunks)
    }

    /// Set checksum for a var.
    ///
    /// This function must be called after nc_def_var and before nc_enddef or any functions which writes data to the file.
    ///
    /// Checksums require chunked data. If this function is called on a variable with contiguous data, then the data is changed to chunked data, with default chunksizes. Use nc_def_var_chunking() to tune performance with user-defined chunksizes.
    func defineChecksuming(enable: Bool) throws {
        try varid.def_var_fletcher32(enable: enable)
    }

    /// Define endianness of a variable.
    ///
    /// With this function the endianness (i.e. order of bits in integers) can be changed on a per-variable basis. By default, the endianness is the same as the default endianness of the platform. But with nc_def_var_endianness the endianness can be explicitly set for a variable.
    ///
    /// Warning: this function is only defined if the type of the variable is an atomic integer or float type.
    ///
    /// This function may only be called after the variable is defined, but before nc_enddef is called.
    func defineEndian(endian: VarId.Endian) throws {
        try varid.def_var_endian(type: endian)
    }

    /// Define a new variable filter.
    /// This is not available in older NetCDF versions
    // func defineFilter(id: UInt32, params: [UInt32]) throws {
    //     try varid.def_var_filter(id: id, params: params)
    // }
}
