//
//  GetMessages.swift
//  Stossycord
//
//  Created by Stossy11 on 20/9/2024.
//

import Foundation


func getMessages(token: String, channel: String, completion: @Sendable @escaping ([Message]) -> Void) {
    var messageLimit: Int = 50
    let url = URL(string: "https://discord.com/api/v10/channels/\(channel)/messages?limit=\(messageLimit)")!
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue(token, forHTTPHeaderField: "Authorization")
    request.addValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
    request.addValue("en-AU,en;q=0.9", forHTTPHeaderField: "Accept-Language")
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data else {
            print("No data in response: \(error?.localizedDescription ?? "Unknown error")")
            return
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                var allmessages: [Message] = []
                
                for message in json {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: message, options: [])
                        let decoder = JSONDecoder()
                        let currentmessage = try decoder.decode(Message.self, from: jsonData)
                        
                        // Append message directly, no need for DispatchQueue.main.async
                        allmessages.append(currentmessage)
                    } catch {
                        print("Error decoding JSON:", error)
                    }
                }
                
                // Sort messages after appending

                // Call the completion handler
                completion(allmessages)
            }
        } catch {
            print("Error parsing JSON: \(error)")
        }
    }
    
    task.resume()
}
