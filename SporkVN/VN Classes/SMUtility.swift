//
//  SMUtility.swift
//
//  Created by James on 11/11/14.
//  Copyright (c) 2014 James Briones. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit
import AVFoundation

// This is just a whole bunch of helpful utility functions stored in one big class instead of in global functions... it's neater this way.
@MainActor
class SMUtility {
    
    @MainActor
    class Screen {
        // Fun fact: this uses the default size and width for an iPhone 4S in landscape mode. Considering this device is EXTREMELY outdated,
        // this means that these defaults really need to change... but I kept it because why not? The defaults should be overriden anyways.
        static var width  = CGFloat(480)
        static var height = CGFloat(320)
        
        // set screen size in points
        static func setSize( screenWidth:CGFloat, screenHeight:CGFloat ) {
            width = abs(screenWidth)
            height = abs(screenHeight)
            print("[SMUtility.Screen] - width: \(width) | height: \(height)")
            //dimensionsSet = true
        }
        
        // retrieve screen size in points
        static func sizeInPoints() -> CGSize {
            /*if dimensionsSet == false {
             print("[SMUtility.Screen] WARNING: Screen size has not been set properly; this function will return an unsure default value.");
             }*/
            return CGSize(width: width, height: height)
        }
        
        static func setSizeFromView(view:SKView) {
            let viewSize = view.frame.size
            width = viewSize.width
            height = viewSize.height
        }
    }
    
    @MainActor
    class Position {
        // returns a price x,y coordinate from normalized values (in which 0.5,0.5 would be the exact center of the screen)
        static func normalizedCoordinates( normalizedX:CGFloat, normalizedY:CGFloat) -> CGPoint {
            let screenSize = SMUtility.Screen.sizeInPoints()
            let x = normalizedX * screenSize.width
            let y = normalizedY * screenSize.height
            return CGPoint( x: x, y: y )
        }
        
        // just adds two positions together to get a third
        static func sumOfTwoPositions( first:CGPoint, second:CGPoint ) -> CGPoint {
            let x = first.x + second.x
            let y = first.y + second.y
            return CGPoint(x: x, y: y)
        }
        
        // Returns the position of the bottom-left corner of an SKNode object
        static func bottomLeftCornerOfSKNode( node:SKNode ) -> CGPoint {
            let widthOfNode = node.frame.size.width
            let heightOfNode = node.frame.size.height
            let x = (widthOfNode * (-0.5))
            let y = (heightOfNode * (-0.5))
            return CGPoint(x: x, y: y)
        }
    }
    
    class Math {
        // Returns distance between two CGPoint objects
        static func distanceBetweenPoints( first:CGPoint, second:CGPoint ) -> CGFloat {
            let subtractedValue = CGPoint( x: first.x - second.x, y: first.y - second.y )
            let p1              = subtractedValue
            let p2              = subtractedValue
            let lengthSquared   = CGFloat( p1.x * p2.x + p1.y * p2.y )
            let length          = CGFloat( sqrt( lengthSquared ) )
            return length;
        }
        
        // Clamp some numerical primite values
        static func clampDouble( input:Double, min:Double, max:Double ) -> Double {
            var result = input
            var actualMin = min
            var actualMax = max
            if min > max {
                actualMin = max
                actualMax = min
            }
            if result < actualMin {
                result = actualMin
            }
            if result > actualMax {
                result = actualMax
            }
            return result
        }
        static func clampFloat( input:CGFloat, min:CGFloat, max:CGFloat ) -> CGFloat {
            var result = input
            var actualMin = min
            var actualMax = max
            if min > max {
                actualMin = max
                actualMax = min
            }
            if result < actualMin {
                result = actualMin
            }
            if result > actualMax {
                result = actualMax
            }
            return result
        }
        static func clampInteger( input:Int, min:Int, max:Int ) -> Int {
            var result = input
            var actualMin = min
            var actualMax = max
            if min > max {
                actualMin = max
                actualMax = min
            }
            if result < actualMin {
                result = actualMin
            }
            if result > actualMax {
                result = actualMax
            }
            return result
        }
    }
    
