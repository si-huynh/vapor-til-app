//
//  CreateUser.swift
//  
//
//  Created by Sĩ Huỳnh on 03/11/2023.
//

import Fluent

struct CreateUser: Migration {
	func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.v20231202.schemaName)
			.id()
            .field(User.v20231202.name, .string, .required)
            .field(User.v20231202.username, .string, .required)
            .field(User.v20231202.password, .string, .required)
            .field(User.v20231202.email, .string, .required)
            .field(User.v20231202.siwaIdentifier, .string)
            .field(User.v20231202.profilePicture, .string)
            .unique(on: User.v20231202.username)
            .unique(on: User.v20231202.email)
			.create()
	}
	
	func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.v20231202.schemaName).delete()
	}
}

extension User {
    enum v20231202 {
        static let schemaName = "users"
        
        static let id = FieldKey(stringLiteral: "id")
        static let name = FieldKey(stringLiteral: "name")
        static let username = FieldKey(stringLiteral: "username")
        static let password = FieldKey(stringLiteral: "password")
        static let email = FieldKey(stringLiteral: "email")
        static let siwaIdentifier = FieldKey(stringLiteral: "siwaIdentifier")
        static let profilePicture = FieldKey(stringLiteral: "profilePicture")
    }
    
    enum v20231203 {
        static let twitterURL = FieldKey(stringLiteral: "twitterURL")
    }
}
