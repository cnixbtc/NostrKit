import XCTest
@testable import NostrKit

final class Tests: XCTestCase {
    func testMessageEncodingSubscription() throws {
        let now = Timestamp(date: Date())
        let then = Timestamp(date: Date.distantFuture)
        
        let subscription = Subscription(filters: [
            .init(
                ids: ["foo"],
                authors: ["bar"],
                eventKinds: [.textNote],
                tags: ["e": ["foo", "bar"], "p": ["bar", "foo"]],
                since: now,
                until: then,
                limit: 10)
        ])
        
        let message = ClientMessage.subscribe(subscription)
        let encoded = try JSONEncoder().encode(message)
        
        let decodedMessage = try JSONSerialization.jsonObject(with: encoded) as! [Any]
        
        XCTAssertEqual(decodedMessage[0] as! String, "REQ")
        XCTAssertNotNil(decodedMessage[1] as? String)
        
        let decodedFilter = decodedMessage[2] as! [String: Any]
        
        XCTAssertEqual(decodedFilter["ids"] as! [String], ["foo"])
        XCTAssertEqual(decodedFilter["authors"] as! [String], ["bar"])
        XCTAssertEqual(decodedFilter["kinds"] as! [Int], [1])
        XCTAssertEqual(decodedFilter["#e"] as! [String], ["foo", "bar"])
        XCTAssertEqual(decodedFilter["#p"] as! [String], ["bar", "foo"])
        XCTAssertEqual(decodedFilter["since"] as! Int, now.timestamp)
        XCTAssertEqual(decodedFilter["until"] as! Int, then.timestamp)
        XCTAssertEqual(decodedFilter["limit"] as! Int, 10)
    }
}