    @MainActor
    class Collision {
        // Retrieves bounding box of sprite node
        static func boundingBoxOfSprite( sprite:SKSpriteNode ) -> CGRect {
            let rectX:CGFloat   = sprite.position.x - (sprite.size.width * sprite.anchorPoint.x)
            let rectY:CGFloat   = sprite.position.y - (sprite.size.height * sprite.anchorPoint.y)
            let width:CGFloat   = sprite.size.width
            let height:CGFloat  = sprite.size.height
            return CGRect(x: rectX, y: rectY, width: width, height: height)
        }
        
        // Determines if the radii of two sprites are in contact with each other
        static func betweenSpriteCircles( first:SKSpriteNode, second:SKSpriteNode ) -> Bool {
            // Returns "averaged out" values for distance: (width + height) / 2
            let radiusOfFirst       = ((first.size.width*0.5) + (first.size.height*0.5)) * 0.5
            let radiusOfSecond      = ((second.size.width*0.5) + (second.size.height*0.5)) * 0.5
            let distanceBetweenTwo  = SMUtility.Math.distanceBetweenPoints( first: first.position, second: second.position )
            
            if( distanceBetweenTwo <= (radiusOfFirst + radiusOfSecond) ) {
                return true
            }
            
            return false
        }
        
        // Determines if two bounding boxes are in contact with each other
        static func betweenSpriteBoundingBoxes( first:SKSpriteNode, second:SKSpriteNode ) -> Bool {
            let firstPos    = first.position
            let firstWidth  = first.size.width
            let firstHeight = first.size.height
            let firstX      = firstPos.x - (firstWidth * first.anchorPoint.x)
            let firstY      = firstPos.y - (firstHeight * first.anchorPoint.y)
            let firstBox    = CGRect(x: firstX , y: firstY, width: firstWidth, height: firstHeight)
            
            let secondPos       = second.position
            let secondWidth     = second.size.width
            let secondHeight    = second.size.height
            let secondX         = secondPos.x - (secondWidth * second.anchorPoint.x)
            let secondY         = secondPos.y - (secondHeight * second.anchorPoint.y)
            let secondBox       = CGRect(x: secondX, y: secondY, width: secondWidth, height: secondHeight)
            
            return firstBox.intersects( secondBox )
        }
    }
    
    class Number {
        // These are just a bunch of very simple type conversion wrappers, and this is done in case another Swift update causes conversion functions
        // to require rewriting. Hopefully by the time you read this, the idea of Swift breaking something as simple as type conversion seems like
        // a silly idea, but these functions were written in a time when new Swift versions broke a lot of code FOR NO REASON. :P
        static func toFloat( number:NSNumber) -> Float {
            return number.floatValue
        }
        static func toDouble( number:NSNumber) -> Double {
            return number.doubleValue
        }
        static func toCGFloat( number:NSNumber) -> CGFloat {
            return CGFloat(number.doubleValue)
        }
        static func toInt( number:NSNumber) -> Int {
            return number.intValue
        }
    }
    
    class Color {
        // Creates UIColor object from RGBA values; these values range from 0 to 255
        static func fromRGBA( r:Int, g:Int, b:Int, a:Int ) -> UIColor {
            // convert to float
            var fR = CGFloat(r)
            var fG = CGFloat(g)
            var fB = CGFloat(b)
            var fA = CGFloat(a)
            // Convert to normalized values (0.0 to 1.0)
            fR = fR / 255.0
            fG = fG / 255.0
            fB = fB / 255.0
            fA = fA / 255.0
            //return [UIColor colorWithRed:fR green:fG blue:fB alpha:fA];
            return UIColor(red: fR, green: fG, blue: fB, alpha: fA)
        }
        
        static func fromRGB( r:Int, g:Int, b:Int ) -> UIColor {
            return fromRGBA( r: r, g: g, b: b, a: 255 )
        }
    }
    
    class Strings {
        /*
         This function exists because the actual method to calculate String lengths in Swift changes every so often.
         At one point it required a function named countElements(), and then changed to String.characters.length
         (This is because the people who make Swift loves changing simple things for no reason and breaking existing code.)
         
         Before it changes again, I just made a function to encapsulate it and will just call this function instead.
         */
        static func lengthOf( string:String ) -> Int {
            return Int(string.count)
        }
        
        // Determines if two strings are the same (ignored case). This functions exists because 'caseInsensitiveCompare' is way
        // too long to type all the time
        static func areSame( first:String, second:String ) -> Bool {
            return first.caseInsensitiveCompare(second) == .orderedSame
        }
        
