//
//  File.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-10.
//

import Foundation
import CNetCDF

public final class File {
    let ncid: Int32 = 0
    
    static func create(file: String, overwriteExisting: Bool, useNetCDF4: Bool) throws -> File {
        fatalError()
    }
    
    static func open(file: String, allowWrite: Bool) throws -> File {
        fatalError()
    }
    
    func getRootGroup() -> Group {
        fatalError()
    }
}

public struct Group {
    let file: File
    /// id of the group
    let ncid: Int32
    
    // list groups / variables
    
    public func getVariable(byName name: String) -> Variable? {
        var varid: Int32 = 0
        let ncerr = netcdfLock.withLock { nc_inq_varid(ncid, name, &varid) }
        if ncerr != NC_NOERR {
            return nil
        }
        fatalError()
        //return Variable.init(fromVarId: varid, ncid: ncid, file: file)
    }
    
    public func createVariable<T: Primitive>(name: String, type: T.Type, dimensions: [Dimension]) -> VariablePrimitive<T> {
        // compression?
        fatalError()
    }
    
    public func getGroup() { }
    
    public func createGroup() { }
    
    /**
     Define a new dimension in this group
     */
    public func createDimension(name: String, length: Int, isUnlimited: Bool = false) throws -> Dimension {
        return try Dimension(group: self, name: name, length: length, isUnlimited: isUnlimited)
    }
    
    /**
     Get a list of IDs of unlimited dimensions.
     In netCDF-4 files, it's possible to have multiple unlimited dimensions. This function returns a list of the unlimited dimension ids visible in a group.
     Dimensions are visible in a group if they have been defined in that group, or any ancestor group.
     */
    public func getUnlimitedDimensionIds() throws -> [Int32] {
        // Get the number of dimesions
        var nUnlimited: Int32 = 0
        try netcdfLock.nc_exec {
            nc_inq_unlimdims(ncid, &nUnlimited, nil)
        }
        // Allocate array and get the IDs
        var unlimitedDimensions = [Int32](repeating: 0, count: Int(nUnlimited))
        try netcdfLock.nc_exec {
            nc_inq_unlimdims(ncid, nil, &unlimitedDimensions)
        }
        return unlimitedDimensions
    }
}


