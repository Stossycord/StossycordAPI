func SendMessageWithButtons(content: String, token: String, channel: String) {
    let url = URL(string: "https://discord.com/api/v10/channels/\(channel)/messages")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    request.addValue(token, forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let messageData: [String: Any] = [
        "content": content,
        "components": [
            [
                "type": 1, // Action row
                "components": [
                    [
                        "type": 2, // Button
                        "label": "Click me!",
                        "style": 1, // Primary button style
                        "custom_id": "button_click"
                    ]
                ]
            ]
        ]
    ]
    
    request.httpBody = try? JSONSerialization.data(withJSONObject: messageData)
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error: \(error)")
        } else if let data = data {
            print("Response: \(String(data: data, encoding: .utf8) ?? "")")
        }
    }
    task.resume()
}
