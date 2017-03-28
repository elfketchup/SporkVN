//
//  SMRecord.h
//
//  Created by James Briones on 2/5/11.
//  Copyright 2011. All rights reserved.
//

import Foundation
import UIKit

/*

SMRecord

This class works by storing game data in NSUserDefaults. There are two types of data; the "global" data
that remains the same across all saved games / new games, and then the data that's stored inside "slots"
and is only relevant within a particular playthrough of the game.

The "global" relevant-across-all-playthroughs data is just stored in NSUserDefault's "root" dictionary
as either NSString or NSNumber objects. Conversely, an entire slot is stored as a single NSData object
in the root dictionary. Each slot can be accessed through the dictionary key "slotX", where X is the
number.

The main Global values are:
1. HIGH SCORE (NSUInteger) - The highest score achieved by a player
2. DATE SAVED (NSDate object) - Time and date of most recent saved game
3. CURRENT SLOT (NSUInteger) - Which save slot was most recently used

Slot Zero ("slot0") is the default slot, and is meant mostly for autosave data. If you're creating a game
where it's not necessary to have multiple slots/games/playthroughs, then you can just store everything
in Slot Zero. On the other hand, some other game types (such as, say, JRPGs) might require multiple slots.
There is no hard-coded limit on the number of slots you can use.

Each slot is an NSData object, which can be decoded into a single NSDictionary (or more practically,
an NSMutableDictionary) called the Record, which holds the following values:

1. ACTIVITY TYPE (NSString) - What kind of activity the player was engaged in when the game was saved
(a specific mini-game, cutscene, etc)
2. ACTIVITY DICTIONARY (NSDictionary) - Stores information specific to that activity (sprite positions, score, etc)
3. FLAG DATA (NSDictionary) - A dictionary of flags (each flag is a key that corresponds to an int value)

An Activity is a particular task/mini-game that the player is involved with. This could be a particular level
in the game, a dialogue/cutscene sequence, a mini-game, traversing a map of the world, etc. The Activity Dictionary
holds information specific to an Activity type, such as mini-game scores, locations of sprites, level data, etc.
When the game is saved, the player's current Activity should save any relevant data, and when the game is loaded,
that same data is supposed to recreate the Activity exactly as the player left it (or something close enough
that the player shouldn't complain too much!)

Flags are information not specific to a particular activity, but can instead be used throughout a particular
playthrough of the game. For example, relationships scores in regards to other characters, progress through
a story, experience points and money, etc. In theory, as long as anything can be stored as an integer value
and is used throughout the playthrough, it can be stored as a flag. (It's also possible to store flags with
non-integer data, but ints are the standard value type... nevertheless, if you want to use another data
type entirely, that can be done).

Since the Record can be accessed by any class that knows of SMRecord, it's also possible to add further data,
in case the combination of Flags and Activity data isn't enough. It's not "officially" supported, but it can
certainly be done.

SMRecord is meant to be used as a singleton, and having multiple SMRecord objects in existence may lead to
unknown/untested behaviors, especially since they all write data to the same NSUserDefaults dictionary.

In the future, functionality for saving to iCloud or to actual files (as opposed to NSUserDefaults) may be
added, but for now SMRecord works well enough.

*/

let SMRecordAutosaveSlotNumber      = 0   // ZERO is the autosave slot (slots 1 and above being "normal" save slots)

// These are keys for the "global" values in the record,
let SMRecordHighScoreKey            = "the high score"   // Highest score achieved by anyone playing the game on this device
let SMRecordDateSavedKey            = "date saved"       // The last time any data was saved on this device
let SMRecordCurrentSlotKey          = "current slot"     // The most recently used slot
let SMRecordUsedSlotNumbersKey      = "used slots array" // Lists all the arrays used so far

// Keys for data that's specific to a particular playthrough and is stored inside of individual "slots" (which contain a single
// NSData object that encapsulates all the other playthrough-specific data)
let SMRecordDataKey                 = "record"               // THe NSData object that holds the dictionary with all the other saved-game data
let SMRecordCurrentScoreKey         = "current score"        // NSUInteger of the player's current score
let SMRecordFlagsKey                = "flag data"            // Key for a dictionary of "flag" data
let SMRecordDateSavedAsString       = "date saved as string" // A string with a more human-readable version of the NSDate object
let SMRecordSpriteAliasesKey	    = "sprite aliases"       // stores all sprite aliases in use by the game 

// Keys for activity data
let SMRecordCurrentActivityDictKey  = "current activity" // Used to locate the activity data in the User Defaults
let SMRecordActivityTypeKey         = "activity type" // Is this a VNScene, or some other kind of CCScene / activity type?
let SMRecordActivityDataKey         = "activity data" // This will almost always be a dictionary with activity-specific data


