//
//  File.swift
//  
//
//  Created by Sĩ Huỳnh on 03/11/2023.
//

import Vapor
import Fluent

final class Acronym: Model {
	static var schema: String = "acronyms"
	
	@ID
	var id: UUID?
	
	@Field(key: "short")
	var short: String
	
	@Field(key: "long")
	var long: String
	
	@Parent(key: "userID")
	var user: User
	
	@Siblings(
		through: AcronymCategoryPivot.self,
		from: \.$acronym,
		to: \.$category
	)
	var categories: [Category]
	
	
	init() {}
	
	init(id: UUID? = nil, short: String, long: String, userID: User.IDValue) {
		self.id = id
		self.short = short
		self.long = long
		self.$user.id = userID
	}
}

extension Acronym: Content {}
