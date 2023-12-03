//
//  AddTwitterToUser.swift
//  
//
//  Created by Sĩ Huỳnh on 02/12/2023.
//

import Fluent

struct AddTwitterToUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.v20231202.schemaName)
            .field(User.v20231203.twitterURL, .string)
            .update()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.v20231202.schemaName)
            .deleteField(User.v20231203.twitterURL)
            .update()
    }
}
