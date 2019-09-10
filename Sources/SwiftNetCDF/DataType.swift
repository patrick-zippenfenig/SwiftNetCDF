//
//  DataType.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-10.
//

import Foundation
import CNetCDF

public enum DataClass: Int32 {
    case nc_vlen = 9999 // NC_VLEN
}

public enum DataType {
    case primitive(PrimitiveType)
    case userDefined(UserDefinedType)
    
    var typeid: nc_type {
        switch self {
        case .primitive(let type): return type.rawValue
        case .userDefined(let userDefined): return userDefined.typeid
        }
    }
    var byteSize: Int { fatalError() }
    
    init(fromTypeId typeid: nc_type, group: Group) throws {
        if let primitve = PrimitiveType(rawValue: typeid) {
            self = DataType.primitive(primitve)
            return
        }
        
        let typeInq = try netcdfLock.inq_user_type(ncid: group.ncid, typeid: typeid)
        // TODO switch user types
        fatalError()
        
    }
}

public enum UserDefinedType {
    case enumeration(Enumeration)
    case compound(Compound)
    case opaque(Opaque)
    case variableLength(VariableLength)
    
    var typeid: nc_type { fatalError() }
    var byteSize: Int { fatalError() }
}

public struct Compound {
    let group: Group
    let typeid: nc_type
    let name: String
    let size: Int
    let numerOfFields: Int
}

public struct Opaque {
    let group: Group
    let typeid: nc_type
    let name: String
    let size: Int
}

public struct Enumeration {
    let group: Group
    let typeid: nc_type
    let name: String
    let size: Int
    let numerOfFields: Int
}

public struct VariableLength {
    let group: Group
    let typeid: nc_type
    let name: String
    let size: Int
    let baseTypeId: nc_type
}
