//
//  ViewController.swift
//  PlayThatSong
//
//  Created by Scott Taylor on 28/04/2015.
//  Copyright (c) 2015 Carnaby Labs. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var currentSongLabel: UILabel!
    
    var audioSession: AVAudioSession!
    //    var audioPlayer: AVAudioPlayer!
    var audioQueuePlayer: AVQueuePlayer!
    var currentSongIndex:Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureAudioSession()
        //        self.configureAudioPlayer()
        self.configureAudioQueuePlayer()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handleRequest:"), name: "WatchKitDidMakeRequest", object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Mark: - IBActions
    
    @IBAction func playButtonPressed(sender: UIButton) {
        self.playMusic()
        self.updateUI()
        
    }
    @IBAction func playPreviousButtonPressed(sender: UIButton) {
        if currentSongIndex > 0 {
            self.audioQueuePlayer.pause()
            self.audioQueuePlayer.seekToTime(kCMTimeZero, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
            let temporaryNowPlayIndex = currentSongIndex
            let temporaryPlayList = self.createSongs()
            self.audioQueuePlayer.removeAllItems()
            for var index = temporaryNowPlayIndex - 1; index < temporaryPlayList.count; index++ {
                self.audioQueuePlayer.insertItem(temporaryPlayList[index] as! AVPlayerItem, afterItem: nil)
            }
            self.currentSongIndex = temporaryNowPlayIndex - 1
            self.audioQueuePlayer.seekToTime(kCMTimeZero, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
            self.audioQueuePlayer.play()
        }
        self.updateUI()
    }
    
    @IBAction func playNextButtonPressed(sender: UIButton) {
        self.audioQueuePlayer.advanceToNextItem()
        self.currentSongIndex = self.currentSongIndex + 1
        self.updateUI()
        
    }
    
    //Mark: - Audio
    
    func configureAudioSession () {
        self.audioSession = AVAudioSession.sharedInstance()
        
        var categoryError: NSError?
        var activeError: NSError?
        
        self.audioSession.setCategory(AVAudioSessionCategoryPlayback, error: &categoryError)
        println("error \(categoryError)")
        
        var success = self.audioSession.setActive(true, error: &activeError)
        if !success {
            println("Error making audio session active \(activeError)")
        }
    }
    
    //    func configureAudioPlayer (){
    //
    //        var songPath = NSBundle.mainBundle().pathForResource("Destiny (Fresh Direct's Chillstep Re", ofType: "mp3")
    //        var songURL = NSURL.fileURLWithPath(songPath!)
    //
    //        println("songURL: \(songURL)")
    //
    //        var songError: NSError?
    //        self.audioPlayer = AVAudioPlayer(contentsOfURL: songURL, error: &songError)
    //        println("song error: \(songError)")
    //        self.audioPlayer.numberOfLoops = 0
    //
    //    }
    
    
    func configureAudioQueuePlayer () {
        
        let songs = createSongs()
        self.audioQueuePlayer = AVQueuePlayer(items: songs)
        
        for var songIndex = 0; songIndex < songs.count; songIndex++ {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "songEnded:", name: AVPlayerItemDidPlayToEndTimeNotification, object: songs[songIndex])
        }
        
    }
    
    func playMusic () {
        //        self.audioPlayer.prepareToPlay()
        //        self.audioPlayer.play()
        
        if audioQueuePlayer.rate > 0 && audioQueuePlayer.error == nil {
            self.audioQueuePlayer.pause()
        }
        else if currentSongIndex == nil {
            self.audioQueuePlayer.play()
            self.currentSongIndex = 0
        } else {
            self.audioQueuePlayer.play()
        }
        
        
        
    }
    
    func createSongs () -> [AnyObject] {
        
        let firstSongPath = NSBundle.mainBundle().pathForResource("Destiny (Fresh Direct's Chillstep Re", ofType: "mp3")
        let secondSongPath = NSBundle.mainBundle().pathForResource("Nhumo_En mi Nube", ofType: "mp3")
        let thirdSongPath = NSBundle.mainBundle().pathForResource("Nhumo_Weeping Willow", ofType: "mp3")
        
        let firstSongURL = NSURL.fileURLWithPath(firstSongPath!)
        let secondSongURL = NSURL.fileURLWithPath(secondSongPath!)
        let thirdSongURL = NSURL.fileURLWithPath(thirdSongPath!)
        
        let firstPlayItem = AVPlayerItem(URL: firstSongURL)
        let secondPlayItem = AVPlayerItem(URL: secondSongURL)
        let thirdPlayItem = AVPlayerItem(URL: thirdSongURL)
        
        let songs: [AnyObject] = [firstPlayItem, secondPlayItem, thirdPlayItem]
        
        return songs
    }
    
    //Mark: - Audio Notification
    
    func songEnded (notification: NSNotification) {
        self.currentSongIndex = self.currentSongIndex + 1
        self.updateUI()
    }
    
    //Mark: - UIUpdate Helpers
    
    func updateUI () {
        self.currentSongLabel.text = currentSongName()
        
        if audioQueuePlayer.rate > 0 && audioQueuePlayer.error == nil {
            self.playButton.setTitle("Pause", forState: UIControlState.Normal)
        } else {
            self.playButton.setTitle("Play", forState: UIControlState.Normal)
        }
        
    }
    
    func currentSongName () -> String {
        var currentSong: String
        
        if currentSongIndex == 0 {
            currentSong = "Destiny"
        } else if currentSongIndex == 1 {
            currentSong = "Nube"
        } else if currentSongIndex == 2 {
            currentSong = "Weeping Willow"
        } else {
            currentSong = "No song playing"
            println("Something went wrong!")
        }
        
        return currentSong
    }
    
    //Mark: - WatchKit Notification
    
    func handleRequest(notification : NSNotification) {
        
        let watchKitInfo = notification.object as? WatchKitInfo
        
        if watchKitInfo!.playerRequest != nil {
            
            let requestedAction: String = watchKitInfo!.playerRequest!
            
            switch requestedAction {
            case "Play":
                self.playMusic()
            case "Next":
                self.playNextButtonPressed(UIButton())
            case "Previous":
                self.playPreviousButtonPressed(UIButton())
            default:
                println("default value printed something wrong")
                
            }
            
            let currentSongDictionary = ["CurrentSong" : currentSongName()]
            watchKitInfo?.replyBlock(currentSongDictionary)
            
            self.updateUI()
            
        }
        
    }
    
}

