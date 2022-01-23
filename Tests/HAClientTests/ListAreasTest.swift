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
            await self.mockExchange.simulateIncomingMessage(message: JSONCoding.serialize(AuthOkMessage()))
        }
        try await client.authenticate(token: "mytoken")
    }
    
    func test_failsWhenNotAuthenticated() async throws {
        let exchange = FakeMessageExchange()
        let unauthenticatedClient = HAClient(messageExchange: exchange)
        
        do {
            try await _ = unauthenticatedClient.listAreas()
            fail("Did not throw")
        } catch {
            expect(error).to(matchError(HAClientError.authenticationRequired))
        }
    }
    
    func test_requestsAreas() async throws {
        mockExchange.outgoingMessageHandler = { msg in
            let expectedMsg = JSONCoding.serialize(Message(type: .listAreas, id: 1))
            expect(msg).to(equal(expectedMsg))
            
            let areasResponse = JSONCoding.serialize(
                ResultMessage<Area>(
                    id: 1,
                    success: true,
                    result: TestExamples.areas
                )
            )
            await self.mockExchange.simulateIncomingMessage(message: areasResponse)
        }
        
        let areas = try await client.listAreas()
        expect(areas).to(haveCount(2))
    }
}
