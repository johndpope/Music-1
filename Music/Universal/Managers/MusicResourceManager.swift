//
//  MusicResourceManager.swift
//  Music
//
//  Created by Jack on 5/6/17.
//  Copyright © 2017 Jack. All rights reserved.
//

import Foundation

typealias MusicResourceIdentifier = String

typealias MusicResourceCollection = [MusicResourceIdentifier: MusicResource]

/// Music Resource
struct MusicResource: JSONInitable {
    
    /// Source of Resource
    ///
    /// - cache: Cache
    /// - download: Download
    /// - network: Network
    enum ResourceSource {
        case cache
        case download
        case network
    }
    
    let id: String
    var name: String = ""
    var md5: String? = nil
    var resourceSource: ResourceSource = .network
    var musicUrl: URL? = nil
    var lyric: String? = nil
    var picUrl: URL? = nil
    
    init(id: String) {
        self.id = id
    }
    
    init(_ json: JSON) {
        id = json["id"].string ?? { assertionFailure("Error Music Id"); return "Error Id" }()
        md5 = json["md5"].string
        name = json["name"].stringValue
        picUrl = json["picUrl"].url
        lyric = json["lyric"].string
    }
    
    var codeing: String {
        var code: [String: String] = ["id": id, "md5": md5 ?? { assertionFailure("Codeing with MD5 Error"); return "Error MD5" }()]
        code["lyric"] = lyric
        code["picUrl"] = picUrl?.absoluteString
        code["name"] = name
        
        return JSON(code).rawString([.jsonSerialization: true]) ?? ""
    }
}

class MusicResourceManager {
    
    static let `default` = MusicResourceManager()
    
    var resourceLoadMode: MusicPlayerPlayMode = .order
    
    private var resources: [MusicResource] = []
    private var resourcesIndexs: [Int] = []
    private var currentResourceIndex: Int = 0
    private var cachedResourceList: MusicResourceCollection = [:]
    private var downloadedResouceList: MusicResourceCollection = [:]
    
    private init() {
        DispatchQueue.global().async {
            self.cachedResourceList = MusicFileManager.default.search(fromURL: MusicFileManager.default.musicCacheURL)
            self.downloadedResouceList = MusicFileManager.default.search(fromURL: MusicFileManager.default.musicDownloadURL)
        }
    }
    
    /// Rest Resources
    ///
    /// - Parameters:
    ///   - resources: Collection for MusicResourceIdentifier
    ///   - resourceIndex: Begin music resource index
    ///   - mode: MusicPlayerPlayMode
    func reset(_ resources: [MusicResource],
               resourceIndex: Int,
               withMode mode: MusicPlayerPlayMode? = nil) {
        
        if let mode = mode { self.resourceLoadMode = mode }
        self.resources = resources
        self.resourcesIndexs = uniqueRandom(0...resources.count - 1)
        self.currentResourceIndex = resourceIndex
    }
    
    /// Get Current MusicResourceIdentifier
    ///
    /// - Returns: MusicResourceIdentifier
    func current() -> MusicResourceIdentifier {
        return resources[currentResourceIndex].id
    }
    
    /// Last MusicResourceIdentifier
    ///
    /// - Returns: MusicResourceIdentifier
    func last() -> MusicResourceIdentifier {
        if currentResourceIndex == 0 { currentResourceIndex = resources.count - 1 }
        else { currentResourceIndex -= 1 }
        return resources[currentResourceIndex].id
    }
    
    /// Next MusicResourceIdentifier
    ///
    /// - Returns: MusicResourceIdentifier
    func next() -> MusicResourceIdentifier {
        currentResourceIndex = (currentResourceIndex + 1) % resources.count
        return resources[currentResourceIndex].id
    }
    
