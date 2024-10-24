//
//  GetMessages.swift
//  Stossycord
//
//  Created by Stossy11 on 20/9/2024.
//

import Foundation

func getDiscordMessages(token: String, webSocketService: WebSocketService, completion: @escaping ([Message]) -> Void) {
    var messageLimit: Int = 50
    let url = URL(string: "https://discord.com/api/v10/channels/\(webSocketService.currentchannel)/messages?limit=\(messageLimit)")!
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue(token, forHTTPHeaderField: "Authorization")
    request.addValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
    request.addValue("en-AU,en;q=0.9", forHTTPHeaderField: "Accept-Language")
    request.addValue("keep-alive", forHTTPHeaderField: "Connection")
    request.addValue("https://discord.com", forHTTPHeaderField: "Origin")
    request.addValue("empty", forHTTPHeaderField: "Sec-Fetch-Dest")
    request.addValue("cors", forHTTPHeaderField: "Sec-Fetch-Mode")
    request.addValue("same-origin", forHTTPHeaderField: "Sec-Fetch-Site")

    let Country: String = CurrentDeviceInfo.shared.Country
    let currentTimeZone = CurrentDeviceInfo.shared.currentTimeZone
    let timeZoneIdentifier = currentTimeZone.identifier
    let deviceInfo = CurrentDeviceInfo.shared.deviceInfo

    request.addValue(deviceInfo.browserUserAgent, forHTTPHeaderField: "User-Agent")
    request.addValue("bugReporterEnabled", forHTTPHeaderField: "X-Debug-Options")
    request.addValue("\(currentTimeZone)-\(Country)", forHTTPHeaderField: "X-Discord-Locale")
    request.addValue(timeZoneIdentifier, forHTTPHeaderField: "X-Discord-Timezone")
    request.addValue(deviceInfo.toBase64() ?? "base64", forHTTPHeaderField: "X-Super-Properties")
    
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
                allmessages.sort(by: { $0.messageId < $1.messageId })

                // Call the completion handler
                completion(allmessages)
            }
        } catch {
            print("Error parsing JSON: \(error)")
        }
    }
    
    task.resume()
}
