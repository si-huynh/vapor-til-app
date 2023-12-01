//
//  ResetPasswordToken.swift
//  
//
//  Created by Sĩ Huỳnh on 30/11/2023.
//

import Fluent
import Vapor

final class ResetPasswordToken: Model, Content {
	static var schema: String = "resetPasswordTokens"
	
	@ID
	var id: UUID?
	
	@Field(key: "token")
	var token: String
	
	@Parent(key: "userID")
	var user: User
	
	init() {}
	
	init(id: UUID? = nil, token: String, userID: User.IDValue) {
		self.id = id
		self.token = token
		self.$user.id = userID
	}
}
