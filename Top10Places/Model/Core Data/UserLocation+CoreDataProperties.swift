//
//  UserLocation+CoreDataProperties.swift
//  Top10Places
//
//  Created by Arviejhay on 7/16/23.
//
//

import Foundation
import CoreData


extension UserLocation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserLocation> {
        return NSFetchRequest<UserLocation>(entityName: "UserLocation")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longtitude: Double
    @NSManaged public var places: Places?

}

extension UserLocation : Identifiable {

}
