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
    
    var typeid: nc_type { fatalError() }
    var size: Int { fatalError() }
    
    init(fromTypeId typeid: nc_type, group: Group) {
        fatalError()
        // https://www.unidata.ucar.edu/software/netcdf/docs/group__user__types.html#gaf4340ce9486b1b38e853d75ed23303da
        // nc_inq_user_type return the user type
    }
}

public enum UserDefinedType {
    case enumeration(Enumeration)
    case compound(Compound)
    case opaque(Opaque)
    case variableLength(VariableLength)
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
