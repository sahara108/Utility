//
//  UploadTask.swift
//  cacom.info
//
//  Created by Nguyen Tuan on 3/16/17.
//  Copyright © 2017 Cacom.info. All rights reserved.
//

public class DownloadTask : Operation, URLSessionDataDelegate {
    var downloadURL: URL
    var progress: ((Float) -> ())?
    var completion: ((String?, FileProviderNetworkError?) -> ())?
    private var downloadCompleted = false
    public var useDefaulSession = false
    
    private var downloadSession: URLSessionTask?
    private var session: URLSession?
    private var tempFile: URL
    var expectedFilePath: URL
    
    private var debounceProgress: (()->())?
    init(downloadURL: URL, destinationPath: URL?, progress: ((Float) -> ())?, completion: ((String?, FileProviderNetworkError?) -> ())?) {
        self.downloadURL = downloadURL
        
        let tmpDir = NSTemporaryDirectory()
        let randomName = Int(Date().timeIntervalSince1970)
        let tmpURL = URL(fileURLWithPath: tmpDir)
        let path = tmpURL.appendingPathComponent("\(randomName)\(arc4random()%1000)")
        tempFile = path
        
        if let output = destinationPath {
            expectedFilePath = output
        }else {
            expectedFilePath = tmpURL.appendingPathComponent("\(abs(downloadURL.hashValue))\(arc4random()%100)")
        }
        
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
        //check if file exist in the tmp dir, return it
//        if FileManager.default.fileExists(atPath: expectedFilePath.path) {
//            completion?(expectedFilePath.path, nil)
//            return
//        }
        
        if !useDefaulSession {
            let randomName = Int(Date().timeIntervalSince1970)
            let taskIdentifier = "\(downloadURL.absoluteString)&\(randomName)&\(arc4random()%1000)"
            let config = URLSessionConfiguration.background(withIdentifier: taskIdentifier)
            config.allowsCellularAccess = false
            session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
        }else {
            session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
        }
        
        var request = URLRequest(url: downloadURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        request.cachePolicy = .useProtocolCachePolicy
        request.setValue("gzip, deflate, sdch, br", forHTTPHeaderField: "Accept-Encoding")

        downloadSession = session?.dataTask(with: request)
        
        downloadSession?.resume()
    }
    
    override public func cancel() {
        downloadSession?.cancel()
        super.cancel()
    }
    
    //MARK
    private var lastP: Float = 0
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        totalReceived = totalReceived.advanced(by: data.count)
        downloadFileHandle?.write(data)
        
        guard expectedLength > 0 else {
            return
        }
        
        lastP = Float(totalReceived) / Float(expectedLength) * 100
        debounceProgress?()
    }
    
    private var downloadFileHandle : FileHandle?
    private var expectedLength: Int64 = 0
    private var totalReceived: Int64 = 0
    //MARK:
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("Did finish download \(downloadURL) with error \(String(describing: error))")
        downloadFileHandle?.closeFile()
        
        try? FileManager.default.moveItem(at: tempFile, to: expectedFilePath)
        completion?(error == nil ? expectedFilePath.path : nil, nil)
        
        downloadCompleted = true
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        expectedLength = response.expectedContentLength
        //completionHandler(.becomeDownload)
        try? FileManager.default.removeItem(at: tempFile)
        _ = FileManager.default.createFile(atPath: tempFile.path, contents: nil, attributes: nil)
        downloadFileHandle = FileHandle(forWritingAtPath: tempFile.path)
        completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        completionHandler(proposedResponse)
    }
    /*
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        try? FileManager.default.moveItem(at: location, to: tempFile)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
        
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else {
            return
        }
        
        let p = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite) * 100
        self.progress?(p)
    }*/
}
