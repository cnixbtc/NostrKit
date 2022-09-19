# NostrKit 

A Swift library for interacting with a [Nostr](https://github.com/nostr-protocol/nostr) relay.

## Installation

NostrKit is available as a [Swift Package Manager](https://swift.org/package-manager/) package.
To use it, add the following dependency to your `Package.swift` file:

``` swift
.package(url: "https://github.com/cnixbtc/NostrKit.git", from: "0.1.0"),
```

## Functionality

NostrKit can be used to publish events on a Nostr relay as well as request events and subscribe to new updates.

### Subscribing to Events

``` swift
let keyPair = try KeyPair(privateKey: "<hex>")
let relay = Relay(url: URL("<url>")!, onEvent: { print($0) })

let subscription = Subscription(filters: [
    .init(authors: [keyPair.publicKey])
])

try await relay.connect()
try await relay.subscribe(to: subscription)

// later on...

try await relay.unsubscribe(from: subscription.id)
```

### Publishing Events

``` swift
let keyPair = try KeyPair(privateKey: "<hex>")
let relay = Relay(url: URL("<url>")!)

let event = try Event(keyPair: keyPair, content: "Hello NostrKit.")

try await relay.connect()
try await relay.send(event: event)
```

Fully functional code examples can be found in `Sources/ExampleReader` as well as `Sources/ExampleWriter`.
Run `swift run example-reader` and `swift run example-writer` to see them in action.
