//
//  VNScene.swift
//  EKVN Swift
//
//  Created by James on 11/11/14.
//  Copyright (c) 2014 James Briones. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit
import AVFoundation

/*

VNScene

VNScene is the main class for displaying and interacting with the Visual Novel system (or "VN system") I've coded.
VNScene works by taking script data (interpreted from a Property List file using VNScript), and processes
the script to handle audio and display graphics, text, and basic animation. It also handles user input for playing
the scene and user choices, plus saving related data to SMRecord.

Visual and audio elements are handled by VNScene; sprites and sounds are stored in a mutable dictionary and mutable array,
respectively. A record of the dialogue scene / visual-novel elements is kept by VNScene, and can be copied over to SMRecord
(and from SMRecord, into device memory) when necessary. During certain "volatile" periods (like when performing effects or
presenting the player with a menu of choices), VNScene will store that record in a "safe save," which is created just before
the effect/choice-menu is run, and holds the data from "the last time it was safe to save the game." Afterwards, when VNScene
resumes "normal" activity, then the safe-save is removed and any attempts to save the game will just draw data from the
"normal" record.

When processing script data from VNScript, the script is divided into "conversations," which are really an NSArray
of text/NSString objects that have been converted to string and number data to be more easily processed. Different "conversations"
represent branching paths in the script. When VNScene begins processing script data, it always starts with a converation
named "start".

*/

/*

Coding/readability notes

NOTE: What would become VNScene was originally written as part of a visual-novel game engine that I made in conjuction
with a custom sprite-drawing kit written in OpenGL ES v1. At that time, it used the MVC (Model-View-Controller) model,
where there were separate classes for each.

Later, I ported the code over to Cocos2D (which worked MUCH better than my custom graphics kit), and the View and
Controller classes were mixed together to form VNScene, while VNScript held the Model information. I've tried
to clean up the code so it would make sense to reflect how things work now, but there are still some quirks and
"leftovers" from the prior version of the code.

Added January 2014: Also, upgrading to Cocos2D v3.0 caused some other changes to be made. VNScene used to be VNLayer,
and inherited from CCLayer. Since that class has been removed, VNScene now inherits from CCScene. As some other
Cocos2D classes have been renamed or had major changes, the classes in EKVN that relied on Cocos2D have had to change
or be renamed alongside that. I've cleaned up the code somewhat, but it's possible that there are still some comments
and other references to the "old" version of Cocos2D that I haven't spotted!

Added September 2014: EKVN SpriteKit has been ported from cocos2d to -- as you might have guessed -- SpriteKit.
The two are kind of similar, but there are enough differences to make seemingly normal things (like positioning nodes)
act differently. To maintain compatibility with the "regular" EKVN that uses cocos2d, a lot of old code (and commments!) have been
left in, but hacked/patched to work with SpriteKit. In short, some things are going to look a little confusing.

*/

/** Defintions and Constants **/

let VNSceneActivityType             = "VNScene" // The type of activity this is (used in conjuction with SMRecord)
let VNSceneToPlayKey                = "scene to play"
let VNSceneViewFontSize             = 17
let VNSceneSpriteIsSafeToRemove     = "sprite is safe to remove" // Used for sprite removal (to free up memory and remove unused sprite)
let VNScenePopSceneWhenDoneKey      = "pop scene when done" // Ask CCDirector to pop the  scene when the script finishes?

// Sprite alignment strings (used for commands)
let VNSceneViewSpriteAlignmentLeftString                = "left"             // 25% of screen width
let VNSceneViewSpriteAlignmentCenterString              = "center"           // 50% of screen width
let VNSceneViewSpriteAlignmentRightString               = "right"            // 75% of screen width
let VNSceneViewSpriteAlignemntFarLeftString             = "far left"         // 0% of screen width
let VNSceneViewSpriteAlignmentExtremeLeftString         = "extreme left"     // -50% of screen width; offscreen to the left
let VNSceneViewSpriteAlignmentFarRightString            = "far right"        // 100% of screen width
let VNSceneViewSpriteAlignmentExtremeRightString        = "extreme right"    // 150% of screen width; offscreen to the right

// View settings keys
let VNSceneViewTalkboxName                  = "talkbox.png"
let VNSceneViewSpeechBoxOffsetFromBottomKey = "speechbox offset from bottom"
let VNSceneViewSpriteTransitionSpeedKey     = "sprite transition speed"
let VNSceneViewTextTransitionSpeedKey       = "text transition speed"
let VNSceneViewNameTransitionSpeedKey       = "speaker name transition speed"
let VNSceneViewSpeechBoxXKey                = "speech box x"
let VNSceneViewSpeechBoxYKey                = "speech box y"
let VNSceneViewNameXKey                     = "name x"
let VNSceneViewNameYKey                     = "name y"
let VNSceneViewSpeechXKey                   = "speech x"
let VNSceneViewSpeechYKey                   = "speech y"
let VNSceneViewSpriteXKey                   = "sprite x"
let VNSceneViewSpriteYKey                   = "sprite y"
let VNSceneViewButtonXKey                   = "button x"
let VNSceneViewButtonYKey                   = "button y"
let VNSceneViewSpeechHorizontalMarginsKey   = "speech horizontal margins"
let VNSceneViewSpeechVerticalMarginsKey     = "speech vertical margins"
let VNSceneViewSpeechBoxFilenameKey         = "speech box filename"
let VNSceneViewSpeechOffsetXKey             = "speech offset x"
let VNSceneViewSpeechOffsetYKey             = "speech offset y"
let VNSceneViewDefaultBackgroundOpacityKey  = "default background opacity"
let VNSceneViewMultiplyFontSizeForiPadKey   = "multiply font size for iPad"
let VNSceneViewButtonUntouchedColorsKey     = "button untouched colors"
let VNSceneViewButtonsTouchedColorsKey      = "button touched colors"

// Resource dictionary keys
let VNSceneViewSpeechTextKey                = "speech text"
let VNSceneViewSpeakerNameKey               = "speaker name"
let VNSceneViewShowSpeechKey                = "show speech flag"
let VNSceneViewBackgroundResourceKey        = "background resource"
let VNSceneViewAudioInfoKey                 = "audio info"
let VNSceneViewSpriteResourcesKey           = "sprite resources"
let VNSceneViewSpriteNameKey                = "sprite name"
let VNSceneViewSpriteAlphaKey               = "sprite alpha"
let VNSceneViewSpeakerNameXOffsetKey        = "speaker name offset x"
let VNSceneViewSpeakerNameYOffsetKey        = "speaker name offset y"
let VNSceneViewButtonFilenameKey            = "button filename"
let VNSceneViewFontSizeKey                  = "font size"
let VNSceneViewFontNameKey                  = "font name"
let VNSceneViewOverrideSpeechFontKey        = "override speech font from save"
let VNSceneViewOverrideSpeechSizeKey        = "override speech size from save"
let VNSceneViewOverrideSpeakerFontKey       = "override speaker font from save"
let VNSceneViewOverrideSpeakerSizeKey       = "override speaker size from save"
let VNSceneViewNoSkipUntilTextShownKey      = "no skipping until text is shown" // Prevents skipping until the text is fully shown

// Dictionary keys
let VNSceneSavedScriptInfoKey       = "script info"
let VNSceneSavedResourcesKey        = "saved resources"
let VNSceneMusicToPlayKey           = "music to play"
let VNSceneMusicShouldLoopKey       = "music should loop"
let VNSceneSpritesToShowKey         = "sprites to show"
let VNSceneSoundsToRemoveKey        = "sounds to remove"
let VNSceneMusicToRemoveKey         = "music to remove"
let VNSceneBackgroundToShowKey      = "background to show"
let VNSceneSpeakerNameToShowKey     = "speaker name to show"
let VNSceneSpeechToDisplayKey       = "speech to display"
let VNSceneShowSpeechKey            = "show speech"
let VNSceneBackgroundXKey           = "background x"
let VNSceneBackgroundYKey           = "background y"
let VNSceneTypewriterTextCanSkip    = "typewriter text can skip"
let VNSceneTypewriterTextSpeed      = "typewriter text speed"

// UI "override" keys (used when you change things like font size/font name in the middle of a scene).
// By default, any changes will be restored when a saved game is loaded, though the "override X from save"
// settings can change this.
let VNSceneOverrideSpeechFontKey    = "override speech font"
let VNSceneOverrideSpeechSizeKey    = "override speech size"
let VNSceneOverrideSpeakerFontKey   = "override speaker font"
let VNSceneOverrideSpeakerSizeKey   = "override speaker size"

// Graphics/display stuff
let VNSceneViewSettingsFileName     = "vnscene view settings"
let VNSceneSpriteXKey               = "x position"
let VNSceneSpriteYKey               = "y position"

// Sprite/node layers
let VNSceneBackgroundLayer:CGFloat  = 50.0
let VNSceneCharacterLayer:CGFloat   = 60.0
let VNSceneUILayer:CGFloat          = 100.0
let VNSceneTextLayer:CGFloat        = 110.0
let VNSceneButtonsLayer:CGFloat     = 120.0
let VNSceneButtonTextLayer:CGFloat  = 130.0

// Node tags (NOTE: In Cocos2D v3.0, numeric tags were replaced with string-based names, similar to Sprite Kit)
let VNSceneTagSpeechBox             = "speech box"   //600
let VNSceneTagSpeakerName           = "speaker name" //601
let VNSceneTagSpeechText            = "speech text"  //602
let VNSceneTagBackground            = "background"   //603

// Scene modes
let VNSceneModeLoading              = 100
let VNSceneModeFinishedLoading      = 101
let VNSceneModeNormal               = 200 // Normal "playing," with dialogue and interaction
let VNSceneModeEffectIsRunning      = 201 // An Effect (fade-in/fade-out, sprite-movement, etc.) is currently running
let VNSceneModeChoiceWithFlag       = 202
let VNSceneModeChoiceWithJump       = 203
let VNSceneModeEnded                = 300 // There isn't any more script data to process

private var VNSceneSharedInstance:VNScene? = nil

//@interface VNScene : SKScene {
class VNScene : SKScene {
    
    // Model data (which in this case is the scene's "script" that determines what will happen)
    //VNScript* script
    var script:VNScript?
    
    class var sharedScene:VNScene? {
        
        if( VNSceneSharedInstance != nil ) {
            return VNSceneSharedInstance
        }
        
        return nil
    }

    // A helper class that can be used to handle .systemcall commands. This may be redundant, now that
    // .callcode exists though!
    //VNSystemCall* systemCallHelper;
    var systemCallHelper:VNSystemCall = VNSystemCall()// FIX LATER
    
    var record:NSMutableDictionary = NSMutableDictionary() // Holds misc data (especially regarding the script)
    var flags:NSMutableDictionary = NSMutableDictionary() // Local flags data (later saved to SMRecord's flags, when the scene is saved)
    
    var mode:Int = VNSceneModeLoading // What the scene is doing (or should be doing) at the current moment
    
    // The "safe save" is an pseudo-autosave created right before performing a "dangerous" action like running an EKEffect.
    // Since saving the game in the middle of an effectt can cause unexpected results (like sprites being in the wrong
    // position), VNScene won't allow for anything to be saved until a "safe" point can be reached. Instead, VNScene saves
    // its data into this dictionary object beforehand, and if the user attempts to save the game in the middle of an effect,
    // they will only save the "safe" information instead of anything dangerous. Of course, when the "dangerous" part ends,
    // this dictionary is deleted, and things can be saved as normal.
    var safeSave:NSMutableDictionary = NSMutableDictionary()
    
    // View data
    var viewSettings:NSMutableDictionary = NSMutableDictionary()
    
    var effectIsRunning:Bool = false
    var isPlayingMusic:Bool = false
    var noSkippingUntilTextIsShown:Bool = false
    var backgroundMusic:AVAudioPlayer? = nil
    
    var soundsLoaded = NSMutableArray()
    var buttons:NSMutableArray = NSMutableArray()
    var choices:NSMutableArray = NSMutableArray() // Holds values that will be used when making choices
    var choiceExtras:NSMutableArray = NSMutableArray() // Holds extra data that's used when making choices (usually, flag data)
    var buttonPicked:Int = -1 // Keeps track of the most recently touched button in the menu
    
    var sprites = NSMutableDictionary()
    var spritesToRemove = NSMutableArray()
    
    var speechBox:SKSpriteNode? // Dialogue box
    var speech:DSMultilineLabelNode?  // The text displayed as dialogue
    var speaker:DSMultilineLabelNode? // Name of speaker
    
    var speechFont = ""; // The name of the font used by the speech text
    var speakerFont = "Helvetica"; // The name of the font used by the speaker text
    var fontSizeForSpeech:CGFloat = 17.0
    var fontSizeForSpeaker:CGFloat = 19.0
    
    var spriteTransitionSpeed:Double = 0.5
    var speechTransitionSpeed:Double = 0.5
    var speakerTransitionSpeed:Double = 0.5
    var buttonTouchedColors = UIColor.blueColor()
    var buttonUntouchedColors = UIColor.blackColor()
    
    var previousScene:SKScene? = nil
    var allSettings:NSDictionary?
    
    var isFinished:Bool = false
    var wasJustLoadedFromSave:Bool = true
    var popSceneWhenDone:Bool = false
    
    // Typewriter text
    var TWModeEnabled = false; // Off by default (standard EKVN text mode)
    var TWCanSkip = true; // Can the user skip ahead (and cut the text short) by tapping?
    var TWSpeedInCharacters = 0; // How many characters it should print per second
    var TWSpeedInFrames = 0
    var TWTimer = 0; // Used to determine how many characters should be displayed (relative to the time/speed of displaying characters)
    var TWSpeedInSeconds = 0.0
    var TWNumberOfCurrentCharacters = 0
    var TWPreviousNumberOfCurrentChars = 0
    var TWNumberOfTotalCharacters = 0
    var TWCurrentText = " "; // What's currently on the screen
    var TWFullText = " "; // The entire line of text
    // Used to handle SpriteKit's weird text-display quirks
    var TWInvisibleText:DSMultilineLabelNode? = nil
    
    // MARK: Initialization
    
    override init() {
        super.init()
    }
    
    init(size:CGSize, settings:NSDictionary) {
        super.init(size: size)
        
        // Copy dictionary values
        allSettings = NSDictionary(dictionary: settings)
    }
    
