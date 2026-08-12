//
//  CollectionItem.swift
//  my-collection
//
//  Created by Ma Jade on 2026/8/12.
//

import Foundation

struct CollectionItem: Codable, Identifiable {
    var id: String
    var imageFileName: String
    var name: String?
    var category: [String]?
    var source: String?
    var price: String?
    var location: String?
    var createDate: Date
    var modifyDate: Date?

    init(
        id: String = UUID().uuidString,
        imageFileName: String,
        name: String? = nil,
        category: [String]? = nil,
        source: String? = nil,
        price: String? = nil,
        location: String? = nil,
        createDate: Date = Date(),
        modifyDate: Date? = nil
    ) {
        self.id = id
        self.imageFileName = imageFileName
        self.name = name
        self.category = category
        self.source = source
        self.price = price
        self.location = location
        self.createDate = createDate
        self.modifyDate = modifyDate
    }
}
