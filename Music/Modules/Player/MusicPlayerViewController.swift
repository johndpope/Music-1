//
//  MusicPlayerViewController.swift
//  Music
//
//  Created by Jack on 3/16/17.
//  Copyright © 2017 Jack. All rights reserved.
//

import UIKit

/// Music Player Status
enum MusicPlayerStatus {
    case playing
    case paused
    prefix public static func !(a: MusicPlayerStatus) -> MusicPlayerStatus {
        return a == .playing ? .paused : .playing
    }
}

class MusicPlayerViewController: MusicViewController, AudioPlayerDelegate {
    
    /// UI
    private let effectView: UIVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    private let backgroundImageView: UIImageView = UIImageView(image: #imageLiteral(resourceName: "background_default_dark-ip5"))
    private let maskBackgroundImageView: UIImageView = UIImageView(image: #imageLiteral(resourceName: "player_background_mask-ip5"))
    
    private let displayView: UIView = UIView()
    private let coverView: MusicPlayerCoverView = MusicPlayerCoverView()
    
    private let actionView: UIView = UIView()
    private let downloadButton: MusicPlayerDownloadButton = MusicPlayerDownloadButton(type: .custom)
    private let loveButton: MusicPlayerLoveButton = MusicPlayerLoveButton(type: .custom)
    
    private let progressView: UIView = UIView()
    private let currentTimeLabel: UILabel = UILabel()
    private let timeSlider: MusicPlayerSlider = MusicPlayerSlider()
    private let durationTimeLabel: UILabel = UILabel()
    
    private let controlView: UIView = UIView()
    private let playModeButton: MusicPlayerModeButton = MusicPlayerModeButton(type: .custom)
    private let lastButton: UIButton = UIButton(type: .custom)
    private let controlButton: MusicPlayerControlButton = MusicPlayerControlButton(type: .custom)
    private let nextButton: UIButton = UIButton(type: .custom)
    private let listButton: UIButton = UIButton(type: .custom)
    
    
    var isHiddenInput: Bool { return resource != nil }
    
    private var isUserInteraction: Bool = false
    private var player: AudioPlayer? = nil
    private var timer: Timer? = nil
    private var resource: MusicResource? = nil
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        currentTimeLabel.text = "00:00"
        durationTimeLabel.text = "00:00"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        
        musicNavigationBar.titleLabel.font = .font18
        
        //        addSwipGesture(target: self, action: #selector(left(sender:)), direction: .left)
        //        addSwipGesture(target: self, action: #selector(right(sender:)), direction: .right)
        
        view.addSubview(backgroundImageView)
        view.addSubview(effectView)
        
        super.viewDidLoad()
        
        displayView.addSubview(coverView)
        
        actionView.addSubview(loveButton)
        actionView.addSubview(downloadButton)
        
        progressView.addSubview(currentTimeLabel)
        progressView.addSubview(durationTimeLabel)
        progressView.addSubview(timeSlider)
        
        controlView.addSubview(playModeButton)
        controlView.addSubview(listButton)
        controlView.addSubview(lastButton)
        controlView.addSubview(controlButton)
        controlView.addSubview(nextButton)
        
        effectView.addSubview(maskBackgroundImageView)
        effectView.addSubview(displayView)
        effectView.addSubview(actionView)
        effectView.addSubview(progressView)
        effectView.addSubview(controlView)
        
        
        // - Background View
        
        backgroundImageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        effectView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        maskBackgroundImageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        // - Display View
        
        displayView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(90)
        }
        coverView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(225)
        }
        // - Action View
        
