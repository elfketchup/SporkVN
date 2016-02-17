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

/** SCREEN DIMENSIONS **/

//void SMSetScreenSizeInPoints( CGFloat width, CGFloat height )
func SMSetScreenSizeInPoints(width:CGFloat, height:CGFloat)
{
    SMScreenWidthInPoints = fabs( width );
    SMScreenHeightInPoints = fabs( height );
    
    //NSLog(@"Screen size in points has been set to: %f, %f", SMScreenWidthInPoints, SMScreenHeightInPoints);
}

func SMScreenSizeInPoints() -> CGSize {
    
    let w = SMScreenWidthInPoints
    let h = SMScreenHeightInPoints
    
    return CGSizeMake(w, h)
}

//void SMSetScreenDataFromView( SKView* view )
func SMSetScreenDataFromView(view:SKView)
{
    let viewSizeInPoints:CGSize = view.frame.size;
    
    let w = viewSizeInPoints.width
    let h = viewSizeInPoints.height
    
    SMSetScreenSizeInPoints( w, height: h );
}

/** POSITIONS **/

//CGPoint SMPositionWithNormalizedCoordinates( CGFloat normalizedX, CGFloat normalizedY )
func SMPositionWithNormalizedCoordinates( normalizedX:CGFloat, normalizedY:CGFloat ) -> CGPoint
{
    let x = (SMScreenWidthInPoints) * (normalizedX)
    let y = (SMScreenHeightInPoints) * (normalizedY)
    
    return CGPointMake( x, y );
}

func SMPositionAddTwoPositions( first:CGPoint, second:CGPoint ) -> CGPoint
{
    let x = first.x + second.x;
    let y = first.y + second.y;
    
    return CGPointMake( x, y );
}

func SMPositionOfBottomLeftCornerOfParentNode( parentNode:SKNode ) -> CGPoint
{
    let widthOfParent = parentNode.frame.size.width;
    let heightOfParent = parentNode.frame.size.height;
    
    let xPos = (widthOfParent * (-0.5));
    let yPos = (heightOfParent * (-0.5));
    
    return CGPointMake(xPos, yPos);
}

/** MATH **/

func SMMathDistanceBetweenPoints( first:CGPoint, second:CGPoint ) -> CGFloat
{
    let subtractedValue         = CGPointMake( first.x - second.x, first.y - second.y );
    let p1:CGPoint              = subtractedValue;
    let p2:CGPoint              = subtractedValue;
    let lengthSquared:CGFloat   = ( p1.x * p2.x + p1.y * p2.y );
    let length:CGFloat          = sqrt( lengthSquared );
    
    return length;
}

/** COLLISION **/

func SMBoundingBoxOfSprite( sprite:SKSpriteNode ) -> CGRect
{
    let rectX:CGFloat = sprite.position.x - (sprite.size.width * sprite.anchorPoint.x);
    let rectY:CGFloat = sprite.position.y - (sprite.size.height * sprite.anchorPoint.y);
    let width:CGFloat = sprite.size.width;
    let height:CGFloat = sprite.size.height;
    
    return CGRectMake(rectX, rectY, width, height);
}

func SMCollisionBetweenSpriteCircles( first:SKSpriteNode, second:SKSpriteNode ) -> Bool
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

func SMCollisionBetweenSpriteBoundingBoxes( first:SKSpriteNode, second:SKSpriteNode ) ->Bool
{
    let firstPos    = first.position;
    let firstWidth  = first.size.width;
    let firstHeight = first.size.height;
    let firstX      = firstPos.x - (firstWidth * first.anchorPoint.x);
    let firstY      = firstPos.y - (firstHeight * first.anchorPoint.y);
    let firstBox    = CGRectMake(firstX , firstY, firstWidth, firstHeight);
    
    let secondPos       = second.position;
    let secondWidth     = second.size.width;
    let secondHeight    = second.size.height;
    let secondX         = secondPos.x - (secondWidth * second.anchorPoint.x);
    let secondY         = secondPos.y - (secondHeight * second.anchorPoint.y);
    let secondBox       = CGRectMake(secondX, secondY, secondWidth, secondHeight);
    
    return CGRectIntersectsRect( firstBox, secondBox );
}

/** TYPE CONVERSION **/

func SMNumberToFloat(someNumber:NSNumber) -> Float
{
    return someNumber.floatValue
}

func SMNumberToDouble(someNumber:NSNumber) -> Double
{
    return someNumber.doubleValue
}

func SMNumberToCGFloat(someNumber:NSNumber) -> CGFloat
{
    return CGFloat(someNumber.doubleValue)
}

func SMNumberToInt(someNumber:NSNumber) -> Int
{
    return someNumber.integerValue
}

func SMNumberInDictionaryToCGFloat(someDictionary:NSDictionary, objectNamed:String) -> CGFloat
{
    let someNumber:NSNumber? = someDictionary.objectForKey(objectNamed) as? NSNumber
    if someNumber != nil {
        return CGFloat(someNumber!.doubleValue)
    }
    
    print("[Could not find number named \(objectNamed) - could not convert to CGFloat]")
    return 0;
}