private let SMRecordSharedInstance = SMRecord()


class SMRecord {
    
    // Singleton access; call SMRecords.sharedRecord
    class var sharedRecord:SMRecord {
        return SMRecordSharedInstance
    }
    
    var record      = NSMutableDictionary(capacity: 1)
    var currentSlot = Int(0)
    
    
    /** UTILITY FUNCTIONS **/
    
    
    // Convert a NSDate value into an easily-readable string value
    func stringFromDate(_ dateObject:Date) -> NSString {
        
        let format:DateFormatter = DateFormatter()
        
        //format.dateFormat = "h:mm a',' yyyy'-'MM'-'dd" // Example: "12:34 AM, 2013-02-10"
        format.dateFormat = "yyyy'-'MM'-'dd',' h:mm a" // Example: "2014-11-11, 12:29 PM"
        let formattedDate:NSString = format.string(from: dateObject) as NSString
        
        return formattedDate
    }
    
    // Set all time/date information in a save slot to the current time.
    func updateDateInDictionary(_ dict:NSDictionary) {
        
        // Get the current time, and then create a string displaying a human-readable version of the current time
        let theTimeRightNow:Date = Date() //[NSDate date];
        print("DIAGNOSTIC: Current date is \(theTimeRightNow)")
        
        let stringWithCurrentTime:NSString = stringFromDate(theTimeRightNow)
        
        // Set date information in the dictionary
        dict.setValue(theTimeRightNow, forKey:SMRecordDateSavedKey)            // Save NSDate object
        dict.setValue(stringWithCurrentTime, forKey:SMRecordDateSavedAsString) // Save human-readable string
    }
    
    // Create new save data for a brand new game. The dictionary has no "real" data, but has several placeholders
    // where actual data can be written into. So it's not really an "empty" record, but just a brand-new one?
    func emptyRecord() -> NSMutableDictionary {
        
        //NSMutableDictionary* tempRecord = [NSMutableDictionary dictionary];
        let tempRecord = NSMutableDictionary()
        
        // Fill the record with default data
        tempRecord.setValue(NSNumber(value: 0), forKey:SMRecordCurrentScoreKey) // No score yet, since this is a new game
        updateDateInDictionary(tempRecord)                      // Set current date as "the time when this was saved"
        resetActivityInformationInDict(tempRecord)              // Fill the activity dictionary with dummy data
        
        // Create a flags dictionary with some default "dummy" data in it
        let tempFlags:NSMutableDictionary = NSMutableDictionary(object: "dummy value", forKey: "dummy key" as NSCopying)
        tempRecord.setValue(tempFlags, forKey:SMRecordFlagsKey) // Load the flags dictionary into the record
        
        return tempRecord // Used to be something like NSDictionary(dictionary: tempRecord) ... dunno if that works better
    }
    
    // This "resets" SMRecord so that it will have brand-new data (as in a fresh saved game). HOWEVER it doesn't attept to save
    // any previous data that might have existed... if you want to be sure that previous save data is actually saved, you'll have
    // to call those functions yourself!
    func startNewRecord()
    {
        record = NSMutableDictionary(dictionary: emptyRecord())
        UserDefaults.standard.setValue(currentSlot, forKey: SMRecordCurrentSlotKey)
    }
    
    func hasAnySavedData() ->Bool {
        
        var result = true; // At first, assume that there IS saved data. The rest of the function will check if this assumption is false!
        
        // This function will check if any of the following objects are missing, since a successful save should have put all of this into device memory
        let lastSavedDate:Date? = UserDefaults.standard.object(forKey: SMRecordDateSavedKey) as? Date
        let usedSlotNumbers:NSArray? = arrayOfUsedSlotNumbers()
        
        if( lastSavedDate == nil || usedSlotNumbers == nil ) {
            result = false;
        }
        
        return result;
    }
    
    /** PROPERTIES **/
    
    // Returns the flags dictionary that's stored in the record... assuming that the record exists, that is!
    // (If the record does exist, then the flags dictionary should also exist inside it too)
    func flags() -> NSMutableDictionary {
        
        if( record.count < 0 ) {
            startNewRecord()
        }
        
        let allMyFlags:NSMutableDictionary? = record.object(forKey: SMRecordFlagsKey) as? NSMutableDictionary
        
        if( allMyFlags != nil ) {
            return allMyFlags!
        }
        
        // In this case, there are no flags at all, so create a new dictionary and just return that
        let emptyFlags = NSMutableDictionary(object: "dummy value", forKey: "dummy key" as NSCopying)
        record.setValue(emptyFlags, forKey: SMRecordFlagsKey)
        return emptyFlags
    }
    
