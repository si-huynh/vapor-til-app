//
//  Token.swift
//  
//
//  Created by Sĩ Huỳnh on 05/11/2023.
//

import Vapor
import Fluent

final class Token: Model, Content {
    static let schema: String = Token.v20231202.schemaName
	
	@ID
	var id: UUID?
	
    @Field(key: Token.v20231202.value)
	var value: String
	
    @Parent(key: Token.v20231202.userID)
	var user: User
	
	init() {}
	
	init(id: UUID? = nil, value: String, userID: User.IDValue) {
		self.id = id
		self.value = value
		self.$user.id = userID
	}
}

extension Token {
	static func generate(for user: User) throws -> Token {
		let random = [UInt8].random(count: 16).base64
		return try Token(value: random, userID: user.requireID())
	}
}

extension Token: ModelTokenAuthenticatable {
	static var valueKey: KeyPath<Token, Field<String>> = \Token.$value
	static let userKey: KeyPath<Token, Parent<User>> = \Token.$user
	
	typealias User = App.User
	
	var isValid: Bool { true }
}
