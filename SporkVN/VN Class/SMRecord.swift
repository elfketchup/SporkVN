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

This class works by storing game data in NSUserDefaults. The game data is originally in a mutable
dictionary (NSMutableDictionary) format, and converted to the Data/NSData type when it's actually
stored in device memory.
 
(NOTE: As of July 2020, there is experimental support for storing data in iCloud using NSUbiquitousKeyValueStore.
       This feature has not been tested thoroughly, but functions similarly as storing data in
       the device's user defaults. However saving data to iCloud this way means that data is limited
       to taking up no more than 1 MB of storage.)
 
 SMRecord functions by keeping track of information using the key-value storage of NSDictionary. Generally,
 a single record will hold:

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

In the future, functionality for more complex cloud storage or for saving to actual files (as opposed to
relying on NSUserDefaults) may be added, but for now SMRecord works well enough.

*/

let SMRecordDataSavedKey          = "save data"

// These are keys for the "global" values in the record,
let SMRecordDateSavedKey            = "date saved"       // The last time any data was saved on this device

// Keys for data that's specific to a particular playthrough and is stored inside of individual "slots" (which contain a single
// NSData object that encapsulates all the other playthrough-specific data)
let SMRecordDataKey                 = "record"               // THe NSData object that holds the dictionary with all the other saved-game data
let SMRecordFlagsKey                = "flag data"            // Key for a dictionary of "flag" data
let SMRecordDateSavedAsString       = "date saved as string" // A string with a more human-readable version of the NSDate object
let SMRecordSpriteAliasesKey	    = "sprite aliases"       // stores all sprite aliases in use by the game 

// Keys for activity data
let SMRecordCurrentActivityDictKey  = "current activity" // Used to locate the activity data in the User Defaults
let SMRecordActivityTypeKey         = "activity type" // Is this a VNScene, or some other kind of CCScene / activity type?
let SMRecordActivityDataKey         = "activity data" // This will almost always be a dictionary with activity-specific data

// Singleton
private let SMRecordSharedInstance = SMRecord()

class SMRecord {
    
    // Singleton access; call SMRecords.sharedRecord
    class var sharedRecord:SMRecord {
        return SMRecordSharedInstance
    }
    
    // stores all save data for this game
    var record      = NSMutableDictionary(capacity: 1)
    
    // Determines whether or not to use the cloud or use ONLY local storage
    var useCloud = false
    
    // MARK: - Initialization
    
    init() {
        // If there's any previously-saved data, then just load that information. If there is NO previously-saved data, then just do nothing.
        // The reasoning here is that if there's previously-saved data, then it should be loaded by default (if the app or player wants to create
        // all new data, they can just do that manually). If no record exists, then it will be created either automatically once the app starts
        // trying to write flag data. Of course, it can also be created manually (like when a new game begins, SMRecord can be told to just
        // create a new record.
        if let dictionaryFromLocalStorage = recordFromLocalStorage() {
            print("[SMRecord] Record initialized with dictionary: \(dictionaryFromLocalStorage)")
            record = NSMutableDictionary(dictionary: dictionaryFromLocalStorage)
        }
    }
    
    // MARK: - Date and time
    
    // Convert a NSDate value into an easily-readable string value
    func stringFromDate(date:Date) -> String {
        let format          = DateFormatter()
        format.dateFormat   = "yyyy'-'MM'-'dd',' h:mm a" // Example: "2014-11-11, 12:29 PM"
        return format.string(from: date)
    }
    
    /*
    // Set all time/date information in a save slot to the current time.
    func updateDateInDictionary(dictionary:NSDictionary) {
        // Get the current time, and then create a string displaying a human-readable version of the current time
        let theTimeRightNow:Date    = Date()
        let stringWithCurrentTime   = stringFromDate(date: theTimeRightNow)
        
        // Set date information in the dictionary
        dictionary.setValue(theTimeRightNow,        forKey:SMRecordDateSavedKey)        // Save NSDate object
        dictionary.setValue(stringWithCurrentTime,  forKey:SMRecordDateSavedAsString)   // Save human-readable string
    }*/
    
    // MARK: - Record
    
    // Create new save data for a brand new game. The dictionary has no "real" data, but has several placeholders
    // where actual data can be written into. So it's not really an "empty" record, but just a brand-new one?
    func emptyRecord() -> NSMutableDictionary {
        let tempRecord = NSMutableDictionary()
        
        // Fill the record with default data
        //updateDateInDictionary(dictionary: tempRecord)      // Set current date as "the time when this was saved"
        resetActivityInformation(inDictionary: tempRecord)  // Fill the activity dictionary with dummy data
        
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
    }
    
