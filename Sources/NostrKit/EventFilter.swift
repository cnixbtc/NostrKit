import Foundation

public struct EventFilter: Encodable {
    let ids: [EventId]?
    let authors: [String]?
    let eventKinds: [EventKind]?
    let tags: [String: [String]]?
    let since: Timestamp?
    let until: Timestamp?
    let limit: Int?
    
    private enum CodingKeys: String, CodingKey {
        case ids
        case authors
        case eventKinds = "kinds"
        case since
        case until
        case limit
    }
    
    private struct TagsCodingKeys: CodingKey {
        var stringValue: String
        var intValue: Int?
        
        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) { return nil }
    }
    
    public init(
        ids: [EventId]? = nil,
        authors: [String]? = nil,
        eventKinds: [EventKind]? = nil,
        tags: [String: [String]]? = nil,
        since: Timestamp? = nil,
        until: Timestamp? =  nil,
        limit: Int? = nil
    ) {
        self.ids = ids
        self.authors = authors
        self.eventKinds = eventKinds
        self.tags = tags
        self.since = since
        self.until = until
        self.limit = limit
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(ids, forKey: .ids)
        try container.encodeIfPresent(authors, forKey: .authors)
        try container.encodeIfPresent(eventKinds, forKey: .eventKinds)
        try container.encodeIfPresent(since, forKey: .since)
        try container.encodeIfPresent(until, forKey: .until)
        try container.encodeIfPresent(limit, forKey: .limit)
        
        var tagsContainer = encoder.container(keyedBy: TagsCodingKeys.self)
        for (id, value) in tags ?? [:] {
            try tagsContainer.encode(value, forKey: .init(stringValue: "#\(id)")!)
        }
    }
}
