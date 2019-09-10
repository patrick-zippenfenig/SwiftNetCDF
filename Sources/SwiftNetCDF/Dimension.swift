//
//  Dimension.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-08.
//

import Foundation

/*public indirect enum FileOrGroup {
    case file(File)
    case group(Group)
}*/

public struct Dimension {
    let dimid: Int32
    let name: String
    
    /// length my be updated for unlimited dimensions
    let length: Int
    
    let isUnlimited: Bool
    
    /**
     Initialise from existing dimension ID. isUlimited must be supplied, because it can not be self discovered.
     */
    init(fromDimId dimid: Int32, isUnlimited: Bool, group: Group) throws {
        let diminq = try netcdfLock.inq_dim(ncid: group.ncid, dimid: dimid)
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
        self.dimid = try netcdfLock.def_dim(ncid: group.ncid, name: name, length: isUnlimited ? netcdfLock.NC_UNLIMITED : length)
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
    
    /*public enum LengthOrUnlimited {
        case length(Int)
        case unlimited
    }*/
}
