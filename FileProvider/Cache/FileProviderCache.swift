//
//  FileProviderCache.swift
//  Utility
//
//  Created by Nguyen Tuan on 7/5/17.
//  Copyright © 2017 Nguyen Tuan. All rights reserved.
//

import UIKit

enum FileCacheType {
    case image
}

class FileProviderCache: NSObject {
    class func applicationCache() -> URL {
        if let path = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).last {
            let final = path.appendingPathComponent("Utility").appendingPathComponent("Cache")
            return final
        }
        
        return URL(string: "Utility")!
    }
    
    class func imageCacheDirectory() -> URL {
        let source = self.applicationCache()
        let path = source.appendingPathComponent("Images")
        
        if !FileManager.default.fileExists(atPath: path.path) {
            #if os(OSX)
                try! NSFileManager.defaultManager().createDirectoryAtURL(path, withIntermediateDirectories: true, attributes: nil)
            #else
                try! FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: [FileAttributeKey.protectionKey.rawValue : FileProtectionType.completeUntilFirstUserAuthentication])
            #endif
            
        }
        
        return path
    }
}
