//
//  SMUtils.swift
//
//  Created by James on 11/11/14.
//  Copyright (c) 2014 James Briones. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit
import AVFoundation

// Set screen/view dimensions; use default sizes for iPhone 4S
var SMScreenWidthInPoints:CGFloat   = 480.0;
var SMScreenHeightInPoints:CGFloat  = 320.0;
var SMScreenDimensionsHaveBeenSet   = false

// MARK: - Screen dimensions
    
// Just tells SMUtils what the screen size is supposed to be (some later calculations are based off this information)
func SMSetScreenSizeInPoints( width:CGFloat, height:CGFloat) {
    SMScreenWidthInPoints = abs( width );
    SMScreenHeightInPoints = abs( height );
    
    print("[SMSetScreenSizeInPoints] - width: \(SMScreenWidthInPoints) | height: \(SMScreenHeightInPoints)")
    
    SMScreenDimensionsHaveBeenSet = true
}

// Retrieves screen size in points
func SMScreenSizeInPoints() -> CGSize {
    // check if the screen dimenions have NOT been passed in properly yet
    if SMScreenDimensionsHaveBeenSet == false {
        // don't really do anything other than print a warning
        print("[SMScreenSizeInPoints] WARNING: Screen size has not been set properly; this function will return an unsure default value.");
    }
    
    let w = SMScreenWidthInPoints
    let h = SMScreenHeightInPoints
    
    return CGSize(width: w, height: h)
}


// determines screen size and other data from a passed-in SKView object
func SMSetScreenDataFromView( view:SKView) {
    let viewSizeInPoints:CGSize = view.frame.size;
    
    let w = viewSizeInPoints.width
    let h = viewSizeInPoints.height
    
    SMSetScreenSizeInPoints( width: w, height: h );
}

// MARK: - Positions

// Returns a precise x,y coordinate from normalized values (in which 0.5,0.5 would be the exact center of the screen)
func SMPositionWithNormalizedCoordinates( normalizedX:CGFloat, normalizedY:CGFloat ) -> CGPoint {
    let x = (SMScreenWidthInPoints) * (normalizedX)
    let y = (SMScreenHeightInPoints) * (normalizedY)
    
    return CGPoint( x: x, y: y );
}

// Returns the value of two CGPoint values added together
func SMPositionAddTwoPositions( first:CGPoint, second:CGPoint ) -> CGPoint {
    let x = first.x + second.x;
    let y = first.y + second.y;
    
    return CGPoint( x: x, y: y );
}

// Returns the position of the bottom-left corner of a particular node
func SMPositionOfBottomLeftCornerOfSKNode( node:SKNode ) -> CGPoint {
    let widthOfNode = node.frame.size.width;
    let heightOfNode = node.frame.size.height;
    
    let xPos = (widthOfNode * (-0.5));
    let yPos = (heightOfNode * (-0.5));
    
    return CGPoint(x: xPos, y: yPos);
}

// MARK: - Math

// Returns distance between two CGPoint objects
func SMMathDistanceBetweenPoints( first:CGPoint, second:CGPoint ) -> CGFloat {
    let subtractedValue         = CGPoint( x: first.x - second.x, y: first.y - second.y );
    let p1:CGPoint              = subtractedValue;
    let p2:CGPoint              = subtractedValue;
    let lengthSquared:CGFloat   = ( p1.x * p2.x + p1.y * p2.y );
    let length:CGFloat          = sqrt( lengthSquared );
    
    return length;
}

