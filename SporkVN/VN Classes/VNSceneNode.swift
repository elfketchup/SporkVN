//
//  VNSceneNode.swift
//  SporkVN
//
//  Created by James on 1/14/18.
//  Copyright © 2018 James Briones. All rights reserved.
//

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


// MARK: - Constants and definitions

let VNSceneActivityType             = "VNScene" // The type of activity this is (used in conjuction with SMRecord)
let VNSceneToPlayKey                = "scene to play"
let VNSceneViewFontSize             = 17
let VNSceneSpriteIsSafeToRemove     = "sprite is safe to remove" // Used for sprite removal (to free up memory and remove unused sprite)
let VNScenePopSceneWhenDoneKey      = "pop scene when done" // Ask CCDirector to pop the  scene when the script finishes?
let VNSceneDiceRollResultFlag       = "DICEROLL" // flag that stores results of dice rolls

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
let VNSceneViewDoesUseHeightMarginForAdsKey = "does use height margin for ads" // currently does nothing
let VNSceneViewButtonTextColorKey           = "button text color"    // color of the text in buttons
let VNSceneViewSpeechboxColorKey            = "speechbox color"      // color speech box
let VNSceneViewSpeechboxTextColorKey        = "speechbox text color" // color of text in speech box (both dialogue and speaker name)
let VNSceneViewChoiceButtonOffsetX          = "choicebox offset x"
let VNSceneViewChoiceButtonOffsetY          = "choicebox offset y"
let VNSceneViewChoiceButtonBlinkSpeedKey    = "choicebox blink speed" // duration of "blink" (fade in/out) in seconds. 0 means no blink.
let VNSceneViewChoiceButtonBlinkMinOpacity  = "choicebox blink minimum opacity" // minimum alpha used when fading out to blink

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
let VNSceneSavedScriptInfoKey           = "script info"
let VNSceneSavedResourcesKey            = "saved resources"
let VNSceneMusicToPlayKey               = "music to play"
let VNSceneMusicShouldLoopKey           = "music should loop"
let VNSceneSpritesToShowKey             = "sprites to show"
let VNSceneSoundsToRemoveKey            = "sounds to remove"
let VNSceneMusicToRemoveKey             = "music to remove"
let VNSceneBackgroundToShowKey          = "background to show"
let VNSceneSpeakerNameToShowKey         = "speaker name to show"
let VNSceneSpeechToDisplayKey           = "speech to display"
let VNSceneShowSpeechKey                = "show speech"
let VNSceneBackgroundXKey               = "background x"
let VNSceneBackgroundYKey               = "background y"
let VNSceneTypewriterTextCanSkip        = "typewriter text can skip"
let VNSceneTypewriterTextSpeed          = "typewriter text speed"
let VNSceneSavedOverriddenSpeechboxKey  = "overridden speechbox" // used to store speechbox sprites modified by .SETSPEECHBOX in saves
let VNSceneChoiceSetsKey                = "choice sets" // stores choice sets that can be modified on the fly and dislayed whenever
let VNSceneChoiceboxFadeinKey           = "choicebox fadein" // determines whether or not choiceboxes fade in (instead of just appear instantly)
let VNSceneChoiceboxFadeTimeKey         = "choicebox fade time" // how quickly the choice box fades into view (in seconds)

// UI "override" keys (used when you change things like font size/font name in the middle of a scene).
// By default, any changes will be restored when a saved game is loaded, though the "override X from save"
// settings can change this.
let VNSceneOverrideSpeechFontKey    = "override speech font"
let VNSceneOverrideSpeechSizeKey    = "override speech size"
let VNSceneOverrideSpeakerFontKey   = "override speaker font"
let VNSceneOverrideSpeakerSizeKey   = "override speaker size"
let VNSceneOverrideChoiceMinOpacity = "override choice min opacity"
let VNSceneOverrideChoiceBlinkSpeed = "override choice blink speed"

// Graphics/display stuff
let VNSceneViewSettingsFileName     = "vnscene view settings"
let VNSceneSpriteXKey               = "x position"
let VNSceneSpriteYKey               = "y position"

// Sprite/node layers
let VNSceneBackgroundLayer          = CGFloat(  50.0    )
let VNSceneCharacterLayer           = CGFloat(  60.0    )
let VNSceneUILayer                  = CGFloat(  100.0   )
let VNSceneTextLayer                = CGFloat(  110.0   )
let VNSceneButtonsLayer             = CGFloat(  120.0   )
let VNSceneButtonTextLayer          = CGFloat(  130.0   )

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

// Transition types (currently unused, but can be used to transition to other types of SKScene subclasses)
let VNSceneTransitionTypeNone       = 00
let VNSceneNodeChoiceButtonStartingPercentage  = CGFloat(0.63) // A percentage of the screen height, is used for positioning buttons during choices

// MARK: - VNSceneNode class

@MainActor
private var VNSceneNodeSharedInstance:VNSceneNode? = nil

/*
 VNSceneNode does all the heavy lifting for dialogue / visual-novel scenes. Display dialogue, characters, user interfaces,
 playing audio, etc... ideally, this should be broken up into smaller classes that do all those things independently.
 */
@MainActor
class VNSceneNode : SKNode {
    
    var script:VNScript?
    
    // There's supposed to be only one instance of VNSceneNode running at any given time, which sharedScene points to
    class var sharedScene:VNSceneNode? {
        if( VNSceneNodeSharedInstance != nil ) {
            return VNSceneNodeSharedInstance
        }
        
        return nil
    }
    
    // A helper class that can be used to handle .systemcall commands.
    var systemCallHelper = VNSystemCall()
    
    var record  = NSMutableDictionary() // Holds misc data (especially regarding the script)
    var flags   = NSMutableDictionary() // Local flags data (later saved to SMRecord's flags, when the scene is saved)
    
    var mode:Int        = VNSceneModeLoading // What the scene is doing (or should be doing) at the current moment
    
    // The "safe save" is an pseudo-autosave created right before performing a "dangerous" action like running an EKEffect.
    // Since saving the game in the middle of an effectt can cause unexpected results (like sprites being in the wrong
    // position), VNScene won't allow for anything to be saved until a "safe" point can be reached. Instead, VNScene saves
    // its data into this dictionary object beforehand, and if the user attempts to save the game in the middle of an effect,
    // they will only save the "safe" information instead of anything dangerous. Of course, when the "dangerous" part ends,
    // this dictionary is deleted, and things can be saved as normal.
    var safeSave        = NSMutableDictionary()
    
    // View data
    var viewSettings    = NSMutableDictionary()
    var viewSize        = CGSize(width: 0, height: 0)
    
    var effectIsRunning                 = false
    var isPlayingMusic                  = false
    var noSkippingUntilTextIsShown      = false
    var backgroundMusic:AVAudioPlayer?  = nil
    
    var soundsLoaded        = NSMutableArray()
    var buttons             = NSMutableArray()
    var choices             = NSMutableArray() // Holds values that will be used when making choices
    var choiceExtras        = NSMutableArray() // Holds extra data that's used when making choices (usually, flag data)
    var buttonPicked        = -1 // Keeps track of the most recently touched button in the menu
    
    var sprites             = NSMutableDictionary()
    var spritesToRemove     = NSMutableArray()
    var localSpriteAliases  = NSMutableDictionary()
    
    var speechBox:SKSpriteNode? // Dialogue box
    var speech:SMTextNode?  // The text displayed as dialogue
    var speaker:SMTextNode? // Name of speaker
    var speechBoxColor              = UIColor.white
    var speechBoxTextColor          = UIColor.white
    
    var speechFont                  = ""; // The name of the font used by the speech text
    var speakerFont                 = "Helvetica"; // The name of the font used by the speaker text
    var fontSizeForSpeech           = CGFloat( 17.0 )
    var fontSizeForSpeaker          = CGFloat( 19.0 )
    
    var spriteTransitionSpeed           = Double( 0.5 )
    var speechTransitionSpeed           = Double( 0.5 )
    var speakerTransitionSpeed          = Double( 0.5 )
    var buttonTouchedColors             = UIColor.blue
    var buttonUntouchedColors           = UIColor.black
    var buttonTextColor                 = UIColor.white
    var choiceButtonOffsetX             = CGFloat(0)
    var choiceButtonOffsetY             = CGFloat(0)
    var choiceboxFadein                 = true
    var choiceboxFadeSpeed              = TimeInterval(0.2)
    var choiceboxBlinkSpeed             = TimeInterval(0) // default of zero means no blink; anything higher is the blink duration in seconds
    var choiceboxMinimumOpacity         = CGFloat(0.5)
    
    var previousScene:SKScene?          = nil
    var allSettings:NSDictionary?
    
    var isFinished              = false
    var wasJustLoadedFromSave   = true
    var popSceneWhenDone        = false
    
    // Typewriter text
    var TWModeEnabled                   = false; // Off by default (standard EKVN text mode)
    var TWCanSkip                       = true; // Can the user skip ahead (and cut the text short) by tapping?
    var TWSpeedInCharacters             = 0; // How many characters it should print per second
    var TWSpeedInFrames                 = 0
    var TWTimer                         = 0; // Used to determine how many characters should be displayed (relative to the time/speed of displaying characters)
    var TWSpeedInSeconds                = 0.0
    var TWNumberOfCurrentCharacters     = 0
    var TWPreviousNumberOfCurrentChars  = 0
    var TWNumberOfTotalCharacters       = 0
    var TWCurrentText                   = " " // What's currently on the screen
    var TWFullText                      = " " // The entire line of text
    var TWCurrentSpeakerText            = " "
    var TWFullSpeakerText               = " "
    // Used to handle SpriteKit's weird text-display quirks
    var TWInvisibleText:SMTextNode? = nil
    var TWInvisibleSpeakerText:SMTextNode? = nil
    
    // Choice sets, used to store dynamically added/removed choices
    var choiceSets = NSMutableDictionary()
    
    // MARK: Initialization
    
    override init() {
        super.init()
    }
    
    init(settings:NSDictionary) {
        super.init()
        allSettings = NSDictionary(dictionary: settings) // copy all dictionary values
    }
    
