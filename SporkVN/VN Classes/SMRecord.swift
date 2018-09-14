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
    
    // MARK: - Initialization
    
    init() {
        // Set default values
        currentSlot = SMRecordAutosaveSlotNumber // ZERO
        let userDefaults:UserDefaults = UserDefaults.standard
        
        // If a slot number was found, then just get that value and overwrite the default slot number
        if let lastSavedSlot = userDefaults.object(forKey: SMRecordCurrentSlotKey) as? NSNumber {
            self.currentSlot = lastSavedSlot.intValue
            print("[SMRecord] Current slot set to \(self.currentSlot), which was the value stored in memory.")
        }
        
        // If there's any previously-saved data, then just load that information. If there is NO previously-saved data, then just do nothing.
        // The reasoning here is that if there's previously-saved data, then it should be loaded by default (if the app or player wants to create
        // all new data, they can just do that manually). If no record exists, then it will be created either automatically once the app starts
        // trying to write flag data. Of course, it can also be created manually (like when a new game begins, SMRecord can be told to just
        // create a new record.
        if self.hasAnySavedData() == true {
            // Display all used slots (this is actually meant for diagnostic/testing purposes)
            if let allUsedSlots = self.arrayOfUsedSlotNumbers() {
                print("[SMRecord] The following slots are in use: \(String(describing: allUsedSlots))")
            }
            
            // Load the data from the current slot (which is the one with the most recent save data)
            self.loadRecordFromCurrentSlot()
            
            // Log success or failure
            if( record.count > 0 ) {
                print("[SMRecord] Record initialized with data: \(record)")
            } else {
                print("[SMRecord] Failed to initialize saved game data.");
            }
        }
    }
    
    // MARK: - Date and time
    
    // Convert a NSDate value into an easily-readable string value
    func stringFromDate(date:Date) -> String {
        let format          = DateFormatter()
        format.dateFormat   = "yyyy'-'MM'-'dd',' h:mm a" // Example: "2014-11-11, 12:29 PM"
        return format.string(from: date)
    }
    
    // Set all time/date information in a save slot to the current time.
    func updateDateInDictionary(dictionary:NSDictionary) {
        // Get the current time, and then create a string displaying a human-readable version of the current time
        let theTimeRightNow:Date    = Date()
        let stringWithCurrentTime   = stringFromDate(date: theTimeRightNow)
        
        // Set date information in the dictionary
        dictionary.setValue(theTimeRightNow,        forKey:SMRecordDateSavedKey)        // Save NSDate object
        dictionary.setValue(stringWithCurrentTime,  forKey:SMRecordDateSavedAsString)   // Save human-readable string
    }
    
    // MARK: - Record
    
    // Create new save data for a brand new game. The dictionary has no "real" data, but has several placeholders
    // where actual data can be written into. So it's not really an "empty" record, but just a brand-new one?
    func emptyRecord() -> NSMutableDictionary {
        let tempRecord = NSMutableDictionary()
        
        // Fill the record with default data
        tempRecord.setValue(NSNumber(value: 0), forKey:SMRecordCurrentScoreKey) // No score yet, since this is a new game
        updateDateInDictionary(dictionary: tempRecord)          // Set current date as "the time when this was saved"
        self.resetActivityInformation(inDictionary: tempRecord) // Fill the activity dictionary with dummy data
        
        // Create a flags dictionary with some default "dummy" data in it
        let tempFlags = NSMutableDictionary(object: "dummy value - empty record", forKey: "dummy key" as NSCopying)
        tempRecord.setValue(tempFlags, forKey:SMRecordFlagsKey) // Load the flags dictionary into the record
        
        return tempRecord // Used to be something like NSDictionary(dictionary: tempRecord) ... dunno if that works better
    }
    
    // This "resets" SMRecord so that it will have brand-new data (as in a fresh saved game). HOWEVER it doesn't attept to save
    // any previous data that might have existed... if you want to be sure that previous save data is actually saved, you'll have
    // to call those functions yourself!
    func startNewRecord() {
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
    
    // MARK - Flags
    
    // Returns the flags dictionary that's stored in the record... assuming that the record exists, that is!
    // (If the record does exist, then the flags dictionary should also exist inside it too)
    func flags() -> NSMutableDictionary {
        if record.count < 0 {
            startNewRecord()
        }
        
        if let allMyFlags = record.object(forKey: SMRecordFlagsKey) as? NSMutableDictionary {
            return allMyFlags
        }
        
        // In this case, there are no flags at all, so create a new dictionary and just return that
        let emptyFlags = NSMutableDictionary(object: "dummy value - flags", forKey: "dummy key" as NSCopying)
        record.setValue(emptyFlags, forKey: SMRecordFlagsKey)
        return emptyFlags
    }
    
    // Set the "flags" mutable dictionary in the record. If there's no record, it just gets created on the fly
    func setFlags(dictionary:NSMutableDictionary) {
        if record.count < 1 {
            record = emptyRecord()
        }
        
        // Flags will only get updated if the dictionary is valid
        record.setValue(dictionary, forKey: SMRecordFlagsKey)
    }
    
    // MARK: - Slot functions
    
    // This grabs an NSArray (filled with NSNumbers) from NSUserDefaults. The array keeps track of which "slots" have
    // saved game information stored in them.
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
    func slotNumberHasBeenUsed(number:Int) -> Bool {
        var result = false // Assume NO by default; this gets changed if data proves otherwise
        
        // Check if there's any slot number data at all. If there isn't, then obviously none of the slot numbers have been used.
        let slotsUsed:NSArray? = arrayOfUsedSlotNumbers()
        if( slotsUsed == nil || slotsUsed!.count < 1 ) {
            return result
        }
        
        // The following loop checks every single index in the array and examines if the NSNumber stored within
        // holds the value as the slot number we're checking for.
        for i in 0 ..< slotsUsed!.count {
            
            let currentNumber:NSNumber = slotsUsed!.object(at: i) as! NSNumber
            let valueOfCurrentNumber:Int = currentNumber.intValue
            
            // Check if the value that was found matches the value that was expected
            if( valueOfCurrentNumber == number ) {
                print("[SMRecord] Match found for slot number \(number) in index \(i)")
                result = true; // This slot number has indeed been used
            }
        }
        
        return result;
    }
    
    // This adds a particular value to the list of used slot numbers.
    func addToUsedSlotNumbers(slotNumber:Int) {
        print("[SMRecord] Will now attempt to add \(slotNumber) to array of used slot numbers.")
        let numberWasAlreadyUsed:Bool = slotNumberHasBeenUsed(number:slotNumber)
        
        // If the number has already been used, then there's no point adding another mention of it; that would
        // up more memory to tell SMRecord something that it already knows. Information will only be added
        // if the slot number in question hasn't been used yet.
        if( numberWasAlreadyUsed == false ) {
            print("[SMRecord] Slot number \(slotNumber) has not been used previously.")
            let slotNumbersArray:NSMutableArray = NSMutableArray() //[[NSMutableArray alloc] init];
            
            // Check if there was any previous data. If there was, then it'll be added to the new array. If not... well, it's not a big deal!
            if let previousSlotsArray = self.arrayOfUsedSlotNumbers() {
                slotNumbersArray.addObjects(from: previousSlotsArray as [AnyObject])
            }
            
            // Add the slot number that was passed in to the newly-created array
            //[slotNumbersArray addObject:@(slotNumber)];
            slotNumbersArray.add(NSNumber(value: slotNumber))
            
            // Create a regular non-mutable NSArray and store the data there
            let unmutableArray:NSArray = NSArray(array: slotNumbersArray) //[[NSArray alloc] initWithArray:slotNumbersArray];
            let deviceMemory:UserDefaults = UserDefaults.standard // Pointer to NSUserDefaults
            deviceMemory.setValue(unmutableArray, forKey: SMRecordUsedSlotNumbersKey)
            print("[SMRecord] Slot number \(slotNumber) saved to array of used slot numbers.")//, (unsigned long)slotNumber);
        }
    }
    
    // MARK: - Score
    
    // Sets the high score (stored in NSUserDefaults)
    func setHighScoreWithInteger(integer:Int) {
        // Remember that the High Score is a global value and should be stored directly in NSUserDefaults instead of the slot/record section
        let theUserDefaults = UserDefaults.standard
        let theHighScore = NSNumber(value: integer) // Used to be unsigned, now regularly signed (theoretically a 64-bit integer)
        theUserDefaults.setValue(theHighScore, forKey: SMRecordHighScoreKey)
        
        /** WARNING: For some reason, the high score isn't being saved to NSUserDefaults anymore, so for now I'm
        saving it into the record along with normal data. **/
        record.setValue(theHighScore, forKey: SMRecordHighScoreKey)
    }
    
    // Retrieve high score value (if any; otherwise returns zero if no data was found)
    func highScore() -> Int {
        var result:Int = 0; // The default value for the "high score" is zero
        
        // It's entirely possible that no high score has been saved yet (either because this is a brand-new game
        // and nothing has been saved yet, or if the game just doesn't really bother with high score data), so it's
        // important to check if a valid value was returned.
        if let theHighScore = record.object(forKey: SMRecordHighScoreKey) as? NSNumber {
            result = theHighScore.intValue // update 'result' with actual data
        } else {
            print("[SMRecord] WARNING: High score could not retrieved.")
        }
        
        return result;
    }
    
    // Sets the current score. Unlike the High Score, the Current Score IS stored in the record/slot section.
    func setCurrentScoreWithInteger(integer:Int) {
        // If there's no current record, then just create one on the fly (and hope it works out!)
        if( record.count < 1 ) {
            //record = [[NSMutableDictionary alloc] initWithDictionary:[self emptyRecord]];
            record = emptyRecord()
        }
        
        // Store the current score as an NSNumber in the record
        record.setValue(NSNumber(value: integer), forKey:SMRecordCurrentScoreKey)
    }
    
    // This will return the current score for this playthrough. If there isn't any record (or there's no scoring data
    // in the record), then it will just return a zero.
    func currentScore() -> Int {
        if( record.count > 0 ) {
            if let scoreFromRecord = record.object(forKey: SMRecordCurrentScoreKey) as? NSNumber {
                return scoreFromRecord.intValue
            }
        }
        
        return 0
    }
    
    // MARK: - NSData handling
    
    // Load NSData from a "slot" stored in NSUserDefaults / device memory.
    func dataFromSlot(slotNumber:Int) -> Data? {
        let deviceMemory:UserDefaults = UserDefaults.standard   // Pointer to where memory is stored in the device
        let slotKey = NSString(string: "slot\(slotNumber)") // Generate name of the dictionary key where save data is stored
        
        print("[SMRecord] Loading record from slot named [\(slotKey)]")
        
        // Try to load the data from the slot that should be stored in the device's memory.
        if let slotData = deviceMemory.object(forKey: slotKey as String) as? Data {
            print("[SMRecord] 'dataFromSlot' has loaded an NSData object of size \(slotData.count) bytes.")
            return (NSData(data: slotData) as Data)
        }
        
        print("[SMRecord] ERROR: No data found in slot number \(slotNumber)")
        return nil;
    }
    
    // Load a dictionary with game record from an NSData object (which was loaded from memory), by unarchiving information from
    // an NSData object into an NSDictionary object
    func recordFromData(data:Data) -> NSDictionary? {
        let unarchiver                  = try! NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = false
        if let dictionaryFromData       = unarchiver.decodeObject(forKey: SMRecordDataKey) as? NSDictionary {
            unarchiver.finishDecoding()
            print("Dictionary from data: \(dictionaryFromData)")
            return NSDictionary(dictionary: dictionaryFromData)
        }
        
        print("[SMRecord] Can't retrieve record from data object.")
        return nil
    }
    
    // Load saved game data from a slot into NSDictionary object
    func recordFromSlot(number:Int) -> NSDictionary? {
        if let loadedData = self.dataFromSlot(slotNumber: number) {
            return self.recordFromData(data: loadedData)
        }
        
        return nil
    }
    
    // This attempts to load a record from the "current slot," which is slotXX (where XX is whatever the heck 'self.currentSlot' is).
    // If this sounds kind of vague and unhelpful... well, I suppose that says something about this function! :P
    //- (void)loadRecordFromCurrentSlot
    func loadRecordFromCurrentSlot() {
        // Load temporary dictionary from a particular slot in device memory
        if let temporaryDictionary = self.recordFromSlot(number: currentSlot) {
            // Copy record data from device memory
            record = NSMutableDictionary(dictionary: temporaryDictionary)
            print("[SMRecord] Record was successfully loaded from slot \(self.currentSlot)")
        } else {
            // Error as there's no valid data in the dictionary
            print("[SMRecord] ERROR: Could not load record from slot \(self.currentSlot)")
        }
    }
    
    // Create an NSData object from a game record
    func dataFromRecord(dictionary:NSDictionary) -> Data {
        self.updateDateInDictionary(dictionary: dictionary)
        
        // Encode the dictionary into NSData format
        let archiver = NSKeyedArchiver(requiringSecureCoding: false)
        archiver.encode(dictionary, forKey: SMRecordDataKey)
        archiver.finishEncoding() //[archiver finishEncoding];
        
        return archiver.encodedData
    }
    
    // Saves NSData object to a particular "slot" (which is located in NSUserDefaults's root dictionary)
    func saveData(data:Data, slotNumber:Int) {
        // Store the NSData object into NSUserDefaults, under the key "slotXX" (XX being whatever value 'slotNumber' is)
        let deviceMemory            = UserDefaults.standard
        let stringWithSlotNumber    = NSString(string: "slot\(slotNumber)") // Dictionary key for slot
        deviceMemory.setValue(data, forKey: stringWithSlotNumber as String) // Store data in NSUserDefaults dictionary
        self.addToUsedSlotNumbers(slotNumber: slotNumber)                   // flag this slot number as being used
    }
    
    // This just checks if the current score is higher than the "high score" saved in NSUserDefaults. If that's the case, then
    // the high score is set to the current score's value.
    func updateHighScore() {
        // Try to get the scores. If, for some reason, there isn't any actual score data, then they'll just be set to zero
        let theCurrentScore = currentScore() //[self currentScore];
        let theHighScore    = highScore()
        
        // Save the current score if it's higher than the High Score that's been saved
        if( theCurrentScore > theHighScore ) {
            self.setHighScoreWithInteger(integer: theCurrentScore)
        }
    }
    
    // If SMRecord is storing any data, then it will get stored to device memory (NSUserDefaults). The slot number being used
    // would be whatever 'currentSlot' has as its value.
    func saveCurrentRecord() {
        if( record.count < 1 ) {
            print("[SMRecord] ERROR: No record data exists.");
            return;
        }
        
        // Update global data
        let deviceMemory = UserDefaults.standard
        let theDateToday = Date()
        let theSlotToUse = NSNumber(value: currentSlot)
        deviceMemory.setValue(theDateToday, forKey: SMRecordDateSavedKey)
        deviceMemory.setValue(theSlotToUse, forKey: SMRecordCurrentSlotKey)
        
        // Update record information
        self.updateDateInDictionary(dictionary: record)
        self.updateHighScore() //updateHighScore()
        
        let recordAsData = self.dataFromRecord(dictionary: record)
        self.saveData(data: recordAsData, slotNumber: currentSlot)
    }
    
    // MARK: - Sprite aliases
    
    // Retrieve sprite alias data rom record and return it in a mutable dictionary
    func spriteAliases() -> NSMutableDictionary {
        // check if the dictionary already exists, and if so, return it
        if let aliasesFromDictionary = record.object(forKey: SMRecordSpriteAliasesKey) as? NSMutableDictionary {
            return aliasesFromDictionary
        }
        
        // otherwise, the dictionary will have to be created inside of the record
        let aliasDictionary = NSMutableDictionary()
        record.setValue(aliasDictionary, forKey:SMRecordSpriteAliasesKey)
        
        return aliasDictionary
    }
    
    // Replace the existing sprite alias dictionary with another dictionary
    func setSpriteAliases(dictionary:NSMutableDictionary) {
        if record.count < 0 {
            self.startNewRecord()
        }
        
        record.setValue(dictionary, forKey:SMRecordSpriteAliasesKey)
    }
    
    // Remove all of the sprite alias data from the dictionary
    func resetAllSpriteAliases() {
        let dummyAliases = NSMutableDictionary()
        dummyAliases.setValue("dummy sprite alias value", forKey:"dummy alias key");
        self.setSpriteAliases(dictionary: dummyAliases)
    }
    
    // Add sprite alias data from another dictionary to the dictionary stored by the record
    func addExistingSpriteAliases(dictionary:NSDictionary) {
        if dictionary.count > 0 {
            let spriteAliasDictionary = self.spriteAliases()
            SMDictionaryAddEntriesFromAnotherDictionary(spriteAliasDictionary, source: dictionary)
        }
    }
    
    // Add a single sprite alias to the dictionary of sprite aliases stored by the record
    func setSpriteAlias(named:String, withUpdatedValue:String) {
        if SMStringLength(named) < 1 || SMStringLength(withUpdatedValue) < 1 {
            return
        }
        
        let allSpriteAliases = self.spriteAliases()
        allSpriteAliases.setValue(withUpdatedValue, forKey: named)
    }
    
    // Return information about a particular sprite alias
    func spriteAliasNamed(name:String) -> String? {
        if record.count < 1 {
            return nil
        }
        
        let allSpriteAliases    = self.spriteAliases()
        let specificAlias       = allSpriteAliases.object(forKey: name) as? String
        
        return specificAlias
    }
    
    // MARK: - Flags
    
    /*
     Opens a PLIST file and copies all items in it to EKRecord as flags.
     
     Can choose whether or not to overwrite existing flags that have the same names.
     */
    func addFlagsFromFile(named:String, overrideExistingFlags:Bool) {
        let rootDictionary = SMDictionaryFromFile(named)
        if rootDictionary == nil {
            print("[EKRecord] WARNING: Could not load flags as the dictionary file could not be loaded.")
            return;
        }
        
        if overrideExistingFlags == true {
            print("[EKRecord] DIAGNOSTIC: Will forcibly overwrite existing flags with flags from file: \(named)")
        } else {
            print("[EKRecord] DIAGNOSTIC: Will add flags (without overwriting) from file named: \(named)")
        }
        
        for key in rootDictionary!.allKeys {
            let value = rootDictionary!.object(forKey: key)
            
            if overrideExistingFlags == true {
                //self.setFlagValue(value! as AnyObject, nameOfFlag: key as! String)
                self.setFlagValue(object: value! as AnyObject, flagNamed: key as! String)
                //self.setFlagValue(value!, forFlagNamed:key)
            } else {
                //let existingFlag = self.flagNamed(key as! String)
                let existingFlag = self.flagNamed(string: key as! String)
                if existingFlag == nil {
                    //self.setValue(value!, forFlagNamed:key as! String)
                    //setFlagValue(value! as AnyObject, nameOfFlag: key as! String)
                    self.setFlagValue(object: value! as AnyObject, flagNamed: key as! String)
                }
            }
        } // end for loop
    } // end function

    
    // This removes any existing flag data and overwrites it with a blank dictionary that has dummy values
    func resetAllFlags() {
        // Create a brand-new dictionary with nothing but dummy data
        //NSMutableDictionary* dummyFlags = [[NSMutableDictionary alloc] init];
        //[dummyFlags setValue:@"dummy value" forKey:@"dummy key"];
        let dummyFlags = NSMutableDictionary()
        dummyFlags.setValue(NSString(string: "dummy value - reset all flags"), forKey: "dummy key")
        
        // Set this "dummy data" dictionary as the flags data
        //[self setFlags:dummyFlags];
        //setFlags(dummyFlags)
        self.setFlags(dictionary: dummyFlags)
    }
    
    
    
    // Adds a dictionary of flags to the Flags data stored in SMRecord
    func addExistingFlags(fromDictionary:NSDictionary) {
        // Check if there's not really any data to add
        if( fromDictionary.count < 1 ) {
            return;
        }
        
        // Check if no record data exists. If that's the case, then start a new record.
        if( record.count < 1 ) {
            //[self startNewRecord];
            startNewRecord()
        }
        
        // Add these new dictionary values to any existing flag data
        let flagsDictionary = self.flags()
        flagsDictionary.addEntries(from: fromDictionary as! [AnyHashable: Any])
    }
    
    func flagNamed(string:String) -> AnyObject? {
            return self.flags().object(forKey: string) as AnyObject?
    }
    
    // Return the int value of a particular flag. It's important to keep in mind though, that while flags by default
    // use int values, it's entirely possible that it might use something entirely different. It's even possible to use
    // completely different types of objects (say, UIImage) as a flag value.
    func valueOfFlagNamed(string:String) -> Int {
        if let theFlag = self.flagNamed(string: string) as? NSNumber {
            // determine if the flag actually contains a numerical value
            if theFlag.isKind(of: NSNumber.self) == true {
                return theFlag.intValue
            } else {
                // this flag probably contains a string, or maybe even something else entirely
                print("[SMRecord] WARNING: Attempt to retrieve value of flag named \(string), but this flag does not contain numerical data.")
            }
        }
        
        return 0 // default value is zero
    }
    
    // Sets the value of a flag
    func setFlagValue(object:AnyObject, flagNamed:String) {
        // Create valid record if one doesn't exist
        if( record.count < 1 ) {
            startNewRecord()
        }
        
        // Update flags dictionary with this value
        let theFlags = self.flags()
        theFlags.setValue(object, forKey: flagNamed)
    }
    
    // Sets a flag's int value. If you want to use a non-integer value (or something that's not even a number to begin with),
    // then you shoule switch to 'setFlagValue' instead.
    func setFlagValueWithInteger(integer:Int, flagNamed:String) {
        // Convert int to NSNumber and pass that into the flags dictionary
        let tempValue = NSNumber(value: integer)
        self.setFlagValue(object: tempValue, flagNamed: flagNamed)
    }
    
    // Adds or subtracts the integer value of a flag by a certain amount (the amount being whatever 'iValue' is).
    //func modifyIntegerValue(_ iValue:Int, nameOfFlag:String) {
    func modifyFlagWithInteger(integer:Int, flagNamed:String) {
        var modifiedInteger:Int = 0
        
        // Create a record if there isn't one already
        if( record.count < 1 ) {
            startNewRecord()
        }
        
        if let numberObject = self.flags().object(forKey: flagNamed) as? NSNumber {
            if numberObject.isKind(of: NSNumber.self) {
                modifiedInteger = numberObject.intValue
            }
        }
        
        modifiedInteger = modifiedInteger + integer
        self.setFlagValue(object: NSNumber(value: modifiedInteger), flagNamed: flagNamed)
    }
    
    // MARK: - Activity data
    
    // Sets the activity information in the record
    func setActivityDictionary(dictionary:NSDictionary) {
        // Check if there's no data
        if( dictionary.count < 1 ){
            print("[SMRecord] ERROR: Invalid activity dictionary was passed in; nothing will be done.")
            return;
        }
        
        // Check if the record is empty
        if record.count < 1 {
            startNewRecord()
        }
        
        // Store a copy of the dictionary into the record
        let dictionaryToStore = NSDictionary(dictionary: dictionary)
        record.setValue(dictionaryToStore, forKey: SMRecordCurrentActivityDictKey)
    }
    
    // Return activity data from record
    func dictionaryOfActivityInformation() -> NSDictionary {
        // Check if the record exists, and if so, then try to grab the activity data from it. By default, there should be some sort of dictionary,
        // even if it's just nothing but dummy values.
        if( record.count > 0 ) {
            if let retrievedDictionary = record.object(forKey: SMRecordCurrentActivityDictKey) as? NSDictionary {
                return NSDictionary(dictionary: retrievedDictionary)
            }
        }
        
        // Otherwise, return empty dictionary
        return NSDictionary()
    }
    
    // This just resets all the activity information stored by a particular dictionary back to its default values (that is, "dummy" values).
    // The "dict" being passed in should be a record dictionary of some kind (ideally, the 'record' dictionary stored by SMRecord)
    func resetActivityInformation(inDictionary:NSDictionary) {
        // Fill out the activity information with useless "dummy data." Later, this data can (and should) be overwritten there's actual data to use
        let informationAboutCurrentActivity = NSMutableDictionary(object: "nil", forKey: "scene to play" as NSCopying)
        let activityDictionary = NSMutableDictionary(objects: ["nil", informationAboutCurrentActivity],
                                                     forKeys: [SMRecordActivityTypeKey as NSCopying, SMRecordActivityDataKey as NSCopying])
        
        // Store dummy data into record
        inDictionary.setValue(activityDictionary, forKey: SMRecordCurrentActivityDictKey)
    }
    
    // For saving/loading to device. This should cause the information stored by SMRecord to being put to NSUserDefaults, and then
    // it would "synchronize," so that the data would be stored directly into the device memory (as opposed to just sitting in RAM).
    func saveToDevice() {
        print("[SMRecord] Will now attempt to save information to device memory.");
        
        if record.count < 1 {
            print("[SMRecord] ERROR: Cannot save information because no record exists.")
            return
        }
        
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
    } // end function
} // end class
