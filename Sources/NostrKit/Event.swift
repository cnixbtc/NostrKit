import Foundation
import Crypto
import secp256k1

public typealias EventId = String

public enum EventError: Error {
    case encodingFailed
    case signingFailed
}

public enum EventKind: Codable, Equatable {
    case setMetadata
    case textNote
    case recommendServer
    case encryptedDirectMessage
    case custom(Int)
    
    public init(id: Int) {
        switch id {
        case 0: self = .setMetadata
        case 1: self = .textNote
        case 2: self = .recommendServer
        case 4: self = .encryptedDirectMessage
        default: self = .custom(id)
        }
    }
    
    var id: Int {
        switch self {
        case .setMetadata: return 0
        case .textNote: return 1
        case .recommendServer: return 2
        case .encryptedDirectMessage: return 4
        case .custom(let customId): return customId
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        self.init(id: try container.decode(Int.self))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        try container.encode(self.id)
    }
}

public struct EventTag: Codable {
    private let underlyingData: [String]
    
    public var id: String {
        return underlyingData.first!
    }
    
    public var otherInformation: [String] {
        return Array(underlyingData.suffix(from: 1))
    }
    
    public static func event(otherEventId: String, recommendedRelay: URL? = nil) -> EventTag {
        return EventTag(id: "e", otherInformation: otherEventId, recommendedRelay?.absoluteString)
    }
    
    public static func pubKey(publicKey: String, recommendedRelay: URL? = nil) -> EventTag {
        return EventTag(id: "p", otherInformation: publicKey, recommendedRelay?.absoluteString)
    }
    
    public init(underlyingData: [String]) {
        self.underlyingData = underlyingData
    }
    
    public init(id: String, otherInformation: String?...) {
        underlyingData = [id] + otherInformation.compactMap { $0 }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        underlyingData = try container.decode([String].self)
        
        guard underlyingData.count > 0 else {
            throw DecodingError.dataCorrupted(.init(codingPath: .init(), debugDescription: "missing required tag id"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(contentsOf: underlyingData)
    }
}

private struct SerializableEvent: Encodable {
    let id = 0
    let publicKey: String
    let createdAt: Timestamp
    let kind: EventKind
    let tags: [EventTag]
    let content: String
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(id)
        try container.encode(publicKey)
        try container.encode(createdAt)
        try container.encode(kind)
        try container.encode(tags)
        try container.encode(content)
    }
}

public struct Event: Codable {
    public let id: EventId
    public let publicKey: String
    public let createdAt: Timestamp
    public let kind: EventKind
    public let tags: [EventTag]
    public let content: String
    public let signature: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case publicKey = "pubkey"
        case createdAt = "created_at"
        case kind
        case tags
        case content
        case signature = "sig"
    }
    
    // Used to sign external event
    public init(keyPair: KeyPair, id: EventId, publicKey: String, createdAt: Timestamp, kind: EventKind, tags: [EventTag], content: String) throws {
        self.id = id
        self.publicKey = publicKey
        self.createdAt = createdAt
        self.kind = kind
        self.tags = tags
        self.content = content
        if publicKey != keyPair.publicKey { throw EventError.signingFailed }
        
        let serializableEvent = SerializableEvent(
            publicKey: publicKey,
            createdAt: createdAt,
            kind: kind,
            tags: tags,
            content: content
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .withoutEscapingSlashes
            let serializedEvent = try encoder.encode(serializableEvent)
            let sig = try keyPair.schnorrSigner.signature(for: serializedEvent)
            guard keyPair.schnorrValidator.isValidSignature(sig, for: serializedEvent) else {
                throw EventError.signingFailed
            }
            self.signature = sig.rawRepresentation.hex()
        } catch is EncodingError {
            throw EventError.encodingFailed
        } catch {
            throw EventError.signingFailed
        }
    }
    
    public init(keyPair: KeyPair, kind: EventKind = .textNote, tags: [EventTag] = [], content: String) throws {
        publicKey = keyPair.publicKey
        createdAt = Timestamp(date: Date())
        self.kind = kind
        self.tags = tags
        self.content = content
        
        let serializableEvent = SerializableEvent(
            publicKey: publicKey,
            createdAt: createdAt,
            kind: kind,
            tags: tags,
            content: content
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .withoutEscapingSlashes
            let serializedEvent = try encoder.encode(serializableEvent)
            self.id = Data(SHA256.hash(data: serializedEvent)).hex()
        
            let sig = try keyPair.schnorrSigner.signature(for: serializedEvent)
            
            guard keyPair.schnorrValidator.isValidSignature(sig, for: serializedEvent) else {
                throw EventError.signingFailed
            }

            self.signature = sig.rawRepresentation.hex()
        } catch is EncodingError {
            throw EventError.encodingFailed
        } catch {
            throw EventError.signingFailed
        }
    }
    
    public func verified() -> Bool {
        
        let serializableEvent = SerializableEvent(publicKey: self.publicKey, createdAt: self.createdAt,
                                                  kind: self.kind, tags: self.tags, content: self.content)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes
        
        guard let serializedEvent = try? encoder.encode(serializableEvent) else {
            return false
        }
        
        let rawId = Data(SHA256.hash(data: serializedEvent))
        
        if rawId.hex() != self.id {
            return false
        }
        
        guard var sig = try? Data(hex: self.signature).bytes else {
            return false
        }
                
        guard var publicKey = try? Data(hex: self.publicKey).bytes else {
            return false
        }
        
        guard let ctx = try? secp256k1.Context.create() else {
            return false
        }
        
        var xOnlyPubkey = secp256k1_xonly_pubkey.init()
        let xOnlyPubkeyValid = secp256k1_xonly_pubkey_parse(ctx, &xOnlyPubkey, &publicKey) != 0
        if !xOnlyPubkeyValid {
            return false
        }
        
        var rawIdBytes = rawId.bytes

        return secp256k1_schnorrsig_verify(ctx, &sig, &rawIdBytes, rawId.count, &xOnlyPubkey) > 0

    }
}
