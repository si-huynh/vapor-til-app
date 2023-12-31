//
//  WebsiteController.swift
//
//
//  Created by Sĩ Huỳnh on 04/11/2023.
//

import Vapor
import Leaf
import Fluent
import SendGrid

struct WebsiteController: RouteCollection {
	let imageFolder = "ProfilePictures/"
	
	func boot(routes: RoutesBuilder) throws {
		let authSessionsRoutes = routes.grouped(User.sessionAuthenticator())
		authSessionsRoutes.get("login", use: loginHandler)
		authSessionsRoutes.post("logout", use: logoutHandler)

		let credentialsAuthRoutes = authSessionsRoutes.grouped(User.credentialsAuthenticator())
		credentialsAuthRoutes.post("login", use: loginPostHandler)
		
		authSessionsRoutes.get(use: indexHandler)
		authSessionsRoutes.get("acronyms", ":acronymID", use: acronymHandler)
		authSessionsRoutes.get("users", ":userID", use: userHandler)
		authSessionsRoutes.get("users", use: allUsersHandler)
		
		authSessionsRoutes.get("categories", use: allCategoriesHandler)
		authSessionsRoutes.get("categories", ":categoryID", use: categoryHandler)
		
		authSessionsRoutes.get("register", use: registerHandler)
		authSessionsRoutes.post("register", use: registerPostHandler)

		authSessionsRoutes.post("login", "siwa", "callback", use: appleAuthCallbackHandler)
		authSessionsRoutes.post("login", "siwa", "handle", use: appleAuthRedirectHandler)
		
		authSessionsRoutes.get("forgottenPassword", use: forgottenPasswordHandler)
		authSessionsRoutes.post("forgottenPassword", use: forgottenPasswordPostHandler)
		authSessionsRoutes.get("resetPassword", use: resetPasswordHandler)
		authSessionsRoutes.post("resetPassword", use: resetPasswordPostHandler)
		
		authSessionsRoutes.get("users", ":userID", "profilePicture", use: getUserProfilePictureHandler)
		
		let protectedRoutes = authSessionsRoutes.grouped(User.redirectMiddleware(path: "/login"))
		
		protectedRoutes.get("acronyms", "create", use: createAcronymHandler)
		protectedRoutes.post("acronyms", "create", use: createAcronymPostHandler)
		
		protectedRoutes.get("acronyms", ":acronymID", "edit", use: editAcronymHandler)
		protectedRoutes.post("acronyms", ":acronymID", "edit", use: editAcronymPostHandler)
		
		protectedRoutes.post("acronyms", ":acronymID", "delete", use: deleteAcronymHandler)
		
		protectedRoutes.get("users", ":userID", "addProfilePicture", use: addProfilePictureHandler)
		protectedRoutes.on(
			.POST,
			"users", ":userID", "addProfilePicture",
			body: .collect(maxSize: "10mb"),
			use: addProfilePicturePostHandler
		)
	}
	
	func indexHandler(_ req: Request) async throws -> View {
		let acronyms = try await Acronym.query(on: req.db).all()
		let userLoggedIn = req.auth.has(User.self)
		let showCookieMessage = req.cookies["cookies-accepted"] == nil
		let context = IndexContext(
			title: "Home page",
			acronyms: acronyms,
			userLoggedIn: userLoggedIn,
			showCookieMessage: showCookieMessage
		)
		return try await req.view.render("index", context)
	}
	
	func acronymHandler(_ req: Request) async throws -> View {
		guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db)
		else {
			throw Abort(.notFound)
		}
		
		let user = try await acronym.$user.get(on: req.db)
		let categories = try await acronym.$categories.get(on: req.db)
		
