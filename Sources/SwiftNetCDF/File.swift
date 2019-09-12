//
//  File.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-10.
//

import Foundation

public final class File {
    /**
     Create a new netCDF file.
     
     This function creates a new netCDF dataset, returning a netCDF ID that can subsequently be used to refer to the netCDF dataset in other netCDF function calls. The new netCDF dataset opened for write access and placed in define mode, ready for you to add dimensions, variables, and attributes.
     
     - Parameters:
        - path: The file name of the new netCDF dataset.
        - overwriteExisting: If true, an existing file will be overwritten
        - useNetCDF4: IIf true, a netCDF4 file will be created. Default true.
     
     - Throws:
         - `NetCDFError.alreadyExists` Specifying a file name of a file that exists and `overwriteExisting` is false.
         - `NetCDFError.noPermissions` Attempting to create a netCDF file in a directory where you do not have permission to create files.
         - `NetCDFError.tooManyOpenFiles` Too many files open
         - `NetCDFError.outOfMemory` Out of memory
         - `NetCDFError.hdf5Error` HDF5 error. (NetCDF-4 files only.)
         - `NetCDFError.netCDF4MetedataError` Error in netCDF-4 dimension metadata. (NetCDF-4 files only.)
     
     - Returns: Root group of a NetCDF file
     */
    public static func create(path: String, overwriteExisting: Bool, useNetCDF4: Bool = true) throws -> Group {
        let ncid = try Nc.create(path: path, overwriteExisting: overwriteExisting, useNetCDF4: useNetCDF4)
        return Group(ncid: ncid, parent: nil)
    }
    
    /**
     Open an existing netCDF file.
     
     This function opens an existing netCDF dataset for access. It determines the underlying file format automatically. Use the same call to open a netCDF classic or netCDF-4 file.
     
     - Parameters:
        - path: File name for netCDF dataset to be opened. When the dataset is located on some remote server, then the path may be an OPeNDAP URL rather than a file path. If a the path is a DAP URL, then the open mode is read-only. Setting NC_WRITE will be ignored.
        - allowWrite: If true, opens the dataset with read-write access. ("Writing" means any kind of change to the dataset, including appending or changing data, adding or renaming dimensions, variables, and attributes, or deleting attributes.)
     
     - Throws:
        - `NetCDFError.noPermissions` Attempting to create a netCDF file in a directory where you do not have permission to open files.
        - `NetCDFError.tooManyOpenFiles` Too many files open
        - `NetCDFError.outOfMemory` Out of memory
        - `NetCDFError.hdf5Error` HDF5 error. (NetCDF-4 files only.)
        - `NetCDFError.netCDF4MetedataError` Error in netCDF-4 dimension metadata. (NetCDF-4 files only.)
     
     - Returns: Root group of a NetCDF file
     */
    public static func open(path: String, allowWrite: Bool) throws -> Group {
        let ncid = try Nc.open(path: path, allowWrite: allowWrite)
        return Group(ncid: ncid, parent: nil)
    }
}
