//
//  VNTestScene.h
//
//  Created by James Briones on 8/30/12.
//  Copyright 2012. All rights reserved.
//

import SpriteKit
import AVFoundation

/*

Some important notes:

The labels have X and Y values, but these aren't X and Y in pixel coordinates. Rather, they're in percentages
(where 0.01 is 1% while 1.00 is 100%), and they're used to position things in relation to the width and height
of the screen. For example, if you were to position the "Start New Game" label at

X: 0.5
Y: 0.3

...then horizontally, it would be at the middle of the screen (50%) while it would be positioned at only 30% of
the screen's height.

Also, (0.0, 0.0) would be the bottom-left corner of the screen, while (1.0, 1.0) should be the upper-right corner.

*/

// Dictionary keys for the UI elements
let VNTestSceneStartNewGameLabelX       = "startnewgame label x"
let VNTestSceneStartNewGameLabelY       = "startnewgame label y"
let VNTestSceneStartNewGameText         = "startnewgame text"
let VNTestSceneStartNewGameFont         = "startnewgame font"
let VNTestSceneStartNewGameSize         = "startnewgame size"
let VNTestSceneStartNewGameColorDict    = "startnewgame color"
let VNTestSceneContinueLabelX           = "continue label x"
let VNTestSceneContinueLabelY           = "continue label y"
let VNTestSceneContinueText             = "continue text"
let VNTestSceneContinueFont             = "continue font"
let VNTestSceneContinueSize             = "continue size"
let VNTestSceneContinueColor            = "continue color"
let VNTestSceneTitleX                   = "title x"
let VNTestSceneTitleY                   = "title y"
let VNTestSceneTitleImage               = "title image"
let VNTestSceneBackgroundImage          = "background image"
let VNTestSceneScriptToLoad             = "script to load"
let VNTestSceneMenuMusic                = "menu music"

let VNTestSceneZForBackgroundImage      = CGFloat(10.0)
let VNTestSceneZForLabels               = CGFloat(20.0)
let VNTestSceneZForTitle                = CGFloat(30.0)

class VNTestScene : SKScene
{
    //CCLabelTTF* playLabel;
    //CCLabelTTF* loadLabel;
    var playLabel:SMTextNode?
    var loadLabel:SMTextNode?
    
    var title:SKSpriteNode?
    var backgroundImage:SKSpriteNode?
    
    var nameOfScript:String?
    //var testScene:VNScene?
    
    // music stuff
    var isPlayingMusic = false;
    var backgroundMusic:AVAudioPlayer? = nil
    
