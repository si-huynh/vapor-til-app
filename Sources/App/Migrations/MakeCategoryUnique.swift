//
//  MakeCategoryUnique.swift
//  
//
//  Created by Sĩ Huỳnh on 02/12/2023.
//

import Fluent

struct MakeCategoryUnique: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Category.v20231202.schemaName)
            .unique(on: Category.v20231202.name)
            .update()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Category.v20231202.schemaName)
            .deleteUnique(on: Category.v20231202.name)
            .delete()
    }
}
