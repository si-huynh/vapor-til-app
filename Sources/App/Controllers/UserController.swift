//
//  UserController.swift
//  
//
//  Created by Sĩ Huỳnh on 03/11/2023.
//

import Vapor
import JWT
import Fluent

struct UsersController: RouteCollection {
	func boot(routes: RoutesBuilder) throws {
		let usersRoute = routes.grouped("api", "users")
		usersRoute.get(use: getAllHandler)
		usersRoute.get(":userID", use: getHandler)
		usersRoute.get(":userID", "acronyms", use: getAcronymsHandler)
		usersRoute.post("siwa", use: signInWithApple)
        usersRoute.get("mostRecentAcronym", use: getUserWithMostRecentAcronym)
        
        let usersRouteV2 = routes.grouped("api", "v2", "users")
        usersRouteV2.get(":userID", use: getV2Handler)
		
		let basicAuthMiddleware = User.authenticator()
		let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware)
		basicAuthGroup.post("login", use: loginHandler)
		
		let tokenAuthMiddleware = Token.authenticator()
		let guardAuthMiddleware = User.guardMiddleware()
		
		let tokenAuthGroup = usersRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
		tokenAuthGroup.post(use: createHandler)
        tokenAuthGroup.delete(":userID", use: deleteHandler)
        tokenAuthGroup.post(":userID", "restore", use: restoreHandler)
        tokenAuthGroup.delete(":userID", "force", use: forceDeleteHandler)
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
    
    func getV2Handler(_ req: Request) async throws -> User.PublicV2 {
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db)
        else {
            throw Abort(.notFound)
        }
        
        return user.convertToPublicV2()
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
    
    func deleteHandler(_ req: Request) async throws -> HTTPStatus {
        let requestUser = try req.auth.require(User.self)
        guard requestUser.userType == .admin
        else {
            throw Abort(.forbidden)
        }
        
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db)
        else {
            return .notFound
        }
        
        do {
            try await user.delete(on: req.db)
            return .noContent
        } catch {
            return .internalServerError
        }
    }
    
    func restoreHandler(_ req: Request) async throws -> HTTPStatus {
        let userID = try req.parameters.require("userID", as: UUID.self)
        guard let user = try await User.query(on: req.db)
            .withDeleted()
            .filter(\.$id == userID)
            .first()
        else {
            return .notFound
        }
        
        do {
            try await user.restore(on: req.db)
            return .ok
        } catch {
            return .internalServerError
        }
    }
    
    func forceDeleteHandler(_ req: Request) async throws -> HTTPStatus {
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db)
        else {
            return .notFound
        }
        
        do {
            try await user.delete(force: true, on: req.db)
            return .noContent
        } catch {
            return .internalServerError
        }
    }
	
	func signInWithApple(_ req: Request) async throws -> Token {
		let data = try req.content.decode(SignInWithAppleToken.self)
		
		guard let appIdentifier = Environment.get("IOS_APPLICATION_IDENTIFIER")
		else {
			throw Abort(.internalServerError)
		}
		
		let siwaToken = try await req.jwt.apple.verify(data.token, applicationIdentifier: appIdentifier)
		let user = try await User.query(on: req.db)
			.filter(\.$siwaIdentifier == siwaToken.subject.value)
			.first()
		if let user = user {
			return try await createTokenForUser(user, req: req)
		} else {
			guard let email = siwaToken.email, let name = data.name
			else {
				throw Abort(.badRequest)
			}
			
			let user = User(
				name: name,
				username: email,
				email: email,
				password: UUID().uuidString,
				siwaIdentifier: siwaToken.subject.value
			)
			try await user.save(on: req.db)
			
			return try await createTokenForUser(user, req: req)
		}
	}
	
	func createTokenForUser(_ user: User, req: Request) async throws -> Token {
		let token = try Token.generate(for: user)
		try await token.save(on: req.db)
		return token
	}
    
    func getUserWithMostRecentAcronym(_ req: Request) async throws -> User.PublicV2 {
        guard let user = try await User.query(on: req.db).join(Acronym.self, on: \Acronym.$user.$id == \User.$id)
            .sort(Acronym.self, \Acronym.$createdAt, .descending)
            .first()
        else {
            throw Abort(.internalServerError)
        }
        
        return user.convertToPublicV2()
    }
}

struct SignInWithAppleToken: Content {
	let token: String
	let name: String?
}