func SMNumberInDictionaryToDouble(someDictionary:NSDictionary, objectNamed:String) -> Double
{
    let someNumber:NSNumber? = someDictionary.objectForKey(objectNamed) as? NSNumber
    if someNumber != nil {
        return someNumber!.doubleValue
    }
    
    print("[Could not find number named \(objectNamed) - could not convert to Double]")
    return 0;
}

func SMNumberInDictionaryToInt(someDictionary:NSDictionary, objectNamed:String) -> Int
{
    let someNumber:NSNumber? = someDictionary.objectForKey(objectNamed) as? NSNumber
    if someNumber != nil {
        return someNumber!.integerValue
    }
    
    print("[Could not find number named \(objectNamed) - could not convert to Int]")
    return 0;
}

/** COLOR **/

func SMColorFromRGBA( r:Int, g:Int, b:Int, a:Int ) -> UIColor
{
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

func SMColorFromRGB( r:Int, g:Int, b:Int ) -> UIColor
{
    return SMColorFromRGBA(r, g: g, b: b, a: 255)
}

func SMColorFromUnsignedCharRGBA( r:Int, g:Int, b:Int, a:Int ) -> UIColor
{
    return SMColorFromRGBA(r, g: g, b: b, a: a)
}

func SMColorFromUnsignedCharRGB( r:Int, g:Int, b:Int ) -> UIColor
{
    return SMColorFromUnsignedCharRGBA(r, g: g, b: b, a: 255);
}

/** STRINGS **/

/*
 This function exists because the actual method to calculate String lengths in Swift changes every so often.
 At one point it required a function named countElements(), and then changed to String.characters.length
 
 Before it changes again, I just made a function to encapsulate it and will just call this function instead
*/
func SMStringLength( theString:String ) -> Int{
    let theLength = theString.characters.count
    
    return theLength
}

func SMStringCharacterAtIndex( theString:String, indexPosition:Int ) -> Character {
    let index = theString.characters.startIndex.advancedBy(indexPosition)
    let theCharacter = theString.characters[index]
    
    return theCharacter
}

/** FILENAME/BUNDLE FUNCTIONS **/


 /*
 Pass in a filename. If the filename has an extension (like ".png") then the extension is removed.
 Otherwise, the string is just returned normally if no extension is detected.
 
 input - string with filename
 extension - OPTIONAL extension (such as ".png" or ".jpg") ... you can just pass in "" if you don't want to bother
 */
func SMStringFilenameWithoutExtension( input:String, theExtension:String ) -> String {
    
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
        let substring = inputAsNSString.substringToIndex(expectedPositionOfPeriod)
        
        return (substring as String)
    }
    
    return input
}

/*
Pass in a filename; the filename is separated into the "name" and the extension. For example, if you pass in
"image.jpg" then you get an array where index 0 is "image" and index 1 is "jpg"
*/
func SMStringArrayWithFilenameAndExtension( filename:String ) -> [String]
{
    if SMStringLength(filename) < 1 {
        return [""]
    }
    
    let theArray = filename.componentsSeparatedByString(".")
    
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
func SMStringURLFromFilename( filename:String ) -> NSURL?
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
    
    let theURL = NSBundle.mainBundle().URLForResource(nameForFile, withExtension: extensionForFile)
    
    return theURL
}


/** AUDIO **/


/*
Enter filename for audio file, get an AVAudioPlayer object (can be played as a sound effect,
or set to infinite loop (-1) for use as background music.
*/
func SMAudioSoundFromFile( filename:String ) -> AVAudioPlayer?
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
        try audio = AVAudioPlayer(contentsOfURL: url!)
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
 
// Retrieve String from dictionary
func SMStringFromDictionary( dict:NSDictionary, nameOfObject:String) -> String
{
    let str:String? = dict.objectForKey(nameOfObject) as? String
    if( str == nil ) {
        return ""
    }
    
    return str!
}

// Retrieve NSNumber from dictionary
func SMNumberFromDictionary( dict:NSDictionary, nameOfObject:String ) -> NSNumber
{
    let number:NSNumber? = dict.objectForKey(nameOfObject) as? NSNumber
    if( number == nil ) {
        return NSNumber(integer: 0);
    }
    
    return number!
}


func SMIntFromDictionary( dict:NSDictionary, nameOfObject:String ) -> Int {
    return SMNumberFromDictionary(dict, nameOfObject: nameOfObject).integerValue
}
func SMBoolFromDictionary( dict:NSDictionary, nameOfObject:String ) -> Bool {
    return SMNumberFromDictionary(dict, nameOfObject: nameOfObject).boolValue
}
func SMFloatFromDictionary( dict:NSDictionary, nameOfObject:String ) -> Float {
    return SMNumberFromDictionary(dict, nameOfObject: nameOfObject).floatValue
}
func SMDoubleFromDictionary( dict:NSDictionary, nameOfObject:String ) -> Double {
    return SMNumberFromDictionary(dict, nameOfObject: nameOfObject).doubleValue
}