    // Set the "flags" mutable dictionary in the record. If there's no record, it just gets created on the fly
    func setFlags(_ updatedFlags:NSMutableDictionary) {
        
        if record.count < 1 {
            record = emptyRecord()
        }
        
        // Flags will only get updated if the dictionary is valid
        record.setValue(updatedFlags, forKey: SMRecordFlagsKey)
    }
    
    // Retrieve sprite alias data rom record and return it in a mutable dictionary
    func spriteAliases() -> NSMutableDictionary {
        // check if the dictionary already exists, and if so, return it
        let s:NSMutableDictionary? = record.object(forKey: SMRecordSpriteAliasesKey) as? NSMutableDictionary
        if s != nil {
            return s!
        }
        
        // otherwise, the dictionary will have to be created inside of the record
        let aliasDictionary = NSMutableDictionary()
        record.setValue(aliasDictionary, forKey:SMRecordSpriteAliasesKey)
        
        return aliasDictionary
    }
    
    func setSpriteAliases(_ updatedAliases:NSMutableDictionary) {
        if record.count < 0 {
           self.startNewRecord()
        }
        
        record.setValue(updatedAliases, forKey:SMRecordSpriteAliasesKey)
    }
    
    /** Slots tracking **/
    
    // This grabs an NSArray (filled with NSNumbers) from NSUserDefaults. The array keeps track of which "slots" have saved game information stored in them.
    func arrayOfUsedSlotNumbers() -> NSArray? {
        
        // The array is considered a "global" value (that is, the same value is stored across multiple playthrough/saved-games)
        // so it would be found under the root dictionary of NSUserDefaults for this app.
        let deviceMemory:UserDefaults = UserDefaults.standard //[NSUserDefaults standardUserDefaults];
        let tempArray:NSArray? = deviceMemory.object(forKey: SMRecordUsedSlotNumbersKey) as? NSArray
        
        if( tempArray == nil ) {
            print("[SMRecord] Cannot find a previously existing array of used slot numbers.");
            return nil
        }
        
        return tempArray
    }
    
    // This just checks if a particular slot number has been used (reminder: the "autosave" slot is slot ZERO)
    func slotNumberHasBeenUsed(_ slotNumber:Int) -> Bool {
        
        var result = false // Assume NO by default; this gets changed if data proves otherwise
        
        // Check if there's any slot number data at all. If there isn't, then obviously none of the slot numbers have been used.
        let slotsUsed:NSArray? = arrayOfUsedSlotNumbers()
        if( slotsUsed == nil || slotsUsed!.count < 1 ) {
            return result
        }
        
        // The following loop checks every single index in the array and examines if the NSNumber stored within holds the value as the slot number we're checking for.
        //for( var i = 0; i < slotsUsed!.count; i += 1 ) {
        //for( var i = 0; i < slotsUsed!.count; i += 1 ) {
        for i in 0 ..< slotsUsed!.count {
            
            let currentNumber:NSNumber = slotsUsed!.object(at: i) as! NSNumber
            let valueOfCurrentNumber:Int = currentNumber.intValue
            
            // Check if the value that was found matches the value that was expected
            if( valueOfCurrentNumber == slotNumber ) {
                print("[SMRecord] Match found for slot number \(slotNumber) in index \(i)")
                result = true; // This slot number has indeed been used
            }
        }
        
        return result;
    }
    
    // This adds a particular value to the list of used slot numbers.
    func addToUsedSlotNumbers(_ slotNumber:Int) {
        
        print("[SMRecord] Will now attempt to add \(slotNumber) to array of used slot numbers.")
        let numberWasAlreadyUsed:Bool = slotNumberHasBeenUsed(slotNumber)
        
        // If the number has already been used, then there's no point adding another mention of it; that would
        // up more memory to tell SMRecord something that it already knows. Information will only be added
        // if the slot number in question hasn't been used yet.
        if( numberWasAlreadyUsed == false ) {
            
            print("[SMRecord] Slot number \(slotNumber) has not been used previously.")
            let slotNumbersArray:NSMutableArray = NSMutableArray() //[[NSMutableArray alloc] init];
            
            // Check if there was any previous data. If there was, then it'll be added to the new array. If not... well, it's not a big deal!
            let previousSlotsArray:NSArray? = arrayOfUsedSlotNumbers()
            if( previousSlotsArray != nil ) {
                //[slotNumbersArray addObjectsFromArray:previousSlotsArray];
                slotNumbersArray.addObjects(from: previousSlotsArray! as [AnyObject])
            }
            
            // Add the slot number that was passed in to the newly-created array
            //[slotNumbersArray addObject:@(slotNumber)];
            slotNumbersArray.add(NSNumber(value: slotNumber))
            
            // Create a regular non-mutable NSArray and store the data there
            let unmutableArray:NSArray = NSArray(array: slotNumbersArray) //[[NSArray alloc] initWithArray:slotNumbersArray];
            let deviceMemory:UserDefaults = UserDefaults.standard // Pointer to NSUserDefaults
            //[deviceMemory setObject:unmutableArray forKey:SMRecordUsedSlotNumbersKey]; // Store the updated array in NSUserDefaults
            deviceMemory.setValue(unmutableArray, forKey: SMRecordUsedSlotNumbersKey)
            print("[SMRecord] Slot number \(slotNumber) saved to array of used slot numbers.")//, (unsigned long)slotNumber);
        }
    }
    