    var sceneNode:VNSceneNode? = nil
    
    
    // This loads the user interface for the title menu. Default view settings are first loaded into a dictionary,
    // and then custom settings are loaded from a file (assuming file the exists, of course!). After that, the actual
    // CCSprite / CCLabelTTF objects are created from that information.
    //- (void)loadUI
    func loadUI() {
        let defaultSettings                 = self.loadDefaultUI()
        let standardSettings                = NSMutableDictionary(dictionary: defaultSettings)
        var customSettings:NSDictionary?    = nil
        
        // Load the custom settings stored in a file
        let dictionaryFilePath:String? = Bundle.main.path(forResource: "main_menu", ofType: "plist")
        if dictionaryFilePath != nil {
            customSettings = NSDictionary(contentsOfFile: dictionaryFilePath!)
            
            if customSettings != nil && customSettings!.count > 0 {
                
                standardSettings.addEntries(from: customSettings! as! [AnyHashable: Any])
                print("[VNTestScene] UI settings have been loaded from file.")
            }
        }
    
        // Check if no custom settings could be loaded. if this is the case, just log it for diagnostics purposes
        if( customSettings == nil ) {
            print("[VNTestScene] UI settings could not be loaded from a file.");
        }
        
        //println("Standard settings are: \n\n\(standardSettings)")
    
        // For the "Start New Game" button, get the values from the dictionary
        let startLabelX = SMUtility.Dictionaries.CGFloatFromDictionary(dictionary: standardSettings, name: VNTestSceneStartNewGameLabelX)
        let startLabelY = SMUtility.Dictionaries.CGFloatFromDictionary(dictionary: standardSettings, name: VNTestSceneStartNewGameLabelY)
        
        let startFontSize:CGFloat = CGFloat( (standardSettings.object(forKey: VNTestSceneStartNewGameSize) as! NSNumber).doubleValue )
        let startText   = standardSettings.object(forKey: VNTestSceneStartNewGameText) as! NSString
        let startFont   = standardSettings.object(forKey: VNTestSceneStartNewGameFont) as! NSString
        let startColors = standardSettings.object(forKey: VNTestSceneStartNewGameColorDict) as! NSDictionary
        
        // Decode start colors
        let startColorR = (startColors.object(forKey: "r") as! NSNumber).intValue
        let startColorG = (startColors.object(forKey: "g") as! NSNumber).intValue
        let startColorB = (startColors.object(forKey: "b") as! NSNumber).intValue
    
        // Now create the actual label
        playLabel           = SMTextNode(fontNamed: startFont as String)
        playLabel!.text     = startText as String
        playLabel!.fontSize = startFontSize
        playLabel!.color    = SMUtility.Color.fromRGB(r: startColorR, g: startColorG, b: startColorB)
        playLabel!.position = SMUtility.Position.normalizedCoordinates(normalizedX: startLabelX, normalizedY: startLabelY)
        playLabel!.zPosition = VNTestSceneZForLabels
        
        self.addChild(playLabel!)
        
        // Now grab the values for the Continue button
        let continueLabelX      = CGFloat( (standardSettings.object(forKey: VNTestSceneContinueLabelX) as! NSNumber).doubleValue )
        let continueLabelY      = CGFloat( (standardSettings.object(forKey: VNTestSceneContinueLabelY) as! NSNumber).doubleValue )
        let continueFontSize    = CGFloat( (standardSettings.object(forKey: VNTestSceneContinueSize) as! NSNumber).doubleValue )
        let continueText        = standardSettings.object(forKey: VNTestSceneContinueText) as! NSString
        let continueFont        = standardSettings.object(forKey: VNTestSceneContinueFont) as! NSString
        let continueColors      = standardSettings.object(forKey: VNTestSceneContinueColor) as! NSDictionary
        
        // Decode continue colors
        let continueColorR = (continueColors.object(forKey: "r") as! NSNumber).intValue
        let continueColorG = (continueColors.object(forKey: "g") as! NSNumber).intValue
        let continueColorB = (continueColors.object(forKey: "b") as! NSNumber).intValue
        
        // Load the "Continue" label
        loadLabel               = SMTextNode(fontNamed: continueFont as String)
        loadLabel!.fontSize     = continueFontSize
        loadLabel!.text         = continueText as String
        loadLabel!.position     = SMUtility.Position.normalizedCoordinates( normalizedX: continueLabelX, normalizedY: continueLabelY )
        loadLabel!.color        = SMUtility.Color.fromRGB( r: continueColorR, g: continueColorG, b: continueColorB )
        loadLabel!.zPosition    = VNTestSceneZForLabels
        self.addChild(loadLabel!)
        
        // Load the title info
        let titleX          = SMUtility.Dictionaries.CGFloatFromDictionary(dictionary: standardSettings, name: VNTestSceneTitleX)
        let titleY          = SMUtility.Dictionaries.CGFloatFromDictionary(dictionary: standardSettings, name: VNTestSceneTitleY)
        let titleImageName  = standardSettings.object(forKey: VNTestSceneTitleImage) as! String
        title               = SKSpriteNode(imageNamed: titleImageName)
        title!.position     = SMUtility.Position.normalizedCoordinates(normalizedX: titleX, normalizedY: titleY)
        title!.zPosition    = VNTestSceneZForTitle
        self.addChild(title!)
        
        // Load background image
        let backgroundImageFilename     = standardSettings.object(forKey: VNTestSceneBackgroundImage) as! String
        backgroundImage                 = SKSpriteNode(imageNamed: backgroundImageFilename)
        backgroundImage!.position       = SMUtility.Position.normalizedCoordinates(normalizedX: 0.5, normalizedY: 0.5)
        backgroundImage!.zPosition      = VNTestSceneZForBackgroundImage
        self.addChild(backgroundImage!)
    
        // Grab script name information
        //nameOfScript = standardSettings[VNTestSceneScriptToLoad];
        nameOfScript = standardSettings.object(forKey: VNTestSceneScriptToLoad) as? String
    
        // The music data is loaded last since it looks weird if music is playing but nothing has shown up on the screen yet.
        if let musicFilename = standardSettings.object(forKey: VNTestSceneMenuMusic) as? NSString {
            // Make sure the music isn't set to 'nil'
            if musicFilename.caseInsensitiveCompare("nil") != ComparisonResult.orderedSame {
                self.playBackgroundMusic(filename: musicFilename as String)
            }
        }
    }
    
