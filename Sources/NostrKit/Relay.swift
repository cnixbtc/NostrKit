import Foundation
import Starscream

public enum RelayError: Error {
    case cannotConnect(Error?)
    case socketError(Error?)
    case writeError(Error?)
}

public protocol RelayDelegate: AnyObject {
    func received(message: RelayMessage)
    func disconnected(error: RelayError)
}

public struct Relay {
    public let url: URL
    private let socket: WebSocket
    
    public weak var delegate: RelayDelegate?
    public var eventCallback: ((RelayMessage) -> Void)?
    public var disconnectCallback: ((RelayError) -> Void)?
    
    public init(url: URL, delegate: RelayDelegate? = nil,
                onEvent eventCallback: ((RelayMessage) -> Void)? = nil,
                onDisconnect disconnectCallback: ((RelayError) -> Void)? = nil) {
        self.url = url
        self.delegate = delegate
        self.eventCallback = eventCallback
        self.disconnectCallback = disconnectCallback
        
        socket = WebSocket(url: url)
    }
    
    public func connect() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            socket.onText = { text in
                guard let message = try? RelayMessage(text: text) else { return }
                delegate?.received(message: message)
                eventCallback?(message)
            }
            
            socket.onDisconnect = { error in
                delegate?.disconnected(error: RelayError.socketError(error))
                disconnectCallback?(RelayError.socketError(error))
            }
            
            socket.onConnect = {
                continuation.resume()
            }
            
            socket.connect()
        }
    }
    
    public func send(event: Event) async throws {
        try await send(message: ClientMessage.event(event))
    }
    
    public func subscribe(to subscription: Subscription) async throws {
        try await send(message: ClientMessage.subscribe(subscription))
    }
    
    public func unsubscribe(from subscriptionId: SubscriptionId) async throws {
        try await send(message: ClientMessage.unsubscribe(subscriptionId))
    }
    
    func send(message: ClientMessage) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            if socket.isConnected {
                do {
                    let message = try message.string()
                    socket.write(string: message) {
                        continuation.resume()
                    }
                } catch {
                    continuation.resume(throwing: RelayError.writeError(error))
                }
            } else {
                continuation.resume()
            }
        }
    }
    
    public func disconnect() {
        socket.disconnect()
    }
}
