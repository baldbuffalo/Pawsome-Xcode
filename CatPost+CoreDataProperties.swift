//
//  CatPost+CoreDataProperties.swift
//  Pawsome
//
//  Created by Rishi Jivani on 27/10/2024.
//
//

import Foundation
import CoreData


extension CatPost {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CatPost> {
        return NSFetchRequest<CatPost>(entityName: "CatPost")
    }

    @NSManaged public var catName: String?
    @NSManaged public var catAge: Int32
    @NSManaged public var catBreed: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var imageData: Data?
    @NSManaged public var username: String?
    @NSManaged public var comments: NSSet?

}

// MARK: Generated accessors for comments
extension CatPost {

    @objc(addCommentsObject:)
    @NSManaged public func addToComments(_ value: Comment)

    @objc(removeCommentsObject:)
    @NSManaged public func removeFromComments(_ value: Comment)

    @objc(addComments:)
    @NSManaged public func addToComments(_ values: NSSet)

    @objc(removeComments:)
    @NSManaged public func removeFromComments(_ values: NSSet)

}

extension CatPost : Identifiable {

}
