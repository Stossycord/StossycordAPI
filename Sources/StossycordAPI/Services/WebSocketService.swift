import Foundation
import AVFoundation
import Network

class WebSocketService: @unchecked Sendable {
    var isConnected: Bool = false

    var isNetworkAvailable: Bool = true // Network status tracking
    var token: String
    var heartbeatTimer: Timer?
    var lastHeartbeatAck: Bool = true
    var heartbeatInterval: TimeInterval = 0
    var onNewMessage: ((Message) -> Void)?
    var onDeleteMessage: ((String) -> Void)?
    var onEditMessage: ((Message) -> Void)?

    private let queue = DispatchQueue.global(qos: .background)

    // Reconnection properties
    private var reconnectionAttempts: Int = 0
    private var maxReconnectionAttempts: Int = 5
    private var reconnectionTimer: Timer?
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession: URLSession

    init(token: String) {
        self.token = token
        urlSession = URLSession(configuration: .default)
    }

    public func connect() {
        guard !token.isEmpty else {
            print("Token is empty!")
            return
        }

        // getdiscordstuff()

        let url = URL(string: "wss://gateway.discord.gg/?encoding=json&v=9")!
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        webSocketTask?.maximumMessageSize = 9999999
        receiveMessage() // Start listening for messages
        isConnected = true
        
        // Send initial connection payload
        let payload: [String: Any] = [
            "op": 2,
            "d": [
                "token": token
                // "capabilities": 30717,
            ]
        ]
        sendJSON(payload)
    }


    func disconnect() {
        reconnectionTimer?.invalidate()
        if isConnected {
            webSocketTask?.cancel(with: .goingAway, reason: nil)
            isConnected = false
        }
    }

    func sendJSON(_ request: [String: Any]) {
        if let data = try? JSONSerialization.data(withJSONObject: request, options: []) {
            webSocketTask?.send(.data(data)) { error in
                if let error = error {
                    print("Error sending message: \(error)")
                }
            }
        }
    }

    func getJSONfromData(data: Data) -> [String: Any]? {
        return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    }

    private func receiveMessage() {
        webSocketTask?.receive { [self] result in
            switch result {
            case .failure(let error):
                print("Error receiving message: \(error)")
                self.connect()
            case .success(let message):
                switch message {
                case .string(let text):
                    // print("Received text: \(text)")
                    self.handleMessage(text)
                case .data(let data):
                    break
                    // print("Received data: \(data)")
                    // Handle binary data if needed
                @unknown default:
                    break
                }
                // Listen for the next message
                self.receiveMessage()
            }
        }
    }

    func handleMessage(_ string: String) {
        guard let data = string.data(using: .utf8), let json = getJSONfromData(data: data) else { return }

        if let t = json["t"] as? String {
            switch t {
            case "MESSAGE_CREATE", "MESSAGE_UPDATE":
                handleChatMessage(json: json, eventType: t)
            case "MESSAGE_DELETE":
                handleDeleteMessage(json: json)
            default:
                break
            }
        } else if let op = json["op"] as? Int {
            switch op {
            case 10:
                handleHello(json: json)
            case 11:
                lastHeartbeatAck = true
            case 1:
                sendHeartbeat()
            default:
                break
            }
        }
    }

    func handleDeleteMessage(json: [String: Any]) {
        
        let messageid = ((json["d"] as? [String: Any])?["message_id"] as? String)
        
        // data.removeAll { $0.messageId == (json["d"] as? [String: Any])?["message_id"] as? String }
    }

    func handleHello(json: [String: Any]) {
        if let d = json["d"] as? [String: Any], let interval = d["heartbeat_interval"] as? Double {
            heartbeatInterval = interval / 1000
            startHeartbeat()
        }
    }

    func sendHeartbeat() {
        let payload: [String: Any] = ["op": 1, "d": Int(Date().timeIntervalSince1970 * 1000)]
        sendJSON(payload)
    }

    func startHeartbeat() {
        heartbeatTimer?.invalidate()
        lastHeartbeatAck = true
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.lastHeartbeatAck {
                self.lastHeartbeatAck = false
                self.sendHeartbeat()
            } else {
                self.disconnect()
            }
        }
    }


    func handleChatMessage(json: [String: Any], eventType: String) {
        guard let json = json["d"] as? [String: Any] else { return }

        var currentMessage: Message
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
            let decoder = JSONDecoder()
            currentMessage = try decoder.decode(Message.self, from: jsonData)
        } catch {
            print("Error decoding Message:", error)
            return
        }
        if eventType == "MESSAGE_CREATE" {
            onNewMessage?(currentMessage)
        } else {
            onEditMessage?(currentMessage)
        }
        
        /*
        if eventType == "MESSAGE_CREATE" {
            data.append(currentMessage)
        } else if eventType == "MESSAGE_UPDATE" {
            if let index = data.firstIndex(where: { $0.messageId == currentMessage.messageId }) {
                data[index].content = currentMessage.content
            }
        }
         */
    }
}
