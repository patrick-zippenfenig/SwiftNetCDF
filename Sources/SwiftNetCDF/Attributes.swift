//
//  Attributes.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-09.
//

import Foundation
import CNetCDF

public protocol AttributeProvider {
    var varid: Int32 { get } // could be NC_GLOBAL
    var group: Group { get }
    
    /// groups and variables have differnet ways to get the attributes count
    var numberOfAttributes: Int32 { get }
}


/// not sure if this structure is usefull....
public struct Attribute<Parent: AttributeProvider> {
    let parent: Parent
    let name: String
    let type: DataType
    let length: Int
    
    init(fromExistingName name: String, parent: Parent) throws {
        let attinq = try netcdfLock.inq_att(ncid: parent.group.ncid, varid: parent.varid, name: name)
        self.parent = parent
        self.length = attinq.length
        self.type = try DataType(fromTypeId: attinq.typeid, group: parent.group)
        self.name = name
    }
    
    /// Read the raw Data
    public func readRaw() throws -> Data {
        // TODO check byte size
        let size = length * type.byteSize
        return try netcdfLock.get_att(ncid: parent.group.ncid, varid: parent.varid, name: name, size: size)
    }
}

extension AttributeProvider {
    // TODO list functions
    
    // get set attribute
    /*public func getAttributeName(attid: Int32) throws -> String? {
        return try netcdfLock.inq_attname(ncid: group.ncid, varid: varid, attid: attid)
    }*/
    
    public func getAttributes() throws -> [Attribute<Self>] {
        return try (0..<numberOfAttributes).map {
            try getAttribute(try netcdfLock.inq_attname(ncid: group.ncid, varid: varid, attid: $0))
        }
    }
    
    public func getAttribute(_ key: String) throws -> Attribute<Self> {
        return try Attribute(fromExistingName: key, parent: self)
    }
    
    /*public func getAttributeInfo(_ key: String) throws -> (typeid: nc_type, length: Int) {
        var typeid: nc_type = 0
        var length: Int = 0
        try netcdfLock.nc_exec { nc_inq_att(group.ncid, varid, key, &typeid, &length) }
        return (typeid, length)
    }
    
    public func getAttributeType(_ key: String) throws -> DataType {
        let attinq = try netcdfLock.inq_att(ncid: group.ncid, varid: varid, name: key)
        return try DataType(fromTypeId: attinq.typeid, group: group)
    }*/
    
    /// TODO this may not work well for arrays...
    public func getAttribute<T: NetCdfAttributeDataType>(_ name: String) throws -> T? {
        return netcdfLock.withLock { T.nc_get_att(group.ncid, varid, key: name) }
    }
    
    /// Set a netcdf attribute
    public func setAttribute<T:NetCdfAttributeDataType>(_ name: String, _ value: T) throws {
        try netcdfLock.nc_exec {
            T.nc_put_att(group.ncid, varid, key: name, value: value)
        }
    }
    

    
    /// Set a netcdf attribute from raw pointer type
    public func setAttributeRaw(name: String, type: DataType, data: Data) throws {
        try netcdfLock.put_att(ncid: group.ncid, varid: varid, name: name, type: type.typeid, data: data)
    }
}


