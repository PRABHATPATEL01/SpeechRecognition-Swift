//
//  ViewController.swift
//  SpeechRecognition
//
//  Created by Prabhat Mishra on 20/01/24.
//

import UIKit
//import InstantSearchVoiceOverlay
//import AVFAudio
import AVFoundation
import Speech
import UserNotifications

class ViewController: UIViewController, SFSpeechRecognizerDelegate,AVAudioRecorderDelegate,AVAudioPlayerDelegate{
    var audioRecorder: AVAudioRecorder!
    var audioFileURL: URL!
    var audioPlayer: AVAudioPlayer!
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    @IBOutlet weak var txtView: UITextView!
    @IBOutlet weak var MickBtn: UIButton!
    
    //    func recording(text: String?, final: Bool?, error: Error?) {
    //        
    //    }
    //    //let voiceOverlay = VoiceOverlayController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    //    AVAudioSession.sharedInstance().requestRecordPermission { granted in
    //        if granted {
    //            // Permission granted, you can proceed with recording
    //        } else {
    //            // Handle the case when permission is denied
    //        }
    //    }
    func playRecording() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFileURL)
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            audioPlayer.play()
            
            // Update UI or perform other tasks when playing starts
            print("Playing recording")
        } catch {
            // Handle audio player setup errors
            print("Error setting up audio player: \(error.localizedDescription)")
        }
    }
    func stopPlayback() {
        if audioPlayer.isPlaying {
            audioPlayer.stop()
            
            // Update UI or perform other tasks when playback stops
            print("Playback stopped")
        }
    }
    
    
    func StartRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
            try audioSession.setActive(true)
            
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            audioFileURL = documentsDirectory.appendingPathComponent("recordedAudio.wav")
            
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFileURL, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.prepareToRecord()
            audioRecorder.record()
            
            // Update UI or perform other tasks when recording starts
            print("Recording started")
        } catch {
            // Handle audio session or recorder setup errors
            print("Error setting up audio session or recorder: \(error.localizedDescription)")
        }
    }
    func stopRecording() {
        audioRecorder.stop()
        
        // Update UI or perform other tasks when recording stops
        print("Recording stopped")
    }
    
    
    override public func viewDidAppear(_ animated: Bool) {
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            /*
             The callback may not be called on the main thread. Add an
             operation to the main queue to update the record button's state.
             */
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.MickBtn.isEnabled = true
                    
                case .denied:
                    self.MickBtn.isEnabled = false
                    self.MickBtn.setTitle("User denied access to speech recognition", for: .disabled)
                    
                case .restricted:
                    self.MickBtn.isEnabled = false
                    self.MickBtn.setTitle("Speech recognition restricted on this device", for: .disabled)
                    
                case .notDetermined:
                    self.MickBtn.isEnabled = false
                    self.MickBtn.setTitle("Speech recognition not yet authorized", for: .disabled)
                }
            }
        }
    }
    
    private func startRecording() throws {
        
        // Cancel the previous task if it's running.
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSession.Category.record)
        try audioSession.setMode(AVAudioSession.Mode.measurement)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        // Configure request so that results are returned before audio recording is finished
        recognitionRequest.shouldReportPartialResults = true
        
        // A recognition task represents a speech recognition session.
        // We keep a reference to the task so that it can be cancelled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                self.txtView.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.MickBtn.isEnabled = true
                self.MickBtn.setTitle("Start Recording", for: [])
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        try audioEngine.start()
        
        txtView.text = "Try to speak"
    }
    
    // MARK: SFSpeechRecognizerDelegate
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            MickBtn.isEnabled = true
            MickBtn.setTitle("Start Recording", for: [])
            
        } else {
            MickBtn.isEnabled = false
            MickBtn.setTitle("Stop Recording", for: .disabled)
        }
    }
    @IBAction func getNotification(_ sender: Any) {
        setInternalNotificaton()
        
        
        
    }
    func setInternalNotificaton(){
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Warning"
        content.body = "This is local notification for simple warning"
        content.sound = .default
        content.userInfo = ["value": "data with local notification"]
        let fireDate = Calendar.current.dateComponents([.day,.month,.year,.hour,.minute,.second], from: Date().addingTimeInterval(3))
        let trigger = UNCalendarNotificationTrigger(dateMatching: fireDate, repeats: false)
        let request = UNNotificationRequest(identifier: "reminder", content: content, trigger: trigger)
        center.add(request) { (error) in
            
            if error != nil {
                print("Error = \(error?.localizedDescription ?? "error in local notification")")
            }
        }
    }
    //        var dateComponents = DateComponents()
    //                dateComponents.year = 2024
    //                dateComponents.month = 1
    //                dateComponents.day = 22
    //                dateComponents.hour = 11
    //                dateComponents.minute = 37
    //                
    //                // Create a Date from the components
    //                if let date = Calendar.current.date(from: dateComponents) {
    //                    // Create notification content
    //                    let content = UNMutableNotificationContent()
    //                    content.title = "Scheduled Notification"
    //                    content.body = "This notification is scheduled for a specific date and time."
    //                    
    //                    // Create a trigger based on the specified date
    //                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
    //                    
    //                    // Create a notification request
    //                    let request = UNNotificationRequest(identifier: "scheduledNotification", content: content, trigger: trigger)
    //                    
    //                    // Add the notification request to the user notification center
    //                    UNUserNotificationCenter.current().add(request) { error in
    //                        if let error = error {
    //                            print("Error scheduling notification: \(error.localizedDescription)")
    //                        } else {
    //                            print("Notification scheduled successfully")
    //                        }
    //                    }
    //                } else {
    //                    print("Failed to create Date from DateComponents.")
    //                }
    //            }
    
    
    
    
    @IBAction func SpeakBtn(_ sender: Any) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            MickBtn.isEnabled = false
            MickBtn.setTitle("Stopping", for: .disabled)
        } else {
            try! startRecording()
            MickBtn.setTitle("Stop recording", for: [])
            if audioRecorder == nil || !audioRecorder.isRecording {
                StartRecording()
            } else {
                stopRecording()
            }
            
        }
        
    }
    
    
    
    
    @IBAction func PlayBtn(_ sender: Any) {
        if audioPlayer == nil || !audioPlayer.isPlaying {
            playRecording()
        } else {
            stopPlayback()
        }
        
        
    }
}
    

    
    
    
    
   
    
        



        
        //        voiceOverlay.delegate = self
        //        voiceOverlay.settings.autoStart = false
        //        voiceOverlay.settings.autoStop = true
        //       //voiceOverlay.settings.autoStop = "5"
        //        voiceOverlay.start(on: self, textHandler: { text, final, _ in
        //
        //            if final {
        //                  print("Finl text: \(text)")
        //            }
        //            else{
        //                print("In progress: \(text)")
        //            }
        //
        //        }, errorHandler: {error in
        //
        //
        //        })
        //         func prepareEngine() throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) {
        //            let audioEngine = AVAudioEngine()
        //
        //            let request = SFSpeechAudioBufferRecognitionRequest()
        //            request.shouldReportPartialResults = true
        //            request.requiresOnDeviceRecognition = true
        //
        //            let audioSession = AVAudioSession.sharedInstance()
        //            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        //            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        //            let inputNode = audioEngine.inputNode
        //
        //            let recordingFormat = inputNode.outputFormat(forBus: 0)
        //            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
        //                request.append(buffer)
        //            }
        //            audioEngine.prepare()
        //            try audioEngine.start()
        //
        //            return (audioEngine, request)
        //        }
        //
        //
       
    
    
    