    // This creates a dictionary that's got the default UI values loaded onto them. If you want to change how it looks,
    // you should open up "main_menu.plist" and set your own custom values for things there.
    //- (NSDictionary*)loadDefaultUI
    func loadDefaultUI() -> NSDictionary {
        let resourcesDictionary = NSMutableDictionary(capacity: 13)
        
        // Create default white colors
        //var whiteColorDict = NSDictionary(dictionaryLiteral: 255, "r", 255, "g", 255, "b")
        let whiteColorDictionary = NSDictionary(dictionary: ["r":255, "g":255, "b":255])
    
        // Create settings for the "start new game" button
        resourcesDictionary.setObject(0.5,                          forKey: VNTestSceneStartNewGameLabelX       as NSCopying)
        resourcesDictionary.setObject(0.3,                          forKey: VNTestSceneStartNewGameLabelY       as NSCopying)
        resourcesDictionary.setObject("Helvetica",                  forKey: VNTestSceneStartNewGameFont         as NSCopying)
        resourcesDictionary.setObject(18,                           forKey: VNTestSceneStartNewGameSize         as NSCopying)
        resourcesDictionary.setObject(whiteColorDictionary.copy(),  forKey: VNTestSceneStartNewGameColorDict    as NSCopying)
        
        // Create settings for "continue" button
        resourcesDictionary.setObject(0.5,                          forKey: VNTestSceneContinueLabelX   as NSCopying)
        resourcesDictionary.setObject(0.2,                          forKey: VNTestSceneContinueLabelX   as NSCopying)
        resourcesDictionary.setObject("Helvetica",                  forKey: VNTestSceneContinueFont     as NSCopying)
        resourcesDictionary.setObject(18,                           forKey: VNTestSceneContinueSize     as NSCopying)
        resourcesDictionary.setObject(whiteColorDictionary.copy(),  forKey: VNTestSceneContinueColor    as NSCopying)
        
        // Set up title data
        resourcesDictionary.setObject(0.5,              forKey: VNTestSceneTitleX       as NSCopying)
        resourcesDictionary.setObject(0.75,             forKey: VNTestSceneTitleY       as NSCopying)
        resourcesDictionary.setObject("title.png",      forKey: VNTestSceneTitleImage   as NSCopying)
        
        // Set up background image
        resourcesDictionary.setObject("skyspace.png",   forKey: VNTestSceneBackgroundImage  as NSCopying)
        // Set up script data
        resourcesDictionary.setObject("demo script",    forKey: VNTestSceneScriptToLoad     as NSCopying)
        // Set default music data
        resourcesDictionary.setObject("nil",            forKey: VNTestSceneMenuMusic        as NSCopying)
        
        return NSDictionary(dictionary: resourcesDictionary)
    }
    
    /* Game starting and loading */
    
    func startNewGame() {
        // Create a blank dictionary with no real data, except for the name of which script file to load.
        // You can pass this in to VNLayer with nothing but that information, and it will load a new game
        // (or at least, a new VNLayer scene!)
        let settingsForScene = NSDictionary(object: nameOfScript!, forKey: VNSceneToPlayKey as NSCopying)
        
        sceneNode = VNSceneNode(settings: settingsForScene)
        sceneNode!.loadDataOnView(view: self.view!)
        sceneNode!.zPosition = 9999
        self.addChild(sceneNode!)
        
        // hide menu
        self.isUserInteractionEnabled = false
        playLabel!.alpha = 0
        loadLabel!.alpha = 0
        title!.alpha = 0.0
        backgroundImage!.alpha = 0
    }
    
