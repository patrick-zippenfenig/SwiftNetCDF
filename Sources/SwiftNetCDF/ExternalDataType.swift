//
//  DataType.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-09.
//

import Foundation

/// These datatypes are available as external and are mapped to Swift datatypes with the protocol `NetcdfConvertible`.
public enum ExternalDataType: Int32, Sendable {
    /// NC_BYTE Int8 8-bit signed integer
    case byte = 1
    /// NC_CHAR Int8 8-bit character
    case char = 2
    /// Int16 NC_SHORT 16-bit integer
    case short = 3
    /// NC_INT (or NC_LONG) 32-bit signed integer
    case int32 = 4
    /// NC_FLOAT 32-bit floating point
    case float = 5
    /// NC_DOUBLE 64-bit floating point
    case double = 6
    /// NC_UBYTE 8-bit unsigned integer (NetCDF 4 only)
    case ubyte = 7
    /// NC_USHORT 16-bit unsigned integer (NetCDF 4 only)
    case ushort = 8
    /// NC_UINT 32-bit unsigned integer (NetCDF 4 only)
    case uint32 = 9
    /// NC_INT64 64-bit signed integer (NetCDF 4 only)
    case int64 = 10
    /// NC_UINT64 64-bit unsigned integer (NetCDF 4 only)
    case uint64 = 11
    /// NC_STRING variable length character string (NetCDF 4 only)
    case string = 12
}

/// Conforming allows read and write operations for netcdf read/write
public protocol NetcdfConvertible {
    /// This function should prepare a buffer, pass it to a closure which reads binary data and then return an array of that type
    static func createFromBuffer(length: Int, fn: (UnsafeMutableRawPointer) throws -> Void) throws -> [Self]

    /// Serialize array of values
    static func withPointer(to: [Self], fn: (UnsafeRawPointer) throws -> Void) throws

    /// The type a Swift variable should represent in a NetCDF file.
    static var netcdfType: ExternalDataType { get }

    /// Some NetCDF datatypes are not exclusively mapped to a single Swift type. E.g. NC_CHAR and NC_BYTE can both be read by Swift Int8.
    /// Also legacy applications with NetCDF version 3 did not have unsigned data types and may store unsigned data in signed data.
    /// Reading a NC_INT64 into Swift UInt is therefore also allowed
    static func canRead(type: ExternalDataType) -> Bool
}

extension NetcdfConvertible {
    /// Wether or not this type can be read
    @inlinable public static func canRead(type: TypeId) -> Bool {
        guard let externalType = type.asExternalDataType() else {
            return false
        }
        return canRead(type: externalType)
    }
}

/// Numeric NetCDF external types. Actually all types except String. A basic conversion with array is possible.
public protocol NetcdfConvertibleNumeric: NetcdfConvertible {
    static var emptyValue: Self { get }
}

extension NetcdfConvertibleNumeric {
    public static func createFromBuffer(length: Int, fn: (UnsafeMutableRawPointer) throws -> Void) throws -> [Self] {
        var arr = [Self](repeating: emptyValue, count: length)
        try fn(&arr)
        return arr
    }

    public static func withPointer(to: [Self], fn: (UnsafeRawPointer) throws -> Void) throws {
        try fn(to)
    }
}

