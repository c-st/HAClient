import Combine
import Nimble
import XCTest

@testable import HAClient

final class IntegrationTest: XCTestCase {
    var cancellables: Set<AnyCancellable>! = []

    func skip_testAuthenticateAndDoStuff() {
        let client = HAClient(messageExchange: WebSocketConnection(endpoint: "ws://homeassistant.raspberrypi.localdomain/api/websocket"))

        waitUntil(timeout: 1) { done in
            client.authenticate(
                token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiIzNmFmZDMyMjdkYzQ0YmNlOGZiNDRhNTFiZDA4MDdkZSIsImlhdCI6MTYxMTI3MTQ2NiwiZXhwIjoxOTI2NjMxNDY2fQ.YDRag0Hvq0lrTvu4Rt_z9NAQAJJNManAP0g4wHBFRq0",
                onConnection: { done() },
                onFailure: { reason in print("Authentication failure", reason) }
            )
        }

        expect(client.currentPhase) == .authenticated

        client.requestRegistry()
        client.requestStates()

        client.registry.allAreas.sink(receiveValue: { areas in
            expect(areas).to(haveCount(4))
        }).store(in: &cancellables)
        
        client.registry.allEntities.sink(receiveValue: { entities in
            expect(entities["light.office_lamp_light"]).toNot(beNil())
        }).store(in: &self.cancellables)
        
        client.registry.allStates.sink(receiveValue: { states in
            expect(states.values).toNot(beNil())
        }).store(in: &self.cancellables)
    }
}