    /** SCORE PROPERTIES **/
    
    // Sets the high score (stored in NSUserDefaults)
    func setHighScore(_ highScoreValue:Int) {
        
        // Remember that the High Score is a global value and should be stored directly in NSUserDefaults instead of the slot/record section
        let theUserDefaults = UserDefaults.standard
        let theHighScore = NSNumber(value: highScoreValue) // Used to be unsigned, now regularly signed (theoretically a 64-bit integer)
        theUserDefaults.setValue(theHighScore, forKey: SMRecordHighScoreKey)
        
        /** WARNING: For some reason, the high score isn't being saved to NSUserDefaults anymore, so for now I'm
        saving it into the record along with normal data. **/
        
        record.setValue(theHighScore, forKey: SMRecordHighScoreKey)
    }
    
    // Retrieve high score value (if any; otherwise returns zero if no data was found)
    func highScore() -> Int {
        
        var result:Int = 0; // The default value for the "high score" is zero
        
        // Try to get data from NSUserDefaults. Keep in mind that the High Score is a "global" value, and is shared across
        // multiple playthroughs (and so isn't something that can be kept in a particular slot/record), so it wouldn't be
        // stored in the slot/record like almost everything else.
        //NSNumber* highScoreFromRecord = [[NSUserDefaults standardUserDefaults] objectForKey:SMRecordHighScoreKey];
        //var highScoreFromRecord:NSNumber? = NSUserDefaults.standardUserDefaults().objectForKey(SMRecordHighScoreKey) as? NSNumber
        
        let theHighScore:NSNumber? = record.object(forKey: SMRecordHighScoreKey) as? NSNumber
        
        // It's entirely possible that no high score has been saved yet (either because this is a brand-new game
        // and nothing has been saved yet, or if the game just doesn't really bother with high score data), so it's
        // important to check if a valid value was returned.
        //if( highScoreFromRecord != nil ) {
        if theHighScore != nil {
            
            // Update 'result' with some actual data
            result = theHighScore!.intValue
        } else {
            print("[SMRecord] WARNING: High score could not retrieved.")
        }
        
        return result;
    }
    
    // Sets the current score. Unlike the High Score, the Current Score IS stored in the record/slot section.
    func setCurrentScore(_ scoreValue:Int) {
        
        // If there's no current record, then just create one on the fly (and hope it works out!)
        if( record.count < 1 ) {
            //record = [[NSMutableDictionary alloc] initWithDictionary:[self emptyRecord]];
            record = emptyRecord()
        }
        
        // Store the current score as an NSNumber in the record
        record.setValue(NSNumber(value: scoreValue), forKey:SMRecordCurrentScoreKey)
    }
    
    // This will return the current score for this playthrough. If there isn't any record (or there's no scoring data
    // in the record), then it will just return a zero.
    func currentScore() -> Int {
        
        var result:Int = 0; // Assume zero by default
        
        if( record.count > 0 ) {
            
            let scoreFromRecord:NSNumber? = record.object(forKey: SMRecordCurrentScoreKey) as? NSNumber
            
            if( scoreFromRecord != nil ) {
                result = scoreFromRecord!.intValue
            }
        }
        
        return result;
    }
    
    /** LOADING DATA **/
    
    // Load NSData from a "slot" stored in NSUserDefaults / device memory.
    func dataFromSlot(_ slotNumber:Int) -> Data? {
        
        let deviceMemory:UserDefaults = UserDefaults.standard   // Pointer to where memory is stored in the device
        let slotKey = NSString(string: "slot\(slotNumber)") // Generate name of the dictionary key where save data is stored
        
        print("[SMRecord] Loading record from slot named [\(slotKey)]")
        
        // Try to load the data from the slot that should be stored in the device's memory.
        let slotData:Data? = deviceMemory.object(forKey: slotKey as String) as? Data
        if( slotData == nil ) {
            print("[SMRecord] ERROR: No data found in slot number \(slotNumber)")
            return nil;
        }
        
        // Note how large the data is
        print("[SMRecord] 'dataFromSlot' has loaded an NSData object of size \(slotData!.count) bytes.")
        
        //return [NSData dataWithData:slotData];
        return (NSData(data: slotData!) as Data)
    }
    
