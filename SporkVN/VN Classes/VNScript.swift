//
//  VNSScript.swift
//  EKVN Swift
//
//  Created by James on 10/16/14.
//  Copyright (c) 2014 James Briones. All rights reserved.
//

import UIKit

/** DEFINITIONS **/

// Items inside of the script
let VNScriptStartingPoint      = "start"
let VNScriptActualScriptKey    = "actual script"

// Resource Dictionary
let VNScriptVariablesKey       = "variables"
let VNScriptSpritesArrayKey    = "sprites" // Stores filenames and sprite positions

// Flags for the script's dictionary. These are normally used for passing in dictionary values, and for when
// the script's data is saved to a dictionary (which can be stored as part of a save file... keep in mind
// that when the game is saved, all the game's data is stored in dictionaries).
let VNScriptConversationNameKey            = "conversation name"
let VNScriptFilenameKey                    = "filename"
let VNScriptIndexesDoneKey                 = "indexes done"
let VNScriptCurrentIndexKey                = "current index"

// The command types, in numeric format
let VNScriptCommandSayLine                  = 100
let VNScriptCommandAddSprite                = 101
let VNScriptCommandSetBackground            = 102
let VNScriptCommandSetSpeaker               = 103
let VNScriptCommandChangeConversation       = 104
let VNScriptCommandJumpOnChoice             = 105
let VNScriptCommandShowSpeechOrNot          = 106
let VNScriptCommandEffectFadeIn             = 107
let VNScriptCommandEffectFadeOut            = 108
let VNScriptCommandEffectMoveBackground     = 109
let VNScriptCommandEffectMoveSprite         = 110
let VNScriptCommandSetSpritePosition        = 111
let VNScriptCommandPlaySound                = 112
let VNScriptCommandPlayMusic                = 113
let VNScriptCommandSetFlag                  = 114
let VNScriptCommandModifyFlagValue          = 115 // Add or subtract
let VNScriptCommandIfFlagHasValue           = 116 // An "if" command, really
let VNScriptCommandModifyFlagOnChoice       = 117 // Choice changes variable
let VNScriptCommandAlignSprite              = 118
let VNScriptCommandRemoveSprite             = 119
let VNScriptCommandJumpOnFlag               = 120 // Change conversation if a certain flag holds a particular value
let VNScriptCommandSystemCall               = 121
let VNScriptCommandCallCode                 = 122
let VNScriptCommandIsFlagMoreThan           = 123
let VNScriptCommandIsFlagLessThan           = 124
let VNScriptCommandIsFlagBetween            = 125
let VNScriptCommandSwitchScript             = 126
let VNScriptCommandSetSpeechFont            = 127
let VNScriptCommandSetSpeechFontSize        = 128
let VNScriptCommandSetSpeakerFont           = 129
let VNScriptCommandSetSpeakerFontSize       = 130
// 131 was used by the now-obsolete "cinematic text" mode
let VNScriptCommandSetTypewriterText        = 132
let VNScriptCommandSetSpeechbox             = 133
let VNScriptCommandSetSpriteAlias           = 134
let VNScriptCommandFlipSprite               = 135

// The command strings. Each one starts with a dot (the parser will only check treat a line as a command if it starts
// with a dot), and is followed by some parameters, separated by colons.
let VNScriptStringAddSprite                 = ".addsprite"           // Adds a sprite to the screen (sprite fades in)
let VNScriptStringSetBackground             = ".setbackground"       // Changes the background of the visual novel scene
let VNScriptStringSetSpeaker                = ".setspeaker"          // Determines what name shows up when someone speaks
let VNScriptStringChangeConversation        = ".setconversation"     // Switches to a different section of the script
let VNScriptStringJumpOnChoice              = ".jumponchoice"        // Switches to different section based on user choice
let VNScriptStringShowSpeechOrNot           = ".showspeech"          // Determines whether speech text should be shown
let VNScriptStringEffectFadeIn              = ".fadein"              // Fades in the scene (background + characters)
let VNScriptStringEffectFadeOut             = ".fadeout"             // The scene fades out to black
let VNScriptStringEffectMoveBackground      = ".movebackground"      // Moves/pans the background
let VNScriptStringEffectMoveSprite          = ".movesprite"          // Moves a sprite around the screen
let VNScriptStringSetSpritePosition         = ".setspriteposition"   // Sets the sprite's exact position
let VNScriptStringPlaySound                 = ".playsound"           // Plays a sound effect once
let VNScriptStringPlayMusic                 = ".playmusic"           // Plays a sound file on infinite loop
let VNScriptStringSetFlag                   = ".setflag"             // Sets a "flag" (numeric value)
let VNScriptStringModifyFlagValue           = ".modifyflag"          // Modifies the numeric value of a flag
let VNScriptStringIfFlagHasValue            = ".isflag"              // Executes another command if a flag has a certain value
let VNScriptStringModifyFlagOnChoice        = ".modifyflagbychoice"  // Modifies a flag's value based on user input
let VNScriptStringAlignSprite               = ".alignsprite"         // Repositions a sprite (left, center, or right)
let VNScriptStringRemoveSprite              = ".removesprite"        // Removes a sprite from the screen
let VNScriptStringJumpOnFlag                = ".jumponflag"          // Changes script section based on flag value
let VNScriptStringSystemCall                = ".systemcall"          // Calls a predefined function outside the VN system
let VNScriptStringCallCode                  = ".callcode"            // Call any function (from a static object, usually)
let VNScriptStringIsFlagMoreThan            = ".isflagmorethan"      // Runs another command if flag is more than a certain value
let VNScriptStringIsFlagLessThan            = ".isflaglessthan"      // Runs a command if a flag is LESS than a certain value
let VNScriptStringIsFlagBetween             = ".isflagbetween"       // Runs a command if a flag is between two values
let VNScriptStringSwitchScript              = ".switchscript"        // Changes to another VNScript (stored in a different .plist file)
let VNScriptStringSetSpeechFont             = ".setspeechfont"       // Changes speech font
let VNScriptStringSetSpeechFontSize         = ".setspeechfontsize"   // Changes speech font size
let VNScriptStringSetSpeakerFont            = ".setspeakerfont"      // Changes the font used by the speaker name
let VNScriptStringSetSpeakerFontSize        = ".setspeakerfontsize"  // Changes font size for speaker
let VNScriptStringSetTypewriterText         = ".settypewritertext"   // Typewriter text, in which dialogue appears one character at a time
let VNScriptStringSetSpriteAlias            = ".setspritealias"      // Assigns a filename to a sprite alias
let VNScriptStringSetSpeechbox              = ".setspeechbox"        // dynamically change speechbox sprite
let VNScriptStringFlipSprite                = ".flipsprite"          // flips sprite around (left/right or upside-down)

// Script syntax
let VNScriptSeparationString               = ":"
let VNScriptNilValue                       = "nil"


/** CLASSES **/

class VNScript {
    
    var data: NSMutableDictionary?
    var conversation: NSArray?
    
    var filename: String?
    var conversationName: String?
    
    // Default set
    var currentIndex: Int   = 0
    var indexesDone: Int    = 0
    var maxIndexes: Int     = 0
    var isFinished: Bool    = false
    
    //init(nameOfFile:String, withConversationNamed:String) {
    //}
    
    // Loads the script from a dictionary with a lot of other data (such as specific conversation names, indexes, etc).
    init?(info:NSDictionary) {
    
        let filenameValue:NSString?       = info.object(forKey: VNScriptFilenameKey) as? NSString
        let conversationValue:NSString?   = info.object(forKey: VNScriptConversationNameKey) as? NSString
        let currentIndexValue:NSNumber?      = info.object(forKey: VNScriptCurrentIndexKey) as? NSNumber
        let indexesDoneValue:NSNumber?       = info.object(forKey: VNScriptIndexesDoneKey) as? NSNumber
        
        if filenameValue == nil || conversationValue == nil {
            print("[VNScript] ERROR: Invalid parameters")
            return nil
        }
        
        let fileLoadResult:Bool = self.didLoadFile(String(filenameValue!), convoName: conversationValue! as String);
        if fileLoadResult == false {
            print("[VNScript] ERROR: Could not load file.");
            return nil
        }
        
        // Copy index values
        if (currentIndexValue != nil) {
            currentIndex = Int(currentIndexValue!.int32Value)
        }
        if( indexesDoneValue != nil ) {
            indexesDone = Int(indexesDoneValue!.int32Value)
        }
    }
    
