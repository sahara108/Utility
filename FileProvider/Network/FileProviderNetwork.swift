//
//  FileProviderNetwork.swift
//  cacom.info
//
//  Created by Nguyen Tuan on 3/15/17.
//  Copyright © 2017 Cacom.info. All rights reserved.
//

public enum FileProviderNetworkError: CustomNSError {
    /// The domain of the error.
    public static var errorDomain: String { get {
            return "FileProviderNetworkManagementDomain"
        }
    }
    
    case uploadFail
}

open class FileProviderNetwork {
    private var uploadQueue = OperationQueue()
    private var downloadQueue = OperationQueue()
    
    public typealias FTPProgressReport = (Float) -> ()
    public typealias FTPFinalResport = (String?, FileProviderNetworkError?) -> ()
    
    public init() {
        uploadQueue.maxConcurrentOperationCount = 2
        downloadQueue.maxConcurrentOperationCount = 2
    }
    
    
    /// Upload a local file to a given url. It will creates a background session for the uploading. By default, the request will uses PUT method.
    ///
    /// - Parameters:
    ///   - filePath: the location of the file
    ///   - toURL: destination URL where we want to upload the file
    ///   - objectName: an unique value can be used for identifiying the request and will be sent back on completion
    ///   - progress: report about uploading progress
    ///   - completion: end of uploading progress. See `FTPFinalResport`
    @discardableResult
    open func startUploadFile(filePath: URL, toURL: URL, given objectName: String, progress: FTPProgressReport?, completion: FTPFinalResport?) -> UploadTask {
        let task = UploadTask(fileURL: filePath, toURL: toURL, progress: progress, completion: completion)
        task.postedValue = objectName
        uploadQueue.addOperation(task)
        
        return task
    }
    
    /// Upload file data to a given url. It will creates a background session for the uploading. By default, the request will uses PUT method.
    ///
    /// - Parameters:
    ///   - data: data to be uploaded
    ///   - toURL: destination URL where we want to upload the file
    ///   - objectName: an unique value can be used for identifiying the request and will be sent back on completion
    ///   - progress: report about uploading progress
    ///   - completion: end of uploading progress. See `FTPFinalResport`
    @discardableResult
    open func startUpload(data: Data, toURL: URL, given objectName: String, progress: FTPProgressReport?, completion: FTPFinalResport?) -> UploadTask {
        let task = UploadTask(fileData: data, toURL: toURL, progress: progress, completion: completion)
        task.postedValue = objectName
        uploadQueue.addOperation(task)
        
        return task
    }
    
    
    /// Download file from a given url. It will creates a background session for the downloading. Please note it will creates many diiferential sessions even if you try to download a single from many times
    ///
    /// - Parameters:
    ///   - fromURL: given url
    ///   - destinationPath: expected location for downloaded file. This path is expected to be returned in completion but it can returns a different path if there is an error while moving the file around
    ///   - progress: report about downloading progress
    ///   - completion: end of downloading progress.
    @discardableResult
    open func downloadFile(fromURL: URL, destinationPath: URL?, progress: FTPProgressReport?, completion: FTPFinalResport?) -> DownloadTask {
        let task = DownloadTask(downloadURL: fromURL, destinationPath: destinationPath, progress: progress, completion: completion)
        downloadQueue.addOperation(task)
        
        return task
    }
    
    open func wipe() {
        uploadQueue.cancelAllOperations()
        downloadQueue.cancelAllOperations()
    }
}