    // Load a dictionary with game record from an NSData object (which was loaded from memory)
    func recordFromData(_ data:Data) -> NSDictionary? {
        
        // Unarchive the information from NSData into NSDictionary
        let unarchiver:NSKeyedUnarchiver = NSKeyedUnarchiver(forReadingWith: data)
        let dictFromData:NSDictionary? = unarchiver.decodeObject(forKey: SMRecordDataKey) as? NSDictionary
        
        if( dictFromData == nil ) {
            print("[SMRecord] Can't retrieve record from data object.")
            return nil
        }
        
        unarchiver.finishDecoding()
        
        return NSDictionary(dictionary: dictFromData!)
    }
    
    // Load saved game data from a slot
    func recordFromSlot(_ slotNumber:Int) -> NSDictionary? {
        
        let loadedData:Data? = dataFromSlot(slotNumber)
        if( loadedData == nil ) {
            return nil
        }
        
        //NSData* loadedData = [self dataFromSlot:slotNumber];
        //return [self recordFromData:loadedData];
        
        return recordFromData(loadedData!)
    }
    
    // This attempts to load a record from the "current slot," which is slotXX (where XX is whatever the heck 'self.currentSlot' is).
    // If this sounds kind of vague and unhelpful... well, I suppose that says something about this function! :P
    //- (void)loadRecordFromCurrentSlot
    func loadRecordFromCurrentSlot() {
        
        let tempDict:NSDictionary? = recordFromSlot(self.currentSlot) // Load temporary dictionary from a particular slot in device memory
        if( tempDict != nil ) { // Dictionary has valid data
            
            // Copy record data from device memory
            //record = [[NSMutableDictionary alloc] initWithDictionary:tempDict];
            record = NSMutableDictionary(dictionary: tempDict!)
            print("[SMRecord] Record was successfully loaded from slot \(self.currentSlot)")
            
        } else { // No valid data in dictionary
            
            // Error
            print("[SMRecord] ERROR: Could not load record from slot \(self.currentSlot)")
        }
    }
    
    /*
 	   Opens a PLIST file and copies all items in it to EKRecord as flags.
 
       Can choose whether or not to overwrite existing flags that have the same names.
    */
    func addFlagsFromFile(_ filename:String, overrideExistingFlags:Bool) {
        let rootDictionary = SMDictionaryFromFile(filename)
        if rootDictionary == nil {
            print("[EKRecord] WARNING: Could not load flags as the dictionary file could not be loaded.")
            return;
        }
    
        if overrideExistingFlags == true {
            print("[EKRecord] DIAGNOSTIC: Will forcibly overwrite existing flags with flags from file: \(filename)")
        } else {
            print("[EKRecord] DIAGNOSTIC: Will add flags (without overwriting) from file named: \(filename)")
        }
        
        for key in rootDictionary!.allKeys {
            
            let value = rootDictionary!.object(forKey: key)
            
            //let value = rootDictionary!.objectForKey(key) as? AnyObject
            
            if overrideExistingFlags == true {
                self.setFlagValue(value! as AnyObject, nameOfFlag: key as! String)
                //self.setFlagValue(value!, forFlagNamed:key)
            } else {
                let existingFlag = self.flagNamed(key as! String)
                if existingFlag == nil {
                    //self.setValue(value!, forFlagNamed:key as! String)
                    setFlagValue(value! as AnyObject, nameOfFlag: key as! String)
                }
            }
        }
    } // end function
    
    /** SAVING DATA **/
    
    // Create an NSData object from a game record
    func dataFromRecord(_ dict:NSDictionary) -> Data {
        
        // Update the date/time information in the record to "right now."
        //[self updateDateInDictionary:dict];
        updateDateInDictionary(dict)
        
        // Encode the dictionary into NSData format
        let data:NSMutableData = NSMutableData() //[[NSMutableData alloc] init];
        let archiver:NSKeyedArchiver = NSKeyedArchiver(forWritingWith: data)
        //[archiver encodeObject:dict forKey:SMRecordDataKey];
        archiver.encode(dict, forKey: SMRecordDataKey)
        archiver.finishEncoding() //[archiver finishEncoding];
        
        // Just note the size of the data object
        print("[SMRecord] 'dataFromRecord' has produced an NSData object of size \(data.length) bytes.")//, (unsigned long)data.length);
        
        //return [NSData dataWithData:data];
        return (NSData(data: data as Data) as Data)
    }
    
