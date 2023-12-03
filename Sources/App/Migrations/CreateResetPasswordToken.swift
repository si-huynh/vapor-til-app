//
//  CreateResetPasswordToken.swift
//  
//
//  Created by Sĩ Huỳnh on 30/11/2023.
//

import Fluent

struct CreateResetPasswordToken: Migration {
	func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(ResetPasswordToken.v20231202.schemaName)
			.id()
            .field(ResetPasswordToken.v20231202.token, .string, .required)
            .field(
                ResetPasswordToken.v20231202.userID,
                .uuid, .required,
                .references(User.v20231202.schemaName, User.v20231202.id)
            )
            .unique(on: ResetPasswordToken.v20231202.token)
			.create()
	}
	
	func revert(on database: Database) -> EventLoopFuture<Void> {
		database.schema(ResetPasswordToken.schema).delete()
	}
}

extension ResetPasswordToken {
    enum v20231202 {
        static let schemaName = "resetPasswordTokens"
        
        static let token = FieldKey(stringLiteral: "token")
        static let userID = FieldKey(stringLiteral: "userID")
    }
}
