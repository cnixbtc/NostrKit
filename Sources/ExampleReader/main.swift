import Foundation
import Starscream
import NostrKit

// See the `docker/` directory in the project root for a local relay to use in development and testing.
let relayUrl = URL(string: "http://localhost:8080")!

// This is just a dummy key pair. Don't use it like this in production.
let keyPair = try KeyPair(privateKey: "df9aae2ac8233ffa210a086c54059d02ba3247dab1130dad968f28f036326a83")

let relay = Relay(url: relayUrl, onEvent: { message in
    print(message)
})

let subscription = Subscription(filters: [
    .init(authors: [keyPair.publicKey])
])

Task {
    do {
        try await relay.connect()
        try await relay.subscribe(to: subscription)
    } catch {
        print("Something went wrong: \(error)")
        
        exit(EXIT_FAILURE)
    }
}

RunLoop.current.run()