    // Saves NSData object to a particular "slot" (which is located in NSUserDefaults's root dictionary)
    func saveData(_ data:Data, slotNumber:Int) {
        
        // Store the NSData object into NSUserDefaults, under the key "slotXX" (XX being whatever value 'slotNumber' is)
        let deviceMemory:UserDefaults = UserDefaults.standard
        let stringWithSlotNumber:NSString = NSString(string: "slot\(slotNumber)") // Dictionary key for slot
        deviceMemory.setValue(data, forKey: stringWithSlotNumber as String) // Store data in NSUserDefaults dictionary
        addToUsedSlotNumbers(slotNumber)
        //[self addToUsedSlotNumbers:slotNumber]; // Flag this slot number as being used
    }
    
    // This just checks if the current score is higher than the "high score" saved in NSUserDefaults. If that's the case, then
    // the high score is set to the current score's value.
    func updateHighScore() {
        
        // Try to get the scores. If, for some reason, there isn't any actual score data, then they'll just be set to zero
        let theCurrentScore = currentScore() //[self currentScore];
        let theHighScore = highScore()
        
        // Save the current score if it's higher than the High Score that's been saved
        if( theCurrentScore > theHighScore ) {
            setHighScore(theCurrentScore)
        }
        
        UserDefaults.standard.synchronize()
    }
    
    // If SMRecord is storing any data, then it will get stored to device memory (NSUserDefaults). The slot number being used
    // would be whatever 'currentSlot' has as its value.
    func saveCurrentRecord()
    {
        if( record.count < 1 ) {
            print("[SMRecord] ERROR: No record data exists.");
            return;
        }
        
        // Update global data
        let deviceMemory:UserDefaults = UserDefaults.standard
        let theDateToday = Date()
        //println("DIAGNOSTIC: The current date to be saved in the record is: \(theDateToday)")
        deviceMemory.setValue(theDateToday, forKey: SMRecordDateSavedKey)
        let theSlotToUse = NSNumber(value: currentSlot)
        deviceMemory.setValue(theSlotToUse, forKey: SMRecordCurrentSlotKey)
        
        // Update record information
        updateDateInDictionary(record)
        updateHighScore()
        
        let recordAsData:Data = dataFromRecord(record)
        saveData(recordAsData, slotNumber: self.currentSlot)
        
        //println("[SMRecord] saveCurrentRecord - Record has been saved.");
    }
    
    /** INITIALIZATION CODE **/
    
    init() {
        
        // Set default values
        setHighScore(0) //    self.highScore = 0;
        currentSlot = SMRecordAutosaveSlotNumber // ZERO
        
        let userDefaults:UserDefaults = UserDefaults.standard
        let lastSavedSlot:NSNumber? = userDefaults.object(forKey: SMRecordCurrentSlotKey) as? NSNumber
        
        // If a slot number was found, then just get that value and overwrite the default slot number
        if( lastSavedSlot != nil ) {
            self.currentSlot = lastSavedSlot!.intValue//[lastSavedSlot unsignedIntegerValue];
            print("[SMRecord] Current slot set to \(self.currentSlot), which was the value stored in memory.")
        }
        
        // If there's any previously-saved data, then just load that information. If there is NO previously-saved data, then just do nothing.
        // The reasoning here is that if there's previously-saved data, then it should be loaded by default (if the app or player wants to create
        // all new data, they can just do that manually). If no record exists, then it will be created either automatically once the app starts
        // trying to write flag data. Of course, it can also be created manually (like when a new game begins, SMRecord can be told to just
        // create a new record.
        //if( [self hasAnySavedData] == YES ) {
        if( hasAnySavedData() == true ) {
            
            // Display all used slots (this is actually meant for diagnostic/testing purposes)
            //NSArray* allUsedSlots = [self arrayOfUsedSlotNumbers];
            let allUsedSlots:NSArray? = arrayOfUsedSlotNumbers()
            if( allUsedSlots != nil ) {
                print("[SMRecord] The following slots are in use: \(String(describing: allUsedSlots))")
            }
            
            // Load the data from the current slot (which is the one with the most recent save data)
            //[self loadRecordFromCurrentSlot];
            loadRecordFromCurrentSlot()
            
            // Log success or failure
            if( record.count > 0 ) {
                print("[SMRecord] Record initialized with data: \(record)")
            } else {
                print("[SMRecord] Failed to initialize saved game data.");
            }
        }
    }
    
    /** SPRITE ALIASES **/
    
    func resetAllSpriteAliases() {
        let dummyAliases = NSMutableDictionary()
        dummyAliases.setValue("dummy sprite alias value", forKey:"dummy alias key");
        self.setSpriteAliases(dummyAliases)
    }
    
    func addExistingSpriteAliases(_ existingAliases:NSDictionary) {
        if existingAliases.count > 0 {
            let spriteAliasDictionary = self.spriteAliases()
            SMDictionaryAddEntriesFromAnotherDictionary(spriteAliasDictionary, source: existingAliases)
        }
    }
    