        // This retrieves the character at a particular index
        static func characterAtIndex( string:String, index:Int ) -> Character {
            let theIndex = string.index(string.startIndex, offsetBy: index)
            let theCharacter = string[theIndex]
            return theCharacter
        }
    }
    
    class Files {
        /*
         Pass in a filename. If the filename has an extension (like ".png") then the extension is removed.
         Otherwise, the string is just returned normally if no extension is detected.
         
         input - string with filename
         extension - OPTIONAL extension (such as ".png" or ".jpg") ... you can just pass in "" if you don't want to bother
         */
        static func filenameWithoutExtension( filename:String, theExtension:String ) -> String {
            var expectedLength = 4 // default value for a three-letter extension ".jpg", but some file extensions can be different (".jpeg")
            // needs 4 characters minimum for filename + extension (example: "a.png")
            if SMUtility.Strings.lengthOf(string: filename) < 5 {
                return ""
            }
            // check if there's a valid extension
            if SMUtility.Strings.lengthOf(string: theExtension) > 0 {
                if (SMUtility.Strings.characterAtIndex(string: theExtension, index: 0) == "." ) {
                    expectedLength = SMUtility.Strings.lengthOf(string: theExtension)
                } else {
                    expectedLength = SMUtility.Strings.lengthOf(string: theExtension) + 1
                }
            }
            let expectedPositionOfPeriod    = SMUtility.Strings.lengthOf(string: filename) - expectedLength
            let theCharacter                = SMUtility.Strings.characterAtIndex(string: filename, index: expectedPositionOfPeriod)
            
            if theCharacter == "." {
                let inputAsNSString = filename as NSString
                let substring = inputAsNSString.substring(to: expectedPositionOfPeriod)
                return (substring as String)
            }
            // returns original filename if nothing could be done
            return filename
        }
        
        /*
         Pass in a filename; the filename is separated into the "name" and the extension. For example, if you pass in
         "image.jpg" then you get an array where index 0 is "image" and index 1 is "jpg"
         */
        static func arrayWithFilenameAndExtension( filename:String ) -> [String] {
            if SMUtility.Strings.lengthOf(string: filename) < 1 {
                return [""]
            }
            let theArray = filename.components(separatedBy: ".")
            // the number of indexes should be exactly 2
            if theArray.count < 2 {
                print("[SMUtility.Files.arrayWithFilenameAndExtension] WARNING: Resulting array from \(filename) has less than 2 indexes.")
            } else if theArray.count > 2 {
                print("[SMUtility.Files.arrayWithFilenameAndExtension] WARNING: Resulting array from \(filename) has more than 2 indexes.")
            }
            return theArray
        }
        
        /*
         Pass in filename, get the URL for the resource stored in NSBundle.
         */
        static func URLFromFilename( filename:String ) -> URL? {
            if SMUtility.Strings.lengthOf(string: filename) < 1 {
                return nil
            }
            let filenameComponents = arrayWithFilenameAndExtension(filename: filename)
            if filenameComponents.count < 2 {
                print("[SMUtility.Files.URLFromFilename] ERROR: Could not load filename array from [\(filename)].")
                return nil;
            }
            let nameForFile         = filenameComponents[0]
            let extensionForFile    = filenameComponents[1]
            let theURL              = Bundle.main.url(forResource: nameForFile, withExtension: extensionForFile)
            return theURL
        }
    }
    
    class Audio {
        /*
        Enter filename for audio file, get an AVAudioPlayer object (can be played as a sound effect,
        or set to infinite loop (-1) for use as background music.
        */
        static func soundFromFile( filename:String ) -> AVAudioPlayer? {
            if SMUtility.Strings.lengthOf(string: filename) < 1 {
                print("[SMUtility.Audio.soundFromFile] ERROR: Invalid filename was passed in.")
                return nil
            }
            let url = SMUtility.Files.URLFromFilename(filename: filename)
            if( url == nil ) {
                print("[SMUtility.Audio.soundFromFile] ERROR: Could not retrieve URL from file named [\(filename)]")
                return nil
            }
            var audio:AVAudioPlayer? = nil
            do {
                try audio = AVAudioPlayer(contentsOf: url!)
            } catch{
                print("[SMUtility.Audio.soundFromFile] ERROR: Could not load audio data for file named [\(filename)] to AVAudioPlayer object.")
                return nil
            }
            return audio
        }
    }
    
