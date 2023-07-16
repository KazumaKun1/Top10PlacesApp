//
//  Places+CoreDataProperties.swift
//  Top10Places
//
//  Created by Arviejhay on 7/16/23.
//
//

import Foundation
import CoreData


extension Places {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Places> {
        return NSFetchRequest<Places>(entityName: "Places")
    }

    @NSManaged public var json: String?
    @NSManaged public var userLocation: UserLocation?

}

extension Places : Identifiable {

}
