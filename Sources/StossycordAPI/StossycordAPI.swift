// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public struct StossycordAPI {
    
    private var websocket: WebSocketService
    
    public var token: String
    
    public var onNewMessage: ((Message) -> Void)?
    public var onDeleteMessage: ((String) -> Void)?
    public var onEditMessage: ((Message) -> Void)?
    
    public init(token: String) {
        websocket = WebSocketService(token: token)
        
        self.token = token
        reciveMessage()
        
    }
    
    public func startReceiving() {
        if websocket.isConnected { return }
        websocket.connect()
    }
    
    public func stopRecieving() {
        if websocket.isConnected { websocket.disconnect() }
    }
    
    private func reciveMessage() {
        websocket.onNewMessage = { message in
            self.onNewMessage?(message)
        }
        
        websocket.onDeleteMessage = { message in
            self.onDeleteMessage?(message)
        }
        
        websocket.onEditMessage = { message in
            self.onEditMessage?(message)
        }
    }
    
    public func listServers(completion: @Sendable @escaping ([Guild]) -> Void) {
        getDiscordGuilds(token: token) { result in
            completion(result)
        }
    }
    
    public func listChannels(_ guild: Guild, completion: @Sendable @escaping ([Channel]) -> Void) {
        getChannels(serverId: guild.id, token: token) { result in
            completion(result)
        }
    }
    
    public func listMessages(_ channel: Channel, completion: @Sendable @escaping ([Message]) -> Void) {
        getMessages(token: token, channel: channel.id) { result in
            completion(result)
        }
    }
    
    public func sendInteractiveMessage(_ message: InteractiveMessage, channel: String) {
        SendInteractiveMessage(message, token: token, channel: channel)
    }
    
    public func editMessage(_ message: Message) {
        EditMessage(token: token, message: message)
    }
    
    public func deleteMessage(_ message: Message) {
        DeleteMessage(token: token, channelID: message.channelId, messageID: message.messageId)
    }
    
    public func sendMessage(_ message: Message, fileUrl: URL?) {
        
        if let repliedMessage = message.messageReference?.messageId {
            SendMessage(content: message.content, fileUrl: fileUrl, token: token, channel: message.channelId, messageReference: ["message_id": repliedMessage])
        } else {
            SendMessage(content: message.content, fileUrl: fileUrl, token: token, channel: message.channelId, messageReference: nil)
        }
    }
    
}



