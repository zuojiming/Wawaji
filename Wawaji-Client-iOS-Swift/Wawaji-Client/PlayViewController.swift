//
//  PlayViewController.swift
//  AgoraWawaji
//
//  Created by suleyu on 2017/11/22.
//  Copyright © 2017 Agora. All rights reserved.
//

import UIKit
import AVFoundation
import AgoraRtcEngineKit

class PlayViewController: UIViewController {
    let wawajiManufacturer = WawajiManufacturer.LeiDi
    
    public var player : Bool!
    public var channel : String!
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var controlView: UIView!
    
    var musicPlayer : AVAudioPlayer?
    var effectPlayer : AVAudioPlayer?
    
    var wawajiController : WawajiController?
    var mediaEngine : AgoraRtcEngineKit!
    var allStreamUids = [UInt]()
    var currentStreamUid : UInt = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = channel
        // Do any additional setup after loading the view.
        
        playMusic()
        loadMediaEngine();
        
        if player {
            wawajiController = WawajiControllerCreator.getWawajiController(manufacturer: wawajiManufacturer)
            wawajiController!.initialize()
            wawajiController!.fetchResult = { [weak self] result in
                var effectFileName : String
                if (result) {
                    self?.showAlert(NSLocalizedString("FetchSuccess", comment: ""))
                    effectFileName = "success"
                }
                else {
                    self?.showAlert(NSLocalizedString("FetchFailed", comment: ""))
                    effectFileName = "failed"
                }
                
                if self?.effectPlayer != nil {
                    self?.effectPlayer!.stop()
                }
                let url = Bundle.main.url(forResource: effectFileName, withExtension: "mp3")
                self?.effectPlayer = try! AVAudioPlayer(contentsOf: url!)
                self?.effectPlayer!.play()
            }
        }
        else {
            controlView.removeFromSuperview()
        }
    }
    
    func playMusic() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: [.defaultToSpeaker])
            try audioSession.setActive(true)
            try audioSession.setMode(AVAudioSessionModeVideoChat)
            
            let url = Bundle.main.url(forResource: "music", withExtension: "mp3")
            musicPlayer = try AVAudioPlayer(contentsOf: url!)
            musicPlayer?.numberOfLoops = -1;
            musicPlayer?.play()
        }
        catch {
            print("\(error)")
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = false
        mediaEngine.leaveChannel(nil)
        mediaEngine = nil
        wawajiController = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func leave(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func switchCamera(_ sender: Any) {
        guard allStreamUids.count > 1 else {
            showAlert(NSLocalizedString("NoMoreCamera", comment: ""))
            return
        }
        
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = currentStreamUid;
        videoCanvas.view = nil;
        mediaEngine.setupRemoteVideo(videoCanvas)

        var index = allStreamUids.index(of: currentStreamUid)!
        if index == allStreamUids.count - 1 {
            index = 0
        }
        else {
            index += 1
        }
        currentStreamUid = allStreamUids[index]
        
        let newVideoCanvas = AgoraRtcVideoCanvas()
        newVideoCanvas.uid = currentStreamUid;
        newVideoCanvas.view = videoView;
        newVideoCanvas.renderMode = .render_Hidden;
        mediaEngine.setupRemoteVideo(newVideoCanvas)
    }
    
    @IBAction func cion(_ sender: Any) {
        if effectPlayer != nil {
            effectPlayer!.stop()
        }
        let url = Bundle.main.url(forResource: "start", withExtension: "m4a")
        effectPlayer = try! AVAudioPlayer(contentsOf: url!)
        effectPlayer!.play()
        
        wawajiController?.insertCion()
    }
    
    @IBAction func startMoveUp(_ sender: Any) {
        if wawajiController?.startMoveUp() == false {
            showAlert(NSLocalizedString("PleaseInsertCion", comment: ""));
        }
    }
    
    @IBAction func stopMoveUp(_ sender: Any) {
        _ = wawajiController?.stopMoveUp()
    }
    
    @IBAction func startMoveDown(_ sender: Any) {
        if wawajiController?.startMoveDown() == false {
            showAlert(NSLocalizedString("PleaseInsertCion", comment: ""));
        }
    }
    
    @IBAction func stopMoveDown(_ sender: Any) {
        _ = wawajiController?.stopMoveDown()
    }
    
    @IBAction func startMoveLeft(_ sender: Any) {
        if wawajiController?.startMoveLeft() == false {
            showAlert(NSLocalizedString("PleaseInsertCion", comment: ""));
        }
    }
    
    @IBAction func stopMoveLeft(_ sender: Any) {
        _ = wawajiController?.stopMoveLeft()
    }
    
    @IBAction func startMoveRight(_ sender: Any) {
        if wawajiController?.startMoveRight() == false {
            showAlert(NSLocalizedString("PleaseInsertCion", comment: ""));
        }
    }
    
    @IBAction func stopMoveRight(_ sender: Any) {
        _ = wawajiController?.stopMoveRight()
    }
    
    @IBAction func fetch(_ sender: Any) {
        if wawajiController?.fetch() == false {
            showAlert(NSLocalizedString("PleaseInsertCion", comment: ""));
        }
    }
    
    func loadMediaEngine() {
        mediaEngine = AgoraRtcEngineKit.sharedEngine(withAppId: KeyCenter.appID, delegate: self)
        mediaEngine.setChannelProfile(.channelProfile_LiveBroadcasting);
        mediaEngine.setClientRole(.clientRole_Broadcaster, withKey: nil)
        mediaEngine.enableVideo();
        mediaEngine.enableLocalVideo(false);
        mediaEngine.disableAudio()
        mediaEngine.setParameters("{\"che.audio.external_device\": true}");
        
        let result = mediaEngine.joinChannel(byKey: nil, channelName: channel, info: nil, uid: 0, joinSuccess: nil)
        if result == 0 {
            UIApplication.shared.isIdleTimerDisabled = true;
        }
        else {
            print("joinChannel failed: \(result)")
            showAlert(NSLocalizedString("JoinChannelFailed", comment: "")) {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func showAlert(_ message: String, completion: (() -> Swift.Void)? = nil) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { action in
            if let completion = completion {
                completion()
            }
        }
        
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
}

extension PlayViewController : AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraRtcErrorCode) {
        print("rtcEngine:didOccurError: \(errorCode)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        print("rtcEngine:didJoinChannel: \(channel)")
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("rtcEngine:didJoinedOfUid: \(uid)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoDecodedOfUid uid: UInt, size: CGSize, elapsed: Int) {
        print("rtcEngine:firstRemoteVideoDecodedOfUid: \(uid)")
        if allStreamUids.contains(uid) {
            return
        }
        
        allStreamUids.append(uid)
        if currentStreamUid == 0 {
            currentStreamUid = uid
            
            let videoCanvas = AgoraRtcVideoCanvas()
            videoCanvas.uid = currentStreamUid;
            videoCanvas.view = videoView;
            videoCanvas.renderMode = .render_Hidden;
            mediaEngine.setupRemoteVideo(videoCanvas)
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraRtcUserOfflineReason) {
        print("rtcEngine:didOfflineOfUid: \(uid)")
    }
}

