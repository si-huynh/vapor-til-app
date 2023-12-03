//
//  User.swift
//  
//
//  Created by Sĩ Huỳnh on 03/11/2023.
//

import Fluent
import Vapor

final class User: Model, Content {
    static let schema: String = User.v20231202.schemaName
	
	@ID
	var id: UUID?
	
    @Field(key: User.v20231202.name)
	var name: String
	
    @Field(key: User.v20231202.username)
	var username: String
	
    @Field(key: User.v20231202.email)
	var email: String
	
	@Children(for: \.$user)
	var acronyms: [Acronym]
	
    @Field(key: User.v20231202.password)
	var password: String
	
    @OptionalField(key: User.v20231202.siwaIdentifier)
	var siwaIdentifier: String?
	
    @OptionalField(key: User.v20231202.profilePicture)
	var profilePicture: String?
    
    @OptionalField(key: User.v20231203.twitterURL)
    var twitterURL: String?
	
	init() {}
	
	init(
		id: UUID? = nil,
		name: String,
		username: String,
		email: String,
		password: String,
		siwaIdentifier: String? = nil,
		profilePicture: String? = nil,
        twitterURL: String? = nil
	) {
		self.name = name
		self.username = username
		self.email = email
		self.password = password
		self.siwaIdentifier = siwaIdentifier
		self.profilePicture = profilePicture
        self.twitterURL = twitterURL
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
    
    final class PublicV2: Content {
        var id: UUID?
        var name: String
        var username: String
        var twitterURL: String?
        
        init(id: UUID?,
             name: String,
             username: String,
             twitterURL: String? = nil
        ) {
            self.id = id
            self.name = name
            self.username = username
            self.twitterURL = twitterURL
        }
    }
}

extension User {
	func convertToPublic() -> User.Public {
		return User.Public(id: id, name: name, username: username)
	}
    
    func convertToPublicV2() -> User.PublicV2 {
        return User.PublicV2(
            id: id,
            name: name,
            username: username,
            twitterURL: twitterURL
        )
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