		let context = AcronymContext(
			title: acronym.short,
			acronym: acronym,
			user: user,
			categories: categories
		)
		return try await req.view.render("acronym", context)
	}
	
	func userHandler(_ req: Request) async throws -> View {
		guard let user = try await User.find(req.parameters.get("userID"), on: req.db)
		else {
			throw Abort(.notFound)
		}
		
		let acronyms = try await user.$acronyms.get(on: req.db)
		let context = UserContext(
			title: user.name,
			user: user,
			acronyms: acronyms,
			authenticatedUser: user
		)
		return try await req.view.render("user", context)
	}
	
	func allUsersHandler(_ req: Request) async throws -> View {
		let users = try await User.query(on: req.db).all()
		let context = AllUsersContext(title: "All Users", users: users)
		return try await req.view.render("allUsers", context)
	}
	
	func allCategoriesHandler(_ req: Request) async throws -> View {
		let categories = try await Category.query(on: req.db).all()
		let context = AllCategoriesContext(categories: categories)
		return try await req.view.render("allCategories", context)
	}
	
	func categoryHandler(_ req: Request) async throws -> View {
		guard let category = try await Category.find(req.parameters.get("categoryID"), on: req.db)
		else {
			throw Abort(.notFound)
		}
		
		let acronyms = try await category.$acronyms.get(on: req.db)
		let context = CategoryContext(title: category.name, category: category, acronyms: acronyms)
		
		return try await req.view.render("category", context)
	}
	
	func createAcronymHandler(_ req: Request) async throws -> View {
		let token = [UInt8].random(count: 16).base64
		let context = CreateAcronymContext(csrfToken: token)
		req.session.data["CSRF_TOKEN"] = token
		return try await req.view.render("createAcronym", context)
	}
	
	func createAcronymPostHandler(_ req: Request) async throws -> Response {
		let data = try req.content.decode(CreateAcronymFormData.self)
		let user = try req.auth.require(User.self)
		let expectedToken = req.session.data["CSRF_TOKEN"]
		req.session.data["CSRF_TOKEN"] = nil
		
		guard let csrfToken = data.csrfToken, csrfToken == expectedToken
		else {
			throw Abort(.badRequest)
		}
		
		let acronym = try Acronym(short: data.short, long: data.long, userID: user.requireID())
		
		try await acronym.save(on: req.db)
		
		guard let id = acronym.id
		else {
			throw Abort(.internalServerError)
		}
		
		for category in data.categories ?? [] {
			try await Category.addCategory(category, to: acronym, on: req)
		}
		
		return req.redirect(to: "/acronyms/\(id)")
	}
	
	func editAcronymHandler(_ req: Request) async throws -> View {
		guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db)
		else {
			throw Abort(.notFound)
		}
		
		let categories = try await acronym.$categories.get(on: req.db)
		let context = EditAcronymContext(acronym: acronym, categories: categories)
		
		return try await req.view.render("createAcronym", context)
	}
	
	func editAcronymPostHandler(_ req: Request) async throws -> Response {
		let updateData = try req.content.decode(CreateAcronymFormData.self)
		guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db)
		else {
			throw Abort(.notFound)
		}
		
		let user = try req.auth.require(User.self)
		let userID = try user.requireID()
		
		acronym.short = updateData.short
		acronym.long = updateData.long
		acronym.$user.id = userID
		
		guard let acronymID = acronym.id
		else {
			throw Abort(.internalServerError)
		}
		
		try await acronym.save(on: req.db)
		
		let existingCategories = try await acronym.$categories.get(on: req.db)
		
		let existingSetCategories = Set<String>(existingCategories.map { $0.name })
		let newSetCategories = Set<String>(updateData.categories ?? [])
		
		let categoriesToAdd = newSetCategories.subtracting(existingSetCategories)
		let categoriesToRemove = existingSetCategories.subtracting(newSetCategories)
		
		for categoryName in categoriesToAdd {
			try await Category.addCategory(categoryName, to: acronym, on: req)
		}
		
		for categoryName in categoriesToRemove {
			if let category = existingCategories.first(where: { $0.name == categoryName }) {
				try await acronym.$categories.detach(category, on: req.db)
			}
		}
		
		return req.redirect(to: "/acronyms/\(acronymID)")
	}
	
	func deleteAcronymHandler(_ req: Request) async throws -> Response {
		guard let acronym = try await Acronym.find(req.parameters.get("acronymID"), on: req.db)
		else {
			throw Abort(.notFound)
		}
		
		try await acronym.delete(on: req.db)
		
		return req.redirect(to: "/")
	}
	
	func loginHandler(_ req: Request) async throws -> Response {
		let context: LoginContext
		let siwaContext = try buildSIWAContext(on: req)

		if let error = req.query[Bool.self, at: "error"], error {
			context = LoginContext(loginError: true, siwaContext: siwaContext)
		} else {
			context = LoginContext(siwaContext: siwaContext)
		}
		
		let response = try await req.view.render("login", context).encodeResponse(for: req).get()
		let expiryDate = Date().addingTimeInterval(300)
		let cookie = HTTPCookies.Value(
			string: siwaContext.state,
			expires: expiryDate,
			maxAge: 300,
			isHTTPOnly: true,
			sameSite: HTTPCookies.SameSitePolicy.none
		)
		response.cookies["SIWA_STATE"] = cookie
		return response
	}
	
	func loginPostHandler(_ req: Request) async throws -> Response {
		if req.auth.has(User.self) {
			return req.redirect(to: "/")
		} else {
			let siwaContext = try buildSIWAContext(on: req)
			let context = LoginContext(loginError: true, siwaContext: siwaContext)
			let response = try await req.view.render("login", context).encodeResponse(for: req).get()
			let expiryDate = Date().addingTimeInterval(300)
			let cookie = HTTPCookies.Value(
				string: siwaContext.state,
				expires: expiryDate,
				maxAge: 300,
				isHTTPOnly: true,
				sameSite: HTTPCookies.SameSitePolicy.none
			)
			response.cookies["SIWA_STATE"] = cookie
			return response
		}
	}
	
	func logoutHandler(_ req: Request) -> Response {
		req.auth.logout(User.self)
		return req.redirect(to: "/")
	}
	
	func registerHandler(_ req: Request) async throws -> Response {
		let siwaContext = try buildSIWAContext(on: req)
		let context: RegisterContext
		if let message = req.query[String.self, at: "message"] {
			context = RegisterContext(message: message, siwaContext: siwaContext)
		} else {
			context = RegisterContext(siwaContext: siwaContext)
		}
		let response = try await req.view.render("register", context).encodeResponse(for: req).get()
		let expiryDate = Date().addingTimeInterval(300)
			let cookie = HTTPCookies.Value(
				string: siwaContext.state,
				expires: expiryDate,
				maxAge: 300,
				isHTTPOnly: true,
				sameSite: HTTPCookies.SameSitePolicy.none
			)
		response.cookies["SIWA_STATE"] = cookie
		return response
	}
	
	func registerPostHandler(_ req: Request) async throws -> Response {
		do {
			try RegisterData.validate(content: req)
		} catch let error as ValidationsError {
			let message = error.description.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Unknown error"
			return req.redirect(to: "/register?message=\(message)")
		}
		
		let data = try req.content.decode(RegisterData.self)
		let password = try Bcrypt.hash(data.password)
        
        var twitterURL: String?
        if let twitter = data.twitterURL, !twitter.isEmpty {
            twitterURL = twitter
        }
		let user = User(
			name: data.name,
			username: data.username,
			email: data.emailAddress,
			password: password,
            twitterURL: twitterURL
		)
		
		try await user.save(on: req.db)
		
		guard user.id != nil else {
			throw Abort(.internalServerError)
		}
		
		req.auth.login(user)
		
		return req.redirect(to: "/")
	}
	
	func appleAuthCallbackHandler(_ req: Request) async throws -> View {
		let siwaData = try req.content.decode(AppleAuthorizationResponse.self)
		
		guard let sessionState = req.cookies["SIWA_STATE"]?.string,
			  !sessionState.isEmpty,
			  sessionState == siwaData.state
		else {
			req.logger.warning("SIWA does not exist or does not match")
			throw Abort(.unauthorized)
		}
		
		let siwaContext = SIWAHandleContext(
			token: siwaData.idToken,
			email: siwaData.user?.email,
			firstName: siwaData.user?.name?.firstName,
			lastName: siwaData.user?.name?.lastName
		)
		
		return try await req.view.render("siwaHandler", siwaContext)
	}

	func appleAuthRedirectHandler(_ req: Request) async throws -> Response {
		let data = try req.content.decode(SIWARedirectData.self)
		
		guard let appIdentifier = Environment.get("WEBSITE_APPLICATION_IDENTIFIER")
		else {
			throw Abort(.internalServerError)
		}

		let siwaToken = try await req.jwt.apple.verify(data.token, applicationIdentifier: appIdentifier)
		let user = try await User.query(on: req.db)
			.filter(\.$siwaIdentifier == siwaToken.subject.value)
			.first()
		
		if let user = user {
			req.auth.login(user)
			return req.redirect(to: "/")
		} else {
			guard let email = data.email,
				  let firstName = data.firstName,
				  let lastName = data.lastName
			else {
				throw Abort(.badRequest)
			}
			
			let user = User(
				name: "\(firstName) \(lastName)",
				username: email,
				email: email,
				password: UUID().uuidString,
				siwaIdentifier: siwaToken.subject.value
			)

			try await user.save(on: req.db)
			
			guard user.id != nil else {
				throw Abort(.internalServerError)
			}
			
			req.auth.login(user)
			return req.redirect(to: "/")
		}
	}

	private func buildSIWAContext(on req: Request) throws -> SIWAContext {
		let state = [UInt8].random(count: 32).base64
		let scopes = "name email"

		guard let clientID = Environment.get("WEBSITE_APPLICATION_IDENTIFIER")
		else {
			req.logger.error("WEBSITE_APPLICATION_IDENTIFIER not set")
			throw Abort(.internalServerError)
		}

		guard let redirectURI = Environment.get("SIWA_REDIRECT_URL")
		else {
			req.logger.error("SIWA_REDIRECT_URL not set")
			throw Abort(.internalServerError)
		}

		return SIWAContext(clientID: clientID, scopes: scopes, redirectURI: redirectURI, state: state)
	}
	
	func forgottenPasswordHandler(_ req: Request) async throws -> View {
		try await req.view.render(
			"forgottenPassword",
			["title": "Reset Your Password"]
		)
	}
	
	func forgottenPasswordPostHandler(_ req: Request) async throws -> View {
		let email = try req.content.get(String.self, at: "email")
		
		guard let user = try await User.query(on: req.db).filter(\.$email == email).first() else {
			return try await req.view.render(
				"forgottenPasswordConfirmed",
				["title": "Password Reset Email Sent"]
			)
		}
		
		let resetTokenString = Data([UInt8].random(count: 32)).base32EncodedString()
		let resetToken: ResetPasswordToken
		do {
			resetToken = try ResetPasswordToken(token: resetTokenString, userID: user.requireID())
		} catch {
			throw Abort(.internalServerError, reason: error.localizedDescription)
		}
		
		do {
			try await resetToken.save(on: req.db)
		} catch {
			throw Abort(.internalServerError, reason: error.localizedDescription)
		}
		
		let emailContent = """
				<p>You've requested to reset your password. <a
				href="http://localhost:8080/resetPassword?\
				token=\(resetTokenString)">
				Click here</a> to reset your password.</p>
				"""
		let emailAddress = EmailAddress(email: user.email, name: user.name)
		let fromEmail = EmailAddress(email: "sobs.fizz-0n@icloud.com", name: "Vapor TIL")
		let emailConfig = Personalization(to: [emailAddress], subject: "Reset Your Password")
		let sendGridEmail = SendGridEmail(
		  personalizations: [emailConfig],
		  from: fromEmail,
		  content: [EmailContent(type: "text/html", value: emailContent)]
		)
		
		do {
			try await req.application.sendgrid.client.send(email: sendGridEmail)
		} catch {
			throw Abort(.internalServerError, reason: error.localizedDescription)
		}
		
		return try await req.view.render(
			"forgottenPasswordConfirmed",
			["title": "Password Reset Email Sent"]
		)
	}
	
	func resetPasswordHandler(_ req: Request) async throws -> View {
		guard let tokenString = try? req.query.get(String.self, at: "token")
		else {
			return try await req.view.render("resetPassword", ResetPasswordContext(error: true))
		}
		
		guard let token = try await ResetPasswordToken.query(on: req.db).filter(\.$token == tokenString).first()
		else {
			throw Abort.redirect(to: "/")
		}
		
		let user = try await token.$user.get(on: req.db)
		
		do {
			try req.session.set("ResetPasswordUser", to: user)
			try await token.delete(on: req.db)
			
			return try await req.view.render("resetPassword", ResetPasswordContext())
		} catch {
			throw Abort(.internalServerError, reason: error.localizedDescription)
		}
	}
	
	func resetPasswordPostHandler(_ req: Request) async throws -> Response {
		let data = try req.content.decode(ResetPasswordData.self)
		guard data.password == data.confirmPassword
		else {
			return try await req.view.render("resetPassword", ResetPasswordContext(error: true))
				.encodeResponse(for: req).get()
		}
		
		let resetPasswordUser = try req.session.get("ResetPasswordUser", as: User.self)
		req.session.data["ResetPasswordUser"] = nil
		
		let newPassword = try Bcrypt.hash(data.password)
		
		do {
			try await User.query(on: req.db)
				.filter(\.$id == resetPasswordUser.requireID())
				.set(\.$password, to: newPassword)
				.update()
			return req.redirect(to: "/login")
		} catch {
			throw Abort.redirect(to: "/")
		}
	}
	
	func addProfilePictureHandler(_ req: Request) async throws -> View {
		guard let user = try await User.find(req.parameters.get("userID"), on: req.db)
		else {
			throw Abort(.notFound)
		}
		
		return try await req.view.render("addProfilePicture", [
			"title": "Add Profile Picture",
			"username": user.name
		])
	}
	
	func addProfilePicturePostHandler(_ req: Request) async throws -> Response {
		let data = try req.content.decode(ImageUploadData.self)
		
		guard let user = try await User.find(req.parameters.get("userID"), on: req.db)
		else {
			throw Abort(.notFound)
		}
		
		let userID = try user.requireID()
		let name = "\(userID)-\(UUID()).jpg"
		
		let path = req.application.directory.workingDirectory + imageFolder + name
		
		try await req.fileio.writeFile(.init(data: data.picture), at: path)
		
		user.profilePicture = name
		try await user.save(on: req.db)
		
		return req.redirect(to: "/users/\(userID)")
	}
	
	func getUserProfilePictureHandler(_ req: Request) async throws -> Response {
		guard let user = try await User.find(req.parameters.get("userID"), on: req.db),
			  let filename = user.profilePicture
		else {
			throw Abort(.notFound)
		}
		
		let path = req.application.directory.workingDirectory + imageFolder + filename
		return req.fileio.streamFile(at: path)
	}
}

