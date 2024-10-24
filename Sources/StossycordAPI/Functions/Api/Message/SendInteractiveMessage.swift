//
//  SendInteractiveMessage.swift
//  StossycordAPI
//
//  Created by Stossy11 on 24/10/2024.
//

import Foundation

func SendInteractiveMessage(_ messageData: InteractiveMessage, token: String, channel: String) {
    let url = URL(string: "https://discord.com/api/v10/channels/\(channel)/messages")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    request.addValue(token, forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    // Encode the message data to JSON
    let jsonData = try? JSONEncoder().encode(messageData)
    request.httpBody = jsonData
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error: \(error)")
        } else if let data = data {
            print("Response: \(String(data: data, encoding: .utf8) ?? "")")
        }
    }
    task.resume()
}
