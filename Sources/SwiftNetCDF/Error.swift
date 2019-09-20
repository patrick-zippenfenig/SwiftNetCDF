//
//  Error.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-20.
//

import Foundation

import CNetCDF
import Foundation

/// All errors this library could throw
public enum NetCDFError: Error {
    case ncerror(code: Int32, error: String)
    case noSuchFileOrDirectory
    case invalidVariable
    case noGroupFound
    case badNcid
    case badVarid
    case badGroupid
    case badName
    case alreadyInDefineMode
    case attributeNotFound
    case noPermissions
    case valueCanNotBeConverted
    case operationRequiresNetCDFv4
    case fileIsInStrictNetCDFv3Mode
    case numberOfDimensionsInvalid
    case numberOfElementsInvalid
    case tooManyOpenFiles
    case outOfMemory
    case hdf5Error
    case netCDF4MetedataError
    case alreadyExists
    
    /// Init from NetCDF error code
    /// TODO find NetCDF definiton for code 2 "no such file"
    init(ncerr: Int32) {
        switch ncerr {
        case 2: self = .noSuchFileOrDirectory
        case NC_ENOTVAR: self = .invalidVariable
        case NC_EBADID: self = .badNcid
        case NC_ENOTVAR: self = .badVarid
        case NC_EBADGRPID: self = .badGroupid
        case NC_EBADNAME: self = .badName
        case NC_ENOTATT: self = .attributeNotFound
        case NC_EINDEFINE: self = .alreadyInDefineMode
        case NC_EPERM: self = .noPermissions
        case NC_ENOTNC4: self = .operationRequiresNetCDFv4
        case NC_ESTRICTNC3: self = .fileIsInStrictNetCDFv3Mode
        case NC_ENOGRP: self = .noGroupFound
        case NC_ENFILE: self = .tooManyOpenFiles
        case NC_ENOMEM: self = .outOfMemory
        case NC_EHDFERR: self = .hdf5Error
        case NC_EDIMMETA: self = .netCDF4MetedataError
        case NC_EEXIST: self = .alreadyExists
        default: self = .ncerror(code: ncerr, error: nc_stringError(ncerr))
        }
    }
}

/**
 Get a the error message for a code as a Swift String
 */
fileprivate func nc_stringError(_ ncerr: Int32) -> String {
    return String(cString: nc_strerror(ncerr))
}
