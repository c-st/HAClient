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
            let expectedMsg = JSONCoding.serialize(ListAreasMessage(id: 1))
            expect(msg).to(equal(expectedMsg))
            
            // respond with area response
            let areasResponse = JSONCoding.serialize(
                ResultMessage<Area>(
                    id: 1,
                    success: true,
                    result: TestExamples.areas
                )
            )
            self.mockExchange.simulateIncomingMessage(message: areasResponse)
        }
        
        let areas = try await client.listAreas()
        expect(areas).to(haveCount(2))
    }
}
