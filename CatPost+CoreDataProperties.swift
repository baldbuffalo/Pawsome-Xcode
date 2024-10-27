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
    @NSManaged public var catAge: Int16
    @NSManaged public var catBreed: String?
    @NSManaged public var comments: NSSet?

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
