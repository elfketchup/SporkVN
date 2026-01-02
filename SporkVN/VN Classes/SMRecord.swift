//
//  SMRecord.h
//
//  Created by James Briones on 2/5/11.
//  Copyright 2011. All rights reserved.
//

import Foundation
import UIKit
import SwiftData

/*
 Update - January 2026:
 
 SMRecord used to rely on a combination of NSUserDefaults (later UserDefaults) and NSMutableDictionary and NSData objects to
 function, but this has now been changed to use SwiftData, which is both simpler and also includes automatic iCloud storage
 if it's enabled in Xcode project settings. Migrating from the old storage scheme to SwiftData has been a little messy, but
 everything seems to work. However, a lot of the old concepts remain. I probably should rethink how this stuff is set up,
 but it's working fine for now. So far.
 
 IMPORTANT:
 For SwiftData to sync with iCloud, make sure the "iCloud" capability is enabled with "CloudKit" selected in the Xcode project settings!
 
 */

// MARK: - SwiftData Models

@Model
class GameSave {
    
    var id: UUID
    var lastModified: Date      // date last modified
    var activityType: String?   // what was the game doing
    var activityData: Data?     // more info about what the game was doing (json/archived data)
    var choiceSets: Data?       // for making visual novel choices
    
    @Relationship(deleteRule: .cascade, inverse: \GameFlag.gameSave)
    var flags: [GameFlag]?      // stores all flags the game has
    
    @Relationship(deleteRule: .cascade, inverse: \SpriteAlias.gameSave)
    var spriteAliases: [SpriteAlias]? // what sprites are on the screen
    
    init(id: UUID = UUID(), lastModified: Date = Date()) {
        self.id = id
        self.lastModified = lastModified
        self.flags = []
        self.spriteAliases = []
    }
}

@Model
class GameFlag {
    
    var key: String             // identifies the flag by name
    var intValue: Int?          // most flags are stored as an integer, so this is the most commonly used value in theory
    var doubleValue: Double?
    var stringValue: String?
    var boolValue: Bool?
    var dateValue: Date?
    var dataValue: Data?        // in theory saving a flag as some kind of Data/NSData object is unlikely, but could happen
    
    var gameSave: GameSave?
    
    init(key: String, value: Any) {
        self.key = key
        self.setValue(value)
    }
    
    func setValue(_ value: Any) {
        intValue = nil
        doubleValue = nil
        stringValue = nil
        boolValue = nil
        dateValue = nil
        dataValue = nil
        
        switch value {
        case let v as Int: intValue = v
        case let v as Double: doubleValue = v
        case let v as String: stringValue = v
        case let v as Bool: boolValue = v
        case let v as Date: dateValue = v
        case let v as Data: dataValue = v
        default:
            dataValue = try? NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: false)
        }
    }
    
    func getValue() -> Any {
        if let v = intValue { return v }
        if let v = doubleValue { return v }
        if let v = stringValue { return v }
        if let v = boolValue { return v }
        if let v = dateValue { return v }
        if let v = dataValue {
            // the following are a list of classes that can be unarchived, if it doesn't neatly fit into these then it'll just return a Data object
            let allowedClasses: [AnyClass] = [NSDictionary.self, NSMutableDictionary.self, NSArray.self, NSMutableArray.self, NSString.self, NSNumber.self, NSDate.self, NSData.self]
            if let unarchived = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: allowedClasses, from: v) {
                return unarchived
            }
            return v // data value as Data object if it couldn't be unarchived normally
        }
        return 0
    }
}

@Model
class SpriteAlias {
    
    var alias: String
    var filename: String
    var gameSave: GameSave?
    
    init(alias: String, filename: String) {
        self.alias = alias
        self.filename = filename
    }
}

/*

SMRecord
 
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

As of January 2026, SMRecord has been updated to use SwiftData for storage, which automatically includes
cloud storage functionality if it's enabled in Xcode project settings.

*/


