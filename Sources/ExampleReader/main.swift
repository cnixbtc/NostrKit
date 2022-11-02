import Foundation
import NostrKit

// This is just a dummy key pair. Don't use it like this in production.
let keyPair = try KeyPair(privateKey: "df9aae2ac8233ffa210a086c54059d02ba3247dab1130dad968f28f036326a83")

let subscription = Subscription(filters: [
    .init(authors: [keyPair.publicKey])
])

let message = ClientMessage.subscribe(subscription)

// See the `docker/` directory in the project root for a local relay to use in development and testing.
let relayUrl = URL(string: "ws://localhost:8080")!
let webSocketTask = URLSession(configuration: .default).webSocketTask(with: relayUrl)

webSocketTask.resume()

webSocketTask.send(.string(try! message.string())) { error in
    if let error = error {
        fatalError("Error: \(error)")
    }
}

func listen() {
    webSocketTask.receive { result in
        switch result {
        case .success(let message):
            switch message {
            case .string(let text):
                let message = try! RelayMessage(text: text)
                print(text)
            default:
                fatalError("Error: Received unknown message type")
            }
        case .failure(let error):
            fatalError("Error: \(error)")
        }
        
        listen()
    }
}

listen()
RunLoop.current.run()
