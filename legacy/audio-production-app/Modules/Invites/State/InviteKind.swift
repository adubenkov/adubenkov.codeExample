//
//  InviteKind.swift
//  
//
//  Created by Andrey Dubenkov on 26/06/2019.
//  Copyright © 2019 . All rights reserved.
//

enum InviteKind: CaseIterable {
    case sent
    case received

    var title: String {
        switch self {
        case .sent:
            return "Sent"
        case .received:
            return "Received"
        }
    }
}
