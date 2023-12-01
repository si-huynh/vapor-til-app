//
//  Models+Testable.swift
//  
//
//  Created by Sĩ Huỳnh on 04/11/2023.
//

@testable import App
import Fluent
import Vapor

extension User {
	static func create(
		name: String = "Luke",
		username: String? = nil,
		on database: Database
	) async throws -> User {
		let createUserName: String
		
		if let suppliedUsername = username {
			createUserName = suppliedUsername
		} else {
			createUserName = UUID().uuidString
		}
		
		let password = try Bcrypt.hash("password")
		let user = User(
			name: name,
			username: createUserName,
			email: "\(createUserName)@test.com",
			password: password
		)
		try await user.save(on: database)
		
		return user
	}
}

extension Acronym {
	static func create(
		short: String = "TIL",
		long: String = "Today I Learned",
		user: User? = nil,
		on database: Database
	) async throws -> Acronym {
		var acronymUser = user
		if acronymUser == nil {
			acronymUser = try await User.create(on: database)
		}
		
		let acronym = Acronym(short: short, long: long, userID: acronymUser!.id!)
		try await acronym.save(on: database)
		
		return acronym
	}
}

extension App.Category {
	static func create(name: String = "Random", on database: Database) async throws -> App.Category {
		let category = Category(name: name)
		try await category.save(on: database)
		return category
	}
}
