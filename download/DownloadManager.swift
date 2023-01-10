//
//  DownloadManager.swift
//  download
//
//  Created by ToThang on 1/9/23.
//

import Foundation
import M3U8Kit
import AVFoundation

protocol DownloadManagerDelegate: AnyObject {
    func didDownloadDone(fileName: String)
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
    
    func downloadFile(m3u8_url url: String, indentify: String) {
        guard let listSegment = getSegmentList(url: url) else { return }
        var segementDownloaded = [String]()
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
        UserDefaults.standard.set(segementDownloaded, forKey: indentify)
        deleagate?.didDownloadDone(fileName: "fileName")
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
    
    private func mergeTs2Mp4(segementDownloadedUrl: [String]) {
        // Create an empty mutable composition
        let composition = AVMutableComposition()
        
        // Create a video track to hold the video assets
        let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        // Create an audio track to hold the audio assets
        let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        // TODO: maintaince for ios16
        // Add the video and audio assets to the tracks
        for tsFileURL in segementDownloadedUrl {
            let asset = AVURLAsset(url: URL(string: tsFileURL)!)
            let videoAssetTrack = asset.tracks(withMediaType: .video).first
            let audioAssetTrack = asset.tracks(withMediaType: .audio).first
            try! videoTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: asset.duration), of: videoAssetTrack!, at: CMTime.zero)
            try! audioTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: asset.duration), of: audioAssetTrack!, at: CMTime.zero)
        }

        // Create an export session for the composition
        let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)!

        // Output mov
        let documentsDirectoryURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let movFileURL = documentsDirectoryURL?.appendingPathComponent("test.mov")

        // Set the output file type and URL
        exportSession.outputFileType = .mov
        exportSession.outputURL = movFileURL

        // Export the composition to a new file
        exportSession.exportAsynchronously {
            // Check for success and handle any errors
            if exportSession.status == .completed {
                print("Successfully exported to: \(movFileURL)")
            } else {
                print("Export failed with error: \(exportSession.error?.localizedDescription ?? "Unknown Error")")
            }
        }

    }
    
    private func download(url: URL, index: UInt, indentify: String, completion: @escaping (_ path: String) -> Void) {
        let documentsDirectoryURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
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
                    completion(fileURL.absoluteString)
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
