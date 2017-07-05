//
//  FileProviderService.swift
//  cacom.info
//
//  Created by Nguyen Tuan on 5/12/17.
//  Copyright © 2017 helo. All rights reserved.
//

import UIKit

class FileProviderService {
    private class FileProviderTask: Hashable, Equatable {
        typealias ImageObject = (imageView: UIImageView, defaultImage: UIImage?)
        var keyObject: [ImageObject]
        var key: String
        var discardable = false
        
        init(object o: ImageObject, key k: String) {
            keyObject = [ImageObject]()
            keyObject.append(o)
            key = k
        }
        
        var hashValue: Int {
            get {
                return keyObject.reduce(0, {$0 & $1.imageView.hashValue}) & key.hashValue
            }
        }
        
        func index(of imageView: UIImageView) -> Int? {
            return keyObject.index(where: {$0.imageView == imageView})
        }
        
        func equal(objects: [ImageObject]) -> Bool {
            guard keyObject.count == objects.count else {
                return false
            }
            
            for i in 0..<keyObject.count {
                let mine = keyObject[i]
                let other = objects[i]
                if mine.imageView != other.imageView {
                    return false
                }
            }
            
            return true
        }
        
        func contains(imageView: UIImageView) -> Bool {
            return keyObject.first(where: {$0.imageView == imageView}) != nil
        }
        
        public static func ==(lhs: FileProviderTask, rhs: FileProviderTask) -> Bool {
            return lhs.equal(objects: rhs.keyObject) && lhs.key == rhs.key
        }
    }
    private var networkProvider : FileProviderNetwork
    private var imageCache = NSCache<NSString, UIImage>()
    
    public init() {
        networkProvider = FileProviderNetwork()
    }
    
    func upload(filePath : String, destination: (url:String, name: String), completion:@escaping (Bool) ->()) {
        guard FileManager.default.fileExists(atPath: filePath) else {
            completion(false)
            return
        }
        
        guard let destinationURL = URL(string: destination.url) else {
            completion(false)
            return
        }
        
        networkProvider.startUploadFile(filePath: URL(fileURLWithPath: filePath), toURL: destinationURL, given: destination.name, progress: nil, completion: { (result, e) in
            completion(e == nil)
        })
    }
    
    func upload(image: UIImage, destination: (url:String, name: String), completion:@escaping (Bool) ->()) {
        guard let imageData = UIImageJPEGRepresentation(image, 0.8) else {
            completion(false)
            return
        }
        
        guard let destinationURL = URL(string: destination.url) else {
            completion(false)
            return
        }
        
        networkProvider.startUpload(data: imageData, toURL: destinationURL, given: destination.name, progress: nil, completion: { (name, error) in
            completion(error == nil)
        })
    }
    
    private func getImage(baseURL: URL, completion: @escaping (UIImage?) -> ()) {
        let urlString = baseURL.absoluteString as NSString
        
        if let cachedImage = imageCache.object(forKey: urlString) {
            completion(cachedImage)
        }else {
            let task = networkProvider.downloadFile(fromURL: baseURL, destinationPath: nil, progress: nil, completion: { (filePath, error) in
                if let imagePath = filePath, let image = UIImage(contentsOfFile: imagePath) {
                    completion(image)
                    self.imageCache.setObject(image, forKey: urlString)
                }else {
                    completion(nil)
                }
            })
            task.useDefaulSession = true
        }
    }
    
    private var pendingFileTasks: Set<FileProviderTask> = Set()
    private var discardableImageQuestQueue: Set<UIImageView> = Set()
    
    private func findTask(byObject object: UIImageView) -> FileProviderTask? {
        var task: FileProviderTask?
        sync(lock: pendingFileTasks as NSObject) {
            task = pendingFileTasks.first(where: { (t) -> Bool in
                return t.contains(imageView: object)
            })
        }
        return task
    }
    
    private func findTask(byKey key: String) -> FileProviderTask? {
        var task: FileProviderTask?
        sync(lock: pendingFileTasks as NSObject) {
            task = pendingFileTasks.first(where: {$0.key == key})
        }
        
        return task
    }
    
    //MARK: -- API
    func imageView(_ imageView: UIImageView, loadImage imgURL: URL?, defaultImage: UIImage? = nil) -> () {
        guard let url = imgURL else {
            imageView.image = defaultImage
            return
        }
        let task = FileProviderTask(object: FileProviderTask.ImageObject(imageView: imageView, defaultImage: defaultImage), key: url.absoluteString)
        
        if let discard = findTask(byObject: imageView) {
            if discard.key != url.absoluteString {
                if let index = discard.index(of: imageView) {
                    sync(lock: discard.keyObject as NSObject, closure: { 
                        discard.keyObject.remove(at: index)
                    })
                }
            }else {
                //should replace it by default image
                imageView.image = defaultImage
                return
            }
        }
        if let discard = findTask(byKey: url.absoluteString) {
            sync(lock: discard.keyObject as NSObject, closure: {
                discard.keyObject.append(FileProviderTask.ImageObject(imageView: imageView, defaultImage: defaultImage))
            })
            imageView.image = defaultImage
            return
        }
        
        sync(lock: pendingFileTasks as NSObject) { 
            pendingFileTasks.insert(task)
        }
        
        imageView.image = defaultImage
        getImage(baseURL: url) { (image) in
            if let discard = self.findTask(byKey: url.absoluteString) {
                for object in discard.keyObject {
//                    NSLog("Start update UI \(view) for url \(url)")
                    object.imageView.image = image ?? object.defaultImage
                    object.imageView.setNeedsDisplay()
                }
                
                sync(lock: self.pendingFileTasks as NSObject) {
                    self.pendingFileTasks.subtract([discard])
                }
            }
        }
    }
    
    // MARK: local file
    private func putFile(data: Data, for key: String, with type: FileCacheType) {
        if type == .image {
            let fileName = "\(key).png"
            let dir = FileProviderCache.imageCacheDirectory()
            let fileURL = dir.appendingPathComponent(fileName)
            try? data.write(to: fileURL)
        }
    }
    
    func putImage(image: UIImage, for key: String) {
        if let imgData = UIImagePNGRepresentation(image) {
            putFile(data: imgData, for: key, with: .image)
        }
    }
    
    private func loadFile(key: String, with type: FileCacheType) -> Data? {
        if type == .image {
            let fileName = "\(key).png"
            let dir = FileProviderCache.imageCacheDirectory()
            let fileURL = dir.appendingPathComponent(fileName)
            return try? Data(contentsOf: fileURL)
        }
        return nil
    }
    
    func loadImage(key: String) -> UIImage? {
        if let data = loadFile(key: key, with: .image) {
            return UIImage(data: data)
        }
        
        return nil
    }
    
    private func removeFile(key: String, with type: FileCacheType) {
        if type == .image {
            let fileName = "\(key).png"
            let dir = FileProviderCache.imageCacheDirectory()
            let fileURL = dir.appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
    
    func removeImage(key: String) {
        removeFile(key: key, with: .image)
    }
}

extension FileProviderService {
    static let service: FileProviderService = FileProviderService()
}

