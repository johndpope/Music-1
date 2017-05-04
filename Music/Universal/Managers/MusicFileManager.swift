//
//  MusicFileManager.swift
//  Music
//
//  Created by Jack on 3/16/17.
//  Copyright © 2017 Jack. All rights reserved.
//

import Foundation

final class MusicFileManager {
    
    static let `default` = MusicFileManager()
    
    private let fileManager = FileManager.default
    private let ioQueue: DispatchQueue
    
    let musicCacheURL: URL
    let musicDownloadURL: URL
    let libraryURL: URL
    
    private init() {
        libraryURL = try! fileManager.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        musicCacheURL = libraryURL.appendingPathComponent("Music/Cache/")
        musicDownloadURL = libraryURL.appendingPathComponent("Music/Download/")
        ioQueue = DispatchQueue(label: "com.xwjack.music.fileManager")
        createMusicCacheDirectory()
        createMusicDownloadDirectory()
    }
    
    func clearCache(_ completed: @escaping () -> ()) {
        
        ioQueue.async {
            self.clear(self.musicCacheURL)
            self.clear(self.musicDownloadURL)
            self.createMusicCacheDirectory()
            DispatchQueue.main.async {
                completed()
            }
        }
    }
    
    func calculateCache(_ completed: @escaping (UInt) -> ()) {
        
        func calculateFileSize(in url: URL) -> UInt {
            let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey, .totalFileAllocatedSizeKey]
            var diskCacheSize: UInt = 0
            
            guard let fileEnumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: Array(resourceKeys), options: .skipsHiddenFiles, errorHandler: nil),
                let urls = fileEnumerator.allObjects as? [URL] else {
                    return diskCacheSize
            }
            
            for fileUrl in urls {
                
                do {
                    let resourceValues = try fileUrl.resourceValues(forKeys: resourceKeys)
                    // If it is a Directory. Continue to next file URL.
                    if resourceValues.isDirectory == true {
                        continue
                    }
                    
                    if let fileSize = resourceValues.totalFileAllocatedSize {
                        diskCacheSize += UInt(fileSize)
                    }
                } catch _ { }
            }
            
            return diskCacheSize
        }
        
        ioQueue.async {
            
            let musicCacheSize = calculateFileSize(in: self.musicCacheURL)
            let musicDownloadSize = calculateFileSize(in: self.musicDownloadURL)
                
            DispatchQueue.main.async {
                completed(musicCacheSize + musicDownloadSize)
            }
        }
    }
    
    private func clear(_ url: URL) {
        /// 删除音乐缓存目录
        if fileManager.fileExists(atPath: url.path) {
            try? fileManager.removeItem(at: url)
        }
    }
    
    private func createMusicCacheDirectory() {
        /// 创建音乐缓存目录
        if !fileManager.fileExists(atPath: musicCacheURL.path) {
            try? fileManager.createDirectory(at: musicCacheURL, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    private func createMusicDownloadDirectory() {
        /// 创建音乐下载目录
        if !fileManager.fileExists(atPath: musicDownloadURL.path) {
            try? fileManager.createDirectory(at: musicDownloadURL, withIntermediateDirectories: true, attributes: nil)
        }
    }
}