    func setSpriteAlias(_ nameOfAlias:String, updatedValue:String) {
        if SMStringLength(nameOfAlias) < 1 || SMStringLength(updatedValue) < 1 {
            return
        }
        
        let s = self.spriteAliases()
        s.setValue(updatedValue, forKey:nameOfAlias)
    }
    
    func spriteAliasNamed(_ nameOfAlias:String) -> String? {
        if record.count < 1 {
            return nil
        }
        
        let s = self.spriteAliases()
        let a = s.object(forKey: nameOfAlias) as? String
        
        return a
    }
    
    /** FLAGS **/
    
    // This removes any existing flag data and overwrites it with a blank dictionary that has dummy values
    func resetAllFlags() {
        // Create a brand-new dictionary with nothing but dummy data
        //NSMutableDictionary* dummyFlags = [[NSMutableDictionary alloc] init];
        //[dummyFlags setValue:@"dummy value" forKey:@"dummy key"];
        let dummyFlags = NSMutableDictionary()
        dummyFlags.setValue(NSString(string: "dummy value"), forKey: "dummy key")
        
        // Set this "dummy data" dictionary as the flags data
        //[self setFlags:dummyFlags];
        setFlags(dummyFlags)
    }
    
    // Adds a dictionary of flags to the Flags data stored in SMRecord
    func addExistingFlags(_ existingFlags:NSDictionary) {
        
        // Check if there's not really any data to add
        if( existingFlags.count < 1 ) {
            return;
        }
        
        // Check if no record data exists. If that's the case, then start a new record.
        if( record.count < 1 ) {
            //[self startNewRecord];
            startNewRecord()
        }
        
        // Add these new dictionary values to any existing flag data
        let flagsDictionary:NSMutableDictionary? = flags()
        
        // Check if the flags dictionary exists or not (it should)
        if( flagsDictionary != nil ) { // Flags dictionary DOES exist
            
            // Just add the 'existingFlags' values to the current flags dictionary
            flagsDictionary!.addEntries(from: existingFlags as! [AnyHashable: Any])
            
        } else { // Flags dictionary does NOT exist (unlikely)
            
            // Convert the 'existingFlags' dict to a mutable dictionary and set that as the new "flags" dictionary
            let dictOfExistingFlags:NSMutableDictionary = NSMutableDictionary(dictionary: existingFlags)
            setFlags(dictOfExistingFlags)
        }
    }
    
    func flagNamed(_ nameOfFlag:String) -> AnyObject? {
        
        // Check if the record exists
        if( record.count > 0 ) {
            
            let flagsDict:NSDictionary? = flags()
            if( flagsDict != nil ) {
                
                return flagsDict!.object(forKey: nameOfFlag) as AnyObject?
            }
        }
        
        return nil // Returns nil if there's no record or no flags dictionary
    }
    
    // Return the int value of a particular flag. It's important to keep in mind though, that while flags by default
    // use int values, it's entirely possible that it might use something entirely different. It's even possible to use
    // completely different types of objects (say, UIImage) as a flag value.
    func valueOfFlagNamed(_ flagName:String) -> Int {
        
        var result:Int = 0;
        let theFlag:NSNumber? = flagNamed(flagName) as? NSNumber
        
        // Check if any data was actually retrieved AND that this holds a number value (as opposed to, say, UIImage or
        // some entirely different type of class).
        if( theFlag != nil ) { //[theFlag isKindOfClass:[NSNumber class]]) {
            
            // Check in case this isn't a number, and make note of it
            if theFlag!.isKind(of: NSNumber.self) == false {
                print("[SMRecord] WARNING: In [valueOfFlagNamed], the flag retrieved is not a number type.")
            }
            
            result = theFlag!.intValue
        }
        
        // If a flag was found, it will return that value. If no flag was found, then it will just return zero.
        return result;
    }
    
    // Sets the value of a flag
    func setFlagValue(_ flagValue:AnyObject, nameOfFlag:String) {
        
        // Create valid record if one doesn't exist
        if( record.count < 1 ) {
            startNewRecord()
        }
        
        // Update flags dictionary with this value
        let theFlags:NSMutableDictionary? = flags()
        if( theFlags != nil ) {
            theFlags!.setValue(flagValue, forKey: nameOfFlag)
        }
        
        //[[self flags] setValue:flagValue forKey:nameOfFlag];
    }
    
    // Sets a flag's int value. If you want to use a non-integer value (or something that's not even a number to begin with),
    // then you shoule switch to 'setFlagValue' instead.
    func setIntegerValue(_ iValue:Int, nameOfFlag:String) {
        
        
        // Convert int to NSNumber and pass that into the flags dictionary
        let tempValue:NSNumber = NSNumber(value: iValue)
        setFlagValue(tempValue, nameOfFlag: nameOfFlag)
        
        //NSNumber* tempValue = [NSNumber numberWithInteger:iValue];
        //[self setFlagValue:tempValue forFlagNamed:nameOfFlag];
    }
    
