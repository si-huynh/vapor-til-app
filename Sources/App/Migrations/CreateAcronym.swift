//
//  CreateAcronym.swift
//
//
//  Created by Sĩ Huỳnh on 03/11/2023.
//

import Fluent

struct CreateAcronym: Migration {
	func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Acronym.v20231202.schemaName)
			.id()
            .field(Acronym.v20231202.short, .string, .required)
            .field(Acronym.v20231202.long, .string, .required)
            .field(
                Acronym.v20231202.userID,
                .uuid, .required,
                .references(User.v20231202.schemaName, User.v20231202.id))
			.create()
	}
	
	func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Acronym.v20231202.schemaName).delete()
	}
}

extension Acronym {
    enum v20231202 {
        static let schemaName = "acronyms"
        
        static let id = FieldKey(stringLiteral: "id")
        static let short = FieldKey(stringLiteral: "short")
        static let long = FieldKey(stringLiteral: "long")
        static let userID = FieldKey(stringLiteral: "userID")
    }
}
