//
//  Comment+CoreDataProperties.swift
//  Pawsome
//
//  Created by Rishi Jivani on 27/10/2024.
//
//

import Foundation
import CoreData


extension Comment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Comment> {
        return NSFetchRequest<Comment>(entityName: "Comment")
    }

    @NSManaged public var catPost: CatPost?

}

extension Comment : Identifiable {

}
