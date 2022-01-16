import Nimble
import XCTest

@testable import HAClient

final class RetrieveStatesTest: XCTestCase {
    var mockExchange: FakeMessageExchange!
    var client: HAClient!

    override func setUp() async throws {
        mockExchange = FakeMessageExchange()
        client = HAClient(messageExchange: mockExchange!)
        mockExchange.outgoingMessageHandler = { msg in
            await self.mockExchange.simulateIncomingMessage(message: JSONCoding.serialize(AuthOkMessage()))
        }
        try await client.authenticate(token: "mytoken")
    }
    
    func test_parsesAttributes() async throws {
        mockExchange.outgoingMessageHandler = { msg in
            let message = """
            {
              "id": 1,
              "success": true,
              "type": "result",
              "result": [
                {
                  "entity_id": "sensor.chinese_air_pollution_level",
                  "state": "good",
                  "attributes": {
                    "key": null,
                    "key2": 1,
                    "key3": 1.23,
                    "key4": false,
                    "key5": ["a", "b", "c"]
                  }
                }
              ]
            }
            """
            await self.mockExchange.simulateIncomingMessage(message: message)
        }
        
        let states = try await client.retrieveStates()
        expect(states).to(haveCount(1))
        
        let expected: [String: Any?] = [
            "key": nil,
            "key2": 1,
            "key3": 1.23,
            "key4": false,
            "key5": ["a", "b", "c"]
        ]
        
        let attributes = states[0].attributes!.asDictionary as NSDictionary
        expect(attributes).to(equal(expected as NSDictionary))
    }
}
