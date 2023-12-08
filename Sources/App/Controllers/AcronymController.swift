//
//  AcronymController.swift
//
//
//  Created by Sĩ Huỳnh on 03/11/2023.
//

import Vapor
import Fluent

struct AcronymController: RouteCollection {
	func boot(routes: RoutesBuilder) throws {
		let acronymsRoutes = routes.grouped("api", "acronyms")
		
		acronymsRoutes.get(use: getAllHandler)
		acronymsRoutes.get(":acronymID", use: getHandler)
		acronymsRoutes.get(":acronymID", "user", use: getUserHandler)
		acronymsRoutes.get(":acronymID", "categories", use: getCategoriesHandler)

		acronymsRoutes.get("search", use: searchHandler)
		acronymsRoutes.get("first", use: getFirstHandler)
		acronymsRoutes.get("sorted", use: sortedHandler)
        acronymsRoutes.get("mostRecent", use: getMostRecentAcronyms)
		
		let tokenAuthMiddleware = Token.authenticator()
		let guardAuthMiddleware = User.guardMiddleware()
		
		let tokenAuthGroup = acronymsRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
		tokenAuthGroup.post(use: createHandler)
		
		tokenAuthGroup.put(":acronymID", use: updateHandler)
		tokenAuthGroup.delete(":acronymID", use: deleteHandler)
		
		tokenAuthGroup.post(":acronymID", "categories", ":categoryID", use: addCategoriesHandler)
		tokenAuthGroup.delete(":acronymID", "categories", ":categoryID", use: removeCategoriesHandler)
	}
	
	func getAllHandler(_ req: Request) async throws -> [Acronym] {
		try await Acronym.query(on: req.db).all()
	}
	
	func createHandler(_ req: Request) async throws -> Acronym {
		let data = try req.content.decode(CreateAcronymData.self)
		let user = try req.auth.require(User.self)
		let acronym = try Acronym(
			short: data.short,
			long: data.long,
			userID: user.requireID()
		)
		
		try await acronym.save(on: req.db)
		
		return acronym
	}
	
	func getHandler(_ req: Request) async throws -> Acronym {
		guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db)
		else {
			throw Abort(.notFound)
		}
		return acronym
	}
	
	func updateHandler(_ req: Request) async throws -> Acronym {
		let updatedAcronym = try req.content.decode(CreateAcronymData.self)
		
		let user = try req.auth.require(User.self)
		let userID = try user.requireID()
		
		guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db)
		else {
			throw Abort(.notFound)
		}
		
		acronym.short = updatedAcronym.short
		acronym.long = updatedAcronym.long
		acronym.$user.id = userID
		
		try await acronym.save(on: req.db)
		
		return acronym
	}
	
	func deleteHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
		Acronym.find(req.parameters.get("acronymID"), on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMap { acronym in
				acronym.delete(on: req.db)
					.transform(to: .noContent)
			}
	}
	
	func searchHandler(_ req: Request) throws -> EventLoopFuture<[Acronym]> {
		guard let searchTerm = req.query[String.self, at: "term"]
		else {
			throw Abort(.badRequest)
		}
		
		return Acronym.query(on: req.db).group(.or) { or in
			or.filter(\.$short == searchTerm)
			or.filter(\.$long == searchTerm)
		}
		.all()
	}
	
	func getFirstHandler(_ req: Request) -> EventLoopFuture<Acronym> {
		return Acronym.query(on: req.db)
			.first()
			.unwrap(or: Abort(.notFound))
	}
	
	func sortedHandler(_ req: Request) -> EventLoopFuture<[Acronym]> {
		return Acronym.query(on: req.db)
			.sort(\.$short, .ascending).all()
	}
	
	func getUserHandler(_ req: Request) -> EventLoopFuture<User> {
		Acronym.find(req.parameters.get("acronymID"), on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMap { acronym in
				acronym.$user.get(on: req.db)
			}
	}
	
	func addCategoriesHandler(_ req: Request) -> EventLoopFuture<HTTPStatus> {
		let acronymQuery = Acronym.find(req.parameters.get("acronymID"), on: req.db)
			.unwrap(or: Abort(.notFound))
		let categoryQuery = Category.find(req.parameters.get("categoryID"), on: req.db)
			.unwrap(or: Abort(.notFound))
		
		return acronymQuery.and(categoryQuery)
			.flatMap { acronym, category in
				acronym.$categories
					.attach(category, on: req.db)
					.transform(to: .created)
			}
	}
	
	func getCategoriesHandler(_ req: Request) -> EventLoopFuture<[Category]> {
		Acronym.find(req.parameters.get("acronymID"), on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMap { acronym in
				acronym.$categories.query(on: req.db).all()
			}
	}
	
	func removeCategoriesHandler(_ req: Request) -> EventLoopFuture<HTTPStatus> {
		let acronymQuery = Acronym.find(req.parameters.get("acronymID"), on: req.db)
			.unwrap(or: Abort(.notFound))
		let categoryQuery = Category.find(req.parameters.get("categoryID"), on: req.db)
			.unwrap(or: Abort(.notFound))
		
		return acronymQuery.and(categoryQuery)
			.flatMap { acronym, category in
				acronym.$categories
					.detach(category, on: req.db)
					.transform(to: .noContent)
			}
	}
    
    func getMostRecentAcronyms(_ req: Request) async throws -> [Acronym] {
        try await Acronym.query(on: req.db).sort(\.$updatedAt, .descending).all()
    }
}

struct CreateAcronymData: Content {
	let short: String
	let long: String
}
