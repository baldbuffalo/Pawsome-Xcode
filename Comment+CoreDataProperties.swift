//
//  Comment+CoreDataProperties.swift
//  Pawsome
//
//  Created by Rishi Jivani on 29/10/2024.
//
//

import Foundation
import CoreData


extension Comment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Comment> {
        return NSFetchRequest<Comment>(entityName: "Comment")
    }

    @NSManaged public var profilePicture: Data?
    @NSManaged public var text: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var username: String?
    @NSManaged public var catPost: CatPost?

}

extension Comment : Identifiable {

}
