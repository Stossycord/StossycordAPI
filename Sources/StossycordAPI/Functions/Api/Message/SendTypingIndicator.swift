//
//  SendTypingIndicator.swift
//  Stossycord
//
//  Created by Stossy11 on 21/9/2024.
//

import Foundation

func sendtyping(token: String, channel: String) {
    let url = URL(string: "https://discord.com/api/v10/channels/\(channel)/typing")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    
    request.addValue(token, forHTTPHeaderField: "Authorization")
    
    request.addValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
    request.addValue("en-AU,en;q=0.9", forHTTPHeaderField: "Accept-Language")
    
    // Create the task
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        if let error = error {
            print("Error: \(error)")
        } else if let data = data {
            // print("Response: \(String(data: data, encoding: .utf8) ?? "")")
        }
    }
    task.resume()
}
