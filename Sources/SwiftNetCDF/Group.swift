//
//  Group.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-12.
//

import Foundation


public struct Group {
    /// Parent is either another group or the file root
    public let parent: RootOrGroup

    /// Netcdf ncid of the group. Offers methods to query additional information
    public let ncid: NcId

    /// Name of this group. "/" for the root group.
    public let name: String

    /// Existing group from ID.
    init(ncid: NcId, root: any NcRootProvider) {
        self.parent = .root(root)
        self.ncid = ncid
        self.name = ncid.inq_grpname()
    }
    
    /// Existing group from ID.
    init(ncid: NcId, parent: Group) {
        self.parent = .group(parent)
        self.ncid = ncid
        self.name = ncid.inq_grpname()
    }

    /// Create a new group
    init(name: String, parent: Group) throws {
        self.ncid = try parent.ncid.def_grp(name: name)
        self.parent = .group(parent)
        self.name = name
    }

    /// Return all dimensions registered in this group
    public func getDimensions() -> [Dimension] {
        let ids = ncid.inq_dimids(includeParents: false)
        // Unlimited dimensions are not be available in NetCDF-3 files
        let unlimited = (try? ncid.inq_unlimdims()) ?? []

        return ids.map { Dimension(fromDimId: $0, isUnlimited: unlimited.contains($0), group: self) }
    }

    /// Try to open an existing variable. Nil if it does not exist
    public func getVariable(name: String) -> Variable? {
        guard let varid = ncid.inq_varid(name: name) else {
            return nil
        }
        return Variable(fromVarId: varid, group: self)
    }

    /// Get all variables in the group
    public func getVariables() -> [Variable] {
        let ids = ncid.inq_varids()
        return ids.map { Variable(fromVarId: $0, group: self) }
    }

    /// Define a new variable in the netcdf file
    /// Internal because user data types should not yet be exposed
    internal func createVariable(name: String, type: TypeId, dimensions: [Dimension]) throws -> Variable {
        return try Variable(name: name, type: type, dimensions: dimensions, group: self)
    }

    public func createVariable<T: NetcdfConvertible>(name: String, type: T.Type, dimensions: [Dimension]) throws -> VariableGeneric<T> {
        let variable = try createVariable(name: name, type: T.netcdfType.typeId, dimensions: dimensions)
        return VariableGeneric(variable: variable)
    }

    /// Try to open an existing subgroup. Nil if it does not exist
    public func getGroup(name: String) -> Group? {
        guard let groupId = ncid.inq_grp_ncid(name: name) else {
            return nil
        }
        return Group(ncid: groupId, parent: self)
    }

    /// Define a new group in the netcdf file
    public func createGroup(name: String) throws -> Group {
        return try Group(name: name, parent: self)
    }

    /// Get all subgroups
    public func getGroups() -> [Group] {
        let ids = ncid.inq_grps()
        return ids.map { Group(ncid: $0, parent: self) }
    }

    /// Define a new dimension in this group
    public func createDimension(name: String, length: Int, isUnlimited: Bool = false) throws -> Dimension {
        return try Dimension(group: self, name: name, length: length, isUnlimited: isUnlimited)
    }

    /// Synchronize an open netcdf dataset to disk.
    ///
    /// The function nc_sync() offers a way to synchronize the disk copy of a netCDF dataset with in-memory buffers. There are two reasons you might want to synchronize after writes:
    ///
    /// To minimize data loss in case of abnormal termination, or
    /// To make data available to other processes for reading immediately after it is written. But note that a process that already had the dataset open for reading would not see the number of records increase when the writing process calls nc_sync(); to accomplish this, the reading process must call nc_sync.
    /// This function is backward-compatible with previous versions of the netCDF library. The intent was to allow sharing of a netCDF dataset among multiple readers and one writer, by having the writer call nc_sync() after writing and the readers call nc_sync() before each read. For a writer, this flushes buffers to disk. For a reader, it makes sure that the next read will be from disk rather than from previously cached buffers, so that the reader will see changes made by the writing process (e.g., the number of records written) without having to close and reopen the dataset. If you are only accessing a small amount of data, it can be expensive in computer resources to always synchronize to disk after every write, since you are giving up the benefits of buffering.
    ///
    /// An easier way to accomplish sharing (and what is now recommended) is to have the writer and readers open the dataset with the NC_SHARE flag, and then it will not be necessary to call nc_sync() at all. However, the nc_sync() function still provides finer granularity than the NC_SHARE flag, if only a few netCDF accesses need to be synchronized among processes.
    ///
    /// It is important to note that changes to the ancillary data, such as attribute values, are not propagated automatically by use of the NC_SHARE flag. Use of the nc_sync() function is still required for this purpose.
    ///
    /// Sharing datasets when the writer enters define mode to change the data schema requires extra care. In previous releases, after the writer left define mode, the readers were left looking at an old copy of the dataset, since the changes were made to a new copy. The only way readers could see the changes was by closing and reopening the dataset. Now the changes are made in place, but readers have no knowledge that their internal tables are now inconsistent with the new dataset schema. If netCDF datasets are shared across redefinition, some mechanism external to the netCDF library must be provided that prevents access by readers during redefinition and causes the readers to call nc_sync before any subsequent access.
    ///
    /// When calling nc_sync(), the netCDF dataset must be in data mode. A netCDF dataset in define mode is synchronized to disk only when nc_enddef() is called. A process that is reading a netCDF dataset that another process is writing may call nc_sync to get updated with the changes made to the data by the writing process (e.g., the number of records written), without having to close and reopen the dataset.
    ///
    /// Data is automatically synchronized to disk when a netCDF dataset is closed, or whenever you leave define mode.
    public func sync() {
        ncid.sync()
    }

