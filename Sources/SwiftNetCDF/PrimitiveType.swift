//
//  DataType.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-09.
//

import Foundation
import CNetCDF

/// Map netcdf type specific functions and swift data types

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
    
    var name: String {
        return "\(self)"
    }
}



public protocol PrimitiveDataType {
    static var netcdfType: PrimitiveType { get }
    static var emptyValue: Self { get }
}

extension Float: PrimitiveDataType {
    public static var emptyValue: Float { return Float.nan }
    public static var netcdfType: PrimitiveType { return .float }
}

extension String {
    public static var netcdfType: PrimitiveType { return .string }
}

public protocol Primitive: Equatable {
    static var netCdfAtomic: PrimitiveType { get }
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
    public static var netCdfAtomic: PrimitiveType { return .float }
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
    public static var netCdfAtomic: PrimitiveType { return .double }
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
    public static var netCdfAtomic: PrimitiveType { return .int64 }
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
    public static var netCdfAtomic: PrimitiveType { return .int32 }
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
    public static var netCdfAtomic: PrimitiveType { return .short }
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
    public static var netCdfAtomic: PrimitiveType { return .ushort }
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
    public static var netCdfAtomic: PrimitiveType { return .ushort }
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
    public static var netCdfAtomic: PrimitiveType { return .byte }
}
