//
//  SavedImage+CoreDataClass.swift
//  
//
//  Created by Shailesh Aher on 3/6/18.
//
//

import Foundation
import CoreData

@objc(SavedImage)
public class SavedImage: NSManagedObject {
    convenience init(tag: String, pic: NSData, id: String, contenxt: NSManagedObjectContext) {
        if let entityDescription = NSEntityDescription.entity(forEntityName: "SavedImage", in: contenxt) {
            self.init(entity: entityDescription, insertInto: contenxt)
            self.tag = tag
            self.image = pic
            self.id = id
        } else {
            fatalError("cannot able to fetch Location")
        }
    }
}
