//
//  File.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-10.
//

import Foundation

public final class File {
    static func create(file: String, overwriteExisting: Bool, useNetCDF4: Bool = true) throws -> Group {
        let ncid = try Nc.create(path: file, overwriteExisting: overwriteExisting, useNetCDF4: useNetCDF4)
        return try Group(ncid: ncid, parent: nil)
    }
    
    static func open(file: String, allowWrite: Bool) throws -> Group {
        let ncid = try Nc.open(path: file, allowWrite: allowWrite)
        return try Group(ncid: ncid, parent: nil)
    }
}
