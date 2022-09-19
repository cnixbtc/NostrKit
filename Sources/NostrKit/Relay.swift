import Foundation
import Starscream

public enum RelayError: Error {
    case cannotConnect(Error?)
    case socketError(Error?)
}

public protocol RelayDelegate: AnyObject {
    func recevied(message: RelayMessage)
}

public struct Relay {
    public let url: URL
    private let socket: WebSocket
    
    public weak var delegate: RelayDelegate?
    public var eventCallback: ((RelayMessage) -> Void)?
    
    public init(url: URL, delegate: RelayDelegate? = nil, onEvent eventCallback: ((RelayMessage) -> Void)? = nil) {
        self.url = url
        self.delegate = delegate
        self.eventCallback = eventCallback
        
        socket = WebSocket(url: url)
    }
    
    public func connect() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            socket.onText = { text in
                guard let message = try? RelayMessage(text: text) else { return }
                delegate?.recevied(message: message)
                eventCallback?(message)
            }
            
            socket.onDisconnect = { error in
                continuation.resume(with: .failure(RelayError.cannotConnect(error)))
            }
            
            socket.onConnect = {
                socket.onDisconnect = { error in
                    continuation.resume(with: .failure(RelayError.socketError(error)))
                }
                
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
            print(try! message.string())
            socket.write(string: try! message.string()) {
                continuation.resume()
            }
        }
    }
    
    public func disconnect() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            socket.onDisconnect = { error in
                if let error = error {
                    continuation.resume(with: .failure(RelayError.socketError(error)))
                } else {
                    continuation.resume()
                }
            }
            socket.disconnect()
        }
    }
}
