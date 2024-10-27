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

    @NSManaged public var age: String?
    @NSManaged public var breed: String?
    @NSManaged public var comments: NSObject?
    @NSManaged public var id: UUID?
    @NSManaged public var imageData: Data?
    @NSManaged public var likes: Int16
    @NSManaged public var location: String?
    @NSManaged public var modificationDate: Date?
    @NSManaged public var name: String?
    @NSManaged public var postDescription: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var username: String?
    @NSManaged public var comment: NSSet?

}

// MARK: Generated accessors for comment
extension CatPost {

    @objc(addCommentObject:)
    @NSManaged public func addToComment(_ value: Comment)

    @objc(removeCommentObject:)
    @NSManaged public func removeFromComment(_ value: Comment)

    @objc(addComment:)
    @NSManaged public func addToComment(_ values: NSSet)

    @objc(removeComment:)
    @NSManaged public func removeFromComment(_ values: NSSet)

}

extension CatPost : Identifiable {

}
