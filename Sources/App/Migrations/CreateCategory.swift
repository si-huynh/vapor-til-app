//
//  CreateCategory.swift
//  
//
//  Created by Sĩ Huỳnh on 04/11/2023.
//

import Fluent

struct CreateCategory: Migration {
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		database.schema(Category.schema)
			.id()
			.field("name", .string, .required)
			.create()
	}
	
	func revert(on database: Database) -> EventLoopFuture<Void> {
		database.schema(Category.schema).delete()
	}
}
