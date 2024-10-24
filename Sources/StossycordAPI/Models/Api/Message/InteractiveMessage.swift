//
//  MessageData.swift
//  StossycordAPI
//
//  Created by Stossy11 on 24/10/2024.
//


import Foundation

public struct InteractiveMessage: Codable {
    let channelid: String
    let content: String
    let components: [ActionRow]
}

public struct ActionRow: Codable {
    let type: Int // Always 1 for ActionRow
    let components: [ButtonComponent]
}

public struct ButtonComponent: Codable {
    let type: Int // Always 2 for Button
    let label: String
    let style: Int
    let custom_id: String
}
