//
//  CreateCategory.swift
//  
//
//  Created by Sĩ Huỳnh on 04/11/2023.
//

import Fluent

struct CreateCategory: Migration {
	func prepare(on database: Database) -> EventLoopFuture<Void> {
		database.schema(Category.schema)
			.id()
            .field(Category.v20231202.name, .string, .required)
			.create()
	}
	
	func revert(on database: Database) -> EventLoopFuture<Void> {
		database.schema(Category.schema).delete()
	}
}

extension Category {
    enum v20231202 {
        static let schemaName = "categories"
        
        static let id = FieldKey(stringLiteral: "id")
        static let name = FieldKey(stringLiteral: "name")
    }
}
