//
//  Attributes.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-09.
//

import Foundation

public protocol AttributeProvider {
    var varid: Int32 { get } // could be NC_GLOBAL
    var group: Group { get }
    
    /// groups and variables have differnet ways to get the attributes count
    var numberOfAttributes: Int32 { get }
}

extension AttributeProvider {
    public func getAttributes() throws -> [Attribute<Self>] {
        return try (0..<numberOfAttributes).map {
            try getAttribute(try netcdfLock.inq_attname(ncid: group.ncid, varid: varid, attid: $0))!
        }
    }
    
    public func getAttribute(_ key: String) throws -> Attribute<Self>? {
        return try Attribute(fromExistingName: key, parent: self)
    }
    
    public func setAttribute<T: NetcdfConvertible>(_ name: String, _ value: T) throws {
        try setAttribute(name, [value])
    }
    
    public func setAttribute<T: NetcdfConvertible>(_ name: String, _ value: [T]) throws {
        let type = DataType.primitive(T.netcdfType)
        try T.withPointer(to: value) { ptr in
            try setAttributeRaw(name: name, type: type, length: value.count, ptr: ptr)
        }
    }
    
    /// Set a netcdf attribute from raw pointer type
    public func setAttributeRaw(name: String, type: DataType, length: Int, ptr: UnsafeRawPointer) throws {
        try netcdfLock.put_att(ncid: group.ncid, varid: varid, name: name, type: type.typeid, length: length, ptr: ptr)
    }
}

public struct Attribute<Parent: AttributeProvider> {
    let parent: Parent
    let name: String
    let type: DataType
    let length: Int
    
    init?(fromExistingName name: String, parent: Parent) throws {
        do {
            let attinq = try netcdfLock.inq_att(ncid: parent.group.ncid, varid: parent.varid, name: name)
            self.parent = parent
            self.length = attinq.length
            self.type = try DataType(fromTypeId: attinq.typeid, group: parent.group)
            self.name = name
        } catch NetCDFError.attributeNotFound {
            return nil
        }
    }
    
    public func read<T: NetcdfConvertible>() throws -> [T]? {
        guard T.netcdfType.rawValue == type.typeid else {
            return nil
        }
        return try T.createFromBuffer(length: length, fn: readRaw)
    }
    
    public func read<T: NetcdfConvertible>() throws -> T? {
        guard length == 1 else {
            return nil
        }
        return try read()?.first
    }
    
    /// Read the raw into a prepared pointer
    public func readRaw(into buffer: UnsafeMutableRawPointer) throws {
        try netcdfLock.get_att(ncid: parent.group.ncid, varid: parent.varid, name: name, buffer: buffer)
    }
    
    public func to<T: NetcdfConvertible>(type _: T.Type) -> AttributePrimitiv<T>? {
        guard T.netcdfType.rawValue == self.type.typeid else {
            return nil
        }
        return AttributePrimitiv()
    }
}

/// is this layer usefull?
public struct AttributePrimitiv<T: NetcdfConvertible> {
    
}
