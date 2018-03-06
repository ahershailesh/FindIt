//
//  SavedImage+CoreDataProperties.swift
//  
//
//  Created by Shailesh Aher on 3/6/18.
//
//

import Foundation
import CoreData


extension SavedImage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SavedImage> {
        return NSFetchRequest<SavedImage>(entityName: "SavedImage")
    }

    @NSManaged public var id: String?
    @NSManaged public var image: NSData?
    @NSManaged public var tag: String?

}
