//
//  CreateAdminUser.swift
//  
//
//  Created by Sĩ Huỳnh on 05/11/2023.
//

import Fluent
import Vapor

struct CreateAdminUser: Migration {
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		let passwordHash: String
		do {
			passwordHash = try Bcrypt.hash("password")
		} catch {
			return database.eventLoop.future(error: error)
		}
		let user = User(
            userType: UserType.standard,
			name: "Admin",
			username: "admin",
			email: "admin@localhost.local",
			password: passwordHash
		)
		return user.save(on: database)
	}
	
	func revert(on database: Database) -> EventLoopFuture<Void> {
		User.query(on: database).filter(\.$username == "admin").delete()
	}
}
