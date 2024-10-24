import Foundation
import AVFoundation
import KeychainSwift
import Network

class WebSocketService {
    var currentUser: User
    var isConnected: Bool = false
    var data: [Message] = []
    var channels: [Channel] = []
    var dms: [DMs] = []
    var currentchannel: String = ""
    var isNetworkAvailable: Bool = true // Network status tracking
    var Guilds: [Guild] = []
    var currentguild: Guild = Guild(id: "", name: "", icon: "")
    let keychain = KeychainSwift()
    var token: String
    var deviceInfo: DeviceInfo = CurrentDeviceInfo.shared.deviceInfo
    var heartbeatTimer: Timer?
    var lastHeartbeatAck: Bool = true
    var heartbeatInterval: TimeInterval = 0
    var onNewMessage: ((Message) -> Void)?

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue.global(qos: .background)

    // Reconnection properties
    private var reconnectionAttempts: Int = 0
    private var maxReconnectionAttempts: Int = 5
    private var reconnectionTimer: Timer?
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession: URLSession

    init() {
        token = KeychainSwift().get("token") ?? ""
        currentUser = User(id: "", username: "", discriminator: "", avatar: "")
        urlSession = URLSession(configuration: .default)

        if !token.isEmpty {
            DispatchQueue.global(qos: .background).async {
                self.connect()
            }
        }
    }

    func connect() {
        token = KeychainSwift().get("token") ?? ""
        guard !token.isEmpty else {
            print("Token is empty!")
            return
        }

        getdiscordstuff()
        setupNetworkMonitor()

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
                "token": token,
                "capabilities": 30717,
                "properties": [
                    "os": deviceInfo.os,
                    "device": "",
                    "browser_version": deviceInfo.browserVersion,
                    "os_version": deviceInfo.osVersion,
                ]
            ]
        ]
        sendJSON(payload)
    }

    func getdiscordstuff() {
        CurrentUser(token: token) { user in
            if let user = user {
                self.currentUser = user
            } else {
                print("Unable to get User")
            }
        }

        getDiscordGuilds(token: token) { result in
            self.Guilds = result
        }

        getDiscordDMs(token: token) { items in
            self.dms = items
        }
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
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("Error receiving message: \(error)")
                self?.connect()
            case .success(let message):
                switch message {
                case .string(let text):
                    // print("Received text: \(text)")
                    self?.handleMessage(text)
                case .data(let data):
                    break
                    // print("Received data: \(data)")
                    // Handle binary data if needed
                @unknown default:
                    break
                }
                // Listen for the next message
                self?.receiveMessage()
            }
        }
    }

    func scheduleReconnection() {
        if reconnectionAttempts < maxReconnectionAttempts {
            let delay = pow(2.0, Double(reconnectionAttempts)) // Exponential backoff
            reconnectionAttempts += 1
            print("Attempting to reconnect in \(delay) seconds...")
            reconnectionTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                self?.connect()
                print("connected")
            }
        } else {
            print("Max reconnection attempts reached. Stopping retries.")
        }
    }

    private func setupNetworkMonitor() {
        monitor.pathUpdateHandler = { [self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    print("Network is available")
                    self.isNetworkAvailable = true
                    if !self.isConnected {
                        self.connect()
                    }
                } else {
                    print("Network is unavailable")
                    self.isNetworkAvailable = false
                }
            }
        }
        monitor.start(queue: queue)
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
        data.removeAll { $0.messageId == (json["d"] as? [String: Any])?["message_id"] as? String }
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
        guard let json = json["d"] as? [String: Any], let channelId = json["channel_id"] as? String, channelId == currentchannel else { return }

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
            data.append(currentMessage)
            onNewMessage?(currentMessage)
        } else if eventType == "MESSAGE_UPDATE" {
            if let index = data.firstIndex(where: { $0.messageId == currentMessage.messageId }) {
                data[index].content = currentMessage.content
            }
        }
    }
}
