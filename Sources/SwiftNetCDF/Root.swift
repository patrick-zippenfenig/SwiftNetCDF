import Foundation


public protocol NcRootProvider { }

public indirect enum RootOrGroup {
    case root(NcRootProvider)
    case group(Group)
}

public final class FileRoot: NcRootProvider {
    /// Netcdf ncid of the root group. Offers methods to query additional information
    public let ncid: NcId
    
    public init(ncid: NcId) {
        self.ncid = ncid
    }
    
    /// Close the netcdf file if this is the last group
    deinit {
        try? ncid.close()
    }
}

/// Retain reference to the underlaying memory storage
public final class MemoryRoot<D: ContiguousBytes>: NcRootProvider {
    /// Netcdf ncid of the root group. Offers methods to query additional information
    public let ncid: NcId
    
    public let fn: D
    
    public init(ncid: NcId, fn: D) {
        self.ncid = ncid
        self.fn = fn
    }
    
    /// Close the netcdf file if this is the last group
    deinit {
        try? ncid.close()
    }
}
