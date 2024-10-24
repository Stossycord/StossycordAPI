//
//  MessageData.swift
//  StossycordAPI
//
//  Created by Stossy11 on 24/10/2024.
//


import Foundation

struct MessageData: Codable {
    let content: String
    let components: [ActionRow]
}

struct ActionRow: Codable {
    let type: Int // Always 1 for ActionRow
    let components: [ButtonComponent]
}

struct ButtonComponent: Codable {
    let type: Int // Always 2 for Button
    let label: String
    let style: Int
    let custom_id: String
}
