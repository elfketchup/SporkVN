//
//  VNSystemCall.swift
//  EKVN Swift
//
//  Created by James on 11/11/14.
//  Copyright (c) 2014 James Briones. All rights reserved.
//

import Foundation

/*

VNSystemCall

This class is built specifically to handle ".SYSTEMCALL" commands that are used in the VN system. These types of commands
are mainly used for game-specific tasks that need to be called/accessed/controlled from within the VN system. Examples
may include autosaving the game, logging diagnostic information, or starting mini-games.

Currently, this class only supports the first two uses, and only at the most basic level. It's recommended that developers
modify/extend this class for their own purposes.

*/

class VNSystemCall {
    
    //- (void)sendCall:(NSArray*)callData
    func sendCall(callData:NSArray) {
        
        if( callData.count < 2 ) {
            return
        }
        
    
        let typeString:NSString = callData.objectAtIndex(0) as! NSString // = [callData objectAtIndex:0];
        let extras:NSArray = callData.objectAtIndex(1) as! NSArray //[callData objectAtIndex:1];
    
        // Check what kind TYPE parameter is
        
        if typeString.caseInsensitiveCompare("nslog") == NSComparisonResult.OrderedSame {
    
            // Use NSLog to record whatever diagnostic data may have been sent from the VN system
            //NSLog(@"[VNSystemCall] %@", [extras objectAtIndex:0]);
            let printout:NSString = extras.objectAtIndex(0) as! NSString
            print("[VNSystemCall] \(printout)")
    
        } else if typeString.caseInsensitiveCompare("autosave") == NSComparisonResult.OrderedSame {
    
            // Do a basic autosave of the VN system
            //[self autosave];
            autosave()
        }
    }
    
    func autosave() {
    
        // Try to get the current VN scene (if it exists)
        //VNScene* currentVNScene = [VNScene currentVNScene];
        //var currentVNScene? = VNScene.sharedScene()
        let currentVNScene:VNScene? = VNScene.sharedScene
    
        // Now check if the scene exists at all
        if( currentVNScene != nil ) {
    
            // Check if the scene can't be saved due to it being created/loaded way too recently
            if( currentVNScene!.wasJustLoadedFromSave == true ) {
    
                print("[VNSystemCall] Cannot autosave; game was just loaded too recently.");
                return;
    
            } else {
    
                // In THEORY, it should be possible to save the game now...
                print("[VNSystemCall] Autosaving...");
                //[currentVNScene saveToRecord]; // Attemp to autosave
                currentVNScene!.saveToRecord()
            }
        }
    }

    
}