//
//  Attributes.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-09.
//

import Foundation
import CNetCDF

protocol AttributeProvider {
    var ncid: Int32 { get }
    var varid: Int32 { get } // could be NC_GLOBAL
    
}

extension AttributeProvider {
    // TODO list functions
    
    // get set attribute
    public func getAttributeName(id: Int32) throws -> String? {
        var ptr = [Int8](repeating: 0, count: Int(NC_MAX_NAME+1))
        try netcdfLock.nc_exec { nc_inq_attname(ncid, varid, id, &ptr) }
        return String(cString: &ptr)
    }
    
    /**
     Get the raw attribute data. See getAttributeInfo for length and data type
     */
    public func getAttributeRaw(_ key: String) throws -> UnsafeRawPointer {
        var ptr = UnsafeRawPointer(bitPattern: 0)
        try netcdfLock.nc_exec { nc_get_att(ncid, varid, key, &ptr) }
        guard let ptrUnwrapped = ptr else {
            fatalError("Could not get nc attribute raw pointer for name \(key)")
        }
        return ptrUnwrapped
    }
    
    public func getAttributeInfo(_ key: String) throws -> (typeid: nc_type, length: Int) {
        var typeid: nc_type = 0
        var length: Int = 0
        try netcdfLock.nc_exec { nc_inq_att(ncid, varid, key, &typeid, &length) }
        return (typeid, length)
    }
    
    public func getAttribute<T: NetCdfAttributeDataType>(_ key: String) throws -> T? {
        return netcdfLock.withLock { T.nc_get_att(ncid, varid, key: key) }
    }
    
    /// Set a netcdf attribute
    public func setAttribute<T:NetCdfAttributeDataType>(_ key: String, _ value: T) throws {
        try netcdfLock.nc_exec {
            T.nc_put_att(ncid, varid, key: key, value: value)
        }
    }
    
    /// Set a netcdf attribute from raw pointer type
    public func setAttributeRaw(_ key: String, type: nc_type, length: Int, ptr: UnsafeRawPointer) throws {
        try netcdfLock.nc_exec {
            nc_put_att(ncid, varid, key, type, length, ptr)
        }
    }
}


