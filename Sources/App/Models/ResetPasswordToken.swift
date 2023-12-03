//
//  ResetPasswordToken.swift
//  
//
//  Created by Sĩ Huỳnh on 30/11/2023.
//

import Fluent
import Vapor

final class ResetPasswordToken: Model, Content {
    static var schema: String = ResetPasswordToken.v20231202.schemaName
	
	@ID
	var id: UUID?
	
    @Field(key: ResetPasswordToken.v20231202.token)
	var token: String
	
    @Parent(key: ResetPasswordToken.v20231202.userID)
	var user: User
	
	init() {}
	
	init(id: UUID? = nil, token: String, userID: User.IDValue) {
		self.id = id
		self.token = token
		self.$user.id = userID
	}
}
