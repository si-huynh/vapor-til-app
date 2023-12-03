//
//  AcronymCategoryPivot.swift
//  
//
//  Created by Sĩ Huỳnh on 04/11/2023.
//

import Fluent

final class AcronymCategoryPivot: Model {
    static var schema: String = AcronymCategoryPivot.v20231202.schemaName
	
	@ID
	var id: UUID?
	
	@Parent(key: AcronymCategoryPivot.v20231202.acronymID)
	var acronym: Acronym
	
	@Parent(key: AcronymCategoryPivot.v20231202.categoryID)
	var category: Category
	
	init() {}
	
	init(id: UUID? = nil, acronym: Acronym, category: Category) throws {
		self.id = id
		self.$acronym.id = try acronym.requireID()
		self.$category.id = try category.requireID()
	}
}
