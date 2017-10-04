//
//  UploadTask.swift
//  cacom.info
//
//  Created by Nguyen Tuan on 3/16/17.
//  Copyright © 2017 Cacom.info. All rights reserved.
//

import Foundation

public class UploadTask : Operation, URLSessionDataDelegate {
    var fileURL: URL?
    var fileData: Data?
    var toURL: URL
    var progress: ((Float) -> ())?
    var postedValue: String?
    var completion: ((String?, FileProviderNetworkError?) -> ())?
    
    private var backgroundSession: URLSession?
    private var uploadSession: URLSessionTask?
    private var uploadCompleted: Bool = false
    
    private var debounceProgress: (()->())?
    
    init(fileURL: URL, toURL: URL, progress: ((Float) -> ())?, completion: ((String?, FileProviderNetworkError?) -> ())?) {
        self.fileURL = fileURL
        self.toURL = toURL
        
        super.init()
        self.progress = progress
        self.completion = completion
        
        debounceProgress = debounce(delay: 1, queue: .main, action: { [weak self] in
            if let `self` = self {
                self.progress?(self.lastP)
            }
        })
    }
    
    init(fileData data: Data, toURL: URL, progress: ((Float) -> ())?, completion: ((String?, FileProviderNetworkError?) -> ())?) {
        self.fileData = data
        self.toURL = toURL
        
        super.init()
        self.progress = progress
        self.completion = completion
        
        debounceProgress = debounce(delay: 1, queue: .main, action: { [weak self] in
            if let `self` = self {
                self.progress?(self.lastP)
            }
        })
    }
    
    
    override public func main() {
        let randomName = Int(Date().timeIntervalSince1970)
        let taskIdentifier = "\(String(describing: postedValue))&\(randomName)&\(arc4random()%1000)"
        let config = URLSessionConfiguration.background(withIdentifier: taskIdentifier)
        let session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
        
        var request = URLRequest(url: toURL)
        request.httpMethod = "PUT"
        request.timeoutInterval = 30
        var fileSize : UInt64 = 0
        
        if let fileURL = fileURL {
            request.httpBodyStream = InputStream(url: fileURL)
            do {
                //get file content size
                let attr = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                fileSize = attr[FileAttributeKey.size] as! UInt64
                
                //if you convert to NSDictionary, you can get file size old way as well.
                let dict = attr as NSDictionary
                fileSize = dict.fileSize()
            } catch {
                print("Error: \(error)")
            }
        }else if let fileData = fileData {
            request.httpBody = fileData
            fileSize = UInt64(fileData.count)
        }
        
        request.setValue("\(fileSize)", forHTTPHeaderField: "Content-Length")
        
        uploadSession = session.dataTask(with: request)
        self.backgroundSession = session
        uploadSession?.resume()
        
        //we will wait until the task is completed
//        while !self.uploadCompleted {
//        }
    }
    
    override public func cancel() {
        uploadSession?.cancel()
        super.cancel()
    }
 
    private var lastP: Float = 0
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard totalBytesExpectedToSend > 0 else {
            return
        }
        
        lastP = Float(totalBytesSent) / Float(totalBytesExpectedToSend) * 100
        debounceProgress?()
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("Did finish upload \(String(describing: postedValue)) with error \(String(describing: error))")
        completion?(error == nil ? postedValue: nil, error == nil ? nil : .uploadFail)
        uploadCompleted = true
    }
}
