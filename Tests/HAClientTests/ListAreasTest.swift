import Nimble
import XCTest

@testable import HAClient

final class ListAreasTest: XCTestCase {
    var mockExchange: FakeMessageExchange!
    var client: HAClient!

    override func setUp() async throws {
        mockExchange = FakeMessageExchange()
        client = HAClient(messageExchange: mockExchange!)
        mockExchange.outgoingMessageHandler = { msg in
            self.mockExchange.simulateIncomingMessage(message: JSONCoding.serialize(AuthOkMessage()))
        }
        try await client.authenticate(token: "mytoken")
    }
    
    func test_requestsAreas() async throws {
        mockExchange.outgoingMessageHandler = { msg in
            let expectedMsg = JSONCoding.serialize(RequestAreaRegistry(id: 1))
            expect(msg).to(equal(expectedMsg))
            
            // respond with area response
            let areasResponse = JSONCoding.serialize(
                ListAreasResultMessage(
                    id: 1,
                    success: true,
                    result: [
                        ListAreasResultMessage.Area(
                            name: "Living room",
                            areaId: "living-room"
                        ),
                        ListAreasResultMessage.Area(
                            name: "Bedroom",
                            areaId: "bedroom"
                        )
                    ]
                )
            )
            self.mockExchange.simulateIncomingMessage(message: areasResponse)
        }
        
        let areas = try await client.listAreas()
        expect(areas).to(haveCount(2))
    }
}
