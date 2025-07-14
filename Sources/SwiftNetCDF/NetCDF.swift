//
//  NetCDF.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-10.
//

import Foundation

public enum NetCDF {
    /// Create a new netCDF file.
    ///
    /// This function creates a new netCDF dataset, returning a netCDF ID that can subsequently be used to refer to the netCDF dataset in other netCDF function calls. The new netCDF dataset opened for write access and placed in define mode, ready for you to add dimensions, variables, and attributes.
    ///
    /// - Parameters:
    ///    - path: The file name of the new netCDF dataset.
    ///    - overwriteExisting: If true, an existing file will be overwritten
    ///    - useNetCDF4: IIf true, a netCDF4 file will be created. Default true.
    ///
    /// - Throws:
    ///     - `NetCDFError.alreadyExists` Specifying a file name of a file that exists and `overwriteExisting` is false.
    ///     - `NetCDFError.noPermissions` Attempting to create a netCDF file in a directory where you do not have permission to create files.
    ///     - `NetCDFError.tooManyOpenFiles` Too many files open
    ///     - `NetCDFError.outOfMemory` Out of memory
    ///     - `NetCDFError.hdf5Error` HDF5 error. (NetCDF-4 files only.)
    ///     - `NetCDFError.netCDF4MetedataError` Error in netCDF-4 dimension metadata. (NetCDF-4 files only.)
    ///
    /// - Returns: Root group of a NetCDF file
    public static func create(path: String, overwriteExisting: Bool, useNetCDF4: Bool = true) throws -> Group {
        let ncid = try Nc.create(path: path, overwriteExisting: overwriteExisting, useNetCDF4: useNetCDF4)
        return Group(ncid: ncid, root: FileRoot(ncid: ncid))
    }

    /// Open an existing netCDF file.
    ///
    /// This function opens an existing netCDF dataset for access. It determines the underlying file format automatically. Use the same call to open a netCDF classic or netCDF-4 file.
    ///
    /// - Parameters:
    ///    - path: File name for netCDF dataset to be opened. When the dataset is located on some remote server, then the path may be an OPeNDAP URL rather than a file path. If a the path is a DAP URL, then the open mode is read-only. Setting NC_WRITE will be ignored.
    ///    - allowUpdate: If true, opens the dataset with read-write access. ("Writing" means any kind of change to the dataset, including appending or changing data, adding or renaming dimensions, variables, and attributes, or deleting attributes.)
    ///
    /// - Throws:
    ///    - `NetCDFError.noPermissions` Attempting to open a netCDF file in a directory where you do not have permission to open files.
    ///    - `NetCDFError.tooManyOpenFiles` Too many files open
    ///    - `NetCDFError.outOfMemory` Out of memory
    ///    - `NetCDFError.hdf5Error` HDF5 error. (NetCDF-4 files only.)
    ///    - `NetCDFError.netCDF4MetedataError` Error in netCDF-4 dimension metadata. (NetCDF-4 files only.)
    ///
    /// - Returns: Root group of a NetCDF file or nil if the file does not exist
    public static func open(path: String, allowUpdate: Bool) throws -> Group? {
        do {
            let ncid = try Nc.open(path: path, allowUpdate: allowUpdate)
            return Group(ncid: ncid, root: FileRoot(ncid: ncid))
        } catch NetCDFError.noSuchFileOrDirectory {
            return nil
        }
    }

    /// Open a netCDF file with the contents taken from a block of memory. Retains a reference to the memory block.
    ///
    /// This function opens an existing netCDF dataset for access. It determines the underlying file format automatically. Use the same call to open a netCDF classic or netCDF-4 file.
    ///
    /// - Parameters:
    ///    - memory: A memory buffer with NetCDF data. Please ensure that the memory address remained valid while using the NetCDF handle.
    ///    - datasetName: Can be set to specify the name of the dataset
    ///
    /// - Throws:
    ///    - `NetCDFError.noPermissions` Attempting to open a netCDF file in a directory where you do not have permission to open files.
    ///    - `NetCDFError.tooManyOpenFiles` Too many files open
    ///    - `NetCDFError.outOfMemory` Out of memory
    ///    - `NetCDFError.hdf5Error` HDF5 error. (NetCDF-4 files only.)
    ///    - `NetCDFError.netCDF4MetedataError` Error in netCDF-4 dimension metadata. (NetCDF-4 files only.)
    ///
    /// - Returns: Root group of a NetCDF file or nil if memory cannot be opened as a netcdf handle
    public static func open<D: ContiguousBytes>(memory: D, datasetName: String = "dataset") throws -> Group? {
        do {
            return try memory.withUnsafeBytes({
                let ncid = try Nc.open(memory: $0, datasetName: datasetName)
                return Group(ncid: ncid, root: MemoryRoot(ncid: ncid, fn: memory))
            })
        } catch NetCDFError.noSuchFileOrDirectory {
            return nil
        }
    }
}