    //func hasAnySavedData() ->Bool {
    func hasSavedLocalData() -> Bool {
        // This function will check if any of the following objects are missing, since a successful save should have put all of this into device memory
        let lastSavedDate:Date?     = UserDefaults.standard.object(forKey: SMRecordDateSavedKey) as? Date
        let previousSaveData:Data?  = UserDefaults.standard.object(forKey: SMRecordDataSavedKey) as? Data
        // If neither of these things exist, then SMRecord will believe there is no saved data
        if( lastSavedDate == nil || previousSaveData == nil ) {
            return false
        }
        
        return true;
    }
    
    // Determine if there's saved game data stored in the cloud
    func hasSavedCloudData() -> Bool {
        if useCloud == false {
            print("[SMRecord] Cannot check cloud storage since SMRecord is set to NOT use cloud storage. Adjust settings first.")
            return false;
        }
        
        let cloudStorage    = NSUbiquitousKeyValueStore.default
        let cloudSaveDate   = cloudStorage.object(forKey: SMRecordDateSavedKey) as? Date
        let dataInCloud     = cloudStorage.object(forKey: SMRecordDataSavedKey) as? Data
        
        if cloudSaveDate == nil || dataInCloud == nil {
            return false
        }
        
        return true
    }
    
    // MARK: - NSData handling
    
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
    
    // Create an NSData object from a game record
    func dataFromRecord(dictionary:NSDictionary) -> Data {
        // Encode the dictionary into NSData format
        let archiver = NSKeyedArchiver(requiringSecureCoding: false)
        archiver.encode(dictionary, forKey: SMRecordDataKey)
        archiver.finishEncoding() //[archiver finishEncoding];
        
        return archiver.encodedData
    }
    
    // This attempts to load a record from the "current slot," which is slotXX (where XX is whatever the heck 'self.currentSlot' is).
    // If this sounds kind of vague and unhelpful... well, I suppose that says something about this function! :P
    func recordFromLocalStorage() -> NSDictionary? {
        let deviceMemory = UserDefaults.standard
        if let dataFromLocalStorage = deviceMemory.object(forKey: SMRecordDataSavedKey) as? Data {
            print("[SMRecord] Found save data in device storage. Will attempt to convert to readable format.")
            
            if let dictionaryFromData = recordFromData(data: dataFromLocalStorage) {
                print("[SMRecord] Save data was converted to readable format.")
                return dictionaryFromData
            } else {
                print("[SMRecord] WARNING: Save data could not be converted to readable format.")
            }
        } else {
            print("[SMRecord] WARNING: No data could be retrieved from device storage.")
        }
        
        return nil
    }
    
