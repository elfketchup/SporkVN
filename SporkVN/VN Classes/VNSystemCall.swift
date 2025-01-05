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
@MainActor
class VNSystemCall {
    func sendCall(_ callData:NSArray) {
        if( callData.count < 2 ) {
            return
        }
        let typeString  = callData.object(at: 0) as! NSString
        let extras      = callData.object(at: 1) as! NSArray
        // Check what kind TYPE parameter is
        if typeString.caseInsensitiveCompare("nslog") == ComparisonResult.orderedSame {
            // Use NSLog to record whatever diagnostic data may have been sent from the VN system
            let printout:NSString = extras.object(at: 0) as! NSString
            print("[VNSystemCall] \(printout)")
        } else if typeString.caseInsensitiveCompare("autosave") == ComparisonResult.orderedSame {
            // Do a basic autosave of the VN system
            autosave()
        }
    }
    
    func autosave() {
        // Try and find if there's any actual scene running right now; if your game is purely a visual novel, there should be
        // one, but if you're just adding VNSceneNode on top of a much larger game, then who knows.
        if let currentVNScene = VNSceneNode.sharedScene {
            // Check if the scene can't be saved due to it being created/loaded way too recently
            if( currentVNScene.wasJustLoadedFromSave == true ) {
                // no point auto-saving if the game was just loaded
                print("[VNSystemCall] Cannot autosave; game was just loaded too recently.");
                return;
            } else {
                // In THEORY, it should be possible to save the game now...
                print("[VNSystemCall] Autosaving...");
                currentVNScene.saveToRecord()
            }
        } else {
            print("[VNSystemCall] Cannot autosave, no current VNSceneNode object detected.")
        }
    }

    
}
