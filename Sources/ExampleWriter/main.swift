import Foundation
import NostrKit

// This is just a dummy key pair. Don't use it like this in production.
let keyPair = try KeyPair(privateKey: "df9aae2ac8233ffa210a086c54059d02ba3247dab1130dad968f28f036326a83")

let event = try Event(keyPair: keyPair, content: "Hello NostrKit.")

let message = ClientMessage.event(event)

// See the `docker/` directory in the project root for a local relay to use in development and testing.
let relayUrl = URL(string: "ws://localhost:8080")!
let webSocketTask = URLSession(configuration: .default).webSocketTask(with: relayUrl)

webSocketTask.resume()

webSocketTask.send(.string(try! message.string())) { error in
    if let error = error {
        fatalError("Error: \(error)")
    }
    
    webSocketTask.cancel(with: .goingAway, reason: nil)
    exit(EXIT_SUCCESS)
}

RunLoop.current.run()
