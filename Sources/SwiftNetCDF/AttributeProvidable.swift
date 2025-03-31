//
//  AttributeProvidable.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-20.
//

import Foundation

/// NetCDF groups and variables provide attributes. This protocol abstracts the attribute logic.
public protocol AttributeProvidable {
    var varid: VarId { get } // could be NC_GLOBAL
    var group: Group { get }

    /// Number of attributes for a group or variable
    var numberOfAttributes: Int32 { get }
}

extension AttributeProvidable {
    /// Get all attributes
    public func getAttributes() throws -> [Attribute<Self>] {
        return try (0 ..< numberOfAttributes).map {
            try getAttribute(try varid.inq_attname(attid: $0))!
        }
    }

    /// Get an attribute by name. Nil if it does not exist.
    /// This function is inlinable to allow type specialization across modules at compile time
    @inlinable public func getAttribute(_ key: String) throws -> Attribute<Self>? {
        return try Attribute(fromExistingName: key, parent: self)
    }

    /// Define a new attribute by name. The value must be a supported external type.
    public func setAttribute<T: NetcdfConvertible>(_ name: String, _ value: T) throws {
        try setAttribute(name, [value])
    }

    /// Define a new attribute by name. The value must be a supported external type. The type parameter can be set to enforce
    public func setAttribute<T: NetcdfConvertible>(_ name: String, _ value: [T], type: ExternalDataType = T.netcdfType) throws {
        guard T.canRead(type: type) else {
            throw NetCDFError.datatypeNotCompatible
        }

        try T.withPointer(to: value) { ptr in
            try setAttributeRaw(name: name, type: type.typeId, length: value.count, ptr: ptr)
        }
    }

    /// Set a netcdf attribute from raw pointer type
    internal func setAttributeRaw(name: String, type: TypeId, length: Int, ptr: UnsafeRawPointer) throws {
        try varid.put_att(name: name, type: type, length: length, ptr: ptr)
    }
}
