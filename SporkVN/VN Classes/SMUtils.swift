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

/** SCREEN DIMENSIONS **/

// Just tells SMUtils what the screen size is supposed to be (some later calculations are based off this information)
func SMSetScreenSizeInPoints(_ width:CGFloat, height:CGFloat) {
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
func SMSetScreenDataFromView(_ view:SKView) {
    let viewSizeInPoints:CGSize = view.frame.size;
    
    let w = viewSizeInPoints.width
    let h = viewSizeInPoints.height
    
    SMSetScreenSizeInPoints( w, height: h );
}

/** POSITIONS **/

// Returns a precise x,y coordinate from normalized values (in which 0.5,0.5 would be the exact center of the screen)
func SMPositionWithNormalizedCoordinates( _ normalizedX:CGFloat, normalizedY:CGFloat ) -> CGPoint
{
    let x = (SMScreenWidthInPoints) * (normalizedX)
    let y = (SMScreenHeightInPoints) * (normalizedY)
    
    return CGPoint( x: x, y: y );
}

// Returns the value of two CGPoint values added together
func SMPositionAddTwoPositions( _ first:CGPoint, second:CGPoint ) -> CGPoint
{
    let x = first.x + second.x;
    let y = first.y + second.y;
    
    return CGPoint( x: x, y: y );
}

// Returns the position of the bottom-left corner of a particular node
func SMPositionOfBottomLeftCornerOfSKNode( _ theNode:SKNode ) -> CGPoint
{
    let widthOfNode = theNode.frame.size.width;
    let heightOfNode = theNode.frame.size.height;
    
    let xPos = (widthOfNode * (-0.5));
    let yPos = (heightOfNode * (-0.5));
    
    return CGPoint(x: xPos, y: yPos);
}

/** MATH **/

// Returns distance between two CGPoint objects
func SMMathDistanceBetweenPoints( _ first:CGPoint, second:CGPoint ) -> CGFloat
{
    let subtractedValue         = CGPoint( x: first.x - second.x, y: first.y - second.y );
    let p1:CGPoint              = subtractedValue;
    let p2:CGPoint              = subtractedValue;
    let lengthSquared:CGFloat   = ( p1.x * p2.x + p1.y * p2.y );
    let length:CGFloat          = sqrt( lengthSquared );
    
    return length;
}

/** COLLISION **/

// Retrieves bounding box of sprite node
func SMBoundingBoxOfSprite( _ sprite:SKSpriteNode ) -> CGRect
{
    let rectX:CGFloat = sprite.position.x - (sprite.size.width * sprite.anchorPoint.x);
    let rectY:CGFloat = sprite.position.y - (sprite.size.height * sprite.anchorPoint.y);
    let width:CGFloat = sprite.size.width;
    let height:CGFloat = sprite.size.height;
    
    return CGRect(x: rectX, y: rectY, width: width, height: height);
}

// Determines if the radii of two sprites are in contact with each other
func SMCollisionBetweenSpriteCircles( _ first:SKSpriteNode, second:SKSpriteNode ) -> Bool
{
    // Returns "averaged out" values for distance: (width + height) / 2
    let radiusOfFirst   = ((first.size.width*0.5) + (first.size.height*0.5)) * 0.5;
    let radiusOfSecond  = ((second.size.width*0.5) + (second.size.height*0.5)) * 0.5;
    
    let distanceBetweenTwo = SMMathDistanceBetweenPoints( first.position, second: second.position );
        
    if( distanceBetweenTwo <= (radiusOfFirst + radiusOfSecond) ) {
        return true;
    }
    
    return false;
}

// Determines if two bounding boxes are in contact with each other
func SMCollisionBetweenSpriteBoundingBoxes( _ first:SKSpriteNode, second:SKSpriteNode ) -> Bool
{
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

/** TYPE CONVERSION **/

/*
 These are very simple type conversion wrappers. This is done in case another Swift update causes conversion functions to require rewriting. :P
 */
func SMNumberToFloat(_ someNumber:NSNumber) -> Float {
    return someNumber.floatValue
}
func SMNumberToDouble(_ someNumber:NSNumber) -> Double {
    return someNumber.doubleValue
}
func SMNumberToCGFloat(_ someNumber:NSNumber) -> CGFloat {
    return CGFloat(someNumber.doubleValue)
}
func SMNumberToInt(_ someNumber:NSNumber) -> Int {
    return someNumber.intValue
}

func SMNumberInDictionaryToCGFloat(_ someDictionary:NSDictionary, objectNamed:String) -> CGFloat {
    let someNumber:NSNumber? = someDictionary.object(forKey: objectNamed) as? NSNumber
    if someNumber != nil {
        return CGFloat(someNumber!.doubleValue)
    }
    
    print("[Could not find number named \(objectNamed) - could not convert to CGFloat]")
    return 0;
}

func SMNumberInDictionaryToDouble(_ someDictionary:NSDictionary, objectNamed:String) -> Double {
    let someNumber:NSNumber? = someDictionary.object(forKey: objectNamed) as? NSNumber
    if someNumber != nil {
        return someNumber!.doubleValue
    }
    
    print("[Could not find number named \(objectNamed) - could not convert to Double]")
    return 0;
}

func SMNumberInDictionaryToInt(_ someDictionary:NSDictionary, objectNamed:String) -> Int {
    let someNumber:NSNumber? = someDictionary.object(forKey: objectNamed) as? NSNumber
    if someNumber != nil {
        return someNumber!.intValue
    }
    
    print("[Could not find number named \(objectNamed) - could not convert to Int]")
    return 0;
}

/** COLOR **/

// Creates UIColor object from RGBA values; these values range from 0 to 255
func SMColorFromRGBA( _ r:Int, g:Int, b:Int, a:Int ) -> UIColor {
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

func SMColorFromRGB( _ r:Int, g:Int, b:Int ) -> UIColor {
    return SMColorFromRGBA(r, g: g, b: b, a: 255)
}


/** STRINGS **/

/*
 This function exists because the actual method to calculate String lengths in Swift changes every so often.
 At one point it required a function named countElements(), and then changed to String.characters.length
 
 Before it changes again, I just made a function to encapsulate it and will just call this function instead
*/
func SMStringLength( _ theString:String ) -> Int {
    let theLength = theString.count
    
    return theLength
}

// This retrieves the character at a particular index
func SMStringCharacterAtIndex( _ theString:String, indexPosition:Int ) -> Character {
    //let index = theString.characters.index(theString.characters.startIndex, offsetBy: indexPosition)
    //let theCharacter = theString.characters[index]
    //let index : String.Index = String.Index.init(encodedOffset: indexPosition)
    //let index : String.Index = String.Index(utf16Offset: indexPosition, in: <#T##StringProtocol#>
    
    let index = theString.index(theString.startIndex, offsetBy: indexPosition)
    let theCharacter = theString[index]
    
    return theCharacter
}

/** FILENAME/BUNDLE FUNCTIONS **/


 /*
 Pass in a filename. If the filename has an extension (like ".png") then the extension is removed.
 Otherwise, the string is just returned normally if no extension is detected.
 
 input - string with filename
 extension - OPTIONAL extension (such as ".png" or ".jpg") ... you can just pass in "" if you don't want to bother
 */
func SMStringFilenameWithoutExtension( _ input:String, theExtension:String ) -> String {
    
    if SMStringLength(input) < 5 { // needs 4 characters minimum for filename + extension (example: "a.png")
        return ""
    }
    
    var expectedLength = 4 // default value for a three-letter extension ".jpg"
    
    // check if there's a valid extension
    if SMStringLength(theExtension) > 0 {
        
        if (SMStringCharacterAtIndex(theExtension, indexPosition: 0) == "." ) {
            expectedLength = SMStringLength(theExtension)
        } else {
            expectedLength = SMStringLength(theExtension) + 1
        }
    }
    
    let expectedPositionOfPeriod = SMStringLength(input) - expectedLength
    let theCharacter = SMStringCharacterAtIndex(input, indexPosition: expectedPositionOfPeriod)
    
    if theCharacter == "." {
        let inputAsNSString = input as NSString
        let substring = inputAsNSString.substring(to: expectedPositionOfPeriod)
        
        return (substring as String)
    }
    
    return input
}

/*
Pass in a filename; the filename is separated into the "name" and the extension. For example, if you pass in
"image.jpg" then you get an array where index 0 is "image" and index 1 is "jpg"
*/
func SMStringArrayWithFilenameAndExtension( _ filename:String ) -> [String]
{
    if SMStringLength(filename) < 1 {
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
func SMStringURLFromFilename( _ filename:String ) -> URL?
{
    if SMStringLength(filename) < 1 {
        return nil
    }
    
    let filenameComponents = SMStringArrayWithFilenameAndExtension(filename)
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


/** AUDIO **/


/*
Enter filename for audio file, get an AVAudioPlayer object (can be played as a sound effect,
or set to infinite loop (-1) for use as background music.
*/
func SMAudioSoundFromFile( _ filename:String ) -> AVAudioPlayer?
{
    if SMStringLength(filename) < 1 {
        print("[SMAudioSoundFromFile] ERROR: Invalid filename was passed in.")
        return nil
    }
    
    let url = SMStringURLFromFilename(filename)
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


/** Swift/Foundation conversion **/
/*

    Trying to access data stored in Foundation classes (such as retrieving various types of data stored in an NSDictionary object)
    can be kind of a hassle in Swift, since converting to/from Foundation types (NSObject, NSString, etc) seems to change with
    every version of Swift. To make it easier -- or try to -- Ive just made some simple utility functions for things that I do a lot,
    but which seem to require being rewritten everytime Swift is updated.
*/

func SMDictionaryFromFile(_ plistFilename:String) -> NSDictionary? {
    // check for invalid filename
    if SMStringLength(plistFilename) < 1 {
        print("[SMDictionaryFromFile] ERROR: Filename was invalid; could not load.")
        return nil
    }
    
    let filepath = Bundle.main.path(forResource: plistFilename, ofType: "plist")
    if filepath == nil {
        print("[EKDictionaryFromFile] ERROR: Could not find property list named: \(plistFilename)")
        return nil;
    }
    
    //let rootDictionary:NSDictionary? = NSDictionary(contentsOfFile:filepath)
    let rootDictionary:NSDictionary? = NSDictionary(contentsOfFile: filepath!)
    if rootDictionary == nil  {
        print("[EKDictionaryFromFile] ERROR: Could not load root dictionary from file named: \(plistFilename)")
        return nil
    }
    
    return rootDictionary
}

// adds data from an existing NSDictionary to another NSDictionary
func SMDictionaryAddEntriesFromAnotherDictionary(_ dest:NSMutableDictionary, source:NSDictionary) {
    if source.count > 0 {
        for key in source.allKeys {
            let someValue = source.object(forKey: key)
            if someValue != nil {
                dest.setValue(someValue!, forKey: key as! String)
            }
        }
    }
}

// Retrieve String from dictionary
func SMStringFromDictionary( _ dict:NSDictionary, nameOfObject:String) -> String
{
    let str:String? = dict.object(forKey: nameOfObject) as? String
    if( str == nil ) {
        return ""
    }
    
    return str!
}

// Retrieve NSArray from dictionary
func SMArrayFromDictionary(_ dict:NSDictionary, nameOfObject:String) -> NSArray? {
    let a = dict.object(forKey: nameOfObject) as? NSArray
    if a != nil {
        return a
    }
    
    return nil
}

// Retrieve NSNumber from dictionary
func SMNumberFromDictionary( _ dict:NSDictionary, nameOfObject:String ) -> NSNumber
{
    let number:NSNumber? = dict.object(forKey: nameOfObject) as? NSNumber
    if( number == nil ) {
        print("[SMNumberFromDictionary] WARNING: Number from key [\(nameOfObject)] could not be found, will auto-generate NSNumber with value of zero.")
        return NSNumber(value: 0);
    }
    
    return number!
}


func SMIntFromDictionary( _ dict:NSDictionary, nameOfObject:String ) -> Int {
    return SMNumberFromDictionary(dict, nameOfObject: nameOfObject).intValue
}
func SMBoolFromDictionary( _ dict:NSDictionary, nameOfObject:String ) -> Bool {
    return SMNumberFromDictionary(dict, nameOfObject: nameOfObject).boolValue
}
func SMFloatFromDictionary( _ dict:NSDictionary, nameOfObject:String ) -> Float {
    return SMNumberFromDictionary(dict, nameOfObject: nameOfObject).floatValue
}
func SMDoubleFromDictionary( _ dict:NSDictionary, nameOfObject:String ) -> Double {
    return SMNumberFromDictionary(dict, nameOfObject: nameOfObject).doubleValue
}

/** MISC FUNCTIONS **/
/*
 Stuff that really doesn't fit elsewhere
 */

// Rolls "dice" to generate random number; possible values include 1 to (maximumRollValue)
//
// for example, to generate the equivalent of a 10d6 with a +5 bonus, you would call: SMDiceRoll(10, 6, 5).
func SMRollDice( _ numberOfDice:Int, maximumRollValue:Int, plusModifier:Int ) -> Int {
    
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
        finalValue = finalValue + random + 1 // adds 1 so that the results are 1-(max)
    }
    
    finalValue = finalValue + plusModifier
    
    return finalValue
}
