//
//  UserTests.swift
//  
//
//  Created by Sĩ Huỳnh on 04/11/2023.
//

@testable import App
import XCTVapor

final class UserTests: XCTestCase {
	
	let usersName = "Alice"
	let usersUsername = "alice"
	let usersURI = "api/users/"
	
	var app: Application!
	
	override func setUp() async throws {
		app = try await Application.testable()
	}
	
	override func tearDown() async throws {
		app.shutdown()
	}
	
	func testUsersCanBeRetrievedFromAPI() async throws {
		let user = try await User.create(
			name: usersName,
			username: usersUsername,
			on: app.db
		)
		
		_ = try await User.create(on: app.db)
		
		try app.test(.GET, usersURI) { response in
			XCTAssertEqual(response.status, .ok)
			let users = try response.content.decode([User.Public].self)
			
			XCTAssertEqual(users.count, 3)
			XCTAssertEqual(users[1].name, usersName)
			XCTAssertEqual(users[1].username, usersUsername)
			XCTAssertEqual(users[1].id, user.id)
		}
	}
	
	func testUserCanBeSaveWithAPI() async throws {
		let user = User(name: usersName, username: usersUsername, password: "password")
		
		try app.test(.POST, usersURI, loggedInRequest: true, beforeRequest: { request in
			try request.content.encode(user)
		}) { response in
			let receivedUser = try response.content.decode(User.Public.self)
			
			XCTAssertEqual(receivedUser.name, usersName)
			XCTAssertEqual(receivedUser.username, usersUsername)
			XCTAssertNotNil(receivedUser.id)
			
			try app.test(.GET, usersURI) { secondResponse in
				let users = try secondResponse.content.decode([User.Public].self)
				XCTAssertEqual(users.count, 2)
				XCTAssertEqual(users[1].name, usersName)
				XCTAssertEqual(users[1].username, usersUsername)
				XCTAssertEqual(users[1].id, receivedUser.id)
			}
		}
	}
	
	func testGettingASingleUserFromTheAPI() async throws {
		let user = try await User.create(
			name: usersName,
			username: usersUsername,
			on: app.db
		)
		
		try app.test(.GET, "\(usersURI)\(user.id!)") { response in
			let receivedUser = try response.content.decode(User.Public.self)
			
			XCTAssertEqual(receivedUser.name, usersName)
			XCTAssertEqual(receivedUser.username, usersUsername)
			XCTAssertEqual(receivedUser.id, user.id)
		}
	}
	
	func testGettingAUsersAcronymsFromTheAPI() async throws {
		let user = try await User.create(on: app.db)
		
		let acronymShort = "OMG"
		let acronymLong = "Oh My God"
		
		let firstAcronym = try await Acronym.create(
			short: "LOL",
			long: "Laugh Out Loud",
			user: user,
			on: app.db
		)
		
		_ = try await Acronym.create(
			short: acronymShort,
			long: acronymLong,
			user: user,
			on: app.db
		)
		
		try app.test(.GET, "\(usersURI)\(user.id!)/acronyms") { response in
			let acronyms = try response.content.decode([Acronym].self)
			
			XCTAssertEqual(acronyms.count, 2)
			XCTAssertEqual(acronyms.first?.id, firstAcronym.id)
			XCTAssertEqual(acronyms.first?.short, firstAcronym.short)
			XCTAssertEqual(acronyms.first?.long, firstAcronym.long)
		}
	}
}
