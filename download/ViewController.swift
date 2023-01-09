//
//  ViewController.swift
//  download
//
//  Created by ToThang on 1/9/23.
//

import UIKit
import M3U8Kit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var playerView: UIView!
    let downloadManager = DownloadManager.share
    
    override func viewDidLoad() {
        super.viewDidLoad()
        downloadManager.deleagate = self
        
        var playerLayer = AVPlayerLayer(player: nil)
        playerView.layer.addSublayer(playerLayer)
        playerLayer.frame = self.playerView.bounds
        playerLayer.videoGravity = .resizeAspect
        
        var list =  UserDefaults.standard.array(forKey: "abc") as? [String] ?? []
        let playerItems = list.map(transformUrlToAsset)
        let playerQueue = AVQueuePlayer(items: playerItems)
        playerLayer.player = playerQueue
        
        playerQueue.play()
    }
    
    private func transformUrlToAsset(url: String) -> AVPlayerItem {
        let url = URL(string: url)
        let asset = AVAsset(url: url!)
        return AVPlayerItem(asset: asset)

    }
    
    @IBAction func downloadAction(_ sender: Any) {
        DownloadManager.share.downloadFile(m3u8_url: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8", indentify: "abc")
    }
}

extension ViewController: DownloadManagerDelegate {
    func didDownloadDone(fileName: String) {
        print("xxxxxx")
    }
}
