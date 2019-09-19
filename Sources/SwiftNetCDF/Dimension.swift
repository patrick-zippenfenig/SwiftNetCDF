//
//  Dimension.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-08.
//

import Foundation

/// Information about a dimension
public struct Dimension {
    public let dimid: DimId
    public let name: String
    
    /// length may be updated for unlimited dimensions
    public var length: Int
    
    public let isUnlimited: Bool
    
    /**
     Initialise from existing dimension ID. isUlimited must be supplied, because it can not be self discovered.
     */
    init(fromDimId dimid: DimId, isUnlimited: Bool, group: Group) {
        let diminq = group.ncid.inq_dim(dimid: dimid)
        self.dimid = dimid
        self.name = diminq.name
        self.length = diminq.length
        self.isUnlimited = isUnlimited
    }
    
    /// Update the dimension length in case the variable was updated
    internal mutating func update(group: Group) {
        let diminq = group.ncid.inq_dim(dimid: dimid)
        self.length = diminq.length
    }
    
    /**
     Define a new dimension in a group. length is ignored if isUnlimited is set
     TODO: Consider using a enum for length or unlimited
     */
    init(group: Group, name: String, length: Int, isUnlimited: Bool) throws {
        self.dimid = try group.ncid.def_dim(name: name, length: isUnlimited ? .unlimited : .length(length))
        self.name = name
        self.length = length
        self.isUnlimited = isUnlimited
    }
}
