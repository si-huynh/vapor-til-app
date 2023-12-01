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
			.field("email", .string, .required)
			.field("siwaIdentifier", .string)
			.field("profilePicture", .string)
			.unique(on: "username")
			.unique(on: "email")
			.create()
	}
	
	func revert(on database: Database) -> EventLoopFuture<Void> {
		database.schema("users").delete()
	}
}