    // Load the script from a Property List (.plist) file in the app bundle. Make sure to not include the ".plist" in the file name.
    // For example, if the script is stored as "ThisScript.plist" in the bundle, just pass in "ThisScript" as the parameter.
    func didLoadFile( _ nameOfFile:String, convoName:String) -> Bool {
        
        let filepath:String? = Bundle.main.path(forResource: nameOfFile, ofType: "plist")
        if filepath == nil {
            print("[VNScript] ERROR: Cannot load file; filepath was invalid.")
            return false
        }
        
        let dict:NSDictionary? = NSDictionary(contentsOfFile: filepath!)
        if( dict == nil ) {
            print("[VNScript] ERROR: Cannot load file; dictionary data is invalid")
            return false
        }
    
        self.filename = nameOfFile // Copy filename
        
        // Load the data
        prepareScript(dict!)

        if changeConversationTo(convoName) == false {
            print("[VNScript] WARNING: Could not load conversation named: \(convoName)");
        }
        
        // Check if no valid data could be loaded from the file
        if( self.data == nil ) {
            print("[VNScript] ERROR: Could not load data.")
            return false
        }
        
        return true
    }
    
    // This processes the script, converting the data from its original Property List format into something
    // that can be used by VNLayer. (This new, converted format is stored in VNScript's "data" dictionary)
    func prepareScript(_ dict:NSDictionary) {
        
        let translatedScript:NSMutableDictionary = NSMutableDictionary(capacity: dict.count)
        
        // Go through each NSArray (conversation) in the script and translate each conversation into something that's
        // easier for the program to process. This "outer" for loop will get all the conversation names and the loops
        // inside this one will translate each conversation.
        for conversationKey in dict.allKeys {
            
            //let loadedArray:NSArray = dict.objectForKey(conversationKey) as NSArray
            //if let originalArray = loadedArray as? NSArray {
            
            let originalArray:NSArray = dict.object(forKey: conversationKey) as! NSArray
            
            if( originalArray.count > 0 ) {
                
                let translatedArray:NSMutableArray = NSMutableArray(capacity: originalArray.count)
                
                for someIndex in originalArray {
                    
                    if let line = someIndex as? NSString {
                        
                        //println("[line:NSString] \(line)");
                        
                        let commandFromLine = line.components(separatedBy: VNScriptSeparationString) as NSArray
                        let translatedLine:NSArray? = analyzedCommand( commandFromLine )
                        
                        if( translatedLine != nil ) {
                            translatedArray.add(translatedLine!)
                            //println("[translated line:NSArray] \(translatedLine!)")
                        }
                    }
                }
                
                let convoKey:NSString = conversationKey as! NSString
                translatedScript.setValue(translatedArray, forKey: convoKey as String)
            }
        }
        
        //println("[TRANSLATED SCRIPT] \(translatedScript)")
        
        //self.data! = NSDictionary(translatedScript)
        //var finishedDict:NSDictionary = NSDictionary(translatedScript)
        //data = translatedScript.copy() as? NSMutableDictionary
        data = translatedScript
        if( data == nil ) {
            print("[VNScript] ERROR: Data is invalid.")
        }
    }
    
    func info() -> NSDictionary {
        
        // Store index data
        let indexesDoneValue:NSNumber   = NSNumber(value: indexesDone)
        let currentIndexValue:NSNumber  = NSNumber(value: currentIndex)
        // Store other data
        let conversationValue:NSString  = NSString(string: conversationName!)
        let filenameValue:NSString      = NSString(string: filename!)
        
        /*let dictForScript:NSDictionary = NSDictionary(dictionaryLiteral:   indexesDoneValue,VNScriptIndexesDoneKey,
                                                                        currentIndexValue,VNScriptCurrentIndexKey,
                                                                        conversationValue,VNScriptConversationNameKey,
                                                                        filenameValue, VNScriptFilenameKey)*/
        let dictForScript = NSDictionary(dictionary: [  VNScriptIndexesDoneKey      :indexesDoneValue,
                                                        VNScriptCurrentIndexKey     :currentIndexValue,
                                                        VNScriptConversationNameKey :conversationValue,
                                                        VNScriptFilenameKey         :filenameValue])
        
        return dictForScript
    }
    
    func changeConversationTo(_ nameOfConversation:String) -> Bool {
        
        if( self.data != nil ) {
            
            conversation = data!.object(forKey: nameOfConversation) as? NSArray
            if( conversation != nil ) {
                
                self.conversationName   = nameOfConversation
                self.currentIndex       = 0
                self.indexesDone        = 0
                self.maxIndexes         = self.conversation!.count
                
                return true
            }
        }
        
        return false
    }
    
    func commandAtLine(_ line:Int) -> NSArray? {
        if( conversation != nil ) {
            
            if( line < conversation!.count) {
                return conversation!.object(at: line) as? NSArray
            }
        }
        
        return nil
    }
    
    func currentCommand() -> NSArray? {
        if( indexesDone > currentIndex ) {
            return nil
        }
        
        return commandAtLine(self.indexesDone)
    }
    
    func lineShouldBeProcessed() -> Bool {
        if indexesDone <= currentIndex {
            return true
        }
        
        return false
    }
    
    func advanceLine() {
        indexesDone = indexesDone + 1
    }
    
    func advanceIndex() {
        currentIndex += 1
    }
    
