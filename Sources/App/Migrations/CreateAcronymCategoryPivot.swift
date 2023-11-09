//
//  CreateAcronymCategoryPivot.swift
//  
//
//  Created by Sĩ Huỳnh on 04/11/2023.
//

import Fluent

struct CreateAcronymCategoryPivot: Migration {
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		database.schema(AcronymCategoryPivot.schema)
			.id()
			.field("acronymID", .uuid, .required, .references("acronyms", "id", onDelete: .cascade))
			.field("categoryID", .uuid, .required, .references("categories", "id", onDelete: .cascade))
			.create()
	}
	
	func revert(on database: Database) -> EventLoopFuture<Void> {
		database.schema(AcronymCategoryPivot.schema).delete()
	}
}
