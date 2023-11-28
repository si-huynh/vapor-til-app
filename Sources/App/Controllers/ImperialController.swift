//
//  ImperialController.swift
//  
//
//  Created by Sĩ Huỳnh on 08/11/2023.
//

import ImperialGoogle
import ImperialGitHub
import Vapor
import Fluent

struct ImperialController: RouteCollection {
	func boot(routes: RoutesBuilder) throws {
		guard let googleCallbackURL = Environment.get("GOOGLE_CALLBACK_URL")
		else {
			fatalError("Google Callback URL not set")
		}
		
		try routes.oAuth(
			from: Google.self,
			authenticate: "login-google",
			authenticateCallback: nil,
			callback: googleCallbackURL,
			scope: ["profile", "email"],
			completion: processGoogleLogin)
		
		guard let githubCallbackURL = Environment.get("GITHUB_CALLBACK_URL")
		else {
			fatalError("Github Callback URL not set")
		}
		
		try routes.oAuth(
			from: GitHub.self,
			authenticate: "login-github",
			callback: githubCallbackURL,
			completion: processGithubLogin
		)
	}
	
	func processGoogleLogin(request: Request, token: String) throws -> EventLoopFuture<ResponseEncodable> {
		return try Google.getUser(on: request)
			.flatMap { user in
				User.query(on: request.db)
					.filter(\.$username == user.email)
					.first()
					.flatMap { foundUser in
						guard let existingUser = foundUser
						else {
							let newUser = User(
								name: user.name,
								username: user.email,
								password: UUID().uuidString
							)
							return newUser.save(on: request.db)
								.map {
									request.session.authenticate(newUser)
									return request.redirect(to: "/")
								}
						}
						request.session.authenticate(existingUser)
						return request.eventLoop.future(request.redirect(to: "/"))
					}
			}
	}
	
	func processGithubLogin(request: Request, token: String) throws -> EventLoopFuture<ResponseEncodable> {
		return try GitHub.getUser(on: request)
			.flatMap { userInfo in
				return User.query(on: request.db)
					.filter(\.$username == userInfo.login)
					.first()
					.flatMap { foundUser in
						guard let existingUser = foundUser
						else {
							let user = User(name: userInfo.name, username: userInfo.login, password: UUID().uuidString)
							return user.save(on: request.db)
								.map {
									request.session.authenticate(user)
									return request.redirect(to: "/")
								}
						}
						request.session.authenticate(existingUser)
						return request.eventLoop.future(request.redirect(to: "/"))
					}
			}
	}
}

struct GoogleUserInfo: Content {
	let email: String
	let name: String
}

extension Google {
	static func getUser(on request: Request) async throws -> GoogleUserInfo {
		var headers = HTTPHeaders()
		headers.bearerAuthorization = try BearerAuthorization(token: request.accessToken())
		
		// https://accounts.google.com/o/oauth2/v2/auth
		let googleAPIURL: URI = "https://www.googleapis.com/oauth2/v1/userinfo?alt=json"
		
		let response = try await request.client.get(googleAPIURL, headers: headers)
		
		guard response.status == .ok
		else {
			if response.status == .unauthorized {
				throw Abort.redirect(to: "/login-google")
			} else {
				throw Abort(.internalServerError)
			}
		}
		
		return try response.content.decode(GoogleUserInfo.self)
	}
	
	static func getUser(on request: Request) throws -> EventLoopFuture<GoogleUserInfo> {
		var headers = HTTPHeaders()
		headers.bearerAuthorization = try BearerAuthorization(token: request.accessToken())
		
		// https://accounts.google.com/o/oauth2/v2/auth
		let googleAPIURL: URI = "https://www.googleapis.com/oauth2/v1/userinfo?alt=json"
		
		return request.client.get(googleAPIURL, headers: headers)
			.flatMapThrowing { response in
				guard response.status == .ok
				else {
					if response.status == .unauthorized {
						throw Abort.redirect(to: "/login-google")
					} else {
						throw Abort(.internalServerError)
					}
				}
				
				return try response.content.decode(GoogleUserInfo.self)
			}
	}
}

struct GitHubUserInfo: Content {
	let name: String
	let login: String
}

extension GitHub {
	static func getUser(on request: Request) throws -> EventLoopFuture<GitHubUserInfo> {
		var headers = HTTPHeaders()
		try headers.add(name: .authorization, value: "token \(request.accessToken())")
		headers.add(name: .userAgent, value: "vapor")
		
		let githubUserAPIURL: URI = "https://api.github.com/user"
		
		return request.client.get(githubUserAPIURL, headers: headers)
			.flatMapThrowing { response in
				guard response.status == .ok else {
					if response.status == .unauthorized {
						throw Abort.redirect(to: "/login-github")
					} else {
						throw Abort(.internalServerError)
					}
				}
				
				return try response.content.decode(GitHubUserInfo.self)
			}
	}
}