struct IndexContext: Encodable {
	let title: String
	let acronyms: [Acronym]
	let userLoggedIn: Bool
	let showCookieMessage: Bool
}

struct AcronymContext: Encodable {
	let title: String
	let acronym: Acronym
	let user: User
	let categories: [Category]
}

struct UserContext: Encodable {
	let title: String
	let user: User
	let acronyms: [Acronym]
	let authenticatedUser: User?
}

struct AllUsersContext: Encodable {
	let title: String
	let users: [User]
}

struct AllCategoriesContext: Encodable {
	let title = "All Categories"
	let categories: [Category]
}

struct CategoryContext: Encodable {
	let title: String
	let category: Category
	let acronyms: [Acronym]
}

struct CreateAcronymContext: Encodable {
	let title = "Create An Acronym"
	let csrfToken: String
}

struct EditAcronymContext: Encodable {
	let title: String = "Edit Acronym"
	let acronym: Acronym
	let editing = true
	let categories: [Category]
}

struct CreateAcronymFormData: Content {
	let short: String
	let long: String
	let categories: [String]?
	let csrfToken: String?
}

struct LoginContext: Encodable {
	let title = "Log In"
	let loginError: Bool
	let siwaContext: SIWAContext
	
	init(loginError: Bool = false, siwaContext: SIWAContext) {
		self.loginError = loginError
		self.siwaContext = siwaContext
	}
}