@MainActor
class SMRecord {

    // MARK: - SwiftData Persistence

    // SwiftData container
    static var modelContainer: ModelContainer?
    static var modelContext: ModelContext?

    // MARK: - Current Game State (Swift-native)

    private(set) static var currentFlags            = [String: Any]()
    private(set) static var currentSpriteAliases    = [String: String]()
    private(set) static var currentActivityData     = [String: Any]()
    private(set) static var currentChoiceSets       = [String: Any]()

    // Determines whether the record system has been started yet
    static var started = false

    // Allowed classes for secure unarchiving (Legacy support)
    static let allowedClasses: [AnyClass] = [NSDictionary.self, NSMutableDictionary.self, NSArray.self, NSMutableArray.self, NSString.self, NSNumber.self, NSDate.self, NSData.self]

    // MARK: - Legacy Constants (Maintained for external API compatibility)
    static let FlagsKey                 = "flag data"
    static let SpriteAliasesKey         = "sprite aliases"
    static let ChoiceSetsKey            = "choice sets"
    static let CurrentActivityDictionaryKey = "current activity"
    static let ActivityTypeKey              = "activity type"
    static let ActivityDataKey              = "activity data"
    
    // MARK: - Record

    // It used to be that the SMRecord was used like a normal class (and not a series of static class functions), and it had an init(),
    // but now that it's all static functions, this is how it's used now... anyway it gets SwiftData up and running so that's what's important
    static func startRecordSystem() {
        if modelContainer == nil {
            do {
                let schema = Schema([GameSave.self, GameFlag.self, SpriteAlias.self])
                let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
                modelContext = modelContainer?.mainContext
            } catch {
                print("[SMRecord] CRITICAL SwiftData Error: \(error)")
            }
        }

        if let context = modelContext {
            let descriptor = FetchDescriptor<GameSave>(sortBy: [SortDescriptor(\.lastModified, order: .reverse)])
            do {
                let saves = try context.fetch(descriptor)
                if let latestSave = saves.first {
                    loadFromGameSave(latestSave)
                    started = true
                    return
                }
            } catch {
                print("[SMRecord] Failed to fetch saves: \(error)")
            }
        }

        started = true
    }

    // This populates the in-memory state from SwiftData models, and shouldn't be called from outside SMRecord
    private static func loadFromGameSave(_ save: GameSave) {
        currentFlags.removeAll()
        if let savedFlags = save.flags {
            for flag in savedFlags {
                currentFlags[flag.key] = flag.getValue()
            }
        }

        currentSpriteAliases.removeAll()
        if let savedAliases = save.spriteAliases {
            for alias in savedAliases {
                currentSpriteAliases[alias.alias] = alias.filename
            }
        }

        currentActivityData.removeAll()
        if let actData = save.activityData,
           let dict = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: allowedClasses, from: actData) as? NSDictionary {
            currentActivityData = dict as? [String: Any] ?? [:]
        }

