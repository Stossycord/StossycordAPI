//
//  CurrentUser.swift
//  Stossycord
//
//  Created by Stossy11 on 19/9/2024.
//

import Foundation

func CurrentUser(token: String, completion: @Sendable @escaping (User?) -> Void) {
    let url = URL(string: "https://discord.com/api/v10/users/@me")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue(token, forHTTPHeaderField: "Authorization")
    request.addValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
    request.addValue("en-AU,en;q=0.9", forHTTPHeaderField: "Accept-Language")
    request.addValue("keep-alive", forHTTPHeaderField: "Connection")

    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        if let error = error {
            print("Error: \(error)")
        } else if let data = data {
            do {
                do {
                    let discordUser = try JSONDecoder().decode(User.self, from: data)
                    completion(discordUser)
                } catch {
                    print("Failed to decode JSON: \(error)")
                    completion(nil)
                }
            } catch {
                print("Error: \(error)")
                completion(nil)
            }
        }
    }

    task.resume()
}