struct RegisterContext: Encodable {
	let title = "Register"
	let message: String?
	let siwaContext: SIWAContext
	
	init(message: String? = nil, siwaContext: SIWAContext) {
		self.message = message
		self.siwaContext = siwaContext
	}
}

struct RegisterData: Content {
	let name: String
	let username: String
	let password: String
	let emailAddress: String
	let confirmPassword: String
    let twitterURL: String?
}

extension RegisterData: Validatable {
	static func validations(_ validations: inout Validations) {
		validations.add("name", as: String.self, is: .ascii)
		validations.add("username", as: String.self, is: .alphanumeric && .count(3...10))
		validations.add("emailAddress", as: String.self, is: .email)
		validations.add("password", as: String.self, is: .count(6...24))
		validations.add("zipCode", as: String.self, is: .zipCode, required: false)
	}
}

extension ValidatorResults {
	struct ZipCode {
		let isValidZipCode: Bool
	}
}

extension ValidatorResults.ZipCode: ValidatorResult {
	var isFailure: Bool {
		!isValidZipCode
	}
	
	var successDescription: String? {
		"is a valid zip code"
	}
	
	var failureDescription: String? {
		"is not a valid zip code"
	}
}

extension Validator where T == String {
	
	private static var zipCodeRegex: String {
		"^\\d{5}(?:[-\\s]\\d{4})?$"
	}
	