    class Dictionaries {
        // Loads a dictionary from a property list file (.PLIST)
        static func dictionaryFromFile( filename:String ) -> NSDictionary? {
            // check for invalid filename
            if SMUtility.Strings.lengthOf(string: filename) < 1 {
                print("[SMUtility.Dictionaries.dictionaryFromFile] ERROR: Filename was invalid; could not load.")
                return nil
            }
            let filepath = Bundle.main.path(forResource: filename, ofType: "plist")
            if filepath == nil {
                print("[SMUtility.Dictionaries.dictionaryFromFile] ERROR: Could not find property list named: \(filename)")
                return nil;
            }
            let rootDictionary:NSDictionary? = NSDictionary(contentsOfFile: filepath!)
            if rootDictionary == nil  {
                print("[SMUtility.Dictionaries.dictionaryFromFile] ERROR: Could not load root dictionary from file named: \(filename)")
                return nil
            }
            return rootDictionary
        }

        // adds data from an existing NSDictionary to another NSDictionary
        static func addEntriesFromAnotherDictionary( destination:NSMutableDictionary, source:NSDictionary ) {
            if source.count > 0 {
                for key in source.allKeys {
                    if let someValue = source.object(forKey: key) {
                        destination.setValue(someValue, forKey: key as! String)
                    }
                }
            }
        }

        // Retrieve String from dictionary
        static func stringFromDictionary( dictionary:NSDictionary, name:String) -> String {
            if let str = dictionary.object(forKey: name) as? String {
                return str
            }
            return "" // default value is an empty string, this gets returned if no valid string could be found
        }

        // Retrieve NSArray from dictionary
        static func arrayFromDictionary( dictionary:NSDictionary, name:String) -> NSArray? {
            if let array = dictionary.object(forKey: name) as? NSArray {
                return array
            }
            return nil
        }

        // Retrieve NSNumber from dictionary
        static func numberFromDictionary( dictionary:NSDictionary, name:String ) -> NSNumber {
            if let number = dictionary.object(forKey: name) as? NSNumber {
                return number
            }
            return NSNumber(value: 0)
        }

        static func integerFromDictionary( dictionary:NSDictionary, name:String ) -> Int {
            return numberFromDictionary(dictionary: dictionary, name: name).intValue
        }
        static func boolFromDictionary( dictionary:NSDictionary, name:String ) -> Bool {
            return numberFromDictionary(dictionary: dictionary, name: name).boolValue
        }
        static func floatFromDictionary( dictionary:NSDictionary, name:String ) -> Float {
            return numberFromDictionary(dictionary: dictionary, name: name).floatValue
        }
        static func doubleFromDictionary( dictionary:NSDictionary, name:String ) -> Double {
            return numberFromDictionary(dictionary: dictionary, name: name).doubleValue
        }
        static func CGFloatFromDictionary( dictionary:NSDictionary, name:String ) -> CGFloat {
            return CGFloat(numberFromDictionary(dictionary: dictionary, name: name).doubleValue)
        }
        
    }
    
    class Arrays {
        // Adds objects from a source array to a mutable destination array (NSArray to NSMutableArray, or NSMutableArray to NSMutableArray works fine too)
        static func addObjectsToMutableArray(destination:NSMutableArray, source:NSArray) {
            for element in source {
                destination.add(element)
            }
        }
    }
    
    class Dice {
        // Rolls "dice" to generate random number; possible values include 1 to (maximumRollValue)
        // for example, to generate the equivalent of a 10d6 with a +5 bonus, you would call: SMDiceRoll(10, 6, 5).
        static func roll( numberOfDice:Int, maximumRollValue:Int, plusModifier:Int ) -> Int {
            var diceCount = numberOfDice;
            var maxValue = maximumRollValue
            // check for invalid inputs and fix them
            if diceCount < 1 {
                diceCount = 1
            }
            if maxValue < 2 {
                maxValue = 2
            }
            var finalValue:Int = 0
            var random:Int = 0
            // loop through all dice
            for _ in 0..<diceCount {
                random = Int( arc4random() ) % maxValue
                finalValue = finalValue + random + 1 // adds 1 so that the results are: from 1 to (max)
            }
            return (finalValue + plusModifier)
        }
    }
}
