//
//  Attribute.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-09.
//

import Foundation


/// A single attribute of a group or variable.
public struct Attribute<Parent: AttributeProvidable> {
    public let parent: Parent
    public let name: String
    public let type: TypeId
    public let length: Int
    
    /// Try to initialise from a name. Nil if the attributes does not exist
    public init?(fromExistingName name: String, parent: Parent) throws {
        guard let attinq = try parent.varid.inq_att(name: name) else {
            return nil
        }
        self.parent = parent
        self.length = attinq.length
        self.type = attinq.type
        self.name = name
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
    internal func readRaw(into buffer: UnsafeMutableRawPointer) throws {
        try parent.varid.get_att(name: name, buffer: buffer)
    }
    
    /*public func to<T: NetcdfConvertible>(type _: T.Type) -> AttributeGeneric<T>? {
        guard T.canRead(type: type) else {
            return nil
        }
        return AttributeGeneric()
    }*/
}

/// is this layer usefull?
/*public struct AttributeGeneric<T: NetcdfConvertible> {
    
}*/
