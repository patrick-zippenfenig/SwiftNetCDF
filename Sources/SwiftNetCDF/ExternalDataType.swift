//
//  DataType.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-09.
//

import Foundation
import CNetCDF

/// Map netcdf type specific functions and swift data types
public enum ExternalDataType: Int32 {
    //case not_a_type = 0
    case byte = 1 // NC_BYTE Int8 8-bit signed integer
    case char = 2 // NC_CHAR Int8 8-bit character
    case short = 3 // Int16 NC_SHORT 16-bit integer
    case int32 = 4 // NC_INT (or NC_LONG) 32-bit signed integer
    case float = 5 // NC_FLOAT 32-bit floating point
    case double = 6 // NC_DOUBLE 64-bit floating point
    case ubyte = 7 // NC_UBYTE 8-bit unsigned integer *
    case ushort = 8 // NC_USHORT 16-bit unsigned integer *
    case uint32 = 9 // NC_UINT 32-bit unsigned integer *
    case int64 = 10 // NC_INT64 64-bit signed integer *
    case uint64 = 11 // NC_UINT64 64-bit unsigned integer *
    case string = 12 // NC_STRING variable length character string (available only for netCDF-4 (NC_NETCDF4) files.)
    
    //  These types are available only for CDF5 (NC_CDF5) and netCDF-4 format (NC_NETCDF4) files. All the unsigned ints and the 64-bit ints are for CDF5 or netCDF-4 files only.
    
    var name: String {
        return "\(self)"
    }
}


/// Conforming allows read and write operations for netcdf read/write
public protocol NetcdfConvertible {
    /// This function should prepare a buffer, pass it to a clouse which reads binary data and then return an array of that type
    static func createFromBuffer(length: Int, fn: (UnsafeMutableRawPointer) throws -> ()) throws -> [Self]
    
    /// Serialise array of values
    static func withPointer(to: [Self], fn: (UnsafeRawPointer) throws -> ()) throws
    
    static var netcdfType: ExternalDataType { get }
    
    /**
     Some NetCDF dataypes are not exclusively mapped to a single Swift type. E.g. NC_CHAR and NC_BYTE can both be read by Swift Int8.
     Also legacy applications with NetCDF version 3 did not have unsigned data types and may store unsigned data in signed data.
     Reading a NC_INT64 into Swift UInt is therefore also allowed
     */
    static func canRead(type: ExternalDataType) -> Bool
}

extension NetcdfConvertible {
    static func canRead(type: DataType) -> Bool {
        guard case let DataType.primitive(primitive) = type else {
            return false
        }
        return canRead(type: primitive)
    }
}


fileprivate protocol NetcdfConvertibleNumeric: NetcdfConvertible {
    static var emptyValue: Self { get }
}

extension NetcdfConvertibleNumeric {
    public static func createFromBuffer(length: Int, fn: (UnsafeMutableRawPointer) throws -> ()) throws -> [Self] {
        var arr = [Self](repeating: emptyValue, count: length)
        try fn(&arr)
        return arr
    }
    