extension Float: NetcdfConvertibleNumeric {
    public static var emptyValue: Float { return Float.nan }
    public static var netcdfType: ExternalDataType { return .float }
    public static func canRead(type: ExternalDataType) -> Bool {
        return type == .float
    }
}
extension Double: NetcdfConvertibleNumeric {
    public static var emptyValue: Double { return Double.nan }
    public static var netcdfType: ExternalDataType { return .double }
    public static func canRead(type: ExternalDataType) -> Bool {
        return type == .double
    }
}
extension Int8: NetcdfConvertibleNumeric {
    public static var emptyValue: Int8 { return Int8.min }
    public static var netcdfType: ExternalDataType { return .byte }
    public static func canRead(type: ExternalDataType) -> Bool {
        return type == .byte || type == .char
    }
}
extension Int16: NetcdfConvertibleNumeric {
    public static var emptyValue: Int16 { return Int16.min }
    public static var netcdfType: ExternalDataType { return .short }
    public static func canRead(type: ExternalDataType) -> Bool {
        return type == .short
    }
}
extension Int32: NetcdfConvertibleNumeric {
    public static var emptyValue: Int32 { return Int32.min }
    public static var netcdfType: ExternalDataType { return .int32 }
    public static func canRead(type: ExternalDataType) -> Bool {
        return type == .int32
    }
}
extension Int: NetcdfConvertibleNumeric {
    public static var emptyValue: Int { return Int.min }
    public static var netcdfType: ExternalDataType { return .int64 }
    public static func canRead(type: ExternalDataType) -> Bool {
        return type == .int64
    }
}
extension Int64: NetcdfConvertibleNumeric {
    public static var emptyValue: Int64 { return Int64.min }
    public static var netcdfType: ExternalDataType { return .int64 }
    public static func canRead(type: ExternalDataType) -> Bool {
        return type == .int64
    }
}
extension UInt8: NetcdfConvertibleNumeric {
    public static var emptyValue: UInt8 { return UInt8.max }
    public static var netcdfType: ExternalDataType { return .ubyte }
    public static func canRead(type: ExternalDataType) -> Bool {
        return type == .ubyte || type == .byte || type == .char
    }
}
extension UInt16: NetcdfConvertibleNumeric {
    public static var emptyValue: UInt16 { return UInt16.max }
    public static var netcdfType: ExternalDataType { return .ushort }
    public static func canRead(type: ExternalDataType) -> Bool {
        return type == .ushort || type == .short
    }
}
extension UInt32: NetcdfConvertibleNumeric {
    public static var emptyValue: UInt32 { return UInt32.max }
    public static var netcdfType: ExternalDataType { return .uint32 }
    public static func canRead(type: ExternalDataType) -> Bool {
        return type == .uint32 || type == .int32
    }
}
extension UInt: NetcdfConvertibleNumeric {
    public static var emptyValue: UInt { return UInt.max }
    public static var netcdfType: ExternalDataType { return .uint64 }
    public static func canRead(type: ExternalDataType) -> Bool {
        return type == .uint64 || type == .int64
    }
}
extension UInt64: NetcdfConvertibleNumeric {
    public static var emptyValue: UInt64 { return UInt64.max }
    public static var netcdfType: ExternalDataType { return .uint64 }
    public static func canRead(type: ExternalDataType) -> Bool {
        return type == .uint64 || type == .int64
    }
}

extension String: NetcdfConvertible {
    public static func canRead(type: ExternalDataType) -> Bool {
        return type == .string
    }

    public static var netcdfType: ExternalDataType { return .string }

    public static func createFromBuffer(length: Int, fn: (UnsafeMutableRawPointer) throws -> Void) throws -> [String] {
        var pointers = [UnsafeMutablePointer<Int8>?](repeating: nil, count: length)
        try fn(&pointers)
        let strings = pointers.map { String(cString: $0!) }
        Nc.free_string(len: length, stringArray: &pointers)
        return strings
    }

    public static func withPointer(to: [String], fn: (UnsafeRawPointer) throws -> Void) throws {
        var pointers = [UnsafeRawPointer]()
        pointers.reserveCapacity(to.count)

        // Recursively call withCString until we have all pointer -> stack size may limit string array length
        func mapRecursive(i: Int, fn: (UnsafeRawPointer) throws -> Void) throws {
            if i == to.count {
                try fn(pointers)
                return
            }
            try to[i].withCString { ptr in
                pointers.append(ptr)
                try mapRecursive(i: i + 1, fn: fn)
            }
        }
        try mapRecursive(i: 0, fn: fn)

        /// Cast data to a C string and then prepare an array of pointer
        // let cStrings = to.map { $0.cString(using: .utf8)! }
        // let pointers = cStrings.map { $0.withUnsafeBytes { $0.baseAddress! } }
        // try fn(pointers)
    }
}
