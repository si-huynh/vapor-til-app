//
//  Category.swift
//  
//
//  Created by Sĩ Huỳnh on 04/11/2023.
//

import Fluent
import Vapor

final class Category: Model, Content {
    static var schema: String = Category.v20231202.schemaName
	
	@ID
	var id: UUID?
	
    @Field(key: Category.v20231202.name)
	var name: String
	
	@Siblings(through: AcronymCategoryPivot.self, from: \.$category, to: \.$acronym)
	var acronyms: [Acronym]
	
	init() {}
	
	init(id: UUID? = nil, name: String) {
		self.id = id
		self.name = name
	}
}

extension Category {
	static func addCategory(_ name: String, to acronym: Acronym, on req: Request) async throws -> Void {
		guard let foundCategory = try await Category.query(on: req.db).filter(\.$name == name).first()
		else {
			let category = Category(name: name)
			try await category.save(on: req.db)
			try await acronym.$categories.attach(category, on: req.db)
			return
		}
		
		try await acronym.$categories.attach(foundCategory, on: req.db)
	}
}
