//
//  DataType.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-10.
//

import Foundation

// public enum DataClass: Int32 {
//     case nc_vlen = 9999 // NC_VLEN
// }

// public enum DataType {
//     case primitive(ExternalDataType)
//     case userDefined(UserDefinedType)

//     var typeid: TypeId {
//         switch self {
//         case .primitive(let type): return type.typeId
//         case .userDefined(let userDefined): return userDefined.typeid
//         }
//     }
//     var name: String {
//         switch self {
//         case .primitive(let type): return type.name
//         case .userDefined(let userDefined): return userDefined.name
//         }
//     }
//     var byteSize: Int { fatalError() }

//     init(type: TypeId, group: Group) {
//         if let primitive = ExternalDataType(rawValue: type.typeid) {
//             self = DataType.primitive(primitive)
//             return
//         }

//         let typeInq = try! group.ncid.inq_user_type(type: type)
//         // TODO switch user types
//         fatalError()

//     }
// }

// public enum UserDefinedType {
//     case enumeration(Enumeration)
//     case compound(Compound)
//     case opaque(Opaque)
//     case variableLength(VariableLength)

//     var typeid: TypeId { fatalError() }
//     var byteSize: Int { fatalError() }
//     var name: String { fatalError() }
// }

// public struct Compound {
//     let group: Group
//     let typeid: TypeId
//     let name: String
//     let size: Int
//     let numberOfFields: Int
// }

// public struct Opaque {
//     let group: Group
//     let typeid: TypeId
//     let name: String
//     let size: Int
// }

// public struct Enumeration {
//     let group: Group
//     let typeid: TypeId
//     let name: String
//     let size: Int
//     let numberOfFields: Int
// }

// public struct VariableLength {
//     let group: Group
//     let typeid: TypeId
//     let name: String
//     let size: Int
//     let baseTypeId: Int32
// }
