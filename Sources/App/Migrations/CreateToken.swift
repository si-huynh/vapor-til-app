//
//  CreateToken.swift
//  
//
//  Created by Sĩ Huỳnh on 05/11/2023.
//

import Fluent

struct CreateToken: Migration {
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		database.schema(Token.schema)
			.id()
			.field("value", .string, .required)
			.field("userID", .uuid, .required, .references("users", "id", onDelete: .cascade))
			.create()
	}
	
	func revert(on database: Database) -> EventLoopFuture<Void> {
		database.schema(Token.schema).delete()
	}
}
