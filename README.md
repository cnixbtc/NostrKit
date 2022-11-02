# NostrKit 

A Swift library providing data types for interacting with a [Nostr](https://github.com/nostr-protocol/nostr) relay.

## Installation

NostrKit is available as a [Swift Package Manager](https://swift.org/package-manager/) package.
To use it, add the following dependency to your `Package.swift` file:

``` swift
.package(url: "https://github.com/cnixbtc/NostrKit.git", from: "1.0.0"),
```

## Functionality

NostrKit provides the necessary data types for interacting with a Nostr relay to create events and manage subscriptions.

### Subscribing to Events

``` swift
let keyPair = try KeyPair(privateKey: "<hex>")

let subscription = Subscription(filters: [
    .init(authors: [keyPair.publicKey])
])

let subscribeMessage = try ClientMessage
    .subscribe(subscription)
    .string()

// Subscribe to events created by this key pair by sending `subscribeMessage` 
// to a relay using a web socket connection of your choice. 
// Later on, create a message to unsubscribe like so:

let unsubscribeMessage = try ClientMessage
    .unsubscribe(subscription.id)
    .string()
```

### Publishing Events

``` swift
let keyPair = try KeyPair(privateKey: "<hex>")

let event = try Event(keyPair: keyPair, content: "Hello NostrKit.")

let message = ClientMessage.event(event)

// Publish the event by sending `subscribeMessage` 
// to a relay using a web socket connection of your choice. 
```

Fully functional code examples can be found in `Sources/ExampleReader` as well as `Sources/ExampleWriter`.
Run `swift run example-reader` and `swift run example-writer` to see them in action.