func SMClampDouble( input:Double, min:Double, max:Double ) -> Double {
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

func SMClampFloat( input:CGFloat, min:CGFloat, max:CGFloat ) -> CGFloat {
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

func SMClampInteger( input:Int, min:Int, max:Int ) -> Int {
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

// MARK: - Collision

// Retrieves bounding box of sprite node
func SMBoundingBoxOfSprite( sprite:SKSpriteNode ) -> CGRect {
    let rectX:CGFloat = sprite.position.x - (sprite.size.width * sprite.anchorPoint.x);
    let rectY:CGFloat = sprite.position.y - (sprite.size.height * sprite.anchorPoint.y);
    let width:CGFloat = sprite.size.width;
    let height:CGFloat = sprite.size.height;
    
    return CGRect(x: rectX, y: rectY, width: width, height: height);
}

// Determines if the radii of two sprites are in contact with each other
func SMCollisionBetweenSpriteCircles( first:SKSpriteNode, second:SKSpriteNode ) -> Bool {
    // Returns "averaged out" values for distance: (width + height) / 2
    let radiusOfFirst   = ((first.size.width*0.5) + (first.size.height*0.5)) * 0.5;
    let radiusOfSecond  = ((second.size.width*0.5) + (second.size.height*0.5)) * 0.5;
    
    let distanceBetweenTwo = SMMathDistanceBetweenPoints( first: first.position, second: second.position );
        
    if( distanceBetweenTwo <= (radiusOfFirst + radiusOfSecond) ) {
        return true;
    }
    
    return false;
}

// Determines if two bounding boxes are in contact with each other
func SMCollisionBetweenSpriteBoundingBoxes( first:SKSpriteNode, second:SKSpriteNode ) -> Bool {
    let firstPos    = first.position;
    let firstWidth  = first.size.width;
    let firstHeight = first.size.height;
    let firstX      = firstPos.x - (firstWidth * first.anchorPoint.x);
    let firstY      = firstPos.y - (firstHeight * first.anchorPoint.y);
    let firstBox    = CGRect(x: firstX , y: firstY, width: firstWidth, height: firstHeight);
    
    let secondPos       = second.position;
    let secondWidth     = second.size.width;
    let secondHeight    = second.size.height;
    let secondX         = secondPos.x - (secondWidth * second.anchorPoint.x);
    let secondY         = secondPos.y - (secondHeight * second.anchorPoint.y);
    let secondBox       = CGRect(x: secondX, y: secondY, width: secondWidth, height: secondHeight);
    
    return firstBox.intersects( secondBox );
}

// MARK: - Type conversion

/*
 These are very simple type conversion wrappers. This is done in case another Swift update causes conversion functions to require rewriting. :P
 */
func SMNumberToFloat( number:NSNumber) -> Float {
    return number.floatValue
}
func SMNumberToDouble( number:NSNumber) -> Double {
    return number.doubleValue
}
func SMNumberToCGFloat( number:NSNumber) -> CGFloat {
    return CGFloat(number.doubleValue)
}
func SMNumberToInt( number:NSNumber) -> Int {
    return number.intValue
}

func SMNumberInDictionaryToCGFloat( dictionary:NSDictionary, objectName:String ) -> CGFloat {
    if let number = dictionary.object(forKey: objectName) as? NSNumber {
        return CGFloat( number.doubleValue )
    }
    
    return 0;
}

func SMNumberInDictionaryToDouble( dictionary:NSDictionary, objectName:String ) -> Double {
    if let number = dictionary.object(forKey: objectName) as? NSNumber {
        return number.doubleValue
    }
    
    return 0;
}

func SMNumberInDictionaryToInt( dictionary:NSDictionary, objectName:String ) -> Int {
    if let number = dictionary.object(forKey: objectName) as? NSNumber {
        return number.intValue
    }
    
    return 0;
}

// MARK: - Color

// Creates UIColor object from RGBA values; these values range from 0 to 255
func SMColorFromRGBA( r:Int, g:Int, b:Int, a:Int ) -> UIColor {
    // convert to float
    var fR = CGFloat(r)
    var fG = CGFloat(g)
    var fB = CGFloat(b)
    var fA = CGFloat(a)
    
    // Convert to normalized values (0.0 to 1.0)
    fR = fR / 255.0;
    fG = fG / 255.0;
    fB = fB / 255.0;
    fA = fA / 255.0;
    
    //return [UIColor colorWithRed:fR green:fG blue:fB alpha:fA];
    return UIColor(red: fR, green: fG, blue: fB, alpha: fA)
}

func SMColorFromRGB( r:Int, g:Int, b:Int ) -> UIColor {
    return SMColorFromRGBA( r: r, g: g, b: b, a: 255 )
}


// MARK: - Strings

/*
 This function exists because the actual method to calculate String lengths in Swift changes every so often.
 At one point it required a function named countElements(), and then changed to String.characters.length
 
 Before it changes again, I just made a function to encapsulate it and will just call this function instead.
*/
func SMStringLength( string:String ) -> Int {
    return Int(string.count)
}

// Determines if two strings are the same (ignored case). This functions exists because 'caseInsensitiveCompare' is way 
// too long to type all the time
func SMStringsAreSame( first:String, second:String ) -> Bool {
    if first.caseInsensitiveCompare(second) == .orderedSame {
        return true
    }
    
    return false
}

// This retrieves the character at a particular index
func SMStringCharacterAtIndex( string:String, indexPosition:Int ) -> Character {
    let index = string.index(string.startIndex, offsetBy: indexPosition)
    let theCharacter = string[index]
    
    return theCharacter
}

// MARK: - Filename/bundle functions

 /*
 Pass in a filename. If the filename has an extension (like ".png") then the extension is removed.
 Otherwise, the string is just returned normally if no extension is detected.
 
 input - string with filename
 extension - OPTIONAL extension (such as ".png" or ".jpg") ... you can just pass in "" if you don't want to bother
 */
func SMStringFilenameWithoutExtension( filename:String, theExtension:String ) -> String {
    // needs 4 characters minimum for filename + extension (example: "a.png")
    if SMStringLength(string: filename) < 5 {
        return ""
    }
    
    var expectedLength = 4 // default value for a three-letter extension ".jpg"
    
    // check if there's a valid extension
    if SMStringLength(string: theExtension) > 0 {
        
        if (SMStringCharacterAtIndex(string: theExtension, indexPosition: 0) == "." ) {
            expectedLength = SMStringLength(string: theExtension)
        } else {
            expectedLength = SMStringLength(string: theExtension) + 1
        }
    }
    
    let expectedPositionOfPeriod    = SMStringLength(string: filename) - expectedLength
    let theCharacter                = SMStringCharacterAtIndex(string: filename, indexPosition: expectedPositionOfPeriod)
    
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
func SMStringArrayWithFilenameAndExtension( filename:String ) -> [String] {
    if SMStringLength(string: filename) < 1 {
        return [""]
    }
    
    let theArray = filename.components(separatedBy: ".")
    
    // the number of indexes should be exactly 2
    if theArray.count < 2 {
        print("[SMStringArrayWithFilenameAndExtension] WARNING: Resulting array from \(filename) has less than 2 indexes.")
    } else if theArray.count > 2 {
        print("[EKStringArrayWithFilenameAndExtension] WARNING: Resulting array from \(filename) has more than 2 indexes.")
    }
    
    return theArray
}

/*
Pass in filename, get the URL for the resource stored in NSBundle.
*/
func SMStringURLFromFilename( filename:String ) -> URL? {
    if SMStringLength(string: filename) < 1 {
        return nil
    }
    
    let filenameComponents = SMStringArrayWithFilenameAndExtension(filename: filename)
    if filenameComponents.count < 2 {
        print("[SMStringUrlFromFilename] ERROR: Could not load filename array from [\(filename)].")
        return nil;
    }
    
    let nameForFile         = filenameComponents[0]
    let extensionForFile    = filenameComponents[1]
    
    //let theURL = Bundle.main.urlForResource(nameForFile, withExtension: extensionForFile)
    let theURL = Bundle.main.url(forResource: nameForFile, withExtension: extensionForFile)
    
    return theURL
}


// MARK: - AUDIO


/*
Enter filename for audio file, get an AVAudioPlayer object (can be played as a sound effect,
or set to infinite loop (-1) for use as background music.
*/
func SMAudioSoundFromFile( filename:String ) -> AVAudioPlayer?
{
    if SMStringLength(string: filename) < 1 {
        print("[SMAudioSoundFromFile] ERROR: Invalid filename was passed in.")
        return nil
    }
    
    let url = SMStringURLFromFilename(filename: filename)
    if( url == nil ) {
        print("[SMAudioSoundFromFile] ERROR: Could not retrieve URL from file named [\(filename)]")
        return nil
    }
    
    var audio:AVAudioPlayer? = nil
    
    do {
        try audio = AVAudioPlayer(contentsOf: url!)
    } catch{
        print("[SMAudioSoundFromFile] ERROR: Could not load audio data for file named [\(filename)]to AVAudioPlayer object.")
        return nil
    }
    
    return audio
}


// MARK: - Swift/Foundation conversion
/*
    Trying to access data stored in Foundation classes (such as retrieving various types of data stored in an NSDictionary object)
    can be kind of a hassle in Swift, since converting to/from Foundation types (NSObject, NSString, etc) seems to change with
    every version of Swift. To make it easier -- or try to -- Ive just made some simple utility functions for things that I do a lot,
    but which seem to require being rewritten everytime Swift is updated.
 
    EDIT - April 11, 2024: These days, Swift doesn't really do drastic changes that break previous code. That said, I'm still going
                           to keep these functions, partly because there's no real guarantee that future versions of Swift won't suddenly
                           change a bunch of things for seemingly no reason, but also because it would be a hassle to rewrite any
                           existing code that calls these functions.
*/

// Loads a dictionary from a property list file (.PLIST)
func SMDictionaryFromFile( filename:String ) -> NSDictionary? {
    // check for invalid filename
    if SMStringLength(string: filename) < 1 {
        print("[SMDictionaryFromFile] ERROR: Filename was invalid; could not load.")
        return nil
    }
    
    let filepath = Bundle.main.path(forResource: filename, ofType: "plist")
    if filepath == nil {
        print("[EKDictionaryFromFile] ERROR: Could not find property list named: \(filename)")
        return nil;
    }
    
    //let rootDictionary:NSDictionary? = NSDictionary(contentsOfFile:filepath)
    let rootDictionary:NSDictionary? = NSDictionary(contentsOfFile: filepath!)
    if rootDictionary == nil  {
        print("[EKDictionaryFromFile] ERROR: Could not load root dictionary from file named: \(filename)")
        return nil
    }
    
    return rootDictionary
}

// adds data from an existing NSDictionary to another NSDictionary
func SMDictionaryAddEntriesFromAnotherDictionary( destination:NSMutableDictionary, source:NSDictionary) {
    if source.count > 0 {
        for key in source.allKeys {
            if let someValue = source.object(forKey: key) {
                destination.setValue(someValue, forKey: key as! String)
            }
        }
    }
}

// Retrieve String from dictionary
func SMStringFromDictionary( dictionary:NSDictionary, nameOfObject:String) -> String {
    if let str = dictionary.object(forKey: nameOfObject) as? String {
        return str
    }
    
    return "" // default value is an empty string
}

// Retrieve NSArray from dictionary
func SMArrayFromDictionary( dictionary:NSDictionary, nameOfObject:String) -> NSArray? {
    if let a = dictionary.object(forKey: nameOfObject) as? NSArray {
        return a
    }
    
    return nil
}

// Retrieve NSNumber from dictionary
func SMNumberFromDictionary( dictionary:NSDictionary, nameOfObject:String ) -> NSNumber {
    if let number = dictionary.object(forKey: nameOfObject) as? NSNumber {
        return number
    }
    
    return NSNumber(value: 0)
}


func SMIntFromDictionary( dictionary:NSDictionary, nameOfObject:String ) -> Int {
    return SMNumberFromDictionary(dictionary: dictionary, nameOfObject: nameOfObject).intValue
}
func SMBoolFromDictionary( dictionary:NSDictionary, nameOfObject:String ) -> Bool {
    return SMNumberFromDictionary(dictionary: dictionary, nameOfObject: nameOfObject).boolValue
}
func SMFloatFromDictionary( dictionary:NSDictionary, nameOfObject:String ) -> Float {
    return SMNumberFromDictionary(dictionary: dictionary, nameOfObject: nameOfObject).floatValue
}
func SMDoubleFromDictionary( dictionary:NSDictionary, nameOfObject:String ) -> Double {
    return SMNumberFromDictionary(dictionary: dictionary, nameOfObject: nameOfObject).doubleValue
}

// MARK: - Array helper functions

// Because NSMutableArray.addObjects(from: someNSArray) will just produce some dumb
// "'NSArray' is not convertible to '[Any]' error message.
func SMArrayAddObjectsToMutableArray(destination:NSMutableArray, sourceArray:NSArray) {
    for element in sourceArray {
        destination.add(element)
    }
}

// MARK: - Misc functions
/*
 Stuff that really doesn't fit elsewhere
 */

// Rolls "dice" to generate random number; possible values include 1 to (maximumRollValue)
//
// for example, to generate the equivalent of a 10d6 with a +5 bonus, you would call: SMDiceRoll(10, 6, 5).
func SMRollDice( numberOfDice:Int, maximumRollValue:Int, plusModifier:Int ) -> Int {
    var diceCount = numberOfDice;
    var maxValue = maximumRollValue// as UInt32
    
    // check for invalid inputs and fix them
    if diceCount < 1 {
        diceCount = 1
    }
    if maxValue < 2 {
        maxValue = 2
    }
    
    var finalValue:Int = 0
    var random:Int = 0
    
    for _ in 0..<diceCount {
        //random = Int(arc4random_uniform(maxValue))
        random = Int( arc4random() ) % maxValue
        finalValue = finalValue + random + 1 // adds 1 so that the results are: from 1 to (max)
    }
    
    finalValue = finalValue + plusModifier
    
    return finalValue
}