    // Just something that Xcode wants me to put in
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        print("[VNSceneNode] ERROR: Initialization via NSCoder has not been implemented!")
    }
    
    func loadDataOnView(view:SKView) {
        SMUtility.Screen.setSizeFromView(view: view) // Get view and screen size data; this is used to position UI elements
    
        //let fooW = view.frame.size.width
        //let fooH = view.frame.size.height
        //print("Width is \(fooW) and height is \(fooH)")
        
        isFinished                  = false
        isUserInteractionEnabled    = true
        wasJustLoadedFromSave       = true
        popSceneWhenDone            = true
        
        // Set default values
        mode            = VNSceneModeLoading; // Mode is "loading resources"
        effectIsRunning = false;
        isPlayingMusic  = false;
        buttonPicked    = -1;
        soundsLoaded    = NSMutableArray()
        sprites         = NSMutableDictionary()
        record          = NSMutableDictionary(dictionary: allSettings!)
        flags           = NSMutableDictionary(dictionary: SMRecord.flags())
        choiceSets      = NSMutableDictionary(dictionary: SMRecord.choiceSetsFromRecord())
        // Also set the defaults for text-skipping behavior
        noSkippingUntilTextIsShown = false
        
        // Set default UI values
        fontSizeForSpeaker  = 0.0;
        fontSizeForSpeech   = 0.0;
        
        viewSize = view.frame.size
        
        // Try to load script info from any saved script data that might exist. Otherwise, just create a fresh script object
        let savedScriptInfo:NSDictionary? = allSettings!.object(forKey: VNSceneSavedScriptInfoKey) as? NSDictionary
        
        // Was there previous saved script / saved game data?
        if( savedScriptInfo != nil ) {
            // Load script data from a saved game
            let loadedScript:VNScript? = VNScript(info: savedScriptInfo!)
            if( loadedScript == nil ) {
                print("[SMRecord] ERROR: Could not load VNScript object.")
                return
            }
            
            script = loadedScript!
            wasJustLoadedFromSave = true // Set flag; this is important since it's meant to prevent autosave errors
            script!.indexesDone = script!.currentIndex
            print("[VNSceneNode] Settings were loaded from a saved game.")
            
        } else { // No previous saved data
            let scriptFileName:NSString? = allSettings!.object(forKey: VNSceneToPlayKey) as? NSString
            if( scriptFileName == nil ) {
                print("[VNSceneNode] ERROR: Could not load script file for new scene.")
                return
            } else {
                print("[VNSceneNode] The name of the script to be loaded is [\(scriptFileName!)]")
            }
            
            // Create the dictionary that will be used to load script data from a file
            let dictionaryForScriptLoading = NSMutableDictionary()
            dictionaryForScriptLoading.setValue(scriptFileName, forKey: VNScriptFilenameKey)
            dictionaryForScriptLoading.setValue(VNScriptStartingPoint, forKey: VNScriptConversationNameKey)
            
            // Create script data
            let loadedScript:VNScript? = VNScript(info: dictionaryForScriptLoading)
            if loadedScript == nil {
                print("[VNSceneNode] ERROR: Could not load script named: \(String(describing: scriptFileName))")
                return
            }
            
            // Otherwise...
            print("[VNSceneNode] Settings were loaded from a script file.")
            script = loadedScript
        }
        
        // Load default view settings
        //[self loadDefaultViewSettings) // The standard settings
        loadDefaultViewSettings()
        print("[VNSceneNode] Default view settings loaded.");
        
        // Load any "extra" view settings that may exist in a certain Property List file ("VNScene View Settings.plist")
        //NSString* filePath = [[NSBundle mainBundle] pathForResource:VNSceneViewSettingsFileName ofType:@"plist")
        let filePath:NSString? = Bundle.main.path(forResource: VNSceneViewSettingsFileName, ofType: "plist") as NSString?
        if filePath != nil {
            
            let manualSettings:NSDictionary? = NSDictionary(contentsOfFile: filePath! as String)
            
            if manualSettings != nil {
                print("[VNSceneNode] Manual settings found; will load into view settings dictionary.")
                viewSettings.addEntries(from: manualSettings! as! [AnyHashable: Any]) // Copy custom settings to UI dictionary; overwrite default values
            }
        }
        
        // This mimics cocos2d's ability to "pop" a scene when it's finished running... however, SpriteKit doesn't
        // have built-in push/pop support for SKScene, so it has to be done manually, and in some cases it might
        // not be a good idea (such as if there's no previous scene to pop to). This flag tracks whether or not
        // to attempt to "pop" the scene when it's finished.
        let shouldPopWhenDone:NSNumber? = record.object(forKey: VNScenePopSceneWhenDoneKey) as? NSNumber
        if( shouldPopWhenDone != nil ) {
            popSceneWhenDone = shouldPopWhenDone!.boolValue
        }
        
        loadUI() // Load the UI using settings dictionary
        
        print("[VNSceneNode] This instance of VNScene will now become the primary VNScene instance.");
        VNSceneNodeSharedInstance = self;
    }
    
    // MARK: Audio
    
    func stopBGMusic() {
        if backgroundMusic != nil {
            backgroundMusic!.stop()
        }
        
        isPlayingMusic = false;
    }
    
    func playBGMusic( filename:String, willLoopForever:Bool ) {
        stopBGMusic()
        
        if SMUtility.Strings.lengthOf(string: filename) < 1 {
            print("[VNSceneNode] ERROR: Could not load background music because input filename is invalid.")
            return;
        }
        
        backgroundMusic = SMUtility.Audio.soundFromFile(filename: filename)
        if backgroundMusic == nil {
            print("[VNSceneNode] ERROR: Could not load background music from file named: \(filename)")
            return;
        }
        
        if willLoopForever == true {
            backgroundMusic!.numberOfLoops = -1
        }
        
        backgroundMusic!.play()
        isPlayingMusic = true;
    }
    
    //- (void)playSoundEffect:(NSString*)filename
    func playSoundEffect( filename:String ) {
        if SMUtility.Strings.lengthOf(string: filename) < 1 {
            print("[VNSceneNode] ERROR: Could not play sound effect because input filename was invalid.")
            return;
        }
        
        let playSoundEffectAction = SKAction.playSoundFileNamed(filename, waitForCompletion: false)
        self.run(playSoundEffectAction)
    }
    
    // MARK: Other setup or deletion functions
    
    // The state of VNScene's UI is stored whenever the game is saved. That way, in case music is playing, or some text is
    // supposed to be on screen, VNScene will remember and SHOULD restore things to exactly the way they were when the game
    // was saved. The restoration of UI is what this function is for.
    func loadSavedResources() {
        // Load any saved resource information from the dictionary
        let savedSprites                = record.object(forKey: VNSceneSpritesToShowKey)              as? NSArray
        let loadedMusic                 = record.object(forKey: VNSceneMusicToPlayKey)                as? NSString
        let savedBackground             = record.object(forKey: VNSceneBackgroundToShowKey)           as? NSString
        let savedSpeakerName            = record.object(forKey: VNSceneSpeakerNameToShowKey)          as? NSString
        let savedSpeech                 = record.object(forKey: VNSceneSpeechToDisplayKey)            as? NSString
        let savedSpeechbox              = record.object(forKey: VNSceneSavedOverriddenSpeechboxKey)   as? NSString
        let showSpeechKey               = record.object(forKey: VNSceneShowSpeechKey)                 as? NSNumber
        let musicShouldLoop             = record.object(forKey: VNSceneMusicShouldLoopKey)            as? NSNumber
        let savedBackgroundX            = record.object(forKey: VNSceneBackgroundXKey)                as? NSNumber
        let savedBackgroundY            = record.object(forKey: VNSceneBackgroundYKey)                as? NSNumber
        
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
            speaker!.text = savedSpeakerName! as String
        }
        
        // Load speech data (if any exists)
        if( savedSpeech != nil ) {
            speech!.text = savedSpeech! as String
        }
        
        if wasJustLoadedFromSave == true {
            speech!.text = " "
        }
        
        // Load background image (CCSprite)
        if( savedBackground != nil ) {
            // Create/load saved background coordinates
            var backgroundX = viewSize.width  * 0.5; // By default, the background would be positioned in the middle of the screen
            var backgroundY = viewSize.height * 0.5;
            
            // Check for custom background coordinates
            if( savedBackgroundX != nil ) {
                backgroundX = CGFloat(savedBackgroundX!.doubleValue)
            }
            if( savedBackgroundY != nil ) {
                backgroundY = CGFloat(savedBackgroundY!.doubleValue)
            }
            
            // Create and add background image node
            let background:SKSpriteNode     = SKSpriteNode(imageNamed:savedBackground! as String)
            background.position             = CGPoint( x: backgroundX, y: backgroundY )
            background.zPosition            = VNSceneBackgroundLayer
            background.name                 = VNSceneTagBackground
            addChild( background )
        }
        
        // Load any music that was saved
        if( loadedMusic != nil ) {
            var loopFlag = true // Default value provided in case the "should loop" flag doesn't couldn't be loaded
            
            if musicShouldLoop != nil {
                loopFlag = musicShouldLoop!.boolValue
            }
            
            isPlayingMusic = true;
            
            playBGMusic(filename: loadedMusic! as String, willLoopForever: loopFlag)
        }
        
        // Check if any sprites need to be displayed
        if( savedSprites != nil ) {
            //print("[VNSceneNode] Sprite data was found in the saved game data.")

            // Check each entry of sprite data that was found, and start loading them into memory and displaying them onto the screen.
            // In theory, the process should be fast enough (and the number of sprites FEW enough) that the user shouldn't notice any delays.
            for spriteData in savedSprites! {
                var doesHaveAlias = true // default assumption, used for loading sprite alias data
                
                // Grab sprite data from dictionary
                let nameOfSprite:NSString = (spriteData as AnyObject).object(forKey: "name") as! NSString
                //print("[VNSceneNode] Restoring saved sprite named: \(nameOfSprite)");
                
                // check for filename
                var filenameOfSprite:NSString? = (spriteData as AnyObject).object(forKey: "filename") as? NSString
                if( filenameOfSprite == nil ) {
                    doesHaveAlias = false
                    filenameOfSprite = nameOfSprite
                }
                
                // Load sprite object and set its coordinates
                let spriteX     = CGFloat(((spriteData as AnyObject).object(forKey: "x") as! NSNumber).doubleValue)
                let spriteY     = CGFloat(((spriteData as AnyObject).object(forKey: "y") as! NSNumber).doubleValue)
                let scaleX      = CGFloat(((spriteData as AnyObject).object(forKey: "scale x") as! NSNumber).doubleValue)
                let scaleY      = CGFloat(((spriteData as AnyObject).object(forKey: "scale y") as! NSNumber).doubleValue)
                
                let sprite          = SKSpriteNode(imageNamed: filenameOfSprite! as String)
                sprite.position     = CGPoint(x: spriteX, y: spriteY)
                sprite.xScale       = scaleX
                sprite.yScale       = scaleY
                sprite.zPosition    = VNSceneCharacterLayer
                addChild(sprite)
                
                // Finally, add the sprite to the 'sprites' dictionary2
                sprites.setValue(sprite, forKey: nameOfSprite as String)
                
                // copy sprite alias data to local sprite aliases dictionary
                if doesHaveAlias == true {
                    localSpriteAliases.setValue(filenameOfSprite, forKey:nameOfSprite as String)
                }
            }
        }
        
        if savedSpeechbox != nil {
            let widthOfScreen               = viewSize.width;//SMScreenSizeInPoints().width
            var originalChildren:NSArray?   = nil
            let boxToBottomMargin           = CGFloat( (viewSettings.object(forKey: VNSceneViewSpeechBoxOffsetFromBottomKey) as! NSNumber).floatValue )
            
            if speechBox != nil {
                originalChildren = speechBox!.children as NSArray?
                speechBox!.removeFromParent()
            }
            
            speechBox               = SKSpriteNode(imageNamed: savedSpeechbox! as String)
            speechBox!.position     = CGPoint( x: widthOfScreen * 0.5, y: (speechBox!.frame.size.height * 0.5) + boxToBottomMargin );
            speechBox!.zPosition    = VNSceneUILayer
            speechBox!.name         = VNSceneTagSpeechBox
            
            self.addChild(speechBox!)
            
            // add children from "old" speech box
            if( originalChildren != nil && originalChildren!.count > 0 ) {
                for someChild in originalChildren! {
                    speechBox!.addChild(someChild as! SKNode)
                }
            }
        }
        
        // make sure the speaker name appears properly
        if savedSpeakerName != nil && speaker != nil {
            speaker!.anchorPoint = CGPoint(x: 0, y: 1.0);
            speaker!.position = self.updatedSpeakerPosition() //[self updatedSpeakerPosition)
            
            // Fade in the speaker name label
            //let fadeIn = SKAction.fadeIn(withDuration: speechTransitionSpeed)
            //speaker!.run(fadeIn)
        }
        
        // Load typewriter text information
        if let TWValueForSpeed = record.object(forKey: VNSceneTypewriterTextSpeed) as? NSNumber {
            TWSpeedInCharacters = TWValueForSpeed.intValue
        }
        if let TWValueForSkip = record.object(forKey: VNSceneTypewriterTextCanSkip) as? NSNumber {
            TWCanSkip = TWValueForSkip.boolValue
        }
        self.updateTypewriterTextSettings()
        
        // choicebox effects
        if let valueForChoiceboxOffsetX = record.object(forKey: VNSceneViewChoiceButtonOffsetX) as? NSNumber {
            choiceButtonOffsetX = CGFloat(valueForChoiceboxOffsetX.doubleValue)
        }
        if let valueForChoiceboxOffsetY = record.object(forKey: VNSceneViewChoiceButtonOffsetY) as? NSNumber {
            choiceButtonOffsetY = CGFloat(valueForChoiceboxOffsetY.doubleValue)
        }
    }
    
    // Loads the default, hard-coded values for the view / UI settings dictionary.
    func loadDefaultViewSettings() {
        let fontSize                = VNSceneViewFontSize;
        let iPadFontSizeMultiplier  = 1.5; // Determines how much larger the "speech text" and speaker name will be on the iPad
        let dialogueBoxName:String  = VNSceneViewTalkboxName;
        
        // Manually enter the default data for the UI
        viewSettings.setValue(1.0,                              forKey: VNSceneViewDefaultBackgroundOpacityKey)
        viewSettings.setValue(0.0,                              forKey: VNSceneViewSpeechBoxOffsetFromBottomKey)
        viewSettings.setValue(0.5,                              forKey: VNSceneViewSpriteTransitionSpeedKey)
        viewSettings.setValue(0.5,                              forKey: VNSceneViewTextTransitionSpeedKey)
        viewSettings.setValue(0.5,                              forKey: VNSceneViewNameTransitionSpeedKey)
        viewSettings.setValue(10.0,                             forKey: VNSceneViewSpeechHorizontalMarginsKey)
        viewSettings.setValue(30.0,                             forKey: VNSceneViewSpeechVerticalMarginsKey)
        viewSettings.setValue(0.0,                              forKey: VNSceneViewSpeechOffsetXKey)
        viewSettings.setValue((fontSize * 2),                   forKey: VNSceneViewSpeechOffsetYKey)
        viewSettings.setValue(0.0,                              forKey: VNSceneViewSpeakerNameXOffsetKey)
        viewSettings.setValue(0.0,                              forKey: VNSceneViewSpeakerNameYOffsetKey)
        viewSettings.setValue((fontSize),                       forKey: VNSceneViewFontSizeKey) // Was 'fontSize'; changed due to iPad font multiplier
        viewSettings.setValue(dialogueBoxName,                  forKey: VNSceneViewSpeechBoxFilenameKey)
        viewSettings.setValue("choicebox.png",                  forKey: VNSceneViewButtonFilenameKey)
        viewSettings.setValue("Helvetica",                      forKey: VNSceneViewFontNameKey)
        viewSettings.setValue((iPadFontSizeMultiplier),         forKey: VNSceneViewMultiplyFontSizeForiPadKey) // This is used for the iPad
        viewSettings.setValue(NSNumber(booleanLiteral: true),   forKey: VNSceneChoiceboxFadeinKey)
        
        // Create default settings for whether or not the "override from save" values should take place.
        viewSettings.setValue(true, forKey:VNSceneViewOverrideSpeakerFontKey)
        viewSettings.setValue(true, forKey:VNSceneViewOverrideSpeakerSizeKey)
        viewSettings.setValue(true, forKey:VNSceneViewOverrideSpeechFontKey)
        viewSettings.setValue(true, forKey:VNSceneViewOverrideSpeechSizeKey)
        
        let buttonTouchedColorsDict     = NSDictionary(dictionary: ["r":0, "g":0, "b":255]) // BLUE <- r0, g0, b255
        let buttonUntouchedColorsDict   = NSDictionary(dictionary: ["r":0, "g":0, "b":0]) // BLACK <- r0, g0, b0
        
        viewSettings.setValue(buttonTouchedColorsDict,      forKey:VNSceneViewButtonsTouchedColorsKey)
        viewSettings.setValue(buttonUntouchedColorsDict,    forKey:VNSceneViewButtonUntouchedColorsKey)
        
        // Load other settings
        viewSettings.setValue(NSNumber(value: false),       forKey:VNSceneViewNoSkipUntilTextShownKey)
    }
    
    // Actually loads images and text for the UI (as opposed to just loading information ABOUT the UI)
    func loadUI() {
        // Load the default settings if they don't exist yet. If there's custom data, the default settings will be overwritten.
        if( viewSettings.count < 1 ) {
            print("[VNSceneNode] Loading default view settings.");
            loadDefaultViewSettings()
        }
        
        // Get screen size data; getting the size/coordiante data is very important for placing UI elements on the screen
        let widthOfScreen = viewSize.width
        
        // Check if this is on an iPad, and if the default font size should be adjusted to compensate for the larger screen size
        if( UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad ) {
            let multiplyFontSizeForiPadFactor:NSNumber? = viewSettings.object(forKey: VNSceneViewMultiplyFontSizeForiPadKey) as? NSNumber // Default is 1.5x
            let standardFontSize:NSNumber? = viewSettings.object(forKey: VNSceneViewFontSizeKey) as? NSNumber // Default value is 17.0
            
            if( multiplyFontSizeForiPadFactor != nil && standardFontSize != nil ) {
                let fontFactor  = multiplyFontSizeForiPadFactor!.doubleValue //[multiplyFontSizeForiPadFactor floatValue)
                let fontSize    = (standardFontSize!.doubleValue) * fontFactor; // Default is standardFontSize * 1.5
                
                viewSettings.setObject(NSNumber(value: fontSize),       forKey:VNSceneViewFontSizeKey as NSCopying)
                
                // The value for the offset key is reset because the font size may have changed, and offsets are affected by this.
                viewSettings.setValue(NSNumber(value: (fontSize * 2)),  forKey:VNSceneViewSpeechOffsetYKey)
            }
        }
        
        // Part 1: Create speech box, and then position it at the bottom of the screen (with a small margin, if one exists).
        //         The default setting is to have NO margin/space, meaning the bottom of the box touches the bottom of the screen.
        
        let speechBoxFile:NSString      = viewSettings.object(forKey: VNSceneViewSpeechBoxFilenameKey) as! NSString
        let boxToBottomValue:NSNumber   = viewSettings.object(forKey: VNSceneViewSpeechBoxOffsetFromBottomKey) as! NSNumber
        let boxToBottomMargin:Double    = boxToBottomValue.doubleValue
        // Create speechbox sprite node and set its data
        speechBox                       = SKSpriteNode(imageNamed: speechBoxFile as String)
        let speechBoxX                  = CGFloat(widthOfScreen * 0.5 )
        let speechBoxHalfHeight         = speechBox!.size.height * 0.5;
        let speechBoxY                  = CGFloat( speechBoxHalfHeight + CGFloat(boxToBottomMargin) )
        speechBox!.position             = CGPoint(x: speechBoxX, y: speechBoxY)
        speechBox!.zPosition            = VNSceneUILayer
        speechBox!.name                 = VNSceneTagSpeechBox
        addChild(speechBox!)
        
        // Save speech box position in the settings dictionary; this is useful in case you need to restore it to its default position later
        viewSettings.setValue( NSNumber(value: Double(speechBox!.position.x)), forKey:"speechbox x")
        viewSettings.setValue( NSNumber(value: Double(speechBox!.position.y)), forKey:"speechbox y")
        
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
        
        // load speechbox color
        let speechBoxColorDictionary = viewSettings.object(forKey: VNSceneViewSpeechboxColorKey) as? NSDictionary
        if speechBoxColorDictionary != nil  {
            let colorR = (speechBoxColorDictionary!.object(forKey: "r") as! NSNumber).intValue
            let colorG = (speechBoxColorDictionary!.object(forKey: "g") as! NSNumber).intValue
            let colorB = (speechBoxColorDictionary!.object(forKey: "b") as! NSNumber).intValue
            
            let theColor = SMUtility.Color.fromRGB(r: colorR, g: colorG, b: colorB)
            
            speechBoxColor = theColor
            print("[VNSceneNode] Speech box color set to \(theColor)")
            
            speechBox!.colorBlendFactor = 1.0;
            speechBox!.color = theColor;
        }
        
        // Part 2: Create the speech label.
        // The "margins" part is tricky. When generating the size for the CCLabelTTF object, it's important to pretend
        // that the margins value is twice as large (as what's stored), since the label's position won't be in the
        // exact center of the speech box, but slightly to the right and down, to create "margins" between speech and
        // the box it's displayed in.
        let verticalMarginValue     = viewSettings.object(forKey: VNSceneViewSpeechVerticalMarginsKey) as! NSNumber
        let horizontalMarginValue   = viewSettings.object(forKey: VNSceneViewSpeechHorizontalMarginsKey) as! NSNumber
        let verticalMargins         = CGFloat(verticalMarginValue.doubleValue)
        let horizontalMargins       = CGFloat(horizontalMarginValue.doubleValue)
        // Width multiplier is used for creating margins (when displaying the speech text). Due to differences in size,
        // the exact value changes between the iPhone and the iPad.
        var widthMultiplierValue:CGFloat = 4.0;
        
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            widthMultiplierValue = 6.0;
        }
        
        let speechSizeWidth     = widthOfSpeechBox - (horizontalMargins * widthMultiplierValue)
        let speechSizeHeight    = heightOfSpeechBox - (verticalMargins * 2.0)
        // Set dimensions
        let speechSize          = CGSize( width: speechSizeWidth, height: speechSizeHeight )
        let fontSizeValue       = viewSettings.object(forKey: VNSceneViewFontSizeKey) as! NSNumber
        let fontSize = CGFloat( fontSizeValue.doubleValue )
        
        // Now actually create the speech label. By default, it's just empty text (until a character/narrator speaks later on)
        //speech = [SMTextNode labelNodeWithFontNamed:[viewSettings.objectForKey(VNSceneViewFontNameKey])
        let fontNameValue = viewSettings.object(forKey: VNSceneViewFontNameKey) as! NSString
        speech = SMTextNode(fontNamed: fontNameValue as String)
        speech!.text = " ";
        speech!.fontSize = fontSize;
        speech!.paragraphWidth = (speechSize.width * 0.92) - (horizontalMargins * widthMultiplierValue);
        
        // Adjust for iPad size differences
        //if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
        if( UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad ) {
            speech!.paragraphWidth = (speechSize.width * 0.94) - (horizontalMargins * widthMultiplierValue);
        }
        
        // Make sure that the position is slightly off-center from where the textbox would be (plus any other offsets that may exist).
        let speechXOffset       = (viewSettings.object(forKey: VNSceneViewSpeechOffsetXKey) as! NSNumber).doubleValue
        let speechYOffset       = (viewSettings.object(forKey: VNSceneViewSpeechOffsetYKey) as! NSNumber).doubleValue
        let originalSpeechPosX  = CGFloat(speechBox!.size.width * 0.5) + CGFloat(speechXOffset)
        let originalSpeechPosY  = speechBox!.size.height * 0.5 + CGFloat(verticalMargins) - CGFloat(speechYOffset)
        let originalSpeechPos   = CGPoint(x: originalSpeechPosX, y: originalSpeechPosY)
        
        let bottomLeftCornerOfSpeechBox = SMUtility.Position.bottomLeftCornerOfSKNode(node: speechBox!);
        speech!.position                = SMUtility.Position.addTwoPoints(first: originalSpeechPos, second: bottomLeftCornerOfSpeechBox);
        speech!.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        speech!.zPosition               = VNSceneTextLayer;
        speech!.name                    = VNSceneTagSpeechText;
        speechBox!.addChild(speech!)
        
        // load speech text colors
        let speechBoxTextColorDict = viewSettings.object(forKey: VNSceneViewSpeechboxTextColorKey) as? NSDictionary
        if speechBoxTextColorDict != nil  {
            let colorR = (speechBoxTextColorDict!.object(forKey: "r") as! NSNumber).intValue
            let colorG = (speechBoxTextColorDict!.object(forKey: "g") as! NSNumber).intValue
            let colorB = (speechBoxTextColorDict!.object(forKey: "b") as! NSNumber).intValue
            
            //let untouchedColor = SMUtility.Color.fromRGB(untouchedR, g: untouchedG, b: untouchedB)
            let theColor = SMUtility.Color.fromRGB(r: colorR, g: colorG, b: colorB)
            
            speechBoxTextColor = theColor
            //print("[VNSceneNode] Speech box color set to \(theColor)")
            
            speech!.colorBlendFactor    = 1.0
            speech!.color               = theColor
        }
        
        /** COPY TO TWINVISIBLE TEXT **/
        TWInvisibleText                             = SMTextNode(fontNamed: fontNameValue as String)
        TWInvisibleText!.text                       = " ";
        TWInvisibleText!.fontSize                   = speech!.fontSize
        TWInvisibleText!.paragraphWidth             = speech!.paragraphWidth
        TWInvisibleText!.position                   = speech!.position
        TWInvisibleText!.horizontalAlignmentMode    = speech!.horizontalAlignmentMode
        TWInvisibleText!.zPosition                  = speech!.zPosition
        TWInvisibleText!.alpha                      = 0.0; // make sure this really is invisible
        TWInvisibleText!.name                       = "TWInvisibleText"
        speechBox!.addChild(TWInvisibleText!)
        
        // Part 3: Create speaker label
        // But first, figure out all the offsets and sizes.
        var speakerNameOffsets  = CGPoint( x: 0.0, y: 0.0 );
        let speakerSize         = CGSize( width: widthOfSpeechBox  * 0.99, height: speechBox!.size.height * 0.95  );
        
        let speakerNameOffsetXValue:NSNumber? = viewSettings.object(forKey: VNSceneViewSpeakerNameXOffsetKey) as? NSNumber
        let speakerNameOffsetYValue:NSNumber? = viewSettings.object(forKey: VNSceneViewSpeakerNameYOffsetKey) as? NSNumber
        if( speakerNameOffsetXValue != nil ) {
            speakerNameOffsets.x = CGFloat(speakerNameOffsetXValue!.doubleValue)
        }
        if( speakerNameOffsetYValue != nil ) {
            speakerNameOffsets.y = CGFloat(speakerNameOffsetYValue!.doubleValue)
        }
        
        // Add the speaker to the speech-box. The "name" is just empty text by default, until an actual name is provided later.
        //speaker = [SMTextNode labelNodeWithFontNamed:[viewSettings.objectForKey(VNSceneViewFontNameKey])
        //speaker = SMTextNode(fontNamed:fontNameValue as String)
        speaker                             = SMTextNode(fontNamed: fontNameValue as String)
        speaker!.text                       = " ";
        speaker!.fontSize                   = CGFloat(fontSize * 1.1) // 1.1 is used as a "magic number" because it looks OK
        speaker!.paragraphWidth             = speakerSize.width;
        speaker!.horizontalAlignmentMode    = SKLabelHorizontalAlignmentMode.left;
        
        // Position the label and then add it to the display
        let speakerPosX                     = (speechBox!.frame.size.width * -0.5) + (speaker!.frame.size.width * 0.5)
        let speakerPosY                     = speechBox!.frame.size.height
        speaker!.position                   = CGPoint( x: speakerPosX, y: speakerPosY );
        speaker!.zPosition                  = VNSceneTextLayer;
        speaker!.name                       = VNSceneTagSpeakerName;
        speechBox!.addChild(speaker!);
        
        // set speaker color value
        speaker!.color = speechBoxTextColor
        speaker!.colorBlendFactor = 1.0
        
        // Part 4: Load the button colors
        // First load the default colors
        buttonUntouchedColors   = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0) // black
        buttonTouchedColors     = UIColor(red: 0, green: 0, blue: 1.0, alpha: 1.0) // blue
        
        // Grab dictionaries from view settings
        let buttonUntouchedColorsDict       = viewSettings.object(forKey: VNSceneViewButtonUntouchedColorsKey)  as? NSDictionary
        let buttonTouchedColorsDict         = viewSettings.object(forKey: VNSceneViewButtonsTouchedColorsKey)   as? NSDictionary
        let buttonTextColorDict             = viewSettings.object(forKey: VNSceneViewButtonTextColorKey)        as? NSDictionary
        
        
        // Copy values from the dictionary
        if( buttonUntouchedColorsDict != nil ) {
            let untouchedR = (buttonUntouchedColorsDict!.object(forKey: "r") as! NSNumber).intValue
            let untouchedG = (buttonUntouchedColorsDict!.object(forKey: "g") as! NSNumber).intValue
            let untouchedB = (buttonUntouchedColorsDict!.object(forKey: "b") as! NSNumber).intValue
            
            let untouchedColor = SMUtility.Color.fromRGB(r: untouchedR, g: untouchedG, b: untouchedB)
            
            buttonUntouchedColors = untouchedColor
            print("[VNSceneNode] Button untouched colors set to \(buttonUntouchedColors)")
        }
        
        if( buttonTouchedColorsDict != nil ) {
            //println("[VNSceneNode] Touched buttons colors settings = %@", buttonTouchedColorsDict);
            let touchedR = (buttonTouchedColorsDict!.object(forKey: "r") as! NSNumber).intValue
            let touchedG = (buttonTouchedColorsDict!.object(forKey: "g") as! NSNumber).intValue
            let touchedB = (buttonTouchedColorsDict!.object(forKey: "b") as! NSNumber).intValue
            
            let touchedColor = SMUtility.Color.fromRGB(r:  touchedR, g: touchedG, b: touchedB)
            buttonTouchedColors = touchedColor
        }
        
        if buttonTextColorDict != nil {
            let R = (buttonTextColorDict!.object(forKey: "r") as! NSNumber).intValue
            let G = (buttonTextColorDict!.object(forKey: "g") as! NSNumber).intValue
            let B = (buttonTextColorDict!.object(forKey: "b") as! NSNumber).intValue
            
            let theColor = SMUtility.Color.fromRGB(r: R, g: G, b: B)
            buttonTextColor = theColor
        }
        
        // Part 5: Load transition speeds
        spriteTransitionSpeed   = (viewSettings.object(forKey: VNSceneViewSpriteTransitionSpeedKey) as! NSNumber).doubleValue
        speechTransitionSpeed   = (viewSettings.object(forKey: VNSceneViewTextTransitionSpeedKey) as! NSNumber).doubleValue
        speakerTransitionSpeed  = (viewSettings.object(forKey: VNSceneViewNameTransitionSpeedKey) as! NSNumber).doubleValue
        
        // Part 6: Load choicebox settings (especially regarding blinking)
        if let choiceboxBlinkSpeedValue = viewSettings.object(forKey: VNSceneViewChoiceButtonBlinkSpeedKey) as? NSNumber {
            choiceboxBlinkSpeed = TimeInterval( choiceboxBlinkSpeedValue.doubleValue )
            
            if choiceboxBlinkSpeed < 0 {
                choiceboxBlinkSpeed = 0
            }
        }
        if let choiceboxBlinkMinimumOpacityValue = viewSettings.object(forKey: VNSceneViewChoiceButtonBlinkMinOpacity) as? NSNumber {
            choiceboxMinimumOpacity = CGFloat( choiceboxBlinkMinimumOpacityValue.doubleValue )
            
            if choiceboxMinimumOpacity < 0 {
                choiceboxMinimumOpacity = 0
            }
            if choiceboxMinimumOpacity > 1.0 {
                choiceboxMinimumOpacity = 1.0
            }
        }
        
        // Override those settings from saves, if they exist
        if let overrideChoiceBlinkSpeed = record.object(forKey: VNSceneOverrideChoiceBlinkSpeed) as? NSNumber {
            choiceboxBlinkSpeed = TimeInterval( overrideChoiceBlinkSpeed.doubleValue )
        }
        if let overrideChoiceMinOpacity = record.object(forKey: VNSceneOverrideChoiceMinOpacity) as? NSNumber {
            choiceboxMinimumOpacity = CGFloat( overrideChoiceMinOpacity.doubleValue )
        }
        
        // Part 7: Load other overrides, if any are found
        let overrideSpeechFont:NSString?    = record.object(forKey: VNSceneOverrideSpeechFontKey) as? NSString
        let overrideSpeakerFont:NSString?   = record.object(forKey: VNSceneOverrideSpeakerFontKey) as? NSString
        let overrideSpeechSize:NSNumber?    = record.object(forKey: VNSceneOverrideSpeechSizeKey) as? NSNumber
        let overrideSpeakerSize:NSNumber?   = record.object(forKey: VNSceneOverrideSpeakerSizeKey) as? NSNumber
        
        let shouldOverrideSpeechFont    = (viewSettings.object(forKey: VNSceneViewOverrideSpeechFontKey) as! NSNumber).boolValue
        let shouldOverrideSpeechSize    = (viewSettings.object(forKey: VNSceneViewOverrideSpeechSizeKey) as! NSNumber).boolValue
        let shouldOverrideSpeakerFont   = (viewSettings.object(forKey: VNSceneViewOverrideSpeakerFontKey) as! NSNumber).boolValue
        let shouldOverrideSpeakerSize   = (viewSettings.object(forKey: VNSceneViewOverrideSpeakerSizeKey) as! NSNumber).boolValue
        
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
        
        // load choicebox/choice-button offsets
        if let valueForChoiceboxOffsetX = viewSettings.object(forKey: VNSceneViewChoiceButtonOffsetX) as? NSNumber {
            choiceButtonOffsetX = CGFloat(valueForChoiceboxOffsetX.doubleValue)
        }
        if let valueForChoiceboxOffsetY = viewSettings.object(forKey: VNSceneViewChoiceButtonOffsetY) as? NSNumber {
            choiceButtonOffsetY = CGFloat(valueForChoiceboxOffsetY.doubleValue)
        }
        
        // Part 8: Load extra features
        let blockSkippingUntilTextIsDone:NSNumber? = viewSettings.object(forKey: VNSceneViewNoSkipUntilTextShownKey) as? NSNumber
        if( blockSkippingUntilTextIsDone != nil ) {
            noSkippingUntilTextIsShown = blockSkippingUntilTextIsDone!.boolValue
        }
        
        // choicebox fade-in settings
        if let choiceboxFadeInValue = viewSettings.object(forKey: VNSceneChoiceboxFadeinKey) as? NSNumber {
            choiceboxFadein = choiceboxFadeInValue.boolValue
        }
        if let choiceboxFadeSpeedValue = viewSettings.object(forKey: VNSceneChoiceboxFadeTimeKey) as? NSNumber {
            choiceboxFadeSpeed = TimeInterval(choiceboxFadeSpeedValue.doubleValue)
        }
    }
    
    // Removes unused character sprites (CCSprite objects) from memory.
    //- (void)removeUnusedSprites
    func removeUnusedSprites() {
        // Check if there are no unused sprites to begin with
        if( spritesToRemove.count < 1 ) {
            return
        }
        
        print("[VNSceneNode] Will now remove unused sprites - \(spritesToRemove.count) found.")
        
        // Just keep removing whatever's in the first index of 'spritesToRemove' until there's nothing left
        while spritesToRemove.count > 0 {
            let sprite:SKSpriteNode = spritesToRemove.object(at: 0) as! SKSpriteNode
            
            // If the sprite has no parent node (and is marked as safe to remove), then it's time to get rid of it
            if( sprite.parent != nil && sprite.name!.caseInsensitiveCompare(VNSceneSpriteIsSafeToRemove) == ComparisonResult.orderedSame ) {
                // remove from array also, before removing from parent node
                spritesToRemove.remove(sprite)
                sprite.removeFromParent()
            }
        }
    }
    
    // This takes all the "active" sprites and moves them to the "inactive" list. If you really want to remove them from memory, you
    // should call 'removeUnusedSprites' soon afterwards; that will actually remove the CCSprite objects from RAM.
    func markActiveSpritesAsUnused() {
        if sprites.count < 1 {
            return
        }
        
        // Grab all the sprites (by name or "key") and relocate them to the "inactive sprites" list
        //for( NSString* spriteName in [sprites allKeys] ) {
        for spriteName in sprites.allKeys {
            let spriteToRelocate        = sprites.object(forKey: spriteName) as! SKSpriteNode
            spriteToRelocate.alpha      = 0.0;                          // Mark as invisble/inactive (inactive as far as VNScene is concerned)
            spriteToRelocate.name       = VNSceneSpriteIsSafeToRemove;  // Mark as definitely unused
            
            spritesToRemove.add(spriteToRelocate)                       // Push to inactive sprites array
            sprites.removeObject(forKey: spriteName)                    // Remove from "active sprites" dictionary
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
            stopBGMusic()
            isPlayingMusic = false; // Make sure this is set to NO, since the function might be called more than once!
        }
        
        // Now, forcibly get rid of anything that might have been missed
        if self.children.count > 0 {
            print("[VNSceneNode] Will now forcibly remove all child nodes of this layer.");
            removeAllChildren()
            print("[VNSceneNode] All child nodes have been removed.");
        }
    }
    
    // MARK: - Choice button helper functions
    
    func setLabelForButton(button:SKSpriteNode, label:String) {
        // Determine where the text should be positioned inside the button
        var labelWithinButtonPos = CGPoint( x: button.frame.size.width * 0.5, y: button.frame.size.height * 0.35 );
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            labelWithinButtonPos.y = button.frame.size.height * 0.31;
        }
        
        // Create button label, set the position of the text, and add this label to the main 'button' sprite
        let labelFontName       = SMUtility.Dictionaries.stringFromDictionary(dictionary: viewSettings, name: VNSceneViewFontNameKey)
        let labelFontSizeNumber = SMUtility.Dictionaries.numberFromDictionary(dictionary: viewSettings, name: VNSceneViewFontSizeKey)
        let labelFontSize       = CGFloat( labelFontSizeNumber.doubleValue )
        
        let buttonLabel         = SKLabelNode(fontNamed: labelFontName)
        buttonLabel.fontSize    = labelFontSize
        buttonLabel.text        = label //choiceTexts.object(at: i) as! NSString as String
        buttonLabel.zPosition   = VNSceneButtonsLayer
        buttonLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        
        // set button text color
        buttonLabel.color               = buttonTextColor;
        buttonLabel.colorBlendFactor    = 1.0;
        buttonLabel.fontColor           = buttonTextColor;
        
        // Position Y coordinate
        var buttonLabelY:CGFloat = 0 - (button.size.height * 0.20)
        
        if( UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad ) {
            buttonLabelY = 0 - (button.size.height * 0.20)
        }
        
        buttonLabel.position = CGPoint(x: 0, y: buttonLabelY)
        
        button.addChild(buttonLabel)
        button.colorBlendFactor = 1.0;
    }
    
    func arrayOfButtonSprites(numberOfButtons:Int) -> NSArray? {
        if( numberOfButtons < 1 ) {
            print("[VNSceneNode] ERROR: arrayOfButtonSprites was called with invalid parameter of \(numberOfButtons)")
            return nil;
        }
        
        let arrayOfButtons  = NSMutableArray()
        let screenWidth     = viewSize.width
        let screenHeight    = viewSize.height
        
        for i in 0..<numberOfButtons {
            let loopIndex = CGFloat( i )
            
            let buttonFilename  = viewSettings.object(forKey: VNSceneViewButtonFilenameKey) as! NSString
            let button          = SKSpriteNode(imageNamed: buttonFilename as String)
            
            // Calculate the amount of space (including space between buttons) that each button will take up, and then
            // figure out the position of the button that's being made. Ideally, the middle of the choice menu will also be the middle
            // of the screen. Of course, if you have a LOT of choices, there may be more buttons than there is space to put them!
            let spaceBetweenButtons         = button.frame.size.height * 0.2; // 20% of button sprite height
            let buttonHeight                = button.frame.size.height;
            let totalButtonSpace            = buttonHeight + spaceBetweenButtons; // total used-up space = 120% of button height
            let heightPercentage            = choiceButtonStartingYFactor(numberOfChoices: numberOfButtons)
            let startingPosition:CGFloat    = (screenHeight * heightPercentage) - ( ( CGFloat(numberOfButtons) * 0.5 ) * totalButtonSpace ) + choiceButtonOffsetY
            let buttonY                     = startingPosition + ( loopIndex * totalButtonSpace ); // This button's position
            
            // Set button position and other attributes
            button.position     = CGPoint( x: (screenWidth * 0.5) + choiceButtonOffsetX, y: buttonY );
            button.color        = buttonUntouchedColors;
            button.zPosition    = VNSceneButtonsLayer;
            
            arrayOfButtons.add(button)
        }
        
        return NSArray(array: arrayOfButtons)
    }
    
    // Pass in an NSArray of labels (strings) and an NSArray filled with buttons (SKSpriteNode), and these will apply the labels to the buttons
    func addLabelsToArrayOfButtons(arrayOfLabels:NSArray, arrayOfButtons:NSArray) {
        if arrayOfButtons.count < 1 {
            print("[VNSceneNode] addLabelsToArrayOfButtons - ERROR: Array of buttons has no items.")
            return;
        }
        if arrayOfLabels.count < arrayOfButtons.count {
            print("[VNSceneNode] addLabelsToArrayOfButtons - WARNING: Not enough labels for each button.")
        }
        
        for i in 0..<arrayOfButtons.count {
            if let currentButton = arrayOfButtons.object(at: i) as? SKSpriteNode {
                if let currentLabel = arrayOfLabels.object(at: i) as? String {
                    //setLabelForButton(currentButton, currentLabel)
                    setLabelForButton(button: currentButton, label: currentLabel)
                }
            }
        }
    }
    
    
    func addButtonsToScene(arrayOfButtons:NSArray) {
        if arrayOfButtons.count < 1 {
            return;
        }
        
        for i in 0..<arrayOfButtons.count {
            if let button = arrayOfButtons.object(at: i) as? SKSpriteNode {
                self.addChild(button)
                buttons.add(button)
                
                if choiceboxFadein == true {
                    // fade in the box
                    button.alpha = 0.0
                    
                    if choiceboxFadeSpeed <= 0.0 {
                        choiceboxFadeSpeed = 0.1
                    }
                    
                    let fadeInAction = SKAction.fadeIn(withDuration: choiceboxFadeSpeed)
                    button.run(fadeInAction)
                }
                
                // Make all the child nodes of the button blink, assuming there's a valid blink duration (basically anything above zero)
                if choiceboxBlinkSpeed > 0 && button.children.count > 0 {
                    for childNodeInChoicebox in button.children {
                        let blinkActionDuration = choiceboxBlinkSpeed * 0.5 // uses half the total duration because the duration is spread across two different actions
                        let blinkFadeOut        = SKAction.fadeAlpha(to: choiceboxMinimumOpacity, duration: blinkActionDuration )
                        let blinkFadeIn         = SKAction.fadeAlpha(to: 1.0, duration: blinkActionDuration)
                        let blinkSequence       = SKAction.sequence([blinkFadeOut, blinkFadeIn])
                        let blinkForever        = SKAction.repeatForever(blinkSequence)
                        
                        // apply repeated blinking action to this child node
                        childNodeInChoicebox.run( blinkForever )
                    }
                }
            } // if let button
        } // end for loop
    } // end addButtonsToScene
    
    // MARK: - Choice sets

    // Adds a destination:"choice text" string combination to a choice set that's been stored in the choice sets dictionary
    func addToChoiceSet(setName:String, destination:String, choiceText:String) {
        var choiceSetObject : NSMutableDictionary? = nil

        if let savedSet = choiceSets.object(forKey: setName) as? NSMutableDictionary {
            //choiceSetObject = NSMutableDictionary(dictionary: savedSet)
            choiceSetObject = savedSet
        } else {
            choiceSetObject = NSMutableDictionary()
            choiceSets.setValue(choiceSetObject, forKey: setName)
        }

        choiceSetObject!.setValue(choiceText, forKey: destination)

        //print("Choice sets currently are: \(choiceSets)")
    }

    // Removes an existing destination/choice combination from a Choice Set
    func removeFromChoiceSet(setName:String, destination:String) {
        if let savedSet = choiceSets.object(forKey: setName) as? NSMutableDictionary {
            savedSet.removeObject(forKey: destination)
        }
    }

    // Remove an entire Choice Set
    func wipeChoiceSet(setName:String) {
        choiceSets.removeObject(forKey: setName)
    }

    // Display a choice set
    func displayChoiceSet(setName:String) {
        if let savedSet = choiceSets.object(forKey: setName) as? NSMutableDictionary {
            if savedSet.count < 1 {
                print("[VNSceneNode] WARNING: There were no choices found in the Choice Set \(setName), so nothing was displayed.")
                return
            }

            self.createSafeSave() // Always create safe-save before doing something volatile

            let choiceTexts = NSMutableArray()
            let destinations = NSMutableArray()

            // Populate the arrays
            for currentDestination in savedSet.allKeys {
                let destinationText = currentDestination as! String
                let currentChoiceText = savedSet.object(forKey: destinationText) as! String
                destinations.add(destinationText)
                choiceTexts.add(currentChoiceText)
            }

            // Make sure the arrays that hold the data are prepared
            buttons.removeAllObjects()
            choices.removeAllObjects()
            
            if let arrayOfButtons = arrayOfButtonSprites(numberOfButtons: choiceTexts.count) {
                addLabelsToArrayOfButtons(arrayOfLabels: choiceTexts, arrayOfButtons: arrayOfButtons)
                addButtonsToScene(arrayOfButtons: arrayOfButtons)
                SMUtility.Arrays.addObjectsToMutableArray(destination: choices, source: destinations)
                mode = VNSceneModeChoiceWithJump
            } else {
                print("[VNSceneNode] displayChoiceSet - WARNING: Could not create array of buttons!")
            }
        }
    }
    
    // MARK: Misc and Utility
    
    // Updates data regarding speed (and whether or not typewriter mode should be enabled). This should only get called occasionally,
    // such as when this speed values are changed.
    func updateTypewriterTextSettings() {
        // check if the speed is at or below zero, meaning that typewriter text mode will be off and text shows instantly
        if TWSpeedInCharacters <= 0 {
            TWModeEnabled = false
            TWTimer = 0
        } else {
            // otherwise it's enabled
            TWModeEnabled = true
            
            // Calculate speed in seconds based on characters per second
            let charsPerSecond = Double(TWSpeedInCharacters)
            TWSpeedInSeconds = (60.0) / charsPerSecond; // at 60fps this is 60/characters-per-second
            
            let speedInFrames = (60.0) * TWSpeedInSeconds;
            TWSpeedInFrames = Int(speedInFrames)
            TWTimer = 0; // This gets reset
            
            //print("[VNSceneNode] DIAGNOSTIC: Typewriter Text - speed in seconds: \(TWSpeedInSeconds) | speed in frames: \(TWSpeedInFrames)");
        }
        
        record.setValue(NSNumber(value: TWSpeedInCharacters), forKey: VNSceneTypewriterTextSpeed)
        record.setValue(NSNumber(value: TWCanSkip), forKey: VNSceneTypewriterTextCanSkip)
    }
    
    // This gets called every frame to determine how to display labels when typewriter text is enabled.
    func updateTypewriterTextDisplay() {
        if TWSpeedInCharacters < 1 {
            return;
        }
        
        var shouldRedrawText = false; // Determines whether or not to go through the trouble of recalculating text node positions
        
        // Used to calculate how many characters to display (in each frame)
        let currentChars        = Double(TWNumberOfCurrentCharacters)
        let charsPerSecond      = Double(TWSpeedInCharacters)
        let charsPerFrame       = (charsPerSecond / 60.0)
        let c                   = currentChars + charsPerFrame
        
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
            
            let TWIndex: String.Index = TWFullText.index(TWFullText.startIndex, offsetBy: numberOfCharsToUse)
            //TWCurrentText = TWFullText.substring(to: TWIndex)
            //TWCurrentText = "\(TWFullText[..<TWIndex])"
            TWCurrentText = String(TWFullText[..<TWIndex])
            
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
            
            speech!.position = CGPoint(x: someX, y: someY)
        }
    }
    
    // just a quick utility function designed to quickly tell if this is portrait mode or not
    func viewIsPortrait() -> Bool {
        let width = viewSize.width
        let height = viewSize.height
        
        if( width > height ) {
            return false
        }
        
        return true
    }
    
    // Used to retrieve potential sprite alias names from the local sprite alias dictionary
    func filenameOfSpriteAlias(_ someName:String) -> String {
        let filenameOfSprite:String? = self.localSpriteAliases.object(forKey: someName) as? String
        
        // Check if the corresponding filename was NOT found in the alias list
        if filenameOfSprite == nil {
            // In this case, just return the original name, which can be assumed to be an actual filename already
            return String(someName)
        }
        
        // Otherwise, assume that the filename was found
        return String(filenameOfSprite!)
    }
    
    // The set/clear effect-running-flag functions exist so that Cocos2D can call them after certain actions
    // (or sequences of actions) have been run. The "effect is running" flag is important, since it lets VNScene
    // know when it's safe (or unsafe) to do certain things (which might interrupt the effect that's being run).
    func setEffectRunningFlag() {
        print("[VNSceneNode] Effect will be running.");
        effectIsRunning = true;
        mode = VNSceneModeEffectIsRunning;
    }
    
    func clearEffectRunningFlag() {
        effectIsRunning = false;
        print("[VNSceneNode] Effect is no longer running.");
    }
    
    // Update script info. This consists of index data, the script name, and which conversation/section is the current one
    // being displayed (or run) before the player.
    func updateScriptInfo() {
        if( script != nil ) {
            // Save existing script information (indexes, "current" conversation name, etc.) in the record.
            // This overwrites any script information which may already have been stored.
            record.setValue(script!.info(), forKey: VNSceneSavedScriptInfoKey)
        }
    }
    
    // This saves important information (script info, flags, which resources are being used, etc) to SMRecord.
    func saveToRecord() {
        print("[VNSceneNode] Saving data to record.");
        
        // Create the default "dictionary to save" that will be passed into SMRecord's "activity dictionary."
        // Keep in mind that the activity dictionary holds the type of activity that the player was engaged in
        // when the game was saved (in this case, the activity is a VN scene), plus any specific details
        // of that activity (in this case, the script's data, which includes indexes, script name, etc.)
        let dictToSave = NSMutableDictionary()
        dictToSave.setValue(VNSceneActivityType, forKey: SMRecord.ActivityTypeKey)
        
        // Check if the "safe save" exists; if it does, then it should be used instead of whatever the current data is.
        //if( safeSave != nil ) {
        if safeSave.count > 1 {
            
            let localFlags          = safeSave.object(forKey: "flags") as! NSDictionary
            let localRecord         = safeSave.object(forKey: "record") as! NSMutableDictionary
            let aliasesFromSafeSave = safeSave.object(forKey: "aliases") as! NSDictionary
            let localChoiceSets     = safeSave.object(forKey: "choicesets") as! NSDictionary
            
            //let recordedFlags = SMRecord.sharedRecord.flags()
            
            //recordedFlags.addEntriesFromDictionary(localFlags)
            //SMDictionaryAddEntriesFromAnotherDictionary(SMRecord.sprite)
            SMRecord.addExistingFlags(fromDictionary: aliasesFromSafeSave)
            SMRecord.addExistingFlags(fromDictionary: localFlags)
            
            // safe choice sets as well
            SMRecord.saveChoiceSetsToRecord(dictionary: localChoiceSets)
            
            dictToSave.setValue(localRecord, forKey: SMRecord.ActivityDataKey)
            //SMRecord.sharedRecord.setActivityDict(dictToSave)
            SMRecord.setActivityDictionary(dictionary: dictToSave)
            if SMRecord.saveToDevice() == false {
                print("[VNSceneNode] WARNING: Attempt to save game data to device data encountered an error.")
            }
            
            //[[[SMRecord sharedRecord] flags] addEntriesFromDictionary:[safeSave.objectForKey(@"flags"])
            //[dictToSave setObject:[safeSave.objectForKey(@"record"] forKey:SMRecordActivityDataKey)
            //[[SMRecord sharedRecord] setActivityDict:dictToSave)
            print("[VNSceneNode] Saving 'safe save' data from scene.")
            return;
        }
        
        // Save all the names and coordinates of the sprites still active in the scene. This data will be enough
        // to recreate them later on, when the game is loaded from saved data.
        let spritesToSave:NSArray? = spriteDataFromScene()
        
        if( spritesToSave != nil ) {
            record.setValue(spritesToSave!, forKey: VNSceneSpritesToShowKey)
        } else {
            record.removeObject(forKey: VNSceneSpritesToShowKey)
        }
        
        // Load all flag data back to SMRecord. Remember that VNScene doesn't have a monopoly on flag data;
        // other classes and game systems can modify the flags as well!
        //[[SMRecord sharedRecord].flags addEntriesFromDictionary:flags)
        //SMRecord.sharedRecord.addExistingFlags(flags)
        SMRecord.addExistingFlags(fromDictionary: flags)
        SMRecord.saveChoiceSetsToRecord(dictionary: choiceSets)
        
        // Update script data and then load it into the activity dictionary.
        updateScriptInfo()                                              // Update all index and conversation data
        dictToSave.setValue(record, forKey:SMRecord.ActivityDataKey)    // Load into activity dictionary
        SMRecord.setActivityDictionary(dictionary: dictToSave)          // Save the activity dictionary into SMRecord
        if SMRecord.saveToDevice() == false {                           // Save all record data to device memory
            print("[VNSceneNode] WARNING: Attempt to save game data to device encountered an error.")
        }
        
        print("[VNSceneNode] Data has been saved. Stored data is: \(dictToSave)");
    }
    
    // Create the "safe save." This function usually gets called before VNScene does some sort of volatile/potentially-hazardous
    // operation, like performing effects or presenting the player with choices menus. In case the game needs to be saved during
    // times like this, the data stored in the "safe save" will be the data that's stored in the saved game.
    func createSafeSave() {
        if( script == nil ) {
            print("[VNSceneNode] WARNING: Cannot create safe save, as no script information exists.")
            return;
        }
        
        print("[VNSceneNode] Creating safe-save data.");
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
                                                    "aliases":self.localSpriteAliases.copy(),
                                                    "record":record,
                                                    "choicesets":choiceSets,
                                                    VNSceneSavedScriptInfoKey:scriptInfo])
    }
    
    func removeSafeSave() {
        print("[VNSceneNode] Removing safe-save data.");
        safeSave.removeAllObjects()
    }
    
    // This creates an array that stores all the sprite filenames and coordinates. When the game is loaded from saved data,
    // the sprites can be easily reloaded and repositioned.
    func spriteDataFromScene() -> NSArray? {
        if sprites.count < 1 {
            print("[VNSceneNode] No sprite data found in scene.");
            return nil;
        }
        
        print("[VNSceneNode] Retrieving sprite data from scene!");
        
        // Create the "sprites array." Each index in the array holds a dictionary, and each dictionary holds
        // certain data: sprite filename, sprite x coordinate, and sprite y coordinate.
        let spritesArray = NSMutableArray()
        
        // Get every single sprite from the 'sprites' dictionary and extract the relevent data from it.
        for spriteName in sprites.allKeys {
            //print("[VNSceneNode] Saving sprite named: \(spriteName)")
            let actualSprite:SKSpriteNode = sprites.object(forKey: spriteName) as! SKSpriteNode //sprites[spriteName)
            let spriteX = NSNumber(value: Double(actualSprite.position.x) ) // Get coordinates; these will be saved to the dictionary.
            let spriteY = NSNumber(value: Double(actualSprite.position.y) )
            
            // store scaling data as well (this is used mostly for inverted sprites)
            let scaleX = NSNumber(value: Double(actualSprite.xScale))
            let scaleY = NSNumber(value: Double(actualSprite.yScale))
            
            // Save relevant data (sprite name and coordinates) in a dictionary
            let tempSpriteDictionary = NSMutableDictionary()
            tempSpriteDictionary.setValue(spriteName, forKey:"name")
            tempSpriteDictionary.setValue(spriteX, forKey:"x")
            tempSpriteDictionary.setValue(spriteY, forKey:"y")
            tempSpriteDictionary.setValue(scaleX, forKey:"scale x")
            tempSpriteDictionary.setValue(scaleY, forKey:"scale y")
            
            // check if this has a different filename
            let filenameOfSprite = self.filenameOfSpriteAlias(spriteName as! String)
            // if the filenames are different, then it means that there is an alias value
            if filenameOfSprite.caseInsensitiveCompare(spriteName as! String) != ComparisonResult.orderedSame {
                tempSpriteDictionary.setValue(filenameOfSprite, forKey:"filename")
            }
            
            let savedSpriteData = NSDictionary(dictionary: tempSpriteDictionary)
            
            // Save dictionary data into the array (which will later be saved to a file)
            spritesArray.add(savedSpriteData)
        }
        
        //return [NSArray arrayWithArray:spritesArray)
        return NSArray(array: spritesArray)
    }
    
    /** CORE FUNCTIONS **/
    
    //- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
    //override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in touches {
            let touchPos = touch.location(in: self)
            
            // During the "choice" sections of the VN scene, any buttons that are touched in the menu will
            // change their background  appearance (to blue, by default), while all the untouched buttons
            // will stay black by default. In both cases, the color of text ON the button remains unchanged.
            if( mode == VNSceneModeChoiceWithJump || mode == VNSceneModeChoiceWithFlag ) {
                if buttons.count > 0 {
                    for button in buttons {
                        let currentButton = button as! SKSpriteNode
                        
                        if ((button as AnyObject).frame).contains(touchPos) == true {
                            currentButton.color = buttonTouchedColors // Turn blue
                        } else {
                            currentButton.color = buttonUntouchedColors // Turn black
                        }
                    }
                }
            }
        }
    } // touchesBegan
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for currentTouch in touches {
            
            let touch:UITouch   = currentTouch
            let touchPos        = touch.location(in: self)
            
            if( mode == VNSceneModeChoiceWithJump || mode == VNSceneModeChoiceWithFlag ) {
                if( buttons.count > 0 ) {
                    for currentButton in buttons {
                        let button:SKSpriteNode = currentButton as! SKSpriteNode
                        
                        if( button.frame.contains(touchPos) ) {
                            button.color = buttonTouchedColors;
                        } else {
                            button.color = buttonUntouchedColors;
                        }
                    }
                }
            }
        }
    }
    
    //- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
    //override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for currentTouch in touches {
            
            let touch:UITouch = currentTouch //as! UITouch
            let touchPos = touch.location(in: self)
            
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
                        let lengthOfTWCurrentText   = SMUtility.Strings.lengthOf(string: TWCurrentText)
                        let lengthOfTWFullText      = SMUtility.Strings.lengthOf(string: TWFullText)
                        
                        if lengthOfTWCurrentText < lengthOfTWFullText {
                            canSkip = false
                        }
                    }
                    
                    if canSkip == true {
                        script!.advanceIndex() // Move the script forward
                    }
                } else {
                    // Only allow advancing/skipping if there's no text or if the opacity/alpha has reached 1.0
                    if SMUtility.Strings.lengthOf(string: speech!.text) < 1 || speech!.alpha >= 1.0 {
                        script!.advanceIndex()
                    }
                }
                
                // If the current mode is some kind of choice menu, then Touches Ended actually picks a choice (assuming,
                // of course, that the touch landed on a button).
            } else if( mode == VNSceneModeChoiceWithJump || mode == VNSceneModeChoiceWithFlag ) { // Choice menu mode
                
                if( buttons.count > 0 ) {
                    
                    //for( int currentButton = 0; currentButton < buttons.count; currentButton++ ) {
                    for currentButton in 0 ..< buttons.count {
                        let button:SKSpriteNode = buttons.object(at: currentButton) as! SKSpriteNode
                        
                        if( button.frame.contains(touchPos) ) {
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
    func update(_ currentTime: TimeInterval) {
        // Check if the scene is finished
        if( script!.isFinished == true ) {
            // Print the 'quitting time' message
            //print("[VNSceneNode] The 'Script Is Finished' flag is triggered. Now moving to 'end of script' mode.");
            mode = VNSceneModeEnded; // Set 'end' mode
        }
        
        //switch( mode ) {
        switch mode {
            
        // Resources need to be loaded?
        case VNSceneModeLoading:
            //print("[VNSceneNode] Now in 'loading mode'");
            
            // Do any last-minute loading operations here
            //[self loadSavedResources)
            loadSavedResources()
            
            // Switch to 'clean-up loading' mode
            mode = VNSceneModeFinishedLoading;
            
        // Have all the resources and script data just finished loading?
        case VNSceneModeFinishedLoading:
            //print("[VNSceneNode] Finished loading.");
            
            // Switch to "Normal Mode" (which is where the dialogue and normal script processing happen)
            mode = VNSceneModeNormal;
            
        // Is everything just being processed as usual?
        case VNSceneModeNormal:
            // Check if there's any safe-save data. When the scene has switched over to Normal Mode, then the safe-save
            // becomes unnecessary, since the conditions that caused it (like certain effects being run) are no longer
            // active. In this case, the safe-save should just be removed so that the normal data can be saved.
            if( safeSave.count > 0 ) {
                removeSafeSave()
            }
            
            // Take care of normal operations
            runScript() // process data from the script
            
            if TWModeEnabled == true {
                // Update typewriter text
                if TWNumberOfCurrentCharacters < TWNumberOfTotalCharacters {
                    TWTimer += 1
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
                let conversationToJumpTo = choices.object(at: buttonPicked) as! NSString // The conversation names are stored in the 'choices' array
                
                // Switch to the new "conversation" / dialogue array.
                if script!.changeConversationTo(nameOfConversation: conversationToJumpTo as String) == false {
                    print("[VNSceneNode] ERROR: Could not switch script to section named: \(conversationToJumpTo)")
                }
                
                mode = VNSceneModeNormal; // Go back to Normal Mode (after this has been processed, of course)
                
                // Get rid of any lingering objects in memory
                if( buttons.count > 0 ) {
                    for currentButton in buttons {
                        
                        let button = currentButton as! SKSpriteNode
                        
                        // remove actions and sub-children from the button's child nodes
                        if button.children.count > 0 {
                            for childNodeInButton in button.children {
                                childNodeInButton.removeAllActions()
                                childNodeInButton.removeAllChildren()
                            }
                        }
                        
                        button.removeAllActions()
                        button.removeAllChildren()
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
                let flagName:NSString?    = choices.object(at: buttonPicked) as? NSString
                var flagValue:NSNumber?   = choiceExtras.object(at: buttonPicked) as? NSNumber
                let oldFlag:NSNumber?     = flags.object(forKey: flagName!) as? NSNumber
                
                // Check if the flag had a previously existing value; if it did, then just add the old value to the new value
                if( oldFlag != nil ) {
                    let oldFlagAsInteger    = oldFlag!.int32Value
                    let flagInteger         = flagValue!.int32Value
                    let combinedIntegers    = oldFlagAsInteger + flagInteger
                    let tempValue           = NSNumber(value: combinedIntegers)
                    
                    flagValue = tempValue
                }
                
                // Set the new value of the flag. The change will be made to the "local" flag dictionary, not the
                // global one stored in SMRecord. This is to prevent any save-data conflicts (since it's certainly
                // possible that not all the data in the VNScene will be stored along with the updated flag data)
                flags.setValue(flagValue!, forKey: flagName! as String)
                
                // Get rid of any unnecessary objects in memory
                if( buttons.count > 0 ) {
                    for currentButton in buttons {
                        let button:SKSpriteNode = currentButton as! SKSpriteNode
                        
                        // remove the actions and child nodes from the button's child nodes
                        if button.children.count > 0 {
                            for childNodeInButton in button.children {
                                childNodeInButton.removeAllActions()
                                childNodeInButton.removeAllChildren()
                            }
                        }
                        
                        button.removeAllActions()
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
                //print("[VNSceneNode] The scene has ended. Flag data will be auto-saved.");
                //print("[VNSceneNode] Remaining scene and activity data will be deleted.");
                
                SMRecord.addExistingFlags(fromDictionary: flags)
                SMRecord.resetActivityInformation(inDictionary: SMRecord.record)
                
                self.isFinished = true; // Mark as finished
                purgeDataCreatedByScene()
            }
            
        default:
            print("[VNSceneNode] WARNING: Now in unknown state");
        }
    }
    
    // Processes the script (during "Normal Mode"). This function determines whether it's safe to process the script (since there are
    // many times when it might be considered "unsafe," such as when effects are being run, or even if it's something mundane like
    // waiting for user input).
    func runScript() {
        if( script == nil ) {
            print("[VNSceneNode] ERROR: Script cannot be run because it has no data.")
            return
        }
        
        var scriptShouldBeRun = true // This flag is used to run the following loop...
        
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
            
            // If the function has made it this far, then it's time to grab more script data and process that
            
            // Get the current line/command from the script
            let currentCommand:NSArray? = script!.currentCommand()
            
            // Check if there is no valid data (this might also mean that there are no more commands at all)
            if( currentCommand == nil ) {
                // Print warning message and finish the scene
                print("[VNSceneNode] NOTICE: Script has run out of commands. Switching to 'Scene Ended' mode...");
                mode = VNSceneModeEnded;
                return;
            }
            
            processCommand(command: currentCommand!)
            script!.indexesDone += 1
        }
    }
    
    // Returns the position for where the speaker label should be (since the size changes every time the text changes, it has to be repositioned each time).
    func updatedSpeakerPosition() -> CGPoint {
        var widthOfSpeechBox = speechBox!.frame.size.width;
        let heightOfSpeechBox = speechBox!.frame.size.height;
        var speakerNameOffsets = CGPoint.zero;
        
        // Load speaker offset values
        let speakerNameOffsetXValue:NSNumber? = viewSettings.object(forKey: VNSceneViewSpeakerNameXOffsetKey) as? NSNumber
        let speakerNameOffsetYValue:NSNumber? = viewSettings.object(forKey: VNSceneViewSpeakerNameYOffsetKey) as? NSNumber
        
        if( speakerNameOffsetXValue != nil ) {
            speakerNameOffsets.x = CGFloat(speakerNameOffsetXValue!.doubleValue)
        }
        if( speakerNameOffsetYValue != nil ) {
            speakerNameOffsets.y = CGFloat(speakerNameOffsetYValue!.doubleValue)
        }
        
        let screenSize = viewSize
        let boxSize = speechBox!.frame.size;
        var workingArea = boxSize;
        
        // Check if the speech box is actually wider than the screen's width
        if( screenSize.width < boxSize.width ) {
            workingArea.width = screenSize.width;
        }
        
        widthOfSpeechBox = workingArea.width;
        
        // Find top-left corner of the speech box
        let topLeftCornerOfSpeechBox:CGPoint = CGPoint( x: 0.0 - (widthOfSpeechBox * 0.5), y: 0 + (heightOfSpeechBox * 0.5));
        // Adjust slightly so that the label isn't jammed up against the upper-left corner; there should be a bit of margins
        let adjustment:CGPoint = CGPoint( x: widthOfSpeechBox * 0.02, y: heightOfSpeechBox * -0.05 );
        // Store adjustments
        let cornerPlusAdjustments:CGPoint = SMUtility.Position.addTwoPoints(first: topLeftCornerOfSpeechBox, second: adjustment);
        // Add custom offsets
        let adjustedPlusOffsets:CGPoint = SMUtility.Position.addTwoPoints(first: cornerPlusAdjustments, second: speakerNameOffsets);
        
        return adjustedPlusOffsets;
    }
    
    // When calculating the heights for buttons during choice segments, this determines the starting Y value factor (represented
    // as a percentage of the screen height. For example, this usually defaults to 0.60 or 60%, but if there are more choices, this
    // might go as high as 70% of the screen height.
    func choiceButtonStartingYFactor(numberOfChoices:Int) -> CGFloat {
        var result = VNSceneNodeChoiceButtonStartingPercentage // this is usually 0.60 or 60% of the screen height
        let choiceNumberCutoff = 3 // above this value, the original starting point will need to be moved
        let heightCutoff = CGFloat(0.75) // can't use a value higher than this

        if numberOfChoices > choiceNumberCutoff {
            let numberOfChoicesAboveStandard = numberOfChoices - choiceNumberCutoff

            result = result + CGFloat(numberOfChoicesAboveStandard) * 0.03
        }

        if result > heightCutoff {
            result = heightCutoff
        }

        return result
    }
    
    // Since the speech label's size changes every time the text changes, this also has to be repositioned each time
    // a new line of dialogue is shown.
    func updatedTextPosition() -> CGPoint {
        var widthOfBox  = speechBox!.frame.size.width;
        let heightOfBox = speechBox!.frame.size.height;
        
        let screenSize:CGSize   = viewSize
        let boxSize:CGSize      = speechBox!.frame.size;
        var workingArea:CGSize  = boxSize;
        
        // Check if the speechbox is wider than the screen/view, in which case whichever one is smaller will be used
        if( screenSize.width < boxSize.width ) {
            workingArea.width = screenSize.width;
        }
        
        widthOfBox = workingArea.width;
        
        let horizontalMarginsNumber = viewSettings.object(forKey: VNSceneViewSpeechHorizontalMarginsKey) as! NSNumber
        let speechXOffsetNumber     = viewSettings.object(forKey: VNSceneViewSpeechOffsetXKey) as! NSNumber
        let horizontalMargins       = CGFloat(horizontalMarginsNumber.doubleValue)
        let speechXOffset           = CGFloat(speechXOffsetNumber.doubleValue)
        
        // Find top-left corner of speechbox (child node will be centered right over the very corner)
        let topLeftCornerOfBox = CGPoint( x: 0.0 - (widthOfBox * 0.5), y: 0 + (heightOfBox * 0.5));
        let textX:CGFloat = topLeftCornerOfBox.x + (widthOfBox * 0.04) + speechXOffset + horizontalMargins; // + speechXOffset + horizontalMargins;
        let textY:CGFloat = topLeftCornerOfBox.y - (heightOfBox * 0.1) - speaker!.frame.size.height;// - verticalMargins - speechYOffset;
        
        return CGPoint(x: textX, y: textY);
    }
    
    // MARK: - Script processing
    
    // Displays dialogue / narration. This is put into a function because currently, there are multiple possible commands that can display
    // dialogue and I don't to copy and paste the same code into each section... much easier to just call it from a function. I'll probably
    // have to implement some similar functions for other things that keep getting used multiple times intstead of copying and pasting.
    // This code has gotten so awkward and convoluted over the years!
    func sayDialogue(line:String) {
        if TWModeEnabled == false {
            // Speech opacity is set to zero, making it invisible. Remember, speech is supposed to "fade in"
            // instead of instantly appearing, since an instant appearance can be visually jarring to players.
            speech!.alpha = 0.0;
            speech!.text = line
            record.setValue(line, forKey: VNSceneSpeechToDisplayKey) // Copy text to save-game record
            
            // Now have the text fade into full visibility.
            let fadeIn:SKAction = SKAction.fadeIn(withDuration: speechTransitionSpeed) //[SKAction fadeInWithDuration:speechTransitionSpeed)
            speech!.run(fadeIn)
            
            // If the speech-box isn't visible (or at least not fully visible), then it should fade-in as well
            if( speechBox!.alpha < 0.9 ) {
                let fadeInSpeechBox = SKAction.fadeIn(withDuration: speechTransitionSpeed)
                speechBox!.run(fadeInSpeechBox)
            }
            
            speech!.anchorPoint = CGPoint(x: 0, y: 1.0);
            speech!.position = updatedTextPosition()
            
        } else {
            //let parameter1AsString = command.object(at: 1) as! NSString
            
            // Reset counter
            TWTimer                     = 0
            //TWFullText                  = String(describing: command.object(at: 1))//parameter1AsString as String
            TWFullText                  = line
            TWCurrentText               = ""
            TWNumberOfCurrentCharacters = 0
            TWNumberOfTotalCharacters   = NSString(string: TWFullText).length
            TWPreviousNumberOfCurrentChars = 0;
            
            //[record setValue:parameter1 forKey:VNSceneSpeechToDisplayKey];
            record.setValue(line, forKey: VNSceneSpeechToDisplayKey)
            
            speech!.text = " "// parameter1AsString
            speechBox!.alpha = 1.0;
            speech!.anchorPoint = CGPoint(x: 0, y: 1.0)
            speech!.position = updatedTextPosition()
            
            TWInvisibleText!.text = String(describing: line) //parameter1AsString as String
            TWInvisibleText!.anchorPoint = CGPoint(x: 0, y: 1.0)
            TWInvisibleText!.position = updatedTextPosition()
            TWInvisibleText!.alpha = 0.0
        }
    }
    
    // This is the most important function; it breaks down the data stored in each line of the script and actually
    // does something useful with it.
    //- (void)processCommand:(NSArray *)command
    func processCommand( command: NSArray) {
        if( command.count < 1 ) {
            print("[VNSceneNode] Cannot process command as array has insufficient data.")
            return
        }
        
        // Extract some data from the command
        let commandTypeNumber       = command.object(at: 0) as! NSNumber // Command type, always stored as 'int'
        let type:Int                = commandTypeNumber.intValue
        
        // Check if the command is really just "display a regular line of text" and if that's the case, this just displays
        // the dialogue and then the function ends without wasting CPU cycles trying to figure out what the other commands are.
        if( type == VNScriptCommandSayLine ) {
            let dialogueLine = String(describing: command.object(at: 1))
            sayDialogue(line: dialogueLine)
            return;
        }
        
        // Advance the script's index to make sure that commands run one after the other. Otherwise, they will only run one at a time
        // and the user would have to keep touching the screen each time in order for the next command to be run. Except for the
        // "display a line of text" command, most of the commands are designed to run one after the other seamlessly.
        script!.currentIndex += 1;
        
        // Now, figure out what type of command this is!
        switch( type ) {
            
        // Adds a CCSprite object to the screen; the image is loaded from a file in the app bundle. Currently, VNScene doesn't
        // support texture atlases, so it can only load the WHOLE IMAGE as-is.
        case VNScriptCommandAddSprite:
            
            let spriteName          = String(describing: command.object(at: 1))
            let filenameOfSprite    = self.filenameOfSpriteAlias(spriteName)
            let parameter2          = command.object(at: 2) as! NSNumber
            let appearAtOnce        = parameter2.boolValue
            
            // Check if this sprite already exists, and if it does, then stop the function since there's no point adding the sprite a second time.
            let spriteAlreadyExists:SKSpriteNode? = sprites.object(forKey: spriteName) as? SKSpriteNode
            if( spriteAlreadyExists != nil ) {
                return;
            }
            
            // Try to load the sprite from an image in the app bundle
            let createdSprite:SKSpriteNode? = SKSpriteNode(imageNamed: filenameOfSprite)
            if( createdSprite == nil ) {
                print("[VNSceneNode] ERROR: Could not load sprite named: \(filenameOfSprite)");
                return;
            }
            
            // Add the newly-created sprite to the sprite dictionary
            sprites.setValue(createdSprite!, forKey: spriteName)
            
            // Position the sprite at the center; the position can be changed later. Usually, the command to change sprite positions
            // is almost immediately right after the command to add the sprite; the commands are executed so quickly that the user
            // shouldn't see any delay.
            createdSprite!.position = SMUtility.Position.normalizedCoordinates(normalizedX: 0.5, normalizedY: 0.5); // Sprite positioned at screen center
            createdSprite!.zPosition = VNSceneCharacterLayer;
            addChild(createdSprite!)
            
            // Right now, the sprite is fully visible on the screen. If it's supposed to fade in, then the opacity is set to zero
            // (making the sprite "invisible") and then it fades in over a period of time (by default, that period is half a second).
            if appearAtOnce == false {
                // Make the sprite fade in gradually ("gradually" being a relative term!)
                createdSprite!.alpha    = 0.0;
                let fadeIn              = SKAction.fadeIn(withDuration: spriteTransitionSpeed)
                createdSprite!.run(fadeIn)
            }
            
        // This "aligns" a sprite so that it's either in the left, center, or right areas of the screen. (This is calculated as being
        // 25%, 50% or 75% of the screen width).
        case VNScriptCommandAlignSprite:
            let spriteName          = String(describing: command.object(at: 1))
            let newAlignment        = command.object(at: 2) as! String // "left", "center", "right"
            let duration            = command.object(at: 3) as! NSNumber // Default duration is 0.5 seconds; this is stored as an NSNumber (double)
            let durationAsDouble    = duration.doubleValue // For when an actual scalar value has to be passed (instead of NSNumber)
            var alignmentFactor     = CGFloat(0.5) // 0.50 is the center of the screen, 0.25 is left-aligned, and 0.75 is right-aligned
            
            // STEP ONE: Find the sprite if it exists. If it doesn't, then just stop the function.
            let sprite:SKSpriteNode? = sprites.object(forKey: spriteName) as? SKSpriteNode
            if( sprite == nil ) {
                return;
            }
            
            // STEP TWO: Set the new sprite position
            
            // Check the string to find out if the sprite should be left-aligned or right-aligned instead
            if newAlignment.caseInsensitiveCompare(VNSceneViewSpriteAlignmentLeftString) == ComparisonResult.orderedSame {
                
                alignmentFactor = 0.25; // "left"
                
            } else if newAlignment.caseInsensitiveCompare(VNSceneViewSpriteAlignmentRightString) == ComparisonResult.orderedSame {
                
                alignmentFactor = 0.75; // "right"
                
            } else if( newAlignment.caseInsensitiveCompare(VNSceneViewSpriteAlignemntFarLeftString) == ComparisonResult.orderedSame ) {
                
                alignmentFactor = 0.0; // "far left"
                
            } else if( newAlignment.caseInsensitiveCompare(VNSceneViewSpriteAlignmentFarRightString) == ComparisonResult.orderedSame ) {
                
                alignmentFactor = 1.0; // "far right"
                
            } else if( newAlignment.caseInsensitiveCompare(VNSceneViewSpriteAlignmentExtremeLeftString) == ComparisonResult.orderedSame ) {
                
                alignmentFactor = -0.5; // "extreme left"
                
            } else if( newAlignment.caseInsensitiveCompare(VNSceneViewSpriteAlignmentExtremeRightString) == ComparisonResult.orderedSame ) {
                
                alignmentFactor = 1.5; // "extreme right"
            }
            
            // Tell the view to instantly re-position the sprite
            //float updatedX = [[CCDirector sharedDirector] viewSize].width * alignmentFactor;
            let updatedX = viewSize.width * alignmentFactor;
            let updatedY = sprite!.position.y; // Maintain the same height as before
            
            // If the duration is set to "instant" (meaning zero duration), then just move the sprite into position and stop the function
            if( durationAsDouble <= 0.0 ) {
                sprite!.position = CGPoint( x: updatedX, y: updatedY ); // Set new position
                return;
            }
            
            createSafeSave() // Create safe-save before using a move effect on the sprite (safe-saves are always used before effects are run)
            
            // STEP THREE: Make preparations for the "move sprite" effect. Once the actual movement has been completed, then
            //            the action sequence will call 'clearEffectRunningFlag' to let VNScene know that the effect's done.
            let moveSprite          = SKAction.move(to: CGPoint(x: updatedX, y: updatedY), duration:durationAsDouble)
            let clearFlagAction     = SKAction.run(self.clearEffectRunningFlag)
            let spriteMoveSequence  = SKAction.sequence([moveSprite, clearFlagAction])
            
            // STEP FOUR: Set the "effect running" flag, and then actually perform the CCAction sequence.
            setEffectRunningFlag()
            sprite!.run(spriteMoveSequence)
            
        // This command just removes a sprite from the screen. It can be done immediately (though suddenly vanishing is kind of
        // jarring for players) or it can gradually fade from sight.
        case VNScriptCommandRemoveSprite:
            let spriteName                  = String(describing: command.object(at: 1))
            let spriteVanishesImmediately   = (command.object(at: 2) as! NSNumber).boolValue //[[command objectAtIndex:2] boolValue)
            
            // Check if the sprite even exists. If it doesn't, just stop the function
            let sprite:SKSpriteNode? = sprites.object(forKey: spriteName) as? SKSpriteNode
            if( sprite == nil ) {
                return;
            }
            
            // Remove the sprite from the sprites array. If the game needs be saved soon right after this command
            // is called, then the now-removed sprite won't be included in the save data.
            sprites.removeObject(forKey: spriteName)
            
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
                spritesToRemove.add(sprite!) // Add to the sprite-removal array; sprite will be removed later by a function
                sprite!.name = VNSceneSpriteIsSafeToRemove; // Mark the sprite as safe-to-delete
                
                // This sequence of CCActions will cause the sprite to fade out, and then it'll be removed from memory.
                let fadeOutSprite = SKAction.fadeOut(withDuration: spriteTransitionSpeed)
                let removeSprite = SKAction.run(self.removeUnusedSprites)
                let spriteRemovalSequence = SKAction.sequence([fadeOutSprite, removeSprite])
                
                sprite!.run(spriteRemovalSequence)
            }
            
        // This command is used to move/pan the background around, using the "moveBy" action
        case VNScriptCommandEffectMoveBackground:
            // Check if the background even exists to begin with, because otherwise there's no point to any of this!
            let backgroundSprite:SKSpriteNode? = self.childNode(withName: VNSceneTagBackground) as? SKSpriteNode
            if( backgroundSprite == nil ) {
                return
            }
            
            let background = backgroundSprite!
            createSafeSave()
            
            let moveByX     = command.object(at: 1) as! NSNumber
            let moveByY     = command.object(at: 2) as! NSNumber
            let duration    = command.object(at: 3) as! NSNumber
            let parallaxing = command.object(at: 4) as! NSNumber
            
            let durationAsDouble    = duration.doubleValue
            let parallaxFactor      = CGFloat(parallaxing.doubleValue)
            
            self.setEffectRunningFlag()
            
            // Also update the background's position in the record, so that when the game is loaded from a saved game,
            // then the background will be where it should be (that is, where it will be once the CCAction has finished).
            let finishedX = background.position.x + CGFloat(moveByX.floatValue)
            let finishedY = background.position.y + CGFloat(moveByY.floatValue)
            
            record.setObject(NSNumber(value: Double(finishedX)), forKey: VNSceneBackgroundXKey as NSCopying)
            record.setObject(NSNumber(value: Double(finishedY)), forKey: VNSceneBackgroundYKey as NSCopying)
            
            // Updates sprites to move along with the background
            for currentName in sprites.allKeys {
                let spriteName = currentName as! String
                let currentSprite:SKSpriteNode? = sprites.object(forKey: spriteName) as? SKSpriteNode
                
                if( currentSprite!.parent != nil ) {
                    let spriteMovementX = parallaxFactor * CGFloat( moveByX.doubleValue )
                    let spriteMovementY = parallaxFactor * CGFloat( moveByY.doubleValue )
                    
                    let movementAction = SKAction.move(by: CGVector(dx: spriteMovementX, dy: spriteMovementY), duration: durationAsDouble)
                    currentSprite!.run(movementAction)
                }
            }
            
            // Set up the movement sequence
            let movementAmount      = CGVector( dx: CGFloat(moveByX.floatValue), dy: CGFloat(moveByY.floatValue) );
            let moveByAction        = SKAction.move(by: movementAmount, duration: durationAsDouble)
            let clearEffectFlag     = SKAction.run(self.clearEffectRunningFlag)
            let movementSequence    = SKAction.sequence([moveByAction, clearEffectFlag])
            
            background.run(movementSequence)
            
        // This command moves a sprite by a certain number of points (since Cocos2D uses points instead of pixels). This
        // is really just a "wrapper" of sorts for the CCMoveBy action in Cocos2D.
        case VNScriptCommandEffectMoveSprite:
            let spriteName      = String(describing: command.object(at: 1))
            let moveByXNumber   = command.object(at: 2) as! NSNumber
            let moveByYNumber   = command.object(at: 3) as! NSNumber
            let durationNumber  = command.object(at: 4) as? NSNumber
            
            // Create scalar versions
            let moveByX = CGFloat( moveByXNumber.doubleValue )
            let moveByY = CGFloat( moveByYNumber.doubleValue )
            var duration = Double( 0 ) // Default duration length
            
            let tempSprite:SKSpriteNode? = sprites.object(forKey: spriteName) as? SKSpriteNode
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
                
                sprite.position = CGPoint(x: updatedX, y: updatedY)
                return; // Stop the function, since an "immediate movement" command doesn't need to go any further
            }
            
            self.setEffectRunningFlag()
            
            // Set up movement action, and then have the "effect is running" flag get cleared at the end of the sequence
            let movementAmount      = CGVector(dx: moveByX, dy: moveByY)
            let moveByAction        = SKAction.move(by: movementAmount, duration: duration)
            let clearEffectFlag     = SKAction.run(self.clearEffectRunningFlag)
            let movementSequence    = SKAction.sequence([moveByAction, clearEffectFlag])
            
            sprite.run(movementSequence)
            
        // Instantly set a sprite's position (this is similar to the "move sprite" command, except this happens instantly).
        // While instant movement can look strange, there are some situations it can be useful.
        case VNScriptCommandSetSpritePosition:
            
            let spriteName = String(describing: command.object(at: 1))
            let updatedXNumber = command.object(at: 2) as! NSNumber
            let updatedYNumber = command.object(at: 3) as! NSNumber
            let updatedX = CGFloat( updatedXNumber.doubleValue )
            let updatedY = CGFloat( updatedYNumber.doubleValue )
            
            let loadedSprite:SKSpriteNode? = sprites.object(forKey: spriteName) as? SKSpriteNode
            if( loadedSprite != nil ) {
                loadedSprite!.position = CGPoint(x: updatedX, y: updatedY)
            }
            
        // Change the background image. If the name parameter is set to "nil" then this command just removes the background image.
        case VNScriptCommandSetBackground:
            
            let backgroundName = String(describing: command.object(at: 1));
            
            // Get rid of the old background
            let background:SKSpriteNode? = self.childNode(withName: VNSceneTagBackground) as? SKSpriteNode
            if( background != nil ) {
                background!.removeFromParent()
            }
            
            // Also remove background data from records
            record.removeObject(forKey: VNSceneBackgroundToShowKey)
            record.removeObject(forKey: VNSceneBackgroundXKey)
            record.removeObject(forKey: VNSceneBackgroundYKey)
            
            // Check the value of the string. If the string is "nil", then just get rid of any existing background
            // data. Otherwise, VNSceneView will try to use the string as a file name.
            if backgroundName.caseInsensitiveCompare(VNScriptNilValue) != ComparisonResult.orderedSame {
                let updatedBackground = SKSpriteNode(imageNamed: backgroundName)
                
                // Get some data needed to set the background
                var alphaValue = CGFloat( 1.0 )
                let alphaNumber:NSNumber? = viewSettings.object(forKey: VNSceneViewDefaultBackgroundOpacityKey) as? NSNumber
                if( alphaNumber != nil ) {
                    alphaValue = CGFloat( alphaNumber!.doubleValue )
                }
                
                // Set properties
                updatedBackground.position  = CGPoint(x: viewSize.width * 0.5, y: viewSize.height * 0.5) // Position at the center of the frame
                updatedBackground.alpha     = alphaValue
                updatedBackground.zPosition = VNSceneBackgroundLayer
                updatedBackground.name      = VNSceneTagBackground
                
                self.addChild(updatedBackground)
                
                // Convert coordinates to NSNumber format
                let backgroundXDouble   = Double( updatedBackground.position.x )
                let backgroundYDouble   = Double( updatedBackground.position.y )
                let bgXNumber           = NSNumber( value: backgroundXDouble )
                let bgYNumber           = NSNumber( value: backgroundYDouble )
                
                // Update record
                record.setObject(backgroundName,    forKey: VNSceneBackgroundToShowKey  as NSCopying)
                record.setObject(bgXNumber,         forKey: VNSceneBackgroundXKey       as NSCopying)
                record.setObject(bgYNumber,         forKey: VNSceneBackgroundYKey       as NSCopying)
            }
            
        // Sets the "speaker name," so that the player knows which character is speaking. The name usually appears above and to the
        // left of the actual dialogue text. The value of the speaker name can be set to "nil" to hide the label.
        case VNScriptCommandSetSpeaker:
            
            let updatedSpeakerName = String(describing: command.object(at: 1))
            
            speaker!.alpha  = 0; // Make the label invisible so that it can fade in
            speaker!.text   = " "; // Default value is to not have any speaker name in the label's text string
            record.removeObject(forKey: VNSceneSpeakerNameToShowKey)
            
            // Check if this is a valid name (instead of the 'nil' value)
            if updatedSpeakerName.caseInsensitiveCompare(VNScriptNilValue) != ComparisonResult.orderedSame {
                // Set new name
                record.setValue(updatedSpeakerName, forKey: VNSceneSpeakerNameToShowKey)
                
                speaker!.alpha          = 0;
                speaker!.text           = updatedSpeakerName;
                
                speaker!.anchorPoint    = CGPoint(x: 0, y: 1.0);
                speaker!.position       = self.updatedSpeakerPosition() //[self updatedSpeakerPosition)
                
                // Fade in the speaker name label
                let fadeIn = SKAction.fadeIn(withDuration: speakerTransitionSpeed)
                speaker!.run(fadeIn)
            }
            
        // This changes which "conversation" (or array of dialogue) in the script is currently being run.
        case VNScriptCommandChangeConversation:
            let updatedConversationName = String(describing: command.object(at: 1))
            
            let convo = script!.data!.object(forKey: updatedConversationName) as? NSArray
            
            if convo == nil {
                print("[VNSceneNode] ERROR: No section titled \(updatedConversationName) was found in script!")
                return;
            }
            
            // If the conversation actually exists, then just switch to it
            if script!.changeConversationTo(nameOfConversation: updatedConversationName) == false {
                print("[VNSceneNode] WARNING: Could not switch script to section named: \(updatedConversationName)")
            }
            
            script!.indexesDone -= 1
            
        // This command presents a choice menu to the player, and after the player chooses, then VNScene switches conversations.
        case VNScriptCommandJumpOnChoice:
            self.createSafeSave() // Always create safe-save before doing something volatile
            
            let choiceTexts     = command.object(at: 1) as! NSArray   // Get the strings to display for individual choices
            let destinations    = command.object(at: 2) as! NSArray  // Get the names of the conversations to "jump" to
            
            // Make sure the arrays that hold the data are prepared
            buttons.removeAllObjects()
            choices.removeAllObjects()
            
            if let arrayOfButtons = arrayOfButtonSprites(numberOfButtons: choiceTexts.count) {
                addLabelsToArrayOfButtons(arrayOfLabels: choiceTexts, arrayOfButtons: arrayOfButtons)
                addButtonsToScene(arrayOfButtons: arrayOfButtons)
                SMUtility.Arrays.addObjectsToMutableArray(destination: choices, source: destinations)
                
                mode = VNSceneModeChoiceWithJump
            } else {
                print("[VNSceneNode] WARNING: Could not create buttons for .JUMPONCHOICE command.")
            }
            
            
        // This command will show (or hide) the speech box (the little box where all the speech/dialogue text is shown).
        // Hiding it is useful in case you want the player to just enjoy the background art.
        case VNScriptCommandShowSpeechOrNot:
            
            let showSpeechNumber    = command.object(at: 1) as! NSNumber
            let showSpeechOrNot     = showSpeechNumber.boolValue
            
            record.setValue(showSpeechNumber, forKey: VNSceneShowSpeechKey)
            
            // Case 1: DO show the speech box
            if( showSpeechOrNot == true ) {
                speechBox!.removeAllActions()
                speech!.removeAllActions()
                
                let fadeInSpeechBox = SKAction.fadeIn(withDuration: speechTransitionSpeed)
                speechBox!.run(fadeInSpeechBox)
                
                let fadeInText = SKAction.fadeIn(withDuration: speechTransitionSpeed)
                speech!.run(fadeInText)
                
            } else {
                // Case 2: DON'T show the speech box.
                
                speech!.removeAllActions()
                speechBox!.removeAllActions()
                
                let fadeOutBox  = SKAction.fadeOut(withDuration: speechTransitionSpeed)
                let fadeOutText = SKAction.fadeOut(withDuration: speechTransitionSpeed)
                
                speechBox!.run(fadeOutBox)
                speech!.run(fadeOutText)
            }
            
            
        // This command causes the background image and character sprites to "fade in" (go from being fully transparent to being opaque).
        case VNScriptCommandEffectFadeIn:
            let durationNumber = command.object(at: 1) as! NSNumber
            let duration = durationNumber.doubleValue
            
            self.createSafeSave()
            self.setEffectRunningFlag()
            
            // Check if there's any character sprites in existence. If there are, they all need to have a CCFadeIn action applied to each and every one.
            if sprites.count > 0 {
                for tempSprite in sprites.allValues {
                    let currentSprite   = tempSprite as! SKSpriteNode
                    let fadeIn          = SKAction.fadeIn(withDuration: duration)
                    
                    currentSprite.run(fadeIn)
                }
            }
            
            // Fade in the background sprite, if it exists
            let backgroundSprite:SKSpriteNode? = self.childNode(withName: VNSceneTagBackground) as? SKSpriteNode
            if( backgroundSprite != nil ) {
                let fadeIn = SKAction.fadeIn(withDuration: duration)
                backgroundSprite!.run(fadeIn)
            }
            
            // Since the upcoming CCSequence runs at the same time that the prior CCFadeIn actions are run, the first thing
            // put into the sequence is a delay action, so that the "function call" action gets run immediately after the
            // fade-in actions finish.
            let delay                   = SKAction.wait(forDuration: duration)
            let callFunc                = SKAction.run(self.clearEffectRunningFlag)
            let delayedClearSequence    = SKAction.sequence([delay, callFunc])
            
            self.run(delayedClearSequence)
            
            // Finally, update the view settings with the "fully faded-in" value for the background's opacity
            viewSettings.setValue(NSNumber(value: 1.0), forKey: VNSceneViewDefaultBackgroundOpacityKey)
            
        // This is similar to the above command, except that it causes the character sprites and background to go from being
        // fully opaque to fully transparent (or "fade out").
        case VNScriptCommandEffectFadeOut:
            let durationNumber = command.object(at: 1) as! NSNumber
            let duration = durationNumber.doubleValue
            
            self.createSafeSave()
            self.setEffectRunningFlag()
            
            if sprites.count > 0 {
                for tempSprite in sprites.allValues {
                    let fadeOut         = SKAction.fadeOut(withDuration: duration)
                    let currentSprite   = tempSprite as! SKSpriteNode
                    currentSprite.run(fadeOut)
                }
                
                let backgroundSprite:SKSpriteNode? = self.childNode(withName: VNSceneTagBackground) as? SKSpriteNode
                if( backgroundSprite != nil ) {
                    let fadeOut = SKAction.fadeOut(withDuration: duration)
                    backgroundSprite!.run(fadeOut)
                }
            }
            
            let delay                   = SKAction.wait(forDuration: duration)
            let callFunc                = SKAction.run(self.clearEffectRunningFlag)
            let delayedClearSequence    = SKAction.sequence([delay, callFunc])
            
            self.run(delayedClearSequence)
            
            viewSettings.setValue(NSNumber(value: 0.0), forKey: VNSceneViewDefaultBackgroundOpacityKey)
            
        // This just plays a sound. I had actually thought about creating some kind of system to keep track of all
        // the sounds loaded, and then to manually remove them from memory once they were no longer being used,
        // but I've never gotten around to implementing it.
        case VNScriptCommandPlaySound:
            let soundName = String(describing: command.object(at: 1))
            
            self.playSoundEffect(filename: soundName)
            
        // This plays music (an MP3 file is good, though AAC might be better since iOS devices supposedly have built-in
        // hardware-decoding for them, or CAF since they have small filesizes and small memory footprints). You can only
        // play one music file at a time. You can choose whether it loops infinitely, or if it just plays once.
        //
        // If you want to STOP music from playing, you can also pass "nil" as the filename (parameter #1) to cause
        // VNScene to stop all music.
        case VNScriptCommandPlayMusic:
            
            let musicName = String(describing: command.object(at: 1))
            let musicShouldLoop = (command.object(at: 2) as! NSNumber)
            
            //print("[VNSceneNode] Should now stop background music.")
            self.stopBGMusic()
            
            if musicName.caseInsensitiveCompare(VNScriptNilValue) == ComparisonResult.orderedSame {
                // If 'nil' was passed in, remove all the existing music data from the saved game information
                record.removeObject(forKey: VNSceneMusicToPlayKey)
                record.removeObject(forKey: VNSceneMusicShouldLoopKey)
            } else {
                // otherwise there should be an actual file here that needs to be played
                record.setValue(musicName, forKey: VNSceneMusicToPlayKey)
                record.setValue(musicShouldLoop, forKey: VNSceneMusicShouldLoopKey)
                
                // Play the new background music
                self.playBGMusic(filename: musicName, willLoopForever: musicShouldLoop.boolValue)
            }
            
            
        // This command sets a variable (or "flag"), which is usually an "int" value stored in an NSNumber object by a dictionary.
        // VNScene stores a local dictionary, and whenever the game is saved, the contents of that dictionary are copied over to
        // SMRecord's own flags dictionary (and stored in device memory).
        case VNScriptCommandSetFlag:
            
            let flagName = String(describing: command.object(at: 1))
            let flagValue:AnyObject = command.object(at: 2) as AnyObject
            
            // Store the new value in the local dictionary
            flags.setValue(flagValue, forKey: flagName)
            
        // This modifies an existing flag's integer value by a certain amount (you might have guessed: a positive value "adds",
        // while a negative "subtracts). If no flag actually exists, then a new flag is created with whatever value was passed in.
        case VNScriptCommandModifyFlagValue:
            let flagName = String(describing: command.object(at: 1))
            let modifyWithValue = (command.object(at: 2) as! NSNumber).intValue
            
            let originalObject:AnyObject? = flags.object(forKey: flagName) as AnyObject?
            if originalObject == nil {
                // Set a new value based on the parameter
                flags.setValue( NSNumber(value: modifyWithValue), forKey: flagName)
                return; // And that's the end of it
            }
            
            // Handle modification operation
            let originalNumber  = originalObject! as! NSNumber
            let originalValue   = originalNumber.intValue
            let modifiedValue   = originalValue + modifyWithValue
            let finalNumber     = NSNumber(value: modifiedValue)
            
            flags.setValue(finalNumber, forKey: flagName)
            
        // This checks if a particular flag has a certain value. If it does, then it executes ANOTHER command (which starts
        // at the third parameter and continues to whatever comes afterwards).
        case VNScriptCommandIfFlagHasValue:
            let flagName            = String(describing: command.object(at: 1))
            let expectedValue       = (command.object(at: 2) as! NSNumber).intValue
            let secondaryCommand    = command.object(at: 3) as! NSArray // Secondary command, which runs if the actual and expected values are the same
            
            let theFlag:NSNumber? = flags.object(forKey: flagName) as? NSNumber
            if theFlag == nil {
                return;
            }
            
            let actualValue = Int(theFlag!.int32Value)
            
            if( actualValue != expectedValue ) {
                return;
            }
            
            // If the function reaches this point, it's safe to move on to the next phase
            self.processCommand(command: secondaryCommand)
            
            let secondaryCommandType = (secondaryCommand.object(at: 0) as! NSNumber).intValue
            
            // Make sure that things don't get knocked out of order by the secondary command (if it involves switching conversations)
            if secondaryCommandType != VNScriptCommandChangeConversation {
                script!.currentIndex -= 1
            }
            
        // This checks if a particular flag is GREATER THAN a certain value. If it does, then it executes ANOTHER command (which starts
        // at the third parameter and continues to whatever comes afterwards).
        case VNScriptCommandIsFlagMoreThan:
            let flagName = String(describing: command.object(at: 1))
            let expectedValue = (command.object(at: 2) as! NSNumber).intValue
            let secondaryCommand = command.object(at: 3) as! NSArray
            
            let theFlag:NSNumber? = flags.object(forKey: flagName) as? NSNumber
            if theFlag == nil {
                return;
            }
            
            let actualValue = Int(theFlag!.int32Value)
            
            if( actualValue <= expectedValue ) {
                return;
            }
            
            self.processCommand(command: secondaryCommand)
            
            let secondaryCommandType = (secondaryCommand.object(at: 0) as! NSNumber).intValue
            if( secondaryCommandType != VNScriptCommandChangeConversation ) {
                script!.currentIndex -= 1
            }
            
            
        // This checks if a particular flag LESS THAN certain value. If it does, then it executes ANOTHER command (which starts
        // at the third parameter and continues to whatever comes afterwards).
        case VNScriptCommandIsFlagLessThan:
            
            let flagName            = String(describing: command.object(at: 1))
            let expectedValue       = (command.object(at: 2) as! NSNumber).intValue
            let secondaryCommand    = command.object(at: 3) as! NSArray
            
            let theFlag:NSNumber? = flags.object(forKey: flagName) as? NSNumber
            if( theFlag == nil ) {
                return;
            }
            
            let actualValue = Int(theFlag!.int32Value)
            if( actualValue >= expectedValue ) {
                return;
            }
            
            self.processCommand(command: secondaryCommand)
            
            let secondaryCommandType = (secondaryCommand.object(at: 0) as! NSNumber).intValue
            if( secondaryCommandType != VNScriptCommandChangeConversation ) {
                script!.currentIndex -= 1;
            }
            
        // This checks if a particular flag is between two values (a lesser value and a greater value). If thie is the case,
        // then a secondary command is run.
        case VNScriptCommandIsFlagBetween:
            let flagName            = String(describing: command.object(at: 1))
            let lesserValue         = (command.object(at: 2) as! NSNumber).intValue
            let greaterValue        = (command.object(at: 3) as! NSNumber).intValue
            let secondaryCommand    = command.object(at: 4) as! NSArray
            
            let theFlag:NSNumber? = flags.object(forKey: flagName) as? NSNumber
            if( theFlag == nil ) {
                return;
            }
            
            let actualValue = Int(theFlag!.int32Value)
            
            if( actualValue <= lesserValue || actualValue >= greaterValue ) {
                return;
            }
            
            self.processCommand(command: secondaryCommand)
            
            let secondaryCommandType = (secondaryCommand.object(at: 0) as! NSNumber).intValue
            if( secondaryCommandType != VNScriptCommandChangeConversation ) {
                script!.currentIndex -= 1;
            }
            
        // This command presents the user with a choice menu. When the user makes a choice, it results in the value of a flag
        // being modified by a certain amount (just like if the .MODIFYFLAG command had been used).
        case VNScriptCommandModifyFlagOnChoice:
            
            // Create "safe" autosave before doing something as volatile as presenting a choice menu
            self.createSafeSave()
            
            let choiceTexts     = command.object(at: 1) as! NSArray
            let variableNames   = command.object(at: 2) as! NSArray
            let variableValues  = command.object(at: 3) as! NSArray
            
            // Prepare the arrays
            buttons.removeAllObjects()
            choices.removeAllObjects()
            choiceExtras.removeAllObjects()
        
            if let arrayOfButtons = arrayOfButtonSprites(numberOfButtons: choiceTexts.count) {
                addLabelsToArrayOfButtons(arrayOfLabels: choiceTexts, arrayOfButtons: arrayOfButtons)
                addButtonsToScene(arrayOfButtons: arrayOfButtons)
                
                // set up choices
                SMUtility.Arrays.addObjectsToMutableArray(destination: choices,       source: variableNames)
                SMUtility.Arrays.addObjectsToMutableArray(destination: choiceExtras,  source: variableValues)
                
                mode = VNSceneModeChoiceWithFlag
            } else {
                print("[VNSceneNode] WARNING: Could not create buttons for .MODIFYFLAGONCHOICE command.")
            }
            
            
        // This command will cause VNScene to switch conversations if a certain flag holds a particular value.
        case VNScriptCommandJumpOnFlag:
            let flagName                = String(describing: command.object(at: 1))
            let expectedValue           = (command.object(at: 2) as! NSNumber).intValue
            let targetedConversation    = command.object(at: 3) as! NSString
            
            let theFlag:NSNumber? = flags.object(forKey: flagName) as? NSNumber
            if theFlag == nil {
                return;
            }
            
            let actualValue = Int(theFlag!.int32Value)
            if( actualValue != expectedValue ) {
                return;
            }
            
            let convo:NSArray? = script!.data!.object(forKey: targetedConversation) as? NSArray
            if convo == nil {
                print("[VNSceneNode] ERROR: No section titled \(targetedConversation) was found in script!")
                return;
            }
            
            //script!.changeConversationTo(targetedConversation as String)
            if script!.changeConversationTo(nameOfConversation: targetedConversation as String) == false {
                print("[VNSceneNode] WARNING: Could not switch script to section named: \(targetedConversation)")
            }
            script!.indexesDone -= 1;
            
        // This command is used in conjuction with the VNSystemCall class, and is used to create certain game-specific effects.
        case VNScriptCommandSystemCall:
            
            let systemCallArray = NSMutableArray(array: command)
            systemCallArray.removeObject(at: 0) // Remove the ".systemcall" part of the command
            
            systemCallHelper.sendCall(systemCallArray)
            
            
        // This command replaces the scene's script with a script loaded from another .PLIST file. This is useful in case
        // your script is actually broken up into multiple .PLIST files.
        case VNScriptCommandSwitchScript:
            
            let scriptName      = command.object(at: 1) as! NSString
            let startingPoint   = command.object(at: 2) as! NSString
            
            print("[VNSceneNode] Switching to script named \(scriptName) with starting point [\(startingPoint)]");
            
            let loadingDictionary = NSDictionary(dictionary: [VNScriptFilenameKey:scriptName,
                                                              VNScriptConversationNameKey:startingPoint])
            
            script = VNScript(info: loadingDictionary);
            if script == nil {
                print("[VNSceneNode] ERROR: Cannot load script named: \(scriptName)")
                return;
            }
            
            script!.indexesDone -= 1;
            print("[VNSceneNode] Script object replaced.");
            
        case VNScriptCommandSetSpeechFont:

            speechFont = String(describing: command.object(at: 1))
            
            // This will only change the font if the font name is of a "proper" length; no supported font on iOS
            // is shorter than 4 characters (as far as I know).
            //if countElements(speechFont) > 3 {
            if SMUtility.Strings.lengthOf(string: speechFont) > 3 {
                
                speech!.fontName = String(describing: command.object(at: 1))
                
                // Update record with override
                record.setObject(speechFont, forKey: VNSceneOverrideSpeechFontKey as NSCopying)
            }
            
        case VNScriptCommandSetSpeechFontSize:
            
            let foundationString    = String(describing: command.object(at: 1)) as NSString
            let convertedSize       = CGFloat( foundationString.floatValue )
            
            fontSizeForSpeech = convertedSize
            
            // Check for a font size that's too small; if this is the case, then just switch to a "normal" font size
            if( fontSizeForSpeech < 1.0 ) {
                fontSizeForSpeech = 13.0;
            }
            
            speech!.fontSize = fontSizeForSpeech;
            
            // Store override data
            let storedFontSize = NSNumber( value: Double(fontSizeForSpeaker) ) // Conver to NSNumber
            record.setValue(storedFontSize, forKey: VNSceneOverrideSpeechSizeKey)
            
            
        case VNScriptCommandSetSpeakerFont:
            
            speakerFont = String(describing: command.object(at: 1))
            
            if SMUtility.Strings.lengthOf(string: speakerFont) > 3 {
                
                speaker!.fontName = speakerFont
                
                // Update records with override
                record.setValue(speakerFont, forKey: VNSceneOverrideSpeakerFontKey)
                
                // Set position
                speaker!.anchorPoint = CGPoint(x: 0, y: 1.0)
                speaker!.position = self.updatedSpeakerPosition()
            }
            
        case VNScriptCommandSetSpeakerFontSize:
            
            let convertedString = String(describing: command.object(at: 1)) as NSString
            
            fontSizeForSpeaker = CGFloat( convertedString.floatValue )
            
            if fontSizeForSpeaker < 1.0 {
                fontSizeForSpeaker = 13.0
            }
            
            speaker!.fontSize = fontSizeForSpeaker
            
            // Store override data
            let storedNumber = NSNumber(value: Double( fontSizeForSpeaker ))
            record.setValue(storedNumber, forKey: VNSceneOverrideSpeakerSizeKey)
            
            // Set the position
            speaker!.anchorPoint = CGPoint(x: 0, y: 1.0);
            speaker!.position = self.updatedSpeakerPosition()
            
        case VNScriptCommandSetTypewriterText:
            
            if let first = command.object(at: 1) as? NSNumber {
                TWSpeedInCharacters = first.intValue;
            }
            if let second = command.object(at: 2) as? NSNumber {
                TWCanSkip = second.boolValue
            }
            
            self.updateTypewriterTextSettings()
            
            
        case VNScriptCommandSetSpeechbox:
            
            let duration = (command.object(at: 2) as! NSNumber).doubleValue
            let speechboxFilename = String(describing: command.object(at: 1))
            
            setSpeechBox(speechboxFilename, duration: duration)
            
        case VNScriptCommandSetSpriteAlias:
            
            let aliasParameter = command.object(at: 1) as! NSString
            let filenameParameter = command.object(at: 2) as! NSString
            
            setSpriteAlias(aliasParameter as String, filename: filenameParameter as String)
            
        case VNScriptCommandFlipSprite:
            
            let spriteName = String(describing: command.object(at: 1))
            let durationAsDouble = (command.object(at: 2) as! NSNumber).doubleValue
            let flipHorizontal = (command.object(at: 3) as! NSNumber).boolValue
            
            flipSpriteNamed(spriteName, duration: durationAsDouble, horizontally: flipHorizontal)
            
            
        case VNScriptCommandRollDice:
            
            let maximumNumber   = command.object(at: 1) as! NSNumber
            let numberOfDice    = command.object(at: 2) as! NSNumber
            let flagName        = command.object(at: 3) as! NSString
            
            rollDice(numberOfDice.intValue, maximumSidesOfDice: maximumNumber.intValue, plusFlagModifier: flagName as String)
            
        case VNScriptCommandModifyChoiceboxOffset:
            
            let xOffset = command.object(at: 1) as! NSNumber;
            let yOffset = command.object(at: 2) as! NSNumber;
            
            modifyChoiceboxOffset(xOffset.doubleValue, yOffset: yOffset.doubleValue)
            
        case VNScriptCommandScaleBackground:
            
            // get the background sprite
            let backgroundSprite:SKSpriteNode? = self.childNode(withName: VNSceneTagBackground) as? SKSpriteNode
            if( backgroundSprite == nil ) {
                return
            }
            
            let scaleNumber = command.object(at: 1) as! NSNumber
            let durationNumber = command.object(at: 2) as! NSNumber
            
            //scaleBackground(scaleFactor: scaleNumber.doubleValue, duration: durationNumber.doubleValue)
            scaleBackground(backgroundSprite!, scaleFactor: scaleNumber.doubleValue, duration: durationNumber.doubleValue)
            
        case VNScriptCommandScaleSprite:
            
            let spriteName = command.object(at: 1) as! NSString
            let scaleNumber = command.object(at: 2) as! NSNumber
            let durationNumber = command.object(at: 3) as! NSNumber
            
            scaleSprite(spriteName as String, scalingAmount: scaleNumber.doubleValue, duration: durationNumber.doubleValue)
            
        case VNScriptCommandAddToChoiceSet:

            let setName     = command.object(at: 1) as! String
            let destination = command.object(at: 2) as! String
            let choiceText  = command.object(at: 3) as! String
            addToChoiceSet(setName: setName, destination: destination, choiceText: choiceText)

        case VNScriptCommandRemoveFromChoiceSet:

            let setName = command.object(at: 1) as! String
            let destination = command.object(at: 2) as! String

            removeFromChoiceSet(setName: setName, destination: destination)

        case VNScriptCommandWipeChoiceSet:
            //print("stuff happens")

            let setName = command.object(at: 1) as! String
            wipeChoiceSet(setName: setName)

        case VNScriptCommandShowChoiceSet:

            let setName = command.object(at: 1) as! String
            displayChoiceSet(setName: setName)

        // This checks if a particular flag is GREATER THAN a certain value. If it does, then it executes ANOTHER command (which starts
        // at the third parameter and continues to whatever comes afterwards).
        case VNScriptCommandIsFlagMoreThanFlag:
            
            let firstFlag           = String(describing: command.object(at: 1))
            let secondFlag          = String(describing: command.object(at: 2))
            let secondaryCommand    = command.object(at: 3) as! NSArray

            let firstFlagNumber:NSNumber? = flags.object(forKey: firstFlag) as? NSNumber
            if firstFlagNumber == nil {
                return;
            }

            let secondFlagNumber:NSNumber? = flags.object(forKey: secondFlag) as? NSNumber
            if secondFlagNumber == nil {
                return
            }

            let firstValue = firstFlagNumber!.intValue
            let secondValue = secondFlagNumber!.intValue

            // halts processing if the first value is NOT greater than the second value
            if( firstValue <= secondValue ) {
                return;
            }

            self.processCommand(command: secondaryCommand)

            let secondaryCommandType = (secondaryCommand.object(at: 0) as! NSNumber).intValue
            if( secondaryCommandType != VNScriptCommandChangeConversation ) {
                script!.currentIndex -= 1
            }

        // This checks if a flag is LESS THAN another flag's value, and executes another command if it's true.
        case VNScriptCommandIsFlagLessThanFlag:
            let firstFlag           = String(describing: command.object(at: 1))
            let secondFlag          = String(describing: command.object(at: 2))
            let secondaryCommand    = command.object(at: 3) as! NSArray

            let firstFlagNumber:NSNumber? = flags.object(forKey: firstFlag) as? NSNumber
            if firstFlagNumber == nil {
                return;
            }

            let secondFlagNumber:NSNumber? = flags.object(forKey: secondFlag) as? NSNumber
            if secondFlagNumber == nil {
                return
            }

            let firstValue = firstFlagNumber!.intValue
            let secondValue = secondFlagNumber!.intValue

            // halts processing if the first value is NOT LESS than the second value
            if( firstValue >= secondValue ) {
                return;
            }

            self.processCommand(command: secondaryCommand)

            let secondaryCommandType = (secondaryCommand.object(at: 0) as! NSNumber).intValue
            if( secondaryCommandType != VNScriptCommandChangeConversation ) {
                script!.currentIndex -= 1
            }

        // Check if two flags are of equal numerical value, and if so, then execute another command
        case VNScriptCommandIsFlagEqualToFlag:
            let firstFlag           = String(describing: command.object(at: 1))
            let secondFlag          = String(describing: command.object(at: 2))
            let secondaryCommand    = command.object(at: 3) as! NSArray

            let firstFlagNumber:NSNumber? = flags.object(forKey: firstFlag) as? NSNumber
            if firstFlagNumber == nil {
                return;
            }

            let secondFlagNumber:NSNumber? = flags.object(forKey: secondFlag) as? NSNumber
            if secondFlagNumber == nil {
                return
            }

            let firstValue = firstFlagNumber!.intValue
            let secondValue = secondFlagNumber!.intValue

            // halts processing if the first value is NOT LESS than the second value
            if( firstValue != secondValue ) {
                return;
            }

            self.processCommand(command: secondaryCommand)

            let secondaryCommandType = (secondaryCommand.object(at: 0) as! NSNumber).intValue
            if( secondaryCommandType != VNScriptCommandChangeConversation ) {
                script!.currentIndex -= 1
            }

        case VNScriptCommandIncreaseFlagByFlag:
            let firstFlag   = String(describing: command.object(at: 1))
            let secondFlag  = String(describing: command.object(at: 2))

            var firstValue = Int(0)
            var secondValue = Int(0)

            if let firstFlagObject = flags.object(forKey: firstFlag) as? NSNumber {
                firstValue = firstFlagObject.intValue
            }
            if let secondFlagObject = flags.object(forKey: secondFlag) as? NSNumber {
                secondValue = secondFlagObject.intValue
            }

            let finalValue = firstValue + secondValue
            let updatedFlag = NSNumber(value: finalValue)

            flags.setValue(updatedFlag, forKey: firstFlag)

        case VNScriptCommandDecreaseFlagByFlag:
            let firstFlag   = String(describing: command.object(at: 1))
            let secondFlag  = String(describing: command.object(at: 2))

            var firstValue = Int(0)
            var secondValue = Int(0)

            if let firstFlagObject = flags.object(forKey: firstFlag) as? NSNumber {
                firstValue = firstFlagObject.intValue
            }
            if let secondFlagObject = flags.object(forKey: secondFlag) as? NSNumber {
                secondValue = secondFlagObject.intValue
            }

            let finalValue = firstValue - secondValue
            let updatedFlag = NSNumber(value: finalValue)

            flags.setValue(updatedFlag, forKey: firstFlag)
            
            
        case VNScriptCommandShowChoiceAndJump:
            
            sayDialogue(line: command.object(at: 1) as! String)
            
            self.createSafeSave() // Always create safe-save before doing something volatile
            
            let choiceTexts     = command.object(at: 2) as! NSArray // Get the strings to display for individual choices
            let destinations    = command.object(at: 3) as! NSArray // Get the names of the conversations to "jump" to
            
            // Make sure the arrays that hold the data are prepared
            buttons.removeAllObjects()
            choices.removeAllObjects()
            
            if let arrayOfButtons = arrayOfButtonSprites(numberOfButtons: choiceTexts.count) {
                addLabelsToArrayOfButtons(arrayOfLabels: choiceTexts, arrayOfButtons: arrayOfButtons)
                addButtonsToScene(arrayOfButtons: arrayOfButtons)
                SMUtility.Arrays.addObjectsToMutableArray(destination: choices, source: destinations)
                
                mode = VNSceneModeChoiceWithJump
            } else {
                print("[VNSceneNode] ERROR: Could not create buttons for .SHOWCHOICEANDJUMP command.")
            }
            
            
        // This command presents the user with a choice menu. When the user makes a choice, it results in the value of a flag
        // being modified by a certain amount (just like if the .MODIFYFLAG command had been used).
        case VNScriptCommandShowChoiceAndModify:
            
            sayDialogue(line: command.object(at: 1) as! String)
            
            // Create "safe" autosave before doing something as volatile as presenting a choice menu
            self.createSafeSave()
            
            let choiceTexts     = command.object(at: 2) as! NSArray
            let variableNames   = command.object(at: 3) as! NSArray
            let variableValues  = command.object(at: 4) as! NSArray
            let numberOfChoices = choiceTexts.count
            
            // Prepare the arrays
            buttons.removeAllObjects()
            choices.removeAllObjects()
            choiceExtras.removeAllObjects()
            
            if let arrayOfButtons = arrayOfButtonSprites(numberOfButtons: numberOfChoices) {
                addLabelsToArrayOfButtons(arrayOfLabels: choiceTexts, arrayOfButtons: arrayOfButtons)
                addButtonsToScene(arrayOfButtons: arrayOfButtons)
                // add the extra info (flags/variables, and the amount to change them by)
                SMUtility.Arrays.addObjectsToMutableArray(destination: choices,       source: variableNames)
                SMUtility.Arrays.addObjectsToMutableArray(destination: choiceExtras,  source: variableValues)
                mode = VNSceneModeChoiceWithFlag
            } else {
                print("[VNSceneNode] WARNING: Could not create buttons for .SHOWCHOICEANDMODIFY command.")
            }
            
        case VNScriptCommandSetChoiceMinOpacity:
            if let updatedMinimumOpacity = command.object(at: 1) as? NSNumber {
                let minOpacityValue     = SMUtility.Math.clampDouble(input: updatedMinimumOpacity.doubleValue, min: 0.0, max: 1.0)
                let valueAsNumber       = NSNumber(floatLiteral: minOpacityValue)
                choiceboxMinimumOpacity = CGFloat( minOpacityValue )
                
                // store override value directly into the record
                record.setValue(valueAsNumber, forKey: VNSceneOverrideChoiceMinOpacity)
            } 
            
        case VNScriptCommandSetChoiceBlinkSpeed:
            if let updatedBlinkSpeed = command.object(at: 1) as? NSNumber {
                var blinkSpeedValue     = updatedBlinkSpeed.doubleValue
                
                // no negative values allowed
                if blinkSpeedValue < 0 {
                    blinkSpeedValue = 0.0
                }
                
                let valueAsNumber       = NSNumber(floatLiteral: blinkSpeedValue)
                choiceboxBlinkSpeed     = blinkSpeedValue
                
                // store the override in the record
                record.setValue(valueAsNumber, forKey: VNSceneOverrideChoiceBlinkSpeed)
            }
                
        default:
            print("[VNSceneNode] WARNING: Unknown command found in script. The command's NSArray is: %@", command);
        } // switch
    } // function
    
    
    
    // MARK: - Script commands
    
    /*
     NOTE:  Originally, all this functionality was in the "processCommand" function. However, while the code didn't have any errors,
     attempting to compile on Xcode 8 would cause linker errors. The only way to avoid linker errors was to either completely comment
     out the last switch/case cases, or to just move the code to its own seperate functions; the latter is what's being done now.
     */
    
    
    // scales background to (scaleFactor) amount
    func scaleBackground(_ sprite:SKSpriteNode, scaleFactor:Double, duration:Double) {
        
        if duration <= 0.0 {
            sprite.setScale(CGFloat(scaleFactor))
        } else {
            self.createSafeSave()
            self.setEffectRunningFlag()
            
            let scaleAction     = SKAction.scale(to: CGFloat(scaleFactor), duration: duration);
            let callClearFlag   = SKAction.run(self.clearEffectRunningFlag);
            let sequence        = SKAction.sequence([scaleAction, callClearFlag]);
            sprite.run(sequence);
        }
    }
    
    // scales an existing sprite by a certain amount over a particular duration
    func scaleSprite(_ spriteName:String, scalingAmount:Double, duration:Double) {
        
        let sprite:SKSpriteNode? = sprites.object(forKey: spriteName) as? SKSpriteNode
        if sprite == nil {
            return;
        }
        
        var xScale = CGFloat(scalingAmount)
        var yScale = CGFloat(scalingAmount)
        
        // invert x/y-scale values when dealing with flipped sprites
        if sprite!.xScale < 0.0 {
            xScale = xScale * (-1)
        }
        if sprite!.yScale < 0.0 {
            yScale = yScale * (-1)
        }
        
        if duration <= 0.0 {
            sprite!.xScale = xScale
            sprite!.yScale = yScale
        } else {
            self.createSafeSave()
            self.setEffectRunningFlag()
            
            let scaleAction = SKAction.scaleX(to: xScale, y: yScale, duration: duration)
            let callClearFlag = SKAction.run(self.clearEffectRunningFlag)
            let sequence = SKAction.sequence([scaleAction, callClearFlag])
            
            sprite!.run(sequence)
        }
    }
    
    // swaps the current speechbox sprite for another sprite
    func setSpeechBox(_ spriteName:String, duration:Double) {
        // prepare positioning data
        var boxToBottomMargin   = CGFloat(0)
        let widthOfScreen       = viewSize.width//SMScreenSizeInPoints().width
        boxToBottomMargin       = CGFloat((viewSettings.object(forKey: VNSceneViewSpeechBoxOffsetFromBottomKey) as! NSNumber).floatValue)
        
        if speechBox == nil {
            print("[VNSceneNode] ERROR: .SETSPEECHBOX failed as speechbox node was invalid.")
            return;
        }
        
        if( duration <= 0.0 ) {
            
            let originalChildren = speechBox!.children
            speechBox?.removeFromParent()
            
            speechBox = SKSpriteNode(imageNamed: spriteName);
            
            speechBox!.position     = CGPoint( x: widthOfScreen * 0.5, y: (speechBox!.frame.size.height * 0.5) + boxToBottomMargin )
            speechBox!.alpha        = 1.0;
            speechBox!.zPosition    = VNSceneUILayer;
            speechBox!.name         = VNSceneTagSpeechBox;
            
            self.addChild( speechBox! )
            
            if originalChildren.count > 0 {
                for aChild in originalChildren {
                    speechBox!.addChild(aChild)
                }
            }
            
            // set speechbox color
            speechBox!.colorBlendFactor = 1.0;
            speechBox!.color            = speechBoxColor;
            
        } else {
            
            // switch gradually
            self.createSafeSave()
            self.setEffectRunningFlag()
            
            let speechBoxChildren = speechBox!.children
            
            // create fake placeholder speechbox that looks like the original
            let fakeSpeechbox       = SKSpriteNode(texture: speechBox!.texture)
            fakeSpeechbox.position  = speechBox!.position;
            fakeSpeechbox.zPosition = speechBox!.zPosition;
    
            self.addChild(fakeSpeechbox)
            
            // get rid of the original speechbox and replace it with a new and invisible speechbox
            //[speechBox removeFromParent];
            speechBox!.removeFromParent()
            speechBox = SKSpriteNode(imageNamed: spriteName)
            
            //speechBox = [SKSpriteNode spriteNodeWithImageNamed:parameter1];
            speechBox!.position     = CGPoint( x: widthOfScreen * 0.5, y: (speechBox!.frame.size.height * 0.5) + boxToBottomMargin );
            speechBox!.alpha        = 0.0;
            speechBox!.zPosition    = VNSceneUILayer;
            speechBox!.name         = VNSceneTagSpeechBox;
        
            self.addChild(speechBox!)
            
            // set speechbox color
            speechBox!.colorBlendFactor = 1.0;
            speechBox!.color            = speechBoxColor;
            
            //for( SKNode* aChild in speechBoxChildren ) {
            for aChild in speechBoxChildren {
                speechBox!.addChild(aChild)
                
                // cause each child node to gradually fade out and fade back in so it looks like it's doing it in time with the speechboxes.
                let fadeOutChild        = SKAction.fadeOut(withDuration: duration * 0.5)
                let fadeInChild         = SKAction.fadeIn(withDuration: duration * 0.5)
                let sequenceForChild    = SKAction.sequence([fadeOutChild, fadeInChild])
                
                aChild.run(sequenceForChild)
            }
            
            // fade out the fake speechbox
            let fadeOut = SKAction.fadeOut(withDuration: duration * 0.5)
            fakeSpeechbox.run(fadeOut)
            
            // fade in the new "real" speechbox
            let fadeIn = SKAction.fadeOut(withDuration: duration * 0.5)
            let delay = SKAction.wait(forDuration: duration * 0.5)
            //let callFunc = SKAction.performSelector(@selec)
            let callFunc = SKAction.run(self.clearEffectRunningFlag)
            let delayedFadeInSequence = SKAction.sequence([delay, fadeIn, callFunc])
            
            speechBox!.run(delayedFadeInSequence)
        }
        
        record.setValue(spriteName, forKey:VNSceneSavedOverriddenSpeechboxKey)
    }
    
    // adjusts sprite alias
    func setSpriteAlias(_ alias:String, filename:String) {
        let filenameParameter = filename as NSString
        
        if filenameParameter.caseInsensitiveCompare(VNScriptNilValue) == ComparisonResult.orderedSame {
            localSpriteAliases.removeObject(forKey: alias) // remove data for this alias
        } else {
            localSpriteAliases.setValue(filename, forKey: alias)
        }
    }
    
    // moves choice box offsets around (instead of having the choicebox buttons appearing near the middle of the screen)
    func modifyChoiceboxOffset(_ xOffset:Double, yOffset:Double) {
        choiceButtonOffsetX = CGFloat(xOffset)
        choiceButtonOffsetY = CGFloat(yOffset)
        
        // save offset data to record
        let xSave = NSNumber(value: xOffset)
        let ySave = NSNumber(value: yOffset)
        record.setValue(xSave, forKey: VNSceneViewChoiceButtonOffsetX);
        record.setValue(ySave, forKey: VNSceneViewChoiceButtonOffsetY);
        
    }
    
    // rolls dice; stores value in a predetermined flag
    func rollDice(_ numberOfDice:Int, maximumSidesOfDice:Int, plusFlagModifier:String) {
        var flagModifier = 0
        
        let theFlag:NSNumber? = flags.object(forKey: plusFlagModifier) as? NSNumber
        if( theFlag != nil ) {
            flagModifier = theFlag!.intValue
        }
        
        let roll = SMUtility.Dice.roll(numberOfDice: numberOfDice, maximumRollValue: maximumSidesOfDice, plusModifier: flagModifier)
        // Store results of roll in DICEROLL flag
        let diceRollResult = NSNumber(integerLiteral: roll)
        flags.setValue(diceRollResult, forKey: VNSceneDiceRollResultFlag)
        //print("[VNSceneNode] Dice roll results of \(roll) stored in flag named: DICEROLL");
    }
    
    // flips sprite around, can flip sprite vertically or horizontally
    func flipSpriteNamed(_ spriteName:String, duration:Double, horizontally:Bool) {
        // get sprite using name
        let sprite:SKSpriteNode? = sprites.object(forKey: spriteName) as? SKSpriteNode
        if sprite == nil {
            return;
        }
        
        self.createSafeSave()
        
        // If this has a duration of zero, the action will take place instantly and then the function will return
        if( duration <= 0.0 ) {
            // determine flip style
            if( horizontally == true ) {
                sprite!.xScale = sprite!.xScale * (-1);
            } else {
                sprite!.yScale = sprite!.yScale * (-1);
            }
            return;
        }
        
        setEffectRunningFlag()
        
        var scaleToX = sprite!.xScale;
        var scaleToY = sprite!.yScale;
        
        var scalingAction:SKAction? = nil
        
        // determine what kind of action to take (this will determine scaling values)
        if( horizontally == true ) {
            scaleToX = scaleToX * (-1);
            scalingAction = SKAction.scaleX(to: scaleToX, duration:duration)
        } else {
            scaleToY = scaleToY * (-1);
            scalingAction = SKAction.scaleY(to: scaleToY, duration:duration)
        }
        
        let clearEffectFlag = SKAction.run(self.clearEffectRunningFlag)
        let theSequence     = SKAction.sequence([scalingAction!, clearEffectFlag])
        
        sprite!.run(theSequence)
    }
}
