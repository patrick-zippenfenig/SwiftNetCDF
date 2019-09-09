//
//  AttributeType.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-09.
//

import Foundation
import CNetCDF


/// Abstract netcdf attributes with generics
public protocol NetCdfAttributeDataType {
    static func nc_put_att(_ ncid: Int32, _ varid: Int32, key: String, value: Self) -> Int32
    static func nc_get_att(_ ncid: Int32, _ varid: Int32, key: String) -> Self?
}


extension String: NetCdfAttributeDataType {
    public static func nc_get_att(_ ncid: Int32, _ varid: Int32, key: String) -> String? {
        let ptr = UnsafeMutablePointer<Int8>(bitPattern: 0)
        let ncerr = nc_get_att_text(ncid, varid, key, ptr)
        if ncerr != NC_NOERR { return nil }
        guard let cstring = ptr else { return nil }
        return String(cString: cstring)
    }
    public static func nc_put_att(_ ncid: Int32, _ varid: Int32, key: String, value: String) -> Int32 {
        return value.withCString { nc_put_att_text(ncid, varid, key, strlen($0), $0) }
    }
}
extension Float: NetCdfAttributeDataType {
    public static func nc_get_att(_ ncid: Int32, _ varid: Int32, key: String) -> Float? {
        var value: Float = 0
        if nc_get_att_float(ncid, varid, key, &value) != NC_NOERR { return nil }
        return value
    }
    public static func nc_put_att(_ ncid: Int32, _ varid: Int32, key: String, value: Float) -> Int32 {
        var val = value
        return nc_put_att_float(ncid, varid, key, self.netCdfAtomic.rawValue, 1, &val)
    }
}
extension Double: NetCdfAttributeDataType {
    public static func nc_get_att(_ ncid: Int32, _ varid: Int32, key: String) -> Double? {
        var value: Double = 0
        if nc_get_att_double(ncid, varid, key, &value) != NC_NOERR { return nil }
        return value
    }
    public static func nc_put_att(_ ncid: Int32, _ varid: Int32, key: String, value: Double) -> Int32 {
        var val = value
        return nc_put_att_double(ncid, varid, key, self.netCdfAtomic.rawValue, 1, &val)
    }
}
extension Int: NetCdfAttributeDataType {
    public static func nc_get_att(_ ncid: Int32, _ varid: Int32, key: String) -> Int? {
        var value: Int = 0
        if nc_get_att_long(ncid, varid, key, &value) != NC_NOERR { return nil }
        return value
    }
    public static func nc_put_att(_ ncid: Int32, _ varid: Int32, key: String, value: Int) -> Int32 {
        var val = value
        return nc_put_att_long(ncid, varid, key, self.netCdfAtomic.rawValue, 1, &val)
    }
}
extension Int32: NetCdfAttributeDataType {
    public static func nc_get_att(_ ncid: Int32, _ varid: Int32, key: String) -> Int32? {
        var value: Int32 = 0
        if nc_get_att_int(ncid, varid, key, &value) != NC_NOERR { return nil }
        return value
    }
    public static func nc_put_att(_ ncid: Int32, _ varid: Int32, key: String, value: Int32) -> Int32 {
        var val = value
        return nc_put_att_int(ncid, varid, key, self.netCdfAtomic.rawValue, 1, &val)
    }
}
extension UInt32: NetCdfAttributeDataType {
    public static func nc_get_att(_ ncid: Int32, _ varid: Int32, key: String) -> UInt32? {
        var value: UInt32 = 0
        if nc_get_att_uint(ncid, varid, key, &value) != NC_NOERR { return nil }
        return value
    }
    public static func nc_put_att(_ ncid: Int32, _ varid: Int32, key: String, value: UInt32) -> Int32 {
        var val = value
        return nc_put_att_uint(ncid, varid, key, self.netCdfAtomic.rawValue, 1, &val)
    }
}
extension Int16: NetCdfAttributeDataType {
    public static func nc_get_att(_ ncid: Int32, _ varid: Int32, key: String) -> Int16? {
        var value: Int16 = 0
        if nc_get_att_short(ncid, varid, key, &value) != NC_NOERR { return nil }
        return value
    }
    public static func nc_put_att(_ ncid: Int32, _ varid: Int32, key: String, value: Int16) -> Int32 {
        var val = value
        return nc_put_att_short(ncid, varid, key, self.netCdfAtomic.rawValue, 1, &val)
    }
}
extension UInt16: NetCdfAttributeDataType {
    public static func nc_get_att(_ ncid: Int32, _ varid: Int32, key: String) -> UInt16? {
        var value: UInt16 = 0
        if nc_get_att_ushort(ncid, varid, key, &value) != NC_NOERR { return nil }
        return value
    }
    public static func nc_put_att(_ ncid: Int32, _ varid: Int32, key: String, value: UInt16) -> Int32 {
        var val = value
        return nc_put_att_ushort(ncid, varid, key, self.netCdfAtomic.rawValue, 1, &val)
    }
}