        loveButton.mode = .disable
        loveButton.addTarget(self, action: #selector(loveButtonClicked(_:)), for: .touchUpInside)
        
        downloadButton.mode = .disable
        downloadButton.addTarget(self, action: #selector(downloadButtonClicked(_:)), for: .touchUpInside)
        
        actionView.snp.makeConstraints { (make) in
            make.height.equalTo(50)
            make.left.right.equalToSuperview()
            make.top.equalTo(displayView.snp.bottom)
        }
        loveButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(15)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        downloadButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-15)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        // - Progress View
        
        currentTimeLabel.font = .font10
        currentTimeLabel.textColor = .white
        
        timeSlider.isEnabled = false
        timeSlider.minimumTrackTintColor = .white
        timeSlider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.1)
        timeSlider.setThumbImage(#imageLiteral(resourceName: "player_slider").scaleToSize(newSize: timeSlider.thumbImageSize), for: .normal)
        timeSlider.setThumbImage(#imageLiteral(resourceName: "player_slider_prs").scaleToSize(newSize: timeSlider.thumbImageSize), for: .highlighted)
        timeSlider.addTarget(self, action: #selector(timeSliderSeek(_:)), for: .touchUpInside)
        timeSlider.addTarget(self, action: #selector(timeSliderSeek(_:)), for: .touchUpOutside)
        timeSlider.addTarget(self, action: #selector(timeSliderValueChange(_:)), for: .valueChanged)
        
        durationTimeLabel.font = .font10
        durationTimeLabel.textColor = .white
        
        progressView.snp.makeConstraints { (make) in
            make.height.equalTo(36)
            make.left.right.equalToSuperview()
            make.top.equalTo(actionView.snp.bottom)
        }
        currentTimeLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
        }
        durationTimeLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
        }
        timeSlider.snp.makeConstraints { (make) in
            make.left.equalTo(currentTimeLabel.snp.right).offset(10)
            make.right.equalTo(durationTimeLabel.snp.left).offset(-10)
            make.centerY.equalToSuperview()
        }
        
        // - Control View
        
        controlButton.mode = .playing
        controlButton.addTarget(self, action: #selector(controlButtonClicked(_:)), for: .touchUpInside)
        
        playModeButton.setImage(#imageLiteral(resourceName: "player_control_model_order"), for: .normal)
        playModeButton.setImage(#imageLiteral(resourceName: "player_control_model_order_highlighted"), for: .highlighted)
        playModeButton.addTarget(self, action: #selector(playModeButtonClicked(_:)), for: .touchUpInside)
        
        lastButton.setImage(#imageLiteral(resourceName: "player_control_last"), for: .normal)
        lastButton.setImage(#imageLiteral(resourceName: "player_control_last_press"), for: .highlighted)
        lastButton.addTarget(self, action: #selector(lastButtonClicked(_:)), for: .touchUpInside)
        
        nextButton.setImage(#imageLiteral(resourceName: "player_control_next"), for: .normal)
        nextButton.setImage(#imageLiteral(resourceName: "player_control_next_press"), for: .highlighted)
        nextButton.addTarget(self, action: #selector(nextButtonClicked(_:)), for: .touchUpInside)
        
        listButton.setImage(#imageLiteral(resourceName: "player_control_list"), for: .normal)
        listButton.setImage(#imageLiteral(resourceName: "player_control_list_press"), for: .highlighted)
        listButton.addTarget(self, action: #selector(listButtonClicked(_:)), for: .touchUpInside)
        
        controlView.snp.makeConstraints { (make) in
            make.height.equalTo(54)
            make.left.right.equalToSuperview()
            make.top.equalTo(progressView.snp.bottom)
            make.bottom.equalToSuperview().offset(-20)
        }
        controlButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(54)
            make.center.equalToSuperview()
        }
        lastButton.snp.makeConstraints { (make) in
            make.right.equalTo(controlButton.snp.left).offset(-15)
            make.width.height.equalTo(40)
            make.centerY.equalToSuperview()
        }
        nextButton.snp.makeConstraints { (make) in
            make.left.equalTo(controlButton.snp.right).offset(15)
            make.width.height.equalTo(40)
            make.centerY.equalToSuperview()
        }
        playModeButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(10)
            make.width.height.equalTo(50)
            make.centerY.equalToSuperview()
        }
        listButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-10)
            make.width.height.equalTo(50)
            make.centerY.equalToSuperview()
        }
    }
    
    func play(withResource resource: MusicResource) {
        
        reset()

        self.resource = resource
        
        title = resource.name
        backgroundImageView.kf.setImage(with: resource.album?.picUrl,
                                        placeholder: backgroundImageView.image ?? #imageLiteral(resourceName: "background_default_dark-ip5"),
                                        options: [.forceTransition,
                                                  .transition(.fade(1))])

        coverView.setImage(url: resource.album?.picUrl)
        
        let rawDuration = resource.duration / 1000
        durationTimeLabel.text = rawDuration.musicTime
        timeSlider.maximumValue = rawDuration.float
        
//        downloadButton.mode = .disable//resource.resourceSource == .downloaded ? .downloaded : .disable
        
        MusicResourceManager.default.register(resource.id, responseBlock: {
            self.player?.respond(with: $0)
        }, progressBlock: {
            self.timeSlider.buffProgress($0)
        }, resourceBlock: { (resource) in
            self.resource = resource
        })
    }
    
    private func reset() {
        player?.stop()
        player = nil
        
        destoryTimer()
        
        player = AudioPlayer()
        player?.delegate = self
        
        createTimer()
        
        timeSlider.resetProgress()
        
        MusicResourceManager.default.unRegister(resource?.id ?? "No Resource")
    }
    
    private func createTimer() {
        timer = Timer(timeInterval: 0.1, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .commonModes)
    }
    
    private func destoryTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func refresh() {
        guard !isUserInteraction,
            let currentTime = player?.currentTime else { return }
        currentTimeLabel.text = currentTime.musicTime
        timeSlider.value = currentTime.float
    }
    
    //MARK: - Progress Target
    
    @objc private func timeSliderValueChange(_ sender: MusicPlayerSlider) {
        isUserInteraction = true
        currentTimeLabel.text = TimeInterval(sender.value).musicTime
    }
    
    @objc private func timeSliderSeek(_ sender: MusicPlayerSlider) {
        isUserInteraction = false
        if player?.seek(toTime: TimeInterval(sender.value)) == true {
            player?.play()
            ConsoleLog.verbose("timeSliderSeek to time: " + "\(sender.value)")
        } else {
            destoryTimer()
            timeSlider.loading(true)
            ConsoleLog.verbose("timeSliderSeek to time: " + "\(sender.value)" + " but need to watting")
        }
    }
    
    //MARK: - Action Target
    
    @objc private func loveButtonClicked(_ sender: MusicPlayerLoveButton) {
//        guard let id = resourceId else { return }
//        MusicNetwork.default.request(API.default.like(musicID: id, isLike: sender.mode == .love), success: {
//            if $0.isSuccess { sender.mode = !sender.mode }
//        })
    }
    
    @objc private func downloadButtonClicked(_ sender: MusicPlayerDownloadButton) {
//        MusicResourceManager.default
    }
    
    //MARK: - Control Target
    
    @objc private func playModeButtonClicked(_ sender: MusicPlayerModeButton) {
        sender.changePlayMode()
        MusicResourceManager.default.resourceLoadMode = sender.mode
    }
    
    @objc private func controlButtonClicked(_ sender: MusicPlayerControlButton) {
        
        guard let player = player else { return }
        
        if sender.mode == .playing { player.play() }
        else { player.pause() }
        sender.mode = !sender.mode
    }
    
    @objc private func lastButtonClicked(_ sender: UIButton) {
        play(withResource: MusicResourceManager.default.last())
    }
    
    @objc private func nextButtonClicked(_ sender: UIButton) {
        play(withResource: MusicResourceManager.default.next())
    }
    
    @objc private func listButtonClicked(_ sender: UIButton) {
        
    }
    
    //MARK: - StreamAudioPlayerDelegate
    func streamAudioPlayerCompletedParsedAudioInfo(_ player: AudioPlayer) {
        ConsoleLog.verbose("streamAudioPlayerCompletedParsedAudioInfo")
        DispatchQueue.main.async {
            self.timeSlider.isEnabled = true
        }
    }
    
    func streamAudioPlayer(_ player: AudioPlayer, didCompletedSeekToTime time: TimeInterval) {
        ConsoleLog.verbose("didCompletedSeekToTime: " + "\(time)")
        DispatchQueue.main.async {
            self.timeSlider.loading(false)
            guard self.controlButton.mode == .paused else { return }
            self.createTimer()
            self.player?.play()
        }
    }
    
    func streamAudioPlayer(_ player: AudioPlayer, queueStatusChange status: AudioQueueStatus) {
        switch status {
        case .playing: controlButton.mode = .paused
        case .paused: controlButton.mode = .playing
        case .stop: controlButton.mode = .playing
        }
    }
    func streamAudioPlayer(_ player: AudioPlayer, anErrorOccur error: WaveError) {
        ConsoleLog.error(error)
    }
//    func streamAudioPlayer(_ player: AudioPlayer, parsedDuration duration: TimeInterval?) {
//        DispatchQueue.main.async {
//            self.timeSlider.isEnabled = true
//            self.resource?.duration = duration
//            self.timeSlider.maximumValue = duration.float
//            self.durationTimeLabel.text = duration.musicTime
//        }
//    }
    
//    func streamAudioPlayer(_ player: AudioPlayer, queueStatusChange isRunning: Bool) {
//        ConsoleLog.verbose("Queue Status Change: isRunning-" + isRunning.description)
//    }
//    func didCompletedPlayAudio(_ player: AudioPlayer) {
//        nextButtonClicked(nextButton)
//    }
}
