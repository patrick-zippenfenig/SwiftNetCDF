//
//  Dimension.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-08.
//

import Foundation

public final class File {
    let ncid: Int32 = 0
}

public indirect enum FileOrGroup {
    case file(File)
    case group(Group)
}

public enum PrimitiveType: Int32 {
    //case not_a_type = 0
    case byte = 1 // Int8 schar
    case char = 2 // Int8 schar
    case short = 3 // Int16 short
    case int32 = 4
    case float = 5
    case double = 6
    case ubyte = 7
    case ushort = 8
    case uint32 = 9
    case int64 = 10
    case string = 12
}

public struct Dimension {
    let dimid: Int32
    let name: String
    let length: Int
    // is unlimited?
}

public struct Group {
    let parent: FileOrGroup
    let groupid: Int32
}

public struct Variable {
    let parent: FileOrGroup
    let name: String
    let varid: Int32
    let dimensions: [Dimension]
    let type: PrimitiveType
}

protocol AttributeProvider {
}
extension AttributeProvider {
    // get set attribute
}