    // I don't even know.
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        //fatalError("init(coder:) has not been implemented")
        print("[VNScene] ERROR: Initialization via NSCoder has not been implemented!")
    }
    
    //- (void)didMoveToView:(SKView *)view
    override func didMoveToView(view: SKView) {
    
        SMSetScreenDataFromView(view); // Get view and screen size data; this is used to position UI elements
    
        isFinished = false
        userInteractionEnabled = true
        wasJustLoadedFromSave = true
        popSceneWhenDone = true
    
        // Set default values
        mode            = VNSceneModeLoading; // Mode is "loading resources"
        effectIsRunning = false;
        isPlayingMusic  = false;
        buttonPicked    = -1;
        soundsLoaded    = NSMutableArray()
        sprites         = NSMutableDictionary()
        record          = NSMutableDictionary(dictionary: allSettings!)
        flags           = NSMutableDictionary(dictionary: SMRecord.sharedRecord.flags())
        // Also set the defaults for text-skipping behavior
        noSkippingUntilTextIsShown = false
        
        // Set default UI values
        fontSizeForSpeaker  = 0.0;
        fontSizeForSpeech   = 0.0;
    
        // Try to load script info from any saved script data that might exist. Otherwise, just create a fresh script object
        let savedScriptInfo:NSDictionary? = allSettings!.objectForKey(VNSceneSavedScriptInfoKey) as? NSDictionary
        
        // Was there previous saved script / saved game data?
        if( savedScriptInfo != nil ) {
            
            // Load script data from a saved game
            //script = VNScript(info: savedScriptInfo!)!
            let loadedScript:VNScript? = VNScript(info: savedScriptInfo!)
            if( loadedScript == nil ) {
                print("[SMRecord] ERROR: Could not load VNScript object.")
                return
            }
            
            script = loadedScript!
            wasJustLoadedFromSave = true // Set flag; this is important since it's meant to prevent autosave errors
            script!.indexesDone = script!.currentIndex
            print("[VNScene] Settings were loaded from a saved game.")
    
        } else { // No previous saved data
            
            let scriptFileName:NSString? = allSettings!.objectForKey(VNSceneToPlayKey) as? NSString
            if( scriptFileName == nil ) {
                print("[VNScene] ERROR: Could not load script file for new scene.")
                return
            } else {
                print("[VNScene] The name of the script to be loaded is [\(scriptFileName!)]")
            }
            
            // Create the dictionary that will be used to load script data from a file
            let dictionaryForScriptLoading = NSMutableDictionary()
            dictionaryForScriptLoading.setValue(scriptFileName, forKey: VNScriptFilenameKey)
            dictionaryForScriptLoading.setValue(VNScriptStartingPoint, forKey: VNScriptConversationNameKey)
            
            // Create script data
            let loadedScript:VNScript? = VNScript(info: dictionaryForScriptLoading)
            if loadedScript == nil {
                print("[VNScene] ERROR: Could not load script named: \(scriptFileName)")
                return
            }
            
            // Otherwise...
            print("[VNScene] Settings were loaded from a script file.")
            script = loadedScript
        }
    
        // Load default view settings
        //[self loadDefaultViewSettings) // The standard settings
        loadDefaultViewSettings()
        print("[VNScene] Default view settings loaded.");
    
        // Load any "extra" view settings that may exist in a certain Property List file ("VNScene View Settings.plist")
        //NSString* filePath = [[NSBundle mainBundle] pathForResource:VNSceneViewSettingsFileName ofType:@"plist")
        let filePath:NSString? = NSBundle.mainBundle().pathForResource(VNSceneViewSettingsFileName, ofType: "plist")
        if filePath != nil {
            
            let manualSettings:NSDictionary? = NSDictionary(contentsOfFile: filePath! as String)
            
            if manualSettings != nil {
                print("[VNScene] Manual settings found; will load into view settings dictionary.")
                viewSettings.addEntriesFromDictionary(manualSettings! as [NSObject : AnyObject]) // Copy custom settings to UI dictionary; overwrite default values
            }
        }
        
        // This mimics cocos2d's ability to "pop" a scene when it's finished running... however, SpriteKit doesn't
        // have built-in push/pop support for SKScene, so it has to be done manually, and in some cases it might
        // not be a good idea (such as if there's no previous scene to pop to). This flag tracks whether or not
        // to attempt to "pop" the scene when it's finished.
        let shouldPopWhenDone:NSNumber? = record.objectForKey(VNScenePopSceneWhenDoneKey) as? NSNumber
        if( shouldPopWhenDone != nil ) {
            popSceneWhenDone = shouldPopWhenDone!.boolValue
        }
        
        loadUI() // Load the UI using settings dictionary
    
        print("[VNScene] This instance of VNScene will now become the primary VNScene instance.");
        VNSceneSharedInstance = self;
    
        //self.allSettings = nil; // Free up space
    }
    
    /** AUDIO **/
    
    func stopBGMusic()
    {
        /*if( isPlayingMusic == true ) {
        //[[OALSimpleAudio sharedInstance] stopBg)
        OALSimpleAudio.sharedInstance().stopBg()
        }*/
        //OALSimpleAudio.sharedInstance().stopBg()
        
        if backgroundMusic != nil {
            backgroundMusic!.stop()
        }
        
        isPlayingMusic = false;
    }
    
    //- (void)playBGMusic:(NSString*)filename willLoop:(BOOL)willLoopForever
    func playBGMusic(filename:String, willLoopForever:Bool)
    {
        //[self stopBGMusic) // Cancel any existing music
        stopBGMusic()
        
        //OALSimpleAudio.sharedInstance().playEffect(filename, loop: willLoopForever)
        //OALSimpleAudio.sharedInstance().playBg(filename, loop: willLoopForever)
        
        if SMStringLength(filename) < 1 {
            print("[VNScene] ERROR: Could not load background music because input filename is invalid.")
            return;
        }
        
        backgroundMusic = SMAudioSoundFromFile(filename)
        
        if backgroundMusic == nil {
            print("[VNScene] ERROR: Could not load background music from file named: \(filename)")
            return;
        }
        
        if willLoopForever == true {
            backgroundMusic!.numberOfLoops = -1
        }
        
        backgroundMusic!.play()
        isPlayingMusic = true;
    }
    
    //- (void)playSoundEffect:(NSString*)filename
    func playSoundEffect(filename:String)
    {
        //[self runAction:[SKAction playSoundFileNamed:filename waitForCompletion:NO])
        //[[OALSimpleAudio sharedInstance] playEffect:filename)
        //OALSimpleAudio.sharedInstance().playEffect(filename)
        
        if SMStringLength(filename) < 1 {
            print("[VNScene] ERROR: Could not play sound effect because input filename was invalid.")
            return;
        }
        
        let playSoundEffectAction = SKAction.playSoundFileNamed(filename, waitForCompletion: false)
        self.runAction(playSoundEffectAction)
    }
    
    
    /** Other setup or deletion functions **/
    
    // The state of VNScene's UI is stored whenever the game is saved. That way, in case music is playing, or some text is
    // supposed to be on screen, VNScene will remember and SHOULD restore things to exactly the way they were when the game
    // was saved. The restoration of UI is what this function is for.
    func loadSavedResources()
    {
        // Load any saved resource information from the dictionary
        let savedSprites:NSArray?       = record.objectForKey(VNSceneSpritesToShowKey)      as? NSArray
        let loadedMusic:NSString?       = record.objectForKey(VNSceneMusicToPlayKey)        as? NSString
        let savedBackground:NSString?   = record.objectForKey(VNSceneBackgroundToShowKey)   as? NSString
        let savedSpeakerName:NSString?  = record.objectForKey(VNSceneSpeakerNameToShowKey)  as? NSString
        let savedSpeech:NSString?       = record.objectForKey(VNSceneSpeechToDisplayKey)    as? NSString
        let showSpeechKey:NSNumber?     = record.objectForKey(VNSceneShowSpeechKey)         as? NSNumber
        let musicShouldLoop:NSNumber?   = record.objectForKey(VNSceneMusicShouldLoopKey)    as? NSNumber
        let savedBackgroundX:NSNumber?  = record.objectForKey(VNSceneBackgroundXKey)        as? NSNumber
        let savedBackgroundY:NSNumber?  = record.objectForKey(VNSceneBackgroundYKey)        as? NSNumber
        let screenSize:CGSize           = SMScreenSizeInPoints(); // Screensize is loaded to help position UI elements
    
        // This determines whether or not the speechbox will be shown. By default, the speechbox is hidden
        // until a point in the script manually tells it to be shown, but when loading from a saved game,
        // it's necessary to know whether or not the box should be shown already
        if( showSpeechKey != nil ) {
    
            if( showSpeechKey!.boolValue == false ) {
                speechBox!.alpha = 0.1
            } else {
                speechBox!.alpha = 1.0
            }
        }
    
        // Load speaker name (if any exists)
        if( savedSpeakerName != nil ) {
            //speaker!.text = savedSpeakerName;
            speaker!.text = savedSpeakerName as! String
        }
    
        // Load speech data (if any exists)
        if( savedSpeech != nil ) {
    
            //[speech setString:savedSpeech)
            speech!.text = savedSpeech as! String
        }
    
        //if( self.wasJustLoadedFromSave == YES )
        if wasJustLoadedFromSave == true {
            //[speech setText:@" ") // Use empty text as the default
            speech!.text = " "
        }
  
        // Load background image (CCSprite)
        if( savedBackground != nil ) {
    
            // Create/load saved background coordinates
            var backgroundX = screenSize.width  * 0.5; // By default, the background would be positioned in the middle of the screen
            var backgroundY = screenSize.height * 0.5;
            
            // Check for custom background coordinates
            if( savedBackgroundX != nil ) {
                backgroundX = CGFloat(savedBackgroundX!.doubleValue)
            }
            if( savedBackgroundY != nil ) {
                backgroundY = CGFloat(savedBackgroundY!.doubleValue)
            }
            
            // Create and add background image node
            let background:SKSpriteNode = SKSpriteNode(imageNamed:savedBackground! as String)
            background.position = CGPointMake( backgroundX, backgroundY )
            background.zPosition = VNSceneBackgroundLayer
            background.name = VNSceneTagBackground
            addChild( background )
        }
    
        // Load any music that was saved
        if( loadedMusic != nil ) {
        
            var loopFlag = true // Default value provided in case the "should loop" flag doesn't couldn't be loaded
            
            if musicShouldLoop != nil {
                loopFlag = musicShouldLoop!.boolValue
            }
    
            isPlayingMusic = true;
            
            playBGMusic(loadedMusic! as String, willLoopForever: loopFlag)
        }
    
        // Check if any sprites need to be displayed
        if( savedSprites != nil ) {

            print("[VNScene] Sprite data was found in the saved game data.")

            // Check each entry of sprite data that was found, and start loading them into memory and displaying them onto the screen.
            // In theory, the process should be fast enough (and the number of sprites FEW enough) that the user shouldn't notice any delays.
            //for( NSDictionary* spriteData in savedSprites ) {
            for spriteData in savedSprites! {

                // Grab sprite data from dictionary
                let spriteFilename:NSString = spriteData.objectForKey("name") as! NSString
                print("[VNScene] Restoring saved sprite named: \(spriteFilename)");

                // Load CCSprite object and set its coordinates
                let spriteXValue = spriteData.objectForKey("x") as! NSNumber
                let spriteYValue = spriteData.objectForKey("y") as! NSNumber
                let spriteX:CGFloat = CGFloat(spriteXValue.doubleValue) // Load coordinates from dictionary
                let spriteY:CGFloat = CGFloat(spriteYValue.doubleValue)
                
                let sprite          = SKSpriteNode(imageNamed: spriteFilename as String)
                sprite.position     = CGPointMake(spriteX, spriteY)
                sprite.zPosition    = VNSceneCharacterLayer
                addChild(sprite)
                
                // Finally, add the sprite to the 'sprites' dictionary
                sprites.setValue(sprite, forKey: spriteFilename as String);
            }
        }
        
        // Load typewriter text information
        if let TWValueForSpeed = record.objectForKey(VNSceneTypewriterTextSpeed) as? NSNumber {
            TWSpeedInCharacters = TWValueForSpeed.integerValue
        }
        if let TWValueForSkip = record.objectForKey(VNSceneTypewriterTextCanSkip) as? NSNumber {
            TWCanSkip = TWValueForSkip.boolValue
        }
        self.updateTypewriterTextSettings()
    }
    
    // Loads the default, hard-coded values for the view / UI settings dictionary.
    //- (void)loadDefaultViewSettings
    func loadDefaultViewSettings() {
        
        let fontSize                = VNSceneViewFontSize;
        let iPadFontSizeMultiplier  = 1.5; // Determines how much larger the "speech text" and speaker name will be on the iPad
        let dialogueBoxName:String  = VNSceneViewTalkboxName;
    
        //if( viewSettings == nil ) {
        //    viewSettings = NSMutableDictionary()
        //}
        
        // Manually enter the default data for the UI
        viewSettings.setValue(1.0, forKey: VNSceneViewDefaultBackgroundOpacityKey)
        viewSettings.setValue(0.0, forKey: VNSceneViewSpeechBoxOffsetFromBottomKey)
        viewSettings.setValue(0.5, forKey: VNSceneViewSpriteTransitionSpeedKey)
        viewSettings.setValue(0.5, forKey: VNSceneViewTextTransitionSpeedKey)
        viewSettings.setValue(0.5, forKey: VNSceneViewNameTransitionSpeedKey)
        viewSettings.setValue(10.0, forKey: VNSceneViewSpeechHorizontalMarginsKey)
        viewSettings.setValue(30.0, forKey: VNSceneViewSpeechVerticalMarginsKey)
        viewSettings.setValue(0.0, forKey: VNSceneViewSpeechOffsetXKey)
        viewSettings.setValue((fontSize * 2), forKey: VNSceneViewSpeechOffsetYKey)
        viewSettings.setValue(0.0, forKey: VNSceneViewSpeakerNameXOffsetKey)
        viewSettings.setValue(0.0, forKey: VNSceneViewSpeakerNameYOffsetKey)
        viewSettings.setValue((fontSize), forKey: VNSceneViewFontSizeKey) // Was 'fontSize'; changed due to iPad font multiplier
        viewSettings.setValue(dialogueBoxName, forKey: VNSceneViewSpeechBoxFilenameKey)
        viewSettings.setValue("choicebox.png", forKey: VNSceneViewButtonFilenameKey)
        viewSettings.setValue("Helvetica", forKey: VNSceneViewFontNameKey)
        viewSettings.setValue((iPadFontSizeMultiplier), forKey: VNSceneViewMultiplyFontSizeForiPadKey) // This is used for the iPad
    
        // Create default settings for whether or not the "override from save" values should take place.
        viewSettings.setValue(true, forKey:VNSceneViewOverrideSpeakerFontKey)
        viewSettings.setValue(true, forKey:VNSceneViewOverrideSpeakerSizeKey)
        viewSettings.setValue(true, forKey:VNSceneViewOverrideSpeechFontKey)
        viewSettings.setValue(true, forKey:VNSceneViewOverrideSpeechSizeKey)
    
        let buttonTouchedColorsDict = NSDictionary(dictionary: ["r":0, "g":0, "b":255]) // BLUE <- r0, g0, b255
        let buttonUntouchedColorsDict = NSDictionary(dictionary: ["r":0, "g":0, "b":0]) // BLACK <- r0, g0, b0

        viewSettings.setValue(buttonTouchedColorsDict, forKey:VNSceneViewButtonsTouchedColorsKey)
        viewSettings.setValue(buttonUntouchedColorsDict, forKey:VNSceneViewButtonUntouchedColorsKey)
    
        // Load other settings
        viewSettings.setValue(NSNumber(bool: false), forKey:VNSceneViewNoSkipUntilTextShownKey)
    }
    
    // Actually loads images and text for the UI (as opposed to just loading information ABOUT the UI)
    func loadUI() {
        
        // Load the default settings if they don't exist yet. If there's custom data, the default settings will be overwritten.
        if( viewSettings.count < 1 ) {
            print("[VNScene] Loading default view settings.");
            loadDefaultViewSettings()
        }
    
        // Get screen size data; getting the size/coordiante data is very important for placing UI elements on the screen
        let widthOfScreen = self.frame.size.width;
    
        // Check if this is on an iPad, and if the default font size should be adjusted to compensate for the larger screen size
        //if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
        if( UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad ) {
    
            let multiplyFontSizeForiPadFactor:NSNumber? = viewSettings.objectForKey(VNSceneViewMultiplyFontSizeForiPadKey) as? NSNumber // Default is 1.5x
            let standardFontSize:NSNumber? = viewSettings.objectForKey(VNSceneViewFontSizeKey) as? NSNumber // Default value is 17.0
            
            if( multiplyFontSizeForiPadFactor != nil && standardFontSize != nil ) {

                let fontFactor = multiplyFontSizeForiPadFactor!.doubleValue //[multiplyFontSizeForiPadFactor floatValue)
                let fontSize = (standardFontSize!.doubleValue) * fontFactor; // Default is standardFontSize * 1.5
    
                viewSettings.setObject(NSNumber(double: fontSize), forKey:VNSceneViewFontSizeKey)
    
                // The value for the offset key is reset because the font size may have changed, and offsets are affected by this.
                viewSettings.setValue(NSNumber(double: (fontSize * 2)), forKey:VNSceneViewSpeechOffsetYKey)
            }
        }
    
        // Part 1: Create speech box, and then position it at the bottom of the screen (with a small margin, if one exists).
        //         The default setting is to have NO margin/space, meaning the bottom of the box touches the bottom of the screen.
        
        let speechBoxFile:NSString      = viewSettings.objectForKey(VNSceneViewSpeechBoxFilenameKey) as! NSString
        let boxToBottomValue:NSNumber   = viewSettings.objectForKey(VNSceneViewSpeechBoxOffsetFromBottomKey) as! NSNumber
        let boxToBottomMargin:Double    = boxToBottomValue.doubleValue
        // Create speechbox sprite node and set its data
        speechBox                       = SKSpriteNode(imageNamed: speechBoxFile as String)
        let speechBoxX                  = CGFloat(widthOfScreen * 0.5 )
        let speechBoxHalfHeight         = speechBox!.size.height * 0.5;
        let speechBoxY                  = CGFloat( speechBoxHalfHeight + CGFloat(boxToBottomMargin) )
        speechBox!.position             = CGPointMake(speechBoxX, speechBoxY)
        speechBox!.zPosition            = VNSceneUILayer
        speechBox!.name                 = VNSceneTagSpeechBox
        addChild(speechBox!)
        
        if speechBox == nil {
            print("[VNScene] WARNING: Speechbox could not be initialized.");
        }
    
        // Save speech box position in the settings dictionary; this is useful in case you need to restore it to its default position later
        viewSettings.setValue( NSNumber(double: Double(speechBox!.position.x)), forKey:"speechbox x")
        viewSettings.setValue( NSNumber(double: Double(speechBox!.position.y)), forKey:"speechbox y")
    
        // Hide the speech-box by default.
        speechBox!.alpha = 0;
    
        // It's possible that the speechbox sprite may be wider than the width of the screen (this can happen if a
        // speechbox designed for the iPhone 5 is shown on an iPhone 4S or earlier). As the speech text's boundaries
        // are based (by default, at least) on the width and height of the speechbox sprite, it may be necessary to
        // pretend that the speechbox is smaller in order to fit it on a pre-iPhone5 screen.
        var widthOfSpeechBox = speechBox!.size.width;
        let heightOfSpeechBox = speechBox!.size.height;
        if( widthOfSpeechBox > widthOfScreen ) {
            widthOfSpeechBox = widthOfScreen; // Limit the width to whatever the screen's width is
        }
    
        // Part 2: Create the speech label.
        // The "margins" part is tricky. When generating the size for the CCLabelTTF object, it's important to pretend
        // that the margins value is twice as large (as what's stored), since the label's position won't be in the
        // exact center of the speech box, but slightly to the right and down, to create "margins" between speech and
        // the box it's displayed in.
        let verticalMarginValue     = viewSettings.objectForKey(VNSceneViewSpeechVerticalMarginsKey) as! NSNumber
        let horizontalMarginValue   = viewSettings.objectForKey(VNSceneViewSpeechHorizontalMarginsKey) as! NSNumber
        
        let verticalMargins     = CGFloat(verticalMarginValue.doubleValue)
        let horizontalMargins   = CGFloat(horizontalMarginValue.doubleValue)
        // Width multiplier is used for creating margins (when displaying the speech text). Due to differences in size,
        // the exact value changes between the iPhone and the iPad.
        var widthMultiplierValue:CGFloat = 4.0;
        //if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
        if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad {
            widthMultiplierValue = 6.0;
        }
    
        let speechSizeWidth = widthOfSpeechBox - (horizontalMargins * widthMultiplierValue)
        let speechSizeHeight = heightOfSpeechBox - (verticalMargins * 2.0)
        // Set dimensions
        let speechSize = CGSizeMake( speechSizeWidth, speechSizeHeight )
        let fontSizeValue = viewSettings.objectForKey(VNSceneViewFontSizeKey) as! NSNumber
        let fontSize = CGFloat( fontSizeValue.doubleValue )
    
        // Now actually create the speech label. By default, it's just empty text (until a character/narrator speaks later on)
        //speech = [DSMultilineLabelNode labelNodeWithFontNamed:[viewSettings.objectForKey(VNSceneViewFontNameKey])
        let fontNameValue = viewSettings.objectForKey(VNSceneViewFontNameKey) as! NSString
        speech = DSMultilineLabelNode(fontNamed: fontNameValue as String)
        speech!.text = " ";
        speech!.fontSize = fontSize;
        speech!.paragraphWidth = (speechSize.width * 0.92) - (horizontalMargins * widthMultiplierValue);
    
        // Adjust for iPad size differences
        //if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
        if( UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad ) {
            speech!.paragraphWidth = (speechSize.width * 0.94) - (horizontalMargins * widthMultiplierValue);
        }
    
        // Make sure that the position is slightly off-center from where the textbox would be (plus any other offsets that may exist).
        let speechXOffset = (viewSettings.objectForKey(VNSceneViewSpeechOffsetXKey) as! NSNumber).doubleValue
        let speechYOffset = (viewSettings.objectForKey(VNSceneViewSpeechOffsetYKey) as! NSNumber).doubleValue
        let originalSpeechPosX = CGFloat(speechBox!.size.width * 0.5) + CGFloat(speechXOffset)
        let originalSpeechPosY = speechBox!.size.height * 0.5 + CGFloat(verticalMargins) - CGFloat(speechYOffset)
        //CGPoint originalSpeechPos = CGPointMake( speechBox!.size.width * 0.5 /* + horizontalMargins */ + speechXOffset,
        //  speechBox!.size.height * 0.5 + verticalMargins - speechYOffset );
        let originalSpeechPos = CGPointMake(originalSpeechPosX, originalSpeechPosY)
    
        let bottomLeftCornerOfSpeechBox = SMPositionOfBottomLeftCornerOfParentNode(speechBox!);
        speech!.position = SMPositionAddTwoPositions(originalSpeechPos, second: bottomLeftCornerOfSpeechBox);
        speech!.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        speech!.zPosition = VNSceneTextLayer;
        speech!.name = VNSceneTagSpeechText;
        //[speechBox addChild:speech)
        speechBox!.addChild(speech!)
        
        /** COPY TO TWINVISIBLE TEXT **/
        TWInvisibleText = DSMultilineLabelNode(fontNamed: fontNameValue as String)
        TWInvisibleText!.text = " ";
        TWInvisibleText!.fontSize = speech!.fontSize
        TWInvisibleText!.paragraphWidth = speech!.paragraphWidth
        TWInvisibleText!.position = speech!.position
        TWInvisibleText!.horizontalAlignmentMode = speech!.horizontalAlignmentMode
        TWInvisibleText!.zPosition = speech!.zPosition
        TWInvisibleText!.alpha = 0.0; // make sure this really is invisible
        speechBox!.addChild(TWInvisibleText!)
    
        // Part 3: Create speaker label
        // But first, figure out all the offsets and sizes.
        var speakerNameOffsets  = CGPointMake( 0.0, 0.0 );
        let speakerSize         = CGSizeMake( widthOfSpeechBox  * 0.99, speechBox!.size.height * 0.95  );
    
        let speakerNameOffsetXValue:NSNumber? = viewSettings.objectForKey(VNSceneViewSpeakerNameXOffsetKey) as? NSNumber
        let speakerNameOffsetYValue:NSNumber? = viewSettings.objectForKey(VNSceneViewSpeakerNameYOffsetKey) as? NSNumber
        if( speakerNameOffsetXValue != nil ) {
            speakerNameOffsets.x = CGFloat(speakerNameOffsetXValue!.doubleValue)
        }
        if( speakerNameOffsetYValue != nil ) {
            speakerNameOffsets.y = CGFloat(speakerNameOffsetYValue!.doubleValue)
        }
    
    // Add the speaker to the speech-box. The "name" is just empty text by default, until an actual name is provided later.
    //speaker = [DSMultilineLabelNode labelNodeWithFontNamed:[viewSettings.objectForKey(VNSceneViewFontNameKey])
        speaker = DSMultilineLabelNode(fontNamed:fontNameValue as String)
        speaker!.text = " ";
        speaker!.fontSize = CGFloat(fontSize * 1.1)
        speaker!.paragraphWidth = speakerSize.width;
        speaker!.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left;
    
        // Position the label and then add it to the display
        let speakerPosX = (speechBox!.frame.size.width * -0.5) + (speaker!.frame.size.width * 0.5)
        let speakerPosY = speechBox!.frame.size.height
        speaker!.position = CGPointMake( speakerPosX, speakerPosY );
        speaker!.zPosition = VNSceneTextLayer;
        speaker!.name = VNSceneTagSpeakerName;
        speechBox!.addChild(speaker!);
    
        // Part 4: Load the button colors
        // First load the default colors
        buttonUntouchedColors = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0) // black
        buttonTouchedColors = UIColor(red: 0, green: 0, blue: 1.0, alpha: 1.0) // blue
    
        // Grab dictionaries from view settings
        let buttonUntouchedColorsDict:NSDictionary? = viewSettings.objectForKey(VNSceneViewButtonUntouchedColorsKey) as? NSDictionary
        let buttonTouchedColorsDict:NSDictionary? = viewSettings.objectForKey(VNSceneViewButtonsTouchedColorsKey) as? NSDictionary
    
        // Copy values from the dictionary
        if( buttonUntouchedColorsDict != nil ) {
            //println("[VNScene] Untouched buttons colors settings = %@", buttonUntouchedColorsDict);
            //UIColor* untouchedColor  = SMColorFromUnsignedCharRGB([[buttonUntouchedColorsDict.objectForKey(@"r"] unsignedCharValue],
                //[[buttonUntouchedColorsDict.objectForKey(@"g"] unsignedCharValue],
                //[[buttonUntouchedColorsDict.objectForKey(@"b"] unsignedCharValue]);
            
            let untouchedR = (buttonUntouchedColorsDict!.objectForKey("r") as! NSNumber).integerValue
            let untouchedG = (buttonUntouchedColorsDict!.objectForKey("g") as! NSNumber).integerValue
            let untouchedB = (buttonUntouchedColorsDict!.objectForKey("b") as! NSNumber).integerValue
            
            let untouchedColor = SMColorFromUnsignedCharRGB(untouchedR, g: untouchedG, b: untouchedB)
            
            buttonUntouchedColors = untouchedColor
            print("[VNScene] Button untouched colors set to \(buttonUntouchedColors)")
        }
        
        if( buttonTouchedColorsDict != nil ) {
            //println("[VNScene] Touched buttons colors settings = %@", buttonTouchedColorsDict);
            
            let touchedR = (buttonTouchedColorsDict!.objectForKey("r") as! NSNumber).integerValue
            let touchedG = (buttonTouchedColorsDict!.objectForKey("g") as! NSNumber).integerValue
            let touchedB = (buttonTouchedColorsDict!.objectForKey("b") as! NSNumber).integerValue
            
            let touchedColor = SMColorFromUnsignedCharRGB(touchedR, g: touchedG, b: touchedB)
            buttonTouchedColors = touchedColor
            
            /*
            UIColor* touchedColor = SMColorFromUnsignedCharRGB([[buttonTouchedColorsDict.objectForKey(@"r"] unsignedCharValue],
            [[buttonTouchedColorsDict.objectForKey(@"g"] unsignedCharValue],
            [[buttonTouchedColorsDict.objectForKey(@"b"] unsignedCharValue]);
            buttonTouchedColors = [touchedColor copy)
                */
        }
    
        // Part 5: Load transition speeds
        spriteTransitionSpeed   = (viewSettings.objectForKey(VNSceneViewSpriteTransitionSpeedKey) as! NSNumber).doubleValue
        speechTransitionSpeed   = (viewSettings.objectForKey(VNSceneViewTextTransitionSpeedKey) as! NSNumber).doubleValue
        speakerTransitionSpeed  = (viewSettings.objectForKey(VNSceneViewNameTransitionSpeedKey) as! NSNumber).doubleValue
    
        // Part 6: Load overrides, if any are found
        let overrideSpeechFont:NSString?    = record.objectForKey(VNSceneOverrideSpeechFontKey) as? NSString
        let overrideSpeakerFont:NSString?   = record.objectForKey(VNSceneOverrideSpeakerFontKey) as? NSString
        let overrideSpeechSize:NSNumber?    = record.objectForKey(VNSceneOverrideSpeechSizeKey) as? NSNumber
        let overrideSpeakerSize:NSNumber?   = record.objectForKey(VNSceneOverrideSpeakerSizeKey) as? NSNumber
    
        let shouldOverrideSpeechFont = (viewSettings.objectForKey(VNSceneViewOverrideSpeechFontKey) as! NSNumber).boolValue
        let shouldOverrideSpeechSize = (viewSettings.objectForKey(VNSceneViewOverrideSpeechSizeKey) as! NSNumber).boolValue
        let shouldOverrideSpeakerFont = (viewSettings.objectForKey(VNSceneViewOverrideSpeakerFontKey) as! NSNumber).boolValue
        let shouldOverrideSpeakerSize = (viewSettings.objectForKey(VNSceneViewOverrideSpeakerSizeKey) as! NSNumber).boolValue
    
        if( shouldOverrideSpeakerFont && overrideSpeakerFont != nil ) {
            speaker!.fontName = overrideSpeakerFont! as String
        }
        if( shouldOverrideSpeakerSize && overrideSpeakerSize != nil ) {
            speaker!.fontSize = CGFloat(overrideSpeakerSize!.doubleValue)
        }
        if( shouldOverrideSpeechFont && overrideSpeechFont != nil ) {
            speech!.fontName = overrideSpeechFont! as String
        }
        if( shouldOverrideSpeechSize && overrideSpeechSize != nil ) {
            speech!.fontSize = CGFloat(overrideSpeechSize!.doubleValue)
        }
    
        // Part 7: Load extra features
        let blockSkippingUntilTextIsDone:NSNumber? = viewSettings.objectForKey(VNSceneViewNoSkipUntilTextShownKey) as? NSNumber
        if( blockSkippingUntilTextIsDone != nil ) {
            noSkippingUntilTextIsShown = blockSkippingUntilTextIsDone!.boolValue
        }
    }
    
    // Removes unused character sprites (CCSprite objects) from memory.
    //- (void)removeUnusedSprites
    func removeUnusedSprites() {
        
        // Check if there are no unused sprites to begin with
        if( spritesToRemove.count < 1 ) {
            return
        }
    
        print("[VNScene] Will now remove unused sprites - \(spritesToRemove.count) found.")
    
        // Get all the CCSprite objects in the array and then remove them, starting from the last item and ending with the first.
        //for( NSInteger i = (spritesToRemove.count - 1); i >= 0; i-- ) {
        for var i = (spritesToRemove.count - 1); i >= 0; i--  {
    
            //SKSpriteNode* sprite = [spritesToRemove objectAtIndex:i)
            let sprite:SKSpriteNode = spritesToRemove.objectAtIndex(i) as! SKSpriteNode
    
            // If the sprite has no parent node (and is marked as safe to remove), then it's time to get rid of it
            //if( sprite.parent != nil && [sprite.name caseInsensitiveCompare:VNSceneSpriteIsSafeToRemove] == NSOrderedSame) {
            if( sprite.parent != nil && sprite.name!.caseInsensitiveCompare(VNSceneSpriteIsSafeToRemove) == NSComparisonResult.OrderedSame ) {
    
                spritesToRemove.removeObject(sprite) // Remove from array also
                sprite.removeFromParent()
            }
        }
    }
    
    // This takes all the "active" sprites and moves them to the "inactive" list. If you really want to remove them from memory, you
    // should call 'removeUnusedSprites' soon afterwards; that will actually remove the CCSprite objects from RAM.
    //- (void)markActiveSpritesAsUnused
    func markActiveSpritesAsUnused() {
        
        if sprites.count < 1 {
            return
        }
    
        // Grab all the sprites (by name or "key") and relocate them to the "inactive sprites" list
        //for( NSString* spriteName in [sprites allKeys] ) {
        for spriteName in sprites.allKeys {
    
            let spriteToRelocate  = sprites.objectForKey(spriteName) as! SKSpriteNode    // Grab sprite from active sprites dictionary
            spriteToRelocate.alpha          = 0.0;                                      // Mark as invisble/inactive (inactive as far as VNScene is concerned)
            spriteToRelocate.name           = VNSceneSpriteIsSafeToRemove;              // Mark as definitely unused
            
            spritesToRemove.addObject(spriteToRelocate)                                 // Push to inactive sprites array
            sprites.removeObjectForKey(spriteName)                                      // Remove from "active sprites" dictionary
        }
    }
    
    // Currently, this removes "unused" character sprites, plus all audio. The name may be misleading, since it doesn't
    // remove "active" character sprites or the background.
    //- (void)purgeDataCreatedByScene
    func purgeDataCreatedByScene() {
        
        markActiveSpritesAsUnused()         // Mark all sprites as being unused
        removeUnusedSprites()               // Remove the "unused" sprites
        spritesToRemove.removeAllObjects()  // Free from memory
        sprites.removeAllObjects()          // Array now unnecessary; any remaining child nodes will be released from memory in this function
    
        // Check if any sounds were loaded; they should be removed by this function.
        if( soundsLoaded.count > 0 ) {
            soundsLoaded.removeAllObjects()
        }
    
        // Unload any music that may be playing.
        if( isPlayingMusic ) {
            //[[OALSimpleAudio sharedInstance] stopBg)
            //[self stopBGMusic)
            stopBGMusic()
            isPlayingMusic = false; // Make sure this is set to NO, since the function might be called more than once!
        }
    
        // Now, forcibly get rid of anything that might have been missed
        //if( self.children && self.children.count > 0 ) {
        if self.children.count > 0 {
            print("[VNScene] Will now forcibly remove all child nodes of this layer.");
            removeAllChildren()
            print("[VNScene] All child nodes have been removed.");
        }
    }
    
    // MARK: Misc and Utility
    
    func updateTypewriterTextSettings() {
        
        if TWSpeedInCharacters <= 0 {
            TWModeEnabled = false
            TWTimer = 0
        } else {
            
            TWModeEnabled = true
            
            // Calculate speed in seconds based on characters per second
            let charsPerSecond = Double(TWSpeedInCharacters)
            TWSpeedInSeconds = (60.0) / charsPerSecond; // at 60fps this is 60/characters-per-second
            
            let speedInFrames = (60.0) * TWSpeedInSeconds;
            TWSpeedInFrames = Int(speedInFrames)
            TWTimer = 0; // This gets reset
            
            print("Typewriter Text - speed in seconds: \(TWSpeedInSeconds) | speed in frames: \(TWSpeedInFrames)");
        }
        
        record.setValue(NSNumber(integer: TWSpeedInCharacters), forKey: VNSceneTypewriterTextSpeed)
        record.setValue(NSNumber(bool: TWCanSkip), forKey: VNSceneTypewriterTextCanSkip)
    }
    
    func updateTypewriterTextDisplay()
    {
        if TWSpeedInCharacters < 1 {
            return;
        }
        
        var shouldRedrawText = false; // Determines whether or not to go through the trouble of recalculating text node positions
        
        // Used to calculate how many characters to display (in each frame)
        let currentChars = Double(TWNumberOfCurrentCharacters)
        let charsPerSecond = Double(TWSpeedInCharacters)
        let charsPerFrame = (charsPerSecond / 60.0)
        let c = currentChars + charsPerFrame
        
        // Convert back to integer (from the more precise Double)
        TWNumberOfCurrentCharacters = Int(c)
        
        // Clamp excessive min-max values
        if TWNumberOfCurrentCharacters < 0 {
            TWNumberOfCurrentCharacters = 0
        } else if TWNumberOfCurrentCharacters > TWNumberOfTotalCharacters {
            TWNumberOfCurrentCharacters = TWNumberOfTotalCharacters
        }

        // The "previous number" counter is used to ensure that changes to the display are only made when it's necessary
        // (in this case, when the value changes for good) instead of possibly every single frame.
        if( TWNumberOfCurrentCharacters > TWPreviousNumberOfCurrentChars ) {
            // Actually commit new values to display
            let numberOfCharsToUse = TWNumberOfCurrentCharacters;
            
            let TWIndex: String.Index = TWFullText.startIndex.advancedBy(numberOfCharsToUse)
            TWCurrentText = TWFullText.substringToIndex(TWIndex)
            
            if speech != nil {
                speech!.text = TWCurrentText
            }
            
            // Update "previous counter" with the new value
            TWPreviousNumberOfCurrentChars = TWNumberOfCurrentCharacters;
            shouldRedrawText = true
        }
        
        if shouldRedrawText == true {
            // Also change the text position so it doesn't get all weird; TWInvisibleText is used as a guide for positioning
            speech!.size = TWInvisibleText!.size
            speech!.paragraphWidth = TWInvisibleText!.paragraphWidth
            speech!.horizontalAlignmentMode = TWInvisibleText!.horizontalAlignmentMode
            speech!.position = TWInvisibleText!.position
            
            var someX = TWInvisibleText!.position.x
            var someY = TWInvisibleText!.position.y
            
            someX = someX + (speech!.size.width * 0.5)
            someY = someY - (speech!.size.height * 0.5)
            
            speech!.position = CGPointMake(someX, someY)
        }
    }
    
    // The set/clear effect-running-flag functions exist so that Cocos2D can call them after certain actions
    // (or sequences of actions) have been run. The "effect is running" flag is important, since it lets VNScene
    // know when it's safe (or unsafe) to do certain things (which might interrupt the effect that's being run).
    func setEffectRunningFlag() {
        
        print("[VNScene] Effect will be running.");
        effectIsRunning = true;
        mode = VNSceneModeEffectIsRunning;
    }
    
    func clearEffectRunningFlag()
    {
        effectIsRunning = false;
        print("[VNScene] Effect is no longer running.");
    }
    
    // Update script info. This consists of index data, the script name, and which conversation/section is the current one
    // being displayed (or run) before the player.
    func updateScriptInfo()
    {
        if( script != nil ) {
            // Save existing script information (indexes, "current" conversation name, etc.) in the record.
            // This overwrites any script information which may already have been stored.
            record.setValue(script!.info(), forKey: VNSceneSavedScriptInfoKey)
        }
    }
    
    // This saves important information (script info, flags, which resources are being used, etc) to SMRecord.
    func saveToRecord()
    {
        print("[VNScene] Saving data to record.");
    
        // Create the default "dictionary to save" that will be passed into SMRecord's "activity dictionary."
        // Keep in mind that the activity dictionary holds the type of activity that the player was engaged in
        // when the game was saved (in this case, the activity is a VN scene), plus any specific details
        // of that activity (in this case, the script's data, which includes indexes, script name, etc.)
        let dictToSave = NSMutableDictionary()
        dictToSave.setValue(VNSceneActivityType, forKey: SMRecordActivityTypeKey)
    
        // Check if the "safe save" exists; if it does, then it should be used instead of whatever the current data is.
        //if( safeSave != nil ) {
        if safeSave.count > 1 {
            
            let localFlags = safeSave.objectForKey("flags") as! NSDictionary
            let localRecord = safeSave.objectForKey("record") as! NSMutableDictionary
            //let recordedFlags = SMRecord.sharedRecord.flags()
            
            //recordedFlags.addEntriesFromDictionary(localFlags)
            SMRecord.sharedRecord.addExistingFlags(localFlags)
            dictToSave.setValue(localRecord, forKey: SMRecordActivityDataKey)
            SMRecord.sharedRecord.setActivityDict(dictToSave)
    
            //[[[SMRecord sharedRecord] flags] addEntriesFromDictionary:[safeSave.objectForKey(@"flags"])
            //[dictToSave setObject:[safeSave.objectForKey(@"record"] forKey:SMRecordActivityDataKey)
            //[[SMRecord sharedRecord] setActivityDict:dictToSave)
            return;
        }
    
        // Save all the names and coordinates of the sprites still active in the scene. This data will be enough
        // to recreate them later on, when the game is loaded from saved data.
        let spritesToSave:NSArray? = spriteDataFromScene()
        
        if( spritesToSave != nil ) {
            record.setValue(spritesToSave!, forKey: VNSceneSpritesToShowKey)
        } else {
            record.removeObjectForKey(VNSceneSpritesToShowKey)
        }
    
        // Load all flag data back to SMRecord. Remember that VNScene doesn't have a monopoly on flag data;
        // other classes and game systems can modify the flags as well!
        //[[SMRecord sharedRecord].flags addEntriesFromDictionary:flags)
        SMRecord.sharedRecord.addExistingFlags(flags)
    
        // Update script data and then load it into the activity dictionary.
        updateScriptInfo()                                          // Update all index and conversation data
        dictToSave.setValue(record, forKey:SMRecordActivityDataKey) // Load into activity dictionary
        SMRecord.sharedRecord.setActivityDict(dictToSave)           // Save the activity dictionary into SMRecord
        SMRecord.sharedRecord.saveToDevice()                        // Save all record data to device memory
    
        print("[VNScene] Data has been saved. Stored data is: \(dictToSave)");
    }
    
    // Create the "safe save." This function usually gets called before VNScene does some sort of volatile/potentially-hazardous
    // operation, like performing effects or presenting the player with choices menus. In case the game needs to be saved during
    // times like this, the data stored in the "safe save" will be the data that's stored in the saved game.
    func createSafeSave()
    {
        if( script == nil ) {
            print("[VNScene] WARNING: Cannot create safe save, as no script information exists.")
            return;
        }
        
        print("[VNScene] Creating safe-save data.");
        updateScriptInfo() // Update index data, conversation name, script filename, etc. to the most recent information
    
        // Save sprite names and coordinates
        let spritesToSave:NSArray? = spriteDataFromScene()
        if( spritesToSave != nil ) {
            record.setValue(spritesToSave, forKey:VNSceneSpritesToShowKey)
        }
    
        // Create dictionary object
        //let flagsAsDictionary = flags.copy() as NSDictionary
        let flagsCopy = NSMutableDictionary(dictionary: flags)
        //let recordCopy = record
        let scriptInfo = script!.info()
        
        safeSave = NSMutableDictionary(dictionary: ["flags":flagsCopy,
            "record":record,
            VNSceneSavedScriptInfoKey:scriptInfo])
        
        /*safeSave = NSMutableDictionary(dictionaryLiteral: flagsCopy, "flags",
                                                       record, "record",
                                                       scriptInfo, VNSceneSavedScriptInfoKey);*/
        /*
        safeSave = NSMutableDictionary(objectsAndKeys: (flags.copy() as NSMutableDictionary), "flags",
                                                        record, "record",
                                                        script!.info(), VNSceneSavedScriptInfoKey); */
    }
    
    func removeSafeSave()
    {
        print("[VNScene] Removing safe-save data.");
        safeSave.removeAllObjects()
    }
    
    // This creates an array that stores all the sprite filenames and coordinates. When the game is loaded from saved data,
    // the sprites can be easily reloaded and repositioned.
    func spriteDataFromScene() -> NSArray?
    {
        //if( sprites == nil || sprites.count < 1 ) {
        if sprites.count < 1 {
            print("[VNScene] No sprite data found in scene.");
            return nil;
        }
    
        print("[VNScene] Retrieving sprite data from scene!");
    
        // Create the "sprites array." Each index in the array holds a dictionary, and each dictionary holds
        // certain data: sprite filename, sprite x coordinate, and sprite y coordinate.
        let spritesArray = NSMutableArray() //[NSMutableArray array)
    
        // Get every single sprite from the 'sprites' dictionary and extract the relevent data from it.
        //for( NSString* spriteName in [sprites allKeys] ) {
        for spriteName in sprites.allKeys {
    
            print("[VNScene] Saving sprite named: \(spriteName)")
            let actualSprite:SKSpriteNode = sprites.objectForKey(spriteName) as! SKSpriteNode //sprites[spriteName)
            let spriteX = NSNumber(double: Double(actualSprite.position.x) ) // Get coordinates; these will be saved to the dictionary.
            let spriteY = NSNumber(double: Double(actualSprite.position.y) )
    
            // Save relevant data (sprite name and coordinates) in a dictionary
            let savedSpriteData = NSDictionary(dictionary: ["name":spriteName,
                "x":spriteX,
                "y":spriteY]);
            
            /*let savedSpriteData = NSDictionary(dictionaryLiteral: spriteName, "name",
                                                               spriteX, "x",
                                                               spriteY, "y")*/
            //NSDictionary* savedSpriteData = @{  @"name" : spriteName,
            //    @"x"    : spriteX,
            //    @"y"    : spriteY };
    
            // Save dictionary data into the array (which will later be saved to a file)
            //[spritesArray addObject:savedSpriteData)
            spritesArray.addObject(savedSpriteData)
        }
    
        //return [NSArray arrayWithArray:spritesArray)
        return NSArray(array: spritesArray)
    }
    
    /** CORE FUNCTIONS **/
    
    //- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
    //override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        for touch in touches {
            
            let touchPos = touch.locationInNode(self)
    
            // During the "choice" sections of the VN scene, any buttons that are touched in the menu will
            // change their background  appearance (to blue, by default), while all the untouched buttons
            // will stay black by default. In both cases, the color of text ON the button remains unchanged.
            if( mode == VNSceneModeChoiceWithJump || mode == VNSceneModeChoiceWithFlag ) {
    
                //if( buttons ) {
                if buttons.count > 0 {
    
                    //for( CCSprite* button in buttons ) {
                    //for( SKSpriteNode* button in buttons ) {
                    for button in buttons {
                        
                        let currentButton = button as! SKSpriteNode
    
                        //if( CGRectContainsPoint(button.frame, touchPos) ) {
                        if CGRectContainsPoint(button.frame, touchPos) == true {
                            currentButton.color = buttonTouchedColors // Turn blue
                        } else {
                            currentButton.color = buttonUntouchedColors // Turn black
                        }
                    }
                }
            }
        }
    } // touchesBegan
    
    //- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
    //override func touchesMoved(touches: NSSet, withEvent event: UIEvent)
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {

        //for( UITouch* touch in touches ) {
        for currentTouch in touches {
            
            let touch:UITouch = currentTouch //as! UITouch
            //CGPoint touchPos = [touch locationInNode:self)
            let touchPos = touch.locationInNode(self)
    
            if( mode == VNSceneModeChoiceWithJump || mode == VNSceneModeChoiceWithFlag ) {
    
                if( buttons.count > 0 ) {
    
                    //for( CCSprite* button in buttons ) {
                    //for( SKSpriteNode* button in buttons ) {
                    for currentButton in buttons {
                        
                        let button:SKSpriteNode = currentButton as! SKSpriteNode
    
                        if( CGRectContainsPoint(button.frame, touchPos) ) {
    
                            //button.color = [[CCColor alloc] initWithCcColor3b:buttonTouchedColors)
                            button.color = buttonTouchedColors;
    
                        } else {
    
                            //button.color = [[CCColor alloc] initWithCcColor3b:buttonUntouchedColors)
                            button.color = buttonUntouchedColors;
                        }
                    }
                }
            }
        }
    }
    
    //- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
    //override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {

        //for( UITouch* touch in touches ) {
        for currentTouch in touches {
            
            let touch:UITouch = currentTouch //as! UITouch
            let touchPos = touch.locationInNode(self)
    
            // Check if this is the "normal mode," in which there are no choices and dialogue is just displayed normally.
            // Every time the user does "Touches Ended" during Normal Mode, VNScene advances to the next command (or line
            // of dialogue).
            if( mode == VNSceneModeNormal ) { // Story mode
    
                // The "just loaded from save" flag is disabled once the user passes the first line of dialogue
                if( self.wasJustLoadedFromSave == true ) {
                    self.wasJustLoadedFromSave = false; // Remove flag
                }
    
                if( noSkippingUntilTextIsShown == false ){
                    
                    var canSkip = true
                    
                    if TWModeEnabled == true && TWCanSkip == false {
                        let lengthOfTWCurrentText = SMStringLength(TWCurrentText)
                        let lengthOfTWFullText = SMStringLength(TWFullText)
                        
                        if lengthOfTWCurrentText < lengthOfTWFullText {
                            canSkip = false
                        }
                    }
                    
                    if canSkip == true {
                        script!.advanceIndex() // Move the script forward
                    }
                } else {
    
                    // Only allow advancing/skipping if there's no text or if the opacity/alpha has reached 1.0
                    //if( speech == nil || speech!.text.length < 1 || speech!.alpha >= 1.0 ) {
                    if SMStringLength(speech!.text) < 1 || speech!.alpha >= 1.0 {
                        script!.advanceIndex()
                    }
                }
    
                // If the current mode is some kind of choice menu, then Touches Ended actually picks a choice (assuming,
                // of course, that the touch landed on a button).
            } else if( mode == VNSceneModeChoiceWithJump || mode == VNSceneModeChoiceWithFlag ) { // Choice menu mode
    
                if( buttons.count > 0 ) {
    
                    //for( int currentButton = 0; currentButton < buttons.count; currentButton++ ) {
                    for var currentButton = 0; currentButton < buttons.count; currentButton++ {
    
                        //SKSpriteNode* button = [buttons objectAtIndex:currentButton)
                        let button:SKSpriteNode = buttons.objectAtIndex(currentButton) as! SKSpriteNode
    
                        if( CGRectContainsPoint(button.frame, touchPos) ) {
    
                            button.color = buttonTouchedColors;
                            buttonPicked = currentButton;   // Remember the button's index for later. 'buttonPicked' is normally set to -1, but
                                                            // when a button is pressed, then the button's index number is copied over to 'buttonPicked'
                                                            // so that VNScene will know which button was pressed.
                        } else {
    
                            button.color = buttonUntouchedColors;
                        }
                    }
                }
            }
        }
    }
    
    //- (void)update:(NSTimeInterval)currentTime
    override func update(currentTime: NSTimeInterval)
    {
        // Check if the scene is finished
        if( script!.isFinished == true ) {
    
            // Print the 'quitting time' message
            print("[VNScene] The 'Script Is Finished' flag is triggered. Now moving to 'end of script' mode.");
            mode = VNSceneModeEnded; // Set 'end' mode
        }
    
        //switch( mode ) {
        switch mode {
    
        // Resources need to be loaded?
        case VNSceneModeLoading:
    
            print("[VNScene] Now in 'loading mode'");
    
            // Do any last-minute loading operations here
            //[self loadSavedResources)
            loadSavedResources()
    
            // Switch to 'clean-up loading' mode
            mode = VNSceneModeFinishedLoading;
    
        // Have all the resources and script data just finished loading?
        case VNSceneModeFinishedLoading:
    
            print("[VNScene] Finished loading.");
    
            // Switch to "Normal Mode" (which is where the dialogue and normal script processing happen)
            mode = VNSceneModeNormal;
    
        // Is everything just being processed as usual?
        case VNSceneModeNormal:
    
            // Check if there's any safe-save data. When the scene has switched over to Normal Mode, then the safe-save
            // becomes unnecessary, since the conditions that caused it (like certain effects being run) are no longer
            // active. In this case, the safe-save should just be removed so that the normal data can be saved.
            if( safeSave.count > 0 ) {
                //[self removeSafeSave)
                removeSafeSave()
            }
    
            // Take care of normal operations
            //[self runScript) // Process script data
            runScript()
            
            if TWModeEnabled == true {
                // Update typewriter text
                
                /*
                if( TWTimer <= TWSpeedInFrames ) {
                    TWTimer++;
                    self.updateTypewriterTextDisplay()
                }*/
                
                if TWNumberOfCurrentCharacters < TWNumberOfTotalCharacters {
                    TWTimer++
                    self.updateTypewriterTextDisplay()
                }
            }
    
        // Is an effect currently running? (this is normally when the "safe save" data comes into play)
        case VNSceneModeEffectIsRunning:
    
            // Ask the scene view object if the effect has finished. If it has, then it will delete the effect object automatically,
            // and then it will be time for VNScene to return to 'normal' mode.
            if( effectIsRunning == false ) {
    
                //[self removeSafeSave)
                removeSafeSave()
    
                // Change mode
                mode = VNSceneModeNormal;
            }
    
        // Is the player being presented with a choice menu? (the "choice with jump" means that when the user makes a choice,
        // VNScene "jumps" to a different array of dialogue immediately afterwards.)
        case VNSceneModeChoiceWithJump:
    
            // Check if there was any input. Normally, 'buttonPicked' is set to -1, but when a button is pressed,
            // the button's tag (which is always zero or higher) is copied over to 'buttonPicked', and so it's possible
            // to figure out which button was pressed just by seeing what value was stored in 'buttonPicked'
            if( buttonPicked >= 0 ) {
    
                let conversationToJumpTo = choices.objectAtIndex(buttonPicked) as! NSString // The conversation names are stored in the 'choices' array
                script!.changeConversationTo(conversationToJumpTo as String) // Switch to the new "conversation" / dialogue array.
                mode = VNSceneModeNormal; // Go back to Normal Mode (after this has been processed, of course)
    
                // Get rid of any lingering objects in memory
                if( buttons.count > 0 ) {
    
                    //for( SKSpriteNode* button in buttons ) {
                    for currentButton in buttons {
                        
                        let button = currentButton as! SKSpriteNode
                        
                        button.removeAllChildren()
                        //[button removeFromParent)
                        button.removeFromParent()
                    }
                }
    
                //[buttons removeAllObjects)
                buttons.removeAllObjects()
                //buttons = nil;
                buttonPicked = -1; // Reset "which button was pressed" to its default, untouched state
            }
    
        // Is the player being presented with another choice menu? (the "choice with flag" means that when a user makes a choice,
        // VNScene just changes the value of a "flag" or variable that it's keeping track of. Later, when the game is saved, the
        // value of that flag is copied over to SMRecord).
        case VNSceneModeChoiceWithFlag:
    
            if( buttonPicked >= 0 ) {
    
                // Get array elements
                let flagName:NSString?    = choices.objectAtIndex(buttonPicked) as? NSString
                var flagValue:NSNumber?   = choiceExtras.objectAtIndex(buttonPicked) as? NSNumber
                let oldFlag:NSNumber?     = flags.objectForKey(flagName!) as? NSNumber
                
                //id flagName  = [choices objectAtIndex:buttonPicked)
                //id flagValue = [choiceExtras objectAtIndex:buttonPicked)
                //id oldFlag   = [flags.objectForKey(flagName)
    
                // Check if the flag had a previously existing value; if it did, then just add the old value to the new value
                if( oldFlag != nil ) {
                    
                    let oldFlagAsInteger = oldFlag!.integerValue
                    let flagInteger = flagValue!.integerValue
                    
                    let combinedIntegers = oldFlagAsInteger + flagInteger
                    
                    let tempValue = NSNumber(integer: combinedIntegers)
                    
                    flagValue = tempValue
    
                    //id tempValue = [NSNumber numberWithInt:( [oldFlag intValue] + [flagValue intValue] ))
                    //flagValue = tempValue;
                }
    
                // Set the new value of the flag. The change will be made to the "local" flag dictionary, not the
                // global one stored in SMRecord. This is to prevent any save-data conflicts (since it's certainly
                // possible that not all the data in the VNScene will be stored along with the updated flag data)
                //[flags.setValue:flagValue forKey:flagName)
                flags.setValue(flagValue!, forKey: flagName! as String)
    
                // Get rid of any unnecessary objects in memory
                if( buttons.count > 0 ) {
                    //for( SKSpriteNode* button in buttons ) {
                    for currentButton in buttons {
                        
                        let button:SKSpriteNode = currentButton as! SKSpriteNode
                        
                        button.removeAllChildren()
                        button.removeFromParent()
                    }
                }
    
                // Get rid of any lingering data
                buttons.removeAllObjects()
                choices.removeAllObjects()
                choiceExtras.removeAllObjects()
                buttonPicked = -1; // Reset this to the original, untouched value
    
                // Return to 'normal' mode
                mode = VNSceneModeNormal;
            }
            
    
            // In this case, the script has completely finished running, so there's nothing left to do but get rid of any
            // lingering resources, save data back to the global record in SMRecord, and then return to the previous CCScene.
        case VNSceneModeEnded:
    
            if( self.isFinished == false ) {
    
                print("[VNScene] The scene has ended. Flag data will be auto-saved.");
                print("[VNScene] Remaining scene and activity data will be deleted.");
    
                // Save all necessary data
                //SMRecord* theRecord = [SMRecord sharedRecord)
                let theRecord = SMRecord.sharedRecord
                //[theRecord addExistingFlags:flags) // Save flag data (this can overwrite existing flag values)
                theRecord.addExistingFlags(flags)
                //[theRecord resetActivityInformationInDict:theRecord.record) // Remove activity data from record
                theRecord.resetActivityInformationInDict(theRecord.record)
    
                self.isFinished = true; // Mark as finished
                //[self purgeDataCreatedByScene) // Get rid of all data stored by the scene
                purgeDataCreatedByScene()
    
                // Note that popping the scene results in a very sudden transition, so it might help if the script
                // ends with a fade-out, and if the previous scene somehow fades in. Otherwise, the sudden transition
                // might seem TOO sudden.
                if( popSceneWhenDone == true ) {
                    print("[VNScene] VNScene will now ask Cocos2D to pop the current scene.");
                    //[[CCDirector sharedDirector] popScene)
    
                    if( previousScene != nil ) {
                        //[self.view presentScene:self.previousScene)
                        print("[VNScene] Previous scene was found; now attempting to switch to previous scene.")
                        self.view!.presentScene(self.previousScene!)
                    } else {
                        print("[VNScene] WARNING: There is no previous scene to return to.");
                    }
                }
            }
            
        default:
            print("[VNScene] WARNING: Now in unknown state");
        }
    }
    
    // Processes the script (during "Normal Mode"). This function determines whether it's safe to process the script (since there are
    // many times when it might be considered "unsafe," such as when effects are being run, or even if it's something mundane like
    // waiting for user input).
    func runScript() {
        
        if( script == nil ) {
            print("[VNScene] ERROR: Script cannot be run because it has no data.")
            return
        }
        
        var scriptShouldBeRun = true; // This flag is used to run the following loop...
    
        while( scriptShouldBeRun == true ) {
    
            // Check if there's anything that could change this flag
            if( script!.lineShouldBeProcessed() == false ) { // Have enough indexes been processed for now?
                scriptShouldBeRun = false;
            }
            if( mode == VNSceneModeEffectIsRunning ) { // When effects are running, it becomes impossible to reliably process the script
                scriptShouldBeRun = false;
            }
            if( mode == VNSceneModeChoiceWithJump || mode == VNSceneModeChoiceWithFlag ) { // Should a choice be made?
                scriptShouldBeRun = false; // Can't run script while waiting for player input!
            }
    
            // Check if any of the "stop running" conditions were met; in that case the function should just stop
            if( scriptShouldBeRun == false ) {
                return;
            }
    
            /* If the function has made it this far, then it's time to grab more script data and process that */
    
            // Get the current line/command from the script
            //NSArray* currentCommand = [script currentCommand)
            let currentCommand:NSArray? = script!.currentCommand()
    
            // Check if there is no valid data (this might also mean that there are no more commands at all)
            if( currentCommand == nil ) {
                // Print warning message and finish the scene
                print("[VNScene] NOTICE: Script has run out of commands. Switching to 'Scene Ended' mode...");
                mode = VNSceneModeEnded;
                return;
            }
    
            // Helpful output! This is just optional, but it's useful for development (especially for tracking
            // bugs and crashes... hopefully most of those have been ironed out at this point!)
            //println("[%ld] %@ - %@", (long)script.currentIndex, [currentCommand objectAtIndex:0], [currentCommand objectAtIndex:1]);
            //var logstr1:String = currentCommand!.objectAtIndex(0) as String
            //var logstr2:String = currentCommand!.objectAtIndex(1) as String
            //println("[\(script!.currentIndex)] \(logstr1) - \(logstr2)")
    
            //[self processCommand:currentCommand)   // Handle whatever line was just taken from the script
            processCommand(currentCommand!)
            //script.indexesDone++;                   // Tell the script that it's handled yet another line
            script!.indexesDone++
        }
    }
    
    // Returns the position for where the speaker label should be (since the size changes every time the text changes,
    // it has to be repositioned each time).
    //- (CGPoint)updatedSpeakerPosition
    func updatedSpeakerPosition() -> CGPoint
    {
        var widthOfSpeechBox = speechBox!.frame.size.width;
        let heightOfSpeechBox = speechBox!.frame.size.height;
        var speakerNameOffsets = CGPointZero;
    
        // Load speaker offset values
        let speakerNameOffsetXValue:NSNumber? = viewSettings.objectForKey(VNSceneViewSpeakerNameXOffsetKey) as? NSNumber
        let speakerNameOffsetYValue:NSNumber? = viewSettings.objectForKey(VNSceneViewSpeakerNameYOffsetKey) as? NSNumber
        
        if( speakerNameOffsetXValue != nil ) {
            speakerNameOffsets.x = CGFloat(speakerNameOffsetXValue!.doubleValue)
        }
        if( speakerNameOffsetYValue != nil ) {
            speakerNameOffsets.y = CGFloat(speakerNameOffsetYValue!.doubleValue)
        }
        
        if( self.view == nil ) {
            print("[VNScene] ERROR: Cannot get updated speaker position, as this scene's view is invalid.");
            return CGPointZero
        }
    
        let screenSize = self.view!.frame.size
        let boxSize = speechBox!.frame.size;
        var workingArea = boxSize;
    
        // Check if the speech box is actually wider than the screen's width
        if( screenSize.width < boxSize.width ) {
            workingArea.width = screenSize.width;
        }
        widthOfSpeechBox = workingArea.width;
    
        // Find top-left corner of the speech box
        let topLeftCornerOfSpeechBox:CGPoint = CGPointMake( 0.0 - (widthOfSpeechBox * 0.5), 0 + (heightOfSpeechBox * 0.5));
        // Adjust slightly so that the label isn't jammed up against the upper-left corner; there should be a bit of margins
        let adjustment:CGPoint = CGPointMake( widthOfSpeechBox * 0.02, heightOfSpeechBox * -0.05 );
        // Store adjustments
        let cornerPlusAdjustments:CGPoint = SMPositionAddTwoPositions(topLeftCornerOfSpeechBox, second: adjustment);
        // Add custom offsets
        let adjustedPlusOffsets:CGPoint = SMPositionAddTwoPositions(cornerPlusAdjustments, second: speakerNameOffsets);
    
        return adjustedPlusOffsets;
    }
    
    // Since the speech label's size changes every time the text changes, this also has to be repositioned each time
    // a new line of dialogue is shown.
    //- (CGPoint)updatedTextPosition
    func updatedTextPosition() -> CGPoint
    {
        //if( !speech || !speechBox )
        //return CGPointZero;
        
        if( self.view == nil ) {
            print("[VNScene] ERROR: Cannot get updated text position, as this scene's view is invalid.");
            return CGPointZero
        }
    
        var widthOfBox = speechBox!.frame.size.width;
        let heightOfBox = speechBox!.frame.size.height;
    
        let screenSize:CGSize = self.view!.frame.size;
        let boxSize:CGSize = speechBox!.frame.size;
        var workingArea:CGSize = boxSize;
    
        // Check if the speechbox is wider than the screen/view, in which case whichever one is smaller will be used
        if( screenSize.width < boxSize.width ) {
            workingArea.width = screenSize.width;
        }
        widthOfBox = workingArea.width;
    
        //float verticalMargins = [[viewSettings.objectForKey(VNSceneViewSpeechVerticalMarginsKey] floatValue)
        let horizontalMarginsNumber = viewSettings.objectForKey(VNSceneViewSpeechHorizontalMarginsKey) as! NSNumber
        let speechXOffsetNumber = viewSettings.objectForKey(VNSceneViewSpeechOffsetXKey) as! NSNumber
        let horizontalMargins   = CGFloat(horizontalMarginsNumber.doubleValue)
        let speechXOffset       = CGFloat(speechXOffsetNumber.doubleValue)
        //float speechYOffset = [[viewSettings.objectForKey(VNSceneViewSpeechOffsetYKey] floatValue)
    
        //println("verticalMargins = %f, speechYOffset = %f", verticalMargins, speechYOffset);
    
        // Find top-left corner of speechbox (child node will be centered right over the very corner)
        let topLeftCornerOfBox = CGPointMake( 0.0 - (widthOfBox * 0.5), 0 + (heightOfBox * 0.5));
        let textX:CGFloat = topLeftCornerOfBox.x + (widthOfBox * 0.04) + speechXOffset + horizontalMargins; // + speechXOffset + horizontalMargins;
        let textY:CGFloat = topLeftCornerOfBox.y - (heightOfBox * 0.1) - speaker!.frame.size.height;// - verticalMargins - speechYOffset;
    
        return CGPointMake(textX, textY);
    }
    
    /** Script Processing **/
    
    // This is the most important function; it breaks down the data stored in each line of the script and actually
    // does something useful with it.
    //- (void)processCommand:(NSArray *)command
    func processCommand(command: NSArray)
    {
        if( command.count < 1 ) {
            print("[VNScene] Cannot process command as array has insufficient data.")
            return
        }
        
        // Extract some data from the command
        let commandTypeNumber       = command.objectAtIndex(0) as! NSNumber // Command type, always stored as 'int'
        let type:Int                = commandTypeNumber.integerValue
        let param1:AnyObject?       = command.objectAtIndex(1) // Get the first parameter (which might be a string, number, etc)
        
        // Check for an invalid parameter
        if param1 == nil {
            print("[VNScene] ERROR: No parameter detected; all commands must have at least 1 parameter!");
            return;
        }
        
        // Parameter 1 type
        var param1IsString = false
        //var param1IsNumber = false
        
        var parameter1String = ""
        
        //if param1!.isKindOfClass(NSNumber) == true {
        //    param1IsNumber = true
        //}
        if param1!.isKindOfClass(NSString) == true {
            param1IsString = true
        }
        
        // Convert to string
        if param1IsString == true {
            parameter1String = param1! as! String
        }
    
        // Check if the command is really just "display a regular line of text"
        if( type == VNScriptCommandSayLine ) {
    
            if TWModeEnabled == false {
                // Speech opacity is set to zero, making it invisible. Remember, speech is supposed to "fade in"
                // instead of instantly appearing, since an instant appearance can be visually jarring to players.
                speech!.alpha = 0.0;
                //[speech setText:parameter1) // Copy over the text (while the text label is "invisble")
                speech!.text = parameter1String
                //[record.setValue:parameter1 forKey:VNSceneSpeechToDisplayKey) // Copy text to save-game record
                record.setValue(param1, forKey: VNSceneSpeechToDisplayKey) // Copy text to save-game record
        
                // Now have the text fade into full visibility.
                let fadeIn:SKAction = SKAction.fadeInWithDuration(speechTransitionSpeed) //[SKAction fadeInWithDuration:speechTransitionSpeed)
                speech!.runAction(fadeIn)
        
                // If the speech-box isn't visible (or at least not fully visible), then it should fade-in as well
                if( speechBox!.alpha < 0.9 ) {
        
                    //CCActionFadeIn* fadeInSpeechBox = [CCActionFadeIn actionWithDuration:speechTransitionSpeed)
                    //let fadeInSpeechBox = [SKAction fadeInWithDuration:speechTransitionSpeed)
                    let fadeInSpeechBox = SKAction.fadeInWithDuration(speechTransitionSpeed)
                    //[speechBox runAction:fadeInSpeechBox)
                    speechBox!.runAction(fadeInSpeechBox)
                }
                
                speech!.anchorPoint = CGPointMake(0, 1.0);
                //speech!.position = [self updatedTextPosition)
                speech!.position = updatedTextPosition()
                
            } else {
                
                let parameter1AsString = command.objectAtIndex(1) as! NSString
                
                // Reset counter
                TWTimer                     = 0;
                TWFullText                  = parameter1AsString as String
                TWCurrentText               = "";
                TWNumberOfCurrentCharacters = 0;
                TWNumberOfTotalCharacters   = Int( parameter1AsString.length )
                TWPreviousNumberOfCurrentChars = 0;
                
                //[record setValue:parameter1 forKey:VNSceneSpeechToDisplayKey];
                record.setValue(parameter1AsString, forKey: VNSceneSpeechToDisplayKey)
                
                
                speech!.text = " "// parameter1AsString
                speechBox!.alpha = 1.0;
                speech!.anchorPoint = CGPointMake(0, 1.0)
                speech!.position = updatedTextPosition()
                
                TWInvisibleText!.text = parameter1AsString as String
                TWInvisibleText!.anchorPoint = CGPointMake(0, 1.0)
                TWInvisibleText!.position = updatedTextPosition()
                TWInvisibleText!.alpha = 0.0
            }
    
            return;
        }
    
        // Advance the script's index to make sure that commands run one after the other. Otherwise, they will only run one at a time
        // and the user would have to keep touching the screen each time in order for the next command to be run. Except for the
        // "display a line of text" command, most of the commands are designed to run one after the other seamlessly.
        script!.currentIndex++;
    
        // Now, figure out what type of command this is!
        switch( type ) {
    
        // Adds a CCSprite object to the screen; the image is loaded from a file in the app bundle. Currently, VNScene doesn't
        // support texture atlases, so it can only load the WHOLE IMAGE as-is.
        case VNScriptCommandAddSprite:
    
            //NSString* spriteName = parameter1;
            let spriteName = parameter1String
            //BOOL appearAtOnce = [[command objectAtIndex:2] boolValue) // Should the sprite show up at once, or fade in (like text does)
            let parameter2 = command.objectAtIndex(2) as! NSNumber
            let appearAtOnce = parameter2.boolValue
    
            // Check if this sprite already exists, and if it does, then stop the function since there's no point adding the sprite a second time.
            let spriteAlreadyExists:SKSpriteNode? = sprites.objectForKey(spriteName) as? SKSpriteNode
            if( spriteAlreadyExists != nil ) {
                return;
            }
    
            // Try to load the sprite from an image in the app bundle
            //CCSprite* createdSprite = [CCSprite spriteWithImageNamed:spriteName) // Loads from file; sprite-sheets not supported
            //SKSpriteNode* createdSprite = [SKSpriteNode spriteNodeWithImageNamed:spriteName)
            let createdSprite:SKSpriteNode? = SKSpriteNode(imageNamed: spriteName)
            if( createdSprite == nil ) {
                print("[VNScene] ERROR: Could not load sprite named: %@", spriteName);
                return;
            }
    
            // Add the newly-created sprite to the sprite dictionary
            //[sprites.setValue:createdSprite forKey:spriteName)
            sprites.setValue(createdSprite!, forKey: spriteName)
    
            // Position the sprite at the center; the position can be changed later. Usually, the command to change sprite positions
            // is almost immediately right after the command to add the sprite; the commands are executed so quickly that the user
            // shouldn't see any delay.
            createdSprite!.position = SMPositionWithNormalizedCoordinates(0.5, normalizedY: 0.5); // Sprite positioned at screen center
            createdSprite!.zPosition = VNSceneCharacterLayer;
            //[self addChild:createdSprite z:VNSceneCharacterLayer)
            //[self addChild:createdSprite)
            addChild(createdSprite!)
    
            // Right now, the sprite is fully visible on the screen. If it's supposed to fade in, then the opacity is set to zero
            // (making the sprite "invisible") and then it fades in over a period of time (by default, that period is half a second).
            //if( appearAtOnce == NO ) {
            if appearAtOnce == false {
                
                // Make the sprite fade in gradually ("gradually" being a relative term!)
                createdSprite!.alpha = 0.0;
                let fadeIn = SKAction.fadeInWithDuration(spriteTransitionSpeed)
                createdSprite!.runAction(fadeIn)
            } // appearAtOnce
    
        // This "aligns" a sprite so that it's either in the left, center, or right areas of the screen. (This is calculated as being
        // 25%, 50% or 75% of the screen width).
        case VNScriptCommandAlignSprite:
    
            //NSString* spriteName = parameter1;
            let spriteName = parameter1String
            let newAlignment = command.objectAtIndex(2) as! String // "left", "center", "right"
            let duration = command.objectAtIndex(3) as! NSNumber // Default duration is 0.5 seconds; this is stored as an NSNumber (double)
            let durationAsDouble = duration.doubleValue // For when an actual scalar value has to be passed (instead of NSNumber)
            
            var alignmentFactor = CGFloat(0.5) // 0.50 is the center of the screen, 0.25 is left-aligned, and 0.75 is right-aligned

            // STEP ONE: Find the sprite if it exists. If it doesn't, then just stop the function.
            let sprite:SKSpriteNode? = sprites.objectForKey(spriteName) as? SKSpriteNode
            if( sprite == nil ) {
                return;
            }
        
            // STEP TWO: Set the new sprite position
        
            // Check the string to find out if the sprite should be left-aligned or right-aligned instead
            if newAlignment.caseInsensitiveCompare(VNSceneViewSpriteAlignmentLeftString) == NSComparisonResult.OrderedSame {
            
                alignmentFactor = 0.25; // "left"
            
            } else if newAlignment.caseInsensitiveCompare(VNSceneViewSpriteAlignmentRightString) == NSComparisonResult.OrderedSame {
            
                alignmentFactor = 0.75; // "right"
            
            } else if( newAlignment.caseInsensitiveCompare(VNSceneViewSpriteAlignemntFarLeftString) == NSComparisonResult.OrderedSame ) {
            
                alignmentFactor = 0.0; // "far left"
            
            } else if( newAlignment.caseInsensitiveCompare(VNSceneViewSpriteAlignmentFarRightString) == NSComparisonResult.OrderedSame ) {
            
                alignmentFactor = 1.0; // "far right"
            
            } else if( newAlignment.caseInsensitiveCompare(VNSceneViewSpriteAlignmentExtremeLeftString) == NSComparisonResult.OrderedSame ) {
            
                alignmentFactor = -0.5; // "extreme left"
            
            } else if( newAlignment.caseInsensitiveCompare(VNSceneViewSpriteAlignmentExtremeRightString) == NSComparisonResult.OrderedSame ) {
            
                alignmentFactor = 1.5; // "extreme right"
            }
        
            // Tell the view to instantly re-position the sprite
            //float updatedX = [[CCDirector sharedDirector] viewSize].width * alignmentFactor;
            let updatedX = self.frame.size.width * alignmentFactor;
            let updatedY = sprite!.position.y; // Maintain the same height as before
        
            // If the duration is set to "instant" (meaning zero duration), then just move the sprite into position
            // and stop the function
            if( durationAsDouble <= 0.0 ) {
                sprite!.position = CGPointMake( updatedX, updatedY ); // Set new position
                return;
            }
        
            createSafeSave() // Create safe-save before using a move effect on the sprite (safe-saves are always used before effects are run)
        
            // STEP THREE: Make preparations for the "move sprite" effect. Once the actual movement has been completed, then
            //            the action sequence will call 'clearEffectRunningFlag' to let VNScene know that the effect's done.
            //CCActionMoveTo* moveSprite              = [CCActionMoveTo actionWithDuration:durationAsDouble position:CGPointMake(updatedX, updatedY))
            //CCActionCallFunc* clearFlagAction       = [CCActionCallFunc actionWithTarget:self selector:@selector(clearEffectRunningFlag))
            //CCActionSequence* spriteMoveSequence    = [CCActionSequence actions:moveSprite, clearFlagAction, nil)
            let moveSprite = SKAction.moveTo(CGPointMake(updatedX, updatedY), duration:durationAsDouble)
            //let clearFlagAction = SKAction.performSelector(Selector("clearEffectRunningFlag"), onThread: <#NSThread!#>, withObject: <#AnyObject!#>, waitUntilDone: <#Bool#>)
            let clearFlagAction = SKAction.runBlock(self.clearEffectRunningFlag)
            //let spriteMoveSequence = SKAction.sequence(moveSprite, clearFlagAction)
            let spriteMoveSequence = SKAction.sequence([moveSprite, clearFlagAction])
        
            //let clearFlagAction = [SKAction performSelector:@selector(clearEffectRunningFlag) onTarget:self)
            //let spriteMoveSequence = [SKAction sequence:@[moveSprite, clearFlagAction])
        
            // STEP FOUR: Set the "effect running" flag, and then actually perform the CCAction sequence.
            setEffectRunningFlag()
            sprite!.runAction(spriteMoveSequence)
    
        // This command just removes a sprite from the screen. It can be done immediately (though suddenly vanishing is kind of
        // jarring for players) or it can gradually fade from sight.
        case VNScriptCommandRemoveSprite:
    
            let spriteName = parameter1String
            let spriteVanishesImmediately = (command.objectAtIndex(2) as! NSNumber).boolValue //[[command objectAtIndex:2] boolValue)
        
            // Check if the sprite even exists. If it doesn't, just stop the function
            let sprite:SKSpriteNode? = sprites.objectForKey(spriteName) as? SKSpriteNode
            if( sprite == nil ) {
                return;
            }
        
            // Remove the sprite from the sprites array. If the game needs be saved soon right after this command
            // is called, then the now-removed sprite won't be included in the save data.
            sprites.removeObjectForKey(spriteName)
        
            // Check if it should just vanish at once (this should probably be done offscreen because it looks weird
            // if it just happens while the player can still see the sprite).
            if( spriteVanishesImmediately == true ) {
        
                // Remove it from its parent node (if it has one)
                if( sprite!.parent != nil ) {
                    sprite!.removeFromParent()
                }
        
            } else {
        
                // If the sprite shouldn't be removed immediately, then it should be moved to an array of "unused" (or soon-to-be-unused)
                // sprites, and then later deleted.
        
                spritesToRemove.addObject(sprite!) // Add to the sprite-removal array; sprite will be removed later by a function
                sprite!.name = VNSceneSpriteIsSafeToRemove; // Mark the sprite as safe-to-delete
        
                // This sequence of CCActions will cause the sprite to fade out, and then it'll be removed from memory.
                //CCActionFadeOut* fadeOutSprite = [CCActionFadeOut actionWithDuration:spriteTransitionSpeed)
                //CCActionCallFunc* removeSprite = [CCActionCallFunc actionWithTarget:self selector:@selector(removeUnusedSprites))
                //CCActionSequence* spriteRemovalSequence = [CCActionSequence actions:fadeOutSprite, removeSprite, nil)
                let fadeOutSprite = SKAction.fadeOutWithDuration(spriteTransitionSpeed)
                let removeSprite = SKAction.runBlock(self.removeUnusedSprites)
                let spriteRemovalSequence = SKAction.sequence([fadeOutSprite, removeSprite])
                
                sprite!.runAction(spriteRemovalSequence)
            }
    
        // This command is used to move/pan the background around, using the "moveBy" action
        case VNScriptCommandEffectMoveBackground:
    
            // Check if the background even exists to begin with, because otherwise there's no point to any of this!
            //CCSprite* background = (CCSprite*) [self getChildByName:VNSceneTagBackground recursively:false)
            let backgroundSprite:SKSpriteNode? = self.childNodeWithName(VNSceneTagBackground) as? SKSpriteNode
            if( backgroundSprite == nil ) {
                return
            }
            
            let background = backgroundSprite!
            createSafeSave()
            
            let moveByX = command.objectAtIndex(1) as! NSNumber
            let moveByY = command.objectAtIndex(2) as! NSNumber
            let duration = command.objectAtIndex(3) as! NSNumber
            let parallaxing = command.objectAtIndex(4) as! NSNumber
            
            let durationAsDouble = duration.doubleValue
            let parallaxFactor = CGFloat(parallaxing.doubleValue)
            
            self.setEffectRunningFlag()
    
            // Also update the background's position in the record, so that when the game is loaded from a saved game,
            // then the background will be where it should be (that is, where it will be once the CCAction has finished).
            let finishedX = background.position.x + CGFloat(moveByX.floatValue)
            let finishedY = background.position.y + CGFloat(moveByY.floatValue)
            record.setObject(NSNumber(double: Double(finishedX)), forKey: VNSceneBackgroundXKey)
            record.setObject(NSNumber(double: Double(finishedY)), forKey: VNSceneBackgroundYKey)
            
            // Updates sprites to move along with the background
            for currentName in sprites.allKeys {
                
                let spriteName = currentName as! String
                let currentSprite:SKSpriteNode? = sprites.objectForKey(spriteName) as? SKSpriteNode
                
                if( currentSprite!.parent != nil ) {
                    
                    let spriteMovementX = parallaxFactor * CGFloat( moveByX.doubleValue )
                    let spriteMovementY = parallaxFactor * CGFloat( moveByY.doubleValue )
                    
                    let movementAction = SKAction.moveBy(CGVectorMake(spriteMovementX, spriteMovementY), duration: durationAsDouble)
                    currentSprite!.runAction(movementAction)
                }
            }
    
            // Set up the movement sequence
            let movementAmount      = CGVectorMake( CGFloat(moveByX.floatValue), CGFloat(moveByY.floatValue) );
            let moveByAction        = SKAction.moveBy(movementAmount, duration: durationAsDouble)
            let clearEffectFlag     = SKAction.runBlock(self.clearEffectRunningFlag)
            let movementSequence    = SKAction.sequence([moveByAction, clearEffectFlag])
            
            background.runAction(movementSequence)
    
        // This command moves a sprite by a certain number of points (since Cocos2D uses points instead of pixels). This
        // is really just a "wrapper" of sorts for the CCMoveBy action in Cocos2D.
        case VNScriptCommandEffectMoveSprite:
            
            let spriteName = parameter1String
            let moveByXNumber = command.objectAtIndex(2) as! NSNumber
            let moveByYNumber = command.objectAtIndex(3) as! NSNumber
            let durationNumber:NSNumber? = command.objectAtIndex(4) as? NSNumber
            
            // Create scalar versions
            let moveByX = CGFloat( moveByXNumber.doubleValue )
            let moveByY = CGFloat( moveByYNumber.doubleValue )
            var duration = Double( 0 ) // Default duration length
            
            let tempSprite:SKSpriteNode? = sprites.objectForKey(spriteName) as? SKSpriteNode
            if( tempSprite == nil ) {
                return;
            }
            
            if durationNumber != nil {
                duration = durationNumber!.doubleValue
            }
            
            let sprite = tempSprite!
            createSafeSave()
            
            if duration < 0.0 {
                let updatedX = sprite.position.x + moveByX
                let updatedY = sprite.position.y + moveByY
                
                sprite.position = CGPointMake(updatedX, updatedY)
                return; // Stop the function, since an "immediate movement" command doesn't need to go any further
            }
    
            self.setEffectRunningFlag()
    
            // Set up movement action, and then have the "effect is running" flag get cleared at the end of the sequence
            let movementAmount      = CGVectorMake(moveByX, moveByY)
            let moveByAction        = SKAction.moveBy(movementAmount, duration: duration)
            let clearEffectFlag     = SKAction.runBlock(self.clearEffectRunningFlag)
            let movementSequence    = SKAction.sequence([moveByAction, clearEffectFlag])
            
            sprite.runAction(movementSequence)
    
    
        // Instantly set a sprite's position (this is similar to the "move sprite" command, except this happens instantly).
        // While instant movement can look strange, there are some situations it can be useful.
        case VNScriptCommandSetSpritePosition:
            
            let spriteName = parameter1String
            let updatedXNumber = command.objectAtIndex(2) as! NSNumber
            let updatedYNumber = command.objectAtIndex(3) as! NSNumber
            let updatedX = CGFloat( updatedXNumber.doubleValue )
            let updatedY = CGFloat( updatedYNumber.doubleValue )
            
            let loadedSprite:SKSpriteNode? = sprites.objectForKey(spriteName) as? SKSpriteNode
            if( loadedSprite != nil ) {
                loadedSprite!.position = CGPointMake(updatedX, updatedY)
            }
            
    
        // Change the background image. If the name parameter is set to "nil" then this command just removes the background image.
        case VNScriptCommandSetBackground:
    
            let backgroundName = parameter1String;
    
            // Get rid of the old background
            let background:SKSpriteNode? = self.childNodeWithName(VNSceneTagBackground) as? SKSpriteNode
            if( background != nil ) {
                background!.removeFromParent()
            }
    
            // Also remove background data from records
            record.removeObjectForKey(VNSceneBackgroundToShowKey)
            record.removeObjectForKey(VNSceneBackgroundXKey)
            record.removeObjectForKey(VNSceneBackgroundYKey)
    
            // Check the value of the string. If the string is "nil", then just get rid of any existing background
            // data. Otherwise, VNSceneView will try to use the string as a file name.
            if backgroundName.caseInsensitiveCompare(VNScriptNilValue) != NSComparisonResult.OrderedSame {
                
                let updatedBackground = SKSpriteNode(imageNamed: backgroundName)
                
                // Get some data needed to set the background
                var alphaValue = CGFloat( 1.0 )
                let alphaNumber:NSNumber? = viewSettings.objectForKey(VNSceneViewDefaultBackgroundOpacityKey) as? NSNumber
                if( alphaNumber != nil ) {
                    alphaValue = CGFloat( alphaNumber!.doubleValue )
                }
                
                // Set properties
                updatedBackground.position  = CGPointMake(self.frame.size.width * 0.5, self.frame.size.height * 0.5) // Position at the center of the frame
                updatedBackground.alpha     = alphaValue
                updatedBackground.zPosition = VNSceneBackgroundLayer
                updatedBackground.name      = VNSceneTagBackground
                
                self.addChild(updatedBackground)
                
                // Convert coordinates to NSNumber format
                let backgroundXDouble = Double( updatedBackground.position.x )
                let backgroundYDouble = Double( updatedBackground.position.y )
                let bgXNumber = NSNumber( double: backgroundXDouble )
                let bgYNumber = NSNumber( double: backgroundYDouble )
                
                // Update record
                record.setObject(backgroundName, forKey: VNSceneBackgroundToShowKey)
                record.setObject(bgXNumber, forKey: VNSceneBackgroundXKey)
                record.setObject(bgYNumber, forKey: VNSceneBackgroundYKey)
            }
    
        // Sets the "speaker name," so that the player knows which character is speaking. The name usually appears above and to the
        // left of the actual dialogue text. The value of the speaker name can be set to "nil" to hide the label.
        case VNScriptCommandSetSpeaker:
    
            let updatedSpeakerName = parameter1String
    
            speaker!.alpha = 0; // Make the label invisible so that it can fade in
            speaker!.text = " "; // Default value is to not have any speaker name in the label's text string
            record.removeObjectForKey(VNSceneSpeakerNameToShowKey)
    
            // Check if this is a valid name (instead of the 'nil' value)
            if updatedSpeakerName.caseInsensitiveCompare(VNScriptNilValue) != NSComparisonResult.OrderedSame {
    
                // Set new name
                record.setValue(updatedSpeakerName, forKey: VNSceneSpeakerNameToShowKey)
    
                speaker!.alpha = 0;
                speaker!.text = updatedSpeakerName;
    
                speaker!.anchorPoint = CGPointMake(0, 1.0);
                speaker!.position = self.updatedSpeakerPosition() //[self updatedSpeakerPosition)
    
                // Fade in the speaker name label
                let fadeIn = SKAction.fadeInWithDuration(speechTransitionSpeed)
                speaker!.runAction(fadeIn)
            }
    
    
        // This changes which "conversation" (or array of dialogue) in the script is currently being run.
        case VNScriptCommandChangeConversation:
    
            //NSString* updatedConversationName = parameter1;
            let updatedConversationName = parameter1String
            
            let convo:NSArray? = script!.data!.objectForKey(updatedConversationName) as? NSArray
            if convo == nil {
                print("[VNScene] ERROR: No section titled \(updatedConversationName) was found in script!")
                return;
            }
    
            // If the conversation actually exists, then just switch to it
            script!.changeConversationTo(updatedConversationName)
            script!.indexesDone--
    
        // This command presents a choice menu to the player, and after the player chooses, then VNScene switches conversations.
        case VNScriptCommandJumpOnChoice:
            
            self.createSafeSave() // Always create safe-save before doing something volatile
            
            let choiceTexts = command.objectAtIndex(1) as! NSArray   // Get the strings to display for individual choices
            let destinations = command.objectAtIndex(2) as! NSArray  // Get the names of the conversations to "jump" to
            let numberOfChoices = choiceTexts.count                 // Calculate number of choices
            
            // Make sure the arrays that hold the data are prepared
            buttons.removeAllObjects()
            choices.removeAllObjects()
    
            // Come up with some position data
            let screenWidth = self.frame.size.width
            let screenHeight = self.frame.size.height
            
            for var i = 0; i < numberOfChoices; i++  {
                
                let buttonImageName     = SMStringFromDictionary(viewSettings, nameOfObject: VNSceneViewButtonFilenameKey) //viewSettings.objectForKey(VNSceneViewButtonFilenameKey) as! NSString
                let button:SKSpriteNode = SKSpriteNode(imageNamed: buttonImageName)
                
                // Calculate the amount of space (including space between buttons) that each button will take up, and then
                // figure out where and how to position the buttons (factoring in margins / spaces between buttons). Generally,
                // the button in the middle of the menu of choices will show up in the middle of the screen with this formula.
                let spaceBetweenButtons:CGFloat   = button.frame.size.height * 0.2;
                let buttonHeight:CGFloat          = button.frame.size.height;
                let totalButtonSpace:CGFloat      = buttonHeight + spaceBetweenButtons;
                let startingPosition:CGFloat      = (screenHeight * 0.5) + ( ( CGFloat(numberOfChoices / 2) ) * totalButtonSpace );
                let buttonY:CGFloat               = startingPosition + ( CGFloat(i) * totalButtonSpace );
    
                // Set button position
                button.position = CGPointMake( screenWidth * 0.5, buttonY );
                button.zPosition = VNSceneButtonsLayer;
                button.name = "\(i)" //button.name = [NSString stringWithFormat:@"%d", i)
                self.addChild(button)
                
                // Set color and add to array
                button.color = buttonUntouchedColors
                buttons.addObject(button)
    
                // Determine where the text should be positioned inside the button
                var labelWithinButtonPos = CGPointMake( button.frame.size.width * 0.5, button.frame.size.height * 0.35 );
                
                if( UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad ) {
                    
                    // The position of the text inside the button has to be adjusted, since the actual font size on the iPad isn't exactly
                    // twice as large, but modified with some custom code. This results in having to do some custom positioning as well!
                    labelWithinButtonPos.y = CGFloat(button.frame.size.height * 0.31)
                }
    
                // Create the button label
                /*CCLabelTTF* buttonLabel = [CCLabelTTF labelWithString:[choiceTexts objectAtIndex:i]
                fontName:[viewSettings.objectForKey(VNSceneViewFontNameKey]
                fontSize:[[viewSettings.objectForKey(VNSceneViewFontSizeKey] floatValue]
                dimensions:button.boundingBox.size)*/
                let labelFontName = SMStringFromDictionary(viewSettings, nameOfObject: VNSceneViewFontNameKey)//viewSettings.objectForKey(VNSceneViewFontNameKey) as NSString
                let labelFontSize = SMNumberFromDictionary(viewSettings, nameOfObject: VNSceneViewFontSizeKey)//viewSettings.objectForKey(VNSceneViewFontSizeKey) as NSNumber
                
                let buttonLabel = SKLabelNode(fontNamed: labelFontName)
                // Set label properties
                buttonLabel.text = choiceTexts.objectAtIndex(i) as! NSString as String
                buttonLabel.fontSize = CGFloat( labelFontSize.floatValue )
                buttonLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center // Center the text in the button
                
                // Handle positioning for the text
                var buttonLabelYPos = 0 - (button.size.height * 0.20)
                
                if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad {
                    buttonLabelYPos = 0 - (button.size.height * 0.20)
                }
                
                buttonLabel.position = CGPointMake(0.0, buttonLabelYPos)
                buttonLabel.zPosition = VNSceneButtonTextLayer
                
                button.addChild(buttonLabel)
                button.colorBlendFactor = 1.0 // Needed to "color" the sprite; it wouldn't have any color-blending otherwise
                
                choices.addObject( destinations.objectAtIndex(i) )
            }
            
            mode = VNSceneModeChoiceWithJump
            
    
        // This command will show (or hide) the speech box (the little box where all the speech/dialogue text is shown).
        // Hiding it is useful in case you want the player to just enjoy the background art.
        case VNScriptCommandShowSpeechOrNot:
            
            let showSpeechNumber = param1! as! NSNumber
            let showSpeechOrNot = showSpeechNumber.boolValue
            
            record.setValue(showSpeechNumber, forKey: VNSceneShowSpeechKey)
    
            // Case 1: DO show the speech box
            if( showSpeechOrNot == true ) {
    
                //[speechBox stopAllActions)
                //[speech stopAllActions)
                speechBox!.removeAllActions()
                speech!.removeAllActions()
    
                //CCActionFadeIn* fadeInSpeechBox = [CCActionFadeIn actionWithDuration:speechTransitionSpeed)
                let fadeInSpeechBox = SKAction.fadeInWithDuration(speechTransitionSpeed)
                speechBox!.runAction(fadeInSpeechBox)
                
                let fadeInText = SKAction.fadeInWithDuration(speechTransitionSpeed)
                speech!.runAction(fadeInText)
                // Case 2: DON'T show the speech box.
                
            } else {
                
                speech!.removeAllActions()
                speechBox!.removeAllActions()
                
                let fadeOutBox = SKAction.fadeOutWithDuration(speechTransitionSpeed)
                let fadeOutText = SKAction.fadeOutWithDuration(speechTransitionSpeed)
                
                speechBox!.runAction(fadeOutBox)
                speech!.runAction(fadeOutText)
            }
    
    
        // This command causes the background image and character sprites to "fade in" (go from being fully transparent to being
        // opaque).
        //
        // Note that if you want a fade-to-black (or rather, fade-FROM-black) effect, it helps if this CCLayer is being run in
        // its own CCScene. If the layer has just been added on to an existing CCScene/CCLayer, then hopefully there's a big
        // black image behind it or something.
        case VNScriptCommandEffectFadeIn:
            
            let durationNumber = param1 as! NSNumber
            let duration = durationNumber.doubleValue
            
            self.createSafeSave()
            self.setEffectRunningFlag()
            
            
            // Check if there's any character sprites in existence. If there are, they all need to have a CCFadeIn action
            // applied to each and every one.
            if sprites.count > 0 {
                
                for tempSprite in sprites.allValues {
                    
                    let currentSprite:SKSpriteNode = tempSprite as! SKSpriteNode
                    let fadeIn = SKAction.fadeInWithDuration(duration)
                    
                    currentSprite.runAction(fadeIn)
                }
            }
            
            // Fade in the background sprite, if it exists
            let backgroundSprite:SKSpriteNode? = self.childNodeWithName(VNSceneTagBackground) as? SKSpriteNode
            if( backgroundSprite != nil ) {
                
                let fadeIn = SKAction.fadeInWithDuration(duration)
                backgroundSprite!.runAction(fadeIn)
            }
    
            // Since the upcoming CCSequence runs at the same time that the prior CCFadeIn actions are run, the first thing
            // put into the sequence is a delay action, so that the "function call" action gets run immediately after the
            // fade-in actions finish.
            
            let delay = SKAction.waitForDuration(duration)
            let callFunc = SKAction.runBlock(self.clearEffectRunningFlag)
            //let callFunc = SKAction performSelector:@selector(clearEffectRunningFlag) onTarget:self)
            let delayedClearSequence = SKAction.sequence([delay, callFunc])
    
            //[self runAction:delayedClearSequence)
            self.runAction(delayedClearSequence)
    
            // Finally, update the view settings with the "fully faded-in" value for the background's opacity
            //[viewSettings.setValue(1.0f forKey:VNSceneViewDefaultBackgroundOpacityKey)
            viewSettings.setValue(NSNumber(double: 1.0), forKey: VNSceneViewDefaultBackgroundOpacityKey)
            
    
        // This is similar to the above command, except that it causes the character sprites and background to go from being
        // fully opaque to fully transparent (or "fade out").
        case VNScriptCommandEffectFadeOut:
            
            let durationNumber = param1 as! NSNumber
            let duration = durationNumber.doubleValue
            
            self.createSafeSave()
            self.setEffectRunningFlag()
            
            if sprites.count > 0 {
                
                for tempSprite in sprites.allValues {
                    let fadeOut = SKAction.fadeOutWithDuration(duration)
                    let currentSprite = tempSprite as! SKSpriteNode
                    currentSprite.runAction(fadeOut)
                }
                
                let backgroundSprite:SKSpriteNode? = self.childNodeWithName(VNSceneTagBackground) as? SKSpriteNode
                if( backgroundSprite != nil ) {
                    let fadeOut = SKAction.fadeOutWithDuration(duration)
                    backgroundSprite!.runAction(fadeOut)
                }
            }
            
            let delay = SKAction.waitForDuration(duration)
            let callFunc = SKAction.runBlock(self.clearEffectRunningFlag)
            let delayedClearSequence = SKAction.sequence([delay, callFunc])
            
            self.runAction(delayedClearSequence)
            
            viewSettings.setValue(NSNumber(double: 0.0), forKey: VNSceneViewDefaultBackgroundOpacityKey)
    
        // This just plays a sound. I had actually thought about creating some kind of system to keep track of all
        // the sounds loaded, and then to manually remove them from memory once they were no longer being used,
        // but I've never gotten around to implementing it.
        case VNScriptCommandPlaySound:
            
            let soundName = parameter1String
            
            self.playSoundEffect(soundName)

    
        // This plays music (an MP3 file is good, though AAC might be better since iOS devices supposedly have built-in
        // hardware-decoding for them, or CAF since they have small filesizes and small memory footprints). You can only
        // play one music file at a time. You can choose whether it loops infinitely, or if it just plays once.
        //
        // If you want to STOP music from playing, you can also pass "nil" as the filename (parameter #1) to cause
        // VNScene to stop all music.
        case VNScriptCommandPlayMusic:
            
            let musicName = parameter1String
            let musicShouldLoop = (command.objectAtIndex(2) as! NSNumber)
            
            print("[VNScene] Should now stop background music.")
            self.stopBGMusic()
            
            if musicName.caseInsensitiveCompare(VNScriptNilValue) == NSComparisonResult.OrderedSame {
                
                // Remove all the existing music data from the saved game information
                record.removeObjectForKey(VNSceneMusicToPlayKey)
                record.removeObjectForKey(VNSceneMusicShouldLoopKey)
                
            } else {
                
                record.setValue(musicName, forKey: VNSceneMusicToPlayKey)
                record.setValue(musicShouldLoop, forKey: VNSceneMusicShouldLoopKey)
                
                // Play the new background music
                self.playBGMusic(musicName, willLoopForever: musicShouldLoop.boolValue)
            }
            
    
        // This command sets a variable (or "flag"), which is usually an "int" value stored in an NSNumber object by a dictionary.
        // VNScene stores a local dictionary, and whenever the game is saved, the contents of that dictionary are copied over to
        // SMRecord's own flags dictionary (and stored in device memory).
        case VNScriptCommandSetFlag:
            
            let flagName = parameter1String
            let flagValue:AnyObject = command.objectAtIndex(2)
            
            //NSLog("[VNScene] Setting flag named [%@] to a value of [%@]", flagName, flagValue);
    
            // Store the new value in the local dictionary
            //[flags.setValue:flagValue forKey:flagName)
            flags.setValue(flagValue, forKey: flagName)
    
    
        // This modifies an existing flag's integer value by a certain amount (you might have guessed: a positive value "adds",
        // while a negative "subtracts). If no flag actually exists, then a new flag is created with whatever value was passed in.
        case VNScriptCommandModifyFlagValue:
            
            let flagName = parameter1String
            let modifyWithValue = (command.objectAtIndex(2) as! NSNumber).integerValue
            
            let originalObject:AnyObject? = flags.objectForKey(flagName)
            if originalObject == nil {
                // Set a new value based on the parameter
                flags.setValue( NSNumber(integer: modifyWithValue), forKey: flagName)
                return; // And that's the end of it
            }
            
            // Handle modification operation
            let originalNumber:NSNumber = originalObject! as! NSNumber
            let originalValue = originalNumber.integerValue
            let modifiedValue = originalValue + modifyWithValue
            let finalNumber = NSNumber(integer: modifiedValue)
            
            flags.setValue(finalNumber, forKey: flagName)
            
            
        // This checks if a particular flag has a certain value. If it does, then it executes ANOTHER command (which starts
        // at the third parameter and continues to whatever comes afterwards).
        case VNScriptCommandIfFlagHasValue:
            
            let flagName = parameter1String
            let expectedValue = (command.objectAtIndex(2) as! NSNumber).integerValue
            let secondaryCommand:NSArray = command.objectAtIndex(3) as! NSArray // Secondary command, which runs if the actual and expected values are the same
            
            let theFlag:NSNumber? = flags.objectForKey(flagName) as? NSNumber
            if theFlag == nil {
                return;
            }

            let actualValue = theFlag!.integerValue
            
            if( actualValue != expectedValue ) {
                return;
            }
            
            // If the function reaches this point, it's safe to move on to the next phase
            self.processCommand(secondaryCommand)
            
            let secondaryCommandType = (secondaryCommand.objectAtIndex(0) as! NSNumber).integerValue
            // Make sure that things don't get knocked out of order by the secondary command (if it involves switching conversations)
            if secondaryCommandType != VNScriptCommandChangeConversation {
                script!.currentIndex--
            }
    
        // This checks if a particular flag is GREATER THAN a certain value. If it does, then it executes ANOTHER command (which starts
        // at the third parameter and continues to whatever comes afterwards).
        case VNScriptCommandIsFlagMoreThan:
            
            let flagName = parameter1String
            let expectedValue = (command.objectAtIndex(2) as! NSNumber).integerValue
            let secondaryCommand = command.objectAtIndex(3) as! NSArray
            
            let theFlag:NSNumber? = flags.objectForKey(flagName) as? NSNumber
            if theFlag == nil {
                return;
            }
            
            let actualValue = theFlag!.integerValue
            
            if( actualValue <= expectedValue ) {
                return;
            }
            
            self.processCommand(secondaryCommand)
            
            let secondaryCommandType = (secondaryCommand.objectAtIndex(0) as! NSNumber).integerValue
            if( secondaryCommandType != VNScriptCommandChangeConversation ) {
                script!.currentIndex--
            }
            
            
        // This checks if a particular flag LESS THAN certain value. If it does, then it executes ANOTHER command (which starts
        // at the third parameter and continues to whatever comes afterwards).
        case VNScriptCommandIsFlagLessThan:
            
            let flagName = parameter1String
            let expectedValue = (command.objectAtIndex(2) as! NSNumber).integerValue
            let secondaryCommand = command.objectAtIndex(3) as! NSArray
            
            let theFlag:NSNumber? = flags.objectForKey(flagName) as? NSNumber
            if( theFlag == nil ) {
                return;
            }
            
            let actualValue = theFlag!.integerValue
            if( actualValue >= expectedValue ) {
                return;
            }
            
            self.processCommand(secondaryCommand)
            
            let secondaryCommandType = (secondaryCommand.objectAtIndex(0) as! NSNumber).integerValue
            if( secondaryCommandType != VNScriptCommandChangeConversation ) {
                script!.currentIndex--;
            }
    
        // This checks if a particular flag is between two values (a lesser value and a greater value). If thie is the case,
        // then a secondary command is run.
        case VNScriptCommandIsFlagBetween:
            
            let flagName = parameter1String
            let lesserValue = (command.objectAtIndex(2) as! NSNumber).integerValue
            let greaterValue = (command.objectAtIndex(3) as! NSNumber).integerValue
            let secondaryCommand = command.objectAtIndex(4) as! NSArray
            
            let theFlag:NSNumber? = flags.objectForKey(flagName) as? NSNumber
            if( theFlag == nil ) {
                return;
            }
            
            let actualValue = theFlag!.integerValue
            
            if( actualValue <= lesserValue || actualValue >= greaterValue ) {
                return;
            }
            
            self.processCommand(secondaryCommand)
    
            let secondaryCommandType = (secondaryCommand.objectAtIndex(0) as! NSNumber).integerValue
            if( secondaryCommandType != VNScriptCommandChangeConversation ) {
                script!.currentIndex--;
            }
    
        // This command presents the user with a choice menu. When the user makes a choice, it results in the value of a flag
        // being modified by a certain amount (just like if the .MODIFYFLAG command had been used).
        case VNScriptCommandModifyFlagOnChoice:
    
            // Create "safe" autosave before doing something as volatile as presenting a choice menu
            self.createSafeSave()
    
            let choiceTexts     = param1! as! NSArray
            let variableNames   = command.objectAtIndex(2) as! NSArray
            let variableValues  = command.objectAtIndex(3) as! NSArray
            let numberOfChoices = choiceTexts.count
            
            // Prepare the arrays
            buttons.removeAllObjects()
            choices.removeAllObjects()
            choiceExtras.removeAllObjects()
            
            let screenWidth = self.frame.size.width
            let screenHeight = self.frame.size.height
            
            // The following loop creates the buttons (and their label "child nodes") and adds them to an array. It also
            // loads the flag modification data into their own arrays.
            for var i = 0; i < numberOfChoices; i++ {
                
                let loopIndex = CGFloat( i )
                let choiceCount = CGFloat( numberOfChoices )
                
                let buttonFilename = viewSettings.objectForKey(VNSceneViewButtonFilenameKey) as! NSString
                let button = SKSpriteNode(imageNamed: buttonFilename as String)
                
                // Calculate the amount of space (including space between buttons) that each button will take up, and then
                // figure out the position of the button that's being made. Ideally, the middle of the choice menu will also be the middle
                // of the screen. Of course, if you have a LOT of choices, there may be more buttons than there is space to put them!
                let spaceBetweenButtons   = button.frame.size.height * 0.2; // 20% of button sprite height
                let buttonHeight          = button.frame.size.height;
                let totalButtonSpace      = buttonHeight + spaceBetweenButtons; // total used-up space = 120% of button height
                let startingPosition      = (screenHeight * 0.5) + ( ( choiceCount * 0.5 ) * totalButtonSpace );
                let buttonY               = startingPosition + ( loopIndex * totalButtonSpace ); // This button's position
        
                // Set button position and other attributes
                button.position     = CGPointMake( screenWidth * 0.5, buttonY );
                //button.color        = [[CCColor alloc] initWithCcColor3b:buttonUntouchedColors)
                button.color        = buttonUntouchedColors;
                button.zPosition    = VNSceneButtonsLayer;
                
                self.addChild(button)
                buttons.addObject(button)
    
                // Determine where the text should be positioned inside the button
                var labelWithinButtonPos = CGPointMake( button.frame.size.width * 0.5, button.frame.size.height * 0.35 );
                if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad {
                    labelWithinButtonPos.y = button.frame.size.height * 0.31;
                }
                
                // Create button label, set the position of the text, and add this label to the main 'button' sprite
                let labelFontName       = SMStringFromDictionary(viewSettings, nameOfObject: VNSceneViewFontNameKey)
                let labelFontSizeNumber = SMNumberFromDictionary(viewSettings, nameOfObject: VNSceneViewFontSizeKey)
                let labelFontSize       = CGFloat( labelFontSizeNumber.doubleValue )
                
                let buttonLabel = SKLabelNode(fontNamed: labelFontName)
                buttonLabel.fontSize = labelFontSize
                buttonLabel.text = choiceTexts.objectAtIndex(i) as! NSString as String
                buttonLabel.zPosition = VNSceneButtonsLayer
                buttonLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
                
                // Position Y coordinate
                var buttonLabelY:CGFloat = 0 - (button.size.height * 0.20)
                
                if( UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad ) {
                    buttonLabelY = 0 - (button.size.height * 0.20)
                }
                
                buttonLabel.position = CGPointMake(0, buttonLabelY)
                
                button.addChild(buttonLabel)
                button.colorBlendFactor = 1.0;
                
                // Set up choices
                choices.addObject(variableNames.objectAtIndex(i))
                choiceExtras.addObject(variableValues.objectAtIndex(i))
            }
            
            mode = VNSceneModeChoiceWithFlag
            
            print("CHOICES array is \(choices)")
            print("CHOICE EXTRAS array is \(choiceExtras)")
            
            
        // This command will cause VNScene to switch conversations if a certain flag holds a particular value.
        case VNScriptCommandJumpOnFlag:
            
            let flagName = parameter1String
            let expectedValue = (command.objectAtIndex(2) as! NSNumber).integerValue
            let targetedConversation = command.objectAtIndex(3) as! NSString
            
            let theFlag:NSNumber? = flags.objectForKey(flagName) as? NSNumber
            if theFlag == nil {
                return;
            }
            
            let actualValue = theFlag!.integerValue
            if( actualValue != expectedValue ) {
                return;
            }
            
            let convo:NSArray? = script!.data!.objectForKey(targetedConversation) as? NSArray
            if convo == nil {
                print("[VNScene] ERROR: No section titled \(targetedConversation) was found in script!")
                return;
            }
            
            script!.changeConversationTo(targetedConversation as String)
            script!.indexesDone--;
            
    
        // This command is used in conjuction with the VNSystemCall class, and is used to create certain game-specific effects.
        case VNScriptCommandSystemCall:
            
            let systemCallArray = NSMutableArray(array: command)
            systemCallArray.removeObjectAtIndex(0) // Remove the ".systemcall" part of the command
            
            systemCallHelper.sendCall(systemCallArray)
            
    
        // This command replaces the scene's script with a script loaded from another .PLIST file. This is useful in case
        // your script is actually broken up into multiple .PLIST files.
        case VNScriptCommandSwitchScript:
            
            let scriptName = command.objectAtIndex(1) as! NSString
            let startingPoint = command.objectAtIndex(2) as! NSString
            
            print("[VNScene] Switching to script named \(scriptName) with starting point [\(startingPoint)]");
            
            //let loadingDictionary = NSDictionary(objectsAndKeys: scriptName, VNScriptFilenameKey,
            //    startingPoint, VNScriptConversationNameKey);
            let loadingDictionary = NSDictionary(dictionary: [VNScriptFilenameKey:scriptName,
                VNScriptConversationNameKey:startingPoint])
            
            script = VNScript(info: loadingDictionary);
            if script == nil {
                print("[VNScene] ERROR: Cannot load script named: \(scriptName)")
                return;
            }
            
            script!.indexesDone--;
            print("[VNScene] Script object replaced.");
            
    
        case VNScriptCommandSetSpeechFont:
            
            speechFont = parameter1String
            
            // This will only change the font if the font name is of a "proper" length; no supported font on iOS
            // is shorter than 4 characters (as far as I know).
            //if countElements(speechFont) > 3 {
            if SMStringLength(speechFont) > 3 {
                
                speech!.fontName = parameter1String
                
                // Update record with override
                record.setObject(speechFont, forKey: VNSceneOverrideSpeechFontKey)
            }
            
            
        case VNScriptCommandSetSpeechFontSize:
            
            let foundationString = parameter1String as NSString
            let convertedSize = CGFloat( foundationString.floatValue )
        
            fontSizeForSpeech = convertedSize
    
            // Check for a font size that's too small; if this is the case, then just switch to a "normal" font size
            if( fontSizeForSpeech < 1.0 ) {
                fontSizeForSpeech = 13.0;
            }
    
            speech!.fontSize = fontSizeForSpeech;
            
            // Store override data
            let storedFontSize = NSNumber( double: Double(fontSizeForSpeaker) ) // Conver to NSNumber
            record.setValue(storedFontSize, forKey: VNSceneOverrideSpeechSizeKey)
    
    
        case VNScriptCommandSetSpeakerFont:
            
            speakerFont = parameter1String
            
            if SMStringLength(speakerFont) > 3 {
                
                speaker!.fontName = speakerFont
                
                // Update records with override
                record.setValue(speakerFont, forKey: VNSceneOverrideSpeakerFontKey)
                
                // Set position
                speaker!.anchorPoint = CGPointMake(0, 1.0)
                speaker!.position = self.updatedSpeakerPosition()
            }
    
        case VNScriptCommandSetSpeakerFontSize:
            
            let convertedString = parameter1String as NSString
            
            fontSizeForSpeaker = CGFloat( convertedString.floatValue )
            
            if fontSizeForSpeaker < 1.0 {
                fontSizeForSpeaker = 13.0
            }
            
            speaker!.fontSize = fontSizeForSpeaker
            
            // Store override data
            let storedNumber = NSNumber(double: Double( fontSizeForSpeaker ))
            record.setValue(storedNumber, forKey: VNSceneOverrideSpeakerSizeKey)
            
            // Set the position
            speaker!.anchorPoint = CGPointMake(0, 1.0);
            speaker!.position = self.updatedSpeakerPosition()
            
        case VNScriptCommandSetTypewriterText:
            
            if let first = command.objectAtIndex(1) as? NSNumber {
                TWSpeedInCharacters = first.integerValue;
            }
            if let second = command.objectAtIndex(2) as? NSNumber {
                TWCanSkip = second.boolValue
            }
            
            self.updateTypewriterTextSettings()
    
    
        default:
            print("[VNScene] WARNING: Unknown command found in script. The command's NSArray is: %@", command);
        } // switch
    } // function
} // class