	public static var zipCode: Validator<T> {
		Validator { input -> ValidatorResult in
			guard let range = input.range(of: zipCodeRegex, options: [.regularExpression]),
				range.lowerBound == input.startIndex && range.upperBound == input.endIndex
			else {
				return ValidatorResults.ZipCode(isValidZipCode: false)
			}
			return ValidatorResults.ZipCode(isValidZipCode: true)
		}
	}
}

struct AppleAuthorizationResponse: Decodable {
	struct User: Decodable {
		struct Name: Decodable {
			let firstName: String?
			let lastName: String?
		}
		let email: String
		let name: Name?
	}
	
	let code: String
	let state: String
	let idToken: String
	let user: User?
	
	enum CodingKeys: String, CodingKey {
		case code
		case state
		case idToken = "id_token"
		case user
	}
	
	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		code = try values.decode(String.self, forKey: .code)
		state = try values.decode(String.self, forKey: .state)
		idToken = try values.decode(String.self, forKey: .idToken)
		
		if let jsonString = try values.decodeIfPresent(String.self, forKey: .user),
		   let jsonData = jsonString.data(using: .utf8) {
			self.user = try JSONDecoder().decode(User.self, from: jsonData)
		} else {
			user = nil
		}
	}
}

struct SIWAHandleContext: Encodable {
	let token: String
	let email: String?
	let firstName: String?
	let lastName: String?
}

struct SIWARedirectData: Content {
	let token: String
	let email: String?
	let firstName: String?
	let lastName: String?
}

struct SIWAContext: Encodable {
	let clientID: String
	let scopes: String
	let redirectURI: String
	let state: String
}

struct ResetPasswordContext: Encodable {
	let title = "Reset Password"
	let error: Bool?
	
	init(error: Bool? = false) {
		self.error = error
	}
}

struct ResetPasswordData: Content {
	let password: String
	let confirmPassword: String
}

struct ImageUploadData: Content {
	let picture: Data
}