    public static func withPointer(to: [Self], fn: (UnsafeRawPointer) throws -> ()) throws {
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


extension String: NetcdfConvertible {
    public static func canRead(type: ExternalDataType) -> Bool {
        return type == .string
    }
    
    public static var netcdfType: ExternalDataType { return .string }
    
    public static func createFromBuffer(length: Int, fn: (UnsafeMutableRawPointer) throws -> ()) throws -> [String] {
        var pointers = [UnsafeMutablePointer<Int8>?](repeating: nil, count: length)
        try fn(&pointers)
        let strings = pointers.map { String(cString: $0!) }
        netcdfLock.free_string(len: length, stringArray: &pointers)
        return strings
    }
    
    public static func withPointer(to: [String], fn: (UnsafeRawPointer) throws -> ()) throws {
        var pointers = [UnsafeRawPointer]()
        pointers.reserveCapacity(to.count)
        
        // Recursively call withCString until we have all pointer -> stack size may limit string array length
        func mapRecursive(i: Int, fn: (UnsafeRawPointer) throws -> ()) throws {
            if i == to.count {
                try fn(pointers)
                return
            }
            try to[i].withCString { ptr in
                pointers.append(ptr)
                try mapRecursive(i: i+1, fn: fn)
            }
        }
        try mapRecursive(i: 0, fn: fn)
        
        /// Cast data to a C string and then prepare an array of pointer
        //let cStrings = to.map { $0.cString(using: .utf8)! }
        //let pointers = cStrings.map { $0.withUnsafeBytes { $0.baseAddress! } }
        //try fn(pointers)
    }
}

/*

public protocol Primitive: Equatable {
    static var netCdfAtomic: ExternalDataType { get }
    static var netCdfNaNValue: Self { get }
    static func nc_put_vara(_ ncid: Int32, _ varid: Int32, start: [Int], count: [Int], data: [Self]) -> Int32
    static func nc_get_vara(_ ncid: Int32, _ varid: Int32, start: [Int], count: [Int], data: inout [Self]) -> Int32
    static func netCdfFromFloat(_ val: Float) -> Self
    func netCdfToFloat(scalefactor: Float) -> Float
    static func netCdfCreateNaNArray(count: Int) -> [Self]
}


extension Float: Primitive {
    public static func netCdfCreateNaNArray(count: Int) -> [Float] {
        return [Float](repeating: .nan, count: count)
    }
    
    public static var netCdfNaNValue: Float { return -Float.greatestFiniteMagnitude }
    public static func netCdfFromFloat(_ val: Float) -> Float {
        return val
    }
    public func netCdfToFloat(scalefactor: Float) -> Float {
        return self == .netCdfNaNValue ? Float.nan : self / scalefactor
    }
    public static func nc_put_vara(_ ncid: Int32, _ varid: Int32, start: [Int], count: [Int], data: [Float]) -> Int32 {
        return nc_put_vara_float(ncid, varid, start, count, data)
    }
    public static func nc_get_vara(_ ncid: Int32, _ varid: Int32, start: [Int], count: [Int], data: inout [Float]) -> Int32 {
        return nc_get_vara_float(ncid, varid, start, count, &data)
    }
    public static var netCdfAtomic: ExternalDataType { return .float }
}

extension Double: Primitive {

    public static func netCdfCreateNaNArray(count: Int) -> [Double] {
        return [Double](repeating: .nan, count: count)
    }
    
    public static var netCdfNaNValue: Double { return -Double.greatestFiniteMagnitude }
    public static func netCdfFromFloat(_ val: Float) -> Double {
        return Double(val)
    }
    public func netCdfToFloat(scalefactor: Float) -> Float {
        fatalError("Netcdf double should not be scaled to float!")
    }
    public static func nc_put_vara(_ ncid: Int32, _ varid: Int32, start: [Int], count: [Int], data: [Double]) -> Int32 {
        return nc_put_vara_double(ncid, varid, start, count, data)
    }
    public static func nc_get_vara(_ ncid: Int32, _ varid: Int32, start: [Int], count: [Int], data: inout [Double]) -> Int32 {
        return nc_get_vara_double(ncid, varid, start, count, &data)
    }
    public static var netCdfAtomic: ExternalDataType { return .double }
}

extension Int: Primitive {
    public static func netCdfCreateNaNArray(count: Int) -> [Int] {
        return [Int](repeating: netCdfNaNValue, count: count)
    }
    
    public static var netCdfNaNValue: Int { return -9223372036854775808 }
    public static func netCdfFromFloat(_ val: Float) -> Int {
        return Int(val)
    }
    public func netCdfToFloat(scalefactor: Float) -> Float {
        fatalError("Netcdf int64 should not be scaled to float!")
    }
    public static func nc_put_vara(_ ncid: Int32, _ varid: Int32, start: [Int], count: [Int], data: [Int]) -> Int32 {
        return nc_put_vara_long(ncid, varid, start, count, data)
    }
    public static func nc_get_vara(_ ncid: Int32, _ varid: Int32, start: [Int], count: [Int], data: inout [Int]) -> Int32 {
        return nc_get_vara_long(ncid, varid, start, count, &data)
    }
    public static var netCdfAtomic: ExternalDataType { return .int64 }
}


extension Int32: Primitive {
    public static var netCdfNaNValue: Int32 { return -2147483647 }
    public static func netCdfFromFloat(_ val: Float) -> Int32 {
        if val.isNaN {
            return netCdfNaNValue
        }
        return Int32(val)
    }
    public func netCdfToFloat(scalefactor: Float) -> Float {
        return self == .netCdfNaNValue ? Float.nan : Float(self) / scalefactor
    }
    public static func netCdfCreateNaNArray(count: Int) -> [Int32] {
        return [Int32](repeating: netCdfNaNValue, count: count)
    }
    public static func nc_put_vara(_ ncid: Int32, _ varid: Int32, start: [Int], count: [Int], data: [Int32]) -> Int32 {
        return nc_put_vara_int(ncid, varid, start, count, data)
    }
    public static func nc_get_vara(_ ncid: Int32, _ varid: Int32, start: [Int], count: [Int], data: inout [Int32]) -> Int32 {
        return nc_get_vara_int(ncid, varid, start, count, &data)
    }
    public static var netCdfAtomic: ExternalDataType { return .int32 }
}

extension Int16: Primitive {
    public static var netCdfNaNValue: Int16 { return -32768 }
    public static func netCdfFromFloat(_ val: Float) -> Int16 {
        if val.isNaN {
            return netCdfNaNValue
        }
        return Int16(val)
    }
    public func netCdfToFloat(scalefactor: Float) -> Float {
        return self == .netCdfNaNValue ? Float.nan : Float(self) / scalefactor
    }
    public static func netCdfCreateNaNArray(count: Int) -> [Int16] {
        return [Int16](repeating: netCdfNaNValue, count: count)
    }
    public static func nc_put_vara(_ ncid: Int32, _ varid: Int32, start: [Int], count: [Int], data: [Int16]) -> Int32 {
        return nc_put_vara_short(ncid, varid, start, count, data)
    }
    public static func nc_get_vara(_ ncid: Int32, _ varid: Int32, start: [Int], count: [Int], data: inout [Int16]) -> Int32 {
        return nc_get_vara_short(ncid, varid, start, count, &data)
    }
    public static var netCdfAtomic: ExternalDataType { return .short }
}


extension UInt32: Primitive {
    public static var netCdfNaNValue: UInt32 { return 4294967295 }
    public static func netCdfFromFloat(_ val: Float) -> UInt32 {
        if val.isNaN {
            return netCdfNaNValue
        }
        return UInt32(val)
    }
    public func netCdfToFloat(scalefactor: Float) -> Float {
        return self == .netCdfNaNValue ? Float.nan : Float(self) / scalefactor
    }
    public static func netCdfCreateNaNArray(count: Int) -> [UInt32] {
        return [UInt32](repeating: netCdfNaNValue, count: count)
    }
    public static func nc_put_vara(_ ncid: Int32, _ varid: Int32, start: [Int], count: [Int], data: [UInt32]) -> Int32 {
        return nc_put_vara_uint(ncid, varid, start, count, data)
    }
    public static func nc_get_vara(_ ncid: Int32, _ varid: Int32, start: [Int], count: [Int], data: inout [UInt32]) -> Int32 {
        return nc_get_vara_uint(ncid, varid, start, count, &data)
    }
    public static var netCdfAtomic: ExternalDataType { return .ushort }
}

extension UInt16: Primitive {
   
    public static var netCdfNaNValue: UInt16 { return 65535 }
    public static func netCdfFromFloat(_ val: Float) -> UInt16 {
        if val.isNaN {
            return netCdfNaNValue
        }
        return UInt16(val)
    }
    public func netCdfToFloat(scalefactor: Float) -> Float {
        return self == .netCdfNaNValue ? Float.nan : Float(self) / scalefactor
    }
    public static func netCdfCreateNaNArray(count: Int) -> [UInt16] {
        return [UInt16](repeating: netCdfNaNValue, count: count)
    }
    public static func nc_put_vara(_ ncid: Int32, _ varid: Int32, start: [Int], count: [Int], data: [UInt16]) -> Int32 {
        return nc_put_vara_ushort(ncid, varid, start, count, data)
    }
    public static func nc_get_vara(_ ncid: Int32, _ varid: Int32, start: [Int], count: [Int], data: inout [UInt16]) -> Int32 {
        return nc_get_vara_ushort(ncid, varid, start, count, &data)
    }
    public static var netCdfAtomic: ExternalDataType { return .ushort }
}

extension UInt8: Primitive {
    public static var netCdfNaNValue: UInt8 { return 255 }
    public static func netCdfFromFloat(_ val: Float) -> UInt8 {
        if val.isNaN {
            return netCdfNaNValue
        }
        return UInt8(val)
    }
    public func netCdfToFloat(scalefactor: Float) -> Float {
        return self == .netCdfNaNValue ? Float.nan : Float(self) / scalefactor
    }
    public static func netCdfCreateNaNArray(count: Int) -> [UInt8] {
        return [UInt8](repeating: netCdfNaNValue, count: count)
    }
    public static func nc_put_vara(_ ncid: Int32, _ varid: Int32, start: [Int], count: [Int], data: [UInt8]) -> Int32 {
        // IDL bug: nc_put_vara_schar has been modified to return unsigned
        return data.withUnsafeBytes { uptr in
            let ptr = uptr.bindMemory(to: Int8.self).baseAddress
            return nc_put_vara_schar(ncid, varid, start, count, ptr)
        }
    }
    public static func nc_get_vara(_ ncid: Int32, _ varid: Int32, start: [Int], count: [Int], data: inout [UInt8]) -> Int32 {
        // IDL bug: nc_put_vara_schar has been modified to return unsigned
        return data.withUnsafeMutableBytes { uptr in
            let ptr = uptr.bindMemory(to: Int8.self).baseAddress
            return nc_get_vara_schar(ncid, varid, start, count, ptr)
        }
    }
    public static var netCdfAtomic: ExternalDataType { return .byte }
}
*/
