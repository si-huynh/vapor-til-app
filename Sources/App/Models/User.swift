//
//  User.swift
//  
//
//  Created by Sĩ Huỳnh on 03/11/2023.
//

import Fluent
import Vapor

final class User: Model, Content {
	static let schema: String = "users"
	
	@ID
	var id: UUID?
	
	@Field(key: "name")
	var name: String
	
	@Field(key: "username")
	var username: String
	
	@Children(for: \.$user)
	var acronyms: [Acronym]
	
	@Field(key: "password")
	var password: String
	
	@OptionalField(key: "siwaIdentifier")
	var siwaIdentifier: String?
	
	init() {}
	
	init(id: UUID? = nil, name: String, username: String, password: String, siwaIdentifier: String?) {
		self.name = name
		self.username = username
		self.password = password
		self.siwaIdentifier = siwaIdentifier
	}
	
	final class Public: Content {
		var id: UUID?
		var name: String
		var username: String
		
		init(id: UUID? = nil, name: String, username: String) {
			self.id = id
			self.name = name
			self.username = username
		}
	}
}

extension User {
	func convertToPublic() -> User.Public {
		return User.Public(id: id, name: name, username: username)
	}
}

extension User: ModelAuthenticatable {
	static var usernameKey: KeyPath<User, Field<String>> = \User.$username
	static var passwordHashKey: KeyPath<User, Field<String>> = \User.$password
	
	func verify(password: String) throws -> Bool {
		try Bcrypt.verify(password, created: self.password)
	}
}

extension User: ModelSessionAuthenticatable {}

extension User: ModelCredentialsAuthenticatable {}
