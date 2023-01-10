//
//  DownloadManager.swift
//  download
//
//  Created by ToThang on 1/9/23.
//

import Foundation
import M3U8Kit
import AVFoundation
import mobileffmpeg

protocol DownloadManagerDelegate: AnyObject {
    func didDownloadDone(url: URL)
}

protocol DownloadManagerInteface {
    func downloadFile(m3u8_url url: String, indentify: String)
    var deleagate: DownloadManagerDelegate? { get set }
}

class DownloadManager: DownloadManagerInteface {
    
    public static var share = DownloadManager()
    private init () {}
    
    weak var deleagate: DownloadManagerDelegate?
    let dispatchGroup = DispatchGroup()
    let documentsDirectoryURL = try? FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

    
    func downloadFile(m3u8_url url: String, indentify: String) {
        guard let listSegment = getSegmentList(url: url) else { return }
        var segementDownloaded = [URL]()
        for i in (0 ..< listSegment.count) {
            dispatchGroup.enter()
            let segment = listSegment.segmentInfo(at: i)
            let mediaUrl = segment?.mediaURL()
            if let mediaUrl = mediaUrl {
                download(url: mediaUrl, index: UInt(i), indentify: indentify) { path in
                    segementDownloaded.append(path)
                }
            }
        }
        dispatchGroup.wait()

        let destinationFile = documentsDirectoryURL?.appendingPathComponent("\(UUID.init().uuidString).mp4")
        mergeTs2Mp4(segementDownloadedUrl: segementDownloaded, destinationFile: destinationFile!)
        removeAllTsAfterDownload(urls: segementDownloaded)
        if let destinationFile = destinationFile {
            deleagate?.didDownloadDone(url: destinationFile)
        }
    }
    
    private func getSegmentList(url: String) -> M3U8SegmentInfoList? {
        let url = URL(string: url)
        do {
            let model = try M3U8PlaylistModel(url: url)
            if let streamList = model.masterPlaylist.xStreamList, streamList.count != 0 {
                let m3u8Url = streamList.xStreamInf(at: 0).m3u8URL()
                do {
                    guard let m3u8UrlAbsolute = m3u8Url?.absoluteString else { return nil }
                    let modelUrlTS = try M3U8PlaylistModel(url: URL(string: m3u8UrlAbsolute))
                    return modelUrlTS.mainMediaPl.segmentList
                }
            }
        } catch {
            print("User creation failed with error: \(error)")
        }
        return M3U8SegmentInfoList()
    }
    
    private func mergeTs2Mp4(segementDownloadedUrl: [URL], destinationFile: URL) {
        var command = "-i concat:"
        for fileUrl in segementDownloadedUrl {
            command += "\(fileUrl)" + "|"
        }
        let range = command.index(command.endIndex, offsetBy: -1)..<command.endIndex
        command.removeSubrange(range)
        command += " -codec copy \(destinationFile)"
        MobileFFmpeg.execute(command)
        print("===== Merge done =====")
    }
    
    private func removeAllTsAfterDownload(urls: [URL]) {
        for url in urls {
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    try FileManager.default.removeItem(at: url)
                } catch {
                    print("Could not delete file, probably read-only filesystem")
                }
            }
        }
    }
    
    private func download(url: URL, index: UInt, indentify: String, completion: @escaping (_ path: URL) -> Void) {
        let fileURL = documentsDirectoryURL?.appendingPathComponent(String(index) +  url.lastPathComponent)
        guard let fileURL = fileURL else { return }
        if FileManager.default.fileExists(atPath: fileURL.absoluteString) {
            dispatchGroup.leave()
            return
        }
        let downloadTask = URLSession.shared.downloadTask(with: url) { localURL, urlResponse, error in
            if let localURL = localURL {
                do {
                    try FileManager.default.moveItem(at: localURL, to: fileURL)
                    print("save done")
                    completion(fileURL)
                    self.dispatchGroup.leave()
                    return
                } catch let e {
                    print("save error \(e)")
                    self.dispatchGroup.leave()
                    return
                }
            }
        }
        downloadTask.resume()
    }
}
