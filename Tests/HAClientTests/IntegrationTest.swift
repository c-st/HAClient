import Nimble
import XCTest

@testable import HAClient

final class IntegrationTest: XCTestCase {
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

        expect(client.registry.areas).toEventually(haveCount(4))
        expect(client.registry.entities["light.office_lamp_light"]).toNotEventually(beNil())
        expect(client.registry.states).toNotEventually(beNil())
    }
}