    func loadSavedGame()
    {
        //if SMRecord.sharedRecord.hasAnySavedData() == false {
        if SMRecord.hasSavedLocalData() == false { //&& SMRecord.sharedRecord.hasSavedCloudData() == false {
            print("[VNTestScene] ERROR: No saved data, cannot continue game!");
            return;
        }
    
        // The following's not very pretty, but it is pretty useful...
        //print("[VNTestScene] For diagnostics purporses, here's a flag dump from SMRecord:\n   \(SMRecord.flags())")
    
        // Load saved-game records from EKRecord. The activity dictionary holds data about what the last thing the user was doing
        // (presumably, watching a scene), how far the player got, relevent data that needs to be reloaded, etc.
        //let activityRecords = SMRecord.sharedRecord.activityDict()
        let activityRecords = SMRecord.dictionaryOfActivityInformation()
        let lastActivity:NSString? = activityRecords.object(forKey: SMRecord.ActivityTypeKey) as? NSString
        if lastActivity == nil {
            print("[VNTestScene] ERROR: No previous activity found. No saved game can be loaded.");
            return;
        }
        
        let savedData = activityRecords.object(forKey: SMRecord.ActivityDataKey) as! NSDictionary
        print("[VNTestScene] Saved data is \(savedData)")
    
        // Unlike when the player is starting a new game, the name of the script to load doesn't have to be passed.
        // It should already be stored within the Activity Records from EKRecord.
        //[[CCDirector sharedDirector] pushScene:[VNScene sceneWithSettings:savedData]];
        
        /*
        let loadedGameScene = VNScene(size: self.size, settings: savedData)
        loadedGameScene.scaleMode = self.scaleMode
        loadedGameScene.previousScene = self;
        self.view!.presentScene(loadedGameScene)*/
        
        sceneNode = VNSceneNode(settings: savedData)
        sceneNode!.loadDataOnView(view: self.view!)
        self.addChild(sceneNode!)
        sceneNode!.zPosition = 9999
        
        // hide menu
        self.isUserInteractionEnabled   = false
        playLabel!.alpha                = 0
        loadLabel!.alpha                = 0
        title!.alpha                    = 0.0
        backgroundImage!.alpha          = 0
    }
    
    /* Audio */
    
    func stopMenuMusic()
    {
        if isPlayingMusic == true {
            //OALSimpleAudio.sharedInstance().stopBg()
            if backgroundMusic != nil {
                backgroundMusic!.stop()
            }
        }
        
        isPlayingMusic = false
    }
    
    func playBackgroundMusic( filename:String )
    {
        if SMUtility.Strings.lengthOf(string: filename) < 1 {
            return;
        }
        self.stopMenuMusic()
        backgroundMusic = SMUtility.Audio.soundFromFile(filename: filename)
        
        if backgroundMusic == nil  {
            print("[VNTestScene] ERROR: Could not load background music from file named: \(filename)")
        } else {
            backgroundMusic!.numberOfLoops = -1;
            backgroundMusic!.play()
        }
        
        isPlayingMusic = true
    }
    
    /* Touch controls */
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for t in touches {
            let touch = t 
            let touchPos = touch.location(in: self)
            
            if SMUtility.Collision.boundingBoxOfSprite(sprite: playLabel!).contains(touchPos) == true {
                self.stopMenuMusic()
                self.startNewGame()
            }
            
            if( SMUtility.Collision.boundingBoxOfSprite(sprite: loadLabel!).contains(touchPos) ) {
                if loadLabel!.alpha > 0.98 {
                    self.stopMenuMusic()
                    self.loadSavedGame()
                }
            }
        }
    }
    
    // MARK: Initialization 
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(size: CGSize) {
        super.init(size: size)
        SMUtility.Screen.setSize(screenWidth: size.width, screenHeight: size.height)
        // determine if there's any previously saved data
        let previousSaveData = SMRecord.hasSavedLocalData()
        isPlayingMusic = false // disable music for now
        self.loadUI()
        // If there's no previous data, then the "Continue" / "Load Game" label will be partially transparent.
        if previousSaveData == false {
            loadLabel!.alpha = 0.5
        } else {
            loadLabel!.alpha = 1.0
        }
        self.isUserInteractionEnabled = true
    }
    
    override func update(_ currentTime: TimeInterval) {
        if sceneNode != nil  {
            sceneNode!.update(currentTime)
            
            // check if VNSceneNode is done running; if it is, then remove it and restore control to the menu scene
            if sceneNode!.isFinished == true {
                sceneNode!.removeFromParent()
                sceneNode = nil
                
                // restore menu
                self.isUserInteractionEnabled = true
                loadLabel!.alpha = 1.0
                playLabel!.alpha = 1.0
                backgroundImage!.alpha = 1.0
                title!.alpha = 1.0
            }
        }
    }
}
