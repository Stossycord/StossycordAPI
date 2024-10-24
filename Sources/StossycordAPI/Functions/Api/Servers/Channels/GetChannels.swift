//
//  GetChannels.swift
//  Stossycord
//
//  Created by Stossy11 on 20/9/2024.
//

import Foundation

func getChannels(serverId: String, token: String, completion: @Sendable @escaping ([Channel]) -> Void) {
    guard let url = URL(string: "https://discord.com/api/v10/guilds/\(serverId)/channels?channel_limit=100") else {
        // print("Invalid URL")
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue(token, forHTTPHeaderField: "Authorization")
    request.addValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
    request.addValue("en-AU,en;q=0.9", forHTTPHeaderField: "Accept-Language")
    request.addValue("keep-alive", forHTTPHeaderField: "Connection")
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        if let error = error {
            print(error)
        } else if let data = data {
            do {
                do {
                    let channels = try JSONDecoder().decode([Channel].self, from: data)
                    completion(channels)
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }

    task.resume()
}