    func currentLine() -> NSArray? {
        return commandAtLine(currentIndex)
    }
    
    
    /** SCRIPT TRANSLATION **/
    
    
    // someCommand is an array of strings
    func analyzedCommand(_ command:NSArray) -> NSArray? {
        
        var analyzedArray:NSArray? = nil
        var type:NSNumber = NSNumber(value: 0)
        
        let firstString:NSString = command.object(at: 0) as! NSString
        let thatFirstStr = firstString as String
        //let firstCharacter = Array(thatFirstStr.characters)[0]
        let characterArray = Array(thatFirstStr.characters)
        let firstCharacter = characterArray[0]
        
        if command.count < 2 || firstCharacter != "." {
            
            //var fixedString:NSMutableString = NSMutableString("%@", command.objectAtIndex(0))
            var fixedString = "\(thatFirstStr)"
            if( command.count > 1 ) {
                
                //for var part = 1; part < command.count; part += 1 {
                for part in 1 ..< command.count {
                    
                    let str:NSString = command.object(at: part) as! NSString
                    let currentPart = str as String
                    
                    let fixedSubString = ":\(currentPart)"
                    fixedString += fixedSubString
                }
            }
            
            type = VNScriptCommandSayLine as NSNumber
            analyzedArray = NSArray(objects: type, fixedString)
            return analyzedArray // Return at once, instead of doing more processing
        }
        
        // Automatically prepare the action and parameter values. After all, pretty much every command has
        // an action string and a first parameter. It's only certain commands that have more parameters than that.
        let action:NSString     = command.object(at: 0) as! NSString
        let parameter1:NSString = command.object(at: 1) as! NSString
        
        if( action.caseInsensitiveCompare(VNScriptStringAddSprite) == ComparisonResult.orderedSame ) {
            
            // Function definition
            //
            //  Name: .ADDSPRITE
            //
            //  Uses Cocos2D to add a sprite to the screen. By default, the sprite usually appears right
            //  at the center of the screen.
            //
            //  Parameters:
            //
            //      #1: Sprite name (string) (example: "girl.png")
            //          Quite simply, the name of a file where the sprite is. Currently, the VN system doesn't
            //          support sprite sheets, so it needs to be a single image in a single file.
            //
            //      #2: (OPTIONAL) Sprite appears at once? (Boolean value) (example: "NO") (default is NO)
            //          If set to YES, the sprite appears immediately (no fade-in). If set to NO, then the
            //          sprite "gradually" fades in (though the fade-in usually takes a second or less).
            //
            //  Example: .addsprite:girl.png:NO
            //
            
            var parameter2:NSString = NSString(string: "NO")
            
            // If an existing command was already provided in the script, then overwrite the default one
            // with the value found within the script.
            if( command.count > 2 ) {
                parameter2 = command.object(at: 2) as! NSString
            }
            
            // Convert the second parameter to a Boolean value (stored as a Boolean NSNumber object)
            let appearParameter:NSNumber = NSNumber(value: parameter2.boolValue)
            
            type = VNScriptCommandAddSprite as NSNumber
            analyzedArray = NSArray(objects: type, parameter1, appearParameter)
            
        } else if action.caseInsensitiveCompare(VNScriptStringAlignSprite) == ComparisonResult.orderedSame {
        
            // Function definition
            //
            //  Name: .ALIGNSPRITE
            //
            //  Aligns a particular sprite in either the center, left, or right ends of the screen. This is done
            //  by finding the center of the sprite and setting the X coordinate to either 25% of the screen's
            //  width (on the iPhone 4S, this is 480*0.25 or 120), 50% (the middle), or 75% (the right).
            //
            //  There's also the Far Left (the left border of the screen), Far Right (the right border of the screen),
            //  and Extreme Left and Extremem Right, which are so far that the sprite is drawn offscreen.
            //
            //  Parameters:
            //
            //      #1: Name of sprite (string) (example: "girl.png")
            //          This is the name of the sprite to manipulate/align. All sprites currently displayed by the
            //          VN system are kept track of in the scene, so if the sprite exists onscreen, it'll be found.
            //
            //      #2: Alignment name (string) (example: "left") (default is "center")
            //          Determines whether to move the sprite to the LEFT, CENTER, or RIGHT of the screen.
            //          (Other, more unusual values also include FAR LEFT, FAR RIGHT, EXTREME LEFT, EXTREME RIGHT)
            //          It has to be one of those values; partial/percentage values aren't supported.
            //
            //      #2: (OPTIONAL) Alignment duration in SECONDS (double value) (example: "0.5") (Default is 0.5)
            //          Determines how long it takes for the sprite to move from its current position to the
            //          new position. Setting it to zero makes the transition instant. Time is measured in seconds.
            //
            //  Example: .alignsprite:girl.png:center
            //
            
            // Set default values
            var newAlignment:NSString   = NSString(string: "center")
            var duration:NSString       = NSString(string: "0.5")
            
            // Overwrite any default values with any values that have been explicitly written into the script
            if( command.count >= 3 ) {
                newAlignment = command.object(at: 2) as! NSString // Parameter 2; should be either "left", "center", or "right"
            }
            if( command.count >= 4 ) {
                duration = command.object(at: 3) as! NSString // Optional, default value is 0.5
            }
            
            type = VNScriptCommandAlignSprite as NSNumber
            let durationToUse:NSNumber = NSNumber(value: duration.doubleValue) // Convert to NSNumber
            analyzedArray = NSArray(objects: type, parameter1, newAlignment, durationToUse)
            
        } else if action.caseInsensitiveCompare(VNScriptStringRemoveSprite) == ComparisonResult.orderedSame {
        
            // Function definition
            //
            //  Name: .REMOVESPRITE
            //
            //  Removes a sprite from the screen, assuming that it's part of the VN system's dictionary of
            //  existing sprite objects.
            //
            //  Parameters:
            //
            //      #1: Name of sprite (string) (example: "girl.png")
            //          This is the name of the sprite to manipulate/align. All sprites currently displayed by the
            //          VN system are kept track of in the scene, so if the sprite exists onscreen, it'll be found.
            //
            //      #2: (OPTIONAL) Sprite appears at once (Boolean value) (example: "NO") (Default is NO)
            //          Determines whether the sprite disappears from the screen instantly or fades out gradually.
            //
            //  Example: .removesprite:girl.png:NO
            //
            
            
            var parameter2:NSString = NSString(string: "NO") // Default value
            
            if( command.count > 2 ) {
                parameter2 = command.object(at: 2) as! NSString // Overwrite default value with user-defined one, if it exists
            }
            
            // Convert to Boolean NSNumber object
            let vanishAtOnce:Bool = parameter2.boolValue
            let vanishParameter:NSNumber = NSNumber(value: vanishAtOnce)
            
            // Example: .removesprite:bob:NO
            type = VNScriptCommandRemoveSprite as NSNumber
            analyzedArray = NSArray(objects: type, parameter1, vanishParameter)
            
        } else if action.caseInsensitiveCompare(VNScriptStringEffectMoveSprite) == ComparisonResult.orderedSame {
        
            // Function definition
            //
            //  Name: .MOVESPRITE
            //
            //  Uses Cocos2D actions to move a sprite by a certain number of points.
            //
            //  Parameters:
            //
            //   (note that all parameters after the first are TECHNICALLY optional, but if you use one,
            //    you had better call the ones that come before it!)
            //
            //      #1: The name of the sprite to move (string) (example: "girl.png")
            //
            //      #2: Amount to move sprite by X points (float) (example: 128) (default is ZERO)
            //
            //      #3: Amount to move the sprite by Y points (float) (example: 256) (default is ZERO)
            //
            //      #4: Duration in seconds (float) (example: 0.5) (default is 0.5 seconds)
            //          This measures how long it takes to move the sprite, in seconds.
            //
            //  Example: .movesprite:girl.png:128:-128:1.0
            //
            
            // Set default values for extra parameters
            var xParameter:NSString         = NSString(string: "0")
            var yParameter:NSString         = NSString(string: "0")
            var durationParameter:NSString  = NSString(string: "0.5")
            
            // Overwrite default values with ones that exist in the script (assuming they exist, of course)
            if( command.count > 2 ) { xParameter = command.object(at: 2) as! NSString; }
            if( command.count > 3 ) { yParameter = command.object(at: 3) as! NSString; }
            if( command.count > 4 ) { durationParameter = command.object(at: 4) as! NSString; }
            
            // Convert parameters (which are NSStrings) to NSNumber values
            let moveByX:NSNumber = NSNumber(value: xParameter.floatValue);
            let moveByY:NSNumber = NSNumber(value: yParameter.floatValue);
            let duration:NSNumber = NSNumber(value: durationParameter.doubleValue);
            
            // syntax = command:sprite:xcoord:ycoord:duration
            type = VNScriptCommandEffectMoveSprite as NSNumber
            analyzedArray = NSArray(objects: type, parameter1, moveByX, moveByY, duration)
            
        } else if action.caseInsensitiveCompare(VNScriptStringEffectMoveBackground) == ComparisonResult.orderedSame {
        
            // Function definition
            //
            //  Name: .MOVEBACKGROUND
            //
            //  Uses Cocos2D actions to move the background by a certain number of points. This is normally used to
            //  pan the background (along the X-axis), but you can move the background up and down as well. Character
            //  sprites can also be moved along with the background, though usually at a slightly different rate;
            //  the rate is referred to as the "parallax factor." A parallax factor of 1.0 means that the character
            //  sprites move just as quickly as the background does, while a factor 0.0 means that the character
            //  sprites do not move at all.
            //
            //  Parameters:
            //
            //      #1: Amount to move sprite by X points (float) (example: 128) (default is ZERO)
            //
            //      #2: Amount to move the sprite by Y points (float) (OPTIONAL) (example: 256) (default is ZERO)
            //
            //      #3: Duration in seconds (float) (OPTIONAL) (example: 0.5) (default is 0.5 seconds)
            //          This measures how long it takes to move the sprite, in seconds.
            //
            //      #4: Parallax factor (float) (OPTIONAL) (example: 0.5) (default is 0.95)
            //          The rate at which sprites move compared to the background. 1.00 means that the
            //          sprites move at exactly the same rate as the background, while 0.00 means that
            //          the sprites do not move at all. You'll probably want to set it something in between.
            //
            //  Example: .movebackground:100:0:1.0
            //
            
            /*var xParameter = NSString(string: "0")
            var yParameter = NSString(string: "0")
            var durationParameter = NSString(string: "0.5")
            var parallaxFactor = NSString(string: "0.95")
            
            if( command.count > 1 ) {
                xParameter = command.objectAtIndex(1) as NSString
            }
            if( command.count > 2 ) {
                yParameter = command.objectAtIndex(2) as NSString
            }
            if( command.count > 3 ) {
                durationParameter = command.objectAtIndex(3) as NSString
            }
            if( command.count > 4 ) {
                parallaxFactor = command.objectAtIndex(4) as NSString
            }
            
            // Convert to NSNumber
            var moveByX = NSNumber(float: xParameter.floatValue)
            var moveByY = NSNumber(float: yParameter.floatValue)
            var duration = NSNumber(double: durationParameter.doubleValue)
            var parallaxing = NSNumber(float: parallaxFactor.floatValue)
            
            // Load to array
            type = VNScriptCommandEffectMoveBackground
            analyzedArray = NSArray(objects: type, moveByX, moveByY, duration, parallaxing)*/
            
            
            // Set default values for extra parameters
            var xParameter:NSString         = NSString(string: "0")
            var yParameter:NSString         = NSString(string: "0")
            var durationParameter:NSString  = NSString(string: "0.5")
            var parallaxFactor:NSString     = NSString(string: "0.95")
            
            // Overwrite default values with ones that exist in the script (assuming they exist, of course)
            if( command.count > 1 ) { xParameter        = command.object(at: 1) as! NSString; }
            if( command.count > 2 ) { yParameter        = command.object(at: 2) as! NSString; }
            if( command.count > 3 ) { durationParameter = command.object(at: 3) as! NSString; }
            if( command.count > 4 ) { parallaxFactor    = command.object(at: 4) as! NSString; }
            
            // Convert parameters (which are NSStrings) to NSNumber values
            let moveByX:NSNumber        = NSNumber(value: xParameter.floatValue);
            let moveByY:NSNumber        = NSNumber(value: yParameter.floatValue);
            let duration:NSNumber       = NSNumber(value: durationParameter.doubleValue);
            let parallaxing:NSNumber    = NSNumber(value: parallaxFactor.floatValue);
            
            // syntax = command:xcoord:ycoord:duration:parallaxing
            type = VNScriptCommandEffectMoveBackground as NSNumber
            analyzedArray = NSArray(objects: type, moveByX, moveByY, duration, parallaxing);
            
        } else if action.caseInsensitiveCompare(VNScriptStringSetSpritePosition) == ComparisonResult.orderedSame {
        
            // Function definition
            //
            //  Name: .SETSPRITEPOSITION
            //
            //  NOTE that unlike .MOVESPRITE, this call is instantaneous. I don't remember why I made it that
            //  way (probably since sprites usually don't move instantly in most visual novels), but it's probably
            //  best to keep things simple like that anyways.
            //
            //  Parameters:
            //
            //      #1: The name of the sprite (string) (example: "girl.png")
            //
            //      #2: The sprite's X coordinate, in points (float) (example: 10)
            //
            //      #3: The sprite's Y coordinate, in points (float) (example: 10)
            //
            //  Example: .setspriteposition:girl.png:100:100
            //
            
            
            var xParameter:NSString = NSString(string: "0");
            var yParameter:NSString = NSString(string: "0");
            
            if( command.count > 2 ) { xParameter = command.object(at: 2) as! NSString }
            if( command.count > 3 ) { yParameter = command.object(at: 3) as! NSString }
            
            let coordinateX:NSNumber = NSNumber(value: xParameter.floatValue);
            let coordinateY:NSNumber = NSNumber(value: yParameter.floatValue);
            
            type = VNScriptCommandSetSpritePosition as NSNumber
            analyzedArray = NSArray(objects: type, parameter1, coordinateX, coordinateY)
            
        } else if action.caseInsensitiveCompare(VNScriptStringSetBackground) == ComparisonResult.orderedSame {
        
            // Function definition
            //
            //  Name: .SETBACKGROUND
            //
            //  Changes whatever image (if any) is used as the background. You can set this to 'nil' which removes
            //  the background entirely, and shows whatever is behind. This is useful if you're overlaying the VN
            //  scene over an existing Cocos2D layer/scene node.
            //
            //  Unlike some of the other image-switching commands, this one is supposed to do the change instantly.
            //  It might be helpful to fade-out and then fade-in the scene during transistions so that the background
            //  change isn't too jarring for the person playing the game.
            //
            //  Parameters:
            //
            //      #1: The name of the background image (string) (example: "beach.png")
            //
            //  Example: .setbackground:beach.png
            
            //type = @VNScriptCommandSetBackground;
            //analyzedArray = @[type, parameter1];
            type = VNScriptCommandSetBackground as NSNumber
            analyzedArray = NSArray(objects: type, parameter1)
            
        //} else if ( [action caseInsensitiveCompare:VNScriptStringSetSpeaker] == NSOrderedSame ) {
        } else if action.caseInsensitiveCompare(VNScriptStringSetSpeaker) == ComparisonResult.orderedSame {
        
            // Function definition
            //
            //  Name: .SETSPEAKER
            //
            //  The "speaker name" is the title of the person speaking. If you set this to "nil" then it
            //  removes whatever the previous speaker name was.
            //
            //  Parameters:
            //
            //      #1: The name of the character speaking (string) (example: "Harry Potter")
            //
            //  Example: .setspeaker:John Smith
            //
            
            //type = @VNScriptCommandSetSpeaker;
            //analyzedArray = @[type, parameter1];
            type = VNScriptCommandSetSpeaker as NSNumber
            analyzedArray = NSArray(objects: type, parameter1)
            
        //} else if ( [action caseInsensitiveCompare:VNScriptStringChangeConversation] == NSOrderedSame ) {
        } else if action.caseInsensitiveCompare(VNScriptStringChangeConversation) == ComparisonResult.orderedSame {
        
            // Function definition
            //
            //  Name: .SETCONVERSATION
            //
            //  This jumps to a new conversation. The beginning conversation name is "start" and the other
            //  arrays in the script's Property List represent other conversations.
            //
            //  Parameters:
            //
            //      #1: The name of the conversation/array to switch to (string) (example: "flirt sequence")
            //
            //  Example: .setconversation:flirt sequence
            //
            
            //type = @VNScriptCommandChangeConversation;
            //analyzedArray = @[type, parameter1];
            type = VNScriptCommandChangeConversation as NSNumber
            analyzedArray = NSArray(objects: type, parameter1)
            
        //} else if ( [action caseInsensitiveCompare:VNScriptStringJumpOnChoice] == NSOrderedSame ) {
        } else if action.caseInsensitiveCompare(VNScriptStringJumpOnChoice) == ComparisonResult.orderedSame {
        
            // Function definition
            //
            //  Name: .JUMPONCHOICE
            //
            //  This presents the player with multiple choices. Each choice causes the scene to jump to a different
            //  "conversation" (or rather, an array in the script dictionary). The function can have multipe parameters,
            //  but the number should always be even-numbered.
            //
            //  Parameters:
            //
            //      #1: The name of the first action (shows up on button when player decides) (string) (example: "Run away")
            //
            //      #2: The name of the conversation to jump to (string) (example: "fleeing sequence")
            //
            //      ...these variables can be repeated multiple times.
            //
            //  Example: .JUMPONCHOICE:"Hug someone":hug sequence:"Glomp someone":glomp sequence
            //
            
            /*
            var numberOfChoices = (command.count - 1) / 2
            
            // Check if there's not enough data
            if numberOfChoices < 1 || command.count < 3 {
                return nil
            }
            
            var choiceText = NSMutableArray(capacity: numberOfChoices)
            var destinations = NSMutableArray(capacity: numberOfChoices)
            
            for var i = 0; i < numberOfChoices; i++ {
                var indexOfChoice = 1 + (2 * i)
                
                choiceText.addObject(command.objectAtIndex(indexOfChoice))
                destinations.addObject(command.objectAtIndex(indexOfChoice+1))
            }
            
            type = VNScriptCommandJumpOnChoice
            analyzedArray = NSArray(objects: type, choiceText, destinations)*/
            
            
            // Figure out how many choices there are
            let numberOfChoices:Int = (command.count - 1) / 2;
            
            // Check if there's not enough data
            if( numberOfChoices < 1 || command.count < 3 ) {
                return nil;
            }
            
            // Create some arrays; one will hold the text that appears to the player, while the other will hold
            // the names of the conversations/arrays that the script will switch to depending on the player's choice.
            let choiceText:NSMutableArray   = NSMutableArray(capacity: numberOfChoices)
            let destinations:NSMutableArray = NSMutableArray(capacity: numberOfChoices)
            
            // After determining the number of choices that exist, use a loop to match each choice text with the
            // name of the conversation that each choice would correspond to. Then add both to the appropriate arrays.
            for i in 0 ..< numberOfChoices { //for( int i = 0; i < numberOfChoices; i++ ) {
                
                // This variable will hold 1 and then every odd number after. It starts at one because index "zero"
                // is where the actual .JUMPONCHOICE string is stored.
                let indexOfChoice = 1 + (2 * i);
                
                // Add choice data to the two separate arrays
                choiceText.add( command.object(at: indexOfChoice) )//[choiceText addObject:[command objectAtIndex:indexOfChoice]];
                destinations.add( command.object(at: indexOfChoice+1) )
            }
            
            type = VNScriptCommandJumpOnChoice as NSNumber
            analyzedArray = NSArray(objects: type, choiceText, destinations)
            
        } else if action.caseInsensitiveCompare(VNScriptStringShowSpeechOrNot) == ComparisonResult.orderedSame {
        
            // Function definition
            //
            //  Name: .SHOWSPEECH
            //
            //  Determines whether or not to show the speech (and accompanying speech-box or speech-area). You
            //  can set it to NO if you don't want any text to show up.
            //
            //  Parameters:
            //
            //      #1: Whether or not to show the speech box (Boolean)
            //
            //  Example: .SHOWSPEECH:NO
            //
            
            // Convert parameter from NSString to a Boolean NSNumber
            /*BOOL showParameter = [parameter1 boolValue];
            NSNumber* parameterObject = @(showParameter);
            
            type = @VNScriptCommandShowSpeechOrNot;
            analyzedArray = @[type, parameterObject];*/
            
            let parameterObject = NSNumber(value: parameter1.boolValue)

            type = VNScriptCommandShowSpeechOrNot as NSNumber
            analyzedArray = NSArray(objects: type, parameterObject)
            
        } else if action.caseInsensitiveCompare(VNScriptStringEffectFadeIn) == ComparisonResult.orderedSame {
        
            // Function definition
            //
            //  Name: .FADEIN
            //
            //  Uses Cocos2D to fade-out the VN scene's backgrounds and sprites... and nothing else (UI
            //  elements like speech text are unaffected).
            //
            //  Parameters:
            //
            //      #1: Duration of fade-in sequence, in seconds (double)
            //
            //  Example: .FADEIN:0.5
            //
            
            /*
            // Convert from NSString to NSNumber
            double fadeDuration = [parameter1 doubleValue]; // NSString gets converted to a 'double' by this
            NSNumber* durationObject = @(fadeDuration);
            
            type = @VNScriptCommandEffectFadeIn;
            analyzedArray = @[type, durationObject];*/
            
            let durationObject  = NSNumber(value: parameter1.doubleValue)
            type                = VNScriptCommandEffectFadeIn as NSNumber
            analyzedArray       = NSArray(objects: type, durationObject)
            
        } else if action.caseInsensitiveCompare(VNScriptStringEffectFadeOut) == ComparisonResult.orderedSame {
        
            // Function definition
            //
            //  Name: .FADEOUT
            //
            //  Uses Cocos2D to fade-out the VN scene's backgrounds and sprites... and nothing else (UI
            //  elements like speech text are unaffected).
            //
            //  Parameters:
            //
            //      #1: Duration of fade-out sequence, in seconds (double)
            //
            //  Example: .FADEOUT:1.0
            //
            
            /*
            double fadeDuration = [parameter1 doubleValue];
            NSNumber* durationObject = @(fadeDuration);
            
            type = @VNScriptCommandEffectFadeOut;
            analyzedArray = @[type, durationObject];*/
            
            let durationObject  = NSNumber(value: parameter1.doubleValue)
            type                = VNScriptCommandEffectFadeOut as NSNumber
            analyzedArray       = NSArray(objects: type, durationObject)
            
        } else if action.caseInsensitiveCompare(VNScriptStringPlaySound) == ComparisonResult.orderedSame {
        
            // Function definition
            //
            //  Name: .PLAYSOUND
            //
            //  Plays a sound (any type of sound file supported by Cocos2D/SimpleAudioEngine)
            //
            //  Parameters:
            //
            //      #1: name of sound file (string)
            //
            //  Example: .PLAYSOUND:effect1.caf
            //
            
            //type = @VNScriptCommandPlaySound;
            //analyzedArray = @[type, parameter1];
            type = VNScriptCommandPlaySound as NSNumber
            analyzedArray = NSArray(objects: type, parameter1)
            
        } else if action.caseInsensitiveCompare(VNScriptStringPlayMusic) == ComparisonResult.orderedSame {
        
            // Function definition
            //
            //  Name: .PLAYMUSIC
            //
            //  Plays background music. May or may not loop. You can also stop any background music
            //  by calling this with the parameter set to "nil"
            //
            //  Parameters:
            //
            //      #1: name of music filename (string)
            //          (you can write "nil" to stop all the music)
            //
            //      #2: (Optional) Should this loop forever? (BOOL value) (default is YES)
            //
            //  Example: .PLAYMUSIC:LevelUpper.mp3:NO
            //
            
            
            var parameter2:NSString = NSString(string: "YES") // Loops forever by default
            
            // Check if there's already a user-specified value, in which case that would override the default value
            if( command.count > 2 ) {
                parameter2 = command.object(at: 2) as! NSString
            }
            
            // Convert the second parameter to a Boolean NSNumber, since it was originally stored as a string
            let musicLoopsForever:Bool = parameter2.boolValue
            let loopParameter:NSNumber = NSNumber(value: musicLoopsForever)
            
            type = VNScriptCommandPlayMusic as NSNumber
            analyzedArray = NSArray(objects: type, parameter1, loopParameter)

        } else if action.caseInsensitiveCompare(VNScriptStringSetFlag) == ComparisonResult.orderedSame {
        
            // Function definition
            //
            //  Name: .SETFLAG
            //
            //  Used to manually set a "flag" value in the VN system.
            //
            //  Parameters:
            //
            //      #1: Name of flag (string)
            //
            //      #2: The value to set the flag to (integer)
            //
            //  Example: .SETFLAG:number of friends:12
            //
            
            var parameter2:NSString = NSString(string: "0") // Default value
            
            if( command.count > 2 ) {
                parameter2 = command.object(at: 2) as! NSString
            }
            
            // Convert the second parameter to an NSNumber (it was originally an NSString)
            let value:NSNumber = NSNumber(value: parameter2.integerValue)
            
            type = VNScriptCommandSetFlag as NSNumber
            analyzedArray = NSArray(objects: type, parameter1, value)
            
        } else if action.caseInsensitiveCompare(VNScriptStringModifyFlagValue) == ComparisonResult.orderedSame {
        
            // Function definition
            //
            //  Name: .MODIFYFLAG
            //
            //  Modifies a flag (which stores a numeric, integer value) by another integer. The catch is,
            //  the modifying value has to be a "literal" number value, and not another flag/variable.
            //
            //  Parameters:
            //
            //      #1: Name of the flag/variable to modify (string)
            //
            //      #2: The number to modify the flag by (integer)
            //
            //  Example: .MODIFYFLAG:number of friends:1
            //
            
            var parameter2 = NSString(string: "0")
            
            if( command.count > 2 ) {
                parameter2 = command.object(at: 2) as! NSString
            }
            
            let modifyWithValue = NSNumber(value: parameter2.integerValue) // Converts from string to integer NSNumber
            
            type = VNScriptCommandModifyFlagValue as NSNumber
            analyzedArray = NSArray(objects: type, parameter1, modifyWithValue)
            
        } else if action.caseInsensitiveCompare(VNScriptStringIfFlagHasValue) == ComparisonResult.orderedSame {
        
            // Function definition
            //
            //  Name: .ISFLAG
            //
            //  Checks if a flag matches a certain value. If it does, then it immediately runs another command.
            //  In theory, you could probably even nest .ISFLAG commands inside each other, but I've never tried
            //  this before.
            //
            //  Parameters:
            //
            //      #1: Name of flag (string)
            //
            //      #2: Expected value (integer)
            //
            //      #3: Another command
            //
            //  Example: .ISFLAG:number of friends:1:.SETSPEAKER:That One Friend You Have
            //
            
            if( command.count < 4 ) {
                return nil;
            }
            
            let variableName:NSString?  = command.object(at: 1) as? NSString
            let expectedValue:NSString? = command.object(at: 2) as? NSString
            let extraCount:Int          = command.count - 3; // This number = secondary command + secondary command's parameters
            
            if( variableName == nil || expectedValue == nil ) {
                print("[VNScript] ERROR: Invalid variable name or value in .ISFLAG command");
                return nil;
            }
            
            // Convert to numerical types
            let expectedValueAsNumber = NSNumber(value: expectedValue!.integerValue)
            
            // Now, here comes the hard part... the 3rd "parameter" (and all that follows) is actually a separate
            // command that will get executed IF the variable contains the expected value. At this point, it's necessary to
            // translate that extra command so it can be more easily run when the actual script gets run for real.
            let extraCommand:NSMutableArray = NSMutableArray(capacity: extraCount)
            
            // This loop starts at the command index where the "secondary command" is and then goes through each
            // parameter of the second command.
            for i in 3 ..< command.count  {
                
                // Extract the secondary/"extra" command and put it in its own array
                let partOfCommand:NSString = command.object(at: i) as! NSString // 3rd parameter and everything afterwards
                extraCommand.add(partOfCommand) // Add that new data to the "extra command" array
            }
            
            // Try to make sense of that secondary command... if it doesn't work out, then just give up on translating this line
            let secondaryCommand:NSArray? = analyzedCommand(extraCommand)
            if( secondaryCommand == nil ) {
                print("[VNScript] ERROR: Could not translate secondary command of .ISFLAG");
                return nil;
            }
            
            type = VNScriptCommandIfFlagHasValue as NSNumber
            //analyzedArray = NSArray(objects: type, variableName!, expectedValue!, secondaryCommand!)
            analyzedArray = NSArray(objects: type, variableName!, expectedValueAsNumber, secondaryCommand!)
            
        } else if action.caseInsensitiveCompare(VNScriptStringIsFlagMoreThan) == ComparisonResult.orderedSame {
        
            // Function definition
            //
            //  Name: .ISFLAGMORETHAN
            //
            //  Checks if a flag's value is above a certain number. If it is, then a secondary command is run.
            //
            //  Parameters:
            //
            //      #1: Name of flag (string)
            //
            //      #2: Certain number (integer)
            //
            //      #3: Another command
            //
            //  Example: .ISFLAGMORETHAN:power level:9000:.PLAYSOUND:over nine thousand.mp3
            //
            
            
            if( command.count < 4 ) {
                return nil;
            }
            
            let variableName:NSString? = command.object(at: 1) as? NSString
            let expectedValue:NSString? = command.object(at: 2) as? NSString
            let extraCount = command.count - 3; // This number = secondary command + secondary command's parameters
            
            if( variableName == nil || expectedValue == nil ) {
                print("[VNScript] ERROR: Invalid variable name or value in .ISFLAGMORETHAN command");
                return nil;
            }
            
            let extraCommand:NSMutableArray = NSMutableArray(capacity: extraCount)
            
            for i in 3 ..< command.count  {
                let partOfCommand:NSString = command.object(at: i) as! NSString
                extraCommand.add(partOfCommand)
            }
            
            let secondaryCommand:NSArray? = analyzedCommand(extraCommand)
            if( secondaryCommand == nil ) {
                print("[VNScript] ERROR: Could not translate secondary command of .ISFLAGMORETHAN");
                return nil;
            }
            
            // Convert to numerical types
            let expectedValueAsNumber = NSNumber(value: expectedValue!.integerValue)
            
            type = VNScriptCommandIsFlagMoreThan as NSNumber
            //analyzedArray = NSArray(objects: type, variableName!, expectedValue!, secondaryCommand!)
            analyzedArray = NSArray(objects: type, variableName!, expectedValueAsNumber, secondaryCommand!)
            
        } else if action.caseInsensitiveCompare(VNScriptStringIsFlagLessThan) == ComparisonResult.orderedSame {
        
            // Function definition
            //
            //  Name: .ISFLAGLESSTHAN
            //
            //  Checks if a flag's value is below a certain number. If it is, then a secondary command is run.
            //
            //  Parameters:
            //
            //      #1: Name of flag (string)
            //
            //      #2: Certain number (integer)
            //
            //      #3: Another command
            //
            //  Example: .ISFLAGLESSTHAN:time remaining:0:.PLAYMUSIC:time's up.mp3
            //
            
            if( command.count < 4 ) {
                return nil;
            }
            
            let variableName:NSString?  = command.object(at: 1) as? NSString
            let expectedValue:NSString? = command.object(at: 2) as? NSString
            let extraCount              = command.count - 3; // This number = secondary command + secondary command's parameters
            
            if( variableName == nil || expectedValue == nil ) {
                print("[VNScript] ERROR: Invalid variable name or value in .ISFLAGLESSTHAN command");
                return nil;
            }
            
            let extraCommand:NSMutableArray = NSMutableArray(capacity: extraCount)
            
            for i in 3 ..< command.count  {
                
                let partOfCommand:NSString = command.object(at: i) as! NSString
                extraCommand.add(partOfCommand)
            }
            
            let secondaryCommand:NSArray? = analyzedCommand(extraCommand)
            if( secondaryCommand == nil ) {
                print("[VNScript] ERROR: Could not translate secondary command of .ISFLAGLESSTHAN");
                return nil;
            }
            
            let expectedValueAsNumber = NSNumber(value: expectedValue!.integerValue)
            type = VNScriptCommandIsFlagLessThan as NSNumber
            //analyzedArray = NSArray(objects: type, variableName!, expectedValue!, secondaryCommand!)
            analyzedArray = NSArray(objects: type, variableName!, expectedValueAsNumber, secondaryCommand!)
            
        } else if action.caseInsensitiveCompare(VNScriptStringIsFlagBetween) == ComparisonResult.orderedSame {
        
            // Function definition
            //
            //  Name: .ISFLAGBETWEEN
            //
            //  Checks if a flag's value is between two numbers, and if it is, this will run another command.
            //
            //  Parameters:
            //
            //      #1: Name of flag (string)
            //
            //      #2: First number (integer)
            //
            //      #3: Second number (integer)
            //
            //      #4: Another command
            //
            //  Example: .ISFLAGBETWEEN:number of cookies:1:3:YOU HAVE EXACTLY TWO COOKIES!
            //
            
            if( command.count < 5 ) {
                return nil;
            }
            
            let variableName:NSString?  = command.object(at: 1) as? NSString
            let firstValue:NSString?    = command.object(at: 2) as? NSString
            let secondValue:NSString?   = command.object(at: 3) as? NSString
            let extraCount              = command.count - 4; // This number = secondary command + secondary command's parameters
            
            if( variableName == nil || firstValue == nil || secondValue == nil ) {
                print("[VNScript] ERROR: Invalid variable name or value in .ISFLAGBETWEEN command");
                return nil;
            }
            
            // Figure out which value is the lesser value, and which one is the greater value. By default,
            // it's assumed first value is the "lesser" value, and the second ond is the "greater" one
            let first:Int           = firstValue!.integerValue
            let second:Int          = secondValue!.integerValue
            var lesserValue:Int     = first
            var greaterValue:Int    = second
            
            // Check if the default value assignment is wrong. In this case, the second value is the lesser one,
            // and that the first value is the greater one.
            if( first > second ) {
                // Reassign the values appropriately
                greaterValue = first;
                lesserValue = second;
            }
            
            let extraCommand:NSMutableArray = NSMutableArray(capacity: extraCount)
            
            for i in 4 ..< command.count  {
                let partOfCommand:NSString = command.object(at: i) as! NSString
                extraCommand.add(partOfCommand)
            }
            
            let secondaryCommand:NSArray? = analyzedCommand(extraCommand)
            if( secondaryCommand == nil ) {
                print("[VNScript] ERROR: Could not translate secondary command of .ISFLAGBETWEEN");
                return nil;
            }
            
            // Convert greater/lesser scalar values back into NSString format for the script
            //var lesserValueString:NSString  = NSString(string: "\(lesserValue)")    //[NSString stringWithFormat:@"%d", lesserValue];
            //var greaterValueString:NSString = NSString(string: "\(greaterValue)")   //[NSString stringWithFormat:@"%d", greaterValue];
            
            let lesserValueNumber = NSNumber(value: lesserValue)
            let greaterValueNumber = NSNumber(value: greaterValue)
            
            type = VNScriptCommandIsFlagBetween as NSNumber
            //analyzedArray = NSArray(objects: type, variableName!, lesserValueString, greaterValueString, secondaryCommand!)
            analyzedArray = NSArray(objects: type, variableName!, lesserValueNumber, greaterValueNumber, secondaryCommand!)
            
        } else if action.caseInsensitiveCompare(VNScriptStringModifyFlagOnChoice) == ComparisonResult.orderedSame {
        
            // Function definition
            //
            //  Name: .MODIFYFLAGBYCHOICE
            //
            //  This presents a choice menu. Each choice causes a particular flag/variable to be changed
            //  by a particular integer value.
            //
            //  Parameters:
            //
            //      #1: The text that will appear on the choice (string)
            //
            //      #2: The name of the flag/variable to be modified (string)
            //
            //      #3: The amount to modify the flag/variable by (integer)
            //
            //      ...these variables can be repeated multiple times.
            //
            //  Example: .MODIFYFLAGBYCHOICE:"Be nice":niceness:1:"Be rude":niceness:-1
            //
            
            
            // Since the first item in the command array is the ".MODIFYFLAG" string, we'll just ignore that first index
            // when counting the number of choices. Also, since each set of parameters consists of three parts (choice text,
            // variable name, and variable value), the number will be divided by three to get the actual number of choices.
            let numberOfChoices = (command.count - 1) / 3;
            
            // Create some empty mutable arrays
            let choiceText:NSMutableArray       = NSMutableArray(capacity: numberOfChoices) //[[NSMutableArray alloc] initWithCapacity:numberOfChoices];
            let variableNames:NSMutableArray    = NSMutableArray(capacity: numberOfChoices) //[[NSMutableArray alloc] initWithCapacity:numberOfChoices];
            let variableValues:NSMutableArray   = NSMutableArray(capacity: numberOfChoices) //[[NSMutableArray alloc] initWithCapacity:numberOfChoices];
            
            for i in 0 ..< numberOfChoices  {
                
                // This is used as an offset in order to get the right index numbers for the 'command' array.
                // It starts at 1 and then jumps to every third number thereafter (from 1 to 4, 7, 10, 13, etc).
                let nameIndex = 1 + (i * 3);
                
                // Get the parameters for the command array
                let text:NSString   = command.object(at: nameIndex) as! NSString // Text to show to player
                let name:NSString   = command.object(at: nameIndex+1) as! NSString // The name of the flag to modify
                let check:NSString  = command.object(at: nameIndex+2) as! NSString // The amount to modify the flag by
                
                let convertedToNumber = NSNumber(value: check.integerValue)
                
                // Move each value to the appropriate array
                choiceText.add(text)
                variableNames.add(name)
                //variableValues.addObject(check)
                variableValues.add(convertedToNumber)
            }
            
            type = VNScriptCommandModifyFlagOnChoice as NSNumber
            analyzedArray = NSArray(objects: type, choiceText, variableNames, variableValues)
            
        } else if action.caseInsensitiveCompare(VNScriptStringJumpOnFlag) == ComparisonResult.orderedSame {
        
            // Function definition
            //
            //  Name: .JUMPONFLAG
            //
            //  If a particular flag has a particular value, then this command will jump to a different
            //  conversation/dialogue-sequence in the script.
            //
            //  Parameters:
            //
            //      #1: The name of the flag to be checked (string)
            //
            //      #2: The expected value of the flag (integer)
            //
            //      #3: The scene to jump to, if the flag's vaue matches the expected value in parameter #2 (string)
            //
            //  Example: .JUMPONFLAG:should jump to beach scene:1:BeachScene
            //
            
            if command.count < 4 {
                return nil
            }
            
            let variableName:NSString?   = command.object(at: 1) as? NSString //[command objectAtIndex:1];
            let expectedValue:NSString?  = command.object(at: 2) as? NSString //[command objectAtIndex:2];
            let newLocation:NSString?    = command.object(at: 3) as? NSString //[command objectAtIndex:3];
            
            if( variableName == nil || expectedValue == nil || newLocation == nil ) {
                print("[VNScript] ERROR: Invalid parameters passed to .JUMPONFLAG command.");
                return nil;
            }
            
            let expectedValueAsNumber = NSNumber(value: expectedValue!.integerValue)
            type = VNScriptCommandJumpOnFlag as NSNumber
            //analyzedArray = NSArray(objects: type, variableName!, expectedValue!, newLocation!)
            analyzedArray = NSArray(objects: type, variableName!, expectedValueAsNumber, newLocation!)
            
        } else if action.caseInsensitiveCompare(VNScriptStringSystemCall) == ComparisonResult.orderedSame {
            
            // Function definition
            //
            //  Name: .SYSTEMCALL
            //
            //  Used to do a "system call," which is usually game-specific. This command will try to contact the
            //  VNSystemCall class, and use it to perform some kind of particular task. Some examples of this would
            //  be starting a mini-game or some other activity that's specific to a particular app.
            //
            //  Parameters:
            //
            //      #1: The "call string" or a string that described what the activity/system-call type will be (string)
            //
            //      #2: (OPTIONAL) The first parameter to pass in to the system call (string?)
            //
            //      ...more parameters can be passed in as necessary
            //
            //  Example: .SYSTEMCALL:start-bullet-hell-minigame:BulletHellLevel01
            //
            
            if( command.count < 1 ) {
                return nil;
            }
            
            let callString:NSString = command.object(at: 1) as! NSString // Extract the call string
            
            //NSMutableArray* extraParameters = [NSMutableArray arrayWithArray:command];
            let extraParameters:NSMutableArray = NSMutableArray(array: command)
            extraParameters.removeObject(at: 1) // Remove call type
            extraParameters.removeObject(at: 0)  // Remove command
            
            // Add a dummy parameter just for the heck of it
            if( extraParameters.count < 1 ) {
                //[extraParameters addObject:@"nil"];
                extraParameters.add(NSString(string: "nil"))
            }
            
            type = VNScriptCommandSystemCall as NSNumber
            analyzedArray = NSArray(objects: type, callString, extraParameters)
            
        } else if action.caseInsensitiveCompare(VNScriptStringCallCode) == ComparisonResult.orderedSame {
            
            // Function definition
            //
            //  Name: .CALLCODE
            //
            //  This action can be used to call functions (usually from static objects). Careful when using it to
            //  call classes or functions that the VN system doesn't have access to! You may need to include header
            //  files from certain places if you really want to use certain classes.
            //
            //  Parameters:
            //
            //      #1: The name of the class to call (string)
            //
            //      #2: The name of a static function to call (string)
            //
            //		#3: (OPTIONAL) The name of another function, PRESUMABLY a function that belongs to the class
            //			instance that was returned by the function called in #2 (string)
            //
            //		#4: (OPTIONAL) A parameter to pass into the function called in #3 (string?)
            //
            //  Example: .CALLCODE:EKRecord:sharedRecord:flagNamed:times played
            //
            
            if( command.count < 3 ) {
                return nil;
            }
            
            // At this point, you'll need an array that has all the things needed to call a particular class,
            // as well as class functions. The first string in the array will be the class, the second will be
            // a "shared object" static function, and if a third string exists, it will call a particular
            // function in that class. If there are any more strings, they will be parameters. For example:
            //
            //  callingArray[0] = EKRecord
            //  callingArray[1] = sharedRecord
            //  callingArray[2] = flagNamed
            //  callingArray[3] = times played
            //
            // ...which would come out something like --> [[EKRecord sharedRecord] flagNamed:@"times played"];
            //
            let callingArray:NSMutableArray = NSMutableArray(array: command)
            callingArray.removeObject(at: 0) // Removes the string ".callcode"
            
            type = VNScriptCommandCallCode as NSNumber
            analyzedArray = NSArray(objects: type, callingArray)
            
        } else if( action.caseInsensitiveCompare(VNScriptStringSwitchScript) == ComparisonResult.orderedSame ) {
            
            // Function definition
            //
            //  Name: .SWITCHSCRIPT
            //
            //  Replaces a scene's script with a script loaded from another .PLIST file. This is useful if you're
            //  using multiple .PLIST files.
            //
            //  Parameters:
            //
            //      #1: The name of the .PLIST file to load (string)
            //
            //      #2: (OPTIONAL) The name of the "conversation"/array to start at to (string) (default is "start")
            //
            //  Example: .SWITCHSCRIPT:script number 2:Some Random Event
            //
            
            if( command.count < 2 ) {
                return nil;
            }
            
            let scriptName:NSString?    = command.object(at: 1) as? NSString
            var startingPoint:NSString  = VNScriptStartingPoint as NSString; // Default value
            
            // Check if the script name is missing
            if( scriptName == nil ) {
                return nil;
            }
            
            // Load non-default starting point (if it exists)
            if( command.count > 2 ) {
                startingPoint = command.object(at: 2) as! NSString
            }
            
            type = VNScriptCommandSwitchScript as NSNumber
            analyzedArray = NSArray(objects: type, scriptName!, startingPoint)
            
        } else if( action.caseInsensitiveCompare(VNScriptStringSetSpeakerFont) == ComparisonResult.orderedSame ) {
            
            // Function definition
            //
            //  Name: .SETSPEAKERFONT
            //
            //  Replaces the current font used by the "speaker name" label with another font.
            //
            //  Parameters:
            //
            //      #1: The name of the font to use (string)
            //
            //  Example: .SETSPEAKERFONT:Helvetica
            //
            
            type = VNScriptCommandSetSpeakerFont as NSNumber
            analyzedArray = NSArray(objects: type, parameter1)
            
        } else if( action.caseInsensitiveCompare(VNScriptStringSetSpeakerFontSize) == ComparisonResult.orderedSame ) {
            
            // Function definition
            //
            //  Name: .SETSPEAKERFONTSIZE
            //
            //  Changes the font size used by the "speaker name" label.
            //
            //  Parameters:
            //
            //      #1: Font size (float)
            //
            //  Example: .SETSPEAKERFONTSIZE:17.0
            //
            
            //let sizeAsNumber = NSNumber( double: parameter1.doubleValue )
            
            type = VNScriptCommandSetSpeakerFontSize as NSNumber
            analyzedArray = NSArray(objects: type, parameter1)
            //analyzedArray = NSArray(objects: type, sizeAsNumber)
            
        } else if( action.caseInsensitiveCompare(VNScriptStringSetSpeechFont) == ComparisonResult.orderedSame ) {
            
            // Function definition
            //
            //  Name: .SETSPEECHFONT
            //
            //  Replaces the current font used by the speech/dialogue label with another font.
            //
            //  Parameters:
            //
            //      #1: The name of the font to use (string)
            //
            //  Example: .SETSPEECHFONT:Courier New
            //
            
            type = VNScriptCommandSetSpeechFont as NSNumber
            analyzedArray = NSArray(objects: type, parameter1)
            
        } else if( action.caseInsensitiveCompare(VNScriptStringSetSpeechFontSize) == ComparisonResult.orderedSame ) {
            
            // Function definition
            //
            //  Name: .SETSPEECHFONTSIZE
            //
            //  Changes the speech/dialogue font size.
            //
            //  Parameters:
            //
            //      #1: Font size (float)
            //
            //  Example: .SETSPEECHFONTSIZE:18.0
            //
            
            type = VNScriptCommandSetSpeechFontSize as NSNumber
            analyzedArray = NSArray(objects: type, parameter1)
            
        } else if action.caseInsensitiveCompare(VNScriptStringSetTypewriterText) == ComparisonResult.orderedSame {
            
            // Function definition
            //
            //  Name: .SETTYPEWRITERTEXT
            //
            //  Sets or disables "typewriter text" mode, in which each character of text/dialogue appears
            //  one at a time (though usually still very quickly).
            //
            //  Parameters:
            //
            //      #1: How many characters it should print per second (Integer)
            //          (setting this to zero disables typewriter text mode)
            //
            //      #2: Whether the user can still skip ahead by tapping the screen (BOOL) (default value is NO)
            //
            //  Example: .SETTYPEWRITERTEXT:30:NO
            //
            
            let defaultSkipString = NSString(string:"NO")
            
            let textSpeed = parameter1.integerValue
            let timeNumber = NSNumber(value: textSpeed)
            
            var canSkip = defaultSkipString.boolValue // use default value first
            if( command.count > 2 ) {
                let secondParameter = command.object(at: 2) as! NSString
                canSkip = secondParameter.boolValue // Use custom value if it exists
            }
        
            let skipNumber = NSNumber(value: canSkip)
            
            type = VNScriptCommandSetTypewriterText as NSNumber
            analyzedArray = NSArray(objects:type, timeNumber, skipNumber)
            
        } else if action.caseInsensitiveCompare(VNScriptStringSetSpriteAlias) == ComparisonResult.orderedSame {
            
            // Function definition
            //
            //  Name: .SETSPRITEALIAS
            //
            //  Assigns a filename to a particular sprite alias. Creates the that sprite alias if none exists.
            //
            //  Parameters:
            //
            //      #1: The sprite alias.
            //
            //      #2: The filename to use.
            //
            //  Example: .SETSPRITEALIAS:hero:harry.png
            //
            
            let aliasParameter = command.object(at: 1) as! NSString
            let filenameParameter = command.object(at: 2) as! NSString
            
            type = VNScriptCommandSetSpriteAlias as NSNumber
            //analyzedArray = @[type, aliasParameter, filenameParameter];
            analyzedArray = NSArray(objects: type, aliasParameter, filenameParameter)
            
        } else if action.caseInsensitiveCompare(VNScriptStringSetSpeechbox) == ComparisonResult.orderedSame {
            
            // Function definition
            //
            //  Name: .SETSPEECHBOX
            //
            //  Dynamically switches to a different speechbox sprite.
            //
            //  Parameters:
            //
            //      #1: Name of speechbox sprite to use (string)
            //
            //      #2: Duration of transition (in seconds) (default is 0, which is instant)
            //
            //  Example: .SETSPEECHBOX:alternate_box.png:1.0
            //
            
            // Set default values
            //NSString* duration = [NSString stringWithFormat:@"0"];
            var duration = NSString(string: "0")
            
            // Overwrite any default values with any values that have been explicitly written into the script
            if command.count >= 3 {
                duration = command.object(at: 2) as! NSString // optional, default value is zero
            }
            
            type = VNScriptCommandSetSpeechbox as NSNumber
            let durationToUse = NSNumber(value: duration.doubleValue)
            analyzedArray = NSArray(objects: type, parameter1, durationToUse)
            
        } else if( action.caseInsensitiveCompare(VNScriptStringFlipSprite) == ComparisonResult.orderedSame ) {
            
            // Function definition
            //
            //  Name: .FLIPSPRITE
            //
            //  Flips the sprite left/right or upside-down/right-side-up.
            //
            //  Parameters:
            //
            //      #1: Name of sprite
            //
            //      #2: Duration (in seconds). Duration of zero is instantaneous.
            //
            //      #3: Whether to flip horizontally or not (YES means horizontal flip, NO means vertical flip)
            //
            //  Example: .FLIPSPRITE:girl.png:0:YES
            //
            
            var duration = NSString(string: "0")
            var flipBool = NSString(string: "YES")
            
            // Set default values
            //NSString* duration = [NSString stringWithFormat:@"0"];
            //NSString* flipBool = [NSString stringWithFormat:@"YES"];
            
            // Overwrite any default values with any values that have been explicitly written into the script
            if command.count >= 3 {
                duration = command.object(at: 2) as! NSString
            }
            if command.count >= 4 {
                flipBool = command.object(at: 3) as! NSString
            }
            
            type = VNScriptCommandFlipSprite as NSNumber
            let durationToUse = NSNumber(value: duration.doubleValue)
            let numberForFlip = NSNumber(value: flipBool.boolValue)
            analyzedArray = NSArray(objects: type, parameter1, durationToUse, numberForFlip)
            
            //type = @VNScriptCommandFlipSprite;
            //NSNumber* durationToUse = @([duration doubleValue]);
            //NSNumber* numberForFlip = @(flipBool.boolValue);
            //analyzedArray = @[type, parameter1, durationToUse, numberForFlip];
        }
        
        return analyzedArray
    }
}
