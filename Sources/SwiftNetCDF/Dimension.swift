//
//  Dimension.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-08.
//

import Foundation
import CNetCDF



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
        var len: Int = 0
        var nameBuffer = [Int8](repeating: 0, count: Int(NC_MAX_NAME+1))
        try netcdfLock.nc_exec {
            nc_inq_dim(group.ncid, dimid, &nameBuffer, &len)
        }
        self.dimid = dimid
        self.name = String(cString: nameBuffer)
        self.length = len
        self.isUnlimited = isUnlimited
    }
    
    /**
     Define a new dimension in a group. length is ignored if isUnlimited is set
     TODO: Consider using a enum for length or unlimited
     */
    init(group: Group, name: String, length: Int, isUnlimited: Bool) throws {
        var dimid: Int32 = 0
        try netcdfLock.nc_exec {
            nc_def_dim(group.ncid, name, isUnlimited ? NC_UNLIMITED : length, &dimid)
        }
        self.dimid = dimid
        self.name = name
        self.length = length
        self.isUnlimited = isUnlimited
    }
    
    /*public enum LengthOrUnlimited {
        case length(Int)
        case unlimited
    }*/
}
