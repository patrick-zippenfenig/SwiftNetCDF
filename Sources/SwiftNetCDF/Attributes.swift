//
//  Attributes.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-09.
//

import Foundation

/**
 NetCDF groups and variables provide attributes. This protocol abstracts the attribute logic.
 */
public protocol AttributeProvider {
    var varid: VarId { get } // could be NC_GLOBAL
    var group: Group { get }
    
    /// Number of attributes for a group or variable
    var numberOfAttributes: Int32 { get }
}

extension AttributeProvider {
    /// Get all attributes
    public func getAttributes() throws -> [Attribute<Self>] {
        return try (0..<numberOfAttributes).map {
            try getAttribute(try varid.inq_attname(attid: $0))!
        }
    }
    
    /// Get an attribute by name. Nil if it does not exist.
    public func getAttribute(_ key: String) throws -> Attribute<Self>? {
        return try Attribute(fromExistingName: key, parent: self)
    }
    
    /// Define a new attribute by name. The value must be a supported external type.
    public func setAttribute<T: NetcdfConvertible>(_ name: String, _ value: T) throws {
        try setAttribute(name, [value])
    }
    
    /// Define a new attribute by name. The value must be a supported external type.
    public func setAttribute<T: NetcdfConvertible>(_ name: String, _ value: [T]) throws {
        let type = DataType.primitive(T.netcdfType)
        try T.withPointer(to: value) { ptr in
            try setAttributeRaw(name: name, type: type, length: value.count, ptr: ptr)
        }
    }
    
    /// Set a netcdf attribute from raw pointer type
    public func setAttributeRaw(name: String, type: DataType, length: Int, ptr: UnsafeRawPointer) throws {
        try varid.put_att(name: name, type: type.typeid, length: length, ptr: ptr)
    }
}

/// A single attribute of a group or variable.
public struct Attribute<Parent: AttributeProvider> {
    let parent: Parent
    let name: String
    let type: DataType
    let length: Int
    
    /// Try to initialise from a name. Nil if the attributes does not exist
    fileprivate init?(fromExistingName name: String, parent: Parent) throws {
        do {
            let attinq = try parent.varid.inq_att(name: name)
            self.parent = parent
            self.length = attinq.length
            self.type = DataType(fromTypeId: attinq.typeid, group: parent.group)
            self.name = name
        } catch NetCDFError.attributeNotFound {
            return nil
        }
    }
    
    /// Try to read this attribute as an external type. Nil if types do not match.
    public func read<T: NetcdfConvertible>() throws -> [T]? {
        guard T.canRead(type: type) else {
            return nil
        }
        return try T.createFromBuffer(length: length, fn: readRaw)
    }
    
    /// Try to read this attribute as an external type. Nil if types do not match or it is not a scalar.
    public func read<T: NetcdfConvertible>() throws -> T? {
        guard length == 1 else {
            return nil
        }
        return try read()?.first
    }
    
    /// Read the raw into a prepared pointer
    public func readRaw(into buffer: UnsafeMutableRawPointer) throws {
        try parent.varid.get_att(name: name, buffer: buffer)
    }
    
    public func to<T: NetcdfConvertible>(type _: T.Type) -> AttributeGeneric<T>? {
        guard T.netcdfType.typeId == self.type.typeid else {
            return nil
        }
        return AttributeGeneric()
    }
}

/// is this layer usefull?
public struct AttributeGeneric<T: NetcdfConvertible> {
    
}
