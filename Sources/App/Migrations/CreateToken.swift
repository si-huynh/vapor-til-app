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
            .field(Token.v20231202.value, .string, .required)
            .field(
                Token.v20231202.userID,
                .uuid, .required,
                .references(User.v20231202.schemaName, User.v20231202.id, onDelete: .cascade)
            )
			.create()
	}
	
	func revert(on database: Database) -> EventLoopFuture<Void> {
		database.schema(Token.schema).delete()
	}
}

extension Token {
    enum v20231202 {
        static let schemaName = "tokens"
        
        static let value = FieldKey(stringLiteral: "value")
        static let userID = FieldKey(stringLiteral: "userID")
    }
}
