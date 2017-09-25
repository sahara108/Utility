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

public protocol FileCache {
    func imageCacheDirectory() -> URL
}

class FileProviderCache: NSObject, FileCache {
    func applicationCache() -> URL {
        if let path = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).last {
            let final = path.appendingPathComponent("Utility").appendingPathComponent("Cache")
            return final
        }
        
        return URL(string: "Utility")!
    }
    
    func imageCacheDirectory() -> URL {
        let source = self.applicationCache()
        let path = source.appendingPathComponent("Images")
        
        if !FileManager.default.fileExists(atPath: path.path) {
            #if os(OSX)
                try! NSFileManager.defaultManager().createDirectoryAtURL(path, withIntermediateDirectories: true, attributes: nil)
            #else
                try! FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: [FileAttributeKey(rawValue: FileAttributeKey.protectionKey.rawValue) : FileProtectionType.completeUntilFirstUserAuthentication])
            #endif
            
        }
        
        return path
    }
}
