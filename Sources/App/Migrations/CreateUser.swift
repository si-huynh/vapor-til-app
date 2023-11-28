//
//  CreateUser.swift
//  
//
//  Created by Sĩ Huỳnh on 03/11/2023.
//

import Fluent

struct CreateUser: Migration {
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		database.schema(User.schema)
			.id()
			.field("name", .string, .required)
			.field("username", .string, .required)
			.field("password", .string, .required)
			.field("siwaIdentifier", .string)
			.unique(on: "username")
			.create()
	}
	
	func revert(on database: Database) -> EventLoopFuture<Void> {
		database.schema("users").delete()
	}
}