    // If SMRecord is storing any data, then it will get stored to device memory (NSUserDefaults). The slot number being used
    // would be whatever 'currentSlot' has as its value.
    func saveCurrentRecord() -> Bool {
        if( record.count < 1 ) {
            print("[SMRecord] ERROR: No record data exists.");
            return false;
        }
        
        // Update global data
        let deviceMemory = UserDefaults.standard
        let theDateToday = Date()
        let recordAsData = dataFromRecord(dictionary: record)
        
        deviceMemory.setValue(theDateToday, forKey: SMRecordDateSavedKey)
        deviceMemory.setValue(recordAsData, forKey: SMRecordDataSavedKey)
        
        return true
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
    
    // Returns the flags dictionary that's stored in the record... assuming that the record exists, that is!
    // (If the record does exist, then the flags dictionary should also exist inside it too)
    func flags() -> NSMutableDictionary {
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
        // Flags will only get updated if the dictionary is valid
        record.setValue(dictionary, forKey: SMRecordFlagsKey)
    }
    
    
    // Opens a PLIST file and copies all items in it to EKRecord as flags.
    // Can choose whether or not to overwrite existing flags that have the same names.
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
        let dummyFlags = NSMutableDictionary()
        dummyFlags.setValue(NSString(string: "dummy value - reset all flags"), forKey: "dummy key")
        
        // Set this "dummy data" dictionary as the flags data
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
    func saveToDevice() -> Bool {
        print("[SMRecord] Will now attempt to save information to device memory.");
        
        if record.count < 1 {
            print("[SMRecord] ERROR: Cannot save information because no record exists.")
            return false
        }
        
        print("[SMRecord] Saving record to device memory...");
        
        //[self saveCurrentRecord];
        if saveCurrentRecord() == false {
            return false
        }
        
        // Now "synchronize" the data so that everything in NSUserDefaults will be moved from RAM into the actual device memory.
        // NSUserDefaults synchronizes its data every so often, but in this case it will be done manually to ensure that SMRecord's data
        // will be moved into device memory.
        //[[NSUserDefaults standardUserDefaults] synchronize];
        let didSync:Bool = UserDefaults.standard.synchronize()
        
        if didSync == false {
            print("[SMRecord] WARNING: Could not synchronize data to device memory.")
            return false
        } else {
            print("[SMRecord] Record was synchronized.")
        }
        
        return true
    } // end function
    
    // MARK: - Cloud storage
    
    // WARNING: This is experimental and hasn't really been tested properly.
    
    // Store autosave data in the cloud
    func saveToCloud() -> Bool {
        print("[SMRecord] Will now attempt to save information to the cloud")
        
        if useCloud == false {
            print("[SMRecord] ERROR: Could not save to cloud as SMRecord is not configured to use cloud storage.")
            return false
        }
        
        if saveToDevice() == false {
            print("[SMRecord] ERROR: Could not save data to local storage. Data will not be saved to cloud.")
            return false
        }
        
        let store = NSUbiquitousKeyValueStore.default
        let currentDate = Date()
        let recordAsData = dataFromRecord(dictionary: record)
        
        store.setValue(currentDate, forKey: SMRecordDateSavedKey)
        store.setValue(recordAsData, forKey: SMRecordDataSavedKey)
        
        print("[SMRecord] Did finish attempting to save data to the cloud.")
        
        return true
    }
    
    // Attempts to load save data from the cloud
    func loadFromCloud() -> Bool {
        print("[SMRecord] Will attempt to load data from cloud")
        
        if useCloud == false {
            print("[SMRecord] ERROR: Could not load from cloud as SMRecord is not configured to use cloud storage.")
            return false
        }
        
        let store               = NSUbiquitousKeyValueStore.default
        let dateFromCloud       = store.value(forKey: SMRecordDateSavedKey) as? Date
        let saveDataFromCloud   = store.value(forKey: SMRecordDataSavedKey) as? Data
        
        // check if any of the information retrieved was invalid
        if dateFromCloud == nil || saveDataFromCloud == nil {
            print("[SMRecord] ERROR: No saved data could be found in the cloud")
            return false;
        }
        
        if let savedDictionary = recordFromData(data: saveDataFromCloud!) {
            record = NSMutableDictionary(dictionary: savedDictionary)
            return true
        }
        
        return false
    } // end function
    
    // Check if there's data saved in the cloud
    func cloudHasNewerSavedData() -> Bool {
        if useCloud == false {
            print("[SMRecord] ERROR: Could not check if data in cloud is newer as cloud storage is disabled.")
            return false
        }
        
        let dateInCloud = NSUbiquitousKeyValueStore.default.object(forKey: SMRecordDateSavedKey) as? Date
        let dateInLocal = UserDefaults.standard.object(forKey: SMRecordDateSavedKey) as? Date
        
        if dateInCloud == nil {
            return false
        }
        if dateInLocal == nil {
            // if it reaches this point (meaning there IS a date in the cloud) and there's no local date, then the cloud is the newest one
            return true
        }
        
        // Compare the two existing dates
        if dateInLocal! < dateInCloud! {
            return true
        }
        
        return false
    }
    
    // Date stored in cloud
    func dateInCloudStorage() -> Date? {
        if useCloud == false {
            print("[SMRecord] ERROR: Could not check data in cloud storage as cloud storage is not currently enabled.")
            return nil
        }
        
        let cloudStorage = NSUbiquitousKeyValueStore.default
        return cloudStorage.object(forKey: SMRecordDateSavedKey) as? Date
    }
    
    // Retrieve NSData object from the cloud and convert it to NSDictionary
    func recordFromCloud() -> NSDictionary? {
        if useCloud == false {
            print("[SMRecord] ERROR: Could not check data in cloud storage as cloud storage is not currently enabled.")
            return nil
        }
        
        let cloudStorage = NSUbiquitousKeyValueStore.default
        
        if let dataInCloud = cloudStorage.object(forKey: SMRecordDataSavedKey) as? Data {
            print("[SMRecord] Data was found in cloud storage. Will now attempt to convert to readable format.")
            
            if let dictionaryFromData = recordFromData(data: dataInCloud) {
                print("[SMRecord] Data was successfully converted to readable format.")
                return dictionaryFromData
            } else {
                print("[SMRecord] WARNING: Data could not be converted to readable format.")
            }
        } else {
            print("[SMRecord] WARNING: No data was found in cloud storage.")
        }
        
        return nil
    }
    
} // end class