    /// Request Music by resource id
    ///
    /// - Parameters:
    ///   - resourceId: Resource id
    ///   - response: MusicPlayerResponse
    func request(_ resourceId: String,
                 responseBlock: ((Data) -> ())? = nil,
                 progressBlock: ((Progress) -> ())? = nil,
                 resourceBlock: ((MusicResource) -> ())? = nil,
                 failedBlock: ((Error) -> ())? = nil) {
        
        DispatchQueue.global().async {
            
            guard let index = self.resources.index(where: { $0.id == resourceId }) else { failedBlock?(MusicError.resourcesError(.noResource)); return }
            let originResource = self.resources[index]
            guard let musicUrl = originResource.musicUrl else { failedBlock?(MusicError.resourcesError(.invalidURL)); return }
            
            var data: Data?
            let group = DispatchGroup()
            let queue = DispatchQueue(label: "com.xwjack.music.musicResourceManager.request",
                                      qos: .background,
                                      attributes: .concurrent,
                                      target: .global())
            
            //Reading Music Data
            if originResource.resourceSource == .network {
                
                group.enter()
                // Request Music Source
                MusicNetwork.default.request(musicUrl,
                                             response: MusicResponse(responseData: responseBlock,
                                                                     progress: progressBlock,
                                                                     response: {
                                                                        group.leave()
                                             }, success: {
                                                data = $0
                                             }, failed: failedBlock))
                
            } else {
                
                //Reading Music File
                guard let data = try? FileHandle(forReadingFrom: musicUrl).readDataToEndOfFile() else { failedBlock?(MusicError.resourcesError(.invalidData)); return  }
                let progress = Progress(totalUnitCount: Int64(data.count))
                progress.completedUnitCount = Int64(data.count)
                
                responseBlock?(data)
                progressBlock?(progress)
            }
            
            //Request Lyric
            if originResource.lyric == nil {
                group.enter()
                
                MusicNetwork.default.request(MusicAPI.default.lyric(musicID: originResource.id), response: { (_, _, _) in
                    group.leave()
                }, success: {
                    guard let lyric = $0["lrc"]["lyric"].string else { return }
                    self.resources[index].lyric = lyric
                }, failed: failedBlock)
            }
            
            //        if originResource.
            
            // Reading Music Lyric
            //        guard let infoData = try? FileHandle(forReadingFrom: musicUrl.appendingPathExtension("info")).readDataToEndOfFile() else { failedBlock?(MusicError.resourcesError(.invalidInfo)); return }
            //        let resource = MusicResource(JSON(data: infoData))
            //        response?.lyric.success?(resource.lyric ?? "Empty Lyric")
            
            //        group.enter()
            //        // Request Music Lyric
            //        MusicNetwork.default.request(MusicAPI.default.lyric(musicID: resourceID), success: {
            //
            //            let lyricModel = MusicLyricModel($0)
            //            self.resources[index].lyric = lyricModel.lyric
            //            response?.lyric.success?(lyricModel.lyric)
            //            group.leave()
            //        }, failed: {
            //            print($0)
            //            group.leave()
            //        })
            //
            
            group.notify(queue: queue, execute: {
                guard let validData = data else { return }
                self.cache(&self.resources[index], data: validData)
            })
        }
    }
    
//    func download(_ resourceId: MusicResourceIdentifier, response: MusicResponse? = nil) {
//        guard let index = resources.index(where: { $0.id == resourceId }) else { response?.failed?(MusicError.resourcesError(.noResource)); return }
//        let resource = resources[index]
//        //TODO:
//    }
    
    private func cache(_ resource: inout MusicResource, data: Data) {
        resource.resourceSource = .cache
        resource.md5 = resource.id.md5()
        
        guard let md5 = resource.md5 else { assertionFailure("MD5 error for resource"); return }
        do {
            try data.write(to: MusicFileManager.default.musicCacheURL.appendingPathComponent(md5))
            try resource.codeing.write(toFile: MusicFileManager.default.musicCacheURL.appendingPathComponent(md5 + ".info").path, atomically: true, encoding: .utf8)
            cachedResourceList[resource.id] = resource
        } catch {
            print(error)
        }
        
    }
    
    private func save(_ resource: MusicResource) {
        var resource = resource
//        resource.isCached = false
//        resource.isDownload = true
        resource.md5 = resource.id.md5()
    }
    
    private func uniqueRandom(_ range: ClosedRange<Int>) -> [Int] {
        var result: [Int] = Array(range.lowerBound...range.upperBound)
        result.reserveCapacity(range.count)
        var i = range.count
        result.forEach{ _ in
            let index = Int(arc4random_uniform(UInt32(i)))
            (result[i - 1], result[index]) = (result[index], result[i - 1])
            i -= 1
        }
        return result
    }
}
