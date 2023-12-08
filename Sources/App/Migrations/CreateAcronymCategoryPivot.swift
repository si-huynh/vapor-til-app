//
//  CreateAcronymCategoryPivot.swift
//  
//
//  Created by Sĩ Huỳnh on 04/11/2023.
//

import Fluent

struct CreateAcronymCategoryPivot: Migration {
	func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(AcronymCategoryPivot.v20231202.schemaName)
			.id()
			.field(
                AcronymCategoryPivot.v20231202.acronymID,
                .uuid,
                .required,
                .references(
                    Acronym.v20231202.schemaName,
                    Acronym.v20231202.id,
                    onDelete: .cascade
                )
            )
			.field(
                AcronymCategoryPivot.v20231202.categoryID,
                .uuid,
                .required,
                .references(
                    Category.v20231202.schemaName,
                    Category.v20231202.id,
                    onDelete: .cascade
                )
            )
			.create()
	}
	
	func revert(on database: Database) -> EventLoopFuture<Void> {
		database.schema(AcronymCategoryPivot.schema).delete()
	}
}

extension AcronymCategoryPivot {
    enum v20231202 {
        static let schemaName = "acronym-category-pivot"
        
        static let acronymID = FieldKey(stringLiteral: "acronymID")
        static let categoryID = FieldKey(stringLiteral: "categoryID")
    }
}