    /// Put open netcdf dataset into define mode.
    ///
    /// The function nc_redef puts an open netCDF dataset into define mode, so dimensions, variables, and attributes can be added or renamed and attributes can be deleted.
    ///
    /// For netCDF-4 files (i.e. files created with NC_NETCDF4 in the cmode in their call to nc_create()), it is not necessary to call nc_redef() unless the file was also created with NC_STRICT_NC3. For straight-up netCDF-4 files, nc_redef() is called automatically, as needed.
    ///
    /// For all netCDF-4 files, the root ncid must be used. This is the ncid returned by nc_open() and nc_create(), and points to the root of the hierarchy tree for netCDF-4 files.
    ///
    /// - Throws:
    /// - `NetCDFError.badGroupid` The ncid must refer to the root group of the file and not a subgroup
    /// - `NetCDFError.alreadyInDefineMode` Already in define mode
    /// - `NetCDFError.noPermissions` File is read only
    public func redefine() throws {
        try ncid.redef()
    }

    /// Leave define mode.
    ///
    /// The changes made to the netCDF dataset while it was in define mode are checked and committed to disk if no problems occurred. Non-record variables may be initialized to a "fill value" as well with nc_set_fill(). The netCDF dataset is then placed in data mode, so variable data can be read or written.
    ///
    /// It's not necessary to call nc_enddef() for netCDF-4 files. With netCDF-4 files, nc_enddef() is called when needed by the netcdf-4 library. User calls to nc_enddef() for netCDF-4 files still flush the metadata to disk.
    ///
    /// This call may involve copying data under some circumstances. For a more extensive discussion see File Structure and Performance.
    ///
    /// For netCDF-4/HDF5 format files there are some variable settings (the compression, endianness, fletcher32 error correction, and fill value) which must be set (if they are going to be set at all) between the nc_def_var() and the next nc_enddef(). Once the nc_enddef() is called, these settings can no longer be changed for a variable.
    public func endDefineMode() {
        ncid.enddef()
    }

    /// Change the fill-value mode to improve write performance.
    ///
    /// This function is intended for advanced usage, to optimize writes under some circumstances described below. The function nc_set_fill() sets the fill mode for a netCDF dataset open for writing and returns the current fill mode in a return parameter. The fill mode can be specified as either NC_FILL or NC_NOFILL. The default behavior corresponding to NC_FILL is that data is pre-filled with fill values, that is fill values are written when you create non-record variables or when you write a value beyond data that has not yet been written. This makes it possible to detect attempts to read data before it was written. For more information on the use of fill values see Fill Values. For information about how to define your own fill values see Attribute Conventions.
    ///
    /// The behavior corresponding to NC_NOFILL overrides the default behavior of prefilling data with fill values. This can be used to enhance performance, because it avoids the duplicate writes that occur when the netCDF library writes fill values that are later overwritten with data.
    ///
    /// A value indicating which mode the netCDF dataset was already in is returned. You can use this value to temporarily change the fill mode of an open netCDF dataset and then restore it to the previous mode.
    ///
    /// After you turn on NC_NOFILL mode for an open netCDF dataset, you must be certain to write valid data in all the positions that will later be read. Note that nofill mode is only a transient property of a netCDF dataset open for writing: if you close and reopen the dataset, it will revert to the default behavior. You can also revert to the default behavior by calling nc_set_fill() again to explicitly set the fill mode to NC_FILL.
    ///
    /// There are three situations where it is advantageous to set nofill mode:
    ///
    /// - Creating and initializing a netCDF dataset. In this case, you should set nofill mode before calling nc_enddef() and then write completely all non-record variables and the initial records of all the record variables you want to initialize.
    /// - Extending an existing record-oriented netCDF dataset. Set nofill mode after opening the dataset for writing, then append the additional records to the dataset completely, leaving no intervening unwritten records.
    /// - Adding new variables that you are going to initialize to an existing netCDF dataset. Set nofill mode before calling nc_enddef() then write all the new variables completely.
    ///
    /// If the netCDF dataset has an unlimited dimension and the last record was written while in nofill mode, then the dataset may be shorter than if nofill mode was not set, but this will be completely transparent if you access the data only through the netCDF interfaces.
    ///
    /// The use of this feature may not be available (or even needed) in future releases. Programmers are cautioned against heavy reliance upon this feature.
    ///
    /// - Parameter mode: `.fill` or `.noFill`
    ///
    /// - Throws: `NetCDFError.noPermissions` if file is in read only mode
    public func setFillMode(_ mode: NcId.FillMode) throws {
        try ncid.set_fill(mode: mode)
    }
}

extension Group: AttributeProvidable {
    public var varid: VarId {
        return ncid.NC_GLOBAL()
    }

    public var group: Group {
        return self
    }

    public var numberOfAttributes: Int32 {
        return ncid.inq_natts()
    }
}
