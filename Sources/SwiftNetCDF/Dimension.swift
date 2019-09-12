//
//  Dimension.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-08.
//

import Foundation

/// Information about a dimension
public struct Dimension {
    let dimid: DimId
    let name: String
    
    /// length my be updated for unlimited dimensions
    let length: Int
    
    let isUnlimited: Bool
    
    /**
     Initialise from existing dimension ID. isUlimited must be supplied, because it can not be self discovered.
     */
    init(fromDimId dimid: DimId, isUnlimited: Bool, group: Group) throws {
        let diminq = try group.ncid.inq_dim(dimid: dimid)
        self.dimid = dimid
        self.name = diminq.name
        self.length = diminq.length
        self.isUnlimited = isUnlimited
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
    
    public func getCdl() -> String {
        if isUnlimited {
            return "\(name) UNLIMITED ; // \(length) currently"
        }
        return "\(name) = \(length) ;"
    }
}
