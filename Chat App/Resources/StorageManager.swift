//
//  StorageManager.swift
//  Chat App
//
//  Created by KhoiLe on 02/09/2021.
//

import Foundation
import FirebaseStorage

final class storageManager {
    static let shared = storageManager()
    
    private let storage = Storage.storage().reference()
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    /// Upload picture to Firebase storage and return url string to download
    public func uploadFrofilePicture(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { metadata, error in
            guard error == nil else {
                print("Failed to upload profile picture")
                completion(.failure(storageError.failedToUpload))
                return
            }
            
            self.storage.child("images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url, error == nil else {
                    print("Failed to get download URL")
                    completion(.failure(storageError.failedToDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("Download URL returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    /// Upload image that will be sent in a conversation to Firebase storage and return url string to download
    public func uploadMessagePhoto(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("message_images/\(fileName)").putData(data, metadata: nil, completion: { metadata, error in
            guard error == nil else {
                print("Failed to upload conversation's picture")
                completion(.failure(storageError.failedToUpload))
                return
            }
            
            self.storage.child("message_images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url, error == nil else {
                    print("Failed to get download URL")
                    completion(.failure(storageError.failedToDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("Download URL returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    public enum storageError: Error {
        case failedToUpload
        case failedToDownloadURL
    }
    
    public func downloadUrl(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let reference = storage.child(path)
        
        reference.downloadURL(completion: { url, error in
            guard let url = url, error == nil else {
                completion(.failure(storageError.failedToDownloadURL))
                return
            }
            
            completion(.success(url))
        })
    }
}
