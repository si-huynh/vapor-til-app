//
//  UserController.swift
//  
//
//  Created by Sĩ Huỳnh on 03/11/2023.
//

import Vapor

struct UsersController: RouteCollection {
	func boot(routes: RoutesBuilder) throws {
		let usersRoute = routes.grouped("api", "users")
		usersRoute.get(use: getAllHandler)
		usersRoute.get(":userID", use: getHandler)
		usersRoute.get(":userID", "acronyms", use: getAcronymsHandler)
		
		let basicAuthMiddleware = User.authenticator()
		let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware)
		basicAuthGroup.post("login", use: loginHandler)
		
		let tokenAuthMiddleware = Token.authenticator()
		let guardAuthMiddleware = User.guardMiddleware()
		
		let tokenAuthGroup = usersRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
		tokenAuthGroup.post(use: createHandler)
	}
	
	func createHandler(_ req: Request) async throws -> User.Public {
		let user = try req.content.decode(User.self)
		user.password = try Bcrypt.hash(user.password)
		
		try await user.save(on: req.db)
		
		return user.convertToPublic()
	}
	
	func getAllHandler(_ req: Request) async throws -> [User.Public] {
		let users = try await User.query(on: req.db).all()
		return users.map { $0.convertToPublic() }
	}
	
	func getHandler(_ req: Request) async throws -> User.Public {
		guard let user = try await User.find(req.parameters.get("userID"), on: req.db)
		else {
			throw Abort(.notFound)
		}
		
		return user.convertToPublic()
	}
	
	func getAcronymsHandler(_ req: Request) async throws -> [Acronym] {
		guard let user = try await User.find(req.parameters.get("userID"), on: req.db)
		else {
			throw Abort(.notFound)
		}
		
		return try await user.$acronyms.get(on: req.db)
	}
	
	func loginHandler(_ req: Request) async throws -> Token {
		let user = try req.auth.require(User.self)
		let token = try Token.generate(for: user)
		
		try await token.save(on: req.db)
		
		return token
	}
}
