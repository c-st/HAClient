import Nimble
import XCTest

@testable import HAClient

final class IntegrationTest: XCTestCase {
    func skip_testAuthenticate() {
        let client = HAClient(messageExchange: WebSocketConnection(endpoint: "ws://homeassistant.raspberrypi.localdomain/api/websocket"))

        waitUntil(timeout: 1) { done in
            client.authenticate(
                token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiIzNmFmZDMyMjdkYzQ0YmNlOGZiNDRhNTFiZDA4MDdkZSIsImlhdCI6MTYxMTI3MTQ2NiwiZXhwIjoxOTI2NjMxNDY2fQ.YDRag0Hvq0lrTvu4Rt_z9NAQAJJNManAP0g4wHBFRq0",
                completion: { done() },
                onFailure: { reason in print("Authentication failure", reason) }
            )
        }

        waitUntil(timeout: 1) { done in
            client.populateRegistry {
                done()
            }
        }

        expect(client.currentPhase) == .authenticated
        expect(client.registry.areas.count).to(be(4))
    }
}