    // Adds or subtracts the integer value of a flag by a certain amount (the amount being whatever 'iValue' is).
    func modifyIntegerValue(_ iValue:Int, nameOfFlag:String) {
        
        var modifiedInteger:Int = 0
        
        // Create a record if there isn't one already
        if( record.count < 1 ) {
            startNewRecord()
        }
        
        // Get the value stored in flags, assuming it exists
        let theFlags:NSMutableDictionary? = flags()
        if( theFlags != nil ) {
            
            // Flag exists, get the original value
            let numberObject:NSNumber? = theFlags!.object(forKey: nameOfFlag) as? NSNumber
            if numberObject != nil && numberObject!.isKind(of: NSNumber.self) {
                modifiedInteger = numberObject!.intValue
            }
        }
        
        // Modify the number value
        modifiedInteger = modifiedInteger + iValue;
        let updatedNumber = NSNumber(value: modifiedInteger)
        
        // Update with new value
        setFlagValue(updatedNumber, nameOfFlag: nameOfFlag)
    }
    
    /** ACTIVITY DATA **/
    
    // Sets the activity information in the record
    func setActivityDict(_ activityDict:NSDictionary) {
        
        // Check if there's no data
        if( activityDict.count < 1 ){
            return;
        }
        
        // Check if the record is empty
        if record.count < 1 {
            startNewRecord()
        }
        
        // Store a copy of the dictionary into the record
        let dictionaryToStore = NSDictionary(dictionary: activityDict)
        record.setValue(dictionaryToStore, forKey: SMRecordCurrentActivityDictKey)
    }
    
    // Return activity data from record
    func activityDict() -> NSDictionary
    {
        //NSDictionary* result = nil; // Assume there's no valid data by default
        
        // Check if the record exists, and if so, then try to grab the activity data from it. By default, there should be some sort of dictionary,
        // even if it's just nothing but dummy values.
        if( record.count > 0 ) {
            
            let retrievedDictionary:NSDictionary? = record.object(forKey: SMRecordCurrentActivityDictKey) as? NSDictionary
            if( retrievedDictionary != nil ) {
                return NSDictionary(dictionary: retrievedDictionary!)
            }
        }
        
        // Otherwise, return empty dictionary
        return NSDictionary()
    }
    
    // This just resets all the activity information stored by a particular dictionary back to its default values (that is, "dummy" values).
    // The "dict" being passed in should be a record dictionary of some kind (ideally, the 'record' dictionary stored by SMRecord)
    func resetActivityInformationInDict(_ dict:NSDictionary)
    {
        // Fill out the activity information with useless "dummy data." Later, this data can (and should) be overwritten there's actual data to use
        let informationAboutCurrentActivity = NSMutableDictionary(object: "nil", forKey: "scene to play" as NSCopying)
        let activityDict = NSMutableDictionary(objects: ["nil", informationAboutCurrentActivity],
                                               forKeys: [SMRecordActivityTypeKey as NSCopying, SMRecordActivityDataKey as NSCopying])
        //NSMutableDictionary(objectsAndKeys: "nil", SMRecordActivityTypeKey,
        //    informationAboutCurrentActivity, SMRecordActivityDataKey)
        
        // Store dummy data into record
        dict.setValue(activityDict, forKey: SMRecordCurrentActivityDictKey)
    }
    
    // For saving/loading to device. This should cause the information stored by SMRecord to being put to NSUserDefaults, and then
    // it would "synchronize," so that the data would be stored directly into the device memory (as opposed to just sitting in RAM).
    func saveToDevice()
    {
        print("[SMRecord] Will now attempt to save information to device memory.");
        
        if( record.count > 0 ) {
            print("[SMRecord] Saving record to device memory...");
            
            //[self saveCurrentRecord];
            saveCurrentRecord()
            
            // Now "synchronize" the data so that everything in NSUserDefaults will be moved from RAM into the actual device memory.
            // NSUserDefaults synchronizes its data every so often, but in this case it will be done manually to ensure that SMRecord's data
            // will be moved into device memory.
            //[[NSUserDefaults standardUserDefaults] synchronize];
            let didSync:Bool = UserDefaults.standard.synchronize()
            
            if didSync == false {
                print("[SMRecord] WARNING: Could not synchronize data to device memory.")
            } else {
                print("[SMRecord] Record was synchronized.")
            }
            
        } else if record.count < 1 {
            print("[SMRecord] ERROR: Cannot save information because no record exists.")
        }
    } // end function
} // end class
