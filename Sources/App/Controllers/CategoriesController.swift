//
//  CategoriesController.swift
//  
//
//  Created by Sĩ Huỳnh on 04/11/2023.
//

import Vapor

struct CategoriesController: RouteCollection {
	func boot(routes: RoutesBuilder) throws {
		let categoriesRoute = routes.grouped("api", "categories")
		categoriesRoute.get(use: getAllHandler)
		categoriesRoute.get(":categoryID", use: getHandler)
		categoriesRoute.get(":categoryID", "acronyms", use: getAcronymsHandler)
        categoriesRoute.get("acronyms", use: getAllCategoriesWithAcronymsAndUser)
		
		let tokenAuthMiddleware = Token.authenticator()
		let guardAuthMiddleware = User.guardMiddleware()
		
		let tokenAuthGroup = categoriesRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
		tokenAuthGroup.post(use: createHandler)
	}
	
	func createHandler(_ req: Request) throws -> EventLoopFuture<Category> {
		let category = try req.content.decode(Category.self)
		return category.save(on: req.db).map { category }
	}
	
	func getAllHandler(_ req: Request) -> EventLoopFuture<[Category]> {
		Category.query(on: req.db).all()
	}
	
	func getHandler(_ req: Request) -> EventLoopFuture<Category> {
		return Category.find(req.parameters.get("categoryID"), on: req.db)
			.unwrap(or: Abort(.notFound))
	}
		
	func getAcronymsHandler(_ req: Request) -> EventLoopFuture<[Acronym]> {
		Category.find(req.parameters.get("categoryID"), on: req.db)
			.unwrap(or: Abort(.notFound))
			.flatMap { category in
				category.$acronyms.get(on: req.db)
			}
	}
    
    func getAllCategoriesWithAcronymsAndUser(_ req: Request) async throws -> [CategoryWithAcronyms] {
        let categories = try await Category.query(on: req.db)
            .with(\.$acronyms) { acronyms in
                acronyms.with(\.$user)
            }
            .all()
        
        return categories.map { category in
            let categoryAcronyms = category.acronyms.map {
                AcronymWithUser(
                    id: $0.id,
                    short: $0.short,
                    long: $0.long,
                    user: $0.user.convertToPublic()
                )
            }
            
            return CategoryWithAcronyms(
                id: category.id,
                name: category.name,
                acronyms: categoryAcronyms
            )
        }
    }
}

struct AcronymWithUser: Content {
    let id: UUID?
    let short: String
    let long: String
    let user: User.Public
}

struct CategoryWithAcronyms: Content {
    let id: UUID?
    let name: String
    let acronyms: [AcronymWithUser]
}