        currentChoiceSets.removeAll()
        if let choiceData = save.choiceSets,
           let dict = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: allowedClasses, from: choiceData) as? NSDictionary {
            currentChoiceSets = dict as? [String: Any] ?? [:]
        }
    }

    // This "resets" SMRecord so that it will have brand-new data (as in a fresh saved game). HOWEVER it doesn't attept to save
    // any previous data that might have existed... if you want to be sure that previous save data is actually saved, you'll have
    // to call those functions yourself!
    static func startNewRecord() {
        currentFlags.removeAll()
        currentSpriteAliases.removeAll()
        currentChoiceSets.removeAll()
        resetActivityInformation()
        started = true
    }

    // determine if there's any data saved locally
    static func hasSavedLocalData() -> Bool {
        if started == false {
            SMRecord.startRecordSystem()
        }

        if let context = modelContext {
             let descriptor = FetchDescriptor<GameSave>()
             if let count = try? context.fetchCount(descriptor), count > 0 {
                 return true
             }
        }

        return false
    }

    // If SMRecord is storing any data, then it will get stored to device memory (now SwiftData, previously UserDefaults)
    static func saveCurrentRecord() -> Bool {
        if !started {
            return false
        }

        guard let context = modelContext else {
            print("[SMRecord] ERROR: ModelContext missing.")
            return false
        }

        var gameSave: GameSave
        let descriptor = FetchDescriptor<GameSave>()
        
        if let saves = try? context.fetch(descriptor), let first = saves.first {
            gameSave = first
        } else {
            gameSave = GameSave()
            context.insert(gameSave)
        }

        gameSave.lastModified = Date()

        // try and sync flags
        var currentKeys = Set<String>()
        for (key, value) in currentFlags {
            currentKeys.insert(key)
        
            if let flag = gameSave.flags?.first(where: { $0.key == key }) {
                flag.setValue(value)
            } else {
                let newFlag = GameFlag(key: key, value: value)
                newFlag.gameSave = gameSave
            }
        }

        if let savedFlags = gameSave.flags {
             for flag in savedFlags {
                 if !currentKeys.contains(flag.key) {
                     context.delete(flag)
                 }
             }
        }

        // now sync sprite aliases
        var currentAliases = Set<String>()
        for (key, value) in currentSpriteAliases {
            currentAliases.insert(key)
            
            if let alias = gameSave.spriteAliases?.first(where: { $0.alias == key }) {
                alias.filename = value
            } else {
                let newAlias = SpriteAlias(alias: key, filename: value)
                newAlias.gameSave = gameSave
            }
        }
        
        if let savedAliases = gameSave.spriteAliases {
            for alias in savedAliases {
                if !currentAliases.contains(alias.alias) {
                    context.delete(alias)
                }
            }
        }

        // sync activity data
        if !currentActivityData.isEmpty {
            gameSave.activityData = try? NSKeyedArchiver.archivedData(withRootObject: currentActivityData, requiringSecureCoding: false)

        }
    
        // sync choice sets
        if !currentChoiceSets.isEmpty {
             gameSave.choiceSets = try? NSKeyedArchiver.archivedData(withRootObject: currentChoiceSets, requiringSecureCoding: false)
        }

        do {
            try context.save()
            return true
        } catch {
            print("[SMRecord] Save failed: \(error)")
            return false
        }
    }

    // Retrieve sprite alias data rom record and return it in a mutable dictionary
    static func spriteAliases() -> NSMutableDictionary {
        return NSMutableDictionary(dictionary: currentSpriteAliases)
    }
    
    // Replace the existing sprite alias dictionary with another dictionary
    static func setSpriteAliases(dictionary:NSMutableDictionary) {
        currentSpriteAliases = dictionary as? [String: String] ?? [:]
    }
    
    // Remove all of the sprite alias data from the dictionary
    static func resetAllSpriteAliases() {
        currentSpriteAliases.removeAll()
    }
    
    // Add sprite alias data from another dictionary to the dictionary stored by the record
    static func addExistingSpriteAliases(dictionary:NSDictionary) {
        for (key, value) in dictionary {
            if let k = key as? String, let v = value as? String {
                currentSpriteAliases[k] = v
            }
        }
    }
    
    // Add a single sprite alias to the dictionary of sprite aliases stored by the record
    static func setSpriteAlias(named:String, withUpdatedValue:String) {
        if named.isEmpty || withUpdatedValue.isEmpty {
            return
        }
        currentSpriteAliases[named] = withUpdatedValue
    }
    
    // Return information about a particular sprite alias
    static func spriteAliasNamed(name:String) -> String? {
        return currentSpriteAliases[name]
    }
    
    // MARK: - Flags
    
    // Returns the flags dictionary that's stored in the record... assuming that the record exists, that is!
    // (If the record does exist, then the flags dictionary should also exist inside it too)
    static func flags() -> NSMutableDictionary {
        return NSMutableDictionary(dictionary: currentFlags)
    }
    
    // Set the "flags" mutable dictionary in the record. If there's no record, it just gets created on the fly
    static func setFlags(dictionary:NSMutableDictionary) {
        currentFlags = dictionary as? [String: Any] ?? [:]
    }
    
    // Opens a PLIST file and copies all items in it to EKRecord as flags.
    // Can choose whether or not to overwrite existing flags that have the same names.
    static func addFlagsFromFile(named:String, overrideExistingFlags:Bool) {
        guard let rootDictionary = SMUtility.Dictionaries.dictionaryFromFile(filename: named) else {
            return;
        }
        for key in rootDictionary.allKeys {
            guard let keyString = key as? String else { continue }
            let value = rootDictionary.object(forKey: keyString)
            if overrideExistingFlags || SMRecord.flagNamed(string: keyString) == nil {
                SMRecord.setFlagValue(object: value! as AnyObject, flagNamed: keyString)
            }
        }
    }
    
    // This removes any existing flag data and overwrites it with a blank dictionary that has dummy values
    static func resetAllFlags() {
        currentFlags.removeAll()
    }
    
    // Adds a dictionary of flags to the Flags data stored in SMRecord
    static func addExistingFlags(fromDictionary:NSDictionary) {
        for (key, value) in fromDictionary {
            if let k = key as? String {
                currentFlags[k] = value
            }
        }
    }
    
    static func flagNamed(string:String) -> AnyObject? {
        return currentFlags[string] as AnyObject?
    }
    
    // Return the int value of a particular flag. It's important to keep in mind though, that while flags by default
    // use int values, it's entirely possible that it might use something entirely different. It's even possible to use
    // completely different types of objects (say, UIImage) as a flag value.
    static func valueOfFlagNamed(string:String) -> Int {
        if let val = currentFlags[string] as? Int { return val }
        if let val = currentFlags[string] as? NSNumber { return val.intValue }
        return 0
    }
    
    // Sets the value of a flag
    static func setFlagValue(object:AnyObject, flagNamed:String) {
        currentFlags[flagNamed] = object
    }
    
    // Sets a flag's int value. If you want to use a non-integer value (or something that's not even a number to begin with),
    // then you shoule switch to 'setFlagValue' instead.
    static func setFlagValueWithInteger(integer:Int, flagNamed:String) {
        currentFlags[flagNamed] = integer
    }
    
    // Adds or subtracts the integer value of a flag by a certain amount (the amount being whatever 'iValue' is).
    //func modifyIntegerValue(_ iValue:Int, nameOfFlag:String) {
    static func modifyFlagWithInteger(integer:Int, flagNamed:String) {
        let currentVal = valueOfFlagNamed(string: flagNamed)
        currentFlags[flagNamed] = currentVal + integer
    }
    
    // MARK: - Choice sets
    
    static func saveChoiceSetsToRecord(dictionary:NSDictionary) {
        currentChoiceSets = dictionary as? [String: Any] ?? [:]
    }
    
    static func choiceSetsFromRecord() -> NSDictionary {
        return currentChoiceSets as NSDictionary
    }
    
    // MARK: - Activity data
    
    // Sets the activity information in the record
    static func setActivityDictionary(dictionary:NSDictionary) {
        currentActivityData = dictionary as? [String: Any] ?? [:]
    }
    
    // Return activity data from record
    static func dictionaryOfActivityInformation() -> NSDictionary {
        return currentActivityData as NSDictionary
    }
    
    // Resets activity information to a default "empty" state
    static func resetActivityInformation() {
        let informationAboutCurrentActivity: [String: Any] = ["scene to play": "nil"]
        let activityDictionary: [String: Any] = [
            SMRecord.ActivityTypeKey: "nil",
            SMRecord.ActivityDataKey: informationAboutCurrentActivity
        ]
        currentActivityData = activityDictionary
    }
    
} // end class

