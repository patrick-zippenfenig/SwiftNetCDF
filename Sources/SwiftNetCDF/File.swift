//
//  File.swift
//  SwiftNetCDF
//
//  Created by Patrick Zippenfenig on 2019-09-10.
//

import Foundation

public final class File {
    static func create(file: String, overwriteExisting: Bool, useNetCDF4: Bool = true) throws -> Group {
        let ncid = try netcdfLock.create(path: file, overwriteExisting: overwriteExisting, useNetCDF4: useNetCDF4)
        return try Group(ncid: ncid, parent: nil)
    }
    
    static func open(file: String, allowWrite: Bool) throws -> Group {
        let ncid = try netcdfLock.open(path: file, allowWrite: allowWrite   )
        return try Group(ncid: ncid, parent: nil)
    }
}

public final class Group {
    let parent: Group?
    /// id of the group
    let ncid: Int32
    let name: String
    
    /// Existing group from ID.
    init(ncid: Int32, parent: Group?) throws {
        self.parent = parent
        self.ncid = ncid
        self.name = try netcdfLock.inq_grpname(ncid: ncid)
    }
    
    /// Create a new group
    init(name: String, parent: Group) throws {
        self.ncid = try netcdfLock.def_grp(ncid: parent.ncid, name: name)
        self.parent = parent
        self.name = name
    }
    
    /// Close the netcdf file if this is the last group
    deinit {
        if parent == nil {
            try? netcdfLock.close(ncid: ncid)
        }
    }
    
    /// Return the (CDL Common Data Language) representation
    func getCdl(headerOnly: Bool = true, indent: Int = 0) throws -> String {
        var out = ""
        let ind = String(repeating: " ", count: indent)
        let dimensions = try getDimensions()
        out += "\(ind)group: \(name) {\n"
        out += "\(ind)  dimensions:\n"
        dimensions.forEach {
            out += "\(ind)        \($0.getCdl())\n"
        }
        
        let variables = try getVariables()
        out += "\(ind)  variables:\n"
        variables.forEach {
            out += $0.getCdl(indent: indent+8)
        }
        out += "\(ind)  } // group \(name)"
        return out
    }
    
    /// Return all dimensions registered in this group
    public func getDimensions() throws -> [Dimension] {
        let ids = try netcdfLock.inq_dimids(ncid: ncid, includeParents: false)
        let unlimited = try netcdfLock.inq_unlimdims(ncid: ncid)
        return try ids.map { try Dimension(fromDimId: $0, isUnlimited: unlimited.contains($0), group: self) }
    }
    
    /// Try to open an exsiting variable. Nil if it does not exist
    public func getVariable(byName name: String) throws -> Variable? {
        do {
            let varid = try netcdfLock.inq_varid(ncid: ncid, name: name)
            return try Variable(fromVarId: varid, group: self)
        } catch (NetCDFError.invalidVariable) {
            return nil
        }
    }
    
    /// Get all varibales in the group
    public func getVariables() throws -> [Variable] {
        let ids = try netcdfLock.inq_varids(ncid: ncid)
        return try ids.map { try Variable(fromVarId: $0, group: self) }
    }
    
    /// Define a new variable in the netcdf file
    public func createVariable(name: String, dataType: DataType, dimensions: [Dimension]) throws -> Variable {
        return try Variable(name: name, dataType: dataType, dimensions: dimensions, group: self)
    }
    
    public func createVariable<T: Primitive>(name: String, type: T.Type, dimensions: [Dimension]) throws -> VariablePrimitive<T> {
        
        let vari = try createVariable(name: name, dataType: DataType.primitive(T.netCdfAtomic), dimensions: dimensions)
        return VariablePrimitive(variable: vari)
    }
    
    /// Try to open an exsisting subgroup. Nil if it does not exist
    public func getGroup(byName name: String) throws -> Group? {
        do {
            let groupId = try netcdfLock.inq_grp_ncid(ncid: ncid, name: name)
            return try Group(ncid: groupId, parent: self)
        } catch (NetCDFError.badNcid) { // TODO check which error is used
            return nil
        }
    }
    
    /// Define a new group in the netcdf file
    public func createGroup(name: String) throws -> Group {
        return try Group(name: name, parent: self)
    }
    
    /// Get all subgroups
    public func getGroups() throws -> [Group] {
        let ids = try netcdfLock.inq_grps(ncid: ncid)
        return try ids.map { try Group(ncid: $0, parent: self) }
    }
    
    /**
     Define a new dimension in this group
     */
    public func createDimension(name: String, length: Int, isUnlimited: Bool = false) throws -> Dimension {
        return try Dimension(group: self, name: name, length: length, isUnlimited: isUnlimited)
    }
    
    public func sync() {
        // Throws only an exception if ncid is invalid
        try! netcdfLock.sync(ncid: ncid)
    }
}


