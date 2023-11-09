//
//  CreateAcronym.swift
//
//
//  Created by Sĩ Huỳnh on 03/11/2023.
//

import Fluent

struct CreateAcronym: Migration {
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		database.schema(Acronym.schema)
			.id()
			.field("short", .string, .required)
			.field("long", .string, .required)
			.field("userID", .uuid, .required, .references("users", "id"))
			.create()
	}
	
	func revert(on database: Database) -> EventLoopFuture<Void> {
		database.schema(Acronym.schema).delete()
	}
}
